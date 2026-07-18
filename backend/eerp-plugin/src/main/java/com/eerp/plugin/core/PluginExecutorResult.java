package com.eerp.plugin.core;

import com.eerp.plugin.context.PluginResult;
import lombok.Data;

import java.util.List;

/**
 * 插件执行器结果。
 *
 * <p>承载整体执行是否成功、是否被阻断、提示消息以及各插件阶段的 {@link PluginResult} 列表。</p>
 */
@Data
public class PluginExecutorResult {

    /** 整体是否成功（任一插件阻断或异常则 false） */
    private boolean success;

    /** 是否阻断后续插件与主操作 */
    private boolean block;

    /** 提示消息 */
    private String message;

    /** 各插件执行结果列表（按 execOrder 顺序） */
    private List<PluginResult> results;
}
