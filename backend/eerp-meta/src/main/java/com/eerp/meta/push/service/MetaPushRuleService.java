package com.eerp.meta.push.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.eerp.meta.push.entity.MetaPushRule;

import java.util.List;

/**
 * 下推规则 Service
 */
public interface MetaPushRuleService extends IService<MetaPushRule> {

    /**
     * 按源业务对象编码查询下推规则列表
     */
    List<MetaPushRule> listBySrcBoCode(String srcBoCode);
}
