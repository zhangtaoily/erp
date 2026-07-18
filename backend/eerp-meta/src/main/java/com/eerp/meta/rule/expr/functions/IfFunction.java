package com.eerp.meta.rule.expr.functions;

import com.eerp.meta.rule.expr.ExprContext;
import com.eerp.meta.rule.expr.ExprException;
import com.eerp.meta.rule.expr.ExprFunction;

import java.util.List;

/**
 * IF(cond, thenExpr, elseExpr) —— 条件选择。
 *
 * <p><b>注意</b>：本接口实现为<b>惰性求值</b>语义。由于 {@link ExprFunction#execute}
 * 接收的是已求值的实参，IF 的短路语义（仅求值选中分支）由
 * {@link com.eerp.meta.rule.expr.ExprAstVisitor} 在函数分发前特殊处理，<b>不会</b>调用
 * 本类的 execute。本类仍注册到注册表以满足函数存在性检查与未来直接调用需求；其 execute
 * 实现 eager 语义作为兜底（按条件返回已求值的 then/else）。</p>
 *
 * <p>对齐设计文档 08 §5.4（IF 为扩展内置函数）。</p>
 */
public class IfFunction implements ExprFunction {

    @Override
    public String name() {
        return "IF";
    }

    @Override
    public Object execute(List<Object> args, ExprContext ctx) throws ExprException {
        FuncUtil.checkArgs("IF", args, 3, 3);
        boolean cond = FuncUtil.toBool(args.get(0));
        return cond ? args.get(1) : args.get(2);
    }
}
