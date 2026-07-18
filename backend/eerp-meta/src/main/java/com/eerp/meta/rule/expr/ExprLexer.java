package com.eerp.meta.rule.expr;

import java.util.ArrayList;
import java.util.List;

/**
 * 手写词法分析器（Lexer / Tokenizer）。
 *
 * <p>将表达式字符串切分为 {@link Token} 序列，供 {@link ExprParser} 递归下降解析。
 * 支持的 token 类型见 {@link TokenType}。</p>
 *
 * <p>词法规则对齐 {@code Expr.g4}：字段引用（$ident(.ident)*）、整数、小数、单引号字符串
 * （支持反斜杠转义）、标识符、各类运算符与标点。空白跳过。</p>
 *
 * <p>注：本类为手写递归下降方案的一部分；当前未启用 antlr4-maven-plugin，故与 ANTLR4
 * 生成的 {@code com.eerp.meta.rule.expr.antlr.ExprLexer} 分包共存不冲突。</p>
 */
public class ExprLexer {

    /** Token 类型 */
    public enum TokenType {
        // 字面量与引用
        INT, DECIMAL, STRING, FIELD_REF, IDENT,
        // 运算符
        PLUS, MINUS, STAR, SLASH, PERCENT,
        GT, LT, GE, LE, EQ, NE,
        AND, OR, NOT,
        ASSIGN, QUESTION, COLON,
        // 标点
        LPAREN, RPAREN, LBRACKET, RBRACKET, LBRACE, RBRACE, COMMA, DOT,
        // 结束
        EOF
    }

    /** 词法 Token */
    public static class Token {
        public final TokenType type;
        public final String text;
        public final int pos;

        public Token(TokenType type, String text, int pos) {
            this.type = type;
            this.text = text;
            this.pos = pos;
        }

        @Override
        public String toString() {
            return type + "(" + text + ")@" + pos;
        }
    }

    private final String src;
    private final int len;
    private int i = 0;
    private final List<Token> tokens = new ArrayList<>();

    public ExprLexer(String src) {
        this.src = src == null ? "" : src;
        this.len = this.src.length();
    }

    /** 执行词法分析，返回 token 列表（末尾含 EOF） */
    public List<Token> tokenize() {
        while (i < len) {
            char c = src.charAt(i);
            // 空白跳过
            if (isWhitespace(c)) {
                i++;
                continue;
            }
            // 字段引用 $ident(.ident)*
            if (c == '$') {
                lexFieldRef();
                continue;
            }
            // 标识符 / 关键字 true|false|null
            if (isIdentStart(c)) {
                lexIdent();
                continue;
            }
            // 数字
            if (isDigit(c)) {
                lexNumber();
                continue;
            }
            // 字符串
            if (c == '\'') {
                lexString();
                continue;
            }
            // 运算符与标点
            lexOperator();
        }
        tokens.add(new Token(TokenType.EOF, "", i));
        return tokens;
    }

    private void lexFieldRef() {
        int start = i;
        i++; // 跳过 $
        if (i >= len || !isIdentStart(src.charAt(i))) {
            throw new ExprException("EXPR_PARSE_ERROR",
                    "字段引用 $ 后必须跟标识符，位置 " + start);
        }
        while (i < len && isIdentPart(src.charAt(i))) {
            i++;
        }
        // 点号链式访问
        while (i < len && src.charAt(i) == '.') {
            int dotPos = i;
            i++;
            if (i >= len || !isIdentStart(src.charAt(i))) {
                throw new ExprException("EXPR_PARSE_ERROR",
                        "字段引用 '.' 后必须跟标识符，位置 " + dotPos);
            }
            while (i < len && isIdentPart(src.charAt(i))) {
                i++;
            }
        }
        // text 不含前导 $，便于后续直接作为字段路径
        tokens.add(new Token(TokenType.FIELD_REF, src.substring(start + 1, i), start));
    }

    private void lexIdent() {
        int start = i;
        while (i < len && isIdentPart(src.charAt(i))) {
            i++;
        }
        tokens.add(new Token(TokenType.IDENT, src.substring(start, i), start));
    }

    private void lexNumber() {
        int start = i;
        while (i < len && isDigit(src.charAt(i))) {
            i++;
        }
        if (i < len && src.charAt(i) == '.' && i + 1 < len && isDigit(src.charAt(i + 1))) {
            i++; // 小数点
            while (i < len && isDigit(src.charAt(i))) {
                i++;
            }
            tokens.add(new Token(TokenType.DECIMAL, src.substring(start, i), start));
        } else {
            tokens.add(new Token(TokenType.INT, src.substring(start, i), start));
        }
    }

    private void lexString() {
        int start = i;
        i++; // 跳过开头 '
        StringBuilder sb = new StringBuilder();
        while (i < len) {
            char c = src.charAt(i);
            if (c == '\\') {
                // 转义：\' -> '，\\ -> \，\n -> 换行，\t -> 制表，其余保留反斜杠+字符
                if (i + 1 < len) {
                    char n = src.charAt(i + 1);
                    switch (n) {
                        case '\'': sb.append('\''); i += 2; continue;
                        case '\\': sb.append('\\'); i += 2; continue;
                        case 'n': sb.append('\n'); i += 2; continue;
                        case 't': sb.append('\t'); i += 2; continue;
                        case 'r': sb.append('\r'); i += 2; continue;
                        default: sb.append(n); i += 2; continue;
                    }
                } else {
                    sb.append(c);
                    i++;
                }
            } else if (c == '\'') {
                i++; // 跳过结尾 '
                tokens.add(new Token(TokenType.STRING, sb.toString(), start));
                return;
            } else {
                sb.append(c);
                i++;
            }
        }
        throw new ExprException("EXPR_PARSE_ERROR",
                "字符串字面量未闭合，缺少结尾单引号，位置 " + start);
    }

    private void lexOperator() {
        char c = src.charAt(i);
        int start = i;
        switch (c) {
            case '+': i++; tokens.add(new Token(TokenType.PLUS, "+", start)); return;
            case '-': i++; tokens.add(new Token(TokenType.MINUS, "-", start)); return;
            case '*': i++; tokens.add(new Token(TokenType.STAR, "*", start)); return;
            case '/': i++; tokens.add(new Token(TokenType.SLASH, "/", start)); return;
            case '%': i++; tokens.add(new Token(TokenType.PERCENT, "%", start)); return;
            case '>':
                i++;
                if (i < len && src.charAt(i) == '=') { i++; tokens.add(new Token(TokenType.GE, ">=", start)); }
                else { tokens.add(new Token(TokenType.GT, ">", start)); }
                return;
            case '<':
                i++;
                if (i < len && src.charAt(i) == '=') { i++; tokens.add(new Token(TokenType.LE, "<=", start)); }
                else { tokens.add(new Token(TokenType.LT, "<", start)); }
                return;
            case '=':
                i++;
                if (i < len && src.charAt(i) == '=') { i++; tokens.add(new Token(TokenType.EQ, "==", start)); }
                else { tokens.add(new Token(TokenType.ASSIGN, "=", start)); }
                return;
            case '!':
                i++;
                if (i < len && src.charAt(i) == '=') { i++; tokens.add(new Token(TokenType.NE, "!=", start)); }
                else { tokens.add(new Token(TokenType.NOT, "!", start)); }
                return;
            case '&':
                i++;
                if (i < len && src.charAt(i) == '&') { i++; tokens.add(new Token(TokenType.AND, "&&", start)); }
                else { throw new ExprException("EXPR_PARSE_ERROR", "未识别的符号 '&'，位置 " + start); }
                return;
            case '|':
                i++;
                if (i < len && src.charAt(i) == '|') { i++; tokens.add(new Token(TokenType.OR, "||", start)); }
                else { throw new ExprException("EXPR_PARSE_ERROR", "未识别的符号 '|'，位置 " + start); }
                return;
            case '?': i++; tokens.add(new Token(TokenType.QUESTION, "?", start)); return;
            case ':': i++; tokens.add(new Token(TokenType.COLON, ":", start)); return;
            case '(': i++; tokens.add(new Token(TokenType.LPAREN, "(", start)); return;
            case ')': i++; tokens.add(new Token(TokenType.RPAREN, ")", start)); return;
            case '[': i++; tokens.add(new Token(TokenType.LBRACKET, "[", start)); return;
            case ']': i++; tokens.add(new Token(TokenType.RBRACKET, "]", start)); return;
            case '{': i++; tokens.add(new Token(TokenType.LBRACE, "{", start)); return;
            case '}': i++; tokens.add(new Token(TokenType.RBRACE, "}", start)); return;
            case ',': i++; tokens.add(new Token(TokenType.COMMA, ",", start)); return;
            case '.': i++; tokens.add(new Token(TokenType.DOT, ".", start)); return;
            default:
                throw new ExprException("EXPR_PARSE_ERROR",
                        "未识别的字符 '" + c + "'，位置 " + start);
        }
    }

    private static boolean isWhitespace(char c) {
        return c == ' ' || c == '\t' || c == '\r' || c == '\n';
    }

    private static boolean isIdentStart(char c) {
        return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_';
    }

    private static boolean isIdentPart(char c) {
        return isIdentStart(c) || (c >= '0' && c <= '9');
    }

    private static boolean isDigit(char c) {
        return c >= '0' && c <= '9';
    }
}
