package com.eerp.meta.list.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.eerp.meta.list.entity.MetaQueryField;

import java.util.List;

/**
 * 查询字段配置 Service
 */
public interface MetaQueryFieldService extends IService<MetaQueryField> {

    /**
     * 按业务对象编码查询查询字段列表
     */
    List<MetaQueryField> listByBoCode(String boCode);
}
