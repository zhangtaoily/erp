package com.eerp.meta.statemachine.vo;

import com.eerp.meta.statemachine.entity.MetaStateMachine;
import com.eerp.meta.statemachine.entity.MetaStateNode;
import com.eerp.meta.statemachine.entity.MetaStateTransition;
import lombok.Data;

import java.util.List;

/**
 * 状态机元数据聚合 VO（状态机定义 + 节点列表 + 流转列表）
 */
@Data
public class StateMachineMetaVO {

    /** 状态机定义 */
    private MetaStateMachine stateMachine;

    /** 状态节点列表 */
    private List<MetaStateNode> nodes;

    /** 状态流转列表 */
    private List<MetaStateTransition> transitions;
}
