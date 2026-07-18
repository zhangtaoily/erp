package com.eerp.plugin.core;

import lombok.Data;

import java.util.List;

/**
 * 已加载插件 DTO。
 *
 * <p>由 {@link PluginLoader} 产出，承载插件实例、识别的系统基类、执行顺序与参数描述符列表。</p>
 */
@Data
public class LoadedPlugin {

    /** 插件实例（三基类子类或 ScriptPluginAdapter） */
    private Object pluginInstance;

    /** 系统基类：BILL / LIST / OPERATION_SERVICE */
    private String baseClass;

    /** 执行顺序（升序串行） */
    private Integer execOrder;

    /** 参数描述符列表（注解反射生成） */
    private List<PluginParamDescriptor> params;
}
