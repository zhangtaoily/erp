package com.eerp.bos.statemachine;

import com.eerp.bos.statemachine.executors.DefaultTransitionExecutor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 流转执行器注册表（注册表模式）。
 * <p>
 * 启动时将所有 {@link AbstractStateTransitionExecutor} 实现按 {@code actionName}
 * 注册到内存映射，提供 O(1) 查询。对齐设计文档 02 §2.2 / §3.5.1。
 */
@Service
public class TransitionExecutorRegistry {

    /** actionName -> executor 缓存映射 */
    private final Map<String, AbstractStateTransitionExecutor> registry = new ConcurrentHashMap<>();

    private final DefaultTransitionExecutor defaultExecutor;

    @Autowired
    public TransitionExecutorRegistry(List<AbstractStateTransitionExecutor> executors,
                                      DefaultTransitionExecutor defaultExecutor) {
        this.defaultExecutor = defaultExecutor;
        if (executors != null) {
            for (AbstractStateTransitionExecutor executor : executors) {
                String name = executor.getActionName();
                if (name != null) {
                    registry.put(name, executor);
                }
            }
        }
    }

    /**
     * 按 actionName 查询执行器；未命中返回默认执行器。
     *
     * @param actionName 流转动作名称
     * @return 匹配的执行器或默认执行器
     */
    public AbstractStateTransitionExecutor get(String actionName) {
        if (actionName == null) {
            return defaultExecutor;
        }
        AbstractStateTransitionExecutor executor = registry.get(actionName);
        return executor == null ? defaultExecutor : executor;
    }
}
