package com.eerp.meta.field.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.eerp.meta.field.entity.MetaFormField;

import java.util.List;

/**
 * 表单字段 Service
 */
public interface MetaFormFieldService extends IService<MetaFormField> {

    /**
     * 按业务对象 + 实体编码查询字段列表
     * <p>entity_code 在不同 bo_code 下可能重复（如多个业务对象都有 goods 子表），
     * 必须用 bo_code + entity_code 联合定位。</p>
     */
    List<MetaFormField> listByBoAndEntity(String boCode, String entityCode);

    /**
     * 批量保存实体字段（先删后插，按 bo_code + entity_code 联合定位）
     */
    void batchSave(String boCode, String entityCode, List<MetaFormField> fields);
}
