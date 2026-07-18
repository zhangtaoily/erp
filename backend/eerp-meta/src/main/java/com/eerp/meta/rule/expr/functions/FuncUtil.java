package com.eerp.meta.rule.expr.functions;

import com.eerp.meta.rule.expr.ExprException;

import java.util.Collections;
import java.util.List;

/**
 * 内置函数公共工具：类型转换、参数校验等。
 *
 * <p>由各内置函数实现类与 {@link com.eerp.meta.rule.expr.ExprAstVisitor} 共享使用，
 * 统一数字 / 布尔 / 列表的语义转换。</p>
 */
public final class FuncUtil {

    private FuncUtil() {
    }

    /** 转为布尔（null-&gt;false，Number 非 0-&gt;true，String "true"/"false"/非空） */
    public static boolean toBool(Object o) {
        if (o == null) {
            return false;
        }
        if (o instanceof Boolean) {
            return (Boolean) o;
        }
        if (o instanceof Number) {
            return ((Number) o).doubleValue() != 0d;
        }
        if (o instanceof String) {
            String s = (String) o;
            if ("true".equalsIgnoreCase(s)) {
                return true;
            }
            if ("false".equalsIgnoreCase(s)) {
                return false;
            }
            return !s.isEmpty();
        }
        return true;
    }

    /** 转为 Number；字符串数字、布尔也支持；null 返回 null */
    public static Number toNumber(Object o) {
        if (o == null) {
            return null;
        }
        if (o instanceof Number) {
            return (Number) o;
        }
        if (o instanceof Boolean) {
            return ((Boolean) o) ? 1 : 0;
        }
        if (o instanceof String) {
            String s = (String) o;
            try {
                if (s.contains(".") || s.contains("e") || s.contains("E")) {
                    return Double.valueOf(s);
                }
                long v = Long.parseLong(s);
                if (v >= Integer.MIN_VALUE && v <= Integer.MAX_VALUE) {
                    return Integer.valueOf((int) v);
                }
                return Long.valueOf(v);
            } catch (NumberFormatException e) {
                throw new ExprException("EXPR_EVAL_ERROR", "无法将字符串转为数字: " + s);
            }
        }
        throw new ExprException("EXPR_EVAL_ERROR", "无法转为数字: " + o);
    }

    /** 转为 double（null 视为 0） */
    public static double toDouble(Object o) {
        Number n = toNumber(o);
        return n == null ? 0d : n.doubleValue();
    }

    /** 是否整型数字（Integer/Long） */
    public static boolean isIntegerNumber(Object o) {
        return o instanceof Integer || o instanceof Long;
    }

    /** 转为 List；null-&gt;空列表；List 直接返回；单值包成单元素列表 */
    @SuppressWarnings("unchecked")
    public static List<Object> asList(Object o) {
        if (o == null) {
            return Collections.emptyList();
        }
        if (o instanceof List) {
            return (List<Object>) o;
        }
        return Collections.singletonList(o);
    }

    /** 校验实参数量 */
    public static void checkArgs(String funcName, List<Object> args, int min, int max) {
        int n = args == null ? 0 : args.size();
        if (n < min || n > max) {
            throw new ExprException("EXPR_EVAL_ERROR",
                    "函数 " + funcName + " 参数数量错误：期望 " + min + "~" + max + "，实际 " + n);
        }
    }

    /** 转为字符串（null-&gt;null） */
    public static String toStr(Object o) {
        return o == null ? null : o.toString();
    }
}
