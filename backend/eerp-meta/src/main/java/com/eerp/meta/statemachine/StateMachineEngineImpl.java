package com.eerp.meta.statemachine;

import com.eerp.meta.cache.StateMachineCache;
import com.eerp.meta.rule.expr.ExprContext;
import com.eerp.meta.rule.expr.ExprEvaluator;
import com.eerp.meta.rule.expr.ExprException;
import com.eerp.meta.statemachine.dto.StateTransitionResult;
import com.eerp.meta.statemachine.entity.MetaStateTransition;
import com.eerp.meta.statemachine.vo.StateMachineMetaVO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * 状态机引擎实现。
 * <p>
 * Phase 1：仅做 transition 查找与校验，不实际更新数据库（由 eerp-bos 的 GenericBillService 负责落库）。
 * Phase 2（A2）：补全 matchTransition / validateTransition / executeTransition，
 * 支持 pre_check 表达式执行；post_action 表达式文本随结果回填，由上层执行器策略执行。
 */
@Service
public class StateMachineEngineImpl extends AbstractStateMachineEngine {

    @Autowired
    private StateMachineCache stateMachineCache;

    @Autowired
    private ExprEvaluator exprEvaluator;

    @Override
    public StateTransitionResult execute(String boCode, Long billId, String buttonCode, String reason) {
        // 1. 匹配流转
        MetaStateTransition matched = matchTransition(boCode, buttonCode);
        if (matched == null) {
            // 区分三种缺失场景，保持 Phase 1 失败信息语义
            StateMachineMetaVO meta = stateMachineCache.get(boCode);
            if (meta == null || meta.getStateMachine() == null) {
                return StateTransitionResult.fail(null, "业务对象[" + boCode + "]未配置状态机");
            }
            List<MetaStateTransition> transitions = meta.getTransitions();
            if (transitions == null || transitions.isEmpty()) {
                return StateTransitionResult.fail(null, "业务对象[" + boCode + "]未配置状态流转");
            }
            return StateTransitionResult.fail(null, "按钮[" + buttonCode + "]在业务对象[" + boCode + "]下未配置状态流转");
        }

        // 2. Phase 1 兼容：不查询数据库，以 transition.fromState 作为校验基准（始终通过）
        validateTransition(matched.getFromState(), matched);

        // 3. 执行流转（Phase 1 无表达式上下文，传 null；preCheck 为空时跳过表达式求值）
        return executeTransition(matched, billId, reason, null);
    }

    @Override
    public MetaStateTransition matchTransition(String boCode, String buttonCode) {
        StateMachineMetaVO meta = stateMachineCache.get(boCode);
        if (meta == null || meta.getStateMachine() == null) {
            return null;
        }
        List<MetaStateTransition> transitions = meta.getTransitions();
        if (transitions == null || transitions.isEmpty()) {
            return null;
        }
        for (MetaStateTransition t : transitions) {
            if (buttonCode != null && buttonCode.equals(t.getButtonCode())) {
                return t;
            }
        }
        return null;
    }

    @Override
    public boolean validateTransition(Integer fromState, MetaStateTransition transition) {
        if (fromState == null || transition == null) {
            return false;
        }
        return fromState.equals(transition.getFromState());
    }

    @Override
    public StateTransitionResult executeTransition(MetaStateTransition transition, Long billId,
                                                   String reason, ExprContext exprCtx) {
        Integer fromState = transition.getFromState();
        Integer toState = transition.getToState();
        String actionName = transition.getActionName();

        // 1. 执行 pre_check 表达式（若配置）
        String preCheck = transition.getPreCheck();
        if (preCheck != null && !preCheck.trim().isEmpty()) {
            if (exprCtx == null) {
                return StateTransitionResult.fail(fromState,
                        "操作[" + actionName + "]前置校验需要表达式上下文");
            }
            try {
                Object checkResult = exprEvaluator.evaluate(preCheck, exprCtx);
                if (!(checkResult instanceof Boolean) || !(Boolean) checkResult) {
                    return StateTransitionResult.fail(fromState,
                            "操作[" + actionName + "]前置校验未通过");
                }
            } catch (ExprException e) {
                return StateTransitionResult.fail(fromState,
                        "操作[" + actionName + "]前置校验异常:" + e.getErrorMessage());
            }
        }

        // 2. 校验 reason（若 requireReason=1）
        Integer requireReason = transition.getRequireReason();
        if (requireReason != null && requireReason == 1
                && (reason == null || reason.trim().isEmpty())) {
            return StateTransitionResult.fail(fromState,
                    "操作[" + actionName + "]要求填写原因");
        }

        // 3. 校验通过，返回流转结果（post_action 表达式交给上层执行）
        StateTransitionResult result = StateTransitionResult.ok(fromState, toState, actionName,
                "操作[" + actionName + "]校验通过");
        result.setPostActionExpr(transition.getPostAction());
        return result;
    }
}
