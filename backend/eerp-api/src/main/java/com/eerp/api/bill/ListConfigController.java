package com.eerp.api.bill;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.eerp.common.api.Result;
import com.eerp.meta.list.entity.MetaListColumn;
import com.eerp.meta.list.entity.MetaQueryField;
import com.eerp.meta.list.service.MetaListColumnService;
import com.eerp.meta.list.service.MetaQueryFieldService;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/bo")
public class ListConfigController {

    private final MetaListColumnService listColumnService;
    private final MetaQueryFieldService queryFieldService;

    public ListConfigController(MetaListColumnService listColumnService, MetaQueryFieldService queryFieldService) {
        this.listColumnService = listColumnService;
        this.queryFieldService = queryFieldService;
    }

    @GetMapping("/{boCode}/columns")
    public Result<List<MetaListColumn>> columns(@PathVariable String boCode) {
        return Result.ok(listColumnService.listByBoCode(boCode));
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
        return Result.ok(queryFieldService.listByBoCode(boCode));
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
        column.setFieldCode((String) map.get("fieldCode"));
        column.setFieldName((String) map.get("fieldName"));
        column.setEntityCode((String) map.get("entityCode"));
        column.setCtrlType((String) map.get("ctrlType"));
        column.setIsShow(toInt(map.get("isShow")));
        column.setIsFixed((String) map.get("isFixed"));
        column.setIsSum(toInt(map.get("isSum")));
        column.setIsAvg(toInt(map.get("isAvg")));
        column.setColWidth(toInt(map.get("colWidth")));
        column.setSortIndex(toInt(map.get("sortIndex")));
        column.setIsEnable(toInt(map.get("isEnable")));
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
        field.setFieldCode((String) map.get("fieldCode"));
        field.setFieldName((String) map.get("fieldName"));
        field.setIsCommon(toInt(map.get("isCommon")));
        field.setIsAdvanced(toInt(map.get("isAdvanced")));
        field.setOperators((String) map.get("operators"));
        field.setDefaultOp((String) map.get("defaultOp"));
        field.setSortIndex(toInt(map.get("sortIndex")));
        field.setIsEnable(toInt(map.get("isEnable")));
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
