package com.eerp.meta.enum_.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.eerp.common.service.AbstractCrudService;
import com.eerp.meta.enum_.entity.MetaEnum;
import com.eerp.meta.enum_.entity.MetaEnumItem;
import com.eerp.meta.enum_.mapper.MetaEnumMapper;
import com.eerp.meta.enum_.mapper.MetaEnumItemMapper;
import com.eerp.meta.enum_.service.MetaEnumService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * 枚举 Service 实现
 */
@Service
public class MetaEnumServiceImpl
        extends AbstractCrudService<MetaEnumMapper, MetaEnum>
        implements MetaEnumService {

    @Autowired
    private MetaEnumItemMapper metaEnumItemMapper;

    @Override
    public MetaEnum getByCode(String enumCode) {
        return lambdaQuery().eq(MetaEnum::getEnumCode, enumCode).last("LIMIT 1").one();
    }

    @Override
    public List<MetaEnumItem> listItems(String enumCode) {
        return metaEnumItemMapper.selectList(
                new LambdaQueryWrapper<MetaEnumItem>()
                        .eq(MetaEnumItem::getEnumCode, enumCode)
                        .orderByAsc(MetaEnumItem::getSortIndex)
        );
    }
}
