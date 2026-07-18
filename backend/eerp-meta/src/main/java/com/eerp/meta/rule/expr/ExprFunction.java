package com.eerp.meta.rule.expr;

import java.util.List;

/**
 * 表达式内置函数接口。
 *
 * <p>每个内置函数（SUM/COUNT/AVG/MAX/MIN/IF/AND/OR/NOT/LOOKUP/ERROR/ROUND/ABS/LEN/
 * UPPER/LOWER/NOW/FORMAT）实现此接口并注册到 {@link ExprFunctionRegistry}。</p>
 *
 * <p>注意：本接口的 {@link #execute} 接收的是<b>已求值的实参</b>（eager 求值）。
 * 需要短路/惰性求值的函数（IF/AND/OR）由 {@link ExprAstVisitor} 在分发前特殊处理，
 * 不会走此接口的 eager 路径，以保证短路语义。</p>
 *
 * <p>对齐设计文档 06 §3.2.11 沙箱白名单函数集 与 08 §5.4 11 内置函数清单。</p>
 */
public interface ExprFunction {

    /**
     * 函数名（大写返回，注册时统一转大写）。
     *
     * @return 函数名，如 "SUM"
     */
    String name();

    /**
     * 执行函数。
     *
     * @param args 已求值的实参列表（可能为空）
     * @param ctx  求值上下文（提供字段取值、子表数据、LOOKUP 数据源等）
     * @return 函数返回值
     * @throws ExprException 当函数内部需要抛校验异常（如 ERROR）或参数非法时
     */
    Object execute(List<Object> args, ExprContext ctx) throws ExprException;
}
