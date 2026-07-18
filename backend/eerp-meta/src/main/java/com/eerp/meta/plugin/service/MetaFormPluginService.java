package com.eerp.meta.plugin.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.eerp.meta.plugin.entity.MetaFormPlugin;

import java.util.List;

/**
 * 表单插件 Service
 */
public interface MetaFormPluginService extends IService<MetaFormPlugin> {

    /**
     * 按业务对象编码查询插件列表
     */
    List<MetaFormPlugin> listByBoCode(String boCode);
}
