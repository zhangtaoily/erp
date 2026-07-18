package com.eerp.meta.rule.expr;

import com.eerp.meta.rule.expr.functions.FuncUtil;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

/**
 * 表达式 AST 访问器 / 求值器。
 *
 * <p>对 {@link ExprNode} AST 进行访问求值。各节点类型对应一个 visit 方法：
 * 字面量 / 字段引用 / 数组 / Map / 一元 / 二元（算术·比较·逻辑）/ 三元 / 赋值 / 函数调用。</p>
 *
 * <p>关键语义：</p>
 * <ul>
 *   <li>字段引用：委托 {@link ExprContext#getFieldValue(String)}。</li>
 *   <li>赋值：求值 RHS 后写入 {@code ctx.variables}，返回赋值后的值（联动规则用）。</li>
 *   <li>逻辑 {@code && / ||}：短路求值。</li>
 *   <li>函数 IF/AND/OR：在分发前特殊处理，保证惰性 / 短路语义（不会走 ExprFunction.execute
 *       的 eager 路径）；其余函数 eager 求值实参后委托 {@link ExprFunctionRegistry}。</li>
 *   <li>算术：整型运算保持 Integer，浮点提升为 Double；{@code /} 恒为 Double 除法。</li>
 *   <li>{@code +}：任一操作数为 String 时做字符串拼接。</li>
 *   <li>沙箱：未注册函数调用抛 {@link ExprException}（白名单即注册表）。</li>
 * </ul>
 *
 * <p>注：手写方案下本类不再继承 ANTLR4 生成的 ExprBaseVisitor；接口契约（各节点 visit
 * 方法）保持不变，未来切换 ANTLR4 时可改为继承 {@code ExprBaseVisitor&lt;Object&gt;} 并
 * 复用各 visit 方法实现。</p>
 */
public class ExprAstVisitor {

    private final ExprContext ctx;
    private final ExprFunctionRegistry registry;

    public ExprAstVisitor(ExprContext ctx, ExprFunctionRegistry registry) {
        this.ctx = ctx;
        this.registry = registry == null ? ctx.getFunctions() : registry;
    }

    /** 访问入口：按节点类型分发 */
    public Object visit(ExprNode node) {
        if (node == null) {
            return null;
        }
        if (node instanceof ExprNode.Literal) {
            return visitLiteral((ExprNode.Literal) node);
        }
        if (node instanceof ExprNode.FieldRef) {
            return visitFieldRef((ExprNode.FieldRef) node);
        }
        if (node instanceof ExprNode.Array) {
            return visitArray((ExprNode.Array) node);
        }
        if (node instanceof ExprNode.MapLit) {
            return visitMapLit((ExprNode.MapLit) node);
        }
        if (node instanceof ExprNode.Unary) {
            return visitUnary((ExprNode.Unary) node);
        }
        if (node instanceof ExprNode.Binary) {
            return visitBinary((ExprNode.Binary) node);
        }
        if (node instanceof ExprNode.Ternary) {
            return visitTernary((ExprNode.Ternary) node);
        }
        if (node instanceof ExprNode.Assign) {
            return visitAssign((ExprNode.Assign) node);
        }
        if (node instanceof ExprNode.FuncCall) {
            return visitFuncCall((ExprNode.FuncCall) node);
        }
        throw new ExprException("EXPR_EVAL_ERROR", "未知 AST 节点类型: " + node.getClass());
    }

    // ============ 各节点 visit 方法 ============

    protected Object visitLiteral(ExprNode.Literal node) {
        return node.value;
    }

    protected Object visitFieldRef(ExprNode.FieldRef node) {
        return ctx.getFieldValue(node.path);
    }

    protected Object visitArray(ExprNode.Array node) {
        List<Object> list = new ArrayList<>(node.elements.size());
        for (ExprNode e : node.elements) {
            list.add(visit(e));
        }
        return list;
    }

    protected Object visitMapLit(ExprNode.MapLit node) {
        Map<String, Object> map = new LinkedHashMap<>(node.keys.size());
        for (int i = 0; i < node.keys.size(); i++) {
            map.put(node.keys.get(i), visit(node.values.get(i)));
        }
        return map;
    }

    protected Object visitUnary(ExprNode.Unary node) {
        Object val = visit(node.operand);
        switch (node.op) {
            case "!":
                return !FuncUtil.toBool(val);
            case "-": {
                Number n = FuncUtil.toNumber(val);
                if (n == null) {
                    return 0;
                }
                if (FuncUtil.isIntegerNumber(n)) {
                    return Integer.valueOf((int) -n.longValue());
                }
                return -n.doubleValue();
            }
            default:
                throw new ExprException("EXPR_EVAL_ERROR", "未知一元运算符: " + node.op);
        }
    }

    protected Object visitBinary(ExprNode.Binary node) {
        // 逻辑短路
        if ("&&".equals(node.op)) {
            Object left = visit(node.left);
            if (!FuncUtil.toBool(left)) {
                return false;
            }
            return FuncUtil.toBool(visit(node.right));
        }
        if ("||".equals(node.op)) {
            Object left = visit(node.left);
            if (FuncUtil.toBool(left)) {
                return true;
            }
            return FuncUtil.toBool(visit(node.right));
        }

        Object left = visit(node.left);
        Object right = visit(node.right);

        switch (node.op) {
            case "+":
                // 任一为 String 则拼接
                if (left instanceof String || right instanceof String) {
                    return str(left) + str(right);
                }
                return arithmetic(left, right, "+");
            case "-":
            case "*":
            case "/":
            case "%":
                return arithmetic(left, right, node.op);
            case ">":
                return compare(left, right) > 0;
            case "<":
                return compare(left, right) < 0;
            case ">=":
                return compare(left, right) >= 0;
            case "<=":
                return compare(left, right) <= 0;
            case "==":
                return equals(left, right);
            case "!=":
                return !equals(left, right);
            default:
                throw new ExprException("EXPR_EVAL_ERROR", "未知二元运算符: " + node.op);
        }
    }

    protected Object visitTernary(ExprNode.Ternary node) {
        boolean cond = FuncUtil.toBool(visit(node.cond));
        return cond ? visit(node.thenExpr) : visit(node.elseExpr);
    }

    protected Object visitAssign(ExprNode.Assign node) {
        Object value = visit(node.value);
        ctx.setVariable(node.field, value);
        return value;
    }

    protected Object visitFuncCall(ExprNode.FuncCall node) {
        String name = node.name.toUpperCase();

        // IF 惰性求值：仅求值命中分支
        if ("IF".equals(name)) {
            if (node.args.size() != 3) {
                throw new ExprException("EXPR_EVAL_ERROR",
                        "IF 函数需要 3 个参数，实际 " + node.args.size());
            }
            boolean cond = FuncUtil.toBool(visit(node.args.get(0)));
            return cond ? visit(node.args.get(1)) : visit(node.args.get(2));
        }
        // AND 短路
        if ("AND".equals(name)) {
            for (ExprNode arg : node.args) {
                if (!FuncUtil.toBool(visit(arg))) {
                    return false;
                }
            }
            return true;
        }
        // OR 短路
        if ("OR".equals(name)) {
            for (ExprNode arg : node.args) {
                if (FuncUtil.toBool(visit(arg))) {
                    return true;
                }
            }
            return false;
        }

        // 其余函数：eager 求值实参后委托注册表
        ExprFunction function = registry.get(name);
        if (function == null) {
            throw new ExprException("EXPR_EVAL_ERROR",
                    "未知或未注册函数: " + node.name + "（不在沙箱白名单内）");
        }
        List<Object> args = new ArrayList<>(node.args.size());
        for (ExprNode arg : node.args) {
            args.add(visit(arg));
        }
        return function.execute(args, ctx);
    }

    // ============ 求值辅助 ============

    /** 算术运算：整型保持 Integer，浮点提升 Double；'/' 恒为 Double */
    private Number arithmetic(Object left, Object right, String op) {
        Number l = FuncUtil.toNumber(left);
        Number r = FuncUtil.toNumber(right);
        if (l == null || r == null) {
            throw new ExprException("EXPR_EVAL_ERROR",
                    "算术运算 '" + op + "' 操作数为 null");
        }
        boolean bothInt = FuncUtil.isIntegerNumber(l) && FuncUtil.isIntegerNumber(r);
        long lv = l.longValue();
        long rv = r.longValue();
        double ld = l.doubleValue();
        double rd = r.doubleValue();
        // 注意：不可使用 bothInt ? Integer.valueOf(...) : Double.valueOf(...) 三元表达式。
        // Java 二元数值提升会把 Integer 与 Double 两分支均拆箱提升为 double 再装箱为 Double，
        // 导致 bothInt 分支也返回 Double，整型保持失效。故此处使用 if/else 显式 return。
        switch (op) {
            case "+":
                if (bothInt) {
                    return Integer.valueOf((int) (lv + rv));
                }
                return Double.valueOf(ld + rd);
            case "-":
                if (bothInt) {
                    return Integer.valueOf((int) (lv - rv));
                }
                return Double.valueOf(ld - rd);
            case "*":
                if (bothInt) {
                    return Integer.valueOf((int) (lv * rv));
                }
                return Double.valueOf(ld * rd);
            case "/":
                return Double.valueOf(ld / rd);
            case "%":
                if (bothInt) {
                    return Integer.valueOf((int) (lv % rv));
                }
                return Double.valueOf(ld % rd);
            default:
                throw new ExprException("EXPR_EVAL_ERROR", "未知算术运算符: " + op);
        }
    }

    /** 比较：均为数字按 double 比较；均为字符串按字典序；否则尝试 Comparable */
    @SuppressWarnings({"rawtypes", "unchecked"})
    private int compare(Object left, Object right) {
        if (left instanceof Number && right instanceof Number) {
            return Double.compare(((Number) left).doubleValue(), ((Number) right).doubleValue());
        }
        if (left instanceof String && right instanceof String) {
            return ((String) left).compareTo((String) right);
        }
        if (left instanceof Comparable && left.getClass().isInstance(right)) {
            return ((Comparable) left).compareTo(right);
        }
        throw new ExprException("EXPR_EVAL_ERROR",
                "无法比较的类型: " + typeOf(left) + " 与 " + typeOf(right));
    }

    /** 相等：均为数字按 double 值比较；否则 Objects.equals（null 安全） */
    private boolean equals(Object left, Object right) {
        if (left instanceof Number && right instanceof Number) {
            return Double.compare(((Number) left).doubleValue(), ((Number) right).doubleValue()) == 0;
        }
        return Objects.equals(left, right);
    }

    private static String str(Object o) {
        return o == null ? "null" : o.toString();
    }

    private static String typeOf(Object o) {
        return o == null ? "null" : o.getClass().getSimpleName();
    }
}
