package com.eerp.meta.rule.expr;

import com.eerp.meta.rule.expr.ExprLexer.Token;
import com.eerp.meta.rule.expr.ExprLexer.TokenType;

import java.util.ArrayList;
import java.util.List;

/**
 * 手写递归下降解析器（Parser）。
 *
 * <p>消费 {@link ExprLexer} 产生的 token 序列，按 {@code Expr.g4} 定义的优先级层次
 * 构造 {@link ExprNode} AST。优先级（从低到高）：</p>
 *
 * <pre>
 *   assignment  ($f = expr，右结合，LHS 必须为字段引用)
 *   ternary     cond ? a : b
 *   logicOr     ||
 *   logicAnd    &&
 *   equality    == !=
 *   comparison  &gt; &lt; &gt;= &lt;=
 *   addition    + -
 *   multiplication * / %
 *   unary       ! -
 *   primary     字面量 / 字段引用 / 函数调用 / (expr) / 数组 / Map
 * </pre>
 *
 * <p>注：本类为手写递归下降方案的一部分；当前未启用 antlr4-maven-plugin，故与 ANTLR4
 * 生成的 {@code com.eerp.meta.rule.expr.antlr.ExprParser} 分包共存不冲突。</p>
 */
public class ExprParser {

    private final List<Token> tokens;
    private int pos = 0;

    public ExprParser(List<Token> tokens) {
        this.tokens = tokens;
    }

    public ExprParser(ExprLexer lexer) {
        this.tokens = lexer.tokenize();
    }

    /** 解析入口：返回 AST 根节点 */
    public ExprNode parse() {
        ExprNode node = expression();
        expect(TokenType.EOF, "表达式末尾存在多余内容");
        return node;
    }

    // ============ 文法规则 ============

    private ExprNode expression() {
        return assignment();
    }

    /** assignment: ternary ('=' expression)? —— 右结合，LHS 必须为字段引用 */
    private ExprNode assignment() {
        ExprNode left = ternary();
        if (peek().type == TokenType.ASSIGN) {
            Token assign = next();
            ExprNode rhs = expression();
            if (!(left instanceof ExprNode.FieldRef)) {
                throw new ExprException("EXPR_PARSE_ERROR",
                        "赋值左值必须为字段引用 $field，位置 " + assign.pos);
            }
            String field = ((ExprNode.FieldRef) left).path;
            return new ExprNode.Assign(field, rhs);
        }
        return left;
    }

    /** ternary: logicOr ('?' expression ':' ternary)? */
    private ExprNode ternary() {
        ExprNode cond = logicOr();
        if (peek().type == TokenType.QUESTION) {
            next();
            ExprNode thenExpr = expression();
            expect(TokenType.COLON, "三元表达式缺少 ':'");
            ExprNode elseExpr = ternary();
            return new ExprNode.Ternary(cond, thenExpr, elseExpr);
        }
        return cond;
    }

    private ExprNode logicOr() {
        ExprNode left = logicAnd();
        while (peek().type == TokenType.OR) {
            next();
            ExprNode right = logicAnd();
            left = new ExprNode.Binary("||", left, right);
        }
        return left;
    }

    private ExprNode logicAnd() {
        ExprNode left = equality();
        while (peek().type == TokenType.AND) {
            next();
            ExprNode right = equality();
            left = new ExprNode.Binary("&&", left, right);
        }
        return left;
    }

    private ExprNode equality() {
        ExprNode left = comparison();
        while (peek().type == TokenType.EQ || peek().type == TokenType.NE) {
            String op = next().text;
            ExprNode right = comparison();
            left = new ExprNode.Binary(op, left, right);
        }
        return left;
    }

    private ExprNode comparison() {
        ExprNode left = addition();
        while (peek().type == TokenType.GT || peek().type == TokenType.LT
                || peek().type == TokenType.GE || peek().type == TokenType.LE) {
            String op = next().text;
            ExprNode right = addition();
            left = new ExprNode.Binary(op, left, right);
        }
        return left;
    }

    private ExprNode addition() {
        ExprNode left = multiplication();
        while (peek().type == TokenType.PLUS || peek().type == TokenType.MINUS) {
            String op = next().text;
            ExprNode right = multiplication();
            left = new ExprNode.Binary(op, left, right);
        }
        return left;
    }

    private ExprNode multiplication() {
        ExprNode left = unary();
        while (peek().type == TokenType.STAR || peek().type == TokenType.SLASH
                || peek().type == TokenType.PERCENT) {
            String op = next().text;
            ExprNode right = unary();
            left = new ExprNode.Binary(op, left, right);
        }
        return left;
    }

    private ExprNode unary() {
        if (peek().type == TokenType.NOT) {
            next();
            return new ExprNode.Unary("!", unary());
        }
        if (peek().type == TokenType.MINUS) {
            next();
            return new ExprNode.Unary("-", unary());
        }
        return primary();
    }

    private ExprNode primary() {
        Token t = peek();
        switch (t.type) {
            case INT:
                next();
                return new ExprNode.Literal(parseInteger(t.text));
            case DECIMAL:
                next();
                return new ExprNode.Literal(Double.valueOf(t.text));
            case STRING:
                next();
                return new ExprNode.Literal(t.text);
            case FIELD_REF:
                next();
                return new ExprNode.FieldRef(t.text);
            case LPAREN: {
                next();
                ExprNode inner = expression();
                expect(TokenType.RPAREN, "缺少右括号 ')'");
                return inner;
            }
            case LBRACKET:
                return arrayLiteral();
            case LBRACE:
                return mapLiteral();
            case IDENT:
                return identOrKeyword();
            default:
                throw new ExprException("EXPR_PARSE_ERROR",
                        "非预期的 token " + t.type + "('" + t.text + "')，位置 " + t.pos);
        }
    }

    private ExprNode identOrKeyword() {
        Token t = next();
        // 关键字字面量
        if ("true".equals(t.text)) {
            return new ExprNode.Literal(Boolean.TRUE);
        }
        if ("false".equals(t.text)) {
            return new ExprNode.Literal(Boolean.FALSE);
        }
        if ("null".equals(t.text)) {
            return new ExprNode.Literal(null);
        }
        // 函数调用：IDENT '(' args ')'
        if (peek().type == TokenType.LPAREN) {
            next(); // 消费 (
            List<ExprNode> args = new ArrayList<>();
            if (peek().type != TokenType.RPAREN) {
                args.add(expression());
                while (peek().type == TokenType.COMMA) {
                    next();
                    args.add(expression());
                }
            }
            expect(TokenType.RPAREN, "函数调用缺少右括号 ')'");
            return new ExprNode.FuncCall(t.text, args);
        }
        throw new ExprException("EXPR_PARSE_ERROR",
                "裸标识符 '" + t.text + "' 非法；字段引用须以 $ 开头，位置 " + t.pos);
    }

    private ExprNode arrayLiteral() {
        expect(TokenType.LBRACKET, "数组字面量缺少 '['");
        List<ExprNode> elements = new ArrayList<>();
        if (peek().type != TokenType.RBRACKET) {
            elements.add(expression());
            while (peek().type == TokenType.COMMA) {
                next();
                elements.add(expression());
            }
        }
        expect(TokenType.RBRACKET, "数组字面量缺少 ']'");
        return new ExprNode.Array(elements);
    }

    private ExprNode mapLiteral() {
        expect(TokenType.LBRACE, "Map 字面量缺少 '{'");
        List<String> keys = new ArrayList<>();
        List<ExprNode> values = new ArrayList<>();
        if (peek().type != TokenType.RBRACE) {
            mapEntry(keys, values);
            while (peek().type == TokenType.COMMA) {
                next();
                mapEntry(keys, values);
            }
        }
        expect(TokenType.RBRACE, "Map 字面量缺少 '}'");
        return new ExprNode.MapLit(keys, values);
    }

    private void mapEntry(List<String> keys, List<ExprNode> values) {
        Token key = peek();
        String keyName;
        if (key.type == TokenType.IDENT) {
            next();
            keyName = key.text;
        } else if (key.type == TokenType.STRING) {
            next();
            keyName = key.text;
        } else {
            throw new ExprException("EXPR_PARSE_ERROR",
                    "Map key 必须为标识符或字符串，位置 " + key.pos);
        }
        expect(TokenType.COLON, "Map 条目缺少 ':'");
        values.add(expression());
        keys.add(keyName);
    }

    // ============ 工具方法 ============

    /** 整数字面量解析：优先 Integer，溢出则 Long */
    private static Number parseInteger(String text) {
        long v = Long.parseLong(text);
        if (v >= Integer.MIN_VALUE && v <= Integer.MAX_VALUE) {
            return Integer.valueOf((int) v);
        }
        return Long.valueOf(v);
    }

    private Token peek() {
        return tokens.get(pos);
    }

    private Token next() {
        return tokens.get(pos++);
    }

    private void expect(TokenType type, String msg) {
        Token t = peek();
        if (t.type != type) {
            throw new ExprException("EXPR_PARSE_ERROR",
                    msg + "；期望 " + type + "，实际 " + t.type + "('" + t.text + "')，位置 " + t.pos);
        }
        pos++;
    }
}
