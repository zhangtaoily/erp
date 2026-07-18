package com.eerp.meta.rule.expr.functions;

import com.eerp.meta.rule.expr.ExprContext;
import com.eerp.meta.rule.expr.ExprException;
import com.eerp.meta.rule.expr.ExprFunction;

import java.util.List;

/**
 * AVG(list) —— 子表字段平均值。
 *
 * <p>实参为字段引用解析出的 {@code List}，对非 null 数字元素求平均。无元素返回 0.0。
 * 返回 Double。</p>
 *
 * <p>对齐设计文档 08 §5.4 AVG(field)。</p>
 */
public class AvgFunction implements ExprFunction {

    @Override
    public String name() {
        return "AVG";
    }

    @Override
    public Object execute(List<Object> args, ExprContext ctx) throws ExprException {
        FuncUtil.checkArgs("AVG", args, 1, 1);
        List<Object> list = FuncUtil.asList(args.get(0));
        double sum = 0d;
        int count = 0;
        for (Object o : list) {
            if (o != null) {
                sum += FuncUtil.toDouble(o);
                count++;
            }
        }
        return count == 0 ? 0d : sum / count;
    }
}
