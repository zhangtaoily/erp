package com.eerp.meta.cache;

import com.eerp.common.cache.AbstractMetaCache;
import com.eerp.meta.statemachine.entity.MetaStateMachine;
import com.eerp.meta.statemachine.service.MetaStateMachineService;
import com.eerp.meta.statemachine.vo.StateMachineMetaVO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

/**
 * 状态机元数据缓存（按 boCode 聚合：状态机 + 节点 + 流转）
 */
@Component
public class StateMachineCache extends AbstractMetaCache<String, StateMachineMetaVO> {

    @Autowired
    private MetaStateMachineService stateMachineService;

    @Override
    protected StateMachineMetaVO load(String boCode) {
        MetaStateMachine machine = stateMachineService.getByBoCode(boCode);
        if (machine == null) {
            return null;
        }
        StateMachineMetaVO vo = new StateMachineMetaVO();
        vo.setStateMachine(machine);
        vo.setNodes(stateMachineService.listNodes(machine.getId()));
        vo.setTransitions(stateMachineService.listTransitions(machine.getId()));
        return vo;
    }
}
