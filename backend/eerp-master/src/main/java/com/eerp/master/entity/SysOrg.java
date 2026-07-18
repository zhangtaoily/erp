package com.eerp.master.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import com.eerp.common.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 组织主数据实体（对应表 sys_org，树形结构，bo_code=MD_ORG）。
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("sys_org")
public class SysOrg extends BaseEntity {

    private String code;

    private String name;

    private String orgType;

    private Long parentId;

    private Integer isAccounting;

    private Integer isBusiness;

    private Long baseCurrId;

    private String taxNo;

    private String address;

    private Integer status;

    private Integer sortIndex;

    private String logo;
}
