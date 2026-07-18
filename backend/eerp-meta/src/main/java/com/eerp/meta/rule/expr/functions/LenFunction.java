package com.eerp.meta.rule.expr.functions;

import com.eerp.meta.rule.expr.ExprContext;
import com.eerp.meta.rule.expr.ExprException;
import com.eerp.meta.rule.expr.ExprFunction;

import java.util.List;

/**
 * LEN(str) —— 字符串长度。返回 Integer。
 */
public class LenFunction implements ExprFunction {

    @Override
    public String name() {
        return "LEN";
    }

    @Override
    public Object execute(List<Object> args, ExprContext ctx) throws ExprException {
        FuncUtil.checkArgs("LEN", args, 1, 1);
        Object o = args.get(0);
        if (o == null) {
            return 0;
        }
        return o.toString().length();
    }
}
