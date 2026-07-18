package com.eerp.master.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import com.eerp.common.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.math.BigDecimal;

@Data
@EqualsAndHashCode(callSuper = true)
@TableName("md_hl_card")
public class MdHlCard extends BaseEntity {

    private String code;

    private String name;

    private Long matId;

    private BigDecimal yarnCount;

    private BigDecimal strand;

    private String twist;

    private String fineness;

    private Long colorId;

    private String craftDesc;

    private String cnName;

    private String enName;

    private String spReq;

    private BigDecimal spPrice;

    private String remark;

    private Integer status;
}
