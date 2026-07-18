package com.eerp.master.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import com.eerp.common.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDate;

/**
 * 员工主数据实体（对应表 sys_employee，平铺结构，bo_code=MD_EMPLOYEE）。
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("sys_employee")
public class SysEmployee extends BaseEntity {

    private String code;

    private String name;

    private Long orgId;

    private Long deptId;

    private String position;

    private Integer gender;

    private LocalDate entryDate;

    private Integer isSaler;

    private Integer isPurchaser;

    private Long userId;

    private String mobile;

    private String email;

    private Long managerId;

    private LocalDate birthday;

    private LocalDate departureDate;

    private Integer employeeRank;

    private Integer active;

    private String remark;

    private Integer status;
}
