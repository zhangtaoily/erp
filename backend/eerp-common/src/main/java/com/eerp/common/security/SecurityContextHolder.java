package com.eerp.common.security;

/**
 * 业务侧安全上下文持有者 (基于 ThreadLocal)
 */
public class SecurityContextHolder {

    private static final ThreadLocal<SecurityContext> HOLDER = new ThreadLocal<>();

    public static void set(SecurityContext context) {
        HOLDER.set(context);
    }

    public static SecurityContext get() {
        return HOLDER.get();
    }

    public static void clear() {
        HOLDER.remove();
    }
}
