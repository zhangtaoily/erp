package com.eerp.meta.code.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.eerp.meta.code.entity.MetaCodeRule;

/**
 * 编码规则 Service
 */
public interface MetaCodeRuleService extends IService<MetaCodeRule> {

    /**
     * 按业务对象编码查询编码规则
     */
    MetaCodeRule getByBoCode(String boCode);
}
