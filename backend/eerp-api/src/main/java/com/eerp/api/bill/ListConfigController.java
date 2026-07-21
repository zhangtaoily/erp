package com.eerp.api.bill;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.eerp.common.api.Result;
import com.eerp.meta.bo.vo.FormMetaVO;
import com.eerp.meta.cache.FormMetaCache;
import com.eerp.meta.entity.dto.FormEntityDTO;
import com.eerp.meta.field.entity.MetaFormField;
import com.eerp.meta.list.entity.MetaListColumn;
import com.eerp.meta.list.entity.MetaQueryField;
import com.eerp.meta.list.service.MetaListColumnService;
import com.eerp.meta.list.service.MetaQueryFieldService;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/bo")
public class ListConfigController {

    private final MetaListColumnService listColumnService;
    private final MetaQueryFieldService queryFieldService;
    private final FormMetaCache formMetaCache;

    public ListConfigController(MetaListColumnService listColumnService,
                                MetaQueryFieldService queryFieldService,
                                FormMetaCache formMetaCache) {
        this.listColumnService = listColumnService;
        this.queryFieldService = queryFieldService;
        this.formMetaCache = formMetaCache;
    }

    @GetMapping("/{boCode}/columns")
    public Result<List<MetaListColumn>> columns(@PathVariable String boCode) {
        List<MetaListColumn> columns = listColumnService.listByBoCode(boCode);
        if (columns == null || columns.isEmpty()) {
            // 兜底：从实体元数据（主实体字段）自动生成默认列配置
            columns = buildDefaultColumns(boCode);
        }
        return Result.ok(columns);
    }

    @PutMapping("/{boCode}/columns")
    public Result<Void> saveColumns(@PathVariable String boCode, @RequestBody Map<String, Object> body) {
        LambdaQueryWrapper<MetaListColumn> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(MetaListColumn::getBoCode, boCode);
        listColumnService.remove(wrapper);
        Object columnsObj = body.get("columns");
        if (columnsObj instanceof List) {
            for (Object item : (List<?>) columnsObj) {
                MetaListColumn column = convertColumn(item, boCode);
                listColumnService.save(column);
            }
        }
        return Result.ok();
    }

    @GetMapping("/{boCode}/query-fields")
    public Result<List<MetaQueryField>> queryFields(@PathVariable String boCode) {
        List<MetaQueryField> fields = queryFieldService.listByBoCode(boCode);
        if (fields == null || fields.isEmpty()) {
            // 兜底：从实体元数据（主实体字段）自动生成默认查询字段配置
            fields = buildDefaultQueryFields(boCode);
        }
        return Result.ok(fields);
    }

    @PutMapping("/{boCode}/query-fields")
    public Result<Void> saveQueryFields(@PathVariable String boCode, @RequestBody Map<String, Object> body) {
        LambdaQueryWrapper<MetaQueryField> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(MetaQueryField::getBoCode, boCode);
        queryFieldService.remove(wrapper);
        Object fieldsObj = body.get("fields");
        if (fieldsObj instanceof List) {
            for (Object item : (List<?>) fieldsObj) {
                MetaQueryField field = convertQueryField(item, boCode);
                queryFieldService.save(field);
            }
        }
        return Result.ok();
    }

    /**
     * 兜底：从所有实体（主/子/孙）字段元数据生成默认列表列配置。
     * 仅用于 meta_list_column 表无配置时，让用户在配置页面能看到所有字段。
     * 主表字段默认显示，子表/孙表字段默认不显示（用户可手动勾选）。
     */
    private List<MetaListColumn> buildDefaultColumns(String boCode) {
        List<MetaListColumn> result = new ArrayList<>();
        FormMetaVO meta = formMetaCache.get(boCode);
        if (meta == null || meta.getEntities() == null) {
            return result;
        }
        int sortIndex = 1;
        for (FormEntityDTO entity : meta.getEntities()) {
            if (entity.getFields() == null) {
                continue;
            }
            boolean isMain = isMainEntity(entity);
            for (MetaFormField f : entity.getFields()) {
                if (f.getFieldCode() == null) {
                    continue;
                }
                MetaListColumn col = new MetaListColumn();
                col.setBoCode(boCode);
                col.setFieldCode(f.getFieldCode());
                col.setFieldName(f.getFieldName());
                col.setEntityCode(entity.getEntityCode());
                col.setCtrlType(f.getCtrlType());
                int isHidden = f.getIsHidden() == null ? 0 : f.getIsHidden();
                int isSystem = f.getIsSystem() == null ? 0 : f.getIsSystem();
                // 主表：默认显示非隐藏非系统字段；子表/孙表：默认不显示
                col.setIsShow(isMain && isHidden == 0 && isSystem == 0 ? 1 : 0);
                col.setIsFixed("none");
                col.setIsSum(0);
                col.setIsAvg(0);
                col.setColWidth(140);
                col.setSortIndex(sortIndex++);
                col.setIsEnable(1);
                result.add(col);
            }
        }
        return result;
    }

    /**
     * 兜底：从所有实体（主/子/孙）字段元数据生成默认查询字段配置。
     * 仅主表的 code / pact_state 默认为常用查询字段。
     */
    private List<MetaQueryField> buildDefaultQueryFields(String boCode) {
        List<MetaQueryField> result = new ArrayList<>();
        FormMetaVO meta = formMetaCache.get(boCode);
        if (meta == null || meta.getEntities() == null) {
            return result;
        }
        int sortIndex = 1;
        for (FormEntityDTO entity : meta.getEntities()) {
            if (entity.getFields() == null) {
                continue;
            }
            boolean isMain = isMainEntity(entity);
            for (MetaFormField f : entity.getFields()) {
                if (f.getFieldCode() == null) {
                    continue;
                }
                String code = f.getFieldCode();
                // 仅主表的 code / pact_state 默认为常用查询字段
                boolean isCommon = isMain && ("code".equals(code) || "pact_state".equals(code));
                MetaQueryField qf = new MetaQueryField();
                qf.setBoCode(boCode);
                qf.setFieldCode(code);
                qf.setFieldName(f.getFieldName());
                qf.setEntityCode(entity.getEntityCode());
                qf.setIsCommon(isCommon ? 1 : 0);
                qf.setIsAdvanced(0);
                if ("code".equals(code)) {
                    qf.setOperators("like,eq");
                    qf.setDefaultOp("like");
                } else if ("pact_state".equals(code)) {
                    qf.setOperators("eq");
                    qf.setDefaultOp("eq");
                } else {
                    qf.setOperators("eq,like");
                    qf.setDefaultOp("eq");
                }
                qf.setSortIndex(sortIndex++);
                qf.setIsEnable(1);
                result.add(qf);
            }
        }
        return result;
    }

    /** 判断是否为主实体 */
    private boolean isMainEntity(FormEntityDTO entity) {
        if ("MAIN".equalsIgnoreCase(entity.getEntityType())) {
            return true;
        }
        Integer level = entity.getEntityLevel();
        return level != null && level == 0;
    }

    @SuppressWarnings("unchecked")
    private MetaListColumn convertColumn(Object item, String boCode) {
        if (item instanceof MetaListColumn) {
            MetaListColumn c = (MetaListColumn) item;
            c.setBoCode(boCode);
            c.setId(null);
            return c;
        }
        Map<String, Object> map = (Map<String, Object>) item;
        MetaListColumn column = new MetaListColumn();
        column.setBoCode(boCode);
        // 前端发送 snake_case 键，同时兼容 camelCase
        column.setFieldCode(str(map, "field_code", "fieldCode"));
        column.setFieldName(str(map, "field_name", "fieldName"));
        column.setEntityCode(str(map, "entity_code", "entityCode"));
        column.setCtrlType(str(map, "ctrl_type", "ctrlType"));
        column.setIsShow(toInt(map.get("is_show") != null ? map.get("is_show") : map.get("isShow")));
        column.setIsFixed(str(map, "is_fixed", "isFixed"));
        column.setIsSum(toInt(map.get("is_sum") != null ? map.get("is_sum") : map.get("isSum")));
        column.setIsAvg(toInt(map.get("is_avg") != null ? map.get("is_avg") : map.get("isAvg")));
        column.setColWidth(toInt(map.get("col_width") != null ? map.get("col_width") : map.get("colWidth")));
        column.setSortIndex(toInt(map.get("sort_index") != null ? map.get("sort_index") : map.get("sortIndex")));
        column.setIsEnable(toInt(map.get("is_enable") != null ? map.get("is_enable") : map.get("isEnable")));
        return column;
    }

    @SuppressWarnings("unchecked")
    private MetaQueryField convertQueryField(Object item, String boCode) {
        if (item instanceof MetaQueryField) {
            MetaQueryField f = (MetaQueryField) item;
            f.setBoCode(boCode);
            f.setId(null);
            return f;
        }
        Map<String, Object> map = (Map<String, Object>) item;
        MetaQueryField field = new MetaQueryField();
        field.setBoCode(boCode);
        field.setFieldCode(str(map, "field_code", "fieldCode"));
        field.setFieldName(str(map, "field_name", "fieldName"));
        field.setEntityCode(str(map, "entity_code", "entityCode"));
        field.setIsCommon(toInt(map.get("is_common") != null ? map.get("is_common") : map.get("isCommon")));
        field.setIsAdvanced(toInt(map.get("is_advanced") != null ? map.get("is_advanced") : map.get("isAdvanced")));
        field.setOperators(str(map, "operators", "operators"));
        field.setDefaultOp(str(map, "default_op", "defaultOp"));
        field.setSortIndex(toInt(map.get("sort_index") != null ? map.get("sort_index") : map.get("sortIndex")));
        field.setIsEnable(toInt(map.get("is_enable") != null ? map.get("is_enable") : map.get("isEnable")));
        return field;
    }

    /** 兼容 snake_case / camelCase 取字符串值 */
    private String str(Map<String, Object> map, String snakeKey, String camelKey) {
        Object v = map.get(snakeKey);
        if (v == null) {
            v = map.get(camelKey);
        }
        return v == null ? null : v.toString();
    }

    private Integer toInt(Object v) {
        if (v == null) {
            return null;
        }
        if (v instanceof Number) {
            return ((Number) v).intValue();
        }
        try {
            return Integer.parseInt(v.toString().trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }
}
