package com.eerp.bos.statemachine;

import com.eerp.meta.rule.expr.ExprContext;
import com.eerp.meta.rule.expr.ExprEvaluator;
import com.eerp.meta.rule.expr.ExprException;
import com.eerp.meta.statemachine.dto.StateTransitionResult;
import com.eerp.meta.statemachine.entity.MetaStateTransition;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.Map;

/**
 * 流转执行器抽象基类（策略模式）。
 * <p>
 * 不同 {@code actionName}（save/submit/audit/reject/revoke/close/cancel/...）
 * 由不同子类提供特化的 preCheck/postAction 逻辑。默认实现委托
 * {@link ExprEvaluator} 执行 {@code transition.preCheck} / {@code transition.postAction}
 * 表达式；子类可 override 增加特定校验或后置动作（如生成编码、立账、is_closed=1）。
 *
 * <p>对齐设计文档 02《单据操作与状态机设计》§3.5.1。</p>
 */
public abstract class AbstractStateTransitionExecutor {

    @Autowired
    protected ExprEvaluator exprEvaluator;

    /** 该执行器处理的 actionName（子类构造器赋值） */
    protected String actionName;

    /**
     * 返回该执行器处理的 actionName。
     *
     * @return actionName（如 save/submit/audit/...）
     */
    public abstract String getActionName();

    /**
     * 判断是否支持指定 actionName。
     *
     * @param actionName 待匹配的 actionName
     * @return 匹配返回 true
     */
    public boolean supports(String actionName) {
        String name = getActionName();
        return name != null && name.equals(actionName);
    }

    /**
     * 前置校验：默认委托 ExprEvaluator 执行 transition.preCheck 表达式。
     * 子类可 override 增加特定校验（如校验下游单据、可下推量）。
     *
     * @param transition 流转定义
     * @param exprCtx    表达式上下文
     * @return 校验通过返回 ok，否则返回 fail
     */
    public StateTransitionResult preCheck(MetaStateTransition transition, ExprContext exprCtx) {
        String preCheck = transition.getPreCheck();
        Integer fromState = transition.getFromState();
        Integer toState = transition.getToState();
        String actionName = transition.getActionName();

        if (preCheck == null || preCheck.trim().isEmpty()) {
            return StateTransitionResult.ok(fromState, toState, actionName, "前置校验通过（无配置）");
        }
        if (exprCtx == null) {
            return StateTransitionResult.fail(fromState,
                    "操作[" + actionName + "]前置校验需要表达式上下文");
        }
        try {
            Object result = exprEvaluator.evaluate(preCheck, exprCtx);
            if (result instanceof Boolean && (Boolean) result) {
                return StateTransitionResult.ok(fromState, toState, actionName, "前置校验通过");
            }
            return StateTransitionResult.fail(fromState,
                    "操作[" + actionName + "]前置校验未通过");
        } catch (ExprException e) {
            return StateTransitionResult.fail(fromState,
                    "操作[" + actionName + "]前置校验异常:" + e.getErrorMessage());
        }
    }

    /**
     * 后置动作：默认委托 ExprEvaluator 执行 transition.postAction 表达式。
     * 子类可 override 增加特定后置动作（如生成编码、立账、is_closed=1）。
     *
     * @param transition 流转定义
     * @param billId     单据ID
     * @param exprCtx    表达式上下文
     * @param extras     附加产物容器（子类向后置流程传递标记，如 needWf/needWriteback/isClosed）
     */
    public void postAction(MetaStateTransition transition, Long billId, ExprContext exprCtx, Map<String, Object> extras) {
        String postAction = transition.getPostAction();
        if (postAction == null || postAction.trim().isEmpty()) {
            return;
        }
        if (exprCtx == null) {
            return;
        }
        try {
            exprEvaluator.evaluate(postAction, exprCtx);
        } catch (ExprException e) {
            // 默认实现仅吞掉异常（后置动作不应阻断主流程）；子类可 override 处理异常
        }
    }
}
