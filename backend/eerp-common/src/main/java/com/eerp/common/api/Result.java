package com.eerp.common.api;

import com.eerp.common.exception.ServiceException;
import lombok.Data;

/**
 * 统一响应结果
 */
@Data
public class Result<T> {

    /** "0" 表示成功 */
    private String code;

    private String message;

    private T data;

    public static <T> Result<T> ok(T data) {
        Result<T> r = new Result<>();
        r.code = "0";
        r.data = data;
        return r;
    }

    public static <T> Result<T> ok() {
        return ok(null);
    }

    public static <T> Result<T> fail(String code, String message) {
        Result<T> r = new Result<>();
        r.code = code;
        r.message = message;
        return r;
    }

    public static <T> Result<T> fail(ServiceException ex) {
        return fail(ex.getCode(), ex.getMessage());
    }

    public boolean success() {
        return "0".equals(code);
    }
}
