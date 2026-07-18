package com.eerp.api.sys.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import com.eerp.common.domain.BaseEntity;
import com.fasterxml.jackson.annotation.JsonIgnore;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

@Data
@EqualsAndHashCode(callSuper = true)
@TableName("sys_user")
public class SysUser extends BaseEntity {

    private String username;

    @JsonIgnore
    private String password;

    private String realName;

    private Long empId;

    private Long orgId;

    private Long deptId;

    private String email;

    private String phone;

    /** 状态（1启用 0停用） */
    private Integer status;

    private LocalDateTime lastLoginTime;

    private LocalDateTime pwdUpdateTime;

    private Integer failCount;
}
