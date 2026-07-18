package com.eerp.master.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import com.eerp.common.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 纺纱工费-原料明细子表（md_spin_fee_raw_material）。
 *
 * <p>该表无审计字段，排除 createBy/createTime/updateBy/updateTime 映射。</p>
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("md_spin_fee_raw_material")
public class MdSpinFeeRawMaterial extends BaseEntity {

    private Integer sortIndex;

    private Long spinFeeId;

    private Long rawMatId;

    private BigDecimal sFee;

    @TableField(exist = false)
    private String createBy;

    @TableField(exist = false)
    private LocalDateTime createTime;

    @TableField(exist = false)
    private String updateBy;

    @TableField(exist = false)
    private LocalDateTime updateTime;
}
