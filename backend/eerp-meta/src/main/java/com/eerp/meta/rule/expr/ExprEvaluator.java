package com.eerp.meta.rule.expr;

import java.util.concurrent.ConcurrentHashMap;

/**
 * 表达式求值入口。
 *
 * <p>对外提供 {@link #evaluate(String, ExprContext)} 与 {@link #evaluateFieldRef(String, ExprContext)}
 * 两个方法。内部委托 {@link ExprLexer} + {@link ExprParser} 将表达式解析为 {@link ExprNode}
 * AST，再用 {@link ExprAstVisitor} 求值。对已解析表达式做 {@link ConcurrentHashMap} 缓存
 * （key=表达式文本，value=AST），避免重复解析，提升高频规则求值性能（对齐设计文档 08
 * §3.2.2 单规则 &lt; 5ms 与预编译缓存约束）。</p>
 *
 * <p>注：手写方案下缓存值为 {@link ExprNode}（AST）而非 ANTLR {@code ParseTree}；
 * 接口契约不变。未来切换 ANTLR4 时，parse() 改为 ANTLR4 Lexer+Parser 生成 ParseTree
 * 即可，缓存类型相应替换，evaluate/evaluateFieldRef 对外签名保持不变。</p>
 */
public class ExprEvaluator {

    /** 表达式 AST 缓存（key=表达式文本） */
    private final ConcurrentHashMap<String, ExprNode> cache = new ConcurrentHashMap<>();

    /** 默认函数注册表（可被 ExprContext 自带的注册表覆盖） */
    private final ExprFunctionRegistry registry;

    public ExprEvaluator() {
        this(new ExprFunctionRegistry());
    }

    public ExprEvaluator(ExprFunctionRegistry registry) {
        this.registry = registry == null ? new ExprFunctionRegistry() : registry;
    }

    /**
     * 求值表达式。
     *
     * @param expr 表达式文本
     * @param ctx  求值上下文
     * @return 求值结果
     * @throws ExprException 解析或求值错误
     */
    public Object evaluate(String expr, ExprContext ctx) {
        if (expr == null || expr.trim().isEmpty()) {
            return null;
        }
        ExprNode ast = cache.computeIfAbsent(expr, this::parse);
        ExprFunctionRegistry reg = ctx.getFunctions() == null ? registry : ctx.getFunctions();
        ExprAstVisitor visitor = new ExprAstVisitor(ctx, reg);
        return visitor.visit(ast);
    }

    /**
     * 直接求值字段引用（不经过完整表达式解析）。
     *
     * @param path 字段路径（不含前导 $），如 "qty" 或 "detail.qty"
     * @param ctx  求值上下文
     * @return 字段值
     */
    public Object evaluateFieldRef(String path, ExprContext ctx) {
        return ctx.getFieldValue(path);
    }

    /** 清空表达式缓存 */
    public void clearCache() {
        cache.clear();
    }

    /** 缓存大小（调试/监控用） */
    public int cacheSize() {
        return cache.size();
    }

    private ExprNode parse(String expr) {
        ExprLexer lexer = new ExprLexer(expr);
        ExprParser parser = new ExprParser(lexer);
        return parser.parse();
    }
}
