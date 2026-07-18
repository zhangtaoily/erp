package com.eerp.plugin.base;

import com.eerp.plugin.context.PluginContext;
import com.eerp.plugin.context.PluginResult;

/**
 * 列表插件基类
 */
public abstract class AbstractListPlugin {
    public void onLoaded(PluginContext ctx) {}
    public PluginResult onFilter(PluginContext ctx) { return PluginResult.ok(); }
    public PluginResult beforeDelete(PluginContext ctx) { return PluginResult.ok(); }
}
