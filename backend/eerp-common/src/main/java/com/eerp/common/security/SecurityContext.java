package com.eerp.common.security;

import lombok.Data;

import java.util.List;

/**
 * 安全上下文数据 (业务侧持有的当前用户信息)
 */
@Data
public class SecurityContext {

    private Long userId;

    private String userName;

    private Long orgId;

    private String orgName;

    private Long deptId;

    private List<Long> roleIds;

    private Long currentOrgId;
}
