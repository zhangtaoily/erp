package com.eerp.api.sys.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import com.eerp.common.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDate;

@Data
@EqualsAndHashCode(callSuper = true)
@TableName("sys_user_org")
public class SysUserOrg extends BaseEntity {

    private Long userId;

    private Long orgId;

    /** 是否主组织（0否 1是） */
    private Integer isMain;

    private LocalDate effDate;

    private LocalDate expDate;
}
