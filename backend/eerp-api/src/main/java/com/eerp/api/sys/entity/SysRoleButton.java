package com.eerp.api.sys.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import com.eerp.common.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

@Data
@EqualsAndHashCode(callSuper = true)
@TableName("sys_role_button")
public class SysRoleButton extends BaseEntity {

    private Long roleId;

    private String boCode;

    private String buttonCode;

    /** 控制级别：enabled可用/disabled禁用/hidden隐藏/readonly只读 */
    private String controlLevel;

    @TableField(exist = false)
    private String createBy;

    @TableField(exist = false)
    private LocalDateTime createTime;

    @TableField(exist = false)
    private String updateBy;

    @TableField(exist = false)
    private LocalDateTime updateTime;
}
