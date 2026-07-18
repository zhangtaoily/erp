package com.eerp.bos.button;

/**
 * 按钮可用性档位（4 档）
 * 严格度排序：HIDDEN > DISABLED > READONLY > ENABLED
 */
public enum ButtonLevel {

    /** 可用 */
    ENABLED("enabled", "可用"),
    /** 禁用 */
    DISABLED("disabled", "禁用"),
    /** 隐藏 */
    HIDDEN("hidden", "隐藏"),
    /** 只读 */
    READONLY("readonly", "只读");

    private final String code;
    private final String label;

    ButtonLevel(String code, String label) {
        this.code = code;
        this.label = label;
    }

    public String getCode() {
        return code;
    }

    public String getLabel() {
        return label;
    }

    /**
     * 按 code 解析档位，未知或 null 默认返回 ENABLED
     */
    public static ButtonLevel fromCode(String code) {
        if (code == null) {
            return ENABLED;
        }
        String trimmed = code.trim().toLowerCase();
        for (ButtonLevel level : values()) {
            if (level.code.equals(trimmed)) {
                return level;
            }
        }
        return ENABLED;
    }

    /**
     * 取两个档位中「更严」的档位（HIDDEN > DISABLED > READONLY > ENABLED）
     */
    public static ButtonLevel strictest(ButtonLevel a, ButtonLevel b) {
        if (a == null) {
            return b;
        }
        if (b == null) {
            return a;
        }
        return severity(a) >= severity(b) ? a : b;
    }

    /**
     * 取两个档位中「更宽松」的档位（ENABLED > READONLY > DISABLED > HIDDEN）
     * 用于多角色合并：任一角色授予更高档位即生效（标准 RBAC）
     */
    public static ButtonLevel mostPermissive(ButtonLevel a, ButtonLevel b) {
        if (a == null) {
            return b;
        }
        if (b == null) {
            return a;
        }
        return severity(a) <= severity(b) ? a : b;
    }

    /**
     * 档位严格度数值：HIDDEN=3, DISABLED=2, READONLY=1, ENABLED=0
     */
    private static int severity(ButtonLevel level) {
        switch (level) {
            case HIDDEN:
                return 3;
            case DISABLED:
                return 2;
            case READONLY:
                return 1;
            case ENABLED:
            default:
                return 0;
        }
    }
}
