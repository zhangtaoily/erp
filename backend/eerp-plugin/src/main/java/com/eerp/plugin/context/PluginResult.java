package com.eerp.plugin.context;

import lombok.Data;

/**
 * 插件执行结果。
 *
 * <p>每个插件阶段方法返回本对象。{@code block=true} 表示阻断后续插件与主操作，
 * 此时 {@code success=false}。</p>
 */
@Data
public class PluginResult {

    /** 是否成功 */
    private boolean success;

    /** 是否阻断后续插件 */
    private boolean block;

    /** 提示消息 */
    private String message;

    /** 返回数据 */
    private Object data;

    /** 成功（无数据） */
    public static PluginResult ok() {
        PluginResult result = new PluginResult();
        result.success = true;
        result.block = false;
        return result;
    }

    /** 成功（携带数据） */
    public static PluginResult ok(Object data) {
        PluginResult result = new PluginResult();
        result.success = true;
        result.block = false;
        result.data = data;
        return result;
    }

    /** 失败（不阻断后续） */
    public static PluginResult fail(String message) {
        PluginResult result = new PluginResult();
        result.success = false;
        result.block = false;
        result.message = message;
        return result;
    }

    /** 阻断后续插件与主操作（success=false） */
    public static PluginResult block(String message) {
        PluginResult result = new PluginResult();
        result.success = false;
        result.block = true;
        result.message = message;
        return result;
    }
}
