package com.eerp.meta.rule.expr;

import java.util.Collections;
import java.util.List;

/**
 * 表达式 AST 节点基类与所有节点类型定义。
 *
 * <p>采用嵌套静态类形式集中定义所有 AST 节点，便于 {@link ExprAstVisitor} 以 instanceof
 * 分发。节点本身是不可变数据结构，求值语义全部在 Visitor 中实现。</p>
 *
 * <p>节点层次（对齐 Expr.g4 语法规则）：</p>
 * <ul>
 *   <li>{@link Literal} —— 字面量（整数/小数/字符串/布尔/null）</li>
 *   <li>{@link FieldRef} —— 字段引用 $field 或 $entity.field</li>
 *   <li>{@link Array} —— 数组字面量 [a, b, c]</li>
 *   <li>{@link MapLit} —— Map 字面量 {k: v}</li>
 *   <li>{@link Unary} —— 一元运算 (! / -)</li>
 *   <li>{@link Binary} —— 二元运算（算术/比较/逻辑）</li>
 *   <li>{@link Ternary} —— 三元条件 cond ? a : b</li>
 *   <li>{@link Assign} —— 赋值 $field = expr</li>
 *   <li>{@link FuncCall} —— 函数调用</li>
 * </ul>
 */
public abstract class ExprNode {

    private ExprNode() {
    }

    /** 字面量 */
    public static final class Literal extends ExprNode {
        public final Object value;

        public Literal(Object value) {
            this.value = value;
        }
    }

    /** 字段引用：path 不含前导 $，如 "qty" 或 "detail.qty" */
    public static final class FieldRef extends ExprNode {
        public final String path;

        public FieldRef(String path) {
            this.path = path;
        }
    }

    /** 数组字面量 */
    public static final class Array extends ExprNode {
        public final List<ExprNode> elements;

        public Array(List<ExprNode> elements) {
            this.elements = elements == null ? Collections.emptyList() : elements;
        }
    }

    /** Map 字面量：keys 与 values 等长对齐 */
    public static final class MapLit extends ExprNode {
        public final List<String> keys;
        public final List<ExprNode> values;

        public MapLit(List<String> keys, List<ExprNode> values) {
            this.keys = keys == null ? Collections.emptyList() : keys;
            this.values = values == null ? Collections.emptyList() : values;
        }
    }

    /** 一元运算：op 为 "!" 或 "-" */
    public static final class Unary extends ExprNode {
        public final String op;
        public final ExprNode operand;

        public Unary(String op, ExprNode operand) {
            this.op = op;
            this.operand = operand;
        }
    }

    /** 二元运算：op 如 "+", "*", ">", "==", "&&" 等 */
    public static final class Binary extends ExprNode {
        public final String op;
        public final ExprNode left;
        public final ExprNode right;

        public Binary(String op, ExprNode left, ExprNode right) {
            this.op = op;
            this.left = left;
            this.right = right;
        }
    }

    /** 三元条件 cond ? thenExpr : elseExpr */
    public static final class Ternary extends ExprNode {
        public final ExprNode cond;
        public final ExprNode thenExpr;
        public final ExprNode elseExpr;

        public Ternary(ExprNode cond, ExprNode thenExpr, ExprNode elseExpr) {
            this.cond = cond;
            this.thenExpr = thenExpr;
            this.elseExpr = elseExpr;
        }
    }

    /** 赋值：$field = expr；field 不含前导 $ */
    public static final class Assign extends ExprNode {
        public final String field;
        public final ExprNode value;

        public Assign(String field, ExprNode value) {
            this.field = field;
            this.value = value;
        }
    }

    /** 函数调用 */
    public static final class FuncCall extends ExprNode {
        public final String name;
        public final List<ExprNode> args;

        public FuncCall(String name, List<ExprNode> args) {
            this.name = name;
            this.args = args == null ? Collections.emptyList() : args;
        }
    }
}
