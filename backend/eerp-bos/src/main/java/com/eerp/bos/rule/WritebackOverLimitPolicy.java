package com.eerp.bos.rule;

/**
 * 反写超限控制策略枚举（对齐 project_memory 硬约束 + 设计文档 08 §3.3.3 / 附录 A.2）。
 *
 * <ul>
 *   <li>BLOCK（阻断）：over_expr 返回 true（超限）→ 抛 ServiceException，事务回滚</li>
 *   <li>WARN（预警放行）：超限时记录告警日志，继续执行反写</li>
 *   <li>ALLOW（允许）：不校验 over_expr，直接执行反写</li>
 * </ul>
 */
public enum WritebackOverLimitPolicy {

    /** 阻断：超限时抛 ServiceException 回滚事务 */
    BLOCK("block"),
    /** 预警放行：超限时记录告警日志，继续反写 */
    WARN("warn"),
    /** 允许：不校验 over_expr，直接执行 */
    ALLOW("allow");

    private final String code;

    WritebackOverLimitPolicy(String code) {
        this.code = code;
    }

    public String getCode() {
        return code;
    }

    /**
     * 按 code 解析枚举（大小写不敏感）。
     *
     * @param code 策略编码（block/warn/allow）
     * @return 枚举值；未匹配返回 null
     */
    public static WritebackOverLimitPolicy fromCode(String code) {
        if (code == null) {
            return null;
        }
        String lower = code.toLowerCase();
        for (WritebackOverLimitPolicy policy : values()) {
            if (policy.code.equals(lower)) {
                return policy;
            }
        }
        return null;
    }
}
