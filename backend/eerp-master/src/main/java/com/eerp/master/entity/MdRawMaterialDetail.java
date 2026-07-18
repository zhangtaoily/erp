package com.eerp.master.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import com.eerp.common.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 原料明细子表（md_raw_material_detail）。
 *
 * <p>该表无审计字段，排除 createBy/createTime/updateBy/updateTime 映射。</p>
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("md_raw_material_detail")
public class MdRawMaterialDetail extends BaseEntity {

    private Integer sortIndex;

    private Long rawMatId;

    private Long matId;

    private BigDecimal ratio;

    private String prdAddrCode;

    private String prdAddrName;

    private String authType;

    private String fineness;

    private String cnComp;

    private String enComp;

    private BigDecimal yarnNum;

    private BigDecimal lineNum;

    private String fiberCode;

    private String fiberName;

    private BigDecimal fiberRatio;

    private String prdArea;

    private String remark;

    @TableField(exist = false)
    private String createBy;

    @TableField(exist = false)
    private LocalDateTime createTime;

    @TableField(exist = false)
    private String updateBy;

    @TableField(exist = false)
    private LocalDateTime updateTime;
}
