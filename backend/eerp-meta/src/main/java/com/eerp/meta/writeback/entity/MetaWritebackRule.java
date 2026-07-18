package com.eerp.meta.writeback.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import com.eerp.common.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 反写规则定义（下游反写上游执行量）
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("meta_writeback_rule")
public class MetaWritebackRule extends BaseEntity {

    /** 规则编码（唯一） */
    private String ruleCode;

    /** 规则名称 */
    private String ruleName;

    /** 下游源单类型（如 sal_outstock） */
    private String srcBillType;

    /** 上游目标单类型（如 sal_order） */
    private String targetBillType;

    /** 触发操作：audit审核/cancel撤销 */
    private String triggerOp;

    /** 源单关联字段（下游单据行字段，如 src_order_goods_id） */
    private String srcLinkField;

    /** 目标单关联字段（上游单据行字段，如 id） */
    private String targetLinkField;

    /** 反写模式：add累加/subtract扣减/cover覆盖 */
    private String writebackMode;

    /** 超限控制：block阻断/warn预警放行/allow允许 */
    private String overControl;

    /** 执行模式：SYNC同步事务内/ASYNC异步事务后（对齐设计文档 08 §5.6，默认 SYNC） */
    private String execMode;

    /** 超限校验表达式（如 target.out_qty + src.qty <= target.order_qty） */
    private String overExpr;

    /** 反写条件（满足才反写） */
    private String conditionExpr;

    /** 是否级联反写上级：0否 1是 */
    private Integer cascade;

    /** 启用状态：0停用 1启用 */
    private Integer isEnabled;

    /** 备注 */
    private String remark;
}
