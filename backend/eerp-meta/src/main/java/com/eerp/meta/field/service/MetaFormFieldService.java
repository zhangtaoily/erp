package com.eerp.meta.field.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.eerp.meta.field.entity.MetaFormField;

import java.util.List;

/**
 * 表单字段 Service
 */
public interface MetaFormFieldService extends IService<MetaFormField> {

    /**
     * 按实体编码查询字段列表
     */
    List<MetaFormField> listByEntityCode(String entityCode);

    /**
     * 批量保存实体字段（先删后插）
     */
    void batchSave(String entityCode, List<MetaFormField> fields);
}
