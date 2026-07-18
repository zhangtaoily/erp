package com.eerp.bos.push;

import lombok.Data;

import java.util.ArrayList;
import java.util.List;

/**
 * 下推执行结果（对齐设计文档 02 §6.3 PushResultDTO）。
 */
@Data
public class PushResult {

    /** 是否成功 */
    private boolean success;

    /** 提示消息 */
    private String message;

    /** 生成的目标单据ID */
    private Long targetBillId;

    /** 关联记录数（写入 biz_bill_link 的行数） */
    private int linkCount;

    /** 错误明细（部分行下推失败时收集） */
    private List<String> errors = new ArrayList<>();

    /** 成功（携带目标单ID + 关联数） */
    public static PushResult ok(Long targetBillId, int linkCount) {
        PushResult r = new PushResult();
        r.success = true;
        r.targetBillId = targetBillId;
        r.linkCount = linkCount;
        r.message = "下推成功，生成 " + linkCount + " 行关联";
        return r;
    }

    /** 失败 */
    public static PushResult fail(String message) {
        PushResult r = new PushResult();
        r.success = false;
        r.message = message;
        return r;
    }

    /** 添加错误明细 */
    public void addError(String error) {
        if (errors == null) {
            errors = new ArrayList<>();
        }
        errors.add(error);
    }
}
