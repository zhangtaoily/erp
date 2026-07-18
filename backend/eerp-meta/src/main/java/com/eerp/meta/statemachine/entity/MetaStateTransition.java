package com.eerp.meta.statemachine.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import com.eerp.common.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * 状态流转定义（含驳回/关闭/取消/变更/下推流转）
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("meta_state_transition")
public class MetaStateTransition extends BaseEntity {

    /** 状态机ID */
    private Long machineId;

    /** 源状态（0暂存1已创建2已提交3已审核4已驳回） */
    private Integer fromState;

    /** 目标状态 */
    private Integer toState;

    /** 操作名称（如 保存/提交/审核/驳回/撤销/关闭/取消/变更/下推） */
    private String actionName;

    /** 触发按钮编码（save/submit/audit/revoke/reject/resubmit/delete/close/cancel/change/push） */
    private String buttonCode;

    /** 前置校验表达式（如校验下游单据是否存在、可下推量） */
    private String preCheck;

    /** 后置动作（如立账/生成凭证/更新库存/is_closed=1） */
    private String postAction;

    /** 是否触发外部工作流（提交/变更需推送审批流） */
    private Integer needWf;

    /** 工作流推送 API 地址（need_wf=1 时配置） */
    private String wfPushApi;

    /** 工作流回调 URL（外部系统回调 ERP 的接口路径） */
    private String wfCallbackUrl;

    /** 回调展示字段说明 */
    private String wfCallbackDisplay;

    /** 是否要求填写原因（驳回/重新提交/删除/变更需填原因） */
    private Integer requireReason;

    /** 排序 */
    private Integer sortIndex;

    /** 该表无审计字段，排除映射 */
    @TableField(exist = false)
    private String createBy;

    @TableField(exist = false)
    private LocalDateTime createTime;

    @TableField(exist = false)
    private String updateBy;

    @TableField(exist = false)
    private LocalDateTime updateTime;
}
