package com.eerp.plugin.core;

import com.eerp.plugin.annotation.FormParam;
import com.eerp.plugin.context.PluginContext;
import com.eerp.plugin.context.PluginResult;
import org.springframework.stereotype.Service;

import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;

/**
 * 插件执行器（对齐 PRD 6.2.7 / 设计文档 §3.2.8）。
 *
 * <p>按 exec_order 升序遍历已加载插件，对每个插件：
 * <ol>
 *   <li>注入 {@code @FormParam} 字段值（运行时从 {@code ctx.billData} 取值，best-effort 不抛异常）；</li>
 *   <li>反射调用与 event 同名的方法（支持 PascalCase ↔ camelCase 大小写兼容）；
 *       方法返回 {@link PluginResult} 则用之，返回 void/null 则视为 {@link PluginResult#ok()}；</li>
 *   <li>若方法抛异常或返回 {@code block=true} 的结果，立即停止后续插件并返回阻断结果。</li>
 * </ol>
 * </p>
 *
 * <p>责任链 + 流水线模式：插件串行执行，前置插件阻断（block=true）或抛异常则后续插件不再执行。
 * 调用方根据 {@link PluginExecutorResult#isBlock()} 决定是否继续主操作。</p>
 */
@Service
public class PluginExecutor {

    /**
     * 执行插件列表。
     *
     * @param plugins 已加载插件列表（按 execOrder 升序；本方法会再次保险排序）
     * @param event   事件（方法名，如 beforeExecuteOperationTransaction）
     * @param ctx     插件上下文
     * @return 执行结果（含整体成败、是否阻断、各插件结果）
     */
    public PluginExecutorResult execute(List<LoadedPlugin> plugins, String event, PluginContext ctx) {
        PluginExecutorResult result = new PluginExecutorResult();
        List<PluginResult> collected = new ArrayList<>();
        result.setSuccess(true);
        result.setBlock(false);
        result.setResults(collected);

        if (plugins == null || plugins.isEmpty()) {
            return result;
        }

        // 保险排序：按 execOrder 升序（null 视为最大值排末尾）
        List<LoadedPlugin> sorted = new ArrayList<>(plugins);
        sorted.sort(Comparator.comparingInt(p -> p.getExecOrder() == null ? Integer.MAX_VALUE : p.getExecOrder()));

        for (LoadedPlugin lp : sorted) {
            // 1. 注入 form 参数（best-effort，不抛异常）
            injectFormParams(lp.getPluginInstance(), ctx);

            // 2. 反射调用事件方法
            PluginResult pr = invokeEvent(lp.getPluginInstance(), event, ctx);
            collected.add(pr);

            // 3. 阻断或异常 → 停止后续插件
            if (pr.isBlock()) {
                result.setSuccess(false);
                result.setBlock(true);
                result.setMessage(pr.getMessage());
                return result;
            }
        }
        return result;
    }

    /** 注入 @FormParam 字段值（运行时从 ctx.billData 取值，按字段类型强制转换） */
    private void injectFormParams(Object instance, PluginContext ctx) {
        if (instance == null || ctx == null || ctx.getBillData() == null) {
            return;
        }
        Map<String, Object> billData = ctx.getBillData();
        Class<?> c = instance.getClass();
        while (c != null && c != Object.class) {
            for (Field f : c.getDeclaredFields()) {
                FormParam fp = f.getAnnotation(FormParam.class);
                if (fp == null) {
                    continue;
                }
                String key = fp.value();
                if (key == null || !billData.containsKey(key)) {
                    continue;
                }
                try {
                    f.setAccessible(true);
                    f.set(instance, coerce(billData.get(key), f.getType()));
                } catch (Exception ignored) {
                    // 注入失败保留字段默认值，不阻断执行
                }
            }
            c = c.getSuperclass();
        }
    }

    /** 反射调用事件方法 */
    private PluginResult invokeEvent(Object instance, String event, PluginContext ctx) {
        if (instance == null || event == null) {
            return PluginResult.ok();
        }
        try {
            Method m = findMethod(instance.getClass(), event);
            if (m == null) {
                // 找不到对应事件方法，视为该插件不响应此事件，直接通过
                return PluginResult.ok();
            }
            m.setAccessible(true);
            Object ret = m.invoke(instance, ctx);
            if (ret instanceof PluginResult) {
                return (PluginResult) ret;
            }
            // void 方法或返回 null → 视为通过
            return PluginResult.ok();
        } catch (Exception e) {
            Throwable cause = e.getCause() != null ? e.getCause() : e;
            return PluginResult.block("插件执行异常: " + cause.getMessage());
        }
    }

    /**
     * 查找事件方法（大小写兼容）。
     * 支持：精确匹配、首字母大小写翻转（PascalCase ↔ camelCase）、
     * 遍历继承链做大小写不敏感匹配（覆盖 protected/private 重写）。
     */
    private Method findMethod(Class<?> clazz, String name) {
        if (name == null || name.isEmpty()) {
            return null;
        }
        // 1. 精确匹配（getMethod 仅返回 public 方法，含继承）
        try {
            return clazz.getMethod(name, PluginContext.class);
        } catch (NoSuchMethodException ignored) {
            // 继续
        }
        // 2. 首字母大小写翻转后再精确匹配（PascalCase ↔ camelCase）
        String alt = flipFirstCharCase(name);
        if (alt != null && !alt.equals(name)) {
            try {
                return clazz.getMethod(alt, PluginContext.class);
            } catch (NoSuchMethodException ignored) {
                // 继续
            }
        }
        // 3. 遍历继承链的 declared 方法做大小写不敏感匹配（覆盖非 public 重写）
        Class<?> c = clazz;
        while (c != null && c != Object.class) {
            for (Method m : c.getDeclaredMethods()) {
                if (m.getParameterCount() == 1
                        && m.getParameterTypes()[0] == PluginContext.class
                        && name.equalsIgnoreCase(m.getName())) {
                    return m;
                }
            }
            c = c.getSuperclass();
        }
        return null;
    }

    /** 翻转首字母大小写；首字符非字母返回 null */
    private String flipFirstCharCase(String name) {
        if (name == null || name.isEmpty()) {
            return null;
        }
        char first = name.charAt(0);
        char flipped;
        if (Character.isUpperCase(first)) {
            flipped = Character.toLowerCase(first);
        } else if (Character.isLowerCase(first)) {
            flipped = Character.toUpperCase(first);
        } else {
            return null;
        }
        return flipped + name.substring(1);
    }

    /** 按字段类型强制转换值；无法转换则原样返回 */
    private Object coerce(Object value, Class<?> type) {
        if (value == null) {
            return null;
        }
        if (type.isInstance(value)) {
            return value;
        }
        String s = value.toString();
        if (type == String.class) {
            return s;
        }
        try {
            if (type == Integer.class || type == int.class) {
                return Integer.valueOf(s);
            }
            if (type == Long.class || type == long.class) {
                return Long.valueOf(s);
            }
            if (type == Double.class || type == double.class) {
                return Double.valueOf(s);
            }
            if (type == Float.class || type == float.class) {
                return Float.valueOf(s);
            }
            if (type == Boolean.class || type == boolean.class) {
                return Boolean.valueOf(s);
            }
            if (type == BigDecimal.class) {
                return new BigDecimal(s);
            }
        } catch (NumberFormatException ignored) {
            // 转换失败原样返回
        }
        return value;
    }
}
