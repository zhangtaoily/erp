package com.eerp.plugin.core;

import com.eerp.plugin.context.PluginContext;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;

/**
 * 插件管理器（对齐 PRD 6.2.7 / 设计文档 §3.2.8）。
 *
 * <p>统一入口：加载 → 构建上下文 → 执行。提供：
 * <ul>
 *   <li>{@link #fire}：调用方已构建 {@link PluginContext} 时使用，按事件触发对应插件链；</li>
 *   <li>{@link #fireEvent}：便捷入口，内部通过 {@link PluginContextFactory} 构建上下文。</li>
 * </ul>
 * </p>
 *
 * <p>调用方负责事务边界划分（对齐 6 阶段流水线事务边界约束）：
 * <ul>
 *   <li>阶段 1-3（onPreparePropertys / onAddValidators / beforeExecuteOperationTransaction）事务外执行，
 *       {@code block=true} 时调用方应中止主操作；</li>
 *   <li>阶段 4-5（beginOperationTransaction / endOperationTransaction）事务内执行，
 *       异常自动回滚主事务；</li>
 *   <li>阶段 6（afterExecuteOperationTransaction）事务后执行，仅记日志，不影响主操作结果。</li>
 * </ul>
 * </p>
 */
@Service
public class PluginManager {

    private final PluginLoader pluginLoader;
    private final PluginExecutor pluginExecutor;
    private final PluginContextFactory pluginContextFactory;

    @Autowired
    public PluginManager(PluginLoader pluginLoader,
                         PluginExecutor pluginExecutor,
                         PluginContextFactory pluginContextFactory) {
        this.pluginLoader = pluginLoader;
        this.pluginExecutor = pluginExecutor;
        this.pluginContextFactory = pluginContextFactory;
    }

    /**
     * 触发指定业务对象 + 事件的插件链（上下文已构建）。
     *
     * @param boCode    业务对象编码
     * @param eventType 事件（阶段方法名，如 beforeExecuteOperationTransaction）
     * @param ctx       插件上下文
     * @return 执行结果
     */
    public PluginExecutorResult fire(String boCode, String eventType, PluginContext ctx) {
        List<LoadedPlugin> plugins = pluginLoader.loadPlugins(boCode, eventType);
        return pluginExecutor.execute(plugins, eventType, ctx);
    }

    /**
     * 触发指定业务对象 + 事件的插件链（便捷入口，自动构建上下文）。
     *
     * @param boCode    业务对象编码
     * @param billId    单据 ID
     * @param operation 操作类型（save/submit/audit/reject/revoke/delete/...）
     * @param eventType 事件（阶段方法名）
     * @param billData  单据数据（主表 + 子表）
     * @param userInfo  用户信息（userId/userName/orgId）
     * @return 执行结果
     */
    public PluginExecutorResult fireEvent(String boCode, Long billId, String operation,
                                          String eventType,
                                          Map<String, Object> billData,
                                          Map<String, Object> userInfo) {
        PluginContext ctx = pluginContextFactory.create(boCode, billId, operation, billData, userInfo);
        return fire(boCode, eventType, ctx);
    }
}
