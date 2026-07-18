package com.eerp.meta.rule.expr.functions;

import com.eerp.meta.rule.expr.ExprContext;
import com.eerp.meta.rule.expr.ExprException;
import com.eerp.meta.rule.expr.ExprFunction;

import java.util.List;

/**
 * AND(a, b, ...) —— 逻辑与。
 *
 * <p><b>注意</b>：短路语义由 {@link com.eerp.meta.rule.expr.ExprAstVisitor} 在分发前特殊
 * 处理（遇到 false 立即返回，不再求值后续参数），不会调用本类 execute。本类 eager 实现
 * 作为兜底，注册以满足函数存在性检查。</p>
 */
public class AndFunction implements ExprFunction {

    @Override
    public String name() {
        return "AND";
    }

    @Override
    public Object execute(List<Object> args, ExprContext ctx) throws ExprException {
        if (args == null || args.isEmpty()) {
            return true;
        }
        for (Object o : args) {
            if (!FuncUtil.toBool(o)) {
                return false;
            }
        }
        return true;
    }
}
