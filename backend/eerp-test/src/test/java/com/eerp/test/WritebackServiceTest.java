package com.eerp.test;

import com.eerp.bos.rule.WritebackCompensationService;
import com.eerp.bos.rule.WritebackResult;
import com.eerp.bos.rule.WritebackServiceImpl;
import com.eerp.common.exception.ServiceException;
import com.eerp.meta.rule.expr.ExprContext;
import com.eerp.meta.rule.expr.ExprEvaluator;
import com.eerp.meta.writeback.entity.MetaWritebackField;
import com.eerp.meta.writeback.entity.MetaWritebackRule;
import com.eerp.meta.writeback.mapper.MetaWritebackFieldMapper;
import com.eerp.meta.writeback.service.MetaWritebackRuleService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.Collections;
import java.util.HashMap;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doReturn;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * 反写服务单元测试（A4: 规则与反写引擎 —— 反写服务部分）。
 *
 * <p>覆盖任务要求的全部场景：</p>
 * <ul>
 *   <li>ADD/SUBTRACT/COVER 三种反写模式</li>
 *   <li>超限 BLOCK/WARN/ALLOW 三种策略</li>
 *   <li>SYNC/ASYNC 两种执行模式</li>
 * </ul>
 *
 * <p>测试策略：MetaWritebackRuleService/MetaWritebackFieldMapper/JdbcTemplate/
 * WritebackCompensationService 使用 Mockito 桩；ExprEvaluator 使用真实实现
 * （A1 已通过 ExprEvaluatorTest 验证）。</p>
 */
@ExtendWith(MockitoExtension.class)
class WritebackServiceTest {

    @Mock
    private MetaWritebackRuleService metaWritebackRuleService;

    @Mock
    private MetaWritebackFieldMapper metaWritebackFieldMapper;

    @Mock
    private JdbcTemplate jdbcTemplate;

    @Mock
    private WritebackCompensationService compensationService;

    private WritebackServiceImpl writebackService;

    private static final String SRC_BO_CODE = "sal_outstock";
    private static final String TARGET_TABLE = "sal_order";
    private static final String OPERATION = "audit";
    private static final Long SRC_BILL_ID = 2001L;
    private static final Long TARGET_BILL_ID = 1001L;
    private static final String TARGET_FIELD = "out_qty";
    private static final String SRC_FIELD = "qty";
    private static final String UPDATE_SQL = "UPDATE " + TARGET_TABLE + " SET " + TARGET_FIELD + " = ? WHERE id = ?";

    @BeforeEach
    void setUp() {
        // 构造真实 ExprEvaluator（不走 Spring 容器）
        writebackService = new WritebackServiceImpl();
        ReflectionTestUtils.setField(writebackService, "metaWritebackRuleService", metaWritebackRuleService);
        ReflectionTestUtils.setField(writebackService, "metaWritebackFieldMapper", metaWritebackFieldMapper);
        ReflectionTestUtils.setField(writebackService, "jdbcTemplate", jdbcTemplate);
        ReflectionTestUtils.setField(writebackService, "exprEvaluator", new ExprEvaluator());
        ReflectionTestUtils.setField(writebackService, "compensationService", compensationService);
    }

    // ============ 三种反写模式 ============

    @Test
    @DisplayName("ADD 模式：目标值=10，反写值=5，结果=15")
    void testAddMode() {
        MetaWritebackRule rule = buildRule("WB_ADD_01", "add", "allow", null, "SYNC");
        MetaWritebackField field = buildField();
        stubRuleAndField(rule, field);
        stubQueryCurrent(10);
        when(jdbcTemplate.update(anyString(), any(Object[].class))).thenReturn(1);

        Map<String, Object> root = buildRootData(5);

        WritebackResult result = writebackService.executeWriteback(
                SRC_BO_CODE, SRC_BILL_ID, OPERATION, new ExprContext(root));

        assertTrue(result.isSuccess(), "ADD 模式应成功");
        assertEquals(1, result.getSuccessRules(), "成功规则数应为 1");
        verifyUpdateValue(15.0);
    }

    @Test
    @DisplayName("SUBTRACT 模式：目标值=10，反写值=3，结果=7")
    void testSubtractMode() {
        MetaWritebackRule rule = buildRule("WB_SUB_01", "subtract", "allow", null, "SYNC");
        MetaWritebackField field = buildField();
        stubRuleAndField(rule, field);
        stubQueryCurrent(10);
        when(jdbcTemplate.update(anyString(), any(Object[].class))).thenReturn(1);

        Map<String, Object> root = buildRootData(3);

        WritebackResult result = writebackService.executeWriteback(
                SRC_BO_CODE, SRC_BILL_ID, OPERATION, new ExprContext(root));

        assertTrue(result.isSuccess(), "SUBTRACT 模式应成功");
        verifyUpdateValue(7.0);
    }

    @Test
    @DisplayName("COVER 模式：目标值=10，反写值=8，结果=8")
    void testCoverMode() {
        MetaWritebackRule rule = buildRule("WB_COVER_01", "cover", "allow", null, "SYNC");
        MetaWritebackField field = buildField();
        stubRuleAndField(rule, field);
        stubQueryCurrent(10);
        when(jdbcTemplate.update(anyString(), any(Object[].class))).thenReturn(1);

        Map<String, Object> root = buildRootData(8);

        WritebackResult result = writebackService.executeWriteback(
                SRC_BO_CODE, SRC_BILL_ID, OPERATION, new ExprContext(root));

        assertTrue(result.isSuccess(), "COVER 模式应成功");
        verifyUpdateValue(8.0);
    }

    // ============ 超限控制 ============

    @Test
    @DisplayName("超限 BLOCK：over_limit_expr $result > 20 在结果=25 时抛 ServiceException")
    void testOverLimitBlock() {
        MetaWritebackRule rule = buildRule("WB_BLK_01", "add", "block", "$result > 20", "SYNC");
        MetaWritebackField field = buildField();
        stubRuleAndField(rule, field);
        stubQueryCurrent(10);
        // BLOCK 时 checkOverLimit 抛异常，不执行 update，不桩 update 避免未使用桩告警

        Map<String, Object> root = buildRootData(15); // 10 + 15 = 25 > 20

        ServiceException ex = assertThrows(ServiceException.class, () ->
                writebackService.executeWriteback(SRC_BO_CODE, SRC_BILL_ID, OPERATION, new ExprContext(root)));

        assertEquals("WB_OVER_LIMIT", ex.getCode(), "错误码应为 WB_OVER_LIMIT");
        verify(jdbcTemplate, never()).update(anyString(), any(Object[].class));
    }

    @Test
    @DisplayName("超限 WARN：结果=25 但 policy=WARN，记录 warning 继续")
    void testOverLimitWarn() {
        MetaWritebackRule rule = buildRule("WB_WARN_01", "add", "warn", "$result > 20", "SYNC");
        MetaWritebackField field = buildField();
        stubRuleAndField(rule, field);
        stubQueryCurrent(10);
        when(jdbcTemplate.update(anyString(), any(Object[].class))).thenReturn(1);

        Map<String, Object> root = buildRootData(15); // 10 + 15 = 25 > 20

        WritebackResult result = writebackService.executeWriteback(
                SRC_BO_CODE, SRC_BILL_ID, OPERATION, new ExprContext(root));

        assertTrue(result.isSuccess(), "WARN 不应阻断反写");
        assertFalse(result.getWarnings().isEmpty(), "应记录超限告警");
        verifyUpdateValue(25.0);
    }

    @Test
    @DisplayName("超限 ALLOW：直接继续，不校验 over_expr")
    void testOverLimitAllow() {
        MetaWritebackRule rule = buildRule("WB_ALLOW_01", "add", "allow", "$result > 20", "SYNC");
        MetaWritebackField field = buildField();
        stubRuleAndField(rule, field);
        stubQueryCurrent(10);
        when(jdbcTemplate.update(anyString(), any(Object[].class))).thenReturn(1);

        Map<String, Object> root = buildRootData(15); // 10 + 15 = 25 > 20，但 ALLOW 不校验

        WritebackResult result = writebackService.executeWriteback(
                SRC_BO_CODE, SRC_BILL_ID, OPERATION, new ExprContext(root));

        assertTrue(result.isSuccess(), "ALLOW 应成功");
        assertTrue(result.getWarnings().isEmpty(), "ALLOW 不应记录告警");
        verifyUpdateValue(25.0);
    }

    // ============ 执行模式 ============

    @Test
    @DisplayName("SYNC 模式：反写失败抛异常，不记录补偿")
    void testSyncModeFailure() {
        MetaWritebackRule rule = buildRule("WB_SYNC_01", "add", "allow", null, "SYNC");
        MetaWritebackField field = buildField();
        stubRuleAndField(rule, field);
        stubQueryCurrent(10);
        when(jdbcTemplate.update(anyString(), any(Object[].class)))
                .thenThrow(new RuntimeException("DB 连接失败"));

        Map<String, Object> root = buildRootData(5);

        RuntimeException ex = assertThrows(RuntimeException.class, () ->
                writebackService.executeWriteback(SRC_BO_CODE, SRC_BILL_ID, OPERATION, new ExprContext(root)));

        assertEquals("DB 连接失败", ex.getMessage());
        // SYNC 模式失败直接抛异常，不记录补偿
        verify(compensationService, never())
                .recordFailure(any(), any(), any(), any(), any());
    }

    @Test
    @DisplayName("ASYNC 模式：反写失败记录 biz_writeback_log，不抛异常")
    void testAsyncModeFailure() {
        MetaWritebackRule rule = buildRule("WB_ASYNC_01", "add", "allow", null, "ASYNC");
        MetaWritebackField field = buildField();
        stubRuleAndField(rule, field);
        stubQueryCurrent(10);
        when(jdbcTemplate.update(anyString(), any(Object[].class)))
                .thenThrow(new RuntimeException("DB 连接失败"));

        Map<String, Object> root = buildRootData(5);

        WritebackResult result = writebackService.executeWriteback(
                SRC_BO_CODE, SRC_BILL_ID, OPERATION, new ExprContext(root));

        assertFalse(result.isSuccess(), "ASYNC 失败后 result.success 应为 false");
        assertFalse(result.getErrors().isEmpty(), "应记录错误信息");
        // ASYNC 模式失败记录到 biz_writeback_log（通过补偿服务）
        verify(compensationService).recordFailure(
                eq(rule.getId()), eq(rule.getRuleCode()), eq(SRC_BILL_ID),
                eq(rule.getSrcBillType()), anyString());
    }

    // ============ 辅助构造 ============

    /** 构造反写规则 */
    private MetaWritebackRule buildRule(String ruleCode, String mode, String overControl,
                                        String overExpr, String execMode) {
        MetaWritebackRule rule = new MetaWritebackRule();
        rule.setId(System.currentTimeMillis());
        rule.setRuleCode(ruleCode);
        rule.setRuleName("测试反写规则-" + ruleCode);
        rule.setSrcBillType(SRC_BO_CODE);
        rule.setTargetBillType(TARGET_TABLE);
        rule.setTriggerOp(OPERATION);
        rule.setWritebackMode(mode);
        rule.setOverControl(overControl);
        rule.setOverExpr(overExpr);
        rule.setExecMode(execMode);
        rule.setIsEnabled(1);
        return rule;
    }

    /** 构造字段映射：srcField=qty → targetField=out_qty */
    private MetaWritebackField buildField() {
        MetaWritebackField field = new MetaWritebackField();
        field.setItemSeq(1);
        field.setSrcField(SRC_FIELD);
        field.setTargetField(TARGET_FIELD);
        return field;
    }

    /** 桩：metaWritebackRuleService.list 返回规则，metaWritebackFieldMapper.listByRuleCode 返回字段映射 */
    @SuppressWarnings("unchecked")
    private void stubRuleAndField(MetaWritebackRule rule, MetaWritebackField field) {
        field.setRuleCode(rule.getRuleCode());
        when(metaWritebackRuleService.list(any(com.baomidou.mybatisplus.core.conditions.Wrapper.class)))
                .thenReturn(Collections.singletonList(rule));
        lenient().when(metaWritebackFieldMapper.listByRuleCode(eq(rule.getRuleCode())))
                .thenReturn(Collections.singletonList(field));
    }

    /** 桩：jdbcTemplate.queryForObject 返回目标当前值 */
    private void stubQueryCurrent(int currentValue) {
        doReturn(currentValue).when(jdbcTemplate)
                .queryForObject(anyString(), eq(Object.class), any(Object[].class));
    }

    /** 构造源单据 rootData：{qty: srcQty, targetBillId: TARGET_BILL_ID} */
    private Map<String, Object> buildRootData(int srcQty) {
        Map<String, Object> root = new HashMap<>();
        root.put(SRC_FIELD, srcQty);
        root.put("targetBillId", TARGET_BILL_ID);
        return root;
    }

    /**
     * 验证 jdbcTemplate.update 被调用且新值为期望值。
     * <p>使用 ArgumentCaptor 捕获 varargs 数组（Object[]），断言第一个元素（新值）和第二个元素（目标单据ID）。</p>
     */
    private void verifyUpdateValue(double expectedNewValue) {
        ArgumentCaptor<Object[]> varargsCaptor = ArgumentCaptor.forClass(Object[].class);
        verify(jdbcTemplate).update(eq(UPDATE_SQL), varargsCaptor.capture());
        Object[] varargs = varargsCaptor.getValue();
        assertEquals(expectedNewValue, ((Number) varargs[0]).doubleValue(), 0.0001,
                "反写新值应为 " + expectedNewValue);
        assertEquals(TARGET_BILL_ID.longValue(), ((Number) varargs[1]).longValue(),
                "目标单据ID应一致");
    }
}
