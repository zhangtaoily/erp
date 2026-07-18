package com.eerp.master.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import com.eerp.common.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

@Data
@EqualsAndHashCode(callSuper = true)
@TableName("md_comp_color")
public class MdCompColor extends BaseEntity {

    private String code;

    private Long colorSysId;

    private String cnName;

    private Integer isAbYarn;

    private String colorName;

    private Integer enabled;

    private String auditor;

    private LocalDateTime auditTime;

    private String remark;
}
