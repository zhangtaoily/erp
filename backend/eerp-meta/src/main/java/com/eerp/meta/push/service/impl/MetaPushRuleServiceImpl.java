package com.eerp.meta.push.service.impl;

import com.eerp.common.service.AbstractCrudService;
import com.eerp.meta.push.entity.MetaPushRule;
import com.eerp.meta.push.mapper.MetaPushRuleMapper;
import com.eerp.meta.push.service.MetaPushRuleService;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * 下推规则 Service 实现
 */
@Service
public class MetaPushRuleServiceImpl
        extends AbstractCrudService<MetaPushRuleMapper, MetaPushRule>
        implements MetaPushRuleService {

    @Override
    public List<MetaPushRule> listBySrcBoCode(String srcBoCode) {
        return lambdaQuery()
                .eq(MetaPushRule::getSrcBoCode, srcBoCode)
                .eq(MetaPushRule::getIsEnable, 1)
                .list();
    }
}
