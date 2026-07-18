package com.eerp.meta.statemachine.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import com.eerp.common.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * 状态机定义
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("meta_state_machine")
public class MetaStateMachine extends BaseEntity {

    /** 状态机编码（唯一） */
    private String code;

    /** 状态机名称 */
    private String name;

    /** 状态字段名 */
    private String stateField;

    /** 备注 */
    private String remark;

    /** 该表无审计字段，排除映射 */
    @TableField(exist = false)
    private String createBy;

    @TableField(exist = false)
    private LocalDateTime createTime;

    @TableField(exist = false)
    private String updateBy;

    @TableField(exist = false)
    private LocalDateTime updateTime;
}
