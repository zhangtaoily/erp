package com.eerp.plugin.base;

import com.eerp.plugin.context.PluginContext;
import com.eerp.plugin.context.PluginResult;

/**
 * 表单插件基类（参考金蝶 AbstractBillPlugIn）
 */
public abstract class AbstractBillPlugin {
    // 表单加载完成
    public void onLoaded(PluginContext ctx) {}
    // 数据变更
    public PluginResult onDataChanged(PluginContext ctx) { return PluginResult.ok(); }
    // 自定义按钮点击
    public PluginResult onCustomButtonClick(PluginContext ctx, String buttonCode) { return PluginResult.ok(); }
    // 保存前
    public PluginResult beforeSave(PluginContext ctx) { return PluginResult.ok(); }
    // 保存后
    public void afterSave(PluginContext ctx) {}
}
