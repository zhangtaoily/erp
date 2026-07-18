package com.eerp.meta.rule.expr.functions;

import com.eerp.meta.rule.expr.ExprContext;
import com.eerp.meta.rule.expr.ExprException;
import com.eerp.meta.rule.expr.ExprFunction;

import java.util.List;

/**
 * ERROR('msg') —— 抛校验异常。
 *
 * <p>用于 validate 类规则：条件不满足时调用 error(...) 立即抛出 {@link ExprException}
 * （errorCode=RULE_VALIDATE_FAIL），由上层捕获并转换为 ServiceException 回滚事务。</p>
 *
 * <p>对齐设计文档 08 §3.2.3 错误抛出与 06 §3.2.11 沙箱白名单 throwException。</p>
 */
public class ErrorFunction implements ExprFunction {

    private static final String ERROR_CODE = "RULE_VALIDATE_FAIL";

    @Override
    public String name() {
        return "ERROR";
    }

    @Override
    public Object execute(List<Object> args, ExprContext ctx) throws ExprException {
        String msg = (args == null || args.isEmpty() || args.get(0) == null)
                ? "校验失败" : String.valueOf(args.get(0));
        throw new ExprException(ERROR_CODE, msg);
    }
}
