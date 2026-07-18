package com.eerp.bos.statemachine.executors;

import com.eerp.bos.statemachine.AbstractStateTransitionExecutor;
import org.springframework.stereotype.Service;

/**
 * 默认流转执行器（actionName=default）。
 * <p>
 * preCheck 与 postAction 均走 {@link AbstractStateTransitionExecutor} 默认逻辑
 * （委托 ExprEvaluator 执行 transition.preCheck / postAction 表达式）。
 * <p>
 * 当 {@link com.eerp.bos.statemachine.TransitionExecutorFactory} 找不到匹配的
 * actionName 时返回本执行器，保证任意流转均有可执行的处理逻辑。
 */
@Service
public class DefaultTransitionExecutor extends AbstractStateTransitionExecutor {

    public DefaultTransitionExecutor() {
        this.actionName = "default";
    }

    @Override
    public String getActionName() {
        return actionName;
    }
}
