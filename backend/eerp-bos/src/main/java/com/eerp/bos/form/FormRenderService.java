package com.eerp.bos.form;

import com.eerp.bos.bill.BillDataAccessor;
import com.eerp.meta.bo.vo.FormMetaVO;
import com.eerp.meta.entity.dto.FormEntityDTO;
import com.eerp.meta.field.entity.MetaFormField;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 表单渲染服务：按模式（新增/查看/编辑）组装表单渲染数据
 */
@Service
public class FormRenderService {

    @Autowired
    private FormMetaServiceImpl formMetaService;

    @Autowired
    private BillDataAccessor billDataAccessor;

    /**
     * 新增模式：返回空数据 + 字段默认值
     */
    public Map<String, Object> renderForNew(String boCode) {
        FormMetaVO meta = formMetaService.getFormMeta(boCode);
        Map<String, Object> result = new LinkedHashMap<>();
        if (meta == null) {
            result.put("entities", new ArrayList<>());
            result.put("data", emptyData());
            result.put("mode", "add");
            return result;
        }

        result.put("entities", meta.getEntities());
        result.put("layout", meta.getLayout());
        result.put("data", buildNewData(meta));
        result.put("mode", "add");
        return result;
    }

    /**
     * 查看模式：从数据库加载完整单据数据
     */
    public Map<String, Object> renderForView(String boCode, Long billId) {
        return renderForEdit(boCode, billId, "view");
    }

    /**
     * 编辑模式：从数据库加载完整单据数据
     */
    public Map<String, Object> renderForEdit(String boCode, Long billId) {
        return renderForEdit(boCode, billId, "edit");
    }

    private Map<String, Object> renderForEdit(String boCode, Long billId, String mode) {
        FormMetaVO meta = formMetaService.getFormMeta(boCode);
        Map<String, Object> result = new LinkedHashMap<>();
        if (meta == null) {
            result.put("entities", new ArrayList<>());
            result.put("data", emptyData());
            result.put("mode", mode);
            return result;
        }
        result.put("entities", meta.getEntities());
        result.put("layout", meta.getLayout());
        result.put("data", billDataAccessor.loadBill(boCode, billId));
        result.put("mode", mode);
        return result;
    }

    /**
     * 构建新增模式数据：主表填充字段默认值，子表为空数组
     */
    private Map<String, Object> buildNewData(FormMetaVO meta) {
        Map<String, Object> data = new LinkedHashMap<>();
        Map<String, Object> main = new LinkedHashMap<>();
        Map<String, Object> subs = new LinkedHashMap<>();

        List<FormEntityDTO> entities = meta.getEntities();
        if (entities != null) {
            for (FormEntityDTO entity : entities) {
                if ("MAIN".equalsIgnoreCase(entity.getEntityType())
                        || (entity.getEntityLevel() != null && entity.getEntityLevel() == 0)) {
                    // 主表：填充默认值
                    if (entity.getFields() != null) {
                        for (MetaFormField field : entity.getFields()) {
                            applyDefaultValue(main, field);
                        }
                    }
                } else {
                    // 子表/孙表：新增模式默认空数组
                    subs.put(entity.getEntityCode(), new ArrayList<>());
                }
            }
        }
        data.put("main", main);
        data.put("subs", subs);
        return data;
    }

    /**
     * 填充字段默认值。支持 TODAY（当天日期）与固定字面量
     */
    private void applyDefaultValue(Map<String, Object> main, MetaFormField field) {
        String defaultValue = field.getDefaultValue();
        if (defaultValue == null || defaultValue.trim().isEmpty()) {
            return;
        }
        String code = field.getFieldCode();
        if (code == null || code.isEmpty()) {
            return;
        }
        String trimmed = defaultValue.trim();
        if ("TODAY".equalsIgnoreCase(trimmed)) {
            main.put(code, LocalDate.now().toString());
            return;
        }
        main.put(code, trimmed);
    }

    private Map<String, Object> emptyData() {
        Map<String, Object> data = new HashMap<>();
        data.put("main", new HashMap<>());
        data.put("subs", new HashMap<>());
        return data;
    }
}
