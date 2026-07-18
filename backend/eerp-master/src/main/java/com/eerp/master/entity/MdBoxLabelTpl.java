package com.eerp.master.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import com.eerp.common.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

@Data
@EqualsAndHashCode(callSuper = true)
@TableName("md_box_label_tpl")
public class MdBoxLabelTpl extends BaseEntity {

    private String code;

    private String cnName;

    private String enName;

    private Long orgId;

    private Integer isEnPrint;

    private Integer enabled;

    private String remark;

    private String auditor;

    private LocalDateTime auditTime;
}
