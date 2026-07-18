package com.eerp.meta.statemachine;

import com.eerp.meta.rule.expr.ExprContext;
import com.eerp.meta.statemachine.dto.StateTransitionResult;
import com.eerp.meta.statemachine.entity.MetaStateTransition;

/**
 * 状态机引擎抽象基类
 * <p>
 * Phase 1：execute 只做流转校验与结果返回，实际状态变更由 eerp-bos 的 GenericBillService 负责。
 * Phase 2（A2）：补全 matchTransition / validateTransition / executeTransition，
 * 支持 pre_check 表达式执行；post_action 表达式的执行交由上层 OperationService
 * 通过 {@code com.eerp.bos.statemachine.TransitionExecutorFactory} 选择执行器完成。
 */
public abstract class AbstractStateMachineEngine {

    /**
     * 执行状态流转校验（Phase 1 兼容入口）
     *
     * @param boCode     业务对象编码
     * @param billId     单据ID（Phase 1 暂不查询数据库，保留参数）
     * @param buttonCode 触发按钮编码（save/submit/audit/revoke/reject/...）
     * @param reason     操作原因（驳回/重新提交/删除/变更需填）
     * @return 流转结果
     */
    public abstract StateTransitionResult execute(String boCode, Long billId, String buttonCode, String reason);

    /**
     * 按 buttonCode 查找匹配的流转。
     *
     * @param boCode     业务对象编码
     * @param buttonCode 触发按钮编码
     * @return 匹配的流转定义；未配置状态机/无流转/未命中均返回 null
     */
    public abstract MetaStateTransition matchTransition(String boCode, String buttonCode);

    /**
     * 校验 fromState 与 transition.from_state 一致。
     *
     * @param fromState  当前单据状态（运行期从数据库读取）
     * @param transition 流转定义
     * @return 一致返回 true，否则 false
     */
    public abstract boolean validateTransition(Integer fromState, MetaStateTransition transition);

    /**
     * 执行流转：pre_check 表达式校验 + reason 校验，通过后返回结果（含 toState + actionName）。
     * <p>
     * post_action 表达式的执行交给上层 OperationService（通过执行器策略完成），
     * 本方法仅将其文本回填到结果的 {@code postActionExpr} 字段供上层使用。
     *
     * @param transition 流转定义
     * @param billId     单据ID
     * @param reason     操作原因
     * @param exprCtx    表达式上下文（含主子表数据）；preCheck 为空时可传 null
     * @return 流转结果
     */
    public abstract StateTransitionResult executeTransition(MetaStateTransition transition, Long billId,
                                                            String reason, ExprContext exprCtx);
}
