package com.eerp.bos.statemachine.executors;

import com.eerp.bos.statemachine.AbstractStateTransitionExecutor;
import com.eerp.meta.rule.expr.ExprContext;
import com.eerp.meta.statemachine.entity.MetaStateTransition;
import org.springframework.stereotype.Service;

import java.util.Map;

/**
 * 关闭流转执行器（actionName=close）。
 * <p>
 * postAction：设置 extras.put("isClosed", true)，由上层 OperationService 落库
 * is_closed=1。对齐设计文档 02 §5.1.3（t12/t13: 3已审核 → 3已审核 自环流，
 * 通过 is_closed 字段标识，不占状态码）。
 */
@Service
public class CloseTransitionExecutor extends AbstractStateTransitionExecutor {

    public CloseTransitionExecutor() {
        this.actionName = "close";
    }

    @Override
    public String getActionName() {
        return actionName;
    }

    @Override
    public void postAction(MetaStateTransition transition, Long billId, ExprContext exprCtx, Map<String, Object> extras) {
        super.postAction(transition, billId, exprCtx, extras);
        if (extras != null) {
            extras.put("isClosed", true);
        }
    }
}
