package com.eerp.plugin.annotation;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * 行为参数注解。
 *
 * <p>声明插件运行时配置参数，运行时由 {@code meta_plugin_param.default_value}（按 param_type）
 * 自动注入到字段。加载器反射扫描本注解自动生成参数描述符（参数零配置）。</p>
 */
@Target(ElementType.FIELD)
@Retention(RetentionPolicy.RUNTIME)
public @interface BehaviorParam {

    /** 参数名（如 "over_action"） */
    String value();

    /** 参数描述 */
    String description() default "";
}
