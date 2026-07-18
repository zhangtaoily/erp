package com.eerp.master.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import com.eerp.common.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * 信用额度明细子表（md_credit_detail）。
 *
 * <p>该表无审计字段，排除 createBy/createTime/updateBy/updateTime 映射。</p>
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("md_credit_detail")
public class MdCreditDetail extends BaseEntity {

    private Integer sortIndex;

    private Long creditId;

    private Long custId;

    private Long currId;

    private BigDecimal amount;

    private String amountStatus;

    private LocalDate validTime;

    private String creditStatus;

    private Integer overdueDays;

    private String remark;

    @TableField(exist = false)
    private String createBy;

    @TableField(exist = false)
    private LocalDateTime createTime;

    @TableField(exist = false)
    private String updateBy;

    @TableField(exist = false)
    private LocalDateTime updateTime;
}
