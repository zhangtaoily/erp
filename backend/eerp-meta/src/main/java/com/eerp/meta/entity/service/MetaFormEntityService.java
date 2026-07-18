package com.eerp.meta.entity.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.eerp.meta.entity.entity.MetaFormEntity;

import java.util.List;

/**
 * 表单实体 Service
 */
public interface MetaFormEntityService extends IService<MetaFormEntity> {

    /**
     * 按业务对象编码查询实体列表
     */
    List<MetaFormEntity> listByBoCode(String boCode);
}
