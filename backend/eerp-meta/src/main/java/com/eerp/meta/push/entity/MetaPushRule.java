package com.eerp.meta.push.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import com.eerp.common.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * 下推转换规则
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("meta_push_rule")
public class MetaPushRule extends BaseEntity {

    /** 规则编码（唯一） */
    private String ruleCode;

    /** 规则名称 */
    private String ruleName;

    /** 源业务对象编码 */
    private String srcBoCode;

    /** 目标业务对象编码 */
    private String tgtBoCode;

    /** 字段映射JSON（src_field/target_field/is_main主表或子表/transform_expr） */
    private String fieldMappingJson;

    /** 可下推量校验表达式（如 F.qty - F.out_qty > 0） */
    private String vpCheckExpr;

    /** 过滤条件表达式（如 F.pact_state == 3 AND F.is_closed == 0） */
    private String filterExpr;

    /** 可下推数量字段 */
    private String qtyField;

    /** 已下推量回写字段 */
    private String pushedField;

    /** 是否允许合并下推（多源单→一目标单） */
    private Integer allowMerge;

    /** 是否允许拆分下推（一源单行→多目标单） */
    private Integer allowSplit;

    /** 是否启用 */
    private Integer isEnable;

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
