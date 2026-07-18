package com.eerp.meta.rule.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.eerp.meta.rule.entity.MetaEntityRule;

import java.util.List;

/**
 * 实体服务规则 Service
 */
public interface MetaEntityRuleService extends IService<MetaEntityRule> {

    /**
     * 按业务对象编码查询规则列表
     */
    List<MetaEntityRule> listByBoCode(String boCode);
}
