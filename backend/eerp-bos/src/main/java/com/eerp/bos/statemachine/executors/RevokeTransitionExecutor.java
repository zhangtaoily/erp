package com.eerp.bos.statemachine.executors;

import com.eerp.bos.statemachine.AbstractStateTransitionExecutor;
import org.springframework.stereotype.Service;

/**
 * 撤销流转执行器（actionName=revoke）。
 * <p>
 * 默认 preCheck/postAction 行为；撤销含反提交（t7: 2→1）与反审核（t8: 3→1）。
 * 对齐设计文档 02 §5.1.3（t7/t8）。
 */
@Service
public class RevokeTransitionExecutor extends AbstractStateTransitionExecutor {

    public RevokeTransitionExecutor() {
        this.actionName = "revoke";
    }

    @Override
    public String getActionName() {
        return actionName;
    }
}
