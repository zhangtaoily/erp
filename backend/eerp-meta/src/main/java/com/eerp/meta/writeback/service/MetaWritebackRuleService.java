package com.eerp.meta.writeback.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.eerp.meta.writeback.entity.MetaWritebackRule;

import java.util.List;

/**
 * 反写规则 Service
 */
public interface MetaWritebackRuleService extends IService<MetaWritebackRule> {

    /**
     * 按下游源单类型查询反写规则列表
     */
    List<MetaWritebackRule> listBySrcBillType(String srcBillType);
}
