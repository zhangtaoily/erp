package com.eerp.plugin.script;

import com.eerp.meta.rule.expr.ExprContext;
import com.eerp.meta.rule.expr.ExprEvaluator;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

/**
 * ANTLR4 脚本引擎实现（对齐 PRD 6.2.5）。
 *
 * <p>委托 A1 表达式引擎 {@link ExprEvaluator} 完成表达式求值。
 * 脚本语法沿用 A1 ExprEvaluator 文法：字段引用使用 {@code $field}（如 {@code $qty > 0}），
 * 字段值取自 {@link ExprContext#getRootData()}。</p>
 */
@Service
public class Antlr4ScriptEngine implements ScriptEngine {

    private final ExprEvaluator exprEvaluator;

    @Autowired
    public Antlr4ScriptEngine(ExprEvaluator exprEvaluator) {
        this.exprEvaluator = exprEvaluator;
    }

    @Override
    public Object eval(String script, ExprContext ctx) {
        if (script == null || script.trim().isEmpty()) {
            return null;
        }
        return exprEvaluator.evaluate(script, ctx);
    }

    @Override
    public boolean evalBoolean(String script, ExprContext ctx) {
        Object result = eval(script, ctx);
        if (result == null) {
            return false;
        }
        if (result instanceof Boolean) {
            return (Boolean) result;
        }
        if (result instanceof Number) {
            return ((Number) result).doubleValue() != 0;
        }
        return Boolean.parseBoolean(result.toString());
    }
}
