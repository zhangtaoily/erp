package com.eerp.meta.statemachine.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.eerp.meta.statemachine.entity.MetaStateMachine;
import com.eerp.meta.statemachine.entity.MetaStateNode;
import com.eerp.meta.statemachine.entity.MetaStateTransition;

import java.util.List;

/**
 * 状态机 Service
 */
public interface MetaStateMachineService extends IService<MetaStateMachine> {

    /**
     * 按业务对象编码（状态机 code）查询状态机
     */
    MetaStateMachine getByBoCode(String boCode);

    /**
     * 查询状态机下所有节点
     */
    List<MetaStateNode> listNodes(Long machineId);

    /**
     * 查询状态机下所有流转
     */
    List<MetaStateTransition> listTransitions(Long machineId);
}
