package com.eerp.meta.plugin.service.impl;

import com.eerp.common.service.AbstractCrudService;
import com.eerp.meta.plugin.entity.MetaFormPlugin;
import com.eerp.meta.plugin.mapper.MetaFormPluginMapper;
import com.eerp.meta.plugin.service.MetaFormPluginService;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * 表单插件 Service 实现
 */
@Service
public class MetaFormPluginServiceImpl
        extends AbstractCrudService<MetaFormPluginMapper, MetaFormPlugin>
        implements MetaFormPluginService {

    @Override
    public List<MetaFormPlugin> listByBoCode(String boCode) {
        return lambdaQuery()
                .eq(MetaFormPlugin::getBoCode, boCode)
                .eq(MetaFormPlugin::getStatus, 1)
                .orderByAsc(MetaFormPlugin::getExecOrder)
                .list();
    }
}
