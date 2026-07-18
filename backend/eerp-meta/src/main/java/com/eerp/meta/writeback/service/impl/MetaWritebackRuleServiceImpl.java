package com.eerp.meta.writeback.service.impl;

import com.eerp.common.service.AbstractCrudService;
import com.eerp.meta.writeback.entity.MetaWritebackRule;
import com.eerp.meta.writeback.mapper.MetaWritebackRuleMapper;
import com.eerp.meta.writeback.service.MetaWritebackRuleService;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * 反写规则 Service 实现
 */
@Service
public class MetaWritebackRuleServiceImpl
        extends AbstractCrudService<MetaWritebackRuleMapper, MetaWritebackRule>
        implements MetaWritebackRuleService {

    @Override
    public List<MetaWritebackRule> listBySrcBillType(String srcBillType) {
        return lambdaQuery()
                .eq(MetaWritebackRule::getSrcBillType, srcBillType)
                .eq(MetaWritebackRule::getIsEnabled, 1)
                .list();
    }
}
