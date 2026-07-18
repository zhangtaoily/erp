package com.eerp.test;

import com.eerp.bos.code.CodeGenerateService;
import com.eerp.bos.statemachine.TransitionExecutorFactory;
import com.eerp.bos.statemachine.AbstractStateTransitionExecutor;
import com.eerp.bos.statemachine.executors.CloseTransitionExecutor;
import com.eerp.bos.statemachine.executors.DefaultTransitionExecutor;
import com.eerp.bos.statemachine.executors.SaveTransitionExecutor;
import com.eerp.bos.statemachine.executors.SubmitTransitionExecutor;
import com.eerp.meta.cache.StateMachineCache;
import com.eerp.meta.rule.expr.ExprContext;
import com.eerp.meta.rule.expr.ExprEvaluator;
import com.eerp.meta.rule.expr.ExprException;
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
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.when;

/**
 * A2：状态机执行补全 + 流转执行器策略 单元测试。
 *
 * <p>覆盖：
 * <ul>
 *   <li>matchTransition：有效/无效 buttonCode</li>
 *   <li>validateTransition：fromState 匹配/不匹配</li>
 *   <li>executeTransition：preCheckExpr 通过/失败/异常、requireReason 校验</li>
 *   <li>SaveTransitionExecutor.postAction：mock CodeGenerateService 验证 extras 写入</li>
 *   <li>CloseTransitionExecutor.postAction：验证 isClosed=true</li>
 *   <li>TransitionExecutorFactory.getExecutor：按 actionName 匹配/未知返回 Default</li>
 *   <li>旧 execute() 方法向后兼容</li>
 * </ul>
 */
@ExtendWith(MockitoExtension.class)
class TransitionExecutorTest {

    @Mock
    private StateMachineCache stateMachineCache;

    @Mock
    private ExprEvaluator exprEvaluator;

    @InjectMocks
    private StateMachineEngineImpl stateMachineEngine;

    private static final String BO_CODE = "SAL_ORDER";

    @BeforeEach
    void setUp() {
        // 构造状态机元数据：save(0->1) / submit(1->2) / audit(2->3) / reject(2->4,需原因)
        MetaStateMachine machine = new MetaStateMachine();
        machine.setId(1L);
        machine.setCode("SM_SAL_ORDER");
        machine.setStateField("pact_state");

        List<MetaStateTransition> transitions = new ArrayList<>();
        transitions.add(buildTransition("save", "保存", 0, 1, 0, null, null));
        transitions.add(buildTransition("submit", "提交", 1, 2, 0, null, null));
        transitions.add(buildTransition("audit", "审核", 2, 3, 0, null, null));
        transitions.add(buildTransition("reject", "驳回", 2, 4, 1, null, null));

        StateMachineMetaVO meta = new StateMachineMetaVO();
        meta.setStateMachine(machine);
        meta.setTransitions(transitions);

        lenient().when(stateMachineCache.get(BO_CODE)).thenReturn(meta);
    }

    private MetaStateTransition buildTransition(String buttonCode, String actionName,
                                                int fromState, int toState, int requireReason,
                                                String preCheck, String postAction) {
        MetaStateTransition t = new MetaStateTransition();
        t.setButtonCode(buttonCode);
        t.setActionName(actionName);
        t.setFromState(fromState);
        t.setToState(toState);
        t.setRequireReason(requireReason);
        t.setPreCheck(preCheck);
        t.setPostAction(postAction);
        return t;
    }

    // ============ matchTransition ============

    @Test
    @DisplayName("matchTransition：有效 buttonCode 返回 transition")
    void testMatchTransitionValid() {
        MetaStateTransition t = stateMachineEngine.matchTransition(BO_CODE, "save");
        assertNotNull(t, "有效 buttonCode 应返回 transition");
        assertEquals("save", t.getButtonCode());
        assertEquals("保存", t.getActionName());
        assertEquals(0, t.getFromState());
        assertEquals(1, t.getToState());
    }

    @Test
    @DisplayName("matchTransition：无效 buttonCode 返回 null")
    void testMatchTransitionInvalid() {
        MetaStateTransition t = stateMachineEngine.matchTransition(BO_CODE, "unknown_button");
        assertNull(t, "无效 buttonCode 应返回 null");
    }

    @Test
    @DisplayName("matchTransition：未配置状态机返回 null")
    void testMatchTransitionNoMachine() {
        when(stateMachineCache.get("NO_SM")).thenReturn(null);
        assertNull(stateMachineEngine.matchTransition("NO_SM", "save"));
    }

    // ============ validateTransition ============

    @Test
    @DisplayName("validateTransition：fromState 匹配返回 true")
    void testValidateTransitionMatch() {
        MetaStateTransition t = buildTransition("save", "保存", 0, 1, 0, null, null);
        assertTrue(stateMachineEngine.validateTransition(0, t), "fromState=0 匹配应返回 true");
    }

    @Test
    @DisplayName("validateTransition：fromState 不匹配返回 false")
    void testValidateTransitionMismatch() {
        MetaStateTransition t = buildTransition("save", "保存", 0, 1, 0, null, null);
        assertFalse(stateMachineEngine.validateTransition(2, t), "fromState=2 不匹配应返回 false");
    }

    @Test
    @DisplayName("validateTransition：fromState 为 null 返回 false")
    void testValidateTransitionNullFromState() {
        MetaStateTransition t = buildTransition("save", "保存", 0, 1, 0, null, null);
        assertFalse(stateMachineEngine.validateTransition(null, t), "fromState=null 应返回 false");
    }

    // ============ executeTransition ============

    @Test
    @DisplayName("executeTransition：preCheckExpr 通过返回 ok")
    void testExecuteTransitionPreCheckPass() {
        MetaStateTransition t = buildTransition("audit", "审核", 2, 3, 0, "$qty > 0", null);
        ExprContext ctx = new ExprContext(new HashMap<>());
        when(exprEvaluator.evaluate(eq("$qty > 0"), any(ExprContext.class))).thenReturn(Boolean.TRUE);

        StateTransitionResult result = stateMachineEngine.executeTransition(t, 1001L, null, ctx);
        assertTrue(result.isSuccess(), "preCheck 通过应返回 ok");
        assertEquals(2, result.getFromState());
        assertEquals(3, result.getToState());
        assertEquals("审核", result.getActionName());
    }

    @Test
    @DisplayName("executeTransition：preCheckExpr 返回 false 返回 fail")
    void testExecuteTransitionPreCheckFail() {
        MetaStateTransition t = buildTransition("audit", "审核", 2, 3, 0, "$qty > 0", null);
        ExprContext ctx = new ExprContext(new HashMap<>());
        when(exprEvaluator.evaluate(eq("$qty > 0"), any(ExprContext.class))).thenReturn(Boolean.FALSE);

        StateTransitionResult result = stateMachineEngine.executeTransition(t, 1001L, null, ctx);
        assertFalse(result.isSuccess(), "preCheck 返回 false 应返回 fail");
        assertEquals(2, result.getFromState());
        assertTrue(result.getMessage().contains("前置校验未通过"));
    }

    @Test
    @DisplayName("executeTransition：preCheckExpr 抛 ExprException 返回 fail")
    void testExecuteTransitionPreCheckException() {
        MetaStateTransition t = buildTransition("audit", "审核", 2, 3, 0, "$qty > 0", null);
        ExprContext ctx = new ExprContext(new HashMap<>());
        when(exprEvaluator.evaluate(eq("$qty > 0"), any(ExprContext.class)))
                .thenThrow(new ExprException("RULE_VALIDATE_FAIL", "数量必须大于0"));

        StateTransitionResult result = stateMachineEngine.executeTransition(t, 1001L, null, ctx);
        assertFalse(result.isSuccess(), "preCheck 抛异常应返回 fail");
        assertTrue(result.getMessage().contains("前置校验异常"));
        assertTrue(result.getMessage().contains("数量必须大于0"));
    }

    @Test
    @DisplayName("executeTransition：requireReason=1 且无 reason 返回 fail")
    void testExecuteTransitionRequireReasonNoReason() {
        MetaStateTransition t = buildTransition("reject", "驳回", 2, 4, 1, null, null);

        StateTransitionResult result = stateMachineEngine.executeTransition(t, 1001L, null, null);
        assertFalse(result.isSuccess(), "无 reason 应返回 fail");
        assertTrue(result.getMessage().contains("原因"), "失败信息应提示需要原因");
    }

    @Test
    @DisplayName("executeTransition：requireReason=1 且有 reason 返回 ok")
    void testExecuteTransitionRequireReasonWithReason() {
        MetaStateTransition t = buildTransition("reject", "驳回", 2, 4, 1, null, null);

        StateTransitionResult result = stateMachineEngine.executeTransition(t, 1001L, "数据有误", null);
        assertTrue(result.isSuccess(), "有 reason 应返回 ok");
        assertEquals(2, result.getFromState());
        assertEquals(4, result.getToState());
    }

    @Test
    @DisplayName("executeTransition：postActionExpr 回填到结果")
    void testExecuteTransitionPostActionExprBackfilled() {
        MetaStateTransition t = buildTransition("save", "保存", 0, 1, 0, null, "GENERATE_CODE()");

        StateTransitionResult result = stateMachineEngine.executeTransition(t, 1001L, null, null);
        assertTrue(result.isSuccess());
        assertEquals("GENERATE_CODE()", result.getPostActionExpr(), "postActionExpr 应回填");
    }

    // ============ 旧 execute() 向后兼容 ============

    @Test
    @DisplayName("旧 execute() 向后兼容：save 流转成功")
    void testLegacyExecuteSave() {
        StateTransitionResult result = stateMachineEngine.execute(BO_CODE, 1001L, "save", null);
        assertTrue(result.isSuccess(), "save 应流转成功");
        assertEquals(0, result.getFromState());
        assertEquals(1, result.getToState());
        assertEquals("保存", result.getActionName());
    }

    @Test
    @DisplayName("旧 execute() 向后兼容：未知按钮返回失败")
    void testLegacyExecuteUnknownButton() {
        StateTransitionResult result = stateMachineEngine.execute(BO_CODE, 1001L, "unknown", null);
        assertFalse(result.isSuccess());
        assertTrue(result.getMessage().contains("unknown"));
    }

    @Test
    @DisplayName("旧 execute() 向后兼容：reject 无原因失败")
    void testLegacyExecuteRejectNoReason() {
        StateTransitionResult result = stateMachineEngine.execute(BO_CODE, 1001L, "reject", null);
        assertFalse(result.isSuccess());
        assertTrue(result.getMessage().contains("原因"));
    }

    // ============ SaveTransitionExecutor.postAction ============

    @Test
    @DisplayName("SaveTransitionExecutor.postAction：mock CodeGenerateService 返回编码，验证 extras 写入")
    void testSaveTransitionExecutorPostAction() {
        SaveTransitionExecutor executor = new SaveTransitionExecutor();
        // 通过反射注入 mock（@Autowired 字段）
        CodeGenerateService codeGenerateService = org.mockito.Mockito.mock(CodeGenerateService.class);
        org.springframework.test.util.ReflectionTestUtils.setField(executor, "codeGenerateService", codeGenerateService);
        when(codeGenerateService.generateCode(BO_CODE)).thenReturn("SO202607170001");

        MetaStateTransition transition = buildTransition("save", "保存", 0, 1, 0, null, null);
        Map<String, Object> extras = new HashMap<>();
        extras.put("boCode", BO_CODE);
        ExprContext ctx = new ExprContext(new HashMap<>());

        executor.postAction(transition, 1001L, ctx, extras);

        assertEquals("SO202607170001", extras.get("code"), "extras 应写入生成编码 code");
        assertEquals("SO202607170001", extras.get("billNo"), "extras 应写入 billNo");
        assertEquals("SO202607170001", ctx.getRootData().get("code"), "主表数据应写入 code");
        assertEquals("SO202607170001", ctx.getRootData().get("bill_no"), "主表数据应写入 bill_no");
    }

    // ============ CloseTransitionExecutor.postAction ============

    @Test
    @DisplayName("CloseTransitionExecutor.postAction：验证 isClosed=true")
    void testCloseTransitionExecutorPostAction() {
        CloseTransitionExecutor executor = new CloseTransitionExecutor();
        MetaStateTransition transition = buildTransition("close", "关闭", 3, 3, 0, null, null);
        Map<String, Object> extras = new HashMap<>();

        executor.postAction(transition, 1001L, null, extras);

        assertEquals(Boolean.TRUE, extras.get("isClosed"), "extras 应设置 isClosed=true");
    }

    // ============ SubmitTransitionExecutor.postAction ============

    @Test
    @DisplayName("SubmitTransitionExecutor.postAction：needWf=1 时标记 needWf=true")
    void testSubmitTransitionExecutorPostAction() {
        SubmitTransitionExecutor executor = new SubmitTransitionExecutor();
        MetaStateTransition transition = buildTransition("submit", "提交", 1, 2, 0, null, null);
        transition.setNeedWf(1);
        Map<String, Object> extras = new HashMap<>();

        executor.postAction(transition, 1001L, null, extras);

        assertEquals(Boolean.TRUE, extras.get("needWf"), "needWf=1 时应标记 needWf=true");
    }

    @Test
    @DisplayName("SubmitTransitionExecutor.postAction：needWf=0 时不标记 needWf")
    void testSubmitTransitionExecutorPostActionNoWf() {
        SubmitTransitionExecutor executor = new SubmitTransitionExecutor();
        MetaStateTransition transition = buildTransition("submit", "提交", 1, 2, 0, null, null);
        transition.setNeedWf(0);
        Map<String, Object> extras = new HashMap<>();

        executor.postAction(transition, 1001L, null, extras);

        assertFalse(extras.containsKey("needWf"), "needWf=0 时不应标记 needWf");
    }

    // ============ TransitionExecutorFactory.getExecutor ============

    @Test
    @DisplayName("TransitionExecutorFactory.getExecutor：按 actionName 返回对应执行器")
    void testFactoryGetExecutorByActionName() {
        SaveTransitionExecutor saveExecutor = new SaveTransitionExecutor();
        SubmitTransitionExecutor submitExecutor = new SubmitTransitionExecutor();
        CloseTransitionExecutor closeExecutor = new CloseTransitionExecutor();
        DefaultTransitionExecutor defaultExecutor = new DefaultTransitionExecutor();

        List<AbstractStateTransitionExecutor> executors = Arrays.asList(
                saveExecutor, submitExecutor, closeExecutor, defaultExecutor);
        TransitionExecutorFactory factory = new TransitionExecutorFactory(executors, defaultExecutor);

        assertEquals(saveExecutor, factory.getExecutor("save"), "save 应返回 SaveTransitionExecutor");
        assertEquals(submitExecutor, factory.getExecutor("submit"), "submit 应返回 SubmitTransitionExecutor");
        assertEquals(closeExecutor, factory.getExecutor("close"), "close 应返回 CloseTransitionExecutor");
        assertEquals(defaultExecutor, factory.getExecutor("default"), "default 应返回 DefaultTransitionExecutor");
    }

    @Test
    @DisplayName("TransitionExecutorFactory.getExecutor：未知 actionName 返回 Default")
    void testFactoryGetExecutorUnknownReturnsDefault() {
        DefaultTransitionExecutor defaultExecutor = new DefaultTransitionExecutor();
        SaveTransitionExecutor saveExecutor = new SaveTransitionExecutor();
        List<AbstractStateTransitionExecutor> executors = Arrays.asList(saveExecutor, defaultExecutor);
        TransitionExecutorFactory factory = new TransitionExecutorFactory(executors, defaultExecutor);

        AbstractStateTransitionExecutor result = factory.getExecutor("unknown_action");
        assertEquals(defaultExecutor, result, "未知 actionName 应返回 DefaultTransitionExecutor");
        assertEquals("default", result.getActionName());
    }

    @Test
    @DisplayName("TransitionExecutorFactory.getExecutor：null actionName 返回 Default")
    void testFactoryGetExecutorNullReturnsDefault() {
        DefaultTransitionExecutor defaultExecutor = new DefaultTransitionExecutor();
        List<AbstractStateTransitionExecutor> executors = Arrays.asList(defaultExecutor);
        TransitionExecutorFactory factory = new TransitionExecutorFactory(executors, defaultExecutor);

        assertEquals(defaultExecutor, factory.getExecutor(null), "null actionName 应返回 Default");
    }
}
