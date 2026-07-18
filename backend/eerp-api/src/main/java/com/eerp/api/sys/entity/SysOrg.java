package com.eerp.api.sys.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import com.eerp.common.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

@Data
@EqualsAndHashCode(callSuper = true)
@TableName("sys_org")
public class SysOrg extends BaseEntity {

    private String code;

    private String name;

    /** 组织类型（group集团/company公司/factory工厂/workshop车间/business事业部） */
    private String orgType;

    private Long parentId;

    private Integer isAccounting;

    private Integer isBusiness;

    private Long baseCurrId;

    private String taxNo;

    private String address;

    /** 状态（1启用 0停用） */
    private Integer status;

    private Integer sortIndex;

    private String logo;
}
