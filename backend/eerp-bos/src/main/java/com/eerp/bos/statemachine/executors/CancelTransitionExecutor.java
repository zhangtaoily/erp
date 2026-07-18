package com.eerp.bos.statemachine.executors;

import com.eerp.bos.statemachine.AbstractStateTransitionExecutor;
import com.eerp.meta.rule.expr.ExprContext;
import com.eerp.meta.statemachine.entity.MetaStateTransition;
import org.springframework.stereotype.Service;

import java.util.Map;

/**
 * 取消流转执行器（actionName=cancel）。
 * <p>
 * postAction：设置 extras.put("isCancel", true)，由上层 OperationService 落库
 * is_cancel=1。对齐设计文档 02 §5.1.3（t14/t15: 3已审核 → 3已审核 自环流，
 * 通过 is_cancel 字段标识，require_reason=1）。
 */
@Service
public class CancelTransitionExecutor extends AbstractStateTransitionExecutor {

    public CancelTransitionExecutor() {
        this.actionName = "cancel";
    }

    @Override
    public String getActionName() {
        return actionName;
    }

    @Override
    public void postAction(MetaStateTransition transition, Long billId, ExprContext exprCtx, Map<String, Object> extras) {
        super.postAction(transition, billId, exprCtx, extras);
        if (extras != null) {
            extras.put("isCancel", true);
        }
    }
}
