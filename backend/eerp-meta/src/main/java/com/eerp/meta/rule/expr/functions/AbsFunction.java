package com.eerp.meta.rule.expr.functions;

import com.eerp.meta.rule.expr.ExprContext;
import com.eerp.meta.rule.expr.ExprException;
import com.eerp.meta.rule.expr.ExprFunction;

import java.util.List;

/**
 * ABS(num) —— 绝对值。返回 Double。
 *
 * <p>对齐设计文档 08 §5.4 ABS(num)。</p>
 */
public class AbsFunction implements ExprFunction {

    @Override
    public String name() {
        return "ABS";
    }

    @Override
    public Object execute(List<Object> args, ExprContext ctx) throws ExprException {
        FuncUtil.checkArgs("ABS", args, 1, 1);
        return Math.abs(FuncUtil.toDouble(args.get(0)));
    }
}
