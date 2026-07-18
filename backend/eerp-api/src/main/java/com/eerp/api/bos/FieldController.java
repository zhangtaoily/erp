package com.eerp.api.bos;

import com.eerp.common.api.Result;
import com.eerp.meta.field.entity.MetaFormField;
import com.eerp.meta.field.service.MetaFormFieldService;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class FieldController {

    private final MetaFormFieldService formFieldService;

    public FieldController(MetaFormFieldService formFieldService) {
        this.formFieldService = formFieldService;
    }

    @GetMapping("/entity/{entityCode}/fields")
    public Result<List<MetaFormField>> list(@PathVariable String entityCode) {
        return Result.ok(formFieldService.listByEntityCode(entityCode));
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

    @PostMapping("/entity/{entityCode}/fields/batch")
    public Result<Void> batchSave(@PathVariable String entityCode, @RequestBody Map<String, Object> body) {
        Object fieldsObj = body.get("fields");
        List<MetaFormField> fields = new java.util.ArrayList<>();
        if (fieldsObj instanceof List) {
            for (Object item : (List<?>) fieldsObj) {
                MetaFormField field = convert(item);
                fields.add(field);
            }
        }
        formFieldService.batchSave(entityCode, fields);
        return Result.ok();
    }

    @SuppressWarnings("unchecked")
    private MetaFormField convert(Object item) {
        if (item instanceof MetaFormField) {
            return (MetaFormField) item;
        }
        Map<String, Object> map = (Map<String, Object>) item;
        MetaFormField field = new MetaFormField();
        field.setBoCode((String) map.get("boCode"));
        field.setEntityCode((String) map.get("entityCode"));
        field.setFieldCode((String) map.get("fieldCode"));
        field.setFieldName((String) map.get("fieldName"));
        field.setFieldType((String) map.get("fieldType"));
        field.setCtrlType((String) map.get("ctrlType"));
        field.setDataType((String) map.get("dataType"));
        field.setDataLength(toInt(map.get("dataLength")));
        field.setDataPrecision(toInt(map.get("dataPrecision")));
        field.setDataScale(toInt(map.get("dataScale")));
        field.setIsRequired(toInt(map.get("isRequired")));
        field.setIsReadonly(toInt(map.get("isReadonly")));
        field.setIsHidden(toInt(map.get("isHidden")));
        field.setIsSystem(toInt(map.get("isSystem")));
        field.setDefaultValue((String) map.get("defaultValue"));
        field.setValidateRule((String) map.get("validateRule"));
        field.setRefBoCode((String) map.get("refBoCode"));
        field.setEnumCode((String) map.get("enumCode"));
        field.setFormula((String) map.get("formula"));
        field.setSummaryTo((String) map.get("summaryTo"));
        field.setGroupName((String) map.get("groupName"));
        field.setColWidth(toInt(map.get("colWidth")));
        field.setSortIndex(toInt(map.get("sortIndex")));
        field.setRemark((String) map.get("remark"));
        return field;
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
