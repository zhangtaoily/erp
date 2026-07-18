package com.eerp.meta.code.service.impl;

import com.eerp.common.service.AbstractCrudService;
import com.eerp.meta.code.entity.MetaCodeRule;
import com.eerp.meta.code.mapper.MetaCodeRuleMapper;
import com.eerp.meta.code.service.MetaCodeRuleService;
import org.springframework.stereotype.Service;

/**
 * 编码规则 Service 实现
 */
@Service
public class MetaCodeRuleServiceImpl
        extends AbstractCrudService<MetaCodeRuleMapper, MetaCodeRule>
        implements MetaCodeRuleService {

    @Override
    public MetaCodeRule getByBoCode(String boCode) {
        return lambdaQuery()
                .eq(MetaCodeRule::getBoCode, boCode)
                .last("LIMIT 1")
                .one();
    }
}
