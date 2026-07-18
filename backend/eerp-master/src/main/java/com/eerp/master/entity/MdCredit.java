package com.eerp.master.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import com.eerp.common.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * 信用额度主数据（md_credit）。
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("md_credit")
public class MdCredit extends BaseEntity {

    private String code;

    private Long orgId;

    private Integer isGroupCredit;

    private Integer custType;

    private String remark;

    private String auditor;

    private LocalDateTime auditTime;
}
