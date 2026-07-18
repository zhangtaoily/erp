package com.eerp.master.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import com.eerp.common.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

@Data
@EqualsAndHashCode(callSuper = true)
@TableName("md_color_series")
public class MdColorSeries extends BaseEntity {

    private String code;

    private Integer enabled;

    private String cnName;

    private String auditor;

    private LocalDateTime auditTime;

    private String remark;
}
