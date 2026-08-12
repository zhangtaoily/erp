package com.eerp.bos.rule;

/**
 * 反写模式枚举（对齐 project_memory 硬约束 + 设计文档 08 §3.3.2 / 附录 A.1）。
 *
 * <ul>
 *   <li>ADD（累加）：审核 apply = target + src；撤销 revert = target - src</li>
 *   <li>SUBTRACT（扣减）：审核 apply = target - src；撤销 revert = target + src</li>
 *   <li>COVER（覆盖）：审核 apply = src；撤销不反向（状态类字段保持覆盖值）</li>
 *   <li>AGGREGATE（聚合重算）：target = base_field - SUM(所有关联下游记录 src_field)</li>
 * </ul>
 */
public enum WritebackMode {

    /** 累加：target += src */
    ADD("add", "累加"),
    /** 扣减：target -= src */
    SUBTRACT("subtract", "扣减"),
    /** 覆盖：target = src（撤销不反向） */
    COVER("cover", "覆盖"),
    /** 聚合重算：target = base_field - SUM(关联下游记录)，幂等，多次保存不重复扣减 */
    AGGREGATE("aggregate", "聚合重算");

    private final String code;
    private final String desc;

    WritebackMode(String code, String desc) {
        this.code = code;
        this.desc = desc;
    }

    public String getCode() {
        return code;
    }

    public String getDesc() {
        return desc;
    }

    /**
     * 按 code 解析枚举（大小写不敏感）。
     *
     * @param code 模式编码（add/subtract/cover）
     * @return 枚举值；未匹配返回 null
     */
    public static WritebackMode fromCode(String code) {
        if (code == null) {
            return null;
        }
        String lower = code.toLowerCase();
        for (WritebackMode mode : values()) {
            if (mode.code.equals(lower)) {
                return mode;
            }
        }
        return null;
    }

    /**
     * 正向计算（save/audit 等正向操作 apply）。
     *
     * @param targetVal 目标当前值
     * @param srcVal    源单据值
     * @return 计算后的新值
     */
    public Number compute(Number targetVal, Number srcVal) {
        double t = targetVal == null ? 0d : targetVal.doubleValue();
        double s = srcVal == null ? 0d : srcVal.doubleValue();
        switch (this) {
            case ADD:
                return t + s;
            case SUBTRACT:
                return t - s;
            case COVER:
                return s;
            case AGGREGATE:
                // aggregate 模式由 doAggregateWriteback 独立处理，不走 compute
                return t;
            default:
                return t;
        }
    }

    /**
     * 反向计算（delete/cancel/revoke 等反向操作 revert）。
     * <p>ADD 反向 = 扣减（还回）；SUBTRACT 反向 = 累加（还回）；COVER 反向 = 不变（状态类字段保持）。</p>
     *
     * @param targetVal 目标当前值
     * @param srcVal    源单据值
     * @return 计算后的新值
     */
    public Number revert(Number targetVal, Number srcVal) {
        double t = targetVal == null ? 0d : targetVal.doubleValue();
        double s = srcVal == null ? 0d : srcVal.doubleValue();
        switch (this) {
            case ADD:
                return t - s;
            case SUBTRACT:
                return t + s;
            case COVER:
                return t;
            case AGGREGATE:
                // aggregate 模式由 doAggregateWriteback 独立处理，不走 revert
                return t;
            default:
                return t;
        }
    }

    /**
     * 判断操作是否为反向操作（delete/cancel/revoke/unclose/uncancel）。
     * <p>反向操作自动使用 {@link #revert} 计算还回值，正向操作使用 {@link #compute}。</p>
     */
    public static boolean isReverseOperation(String operation) {
        if (operation == null) {
            return false;
        }
        String op = operation.toLowerCase();
        return "delete".equals(op) || "cancel".equals(op) || "revoke".equals(op)
                || "unclose".equals(op) || "uncancel".equals(op) || "reject".equals(op);
    }
}
