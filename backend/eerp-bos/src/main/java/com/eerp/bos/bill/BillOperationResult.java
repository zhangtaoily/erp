package com.eerp.bos.bill;

import lombok.Data;

/**
 * 单据操作结果
 */
@Data
public class BillOperationResult {

    private boolean success;

    private String message;

    private Object data;

    public static BillOperationResult ok(Object data) {
        BillOperationResult r = new BillOperationResult();
        r.success = true;
        r.data = data;
        return r;
    }

    public static BillOperationResult ok() {
        BillOperationResult r = new BillOperationResult();
        r.success = true;
        return r;
    }

    public static BillOperationResult fail(String message) {
        BillOperationResult r = new BillOperationResult();
        r.success = false;
        r.message = message;
        return r;
    }
}
