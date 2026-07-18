package com.eerp.plugin.annotation;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * 表单参数注解（对齐 PRD 6.2.4.1）。
 *
 * <p>声明插件所需的单据字段参数，运行时由 {@code ctx.billData[value]} 注入到字段。
 * 加载器反射扫描本注解自动生成参数描述符（参数零配置）。</p>
 */
@Target(ElementType.FIELD)
@Retention(RetentionPolicy.RUNTIME)
public @interface FormParam {

    /** 参数名（单据字段编码，如 "cust_credit"） */
    String value();

    /** 参数描述 */
    String description() default "";

    /** 是否必填 */
    boolean required() default false;
}
