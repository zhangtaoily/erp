package com.eerp.meta.rule.expr.functions;

import com.eerp.meta.rule.expr.ExprContext;
import com.eerp.meta.rule.expr.ExprException;
import com.eerp.meta.rule.expr.ExprFunction;

import java.util.List;

/**
 * UPPER(str) —— 字符串转大写。
 */
public class UpperFunction implements ExprFunction {

    @Override
    public String name() {
        return "UPPER";
    }

    @Override
    public Object execute(List<Object> args, ExprContext ctx) throws ExprException {
        FuncUtil.checkArgs("UPPER", args, 1, 1);
        Object o = args.get(0);
        return o == null ? null : o.toString().toUpperCase();
    }
}
