package com.eerp.master.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import com.eerp.common.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * 部门主数据实体（对应表 sys_dept，树形结构，bo_code=MD_DEPT）。
 *
 * <p>注意：sys_dept 表无 create_by/create_time/update_by/update_time 列，
 * 故对继承自 BaseEntity 的审计字段标注 @TableField(exist = false)。</p>
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("sys_dept")
public class SysDept extends BaseEntity {

    private String code;

    private String name;

    private Long orgId;

    private Long parentId;

    private String deptType;

    private Long managerId;

    private Integer status;

    private Integer sortIndex;

    @TableField(exist = false)
    private String createBy;

    @TableField(exist = false)
    private LocalDateTime createTime;

    @TableField(exist = false)
    private String updateBy;

    @TableField(exist = false)
    private LocalDateTime updateTime;
}
