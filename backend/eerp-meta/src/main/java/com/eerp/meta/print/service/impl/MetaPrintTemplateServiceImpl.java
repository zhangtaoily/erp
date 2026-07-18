package com.eerp.meta.print.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.eerp.common.service.AbstractCrudService;
import com.eerp.meta.print.entity.MetaPrintTemplate;
import com.eerp.meta.print.mapper.MetaPrintTemplateMapper;
import com.eerp.meta.print.service.MetaPrintTemplateService;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * 打印模板元数据 Service 实现
 */
@Service
public class MetaPrintTemplateServiceImpl
        extends AbstractCrudService<MetaPrintTemplateMapper, MetaPrintTemplate>
        implements MetaPrintTemplateService {

    @Override
    public List<MetaPrintTemplate> listByBoCode(String boCode) {
        return lambdaQuery()
                .eq(MetaPrintTemplate::getBoCode, boCode)
                .eq(MetaPrintTemplate::getIsEnable, 1)
                .orderByAsc(MetaPrintTemplate::getCreateTime)
                .list();
    }

    @Override
    public MetaPrintTemplate getDefault(String boCode) {
        LambdaQueryWrapper<MetaPrintTemplate> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(MetaPrintTemplate::getBoCode, boCode)
                .eq(MetaPrintTemplate::getIsDefault, 1)
                .eq(MetaPrintTemplate::getIsEnable, 1)
                .last("LIMIT 1");
        return getOne(wrapper);
    }
}
