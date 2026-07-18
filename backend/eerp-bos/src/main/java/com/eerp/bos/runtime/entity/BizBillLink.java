package com.eerp.bos.runtime.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import com.eerp.common.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 单据上下游关联记录，对应表 biz_bill_link。
 *
 * <p>下推时由 {@code AbstractPushService} 写入，联查时由 {@code AbstractBillLinkService.buildTraceTree}
 * 递归构建上下游追溯树（对齐设计文档 02 §3.6 / §5.3.2）。</p>
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("biz_bill_link")
public class BizBillLink extends BaseEntity {

    /** 源业务对象编码 */
    private String srcBoCode;

    /** 目标业务对象编码 */
    private String tgtBoCode;

    /** 源单据ID */
    private Long srcBillId;

    /** 目标单据ID */
    private Long tgtBillId;

    /** 源行ID */
    private Long srcLineId;

    /** 目标行ID */
    private Long tgtLineId;

    /** 关联数量 */
    private BigDecimal linkQty;

    /** 转换规则编码 */
    private String pushRuleCode;

    /** 该表无审计字段，排除映射 */
    @TableField(exist = false)
    private String createBy;

    @TableField(exist = false)
    private LocalDateTime createTime;

    @TableField(exist = false)
    private String updateBy;

    @TableField(exist = false)
    private LocalDateTime updateTime;
}
