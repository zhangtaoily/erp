package com.eerp.plugin.script;

import com.eerp.meta.rule.expr.ExprContext;

/**
 * 脚本引擎接口（对齐 PRD 6.2.5）。
 *
 * <p>脚本插件表达式求值入口，底层委托 A1 表达式引擎（ANTLR4 文法）。</p>
 */
public interface ScriptEngine {

    /**
     * 求值脚本，返回结果。
     *
     * @param script 脚本表达式
     * @param ctx    求值上下文
     * @return 求值结果
     */
    Object eval(String script, ExprContext ctx);

    /**
     * 求值脚本并转为布尔。
     *
     * @param script 脚本表达式
     * @param ctx    求值上下文
     * @return 布尔结果
     */
    boolean evalBoolean(String script, ExprContext ctx);
}
