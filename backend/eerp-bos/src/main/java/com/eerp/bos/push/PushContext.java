package com.eerp.bos.push;

import lombok.Data;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

/**
 * 下推上下文（对齐设计文档 02 §3.9 PushContextDTO）。
 *
 * <p>由前端 {@code PushDialog} 提交，作为 {@code AbstractPushService.push} 的入参。</p>
 */
@Data
public class PushContext {

    /** 源业务对象编码 */
    private String srcBoCode;

    /** 源单据ID */
    private Long srcBillId;

    /** 目标业务对象编码 */
    private String tgtBoCode;

    /** 下推规则编码 */
    private String ruleCode;

    /** 行勾选 + 本次下推量 */
    private List<PushLine> lines = new ArrayList<>();

    /** 是否允许合并下推（多源单→一目标单） */
    private Boolean allowMerge;

    /** 是否允许拆分下推（一源单行→多目标单） */
    private Boolean allowSplit;

    /** 操作人ID */
    private Long userId;

    /** 操作人姓名 */
    private String userName;

    /** 附加数据（透传） */
    private java.util.Map<String, Object> extras;
}
