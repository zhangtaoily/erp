package com.eerp.bos.list;

import com.eerp.common.api.PageRequest;
import com.eerp.common.api.PageResult;
import com.eerp.meta.bo.vo.FormMetaVO;
import com.eerp.meta.cache.FormMetaCache;
import com.eerp.meta.entity.dto.FormEntityDTO;
import com.eerp.meta.field.entity.MetaFormField;
import com.eerp.meta.list.entity.MetaListColumn;
import com.eerp.meta.list.entity.MetaQueryField;
import com.eerp.meta.list.service.MetaListColumnService;
import com.eerp.meta.list.service.MetaQueryFieldService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.util.*;

/**
 * 列表查询服务实现：基于元数据动态构建分页查询 SQL
 * <p>
 * 列名/表名来自元数据（可信），数据值参数化。ORDER BY 字段经白名单校验。
 */
@Service
public class ListServiceImpl extends AbstractListService {

    @Autowired
    private MetaListColumnService metaListColumnService;

    @Autowired
    private MetaQueryFieldService metaQueryFieldService;

    @Autowired
    private FormMetaCache formMetaCache;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    private static final Set<String> ALLOWED_OPS = new HashSet<>(Arrays.asList(
            "eq", "ne", "gt", "lt", "ge", "le", "like", "not_like",
            "begin_with", "end_with", "is_null", "is_not_null", "in", "between"));

    private static final Set<String> SYSTEM_ORDER_COLS = new HashSet<>(Arrays.asList(
            "id", "create_time", "update_time", "pact_state", "code"));

    @Override
    public PageResult<Map<String, Object>> page(String boCode, PageRequest pageRequest, Map<String, Object> params) {
        FormMetaVO meta = formMetaCache.get(boCode);
        if (meta == null || meta.getBusinessObject() == null || meta.getEntities() == null) {
            return new PageResult<>(Collections.emptyList(), 0, pageRequest.getPageNum(), pageRequest.getPageSize());
        }
        String mainTable = meta.getBusinessObject().getMainTable();
        if (mainTable == null) {
            return new PageResult<>(Collections.emptyList(), 0, pageRequest.getPageNum(), pageRequest.getPageSize());
        }

        List<MetaListColumn> columns = metaListColumnService.listByBoCode(boCode);

        // 分析列配置涉及哪些实体（通过 entity_code）
        Set<String> involvedEntityCodes = new LinkedHashSet<>();
        for (FormEntityDTO e : meta.getEntities()) {
            if (isMainEntity(e)) {
                involvedEntityCodes.add(e.getEntityCode());
                break;
            }
        }
        if (columns != null) {
            for (MetaListColumn col : columns) {
                Integer isShow = col.getIsShow();
                Integer isEnable = col.getIsEnable();
                if (col.getFieldCode() != null
                        && (isShow == null || isShow == 1)
                        && (isEnable == null || isEnable == 1)
                        && col.getEntityCode() != null && !col.getEntityCode().isEmpty()) {
                    involvedEntityCodes.add(col.getEntityCode());
                }
            }
        }

        // expand 参数强制展开（向后兼容）
        boolean forceExpand = false;
        if (params != null) {
            Object expand = params.get("expand");
            if (expand != null && ("true".equalsIgnoreCase(expand.toString()) || "1".equals(expand.toString()))) {
                forceExpand = true;
            }
        }

        // 判断是否有非主表实体
        boolean needJoin = forceExpand;
        for (String ec : involvedEntityCodes) {
            for (FormEntityDTO e : meta.getEntities()) {
                if (ec.equals(e.getEntityCode()) && !isMainEntity(e)) {
                    needJoin = true;
                    break;
                }
            }
            if (needJoin) break;
        }

        if (needJoin) {
            return pageJoin(boCode, pageRequest, params, meta, mainTable, columns, involvedEntityCodes);
        }
        return pagePlain(boCode, pageRequest, params);
    }

    /**
     * 主表单表查询（无 JOIN）。
     */
    private PageResult<Map<String, Object>> pagePlain(String boCode, PageRequest pageRequest,
                                                      Map<String, Object> params) {
        FormMetaVO meta = formMetaCache.get(boCode);
        if (meta == null || meta.getBusinessObject() == null) {
            return new PageResult<>(Collections.emptyList(), 0, pageRequest.getPageNum(), pageRequest.getPageSize());
        }
        String mainTable = meta.getBusinessObject().getMainTable();
        if (mainTable == null) {
            return new PageResult<>(Collections.emptyList(), 0, pageRequest.getPageNum(), pageRequest.getPageSize());
        }

        // 列定义
        List<MetaListColumn> columns = metaListColumnService.listByBoCode(boCode);
        List<String> selectCols = new ArrayList<>();
        Set<String> colWhitelist = new HashSet<>(SYSTEM_ORDER_COLS);
        if (columns != null) {
            for (MetaListColumn c : columns) {
                Integer isShow = c.getIsShow();
                Integer isEnable = c.getIsEnable();
                if (c.getFieldCode() != null
                        && (isShow == null || isShow == 1)
                        && (isEnable == null || isEnable == 1)) {
                    selectCols.add("`" + c.getFieldCode() + "`");
                }
                if (c.getFieldCode() != null) {
                    colWhitelist.add(c.getFieldCode());
                }
            }
        }

        String selectSql = selectCols.isEmpty() ? "*" : String.join(", ", selectCols);

        // 查询字段配置
        List<MetaQueryField> queryFields = metaQueryFieldService.listByBoCode(boCode);
        Map<String, MetaQueryField> queryFieldMap = new HashMap<>();
        if (queryFields != null) {
            for (MetaQueryField qf : queryFields) {
                if (qf.getIsEnable() == null || qf.getIsEnable() == 1) {
                    queryFieldMap.put(qf.getFieldCode(), qf);
                }
            }
        }

        // 构建 WHERE
        List<Object> args = new ArrayList<>();
        String whereSql = buildWhere(params, queryFieldMap, args, "");

        // ORDER BY
        String orderSql = buildOrderBy(pageRequest.getOrderBy(), colWhitelist, "");

        // 分页
        int pageNum = pageRequest.getPageNum() <= 0 ? 1 : pageRequest.getPageNum();
        int pageSize = pageRequest.getPageSize() <= 0 ? 20 : pageRequest.getPageSize();
        int offset = (pageNum - 1) * pageSize;

        String query = "SELECT " + selectSql + " FROM `" + mainTable + "`"
                + (whereSql.isEmpty() ? "" : " WHERE " + whereSql)
                + (orderSql.isEmpty() ? "" : " ORDER BY " + orderSql)
                + " LIMIT ?, ?";

        List<Object> queryArgs = new ArrayList<>(args);
        queryArgs.add(offset);
        queryArgs.add(pageSize);

        List<Map<String, Object>> list = jdbcTemplate.queryForList(query, queryArgs.toArray());

        // 补充 ref 字段的名称（如 sal_org_id → sal_org_id_name = "江苏纺织"）
        if (!list.isEmpty()) {
            enrichRefNames(boCode, list);
        }

        String countSql = "SELECT COUNT(*) FROM `" + mainTable + "`"
                + (whereSql.isEmpty() ? "" : " WHERE " + whereSql);
        Long total = jdbcTemplate.queryForObject(countSql, Long.class, args.toArray());
        if (total == null) {
            total = 0L;
        }

        return new PageResult<>(list, total, pageNum, pageSize);
    }

    /**
     * 明细展开模式查询：主表 LEFT JOIN 第一个 sub 实体，按明细行展开数据。
     * 例如 sal_int_cont LEFT JOIN sal_int_cont_goods ON m.id = s.int_cont_id。
     * 主表字段直接返回原列名，子表字段以 sub_ 前缀返回（如 sub_goods_id、sub_qty）。
     */
    private PageResult<Map<String, Object>> pageExpanded(String boCode, PageRequest pageRequest, Map<String, Object> params) {
        FormMetaVO meta = formMetaCache.get(boCode);
        if (meta == null || meta.getBusinessObject() == null || meta.getEntities() == null) {
            return new PageResult<>(Collections.emptyList(), 0, pageRequest.getPageNum(), pageRequest.getPageSize());
        }
        String mainTable = meta.getBusinessObject().getMainTable();
        if (mainTable == null) {
            return new PageResult<>(Collections.emptyList(), 0, pageRequest.getPageNum(), pageRequest.getPageSize());
        }

        // 查找第一个 sub 实体（entity_type='sub' 或 entity_level=1）
        FormEntityDTO subEntity = null;
        for (FormEntityDTO e : meta.getEntities()) {
            if ("sub".equalsIgnoreCase(e.getEntityType())
                    || (e.getEntityLevel() != null && e.getEntityLevel() == 1)) {
                subEntity = e;
                break;
            }
        }
        if (subEntity == null || subEntity.getTableName() == null || subEntity.getLinkField() == null) {
            // 没有 sub 实体，降级到主表查询
            return pagePlain(boCode, pageRequest, params);
        }
        String subTable = subEntity.getTableName();
        String linkField = subEntity.getLinkField();

        // 主表 SELECT 列（带 m. 前缀）
        List<MetaListColumn> columns = metaListColumnService.listByBoCode(boCode);
        List<String> mainSelectCols = new ArrayList<>();
        Set<String> colWhitelist = new HashSet<>(SYSTEM_ORDER_COLS);
        if (columns != null) {
            for (MetaListColumn c : columns) {
                Integer isShow = c.getIsShow();
                Integer isEnable = c.getIsEnable();
                if (c.getFieldCode() != null
                        && (isShow == null || isShow == 1)
                        && (isEnable == null || isEnable == 1)) {
                    mainSelectCols.add("m.`" + c.getFieldCode() + "`");
                }
                if (c.getFieldCode() != null) {
                    colWhitelist.add(c.getFieldCode());
                }
            }
        }
        // 确保 m.id 一定被选上
        boolean hasMainId = mainSelectCols.stream().anyMatch(s -> s.equals("m.`id`"));
        if (!hasMainId) {
            mainSelectCols.add(0, "m.`id`");
        }

        // 子表 SELECT 列（带 s. 前缀，AS sub_xxx）
        List<String> subSelectCols = new ArrayList<>();
        subSelectCols.add("s.`id` AS `sub_id`");
        subSelectCols.add("s.`sort_index` AS `sub_sort_index`");
        if (subEntity.getFields() != null) {
            for (MetaFormField f : subEntity.getFields()) {
                String code = f.getFieldCode();
                if (code == null) {
                    continue;
                }
                // 跳过主键、排序字段（已单独选）、关联父表的外键
                if ("id".equals(code) || "sort_index".equals(code) || code.equals(linkField)) {
                    continue;
                }
                // 跳过隐藏字段
                if (f.getIsHidden() != null && f.getIsHidden() == 1) {
                    continue;
                }
                subSelectCols.add("s.`" + code + "` AS `sub_" + code + "`");
            }
        }

        List<String> allSelectCols = new ArrayList<>(mainSelectCols);
        allSelectCols.addAll(subSelectCols);
        String selectSql = String.join(", ", allSelectCols);

        // 查询字段配置（仅作用于主表）
        List<MetaQueryField> queryFields = metaQueryFieldService.listByBoCode(boCode);
        Map<String, MetaQueryField> queryFieldMap = new HashMap<>();
        if (queryFields != null) {
            for (MetaQueryField qf : queryFields) {
                if (qf.getIsEnable() == null || qf.getIsEnable() == 1) {
                    queryFieldMap.put(qf.getFieldCode(), qf);
                }
            }
        }

        List<Object> args = new ArrayList<>();
        String whereSql = buildWhere(params, queryFieldMap, args, "m.");
        // ORDER BY：默认按主表 id 倒序、明细行 sort_index 正序
        String orderSql = buildOrderBy(pageRequest.getOrderBy(), colWhitelist, "m.");
        if (orderSql.isEmpty()) {
            orderSql = "m.`id` DESC, s.`sort_index` ASC";
        } else {
            orderSql = orderSql + ", s.`sort_index` ASC";
        }

        int pageNum = pageRequest.getPageNum() <= 0 ? 1 : pageRequest.getPageNum();
        int pageSize = pageRequest.getPageSize() <= 0 ? 20 : pageRequest.getPageSize();
        int offset = (pageNum - 1) * pageSize;

        String query = "SELECT " + selectSql + " FROM `" + mainTable + "` m"
                + " LEFT JOIN `" + subTable + "` s ON m.`id` = s.`" + linkField + "`"
                + (whereSql.isEmpty() ? "" : " WHERE " + whereSql)
                + " ORDER BY " + orderSql
                + " LIMIT ?, ?";

        List<Object> queryArgs = new ArrayList<>(args);
        queryArgs.add(offset);
        queryArgs.add(pageSize);

        List<Map<String, Object>> list = jdbcTemplate.queryForList(query, queryArgs.toArray());
        if (!list.isEmpty()) {
            enrichRefNames(boCode, list);
        }

        // COUNT：与主查询相同的 JOIN 结构（统计展开后的行数）
        String countSql = "SELECT COUNT(*) FROM `" + mainTable + "` m"
                + " LEFT JOIN `" + subTable + "` s ON m.`id` = s.`" + linkField + "`"
                + (whereSql.isEmpty() ? "" : " WHERE " + whereSql);
        Long total = jdbcTemplate.queryForObject(countSql, Long.class, args.toArray());
        if (total == null) {
            total = 0L;
        }

        return new PageResult<>(list, total, pageNum, pageSize);
    }

    /**
     * 自动 JOIN 查询：根据列配置的 entity_code 自动 JOIN 涉及的表（主/子/孙）。
     * <p>主表别名 m，子表别名 s（多个则 s1/s2...），孙表别名 g（多个则 g1/g2...）。
     * 子表字段以 sub_ 前缀返回，孙表字段以 grand_ 前缀返回。</p>
     */
    private PageResult<Map<String, Object>> pageJoin(String boCode, PageRequest pageRequest,
                                                      Map<String, Object> params,
                                                      FormMetaVO meta, String mainTable,
                                                      List<MetaListColumn> columns,
                                                      Set<String> involvedEntityCodes) {
        Map<String, FormEntityDTO> entityMap = new HashMap<>();
        for (FormEntityDTO e : meta.getEntities()) {
            if (e.getEntityCode() != null) {
                entityMap.put(e.getEntityCode(), e);
            }
        }

        // 1. 构建实体 -> 别名映射
        Map<String, String> entityAliasMap = new LinkedHashMap<>();
        for (FormEntityDTO e : meta.getEntities()) {
            if (isMainEntity(e)) {
                entityAliasMap.put(e.getEntityCode(), "m");
                break;
            }
        }
        int subIdx = 0, grandIdx = 0;
        // 先加入 involvedEntityCodes 中的子表
        for (String ec : involvedEntityCodes) {
            FormEntityDTO e = entityMap.get(ec);
            if (e == null || isMainEntity(e) || entityAliasMap.containsKey(ec)) {
                continue;
            }
            if (e.getTableName() == null || e.getLinkField() == null) {
                continue;
            }
            if ("sub".equalsIgnoreCase(e.getEntityType()) || (e.getEntityLevel() != null && e.getEntityLevel() == 1)) {
                subIdx++;
                entityAliasMap.put(ec, subIdx == 1 ? "s" : "s" + subIdx);
            } else {
                grandIdx++;
                entityAliasMap.put(ec, grandIdx == 1 ? "g" : "g" + grandIdx);
            }
        }
        // 孙表依赖子表：如果孙表被选中但子表未选中，自动加入子表作为 JOIN 桥梁
        for (FormEntityDTO e : meta.getEntities()) {
            String ec = e.getEntityCode();
            if (isMainEntity(e) || entityAliasMap.containsKey(ec)) {
                continue;
            }
            boolean isGrand = !"sub".equalsIgnoreCase(e.getEntityType())
                    && (e.getEntityLevel() != null && e.getEntityLevel() == 2);
            if (!isGrand || !involvedEntityCodes.contains(ec)) {
                continue;
            }
            // 加入父实体（子表）
            String parentEc = e.getParentEntityCode();
            if (parentEc != null && !entityAliasMap.containsKey(parentEc)) {
                FormEntityDTO parent = entityMap.get(parentEc);
                if (parent != null && parent.getTableName() != null && parent.getLinkField() != null) {
                    subIdx++;
                    entityAliasMap.put(parentEc, subIdx == 1 ? "s" : "s" + subIdx);
                }
            }
            if (e.getTableName() != null && e.getLinkField() != null) {
                grandIdx++;
                entityAliasMap.put(ec, grandIdx == 1 ? "g" : "g" + grandIdx);
            }
        }

        // 2. 构建 SELECT 列
        List<String> selectCols = new ArrayList<>();
        Set<String> colWhitelist = new HashSet<>(SYSTEM_ORDER_COLS);
        selectCols.add("m.`id`");
        if (columns != null) {
            for (MetaListColumn col : columns) {
                Integer isShow = col.getIsShow();
                Integer isEnable = col.getIsEnable();
                if (col.getFieldCode() == null || (isShow != null && isShow != 1) || (isEnable != null && isEnable != 1)) {
                    continue;
                }
                String ec = col.getEntityCode();
                String alias = entityAliasMap.getOrDefault(ec, "m");
                String prefix = getPrefixByAlias(alias);
                if (prefix.isEmpty()) {
                    if (!"id".equals(col.getFieldCode())) {
                        selectCols.add(alias + ".`" + col.getFieldCode() + "`");
                    }
                } else {
                    selectCols.add(alias + ".`" + col.getFieldCode() + "` AS `" + prefix + col.getFieldCode() + "`");
                }
                colWhitelist.add(col.getFieldCode());
            }
        }

        // 3. 构建 JOIN 子句
        StringBuilder joinSql = new StringBuilder();
        joinSql.append(" FROM `").append(mainTable).append("` m");
        // 按实体顺序（主→子→孙）追加 JOIN
        for (FormEntityDTO e : meta.getEntities()) {
            String ec = e.getEntityCode();
            if (isMainEntity(e) || !entityAliasMap.containsKey(ec)) {
                continue;
            }
            if (e.getTableName() == null || e.getLinkField() == null) {
                continue;
            }
            String alias = entityAliasMap.get(ec);
            String parentEc = e.getParentEntityCode();
            String parentAlias = entityAliasMap.getOrDefault(parentEc, "m");
            joinSql.append(" LEFT JOIN `").append(e.getTableName()).append("` ").append(alias)
                    .append(" ON ").append(parentAlias).append(".`id` = ").append(alias).append(".`").append(e.getLinkField()).append("`");
        }

        // 4. 查询字段配置
        List<MetaQueryField> queryFields = metaQueryFieldService.listByBoCode(boCode);
        Map<String, MetaQueryField> queryFieldMap = new HashMap<>();
        if (queryFields != null) {
            for (MetaQueryField qf : queryFields) {
                if (qf.getIsEnable() == null || qf.getIsEnable() == 1) {
                    queryFieldMap.put(qf.getFieldCode(), qf);
                }
            }
        }

        // 5. 构建 WHERE（根据字段所属实体确定表别名前缀）
        List<Object> args = new ArrayList<>();
        String whereSql = buildWhereWithEntityAlias(params, queryFieldMap, args, meta, entityAliasMap);

        // 6. ORDER BY
        String orderSql = buildOrderBy(pageRequest.getOrderBy(), colWhitelist, "m.");
        if (orderSql.isEmpty()) {
            orderSql = "m.`id` DESC";
        }

        // 7. 分页
        int pageNum = pageRequest.getPageNum() <= 0 ? 1 : pageRequest.getPageNum();
        int pageSize = pageRequest.getPageSize() <= 0 ? 20 : pageRequest.getPageSize();
        int offset = (pageNum - 1) * pageSize;

        String query = "SELECT " + String.join(", ", selectCols) + joinSql
                + (whereSql.isEmpty() ? "" : " WHERE " + whereSql)
                + " ORDER BY " + orderSql
                + " LIMIT ?, ?";

        List<Object> queryArgs = new ArrayList<>(args);
        queryArgs.add(offset);
        queryArgs.add(pageSize);

        List<Map<String, Object>> list = jdbcTemplate.queryForList(query, queryArgs.toArray());
        if (!list.isEmpty()) {
            enrichRefNamesMultiEntity(list, meta, entityAliasMap);
        }

        // 8. COUNT
        String countSql = "SELECT COUNT(*)" + joinSql + (whereSql.isEmpty() ? "" : " WHERE " + whereSql);
        Long total = jdbcTemplate.queryForObject(countSql, Long.class, args.toArray());
        if (total == null) {
            total = 0L;
        }

        return new PageResult<>(list, total, pageNum, pageSize);
    }

    /** 根据表别名获取结果集中的字段前缀：m→""，s→"sub_"，g→"grand_" */
    private String getPrefixByAlias(String alias) {
        if ("m".equals(alias)) return "";
        if (alias.startsWith("s")) return "sub_";
        if (alias.startsWith("g")) return "grand_";
        return "";
    }

    /** 通过 fieldCode 查找所属实体编码（先查主表，再查子表/孙表） */
    private String findEntityCodeByFieldCode(FormMetaVO meta, String fieldCode) {
        if (meta == null || meta.getEntities() == null) return null;
        for (FormEntityDTO e : meta.getEntities()) {
            if (isMainEntity(e) && e.getFields() != null) {
                for (MetaFormField f : e.getFields()) {
                    if (fieldCode.equals(f.getFieldCode())) return e.getEntityCode();
                }
            }
        }
        for (FormEntityDTO e : meta.getEntities()) {
            if (!isMainEntity(e) && e.getFields() != null) {
                for (MetaFormField f : e.getFields()) {
                    if (fieldCode.equals(f.getFieldCode())) return e.getEntityCode();
                }
            }
        }
        return null;
    }

    /**
     * 构建 WHERE 子句（自动 JOIN 场景）：根据每个查询字段所属实体确定表别名前缀。
     */
    private String buildWhereWithEntityAlias(Map<String, Object> params,
                                              Map<String, MetaQueryField> queryFieldMap,
                                              List<Object> args, FormMetaVO meta,
                                              Map<String, String> entityAliasMap) {
        if (params == null || params.isEmpty()) return "";
        StringBuilder sb = new StringBuilder();
        for (Map.Entry<String, Object> entry : params.entrySet()) {
            String fieldCode = entry.getKey();
            Object value = entry.getValue();
            if ("expand".equals(fieldCode)) continue;

            MetaQueryField qf = queryFieldMap.get(fieldCode);
            if (qf == null) {
                // 系统字段，默认属于主表
                String sysFragment = buildSystemFieldCondition(fieldCode, value, args, "m.");
                if (sysFragment != null) {
                    if (sb.length() > 0) sb.append(" AND ");
                    sb.append(sysFragment);
                }
                continue;
            }
            String op = resolveOp(qf, value);
            if (op == null || !ALLOWED_OPS.contains(op)) continue;

            // 优先使用查询字段配置的 entityCode，为空时通过元数据查找
            String entityCode = qf.getEntityCode();
            if (entityCode == null || entityCode.isEmpty()) {
                entityCode = findEntityCodeByFieldCode(meta, fieldCode);
            }
            String alias = entityAliasMap.getOrDefault(entityCode, "m");
            String colPrefix = alias + ".";
            String fragment = buildCondition(fieldCode, op, value, args, colPrefix);
            if (fragment != null) {
                if (sb.length() > 0) sb.append(" AND ");
                sb.append(fragment);
            }
        }
        return sb.toString();
    }

    /**
     * 补充 ref 字段名称（自动 JOIN 场景）：遍历所有涉及实体的 ref 字段，
     * 主表字段 key 为 fieldCode，子表为 sub_fieldCode，孙表为 grand_fieldCode。
     */
    private void enrichRefNamesMultiEntity(List<Map<String, Object>> list, FormMetaVO meta,
                                            Map<String, String> entityAliasMap) {
        if (meta == null || meta.getEntities() == null) return;
        for (FormEntityDTO entity : meta.getEntities()) {
            String alias = entityAliasMap.get(entity.getEntityCode());
            if (alias == null || entity.getFields() == null) continue;
            String prefix = getPrefixByAlias(alias);
            for (MetaFormField field : entity.getFields()) {
                if (!"ref".equalsIgnoreCase(field.getCtrlType())) continue;
                String refBoCode = field.getRefBoCode();
                String fieldCode = field.getFieldCode();
                if (refBoCode == null || refBoCode.isEmpty() || fieldCode == null) continue;
                String resultKey = prefix.isEmpty() ? fieldCode : prefix + fieldCode;
                String nameKey = resultKey + "_name";
                enrichSingleRefFieldMulti(resultKey, nameKey, refBoCode, list);
            }
        }
    }

    /** 为单个 ref 字段补充名称（多实体场景，通过 resultKey/nameKey 精确定位） */
    private void enrichSingleRefFieldMulti(String resultKey, String nameKey, String refBoCode,
                                            List<Map<String, Object>> list) {
        Set<String> ids = new HashSet<>();
        for (Map<String, Object> row : list) {
            Object v = row.get(resultKey);
            if (v != null) {
                String s = v.toString().trim();
                if (!s.isEmpty()) ids.add(s);
            }
        }
        if (ids.isEmpty()) return;
        FormMetaVO refMeta = formMetaCache.get(refBoCode);
        if (refMeta == null || refMeta.getBusinessObject() == null) return;
        String refTable = refMeta.getBusinessObject().getMainTable();
        String nameField = resolveNameField(refMeta);
        if (refTable == null || nameField == null) return;
        Map<String, String> nameMap = batchQueryNames(refTable, nameField, ids);
        if (nameMap.isEmpty()) return;
        for (Map<String, Object> row : list) {
            Object v = row.get(resultKey);
            if (v != null) {
                String name = nameMap.get(v.toString());
                if (name != null) row.put(nameKey, name);
            }
        }
    }

    /**
     * 补充 ref 字段的显示名称。
     *
     * <p>遍历主实体的 ref 类型字段，批量查询对应主数据表的 id→name 映射，
     * 在每行数据中补充 {field_code}_name 字段。表名/列名来自元数据（可信），
     * 数据值参数化查询。</p>
     */
    private void enrichRefNames(String boCode, List<Map<String, Object>> list) {
        FormMetaVO meta = formMetaCache.get(boCode);
        if (meta == null || meta.getEntities() == null) {
            return;
        }
        // 找出主实体的 ref 字段
        for (FormEntityDTO entity : meta.getEntities()) {
            if (!isMainEntity(entity) || entity.getFields() == null) {
                continue;
            }
            for (MetaFormField field : entity.getFields()) {
                if (!"ref".equalsIgnoreCase(field.getCtrlType())) {
                    continue;
                }
                String refBoCode = field.getRefBoCode();
                String fieldCode = field.getFieldCode();
                if (refBoCode == null || refBoCode.isEmpty() || fieldCode == null) {
                    continue;
                }
                enrichSingleRefField(fieldCode, refBoCode, list);
            }
            break; // 仅处理主实体
        }
    }

    /** 判断是否为主实体 */
    private boolean isMainEntity(FormEntityDTO entity) {
        if ("MAIN".equalsIgnoreCase(entity.getEntityType())) {
            return true;
        }
        Integer level = entity.getEntityLevel();
        return level != null && level == 0;
    }

    /** 为单个 ref 字段补充名称 */
    private void enrichSingleRefField(String fieldCode, String refBoCode, List<Map<String, Object>> list) {
        // 收集该字段的所有非空 ID（统一转为字符串）
        Set<String> ids = new HashSet<>();
        for (Map<String, Object> row : list) {
            Object v = row.get(fieldCode);
            if (v != null) {
                String s = v.toString().trim();
                if (!s.isEmpty()) {
                    ids.add(s);
                }
            }
        }
        if (ids.isEmpty()) {
            return;
        }
        // 获取 ref BO 的主表名和名称字段
        FormMetaVO refMeta = formMetaCache.get(refBoCode);
        if (refMeta == null || refMeta.getBusinessObject() == null) {
            return;
        }
        String refTable = refMeta.getBusinessObject().getMainTable();
        String nameField = resolveNameField(refMeta);
        if (refTable == null || nameField == null) {
            return;
        }
        // 批量查询 id→name 映射
        Map<String, String> nameMap = batchQueryNames(refTable, nameField, ids);
        if (nameMap.isEmpty()) {
            return;
        }
        // 补充 {field}_name
        String nameKey = fieldCode + "_name";
        for (Map<String, Object> row : list) {
            Object v = row.get(fieldCode);
            if (v != null) {
                String name = nameMap.get(v.toString());
                if (name != null) {
                    row.put(nameKey, name);
                }
            }
        }
    }

    /**
     * 从 ref BO 的主实体字段元数据中解析名称字段。
     * 优先级：name > cn_name > short_name > stamp_name > item_name > code
     */
    private String resolveNameField(FormMetaVO refMeta) {
        if (refMeta.getEntities() == null) {
            return "name";
        }
        String fallback = null;
        for (FormEntityDTO entity : refMeta.getEntities()) {
            if (!isMainEntity(entity) || entity.getFields() == null) {
                continue;
            }
            for (MetaFormField f : entity.getFields()) {
                String code = f.getFieldCode();
                if ("name".equals(code)) {
                    return "name";
                }
                if (fallback == null && ("cn_name".equals(code) || "short_name".equals(code)
                        || "stamp_name".equals(code) || "item_name".equals(code))) {
                    fallback = code;
                }
            }
            if (fallback != null) {
                return fallback;
            }
            // 没有 name 类字段，用 code
            for (MetaFormField f : entity.getFields()) {
                if ("code".equals(f.getFieldCode())) {
                    return "code";
                }
            }
            break;
        }
        return "name";
    }

    /** 批量查询主数据表 id→name 映射 */
    private Map<String, String> batchQueryNames(String table, String nameField, Set<String> ids) {
        Map<String, String> result = new HashMap<>();
        if (ids.isEmpty()) {
            return result;
        }
        // nameField 回退到 code 时，尝试通过 staff_id JOIN sys_employee 获取名称
        // （sys_saler / sys_merchandiser 等表无 name 列，通过 staff_id 关联 sys_employee）
        if ("code".equals(nameField)) {
            Map<String, String> joined = tryQueryViaStaffJoin(table, ids);
            if (!joined.isEmpty()) {
                return joined;
            }
        }
        try {
            StringBuilder placeholders = new StringBuilder();
            List<Object> args = new ArrayList<>();
            int i = 0;
            for (String id : ids) {
                if (i++ > 0) {
                    placeholders.append(",");
                }
                placeholders.append("?");
                args.add(id);
            }
            String sql = "SELECT `id`, `" + nameField + "` AS `nm` FROM `" + table
                    + "` WHERE `id` IN (" + placeholders + ")";
            List<Map<String, Object>> rows = jdbcTemplate.queryForList(sql, args.toArray());
            for (Map<String, Object> row : rows) {
                Object id = row.get("id");
                Object nm = row.get("nm");
                if (id != null && nm != null) {
                    result.put(id.toString(), nm.toString());
                }
            }
        } catch (Exception e) {
            // 表不存在或列不存在时跳过（不影响主查询）
        }
        return result;
    }

    /**
     * 通过 staff_id JOIN sys_employee 获取名称。
     * 用于 sys_saler / sys_merchandiser 等无 name 列、通过 staff_id 关联员工的表。
     * 若表无 staff_id 列则返回空 Map（由调用方 fallback 到 code）。
     */
    private Map<String, String> tryQueryViaStaffJoin(String table, Set<String> ids) {
        Map<String, String> result = new HashMap<>();
        try {
            StringBuilder placeholders = new StringBuilder();
            List<Object> args = new ArrayList<>();
            int i = 0;
            for (String id : ids) {
                if (i++ > 0) {
                    placeholders.append(",");
                }
                placeholders.append("?");
                args.add(id);
            }
            String sql = "SELECT t.`id`, e.`name` AS `nm` FROM `" + table
                    + "` t LEFT JOIN `sys_employee` e ON t.`staff_id` = e.`id`"
                    + " WHERE t.`id` IN (" + placeholders + ")";
            List<Map<String, Object>> rows = jdbcTemplate.queryForList(sql, args.toArray());
            for (Map<String, Object> row : rows) {
                Object id = row.get("id");
                Object nm = row.get("nm");
                if (id != null && nm != null) {
                    result.put(id.toString(), nm.toString());
                }
            }
        } catch (Exception e) {
            // 表无 staff_id 列或其他错误，返回空 Map
        }
        return result;
    }

    /**
     * 构建参数化 WHERE 子句。仅允许查询字段配置中声明的字段参与过滤。
     *
     * @param alias 列前缀（如 "m."），用于 JOIN 场景；空串表示无前缀
     */
    @SuppressWarnings("unchecked")
    private String buildWhere(Map<String, Object> params, Map<String, MetaQueryField> queryFieldMap,
                              List<Object> args, String alias) {
        if (params == null || params.isEmpty()) {
            return "";
        }
        StringBuilder sb = new StringBuilder();
        for (Map.Entry<String, Object> entry : params.entrySet()) {
            String fieldCode = entry.getKey();
            Object value = entry.getValue();
            // expand 是控制参数，不参与 WHERE
            if ("expand".equals(fieldCode)) {
                continue;
            }
            MetaQueryField qf = queryFieldMap.get(fieldCode);
            if (qf == null) {
                // 未在查询字段配置中声明的系统字段，使用默认运算符（通用单据查询场景）
                String sysFragment = buildSystemFieldCondition(fieldCode, value, args, alias);
                if (sysFragment != null) {
                    if (sb.length() > 0) {
                        sb.append(" AND ");
                    }
                    sb.append(sysFragment);
                }
                continue;
            }
            String op = resolveOp(qf, value);
            if (op == null || !ALLOWED_OPS.contains(op)) {
                continue;
            }
            String fragment = buildCondition(fieldCode, op, value, args, alias);
            if (fragment != null) {
                if (sb.length() > 0) {
                    sb.append(" AND ");
                }
                sb.append(fragment);
            }
        }
        return sb.toString();
    }

    /**
     * 系统字段默认查询条件（无需 meta_query_field 配置）。
     * <p>支持 pact_state（eq）、code（like 模糊查）、id（eq）三个所有单据通用的系统字段。
     * 字段名经白名单硬编码，不来自用户输入，无注入风险。</p>
     *
     * @param alias 列前缀（如 "m."），用于 JOIN 场景；空串表示无前缀
     */
    private String buildSystemFieldCondition(String fieldCode, Object value, List<Object> args, String alias) {
        if (value == null) {
            return null;
        }
        String s = value.toString().trim();
        if (s.isEmpty()) {
            return null;
        }
        if ("pact_state".equals(fieldCode) || "id".equals(fieldCode)) {
            args.add(value);
            return alias + "`" + fieldCode + "` = ?";
        }
        if ("code".equals(fieldCode)) {
            args.add("%" + s + "%");
            return alias + "`code` LIKE ?";
        }
        return null;
    }

    @SuppressWarnings("unchecked")
    private String resolveOp(MetaQueryField qf, Object value) {
        String allowed = qf.getOperators();
        Set<String> allowedSet = new HashSet<>();
        if (allowed != null) {
            for (String s : allowed.split(",")) {
                String t = s.trim().toLowerCase();
                if (!t.isEmpty()) {
                    allowedSet.add(t);
                }
            }
        }
        String op = null;
        Object rawValue = value;
        if (value instanceof Map) {
            Object opObj = ((Map<String, Object>) value).get("op");
            if (opObj != null) {
                op = opObj.toString().trim().toLowerCase();
            }
            rawValue = ((Map<String, Object>) value).get("value");
        }
        if (op == null || op.isEmpty()) {
            op = qf.getDefaultOp();
            if (op != null) {
                op = op.trim().toLowerCase();
            }
        }
        if (op == null || op.isEmpty()) {
            op = "eq";
        }
        if (!allowedSet.isEmpty() && !allowedSet.contains(op)) {
            return null;
        }
        // is_null / is_not_null 不需要值；其余要求值非空
        if (!"is_null".equals(op) && !"is_not_null".equals(op)) {
            if (rawValue == null || (rawValue instanceof String && ((String) rawValue).isEmpty())) {
                return null;
            }
        }
        return op;
    }

    @SuppressWarnings("unchecked")
    private String buildCondition(String fieldCode, String op, Object value, List<Object> args, String alias) {
        String col = alias + "`" + fieldCode + "`";
        Object rawValue = value;
        if (value instanceof Map) {
            rawValue = ((Map<String, Object>) value).get("value");
        }
        switch (op) {
            case "eq":
                args.add(rawValue);
                return col + " = ?";
            case "ne":
                args.add(rawValue);
                return col + " <> ?";
            case "gt":
                args.add(rawValue);
                return col + " > ?";
            case "lt":
                args.add(rawValue);
                return col + " < ?";
            case "ge":
                args.add(rawValue);
                return col + " >= ?";
            case "le":
                args.add(rawValue);
                return col + " <= ?";
            case "like":
                args.add("%" + rawValue + "%");
                return col + " LIKE ?";
            case "not_like":
                args.add("%" + rawValue + "%");
                return col + " NOT LIKE ?";
            case "begin_with":
                args.add(rawValue + "%");
                return col + " LIKE ?";
            case "end_with":
                args.add("%" + rawValue);
                return col + " LIKE ?";
            case "is_null":
                return col + " IS NULL";
            case "is_not_null":
                return col + " IS NOT NULL";
            case "in": {
                Collection<Object> items;
                if (rawValue instanceof Collection) {
                    items = new ArrayList<>((Collection<Object>) rawValue);
                } else if (rawValue.getClass().isArray()) {
                    items = new ArrayList<>(Arrays.asList((Object[]) rawValue));
                } else {
                    items = Collections.singletonList(rawValue);
                }
                if (items.isEmpty()) {
                    return null;
                }
                StringBuilder placeholders = new StringBuilder();
                int i = 0;
                for (Object it : items) {
                    if (i++ > 0) {
                        placeholders.append(",");
                    }
                    placeholders.append("?");
                    args.add(it);
                }
                return col + " IN (" + placeholders + ")";
            }
            case "between": {
                List<Object> pair;
                if (rawValue instanceof Collection) {
                    pair = new ArrayList<>((Collection<Object>) rawValue);
                } else if (rawValue.getClass().isArray()) {
                    pair = Arrays.asList((Object[]) rawValue);
                } else {
                    return null;
                }
                if (pair.size() < 2) {
                    return null;
                }
                args.add(pair.get(0));
                args.add(pair.get(1));
                return col + " BETWEEN ? AND ?";
            }
            default:
                return null;
        }
    }

    /**
     * 构建安全 ORDER BY：仅允许白名单列名与 asc/desc 方向
     *
     * @param alias 列前缀（如 "m."），用于 JOIN 场景；空串表示无前缀
     */
    private String buildOrderBy(String orderBy, Set<String> whitelist, String alias) {
        if (orderBy == null || orderBy.trim().isEmpty()) {
            return "";
        }
        StringBuilder sb = new StringBuilder();
        for (String part : orderBy.split(",")) {
            String p = part.trim();
            if (p.isEmpty()) {
                continue;
            }
            String direction = "ASC";
            String col = p;
            int sp = p.lastIndexOf(' ');
            if (sp > 0) {
                col = p.substring(0, sp).trim();
                String dir = p.substring(sp + 1).trim().toLowerCase();
                if ("desc".equals(dir)) {
                    direction = "DESC";
                } else if (!"asc".equals(dir)) {
                    continue;
                }
            }
            if (!whitelist.contains(col)) {
                continue;
            }
            if (sb.length() > 0) {
                sb.append(", ");
            }
            sb.append(alias).append("`").append(col).append("` ").append(direction);
        }
        return sb.toString();
    }
}
