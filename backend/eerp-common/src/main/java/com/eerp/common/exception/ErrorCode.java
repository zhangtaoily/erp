package com.eerp.common.exception;

import lombok.Getter;

/**
 * 错误码枚举
 */
@Getter
public enum ErrorCode {

    SUCCESS("0"),
    BO_NOT_FOUND("BO_001"),
    BO_STATE_INVALID("STATE_001"),
    PLUGIN_BLOCKED("PLUGIN_001"),
    RULE_EVAL_FAIL("RULE_001"),
    WB_OVER_LIMIT("WB_001"),
    PERM_DENIED("PERM_001"),
    PERM_NO_BUTTON("PERM_002"),
    VALIDATE_FAIL("VAL_001"),
    UNAUTHORIZED("AUTH_001"),
    SYSTEM_ERROR("SYS_500");

    private final String code;

    ErrorCode(String code) {
        this.code = code;
    }
}
