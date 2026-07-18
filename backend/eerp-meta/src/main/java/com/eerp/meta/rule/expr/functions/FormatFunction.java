package com.eerp.meta.rule.expr.functions;

import com.eerp.meta.rule.expr.ExprContext;
import com.eerp.meta.rule.expr.ExprException;
import com.eerp.meta.rule.expr.ExprFunction;

import java.text.DecimalFormat;
import java.time.format.DateTimeFormatter;
import java.time.temporal.TemporalAccessor;
import java.util.List;

/**
 * FORMAT(value, pattern) —— 按模式格式化为字符串。
 *
 * <p>value 为数字时使用 {@link DecimalFormat}（如 {@code FORMAT(1234.5, '#,##0.00')}
 * &rarr; {@code "1,234.50"}）；value 为 {@link TemporalAccessor}（如 NOW() 返回值）时
 * 使用 {@link DateTimeFormatter}；其余情况使用 {@link String#format}。</p>
 */
public class FormatFunction implements ExprFunction {

    @Override
    public String name() {
        return "FORMAT";
    }

    @Override
    public Object execute(List<Object> args, ExprContext ctx) throws ExprException {
        FuncUtil.checkArgs("FORMAT", args, 2, 2);
        Object value = args.get(0);
        String pattern = FuncUtil.toStr(args.get(1));
        if (value == null) {
            return null;
        }
        if (pattern == null) {
            return value.toString();
        }
        try {
            if (value instanceof Number) {
                return new DecimalFormat(pattern).format(value);
            }
            if (value instanceof TemporalAccessor) {
                return DateTimeFormatter.ofPattern(pattern).format((TemporalAccessor) value);
            }
            return String.format(pattern, value);
        } catch (Exception e) {
            throw new ExprException("EXPR_EVAL_ERROR",
                    "FORMAT 格式化失败: " + e.getMessage(), e);
        }
    }
}
