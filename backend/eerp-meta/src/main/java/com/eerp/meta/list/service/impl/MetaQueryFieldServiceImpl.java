package com.eerp.meta.list.service.impl;

import com.eerp.common.service.AbstractCrudService;
import com.eerp.meta.list.entity.MetaQueryField;
import com.eerp.meta.list.mapper.MetaQueryFieldMapper;
import com.eerp.meta.list.service.MetaQueryFieldService;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * 查询字段配置 Service 实现
 */
@Service
public class MetaQueryFieldServiceImpl
        extends AbstractCrudService<MetaQueryFieldMapper, MetaQueryField>
        implements MetaQueryFieldService {

    @Override
    public List<MetaQueryField> listByBoCode(String boCode) {
        return lambdaQuery()
                .eq(MetaQueryField::getBoCode, boCode)
                .orderByAsc(MetaQueryField::getSortIndex)
                .list();
    }
}
