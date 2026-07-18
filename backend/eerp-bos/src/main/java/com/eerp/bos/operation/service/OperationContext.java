package com.eerp.bos.operation.service;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Map;

/**
 * 操作编排上下文（对齐设计文档 02 §3.5）。
 *
 * <p>承载单据操作的全部入参：业务对象编码、单据 ID（新增时为空）、操作类型、
 * 完整单据数据（主表 + 子表）、操作用户信息、驳回/变更原因。</p>
 *
 * <p>由 {@link AbstractOperationService#executeOperation} 消费，贯穿 6 阶段流水线全链路。</p>
 */
@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class OperationContext {

    /** 业务对象编码 */
    private String boCode;

    /** 单据 ID（新增时为空） */
    private Long billId;

    /** 操作类型：save/draft/submit/audit/reject/revoke/close/cancel/delete */
    private String operation;

    /** 完整单据数据（主表 + 子表，结构：{main: {...}, subs: {entity_code: [...]}}） */
    private Map<String, Object> billData;

    /** 操作用户 ID */
    private Long userId;

    /** 操作用户名 */
    private String userName;

    /** 驳回/变更原因 */
    private String reason;
}
