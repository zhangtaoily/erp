package com.eerp.bos.statemachine.executors;

import com.eerp.bos.statemachine.AbstractStateTransitionExecutor;
import com.eerp.meta.rule.expr.ExprContext;
import com.eerp.meta.statemachine.entity.MetaStateTransition;
import org.springframework.stereotype.Service;

import java.util.Map;

/**
 * 审核流转执行器（actionName=audit）。
 * <p>
 * postAction：标记需要执行反写规则（extras.put("needWriteback", true)）
 * 与业财凭证生成（extras.put("needVoucher", true)），由上层 OperationService
 * 在事务内阶段调用 08 反写引擎与凭证服务。
 * 对齐设计文档 02 §6.2（t4: 2已提交 → 3已审核，post_action=立账/凭证/库存/反写）。
 */
@Service
public class AuditTransitionExecutor extends AbstractStateTransitionExecutor {

    public AuditTransitionExecutor() {
        this.actionName = "audit";
    }

    @Override
    public String getActionName() {
        return actionName;
    }

    @Override
    public void postAction(MetaStateTransition transition, Long billId, ExprContext exprCtx, Map<String, Object> extras) {
        super.postAction(transition, billId, exprCtx, extras);
        if (extras != null) {
            extras.put("needWriteback", true);
            extras.put("needVoucher", true);
        }
    }
}
