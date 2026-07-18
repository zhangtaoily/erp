package com.eerp.meta.statemachine.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.eerp.common.service.AbstractCrudService;
import com.eerp.meta.statemachine.entity.MetaStateMachine;
import com.eerp.meta.statemachine.entity.MetaStateNode;
import com.eerp.meta.statemachine.entity.MetaStateTransition;
import com.eerp.meta.statemachine.mapper.MetaStateMachineMapper;
import com.eerp.meta.statemachine.mapper.MetaStateNodeMapper;
import com.eerp.meta.statemachine.mapper.MetaStateTransitionMapper;
import com.eerp.meta.statemachine.service.MetaStateMachineService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * 状态机 Service 实现
 */
@Service
public class MetaStateMachineServiceImpl
        extends AbstractCrudService<MetaStateMachineMapper, MetaStateMachine>
        implements MetaStateMachineService {

    @Autowired
    private MetaStateNodeMapper stateNodeMapper;

    @Autowired
    private MetaStateTransitionMapper stateTransitionMapper;

    @Override
    public MetaStateMachine getByBoCode(String boCode) {
        // meta_state_machine 表通过 code 字段标识（业务上 code 即 bo_code）
        return lambdaQuery().eq(MetaStateMachine::getCode, boCode).last("LIMIT 1").one();
    }

    @Override
    public List<MetaStateNode> listNodes(Long machineId) {
        return stateNodeMapper.selectList(
                new LambdaQueryWrapper<MetaStateNode>()
                        .eq(MetaStateNode::getMachineId, machineId)
                        .orderByAsc(MetaStateNode::getSortIndex)
        );
    }

    @Override
    public List<MetaStateTransition> listTransitions(Long machineId) {
        return stateTransitionMapper.selectList(
                new LambdaQueryWrapper<MetaStateTransition>()
                        .eq(MetaStateTransition::getMachineId, machineId)
                        .orderByAsc(MetaStateTransition::getSortIndex)
        );
    }
}
