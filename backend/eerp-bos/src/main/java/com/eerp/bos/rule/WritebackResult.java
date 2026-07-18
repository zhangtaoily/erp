package com.eerp.bos.rule;

import lombok.Data;

import java.util.ArrayList;
import java.util.List;

/**
 * 反写执行结果 DTO。
 *
 * <p>由 {@link AbstractWritebackService#executeWriteback} 返回，汇总本次反写执行的统计信息。</p>
 */
@Data
public class WritebackResult {

    /** 是否全部成功（无错误） */
    private boolean success;

    /** 总规则数 */
    private int totalRules;

    /** 成功执行规则数 */
    private int successRules;

    /** 错误信息列表（SYNC 失败 / ASYNC 失败记录） */
    private List<String> errors = new ArrayList<>();

    /** 告警信息列表（超限 WARN 等） */
    private List<String> warnings = new ArrayList<>();

    /** 累加错误信息 */
    public void addError(String error) {
        if (error != null) {
            this.errors.add(error);
        }
    }

    /** 累加告警信息 */
    public void addWarning(String warning) {
        if (warning != null) {
            this.warnings.add(warning);
        }
    }
}
