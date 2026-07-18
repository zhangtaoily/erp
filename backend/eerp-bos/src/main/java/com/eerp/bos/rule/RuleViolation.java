package com.eerp.bos.rule;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 规则违反信息（规则执行结果 DTO）。
 *
 * <p>由 {@link AbstractRuleEngine#executeRule} 返回，描述单条规则的违反情况。
 * 当 {@link #block} 为 true 时，上层操作（保存/提交/审核）需回滚事务（对齐设计文档 08 §3.5）。</p>
 */
@Data
@AllArgsConstructor
@NoArgsConstructor
public class RuleViolation {

    /** 规则编码 */
    private String ruleCode;

    /** 违反提示信息 */
    private String message;

    /** 严重级别：ERROR / WARNING / INFO */
    private String severity;

    /** 是否阻断后续流程（true 时上层操作回滚） */
    private boolean block;
}
