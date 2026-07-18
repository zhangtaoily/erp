package com.eerp.meta.bo.dto;

import lombok.Data;

/**
 * 业务对象 DTO（对齐前端 BusinessObject）
 */
@Data
public class BusinessObjectDTO {

    private Long id;

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

    private String createBy;

    private java.time.LocalDateTime createTime;

    private String updateBy;

    private java.time.LocalDateTime updateTime;
}
