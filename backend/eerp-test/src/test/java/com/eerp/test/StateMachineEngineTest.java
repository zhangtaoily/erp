package com.eerp.test;

import com.eerp.meta.cache.StateMachineCache;
import com.eerp.meta.statemachine.StateMachineEngineImpl;
import com.eerp.meta.statemachine.dto.StateTransitionResult;
import com.eerp.meta.statemachine.entity.MetaStateMachine;
import com.eerp.meta.statemachine.entity.MetaStateTransition;
import com.eerp.meta.statemachine.vo.StateMachineMetaVO;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.when;

/**
 * 状态机引擎单元测试
 */
@ExtendWith(MockitoExtension.class)
class StateMachineEngineTest {

    @Mock
    private StateMachineCache stateMachineCache;

    @InjectMocks
    private StateMachineEngineImpl stateMachineEngine;

    private static final String BO_CODE = "SAL_ORDER";

    @BeforeEach
    void setUp() {
        // 构造状态机元数据：0暂存 -> 1已创建 -> 2已提交 -> 3已审核 -> 4已驳回
        MetaStateMachine machine = new MetaStateMachine();
        machine.setId(1L);
        machine.setCode("SM_SAL_ORDER");
        machine.setStateField("pact_state");

        List<MetaStateTransition> transitions = new ArrayList<>();
        // save: 0 -> 1
        transitions.add(buildTransition("save", "保存", 0, 1, 0));
        // submit: 1 -> 2
        transitions.add(buildTransition("submit", "提交", 1, 2, 0));
        // audit: 2 -> 3
        transitions.add(buildTransition("audit", "审核", 2, 3, 0));
        // reject: 2 -> 4 (需原因)
        transitions.add(buildTransition("reject", "驳回", 2, 4, 1));

        StateMachineMetaVO meta = new StateMachineMetaVO();
        meta.setStateMachine(machine);
        meta.setTransitions(transitions);

        // 使用 lenient 模式：该 stub 在 testNoStateMachine/testNoTransitions 中未使用
        lenient().when(stateMachineCache.get(BO_CODE)).thenReturn(meta);
    }

    private MetaStateTransition buildTransition(String buttonCode, String actionName,
                                                 int fromState, int toState, int requireReason) {
        MetaStateTransition t = new MetaStateTransition();
        t.setButtonCode(buttonCode);
        t.setActionName(actionName);
        t.setFromState(fromState);
        t.setToState(toState);
        t.setRequireReason(requireReason);
        return t;
    }

    @Test
    @DisplayName("有效状态流转：save(0→1) → submit(1→2) → audit(2→3) 依次成功")
    void testValidTransition() {
        // save: 0 -> 1
        StateTransitionResult r1 = stateMachineEngine.execute(BO_CODE, 1001L, "save", null);
        assertTrue(r1.isSuccess(), "save应流转成功");
        assertEquals(0, r1.getFromState(), "save源状态应为0");
        assertEquals(1, r1.getToState(), "save目标状态应为1");
        assertEquals("保存", r1.getActionName());

        // submit: 1 -> 2
        StateTransitionResult r2 = stateMachineEngine.execute(BO_CODE, 1001L, "submit", null);
        assertTrue(r2.isSuccess(), "submit应流转成功");
        assertEquals(1, r2.getFromState());
        assertEquals(2, r2.getToState());

        // audit: 2 -> 3
        StateTransitionResult r3 = stateMachineEngine.execute(BO_CODE, 1001L, "audit", null);
        assertTrue(r3.isSuccess(), "audit应流转成功");
        assertEquals(2, r3.getFromState());
        assertEquals(3, r3.getToState());
    }

    @Test
    @DisplayName("非法按钮编码返回失败")
    void testInvalidTransition() {
        StateTransitionResult result = stateMachineEngine.execute(BO_CODE, 1001L, "unknown_button", null);
        assertFalse(result.isSuccess(), "未知按钮应返回失败");
        assertNotNull(result.getMessage(), "失败信息不应为空");
        assertTrue(result.getMessage().contains("unknown_button"), "失败信息应包含按钮编码");
    }

    @Test
    @DisplayName("需要原因的操作无原因时失败")
    void testRequireReason() {
        // reject 需要原因，不传reason应失败
        StateTransitionResult result = stateMachineEngine.execute(BO_CODE, 1001L, "reject", null);
        assertFalse(result.isSuccess(), "无原因的驳回应失败");
        assertTrue(result.getMessage().contains("原因"), "失败信息应提示需要原因");
    }

    @Test
    @DisplayName("需要原因的操作填写原因后成功")
    void testRequireReasonWithReason() {
        StateTransitionResult result = stateMachineEngine.execute(BO_CODE, 1001L, "reject", "数据有误");
        assertTrue(result.isSuccess(), "填写原因的驳回应成功");
        assertEquals(2, result.getFromState());
        assertEquals(4, result.getToState());
    }

    @Test
    @DisplayName("业务对象未配置状态机时返回失败")
    void testNoStateMachine() {
        when(stateMachineCache.get("NO_SM")).thenReturn(null);
        StateTransitionResult result = stateMachineEngine.execute("NO_SM", 1L, "submit", null);
        assertFalse(result.isSuccess(), "未配置状态机应返回失败");
        assertTrue(result.getMessage().contains("未配置状态机"));
    }

    @Test
    @DisplayName("状态机无流转配置时返回失败")
    void testNoTransitions() {
        StateMachineMetaVO emptyMeta = new StateMachineMetaVO();
        emptyMeta.setStateMachine(new MetaStateMachine());
        emptyMeta.setTransitions(Collections.emptyList());
        when(stateMachineCache.get("EMPTY_SM")).thenReturn(emptyMeta);

        StateTransitionResult result = stateMachineEngine.execute("EMPTY_SM", 1L, "submit", null);
        assertFalse(result.isSuccess(), "无流转配置应返回失败");
        assertTrue(result.getMessage().contains("未配置状态流转"));
    }
}
