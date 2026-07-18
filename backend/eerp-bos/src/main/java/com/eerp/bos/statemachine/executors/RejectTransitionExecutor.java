package com.eerp.bos.statemachine.executors;

import com.eerp.bos.statemachine.AbstractStateTransitionExecutor;
import org.springframework.stereotype.Service;

/**
 * 驳回流转执行器（actionName=reject）。
 * <p>
 * 默认 preCheck/postAction 行为；驳回操作的 requireReason=1 由状态机引擎校验。
 * 对齐设计文档 02 §5.1.3（t5: 2已提交 → 4已驳回，require_reason=1）。
 */
@Service
public class RejectTransitionExecutor extends AbstractStateTransitionExecutor {

    public RejectTransitionExecutor() {
        this.actionName = "reject";
    }

    @Override
    public String getActionName() {
        return actionName;
    }
}
