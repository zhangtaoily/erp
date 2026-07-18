package com.eerp.meta.rule.expr.functions;

import com.eerp.meta.rule.expr.ExprContext;
import com.eerp.meta.rule.expr.ExprException;
import com.eerp.meta.rule.expr.ExprFunction;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;

/**
 * ROUND(num, digits) —— 四舍五入。
 *
 * <p>第二参数 digits 为小数位数（默认 0）。使用 BigDecimal HALF_UP 保证精度。
 * 返回 Double。</p>
 *
 * <p>对齐设计文档 08 §5.4 ROUND(num, digits)。</p>
 */
public class RoundFunction implements ExprFunction {

    @Override
    public String name() {
        return "ROUND";
    }

    @Override
    public Object execute(List<Object> args, ExprContext ctx) throws ExprException {
        FuncUtil.checkArgs("ROUND", args, 1, 2);
        double num = FuncUtil.toDouble(args.get(0));
        int digits = args.size() > 1 ? (int) FuncUtil.toDouble(args.get(1)) : 0;
        BigDecimal bd = BigDecimal.valueOf(num).setScale(digits, RoundingMode.HALF_UP);
        return bd.doubleValue();
    }
}
