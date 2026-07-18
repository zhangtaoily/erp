package com.eerp.plugin.script;

import com.eerp.meta.rule.expr.ExprContext;
import com.eerp.plugin.base.AbstractOperationServicePlugin;
import com.eerp.plugin.context.PluginContext;
import com.eerp.plugin.context.PluginResult;

import java.util.HashMap;
import java.util.Map;

/**
 * 脚本插件适配器（对齐 PRD 6.2.5）。
 *
 * <p>将脚本表达式包装为 {@link AbstractOperationServicePlugin}（最常见的脚本插件场景）。
 * 构造器接收脚本表达式 Map（key 为阶段方法名，value 为对应阶段的脚本表达式）与脚本引擎；
 * 每个阶段方法以 {@code ctx.billData} 为根数据求值脚本，求值为 false 时返回
 * {@link PluginResult#block(String)}。</p>
 *
 * <p>脚本语法沿用 A1 ExprEvaluator 文法，字段引用使用 {@code $field}，
 * 例如 {@code $qty > 0} 取 {@code ctx.billData.qty} 进行比较。</p>
 */
public class ScriptPluginAdapter extends AbstractOperationServicePlugin {

    private final ScriptEngine scriptEngine;
    private final String scriptOnPrepare;
    private final String scriptOnAddValidators;
    private final String scriptBefore;
    private final String scriptBegin;
    private final String scriptEnd;
    private final String scriptAfter;

    /**
     * 构造器接收脚本表达式 Map 与脚本引擎。
     *
     * @param scripts      脚本表达式 Map（key=阶段方法名，value=脚本表达式）
     * @param scriptEngine 脚本引擎
     */
    public ScriptPluginAdapter(Map<String, String> scripts, ScriptEngine scriptEngine) {
        this.scriptEngine = scriptEngine;
        this.scriptOnPrepare = scripts == null ? null : scripts.get("onPreparePropertys");
        this.scriptOnAddValidators = scripts == null ? null : scripts.get("onAddValidators");
        this.scriptBefore = scripts == null ? null : scripts.get("beforeExecuteOperationTransaction");
        this.scriptBegin = scripts == null ? null : scripts.get("beginOperationTransaction");
        this.scriptEnd = scripts == null ? null : scripts.get("endOperationTransaction");
        this.scriptAfter = scripts == null ? null : scripts.get("afterExecuteOperationTransaction");
    }

    @Override
    public PluginResult onPreparePropertys(PluginContext ctx) {
        return evalStage(scriptOnPrepare, ctx);
    }

    @Override
    public PluginResult onAddValidators(PluginContext ctx) {
        return evalStage(scriptOnAddValidators, ctx);
    }

    @Override
    public PluginResult beforeExecuteOperationTransaction(PluginContext ctx) {
        return evalStage(scriptBefore, ctx);
    }

    @Override
    public PluginResult beginOperationTransaction(PluginContext ctx) {
        return evalStage(scriptBegin, ctx);
    }

    @Override
    public PluginResult endOperationTransaction(PluginContext ctx) {
        return evalStage(scriptEnd, ctx);
    }

    @Override
    public void afterExecuteOperationTransaction(PluginContext ctx) {
        // 事务后阶段不阻断，仅求值脚本（副作用）
        if (scriptAfter != null && !scriptAfter.trim().isEmpty()) {
            scriptEngine.evalBoolean(scriptAfter, toExprContext(ctx));
        }
    }

    /** 求值阶段脚本：空脚本通过；求值 false 则阻断 */
    private PluginResult evalStage(String script, PluginContext ctx) {
        if (script == null || script.trim().isEmpty()) {
            return PluginResult.ok();
        }
        boolean pass = scriptEngine.evalBoolean(script, toExprContext(ctx));
        return pass ? PluginResult.ok() : PluginResult.block("脚本校验未通过: " + script);
    }

    /** 将 PluginContext 转换为 ExprContext，billData 作为根数据 */
    private ExprContext toExprContext(PluginContext ctx) {
        Map<String, Object> billData = ctx == null ? null : ctx.getBillData();
        return new ExprContext(billData == null ? new HashMap<>() : billData);
    }
}
