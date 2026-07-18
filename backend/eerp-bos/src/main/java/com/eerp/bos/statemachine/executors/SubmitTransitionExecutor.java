package com.eerp.bos.statemachine.executors;

import com.eerp.bos.statemachine.AbstractStateTransitionExecutor;
import com.eerp.meta.rule.expr.ExprContext;
import com.eerp.meta.statemachine.entity.MetaStateTransition;
import org.springframework.stereotype.Service;

import java.util.Map;

/**
 * 提交流转执行器（actionName=submit）。
 * <p>
 * postAction：当 transition.needWf=1 时，标记单据需要推送外部工作流
 * （extras.put("needWf", true)），由上层 OperationService 在事务后阶段推送。
 * 对齐设计文档 02 §6.1（t3: 1已创建 → 2已提交，need_wf=1）。
 */
@Service
public class SubmitTransitionExecutor extends AbstractStateTransitionExecutor {

    public SubmitTransitionExecutor() {
        this.actionName = "submit";
    }

    @Override
    public String getActionName() {
        return actionName;
    }

    @Override
    public void postAction(MetaStateTransition transition, Long billId, ExprContext exprCtx, Map<String, Object> extras) {
        super.postAction(transition, billId, exprCtx, extras);
        if (extras != null && transition.getNeedWf() != null && transition.getNeedWf() == 1) {
            extras.put("needWf", true);
        }
    }
}
