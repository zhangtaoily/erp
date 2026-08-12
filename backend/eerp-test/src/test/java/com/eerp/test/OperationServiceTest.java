package com.eerp.test;

import com.eerp.bos.bill.BillDataAccessor;
import com.eerp.bos.operation.service.GenericOperationService;
import com.eerp.bos.operation.service.OperationContext;
import com.eerp.bos.operation.service.OperationResult;
import com.eerp.bos.operation.service.WfPushPort;
import com.eerp.bos.rule.RuleEngineImpl;
import com.eerp.bos.rule.RuleViolation;
import com.eerp.bos.rule.WritebackResult;
import com.eerp.bos.rule.WritebackServiceImpl;
import com.eerp.bos.statemachine.AbstractStateTransitionExecutor;
import com.eerp.bos.statemachine.TransitionExecutorFactory;
import com.eerp.common.id.SnowflakeIdGenerator;
import com.eerp.meta.bo.entity.MetaBusinessObject;
import com.eerp.meta.bo.vo.FormMetaVO;
import com.eerp.meta.cache.FormMetaCache;
import com.eerp.meta.cache.StateMachineCache;
import com.eerp.meta.rule.expr.ExprContext;
import com.eerp.meta.statemachine.StateMachineEngineImpl;
import com.eerp.meta.statemachine.dto.StateTransitionResult;
import com.eerp.meta.statemachine.entity.MetaStateMachine;
import com.eerp.meta.statemachine.entity.MetaStateTransition;
import com.eerp.meta.statemachine.vo.StateMachineMetaVO;
import com.eerp.plugin.context.PluginContext;
import com.eerp.plugin.core.PluginContextFactory;
import com.eerp.plugin.core.PluginExecutorResult;
import com.eerp.plugin.core.PluginManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.mockito.ArgumentCaptor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.TransactionStatus;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.mockito.ArgumentCaptor.forClass;

/**
 * 操作编排服务单元测试（6 阶段流水线全链路，对齐 A5）。
 *
 * <p>使用 @MockitoSettings(strictness = LENIENT) 避免未使用 stub 报错
 * （不同测试用例使用不同的 stub 组合）。</p>
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class OperationServiceTest {

    @Mock
    private PluginManager pluginManager;
    @Mock
    private PluginContextFactory pluginContextFactory;
    @Mock
    private RuleEngineImpl ruleEngine;
    @Mock
    private WritebackServiceImpl writebackService;
    @Mock
    private StateMachineEngineImpl stateMachineEngine;
    @Mock
    private TransitionExecutorFactory transitionExecutorFactory;
    @Mock
    private WfPushPort wfPushPort;
    @Mock
    private PlatformTransactionManager transactionManager;
    @Mock
    private TransactionStatus transactionStatus;
    @Mock
    private BillDataAccessor billDataAccessor;
    @Mock
    private JdbcTemplate jdbcTemplate;
    @Mock
    private FormMetaCache formMetaCache;
    @Mock
    private StateMachineCache stateMachineCache;
    @Mock
    private SnowflakeIdGenerator snowflakeIdGenerator;
    @Mock
    private AbstractStateTransitionExecutor transitionExecutor;

    @InjectMocks
    private GenericOperationService operationService;

    private static final String BO_CODE = "SAL_ORDER";
    private static final Long BILL_ID = 1001L;

    @BeforeEach
    void setUp() {
        // 公共元数据 mock
        lenient().when(formMetaCache.get(BO_CODE)).thenReturn(buildFormMeta());
        lenient().when(stateMachineCache.get(BO_CODE)).thenReturn(buildStateMachineMeta());

        // 公共：jdbcTemplate 统一返回 1（UPDATE/INSERT）
        lenient().when(jdbcTemplate.update(anyString(), any(Object[].class))).thenReturn(1);
        lenient().when(snowflakeIdGenerator.nextId()).thenReturn(8001L);

        // 公共：事务管理器 mock（让 TransactionTemplate 正常执行回调）
        lenient().when(transactionManager.getTransaction(any())).thenReturn(transactionStatus);

        // 公共：插件上下文工厂返回真实 PluginContext
        lenient().when(pluginContextFactory.create(any(), any(), any(), any(), any()))
                .thenAnswer(inv -> {
                    PluginContext ctx = new PluginContext();
                    ctx.setBoCode(inv.getArgument(0));
                    ctx.setBillId(inv.getArgument(1));
                    ctx.setOperation(inv.getArgument(2));
                    ctx.setBillData(inv.getArgument(3));
                    ctx.setVariables(new HashMap<>());
                    ctx.setExtras(new HashMap<>());
                    ctx.setValidationErrors(new ArrayList<>());
                    return ctx;
                });

        // 公共：插件默认返回成功
        lenient().when(pluginManager.fire(anyString(), anyString(), any(PluginContext.class)))
                .thenReturn(successPluginResult());

        // 公共：规则引擎默认无违规
        lenient().when(ruleEngine.executeRules(anyString(), anyString(), any(ExprContext.class)))
                .thenReturn(new ArrayList<>());

        // 公共：反写默认成功
        lenient().when(writebackService.executeWriteback(anyString(), any(), anyString(), any(ExprContext.class)))
                .thenReturn(buildWritebackSuccess());

        // 公共：流转执行器工厂
        lenient().when(transitionExecutorFactory.getExecutor(anyString())).thenReturn(transitionExecutor);
    }

    // ==================== 保存操作测试 ====================

    @Test
    @DisplayName("保存新单据：6 阶段流水线全通过，返回单据ID")
    void testSaveSuccess() {
        Map<String, Object> billData = new HashMap<>();
        billData.put("main", new HashMap<String, Object>());

        OperationContext ctx = OperationContext.builder()
                .boCode(BO_CODE)
                .operation("save")
                .billData(billData)
                .userName("admin")
                .build();

        when(billDataAccessor.saveBill(eq(BO_CODE), any())).thenReturn(BILL_ID);
        when(jdbcTemplate.queryForMap(anyString(), eq(BILL_ID))).thenReturn(billRow(1, "SO20240001"));

        OperationResult result = operationService.executeOperation(ctx);

        assertTrue(result.isSuccess(), "保存应成功");
        assertEquals(BILL_ID, result.getBillId());
        verify(billDataAccessor).saveBill(eq(BO_CODE), any());
        // 验证 6 阶段全部触发
        verify(pluginManager).fire(eq(BO_CODE), eq("onPreparePropertys"), any());
        verify(pluginManager).fire(eq(BO_CODE), eq("onAddValidators"), any());
        verify(pluginManager).fire(eq(BO_CODE), eq("beforeExecuteOperationTransaction"), any());
        verify(pluginManager).fire(eq(BO_CODE), eq("beginOperationTransaction"), any());
        verify(pluginManager).fire(eq(BO_CODE), eq("endOperationTransaction"), any());
        verify(pluginManager).fire(eq(BO_CODE), eq("afterExecuteOperationTransaction"), any());
    }

    @Test
    @DisplayName("保存：阶段3插件阻断 → 操作失败，不执行落库")
    void testSavePluginBlockStage3() {
        Map<String, Object> billData = new HashMap<>();
        billData.put("main", new HashMap<>());

        OperationContext ctx = OperationContext.builder()
                .boCode(BO_CODE)
                .operation("save")
                .billData(billData)
                .build();

        // 阶段3阻断
        when(pluginManager.fire(eq(BO_CODE), eq("beforeExecuteOperationTransaction"), any()))
                .thenReturn(blockPluginResult("前置校验失败"));

        OperationResult result = operationService.executeOperation(ctx);

        assertFalse(result.isSuccess(), "阶段3阻断应返回失败");
        assertTrue(result.getMessage().contains("前置校验失败"));
    }

    @Test
    @DisplayName("保存：阶段2校验器收集错误 → 操作失败")
    void testSaveValidationErrors() {
        Map<String, Object> billData = new HashMap<>();
        billData.put("main", new HashMap<>());

        OperationContext ctx = OperationContext.builder()
                .boCode(BO_CODE)
                .operation("save")
                .billData(billData)
                .build();

        // 阶段2返回成功但携带校验错误
        when(pluginManager.fire(eq(BO_CODE), eq("onAddValidators"), any()))
                .thenAnswer(inv -> {
                    PluginContext pc = inv.getArgument(2);
                    pc.addValidationError("数量必须大于0");
                    return successPluginResult();
                });

        OperationResult result = operationService.executeOperation(ctx);

        assertFalse(result.isSuccess(), "校验错误应返回失败");
        assertTrue(result.getMessage().contains("数量必须大于0"));
    }

    @Test
    @DisplayName("保存：单据数据为空 → 操作失败")
    void testSaveNullBillData() {
        OperationContext ctx = OperationContext.builder()
                .boCode(BO_CODE)
                .operation("save")
                .billData(null)
                .build();

        OperationResult result = operationService.executeOperation(ctx);

        assertFalse(result.isSuccess());
        assertTrue(result.getMessage().contains("空"));
    }

    // ==================== 状态流转操作测试 ====================

    @Test
    @DisplayName("提交操作：状态机校验通过 → 状态变更 → 操作日志记录")
    void testSubmitSuccess() {
        OperationContext ctx = OperationContext.builder()
                .boCode(BO_CODE)
                .billId(BILL_ID)
                .operation("submit")
                .userName("admin")
                .build();

        MetaStateTransition transition = buildTransition("submit", "提交", 1, 2, 0);
        when(stateMachineEngine.execute(BO_CODE, BILL_ID, "submit", null))
                .thenReturn(StateTransitionResult.ok(1, 2, "提交", "操作[提交]校验通过"));
        when(stateMachineEngine.matchTransition(BO_CODE, "submit")).thenReturn(transition);
        when(billDataAccessor.loadBill(BO_CODE, BILL_ID)).thenReturn(billDataMap(1, "SO001"));
        when(jdbcTemplate.queryForMap(anyString(), eq(BILL_ID))).thenReturn(billRow(1, "SO001"));

        OperationResult result = operationService.executeOperation(ctx);

        assertTrue(result.isSuccess(), "提交应成功");
        verify(stateMachineEngine).execute(BO_CODE, BILL_ID, "submit", null);
        // 验证状态变更 UPDATE + 操作日志 INSERT 共调用 2 次
        ArgumentCaptor<String> sqlCaptor = ArgumentCaptor.forClass(String.class);
        verify(jdbcTemplate, times(2)).update(sqlCaptor.capture(), any(Object[].class));
        assertTrue(sqlCaptor.getAllValues().get(0).contains("UPDATE"),
                "首次 UPDATE 应为状态变更");
    }

    @Test
    @DisplayName("提交操作：状态机校验失败 → 操作被拒绝")
    void testSubmitStateMachineFails() {
        OperationContext ctx = OperationContext.builder()
                .boCode(BO_CODE)
                .billId(BILL_ID)
                .operation("audit")
                .build();

        when(stateMachineEngine.execute(BO_CODE, BILL_ID, "audit", null))
                .thenReturn(StateTransitionResult.fail(0, "当前状态不允许审核"));
        when(billDataAccessor.loadBill(BO_CODE, BILL_ID)).thenReturn(billDataMap(0, "SO001"));

        OperationResult result = operationService.executeOperation(ctx);

        assertFalse(result.isSuccess(), "状态机校验失败应返回失败");
        assertTrue(result.getMessage().contains("不允许审核"));
    }

    @Test
    @DisplayName("审核操作：needWriteback=true → 反写服务被调用")
    void testAuditWithWriteback() {
        OperationContext ctx = OperationContext.builder()
                .boCode(BO_CODE)
                .billId(BILL_ID)
                .operation("audit")
                .userName("admin")
                .build();

        MetaStateTransition transition = buildTransition("audit", "审核", 2, 3, 0);
        when(stateMachineEngine.execute(BO_CODE, BILL_ID, "audit", null))
                .thenReturn(StateTransitionResult.ok(2, 3, "审核", "操作[审核]校验通过"));
        when(stateMachineEngine.matchTransition(BO_CODE, "audit")).thenReturn(transition);
        when(billDataAccessor.loadBill(BO_CODE, BILL_ID)).thenReturn(billDataMap(2, "SO001"));
        when(jdbcTemplate.queryForMap(anyString(), eq(BILL_ID))).thenReturn(billRow(2, "SO001"));

        // 流转执行器 postAction 设置 needWriteback
        lenient().doAnswer(inv -> {
            Map<String, Object> extras = inv.getArgument(3);
            extras.put("needWriteback", true);
            return null;
        }).when(transitionExecutor).postAction(any(), any(), any(), any());

        OperationResult result = operationService.executeOperation(ctx);

        assertTrue(result.isSuccess(), "审核应成功");
        verify(writebackService).executeWriteback(eq(BO_CODE), eq(BILL_ID), eq("audit"), any(ExprContext.class));
    }

    @Test
    @DisplayName("审核操作：实体规则 block=true → 操作失败（事务回滚）")
    void testRuleViolationBlocks() {
        OperationContext ctx = OperationContext.builder()
                .boCode(BO_CODE)
                .billId(BILL_ID)
                .operation("audit")
                .build();

        when(stateMachineEngine.execute(BO_CODE, BILL_ID, "audit", null))
                .thenReturn(StateTransitionResult.ok(2, 3, "审核", "通过"));
        when(stateMachineEngine.matchTransition(BO_CODE, "audit"))
                .thenReturn(buildTransition("audit", "审核", 2, 3, 0));
        when(billDataAccessor.loadBill(BO_CODE, BILL_ID)).thenReturn(billDataMap(2, "SO001"));

        // 规则引擎返回 block 违规
        List<RuleViolation> violations = new ArrayList<>();
        violations.add(new RuleViolation("R001", "金额超限", "ERROR", true));
        when(ruleEngine.executeRules(eq(BO_CODE), eq("OnBeforeAudit"), any(ExprContext.class)))
                .thenReturn(violations);

        OperationResult result = operationService.executeOperation(ctx);

        assertFalse(result.isSuccess(), "规则阻断应返回失败");
        assertTrue(result.getMessage().contains("金额超限"));
    }

    @Test
    @DisplayName("审核操作：阶段4插件阻断 → 操作失败（事务回滚）")
    void testPluginBlockInTransaction() {
        OperationContext ctx = OperationContext.builder()
                .boCode(BO_CODE)
                .billId(BILL_ID)
                .operation("audit")
                .build();

        when(stateMachineEngine.execute(BO_CODE, BILL_ID, "audit", null))
                .thenReturn(StateTransitionResult.ok(2, 3, "审核", "通过"));
        when(stateMachineEngine.matchTransition(BO_CODE, "audit"))
                .thenReturn(buildTransition("audit", "审核", 2, 3, 0));
        when(billDataAccessor.loadBill(BO_CODE, BILL_ID)).thenReturn(billDataMap(2, "SO001"));

        // 阶段4阻断
        when(pluginManager.fire(eq(BO_CODE), eq("beginOperationTransaction"), any()))
                .thenReturn(blockPluginResult("事务内前置校验失败"));

        OperationResult result = operationService.executeOperation(ctx);

        assertFalse(result.isSuccess(), "阶段4阻断应返回失败");
        assertTrue(result.getMessage().contains("事务内前置校验失败"));
    }

    @Test
    @DisplayName("提交操作：needWf=true → 工作流推送被调用（事务后）")
    void testWfPushAfterSubmit() {
        OperationContext ctx = OperationContext.builder()
                .boCode(BO_CODE)
                .billId(BILL_ID)
                .operation("submit")
                .userId(9001L)
                .build();

        MetaStateTransition transition = buildTransition("submit", "提交", 1, 2, 0);
        transition.setNeedWf(1);
        transition.setWfPushApi("http://wf.example.com/push");

        when(stateMachineEngine.execute(BO_CODE, BILL_ID, "submit", null))
                .thenReturn(StateTransitionResult.ok(1, 2, "提交", "通过"));
        when(stateMachineEngine.matchTransition(BO_CODE, "submit")).thenReturn(transition);
        when(billDataAccessor.loadBill(BO_CODE, BILL_ID)).thenReturn(billDataMap(1, "SO001"));
        when(jdbcTemplate.queryForMap(anyString(), eq(BILL_ID))).thenReturn(billRow(1, "SO001"));

        // 流转执行器设置 needWf
        lenient().doAnswer(inv -> {
            Map<String, Object> extras = inv.getArgument(3);
            extras.put("needWf", true);
            return null;
        }).when(transitionExecutor).postAction(any(), any(), any(), any());

        when(wfPushPort.pushWf(eq(BO_CODE), eq(BILL_ID), eq("http://wf.example.com/push"), any(), eq(9001L)))
                .thenReturn("wf-req-001");

        OperationResult result = operationService.executeOperation(ctx);

        assertTrue(result.isSuccess(), "提交应成功");
        verify(wfPushPort).pushWf(eq(BO_CODE), eq(BILL_ID), eq("http://wf.example.com/push"), any(), eq(9001L));
    }

    // ==================== 删除操作测试 ====================

    @Test
    @DisplayName("删除操作：6 阶段流水线全通过 → 删除成功")
    void testDeleteSuccess() {
        OperationContext ctx = OperationContext.builder()
                .boCode(BO_CODE)
                .billId(BILL_ID)
                .operation("delete")
                .reason("作废删除")
                .userName("admin")
                .build();

        when(billDataAccessor.loadBill(BO_CODE, BILL_ID)).thenReturn(billDataMap(3, "SO001"));
        when(jdbcTemplate.queryForMap(anyString(), eq(BILL_ID))).thenReturn(billRow(3, "SO001"));

        OperationResult result = operationService.executeOperation(ctx);

        assertTrue(result.isSuccess(), "删除应成功");
        verify(billDataAccessor).deleteBill(BO_CODE, BILL_ID);
        // 删除无状态机校验
        verify(stateMachineEngine, org.mockito.Mockito.never())
                .execute(anyString(), any(), anyString(), any());
    }

    @Test
    @DisplayName("操作：单据ID为空 → 操作失败")
    void testOperateNullBillId() {
        OperationContext ctx = OperationContext.builder()
                .boCode(BO_CODE)
                .billId(null)
                .operation("submit")
                .build();

        OperationResult result = operationService.executeOperation(ctx);

        assertFalse(result.isSuccess(), "单据ID为空应返回失败");
        assertTrue(result.getMessage().contains("ID为空"));
    }

    @Test
    @DisplayName("关闭操作：is_closed=1 被设置")
    void testCloseOperation() {
        OperationContext ctx = OperationContext.builder()
                .boCode(BO_CODE)
                .billId(BILL_ID)
                .operation("close")
                .userName("admin")
                .build();

        when(stateMachineEngine.execute(BO_CODE, BILL_ID, "close", null))
                .thenReturn(StateTransitionResult.ok(3, 3, "关闭", "通过"));
        when(stateMachineEngine.matchTransition(BO_CODE, "close"))
                .thenReturn(buildTransition("close", "关闭", 3, 3, 0));
        when(billDataAccessor.loadBill(BO_CODE, BILL_ID)).thenReturn(billDataMap(3, "SO001"));
        when(jdbcTemplate.queryForMap(anyString(), eq(BILL_ID))).thenReturn(billRow(3, "SO001"));

        OperationResult result = operationService.executeOperation(ctx);

        assertTrue(result.isSuccess(), "关闭应成功");
        // 验证状态变更 UPDATE（含 is_closed=1）+ 操作日志 INSERT 共 2 次
        ArgumentCaptor<String> sqlCaptor = ArgumentCaptor.forClass(String.class);
        verify(jdbcTemplate, times(2)).update(sqlCaptor.capture(), any(Object[].class));
        assertTrue(sqlCaptor.getAllValues().get(0).contains("is_closed"),
                "状态变更 UPDATE 应包含 is_closed 字段");
    }

    // ==================== 辅助方法 ====================

    private FormMetaVO buildFormMeta() {
        MetaBusinessObject bo = new MetaBusinessObject();
        bo.setBoCode(BO_CODE);
        bo.setMainTable("sal_order");
        FormMetaVO vo = new FormMetaVO();
        vo.setBusinessObject(bo);
        return vo;
    }

    private StateMachineMetaVO buildStateMachineMeta() {
        MetaStateMachine machine = new MetaStateMachine();
        machine.setStateField("pact_state");
        StateMachineMetaVO vo = new StateMachineMetaVO();
        vo.setStateMachine(machine);
        return vo;
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

    private PluginExecutorResult successPluginResult() {
        PluginExecutorResult r = new PluginExecutorResult();
        r.setSuccess(true);
        r.setBlock(false);
        r.setResults(new ArrayList<>());
        return r;
    }

    private PluginExecutorResult blockPluginResult(String message) {
        PluginExecutorResult r = new PluginExecutorResult();
        r.setSuccess(false);
        r.setBlock(true);
        r.setMessage(message);
        r.setResults(new ArrayList<>());
        return r;
    }

    private WritebackResult buildWritebackSuccess() {
        WritebackResult r = new WritebackResult();
        r.setSuccess(true);
        r.setTotalRules(0);
        r.setSuccessRules(0);
        return r;
    }

    /** 返回同时含 s（状态）和 c（单据编号）的 map */
    private Map<String, Object> billRow(int state, String code) {
        Map<String, Object> row = new HashMap<>();
        row.put("s", state);
        row.put("c", code);
        return row;
    }

    /** 构建单据数据 {main: {...}, subs: {}} */
    private Map<String, Object> billDataMap(int state, String code) {
        Map<String, Object> data = new HashMap<>();
        Map<String, Object> main = new HashMap<>();
        main.put("id", BILL_ID);
        main.put("code", code);
        main.put("pact_state", state);
        data.put("main", main);
        data.put("subs", new HashMap<>());
        return data;
    }
}
