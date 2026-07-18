package com.eerp.master.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import com.eerp.common.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 原料主数据（md_raw_material）。
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("md_raw_material")
public class MdRawMaterial extends BaseEntity {

    private String code;

    private String name;

    private String cnName;

    private String enName;

    private String fineness;

    private BigDecimal sFee;

    private BigDecimal damp;

    private String prdName;

    private BigDecimal cmRate;

    private BigDecimal lossRate;

    private BigDecimal woolRate;

    private BigDecimal bulkRate;

    private String productType;

    private String description;

    private BigDecimal recombRate;

    private String customsName;

    private Long groupId;

    private Integer enabled;

    private String spinType;

    private String recombType;

    private String prdArea;

    private String remark;

    private String auditor;

    private LocalDateTime auditTime;
}
