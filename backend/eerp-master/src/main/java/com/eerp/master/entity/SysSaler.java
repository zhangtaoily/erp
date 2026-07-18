package com.eerp.master.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import com.eerp.common.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * 销售员主数据实体（对应表 sys_saler，平铺结构，bo_code=MD_SALER）。
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("sys_saler")
public class SysSaler extends BaseEntity {

    private String code;

    private Long staffId;

    private Long deptId;

    private Integer isCalBizFee;

    private Integer enabled;

    private String auditor;

    private LocalDateTime auditTime;

    private String remark;
}
