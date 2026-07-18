package com.eerp.meta.rule.expr.functions;

import com.eerp.meta.rule.expr.ExprContext;
import com.eerp.meta.rule.expr.ExprException;
import com.eerp.meta.rule.expr.ExprFunction;

import java.util.List;

/**
 * LOWER(str) —— 字符串转小写。
 */
public class LowerFunction implements ExprFunction {

    @Override
    public String name() {
        return "LOWER";
    }

    @Override
    public Object execute(List<Object> args, ExprContext ctx) throws ExprException {
        FuncUtil.checkArgs("LOWER", args, 1, 1);
        Object o = args.get(0);
        return o == null ? null : o.toString().toLowerCase();
    }
}
