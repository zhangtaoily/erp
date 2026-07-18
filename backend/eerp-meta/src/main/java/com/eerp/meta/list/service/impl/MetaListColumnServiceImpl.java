package com.eerp.meta.list.service.impl;

import com.eerp.common.service.AbstractCrudService;
import com.eerp.meta.list.entity.MetaListColumn;
import com.eerp.meta.list.mapper.MetaListColumnMapper;
import com.eerp.meta.list.service.MetaListColumnService;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * 列表列定义 Service 实现
 */
@Service
public class MetaListColumnServiceImpl
        extends AbstractCrudService<MetaListColumnMapper, MetaListColumn>
        implements MetaListColumnService {

    @Override
    public List<MetaListColumn> listByBoCode(String boCode) {
        return lambdaQuery()
                .eq(MetaListColumn::getBoCode, boCode)
                .orderByAsc(MetaListColumn::getSortIndex)
                .list();
    }
}
