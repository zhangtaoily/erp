package com.eerp.master.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import com.eerp.common.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * 仓库主数据实体（对应表 md_warehouse，平铺结构，bo_code=MD_WAREHOUSE）。
 *
 * <p>注意：md_warehouse 表无 create_by/create_time/update_by/update_time 列，
 * 故对继承自 BaseEntity 的审计字段标注 @TableField(exist = false)。</p>
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("md_warehouse")
public class MdWarehouse extends BaseEntity {

    private String code;

    private String name;

    private Long orgId;

    private String whType;

    private Integer batchFlag;

    private Long managerId;

    private String address;

    private Integer status;

    @TableField(exist = false)
    private String createBy;

    @TableField(exist = false)
    private LocalDateTime createTime;

    @TableField(exist = false)
    private String updateBy;

    @TableField(exist = false)
    private LocalDateTime updateTime;
}
