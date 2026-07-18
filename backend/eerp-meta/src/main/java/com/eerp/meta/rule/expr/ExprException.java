package com.eerp.meta.rule.expr;

/**
 * 表达式引擎自定义异常。
 *
 * <p>由 {@code error('msg')} 函数在校验失败时抛出，也用于表达式求值过程中的语义错误
 * （如类型不匹配、字段不存在、沙箱校验失败等）。携带 errorCode + message，便于上层
 * 统一异常处理转换为 ServiceException。</p>
 *
 * <p>对齐设计文档 08《实体服务规则与反写规则设计》§3.2.3 RuleAstVisitor 错误抛出
 * 与 §3.5 事务边界（validate/available 失败抛 ServiceException(RULE_VALIDATE_FAIL)）。</p>
 */
public class ExprException extends RuntimeException {

    private static final long serialVersionUID = 1L;

    /** 错误码（如 RULE_VALIDATE_FAIL / EXPR_PARSE_ERROR / EXPR_EVAL_ERROR 等） */
    private final String errorCode;

    /** 错误消息 */
    private final String errorMessage;

    public ExprException(String errorCode, String errorMessage) {
        super(errorMessage);
        this.errorCode = errorCode;
        this.errorMessage = errorMessage;
    }

    public ExprException(String errorCode, String errorMessage, Throwable cause) {
        super(errorMessage, cause);
        this.errorCode = errorCode;
        this.errorMessage = errorMessage;
    }

    public String getErrorCode() {
        return errorCode;
    }

    public String getErrorMessage() {
        return errorMessage;
    }
}
