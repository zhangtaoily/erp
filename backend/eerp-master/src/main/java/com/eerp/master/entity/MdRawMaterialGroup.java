package com.eerp.master.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import com.eerp.common.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * 原料分组树形主数据（md_raw_material_group）。
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("md_raw_material_group")
public class MdRawMaterialGroup extends BaseEntity {

    private String code;

    private Long parentId;

    private Integer enabled;

    private String cnName;

    private String enName;

    private String auditor;

    private LocalDateTime auditTime;

    private String remark;
}
