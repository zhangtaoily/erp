package com.eerp.meta.rule.expr.functions;

import com.eerp.meta.rule.expr.ExprContext;
import com.eerp.meta.rule.expr.ExprException;
import com.eerp.meta.rule.expr.ExprFunction;

import java.util.List;

/**
 * SUM(list) —— 子表字段求和。
 *
 * <p>实参为字段引用解析出的 {@code List}（如 {@code $detail.amount}），对其中数字元素求和，
 * 跳过 null。返回 Double。</p>
 *
 * <p>对齐设计文档 08 §5.4 SUM(field)。</p>
 */
public class SumFunction implements ExprFunction {

    @Override
    public String name() {
        return "SUM";
    }

    @Override
    public Object execute(List<Object> args, ExprContext ctx) throws ExprException {
        FuncUtil.checkArgs("SUM", args, 1, 1);
        List<Object> list = FuncUtil.asList(args.get(0));
        double sum = 0d;
        for (Object o : list) {
            if (o != null) {
                sum += FuncUtil.toDouble(o);
            }
        }
        return sum;
    }
}
