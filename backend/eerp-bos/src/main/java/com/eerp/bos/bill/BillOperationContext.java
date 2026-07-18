package com.eerp.bos.bill;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;

import java.util.Map;

/**
 * 单据操作上下文
 */
@Data
@Builder
@AllArgsConstructor
public class BillOperationContext {

    /** 业务对象编码 */
    private String boCode;

    /** 单据ID（新增时为空） */
    private Long billId;

    /** 操作类型：save/submit/audit/reject/revoke/delete/close/cancel */
    private String operation;

    /** 完整单据数据（主表+子表） */
    private Map<String, Object> billData;

    /** 操作用户ID */
    private Long userId;

    /** 操作用户名 */
    private String userName;

    /** 驳回/变更原因 */
    private String reason;
}
