package com.eerp.meta.enum_.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.eerp.meta.enum_.entity.MetaEnum;
import com.eerp.meta.enum_.entity.MetaEnumItem;

import java.util.List;

/**
 * 枚举 Service
 */
public interface MetaEnumService extends IService<MetaEnum> {

    /**
     * 按枚举编码查询枚举定义
     */
    MetaEnum getByCode(String enumCode);

    /**
     * 按枚举编码查询枚举项列表
     */
    List<MetaEnumItem> listItems(String enumCode);
}
