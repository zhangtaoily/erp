package com.eerp.plugin.base;

import com.eerp.plugin.context.PluginContext;
import com.eerp.plugin.context.PluginResult;

/**
 * 操作服务插件基类，定义 6 阶段流水线方法签名（对齐 project_memory 硬约束）
 */
public abstract class AbstractOperationServicePlugin {
    // 阶段1：事务外 - 预加载字段值
    public PluginResult onPreparePropertys(PluginContext ctx) { return PluginResult.ok(); }
    // 阶段2：事务外 - 挂载校验器
    public PluginResult onAddValidators(PluginContext ctx) { return PluginResult.ok(); }
    // 阶段3：事务外 - 事务前校验
    public PluginResult beforeExecuteOperationTransaction(PluginContext ctx) { return PluginResult.ok(); }
    // 阶段4：事务内 - 事务内前置
    public PluginResult beginOperationTransaction(PluginContext ctx) { return PluginResult.ok(); }
    // 阶段5：事务内 - 事务内后置
    public PluginResult endOperationTransaction(PluginContext ctx) { return PluginResult.ok(); }
    // 阶段6：事务后 - 事务后通知（异常不回滚）
    public void afterExecuteOperationTransaction(PluginContext ctx) {}
}
