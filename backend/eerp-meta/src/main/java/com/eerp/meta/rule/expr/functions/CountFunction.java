package com.eerp.meta.rule.expr.functions;

import com.eerp.meta.rule.expr.ExprContext;
import com.eerp.meta.rule.expr.ExprException;
import com.eerp.meta.rule.expr.ExprFunction;

import java.util.List;

/**
 * COUNT(list) —— 子表行计数 / 元素计数。
 *
 * <p>实参可为子实体编码（{@code COUNT($detail)}，返回行数）或子实体字段
 * （{@code COUNT($detail.qty)}，返回元素数）。返回 Integer。</p>
 *
 * <p>对齐设计文档 08 §5.4 COUNT()。</p>
 */
public class CountFunction implements ExprFunction {

    @Override
    public String name() {
        return "COUNT";
    }

    @Override
    public Object execute(List<Object> args, ExprContext ctx) throws ExprException {
        FuncUtil.checkArgs("COUNT", args, 0, 1);
        if (args.isEmpty() || args.get(0) == null) {
            return 0;
        }
        return FuncUtil.asList(args.get(0)).size();
    }
}
