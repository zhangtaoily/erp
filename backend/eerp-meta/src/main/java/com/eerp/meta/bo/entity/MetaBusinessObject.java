package com.eerp.meta.bo.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import com.eerp.common.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * BOS 业务对象定义（动态领域建模入口）
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("meta_business_object")
public class MetaBusinessObject extends BaseEntity {

    /** 业务对象编码（全局唯一，如 SAL_ORDER） */
    private String boCode;

    /** 业务对象名称（如 销售订单） */
    private String boName;

    /** 类型：bill单据/master基础资料/report报表 */
    private String boType;

    /** 主表物理表名（如 sal_order） */
    private String mainTable;

    /** 主键字段名 */
    private String mainKey;

    /** 主键策略：auto自增/snowflake雪花/uuid */
    private String pkStrategy;

    /** 是否支持状态机（0否 1是） */
    private Integer isStateful;

    /** 是否支持下推（0否 1是） */
    private Integer isPushable;

    /** 是否支持打印（0否 1是） */
    private Integer isPrintable;

    /** 适用组织类型（group/company/factory/workshop/business） */
    private String orgType;

    /** 状态：0停用 1启用 */
    private Integer status;

    /** 备注 */
    private String remark;
}
