package com.eerp.meta.rule.service.impl;

import com.eerp.common.service.AbstractCrudService;
import com.eerp.meta.rule.entity.MetaEntityRule;
import com.eerp.meta.rule.mapper.MetaEntityRuleMapper;
import com.eerp.meta.rule.service.MetaEntityRuleService;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * 实体服务规则 Service 实现
 */
@Service
public class MetaEntityRuleServiceImpl
        extends AbstractCrudService<MetaEntityRuleMapper, MetaEntityRule>
        implements MetaEntityRuleService {

    @Override
    public List<MetaEntityRule> listByBoCode(String boCode) {
        return lambdaQuery()
                .eq(MetaEntityRule::getBoCode, boCode)
                .orderByAsc(MetaEntityRule::getPriority)
                .list();
    }
}
