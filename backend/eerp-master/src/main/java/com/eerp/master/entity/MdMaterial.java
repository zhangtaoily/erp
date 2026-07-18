package com.eerp.master.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import com.eerp.common.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.math.BigDecimal;

/**
 * 物料主数据（md_material）。
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("md_material")
public class MdMaterial extends BaseEntity {

    private String code;

    private String name;

    private String nameEn;

    private String spec;

    private String matType;

    private BigDecimal yarnCount;

    private BigDecimal strand;

    private String yarnType;

    private String twist;

    private String fineness;

    private String color;

    private Long unitId;

    private String weightType;

    private BigDecimal ctWeight;

    private Integer batchFlag;

    private Integer vatFlag;

    private Integer shelfLife;

    private BigDecimal taxRate;

    private BigDecimal stdCost;

    private Integer purchaseFlag;

    private Integer saleFlag;

    private Integer produceFlag;

    private String barcode;

    private String dyeMethod;

    private String prdType;

    private String yarnProc;

    private String twistDirection;

    private String rawMaterialDetail;

    private String customsNo;

    private String customsName;

    private BigDecimal raFee;

    private BigDecimal paRate;

    private BigDecimal sFee;

    private BigDecimal saleRate;

    private String stockType;

    private Long matGpId;

    private String matProp;

    private BigDecimal prdRate;

    private Integer isNewyarn;

    private String matIndex;

    private Integer isInventory;

    private Integer isSubContract;

    private Integer isCheck;

    private Integer isMainPrd;

    private String remark;

    /** 状态（1启用 0停用） */
    private Integer status;
}
