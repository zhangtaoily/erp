package com.eerp.bos.bill;

import com.eerp.common.id.SnowflakeIdGenerator;
import com.eerp.meta.bo.vo.FormMetaVO;
import com.eerp.meta.entity.dto.FormEntityDTO;
import com.eerp.meta.field.entity.MetaFormField;
import com.eerp.meta.cache.FormMetaCache;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * 单据数据访问器：基于元数据动态读写主表/子表/孙表数据。
 * <p>
 * 表名与列名均来自元数据（可信来源），动态拼接到 SQL 中；
 * 数据值一律使用参数化（?）查询，避免 SQL 注入。
 */
@Service
public class BillDataAccessor {

    @Autowired
    private FormMetaCache formMetaCache;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Autowired
    private SnowflakeIdGenerator snowflakeIdGenerator;

    /**
     * 加载完整单据（主表 + 子表 + 孙表）
     *
     * @return {main: {...}, subs: {entity_code: [...]}}
     */
    public Map<String, Object> loadBill(String boCode, Long billId) {
        Map<String, Object> result = new LinkedHashMap<>();
        Map<String, Object> main = new LinkedHashMap<>();
        Map<String, Object> subs = new LinkedHashMap<>();
        result.put("main", main);
        result.put("subs", subs);

        FormMetaVO meta = formMetaCache.get(boCode);
        if (meta == null || meta.getEntities() == null || meta.getEntities().isEmpty()) {
            return result;
        }

        List<FormEntityDTO> entities = sortedByLevel(meta.getEntities());

        // 主表
        FormEntityDTO mainEntity = findMain(entities);
        if (mainEntity == null) {
            return result;
        }
        Map<String, Object> mainRow = selectOne(mainEntity.getTableName(), billId);
        if (mainRow == null) {
            return result;
        }
        main.putAll(mainRow);

        // 子表 / 孙表
        for (FormEntityDTO entity : entities) {
            if (isMain(entity)) {
                continue;
            }
            String linkField = entity.getLinkField();
            if (linkField == null || linkField.isEmpty()) {
                continue;
            }
            List<Map<String, Object>> rows = new ArrayList<>();

            if (isLevel(entity, 1)) {
                // 子表：按主表ID查询
                rows = selectList(entity.getTableName(), linkField, billId);
            } else if (isLevel(entity, 2)) {
                // 孙表：按父实体（子表）各行ID查询
                String parentCode = entity.getParentEntityCode();
                List<Map<String, Object>> parentRows = parentCode != null
                        ? (List<Map<String, Object>>) subs.getOrDefault(parentCode, new ArrayList<>())
                        : new ArrayList<>();
                for (Map<String, Object> parentRow : parentRows) {
                    Object parentId = parentRow.get("id");
                    if (parentId == null) {
                        continue;
                    }
                    List<Map<String, Object>> childRows = selectList(entity.getTableName(), linkField, parentId);
                    rows.addAll(childRows);
                }
            }
            subs.put(entity.getEntityCode(), rows);
        }
        return result;
    }

    /**
     * 保存单据（新增或更新主表 + 子表 + 孙表），返回主表ID
     */
    @Transactional(rollbackFor = Exception.class)
    @SuppressWarnings("unchecked")
    public Long saveBill(String boCode, Map<String, Object> billData) {
        FormMetaVO meta = formMetaCache.get(boCode);
        if (meta == null || meta.getEntities() == null || meta.getEntities().isEmpty()) {
            throw new IllegalArgumentException("业务对象[" + boCode + "]未配置表单元数据");
        }

        List<FormEntityDTO> entities = sortedByLevel(meta.getEntities());
        FormEntityDTO mainEntity = findMain(entities);
        if (mainEntity == null) {
            throw new IllegalArgumentException("业务对象[" + boCode + "]未配置主实体");
        }

        Map<String, Object> mainData = (Map<String, Object>) billData.getOrDefault("main", new LinkedHashMap<>());
        Set<String> mainCols = allowedColumns(mainEntity);

        // 主表：有 id 则 UPDATE，否则 INSERT
        Long mainId = toLong(mainData.get("id"));
        if (mainId != null) {
            updateRow(mainEntity.getTableName(), mainData, mainCols, mainId);
        } else {
            mainId = snowflakeIdGenerator.nextId();
            mainData.put("id", mainId);
            insertRow(mainEntity.getTableName(), mainData, mainCols);
        }

        // 子表 / 孙表
        Map<String, Object> subs = (Map<String, Object>) billData.getOrDefault("subs", new LinkedHashMap<>());
        for (FormEntityDTO entity : entities) {
            if (isMain(entity)) {
                continue;
            }
            // 孙表（level>=2）通过嵌套在父行中保存，不直接从 subs 读取
            if (isLevel(entity, 2)) {
                continue;
            }
            Object rowsObj = subs.get(entity.getEntityCode());
            if (!(rowsObj instanceof List)) {
                continue;
            }
            List<Map<String, Object>> rows = (List<Map<String, Object>>) rowsObj;
            Set<String> cols = allowedColumns(entity);
            String linkField = entity.getLinkField();

            for (Map<String, Object> row : rows) {
                // 一级子表：自动回填与主表的关联字段
                if (isLevel(entity, 1) && linkField != null && !linkField.isEmpty()
                        && isNullOrEmpty(row.get(linkField))) {
                    row.put(linkField, mainId);
                }
                Long rowId = toLong(row.get("id"));
                if (rowId != null) {
                    updateRow(entity.getTableName(), row, cols, rowId);
                } else {
                    rowId = snowflakeIdGenerator.nextId();
                    row.put("id", rowId);
                    insertRow(entity.getTableName(), row, cols);
                }
                // 处理嵌套的孙表行（key=孙表 entity_code）
                saveNestedGrandChildren(entities, entity, row, rowId);
            }
        }
        return mainId;
    }

    /**
     * 保存嵌套在父行中的孙表数据。
     *
     * <p>孙表行嵌套在父行 Map 中，key 为孙表 entity_code。
     * 保存时自动回填 link_field 为父行 ID。</p>
     */
    @SuppressWarnings("unchecked")
    private void saveNestedGrandChildren(List<FormEntityDTO> entities, FormEntityDTO parentEntity,
                                          Map<String, Object> parentRow, Long parentId) {
        for (FormEntityDTO entity : entities) {
            if (!isLevel(entity, 2)) {
                continue;
            }
            // 孙表的 parent_entity_code 必须匹配当前父实体
            if (!parentEntity.getEntityCode().equals(entity.getParentEntityCode())) {
                continue;
            }
            Object childRowsObj = parentRow.get(entity.getEntityCode());
            if (!(childRowsObj instanceof List)) {
                continue;
            }
            List<Map<String, Object>> childRows = (List<Map<String, Object>>) childRowsObj;
            Set<String> childCols = allowedColumns(entity);
            String childLinkField = entity.getLinkField();

            for (Map<String, Object> childRow : childRows) {
                // 回填孙表与父行的关联字段
                if (childLinkField != null && !childLinkField.isEmpty()
                        && isNullOrEmpty(childRow.get(childLinkField))) {
                    childRow.put(childLinkField, parentId);
                }
                Long childRowId = toLong(childRow.get("id"));
                if (childRowId != null) {
                    updateRow(entity.getTableName(), childRow, childCols, childRowId);
                } else {
                    childRowId = snowflakeIdGenerator.nextId();
                    childRow.put("id", childRowId);
                    insertRow(entity.getTableName(), childRow, childCols);
                }
            }
        }
    }

    /**
     * 删除单据（子表 + 孙表 + 主表）
     */
    @Transactional(rollbackFor = Exception.class)
    public void deleteBill(String boCode, Long billId) {
        FormMetaVO meta = formMetaCache.get(boCode);
        if (meta == null || meta.getEntities() == null || meta.getEntities().isEmpty()) {
            return;
        }
        List<FormEntityDTO> entities = sortedByLevel(meta.getEntities());
        // 先删子表/孙表，再删主表
        for (FormEntityDTO entity : entities) {
            if (isMain(entity)) {
                continue;
            }
            String linkField = entity.getLinkField();
            if (linkField == null || linkField.isEmpty()) {
                continue;
            }
            if (isLevel(entity, 1)) {
                jdbcTemplate.update("DELETE FROM `" + entity.getTableName() + "` WHERE `" + linkField + "` = ?", billId);
            } else if (isLevel(entity, 2)) {
                // 孙表：通过父实体关联字段级联删除
                String parentCode = entity.getParentEntityCode();
                FormEntityDTO parentEntity = findByCode(entities, parentCode);
                if (parentEntity == null) {
                    continue;
                }
                String parentLink = parentEntity.getLinkField();
                if (parentLink == null) {
                    continue;
                }
                String sql = "DELETE FROM `" + entity.getTableName()
                        + "` WHERE `" + linkField + "` IN (SELECT `id` FROM `"
                        + parentEntity.getTableName() + "` WHERE `" + parentLink + "` = ?)";
                jdbcTemplate.update(sql, billId);
            }
        }
        FormEntityDTO mainEntity = findMain(entities);
        if (mainEntity != null) {
            jdbcTemplate.update("DELETE FROM `" + mainEntity.getTableName() + "` WHERE `id` = ?", billId);
        }
    }

    // ---------------- 内部工具方法 ----------------

    private Map<String, Object> selectOne(String table, Long id) {
        if (table == null || id == null) {
            return null;
        }
        try {
            return jdbcTemplate.queryForMap("SELECT * FROM `" + table + "` WHERE `id` = ?", id);
        } catch (EmptyResultDataAccessException e) {
            return null;
        }
    }

    private List<Map<String, Object>> selectList(String table, String linkField, Object parentId) {
        if (table == null || linkField == null || parentId == null) {
            return new ArrayList<>();
        }
        return jdbcTemplate.queryForList("SELECT * FROM `" + table + "` WHERE `" + linkField + "` = ?", parentId);
    }

    private void insertRow(String table, Map<String, Object> data, Set<String> allowedCols) {
        List<String> cols = new ArrayList<>();
        List<Object> vals = new ArrayList<>();
        for (Map.Entry<String, Object> e : data.entrySet()) {
            String key = e.getKey();
            if (allowedCols.contains(key)) {
                cols.add(key);
                vals.add(e.getValue());
            }
        }
        if (cols.isEmpty()) {
            return;
        }
        StringBuilder sql = new StringBuilder("INSERT INTO `").append(table).append("` (");
        for (int i = 0; i < cols.size(); i++) {
            if (i > 0) {
                sql.append(", ");
            }
            sql.append("`").append(cols.get(i)).append("`");
        }
        sql.append(") VALUES (");
        for (int i = 0; i < cols.size(); i++) {
            if (i > 0) {
                sql.append(", ");
            }
            sql.append("?");
        }
        sql.append(")");
        jdbcTemplate.update(sql.toString(), vals.toArray());
    }

    private void updateRow(String table, Map<String, Object> data, Set<String> allowedCols, Long id) {
        List<String> cols = new ArrayList<>();
        List<Object> vals = new ArrayList<>();
        for (Map.Entry<String, Object> e : data.entrySet()) {
            String key = e.getKey();
            if ("id".equals(key)) {
                continue;
            }
            if (allowedCols.contains(key)) {
                cols.add(key);
                vals.add(e.getValue());
            }
        }
        if (cols.isEmpty()) {
            return;
        }
        StringBuilder sql = new StringBuilder("UPDATE `").append(table).append("` SET ");
        for (int i = 0; i < cols.size(); i++) {
            if (i > 0) {
                sql.append(", ");
            }
            sql.append("`").append(cols.get(i)).append("` = ?");
        }
        sql.append(" WHERE `id` = ?");
        vals.add(id);
        jdbcTemplate.update(sql.toString(), vals.toArray());
    }

    /**
     * 允许写入的列集合（来自字段元数据 + id + 关联字段），用于过滤输入、防止列名注入
     *
     * <p>关联字段（link_field）必须显式加入：子表 INSERT 时通过回填 link_field 与主表 ID 关联，
     * 若未加入则会过滤掉关联字段，导致子表记录的 link_field 为 NULL，破坏主子孙三表关联。</p>
     */
    private Set<String> allowedColumns(FormEntityDTO entity) {
        Set<String> cols = new HashSet<>();
        cols.add("id");
        if (entity.getLinkField() != null && !entity.getLinkField().isEmpty()) {
            cols.add(entity.getLinkField());
        }
        if (entity.getFields() != null) {
            for (MetaFormField f : entity.getFields()) {
                if (f.getFieldCode() != null) {
                    cols.add(f.getFieldCode());
                }
            }
        }
        return cols;
    }

    private List<FormEntityDTO> sortedByLevel(List<FormEntityDTO> entities) {
        List<FormEntityDTO> list = new ArrayList<>(entities);
        list.sort(Comparator.comparingInt(e -> e.getEntityLevel() == null ? 0 : e.getEntityLevel()));
        return list;
    }

    private FormEntityDTO findMain(List<FormEntityDTO> entities) {
        for (FormEntityDTO e : entities) {
            if (isMain(e)) {
                return e;
            }
        }
        return null;
    }

    private FormEntityDTO findByCode(List<FormEntityDTO> entities, String code) {
        if (code == null) {
            return null;
        }
        for (FormEntityDTO e : entities) {
            if (code.equals(e.getEntityCode())) {
                return e;
            }
        }
        return null;
    }

    private boolean isMain(FormEntityDTO e) {
        return "MAIN".equalsIgnoreCase(e.getEntityType())
                || (e.getEntityLevel() != null && e.getEntityLevel() == 0);
    }

    private boolean isLevel(FormEntityDTO e, int level) {
        return e.getEntityLevel() != null && e.getEntityLevel() == level;
    }

    private Long toLong(Object v) {
        if (v == null) {
            return null;
        }
        if (v instanceof Number) {
            return ((Number) v).longValue();
        }
        String s = v.toString().trim();
        if (s.isEmpty()) {
            return null;
        }
        try {
            return Long.parseLong(s);
        } catch (NumberFormatException e) {
            return null;
        }
    }

    /** null 或空字符串检查（用于 link_field 回填判断） */
    private boolean isNullOrEmpty(Object v) {
        if (v == null) return true;
        if (v instanceof String) return ((String) v).trim().isEmpty();
        return false;
    }
}
