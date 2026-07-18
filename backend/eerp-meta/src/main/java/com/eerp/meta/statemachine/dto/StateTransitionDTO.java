package com.eerp.meta.statemachine.dto;

import lombok.Data;

/**
 * 状态流转 DTO
 */
@Data
public class StateTransitionDTO {

    private Long id;

    /** 状态机ID */
    private Long machineId;

    /** 源状态 */
    private Integer fromState;

    /** 目标状态 */
    private Integer toState;

    /** 操作名称（如 保存/提交/审核/驳回/撤销/关闭/取消/变更/下推） */
    private String actionName;

    /** 触发按钮编码 */
    private String buttonCode;

    /** 前置校验表达式 */
    private String preCheck;

    /** 后置动作 */
    private String postAction;

    /** 是否触发外部工作流 */
    private Integer needWf;

    /** 工作流推送 API 地址 */
    private String wfPushApi;

    /** 工作流回调 URL */
    private String wfCallbackUrl;

    /** 回调展示字段说明 */
    private String wfCallbackDisplay;

    /** 是否要求填写原因 */
    private Integer requireReason;

    /** 排序 */
    private Integer sortIndex;
}
