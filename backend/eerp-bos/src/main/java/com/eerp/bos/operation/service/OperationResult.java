package com.eerp.bos.operation.service;

import lombok.Data;

import java.util.HashMap;
import java.util.Map;

/**
 * 操作编排结果（对齐设计文档 02 §3.5）。
 *
 * <p>由 {@link AbstractOperationService#executeOperation} 返回，承载操作成败、提示消息、
 * 单据 ID、附加产物（needWf/needWriteback 等流转执行器标记）。</p>
 */
@Data
public class OperationResult {

    /** 是否成功 */
    private boolean success;

    /** 提示信息 */
    private String message;

    /** 单据 ID（save 操作返回） */
    private Long billId;

    /** 附加数据 */
    private Object data;

    /** 附加产物（流转执行器 postAction 写入：needWf/needWriteback/needVoucher/isClosed/isCancel） */
    private Map<String, Object> extras = new HashMap<>();

    /** 成功（携带单据 ID） */
    public static OperationResult ok(Long billId) {
        OperationResult r = new OperationResult();
        r.success = true;
        r.billId = billId;
        return r;
    }

    /** 成功（携带消息） */
    public static OperationResult ok(String message) {
        OperationResult r = new OperationResult();
        r.success = true;
        r.message = message;
        return r;
    }

    /** 成功（携带单据 ID 和消息） */
    public static OperationResult ok(Long billId, String message) {
        OperationResult r = new OperationResult();
        r.success = true;
        r.billId = billId;
        r.message = message;
        return r;
    }

    /** 失败 */
    public static OperationResult fail(String message) {
        OperationResult r = new OperationResult();
        r.success = false;
        r.message = message;
        return r;
    }
}
