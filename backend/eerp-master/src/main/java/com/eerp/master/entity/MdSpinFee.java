package com.eerp.master.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import com.eerp.common.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * 纺纱工费主数据（md_spin_fee）。
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("md_spin_fee")
public class MdSpinFee extends BaseEntity {

    private String code;

    private String remark;

    private String auditor;

    private LocalDateTime auditTime;
}
