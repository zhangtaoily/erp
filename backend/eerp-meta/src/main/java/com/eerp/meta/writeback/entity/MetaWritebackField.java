package com.eerp.meta.writeback.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import com.eerp.common.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * 反写字段映射
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("meta_writeback_field")
public class MetaWritebackField extends BaseEntity {

    /** 规则编码 */
    private String ruleCode;

    /** 序号 */
    private Integer itemSeq;

    /** 下游字段（如 qty） */
    private String srcField;

    /** 上游字段（如 out_qty） */
    private String targetField;

    /** 基准字段（aggregate模式用，上游的基准字段如 order_qty） */
    private String baseField;

    /** 反写表达式（如 target_field = target_field + src_field） */
    private String writebackExpr;

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
