package com.eerp.master.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import com.eerp.common.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * 客户主数据（md_customer）。
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("md_customer")
public class MdCustomer extends BaseEntity {

    private String code;

    private String name;

    private String nameEn;

    private String shortName;

    private String custType;

    private String tradeType;

    private Long currId;

    private Long salOrgId;

    private Long salerId;

    private BigDecimal creditLimit;

    private Integer creditPeriod;

    private BigDecimal taxRate;

    private String taxNo;

    private String firpType;

    private String recType;

    private String contact;

    private String phone;

    private String fax;

    private String email;

    private String address;

    private String addressEn;

    private String harbourEnd;

    private String bankName;

    private String bankAccount;

    private BigDecimal creditBalance;

    private Integer isCreditCheck;

    private LocalDate creditExpiry;

    private String creditLevel;

    private String creditStatus;

    private String arPeriod;

    private Integer overdueDays;

    private Long groupCustId;

    private Long custGpId;

    private Integer isGpCust;

    private String legalPerson;

    private BigDecimal regCapital;

    private String compNature;

    private String compSize;

    private LocalDate compDate;

    private String industry;

    private String country;

    private String province;

    private String region;

    private String postCode;

    private String invTitle;

    private String invType;

    private String prodInvName;

    private String attm;

    private Integer allowSale;

    private Integer allowTrust;

    private Integer allowPurchase;

    private Integer allowOutsource;

    private String remark;

    /** 状态（1启用 0停用） */
    private Integer status;
}
