package com.eerp.meta.layout.service.impl;

import com.eerp.common.service.AbstractCrudService;
import com.eerp.meta.layout.entity.MetaFormLayout;
import com.eerp.meta.layout.mapper.MetaFormLayoutMapper;
import com.eerp.meta.layout.service.MetaFormLayoutService;
import org.springframework.stereotype.Service;

/**
 * 表单布局 Service 实现
 */
@Service
public class MetaFormLayoutServiceImpl
        extends AbstractCrudService<MetaFormLayoutMapper, MetaFormLayout>
        implements MetaFormLayoutService {

    @Override
    public MetaFormLayout getDefault(String boCode) {
        return lambdaQuery()
                .eq(MetaFormLayout::getBoCode, boCode)
                .eq(MetaFormLayout::getIsDefault, 1)
                .last("LIMIT 1")
                .one();
    }
}
