package com.eerp.bos.statemachine;

import com.eerp.bos.statemachine.executors.DefaultTransitionExecutor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * 流转执行器工厂（工厂模式）。
 * <p>
 * 注入 Spring 自动收集的所有 {@link AbstractStateTransitionExecutor} 实现，
 * 按 {@code actionName} 匹配；无匹配返回 {@link DefaultTransitionExecutor}。
 * 对齐设计文档 02 §2.2 / §3.5.1。
 */
@Service
public class TransitionExecutorFactory {

    private final List<AbstractStateTransitionExecutor> executors;

    private final DefaultTransitionExecutor defaultExecutor;

    @Autowired
    public TransitionExecutorFactory(List<AbstractStateTransitionExecutor> executors,
                                     DefaultTransitionExecutor defaultExecutor) {
        this.executors = executors;
        this.defaultExecutor = defaultExecutor;
    }

    /**
     * 按 actionName 获取执行器；未知 actionName 返回默认执行器。
     *
     * @param actionName 流转动作名称（save/submit/audit/...）
     * @return 匹配的执行器或默认执行器
     */
    public AbstractStateTransitionExecutor getExecutor(String actionName) {
        if (actionName != null && executors != null) {
            for (AbstractStateTransitionExecutor executor : executors) {
                if (executor.supports(actionName)) {
                    return executor;
                }
            }
        }
        return defaultExecutor;
    }
}
