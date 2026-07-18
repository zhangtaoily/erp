package com.eerp.meta.code.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import com.eerp.common.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * 编码流水记录（并发安全）
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("meta_code_serial")
public class MetaCodeSerial extends BaseEntity {

    /** 规则编码 */
    private String ruleCode;

    /** 组织ID（按组织+年重置时使用） */
    private Long orgId;

    /** 周期标识（如 2026 / 202607 / 2026_001） */
    private String period;

    /** 当前流水值 */
    private Long currentSerial;

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
