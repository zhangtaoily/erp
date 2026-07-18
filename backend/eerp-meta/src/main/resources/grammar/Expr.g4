/*
 * Expr.g4 —— 平台基座表达式引擎语法（combined grammar）
 *
 * 说明：
 *   - 本文件是表达式语法的正式规范定义，与手写递归下降解析器（ExprLexer/ExprParser）
 *     所接受的语法保持一致。当前运行时采用手写解析器实现，未激活 antlr4-maven-plugin；
 *     未来切换至 ANTLR4 代码生成方案时，在 eerp-meta/pom.xml 的 build/plugins 中激活
 *     antlr4-maven-plugin（sourceDirectory=src/main/resources/grammar，
 *     outputDirectory=${project.build.directory}/generated-sources/antlr4，
 *     listener=false，visitor=true），生成的代码将落入 com.eerp.meta.rule.expr.antlr
 *     子包（见 @header），与手写实现类（com.eerp.meta.rule.expr.ExprLexer/ExprParser）
 *     分包，避免类名冲突。
 *   - 语法对齐设计文档 06《编码规则与插件机制设计》§3.2.11 脚本表达式引擎与
 *     08《实体服务规则与反写规则设计》§3.2.2/§3.2.3 bos-expr 表达式语法。
 *
 * 支持特性：
 *   1. 字段引用：$field_name 或 $entity.field（$ 开头标识符，支持点号访问子实体）
 *   2. 字面量：整数、小数、字符串（单引号）、true/false/null
 *   3. 算术：+ - * / %
 *   4. 比较：> < >= <= == !=
 *   5. 逻辑：&& || !
 *   6. 三元：condition ? thenExpr : elseExpr
 *   7. 赋值：$field = expr（联动规则用，返回赋值后的值；LHS 必须为字段引用）
 *   8. 校验：error('msg') 函数抛校验异常
 *   9. 函数调用：SUM/COUNT/AVG/MAX/MIN/IF/LOOKUP 等
 *  10. 括号分组：(expr)
 *  11. 数组字面量：[a, b, c]
 *  12. Map 字面量：{key: val}
 */
grammar Expr;

@header {
package com.eerp.meta.rule.expr.antlr;
}

// ============ Parser 规则 ============

/// 入口：单个表达式 + EOF
program: expression EOF;

/// 表达式（赋值优先级最低，右结合）
/// 赋值左值在语法层允许为任意 ternary，求值期校验必须为字段引用
expression
    : assignment
    ;

assignment
    : ternary ('=' expression)?
    ;

/// 三元条件表达式
ternary
    : logicOr ('?' expression ':' ternary)?
    ;

/// 逻辑或（短路）
logicOr
    : logicAnd ('||' logicAnd)*
    ;

/// 逻辑与（短路）
logicAnd
    : equality ('&&' equality)*
    ;

/// 相等性比较
equality
    : comparison (('==' | '!=') comparison)*
    ;

/// 大小比较
comparison
    : addition (('>' | '<' | '>=' | '<=') addition)*
    ;

/// 加减
addition
    : multiplication (('+' | '-') multiplication)*
    ;

/// 乘除模
multiplication
    : unary (('*' | '/' | '%') unary)*
    ;

/// 一元（逻辑非 / 负号）
unary
    : ('!' | '-') unary
    | primary
    ;

/// 基础项
primary
    : literal
    | fieldRef
    | functionCall
    | '(' expression ')'
    | arrayLiteral
    | mapLiteral
    ;

/// 字段引用：$field 或 $entity.field
fieldRef
    : FIELD_REF
    ;

/// 函数调用
functionCall
    : IDENT '(' argumentList? ')'
    ;

/// 实参列表
argumentList
    : expression (',' expression)*
    ;

/// 数组字面量
arrayLiteral
    : '[' argumentList? ']'
    ;

/// Map 字面量
mapLiteral
    : '{' mapEntry (',' mapEntry)* '}'
    | '{' '}'
    ;

/// Map 条目
mapEntry
    : (IDENT | STRING) ':' expression
    ;

/// 字面量
literal
    : INTEGER
    | DECIMAL
    | STRING
    | BOOL
    | 'null'
    ;

// ============ Lexer 规则 ============

/// 布尔字面量（置于 IDENT 之前，保证 true/false 优先识别为 BOOL）
BOOL: 'true' | 'false';

/// 字段引用：$ 开头 + 标识符（支持点号链式访问子实体）
FIELD_REF: '$' IDENT ('.' IDENT)*;

/// 标识符（函数名、Map key 等）
IDENT: [a-zA-Z_][a-zA-Z0-9_]*;

/// 整数字面量
INTEGER: [0-9]+;

/// 小数字面量
DECIMAL: [0-9]+ '.' [0-9]+;

/// 字符串字面量（单引号，支持反斜杠转义）
STRING: '\'' (~'\'' | '\\' .)* '\'';

/// 空白跳过
WS: [ \t\r\n]+ -> skip;
