package com.eerp.meta.field.service.impl;

import com.eerp.common.service.AbstractCrudService;
import com.eerp.meta.field.entity.MetaFormField;
import com.eerp.meta.field.mapper.MetaFormFieldMapper;
import com.eerp.meta.field.service.MetaFormFieldService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * 表单字段 Service 实现
 */
@Service
public class MetaFormFieldServiceImpl
        extends AbstractCrudService<MetaFormFieldMapper, MetaFormField>
        implements MetaFormFieldService {

    @Override
    public List<MetaFormField> listByBoAndEntity(String boCode, String entityCode) {
        return lambdaQuery()
                .eq(MetaFormField::getBoCode, boCode)
                .eq(MetaFormField::getEntityCode, entityCode)
                .orderByAsc(MetaFormField::getSortIndex)
                .list();
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void batchSave(String boCode, String entityCode, List<MetaFormField> fields) {
        // 先清除该 BO + 实体下既有字段
        lambdaUpdate()
                .eq(MetaFormField::getBoCode, boCode)
                .eq(MetaFormField::getEntityCode, entityCode)
                .remove();
        if (fields == null || fields.isEmpty()) {
            return;
        }
        // 统一归属到指定 BO + 实体
        fields.forEach(f -> {
            f.setBoCode(boCode);
            f.setEntityCode(entityCode);
        });
        saveBatch(fields);
    }
}
