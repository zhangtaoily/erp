package com.eerp.meta.rule.expr.functions;

import com.eerp.meta.rule.expr.ExprContext;
import com.eerp.meta.rule.expr.ExprException;
import com.eerp.meta.rule.expr.ExprFunction;

import java.util.List;

/**
 * NOT(a) —— 逻辑非。
 */
public class NotFunction implements ExprFunction {

    @Override
    public String name() {
        return "NOT";
    }

    @Override
    public Object execute(List<Object> args, ExprContext ctx) throws ExprException {
        FuncUtil.checkArgs("NOT", args, 1, 1);
        return !FuncUtil.toBool(args.get(0));
    }
}
