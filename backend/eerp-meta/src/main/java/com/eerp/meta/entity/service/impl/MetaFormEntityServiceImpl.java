package com.eerp.meta.entity.service.impl;

import com.eerp.common.service.AbstractCrudService;
import com.eerp.meta.entity.entity.MetaFormEntity;
import com.eerp.meta.entity.mapper.MetaFormEntityMapper;
import com.eerp.meta.entity.service.MetaFormEntityService;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * 表单实体 Service 实现
 */
@Service
public class MetaFormEntityServiceImpl
        extends AbstractCrudService<MetaFormEntityMapper, MetaFormEntity>
        implements MetaFormEntityService {

    @Override
    public List<MetaFormEntity> listByBoCode(String boCode) {
        return lambdaQuery()
                .eq(MetaFormEntity::getBoCode, boCode)
                .orderByAsc(MetaFormEntity::getSortIndex)
                .list();
    }
}
