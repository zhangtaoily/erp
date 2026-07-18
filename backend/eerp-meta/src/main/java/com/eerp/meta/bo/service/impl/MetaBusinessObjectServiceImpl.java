package com.eerp.meta.bo.service.impl;

import com.eerp.common.service.AbstractCrudService;
import com.eerp.meta.bo.entity.MetaBusinessObject;
import com.eerp.meta.bo.mapper.MetaBusinessObjectMapper;
import com.eerp.meta.bo.service.MetaBusinessObjectService;
import org.springframework.stereotype.Service;

/**
 * 业务对象 Service 实现
 */
@Service
public class MetaBusinessObjectServiceImpl
        extends AbstractCrudService<MetaBusinessObjectMapper, MetaBusinessObject>
        implements MetaBusinessObjectService {

    @Override
    public MetaBusinessObject getByBoCode(String boCode) {
        return baseMapper.getByBoCode(boCode);
    }
}
