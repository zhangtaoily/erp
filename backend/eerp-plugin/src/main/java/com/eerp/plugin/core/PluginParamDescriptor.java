package com.eerp.plugin.core;

import lombok.Data;

/**
 * 插件参数描述符。
 *
 * <p>由 {@code @FormParam} / {@code @BehaviorParam} 字段注解反射生成，
 * 描述参数名、类型、是否必填与运行时值。paramType 取值：
 * STRING / NUMBER / BOOLEAN / EXPRESSION / BEHAVIOR。</p>
 */
@Data
public class PluginParamDescriptor {

    /** 参数名 */
    private String paramName;

    /** 参数类型：STRING / NUMBER / BOOLEAN / EXPRESSION / BEHAVIOR */
    private String paramType;

    /** 参数描述 */
    private String description;

    /** 是否必填 */
    private boolean required;

    /** 运行时值（behavior 取自 meta_plugin_param.default_value；form 运行时由 billData 注入） */
    private Object value;
}
