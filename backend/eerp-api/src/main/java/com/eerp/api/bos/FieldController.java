package com.eerp.api.bos;

import com.eerp.common.api.Result;
import com.eerp.meta.field.entity.MetaFormField;
import com.eerp.meta.field.service.MetaFormFieldService;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * 表单字段元数据接口
 * <p>entity_code 在不同 bo_code 下可能重复（如 SAL_INT_CONT 和 SAL_QUOTE 都有 goods 子表），
 * 所有接口必须用 bo_code + entity_code 联合定位，避免数据串号。</p>
 */
@RestController
@RequestMapping("/api")
public class FieldController {

    private final MetaFormFieldService formFieldService;

    public FieldController(MetaFormFieldService formFieldService) {
        this.formFieldService = formFieldService;
    }

    /**
     * 查询指定业务对象 + 实体下的字段列表
     */
    @GetMapping("/bo/{boCode}/entity/{entityCode}/fields")
    public Result<List<MetaFormField>> list(@PathVariable String boCode,
                                            @PathVariable String entityCode) {
        return Result.ok(formFieldService.listByBoAndEntity(boCode, entityCode));
    }

    @PostMapping("/field")
    public Result<MetaFormField> create(@RequestBody MetaFormField data) {
        formFieldService.save(data);
        return Result.ok(data);
    }

    @PutMapping("/field/{id}")
    public Result<MetaFormField> update(@PathVariable Long id, @RequestBody MetaFormField data) {
        data.setId(id);
        formFieldService.updateById(data);
        return Result.ok(data);
    }

    @DeleteMapping("/field/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        formFieldService.removeById(id);
        return Result.ok();
    }

    /**
     * 批量保存字段（先删后插，按 bo_code + entity_code 联合定位）
     */
    @PostMapping("/bo/{boCode}/entity/{entityCode}/fields/batch")
    public Result<Void> batchSave(@PathVariable String boCode,
                                  @PathVariable String entityCode,
                                  @RequestBody Map<String, Object> body) {
        Object fieldsObj = body.get("fields");
        List<MetaFormField> fields = new java.util.ArrayList<>();
        if (fieldsObj instanceof List) {
            for (Object item : (List<?>) fieldsObj) {
                MetaFormField field = convert(item);
                fields.add(field);
            }
        }
        formFieldService.batchSave(boCode, entityCode, fields);
        return Result.ok();
    }

    @SuppressWarnings("unchecked")
    private MetaFormField convert(Object item) {
        if (item instanceof MetaFormField) {
            return (MetaFormField) item;
        }
        Map<String, Object> map = (Map<String, Object>) item;
        MetaFormField field = new MetaFormField();
        // 兼容 snake_case / camelCase 键名（前端 toSnakeKeys 后发送 snake_case）
        field.setBoCode(str(map, "bo_code", "boCode"));
        field.setEntityCode(str(map, "entity_code", "entityCode"));
        field.setFieldCode(str(map, "field_code", "fieldCode"));
        field.setFieldName(str(map, "field_name", "fieldName"));
        field.setFieldType(str(map, "field_type", "fieldType"));
        field.setCtrlType(str(map, "ctrl_type", "ctrlType"));
        field.setDataType(str(map, "data_type", "dataType"));
        field.setDataLength(toInt(first(map, "data_length", "dataLength")));
        field.setDataPrecision(toInt(first(map, "data_precision", "dataPrecision")));
        field.setDataScale(toInt(first(map, "data_scale", "dataScale")));
        field.setIsRequired(toInt(first(map, "is_required", "isRequired")));
        field.setIsReadonly(toInt(first(map, "is_readonly", "isReadonly")));
        field.setIsHidden(toInt(first(map, "is_hidden", "isHidden")));
        field.setIsSystem(toInt(first(map, "is_system", "isSystem")));
        field.setDefaultValue(str(map, "default_value", "defaultValue"));
        field.setValidateRule(str(map, "validate_rule", "validateRule"));
        field.setRefBoCode(str(map, "ref_bo_code", "refBoCode"));
        field.setEnumCode(str(map, "enum_code", "enumCode"));
        field.setFormula(str(map, "formula", "formula"));
        field.setSummaryTo(str(map, "summary_to", "summaryTo"));
        field.setLinkFrom(str(map, "link_from", "linkFrom"));
        field.setGroupName(str(map, "group_name", "groupName"));
        field.setColWidth(toInt(first(map, "col_width", "colWidth")));
        field.setSortIndex(toInt(first(map, "sort_index", "sortIndex")));
        field.setRemark(str(map, "remark", "remark"));
        return field;
    }

    private String str(Map<String, Object> map, String snake, String camel) {
        Object v = map.get(snake);
        if (v == null) v = map.get(camel);
        return v == null ? null : v.toString();
    }

    private Object first(Map<String, Object> map, String snake, String camel) {
        Object v = map.get(snake);
        return v != null ? v : map.get(camel);
    }

    private Integer toInt(Object v) {
        if (v == null) {
            return null;
        }
        // 处理前端 el-switch 返回的 Boolean（true/false）
        if (v instanceof Boolean) {
            return ((Boolean) v) ? 1 : 0;
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
