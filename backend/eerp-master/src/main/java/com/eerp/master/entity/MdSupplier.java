package com.eerp.master.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import com.eerp.common.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * 供应商主数据（md_supplier）。
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("md_supplier")
public class MdSupplier extends BaseEntity {

    private String code;

    private String name;

    private String nameEn;

    private String shortName;

    private String supType;

    private Long currId;

    private Long purOrgId;

    private Long purchaserId;

    private BigDecimal taxRate;

    private String taxNo;

    private String firpType;

    private String payType;

    private Integer isAgri;

    private String creditLevel;

    private String contact;

    private String phone;

    private String fax;

    private String email;

    private String address;

    private String bankName;

    private String bankAccount;

    private BigDecimal onTimeRate;

    private BigDecimal passRate;

    private BigDecimal evalScore;

    private String evalLevel;

    private LocalDate evalDate;

    /** 状态（1启用 0停用） */
    private Integer status;
}
