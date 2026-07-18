package com.eerp.common.exception;

/**
 * 业务异常
 */
public class ServiceException extends RuntimeException {

    private final String code;

    private final String message;

    public ServiceException(ErrorCode errorCode) {
        super(errorCode.name());
        this.code = errorCode.getCode();
        this.message = errorCode.name();
    }

    public ServiceException(String code, String message) {
        super(message);
        this.code = code;
        this.message = message;
    }

    public ServiceException(String code, String message, Throwable cause) {
        super(message, cause);
        this.code = code;
        this.message = message;
    }

    public String getCode() {
        return code;
    }

    @Override
    public String getMessage() {
        return message;
    }
}
