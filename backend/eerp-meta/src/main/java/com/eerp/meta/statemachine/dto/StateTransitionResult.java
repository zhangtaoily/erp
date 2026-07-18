package com.eerp.meta.statemachine.dto;

import lombok.Data;

/**
 * 状态流转结果（状态机引擎返回）
 */
@Data
public class StateTransitionResult {

    /** 是否流转成功 */
    private boolean success;

    /** 提示信息 */
    private String message;

    /** 源状态 */
    private Integer fromState;

    /** 目标状态 */
    private Integer toState;

    /** 触发操作名称（如 保存/提交/审核/驳回） */
    private String actionName;

    /** 后置动作表达式（供上层 OperationService 选择执行器执行 post_action） */
    private String postActionExpr;

    public static StateTransitionResult ok(Integer fromState, Integer toState, String message) {
        StateTransitionResult result = new StateTransitionResult();
        result.setSuccess(true);
        result.setFromState(fromState);
        result.setToState(toState);
        result.setMessage(message);
        return result;
    }

    public static StateTransitionResult ok(Integer fromState, Integer toState, String actionName, String message) {
        StateTransitionResult result = new StateTransitionResult();
        result.setSuccess(true);
        result.setFromState(fromState);
        result.setToState(toState);
        result.setActionName(actionName);
        result.setMessage(message);
        return result;
    }

    public static StateTransitionResult fail(Integer fromState, String message) {
        StateTransitionResult result = new StateTransitionResult();
        result.setSuccess(false);
        result.setFromState(fromState);
        result.setToState(fromState);
        result.setMessage(message);
        return result;
    }
}
