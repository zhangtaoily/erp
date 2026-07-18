package com.eerp.meta.rule.expr.functions;

import com.eerp.meta.rule.expr.ExprContext;
import com.eerp.meta.rule.expr.ExprException;
import com.eerp.meta.rule.expr.ExprFunction;

import java.util.List;

/**
 * MAX(list) —— 子表字段最大值。
 *
 * <p>实参为字段引用解析出的 {@code List}，取非 null 数字元素最大值。无元素返回 null。
 * 返回 Double。</p>
 *
 * <p>对齐设计文档 08 §5.4 MAX(field)。</p>
 */
public class MaxFunction implements ExprFunction {

    @Override
    public String name() {
        return "MAX";
    }

    @Override
    public Object execute(List<Object> args, ExprContext ctx) throws ExprException {
        FuncUtil.checkArgs("MAX", args, 1, 1);
        List<Object> list = FuncUtil.asList(args.get(0));
        Double max = null;
        for (Object o : list) {
            if (o == null) {
                continue;
            }
            double v = FuncUtil.toDouble(o);
            if (max == null || v > max) {
                max = v;
            }
        }
        return max;
    }
}
