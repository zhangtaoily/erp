package com.eerp.master.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import com.eerp.common.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * 纺纱工费-物料明细子表（md_spin_fee_material）。
 *
 * <p>该表无审计字段，排除 createBy/createTime/updateBy/updateTime 映射。</p>
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("md_spin_fee_material")
public class MdSpinFeeMaterial extends BaseEntity {

    private Integer sortIndex;

    private Long spinFeeId;

    private Long matId;

    @TableField(exist = false)
    private String createBy;

    @TableField(exist = false)
    private LocalDateTime createTime;

    @TableField(exist = false)
    private String updateBy;

    @TableField(exist = false)
    private LocalDateTime updateTime;
}
