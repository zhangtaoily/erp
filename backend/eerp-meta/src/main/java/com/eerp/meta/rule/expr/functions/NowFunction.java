package com.eerp.meta.rule.expr.functions;

import com.eerp.meta.rule.expr.ExprContext;
import com.eerp.meta.rule.expr.ExprException;
import com.eerp.meta.rule.expr.ExprFunction;

import java.time.LocalDateTime;
import java.util.List;

/**
 * NOW() —— 当前日期时间。返回 {@link LocalDateTime}。
 *
 * <p>对齐设计文档 08 §5.4 NOW()。</p>
 */
public class NowFunction implements ExprFunction {

    @Override
    public String name() {
        return "NOW";
    }

    @Override
    public Object execute(List<Object> args, ExprContext ctx) throws ExprException {
        return LocalDateTime.now();
    }
}
