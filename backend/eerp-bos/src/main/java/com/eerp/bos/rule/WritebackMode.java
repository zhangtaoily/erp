package com.eerp.bos.rule;

/**
 * 反写模式枚举（对齐 project_memory 硬约束 + 设计文档 08 §3.3.2 / 附录 A.1）。
 *
 * <ul>
 *   <li>ADD（累加）：审核 apply = target + src；撤销 revert = target - src</li>
 *   <li>SUBTRACT（扣减）：审核 apply = target - src；撤销 revert = target + src</li>
 *   <li>COVER（覆盖）：审核 apply = src；撤销不反向（状态类字段保持覆盖值）</li>
 * </ul>
 */
public enum WritebackMode {

    /** 累加：target += src */
    ADD("add", "累加"),
    /** 扣减：target -= src */
    SUBTRACT("subtract", "扣减"),
    /** 覆盖：target = src（撤销不反向） */
    COVER("cover", "覆盖");

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
     * 正向计算（审核 apply）。
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
            default:
                return t;
        }
    }
}
