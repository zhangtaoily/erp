package com.eerp.meta.rule.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import com.eerp.common.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * 实体服务规则条目
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("meta_entity_rule_item")
public class MetaEntityRuleItem extends BaseEntity {

    /** 规则编码 */
    private String ruleCode;

    /** 条目序号 */
    private Integer itemSeq;

    /** 条件表达式（calc/available可空） */
    private String conditionExpr;

    /** 动作表达式（赋值/校验/联动，ANTLR4解析） */
    private String actionExpr;

    /** 校验失败提示信息 */
    private String errorMsg;

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
