package com.eerp.master.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import com.eerp.common.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

@Data
@EqualsAndHashCode(callSuper = true)
@TableName("md_print_color")
public class MdPrintColor extends BaseEntity {

    private String code;

    private String cnName;

    private Integer enabled;

    private Long compColorId;

    private Long colorSysId;

    private String colorName;

    private String dyeMethodId;

    private String auditor;

    private LocalDateTime auditTime;

    private String remark;
}
