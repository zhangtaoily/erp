package com.eerp.test;

import com.baomidou.mybatisplus.core.conditions.Wrapper;
import com.eerp.bos.rule.RuleEngineImpl;
import com.eerp.bos.rule.RuleItemExecutor;
import com.eerp.bos.rule.RuleViolation;
import com.eerp.meta.rule.entity.MetaEntityRule;
import com.eerp.meta.rule.entity.MetaEntityRuleItem;
import com.eerp.meta.rule.expr.ExprContext;
import com.eerp.meta.rule.expr.ExprEvaluator;
import com.eerp.meta.rule.mapper.MetaEntityRuleItemMapper;
import com.eerp.meta.rule.service.MetaEntityRuleService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.LinkedHashMap;
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
 * 规则引擎单元测试（A4: 规则与反写引擎 —— 实体规则引擎部分）。
 *
 * <p>覆盖任务要求的全部场景：</p>
 * <ul>
 *   <li>VALIDATE 规则：表达式 "$qty > 0" 在 qty=-1 时返回 RuleViolation(block=true)</li>
 *   <li>VALIDATE 规则：qty=10 时无 violation</li>
 *   <li>LINKAGE 规则：表达式 "$total = $qty * $price" 执行后 ctx.rootData.total == 55.0</li>
 *   <li>AGGREGATE 规则：SUM($detail.amount) 聚合子表</li>
 *   <li>多规则按 priority 串行</li>
 *   <li>block violation 收集</li>
 * </ul>
 *
 * <p>测试策略：MetaEntityRuleService / MetaEntityRuleItemMapper 使用 Mockito 桩；
 * ExprEvaluator 使用真实实现（A1 已通过 ExprEvaluatorTest 验证）。</p>
 */
@ExtendWith(MockitoExtension.class)
class RuleEngineTest {

    @Mock
    private MetaEntityRuleService metaEntityRuleService;

    @Mock
    private MetaEntityRuleItemMapper metaEntityRuleItemMapper;

    private RuleEngineImpl ruleEngine;

    private static final String BO_CODE = "SAL_ORDER";
    private static final String TRIGGER_EVENT = "OnBeforeSave";

    @BeforeEach
    void setUp() {
        // 构造真实 ExprEvaluator + RuleItemExecutor（不走 Spring 容器）
        ExprEvaluator evaluator = new ExprEvaluator();
        RuleItemExecutor itemExecutor = new RuleItemExecutor();
        ReflectionTestUtils.setField(itemExecutor, "exprEvaluator", evaluator);

        ruleEngine = new RuleEngineImpl();
        ReflectionTestUtils.setField(ruleEngine, "metaEntityRuleService", metaEntityRuleService);
        ReflectionTestUtils.setField(ruleEngine, "metaEntityRuleItemMapper", metaEntityRuleItemMapper);
        ReflectionTestUtils.setField(ruleEngine, "ruleItemExecutor", itemExecutor);
    }

    // ============ VALIDATE 规则 ============

    @Test
    @DisplayName("VALIDATE 规则：$qty > 0 在 qty=-1 时返回 RuleViolation(block=true)")
    void testValidateRuleViolation() {
        MetaEntityRule rule = buildRule("R_VAL_01", "validate", 100, "$qty > 0", "数量必须大于0");
        stubRules(rule);

        Map<String, Object> root = new HashMap<>();
        root.put("qty", -1);
        ExprContext ctx = new ExprContext(root);

        List<RuleViolation> violations = ruleEngine.executeRules(BO_CODE, TRIGGER_EVENT, ctx);

        assertEquals(1, violations.size(), "应返回 1 个违反");
        RuleViolation v = violations.get(0);
        assertEquals("R_VAL_01", v.getRuleCode());
        assertEquals("数量必须大于0", v.getMessage());
        assertEquals("ERROR", v.getSeverity());
        assertTrue(v.isBlock(), "validate 失败应 block=true");
    }

    @Test
    @DisplayName("VALIDATE 规则：qty=10 时无 violation")
    void testValidateRulePass() {
        MetaEntityRule rule = buildRule("R_VAL_02", "validate", 100, "$qty > 0", "数量必须大于0");
        stubRules(rule);

        Map<String, Object> root = new HashMap<>();
        root.put("qty", 10);
        ExprContext ctx = new ExprContext(root);

        List<RuleViolation> violations = ruleEngine.executeRules(BO_CODE, TRIGGER_EVENT, ctx);

        assertTrue(violations.isEmpty(), "qty=10 校验通过应无违反");
    }

    @Test
    @DisplayName("VALIDATE 规则：error() 函数抛 ExprException 也收集为 violation")
    void testValidateRuleWithErrorFunction() {
        // 表达式 IF($qty <= 0, error('数量非法'), true)
        MetaEntityRule rule = buildRule("R_VAL_03", "validate", 100,
                "IF($qty <= 0, error('数量非法'), true)", null);
        stubRules(rule);

        Map<String, Object> root = new HashMap<>();
        root.put("qty", 0);
        ExprContext ctx = new ExprContext(root);

        List<RuleViolation> violations = ruleEngine.executeRules(BO_CODE, TRIGGER_EVENT, ctx);

        assertEquals(1, violations.size());
        assertEquals("数量非法", violations.get(0).getMessage());
        assertTrue(violations.get(0).isBlock());
    }

    // ============ LINKAGE 规则 ============

    @Test
    @DisplayName("LINKAGE 规则：$total = $qty * $price 执行后 ctx.rootData.total == 55.0")
    void testLinkageRuleAssignment() {
        MetaEntityRule rule = buildRule("R_LINK_01", "linkage", 100,
                "$total = $qty * $price", null);
        stubRules(rule);

        Map<String, Object> root = new HashMap<>();
        root.put("qty", 10);
        root.put("price", 5.5);
        ExprContext ctx = new ExprContext(root);

        List<RuleViolation> violations = ruleEngine.executeRules(BO_CODE, TRIGGER_EVENT, ctx);

        assertTrue(violations.isEmpty(), "linkage 不应产生违反");
        // 验证赋值已写回 rootData
        Object total = ctx.getRootData().get("total");
        assertNotNull(total, "rootData.total 不应为 null");
        assertEquals(55.0, ((Number) total).doubleValue(), 0.0001,
                "rootData.total 应为 55.0（10 * 5.5）");
    }

    @Test
    @DisplayName("LINKAGE 规则：赋值后变量可在后续表达式中引用")
    void testLinkageRuleVariableReference() {
        // 两条 item：先赋值 $total，再用 $total 计算 $tax
        MetaEntityRule rule = buildRule("R_LINK_02", "linkage", 100, null, null);
        MetaEntityRuleItem item1 = buildItem(1, "$total = $qty * $price", null);
        MetaEntityRuleItem item2 = buildItem(2, "$tax = $total * 0.1", null);
        rule.setItems(Arrays.asList(item1, item2));
        stubRules(rule);

        Map<String, Object> root = new HashMap<>();
        root.put("qty", 10);
        root.put("price", 5.5);
        ExprContext ctx = new ExprContext(root);

        ruleEngine.executeRules(BO_CODE, TRIGGER_EVENT, ctx);

        assertEquals(55.0, ((Number) ctx.getRootData().get("total")).doubleValue(), 0.0001);
        assertEquals(5.5, ((Number) ctx.getRootData().get("tax")).doubleValue(), 0.0001);
    }

    // ============ AGGREGATE 规则 ============

    @Test
    @DisplayName("AGGREGATE 规则：SUM($detail.amount) 聚合子表 == 60.0")
    void testAggregateRuleSum() {
        MetaEntityRule rule = buildRule("R_AGG_01", "aggregate", 100,
                "SUM($detail.amount)", null);
        stubRules(rule);

        ExprContext ctx = buildDetailContext();

        List<RuleViolation> violations = ruleEngine.executeRules(BO_CODE, TRIGGER_EVENT, ctx);

        assertTrue(violations.isEmpty(), "aggregate 不应产生违反");
        // 聚合结果写入 _aggregate_result 变量
        Object result = ctx.getVariable(RuleEngineImpl.AGGREGATE_RESULT_VAR);
        assertNotNull(result, "聚合结果不应为 null");
        assertEquals(60.0, ((Number) result).doubleValue(), 0.0001,
                "SUM($detail.amount) 应为 60.0（10+20+30）");
    }

    @Test
    @DisplayName("AGGREGATE 规则：COUNT($detail) == 3")
    void testAggregateRuleCount() {
        MetaEntityRule rule = buildRule("R_AGG_02", "aggregate", 100,
                "COUNT($detail)", null);
        stubRules(rule);

        ExprContext ctx = buildDetailContext();
        ruleEngine.executeRules(BO_CODE, TRIGGER_EVENT, ctx);

        Object result = ctx.getVariable(RuleEngineImpl.AGGREGATE_RESULT_VAR);
        assertEquals(Integer.valueOf(3), result, "COUNT($detail) 应为 3");
    }

    // ============ 多规则串行 + block 收集 ============

    @Test
    @DisplayName("多规则按 priority 串行：低 priority 先执行，结果可被后续规则引用")
    void testMultipleRulesSerialByPriority() {
        // 规则1（priority=10）：linkage 计算 $total = $qty * $price
        MetaEntityRule rule1 = buildRule("R_MULTI_01", "linkage", 10,
                "$total = $qty * $price", null);
        // 规则2（priority=20）：validate 校验 $total > 100
        MetaEntityRule rule2 = buildRule("R_MULTI_02", "validate", 20,
                "$total > 100", "合计必须大于100");

        // list 返回时按 priority 升序（rule1 在前）
        when(metaEntityRuleService.list(any(Wrapper.class))).thenReturn(Arrays.asList(rule1, rule2));
        lenient().when(metaEntityRuleItemMapper.listByRuleCode(eq("R_MULTI_01")))
                .thenReturn(rule1.getItems());
        lenient().when(metaEntityRuleItemMapper.listByRuleCode(eq("R_MULTI_02")))
                .thenReturn(rule2.getItems());

        Map<String, Object> root = new HashMap<>();
        root.put("qty", 10);
        root.put("price", 5.5); // total = 55.0
        ExprContext ctx = new ExprContext(root);

        List<RuleViolation> violations = ruleEngine.executeRules(BO_CODE, TRIGGER_EVENT, ctx);

        // rule1 linkage 执行后 $total=55.0；rule2 validate $total > 100 → false → 违反
        assertEquals(1, violations.size(), "rule2 应校验失败");
        assertEquals("R_MULTI_02", violations.get(0).getRuleCode());
        assertTrue(violations.get(0).isBlock());
        // 验证 rule1 的赋值确实执行（serial 顺序）
        assertEquals(55.0, ((Number) ctx.getRootData().get("total")).doubleValue(), 0.0001);
    }

    @Test
    @DisplayName("block violation 收集：多条规则中违反的均被收集")
    void testBlockViolationCollection() {
        // 两条 validate 规则，均会违反
        MetaEntityRule rule1 = buildRule("R_BLK_01", "validate", 10,
                "$qty > 0", "数量必须大于0");
        MetaEntityRule rule2 = buildRule("R_BLK_02", "validate", 20,
                "$price > 0", "单价必须大于0");

        when(metaEntityRuleService.list(any(Wrapper.class))).thenReturn(Arrays.asList(rule1, rule2));
        lenient().when(metaEntityRuleItemMapper.listByRuleCode(eq("R_BLK_01")))
                .thenReturn(rule1.getItems());
        lenient().when(metaEntityRuleItemMapper.listByRuleCode(eq("R_BLK_02")))
                .thenReturn(rule2.getItems());

        Map<String, Object> root = new HashMap<>();
        root.put("qty", -1);
        root.put("price", -2);
        ExprContext ctx = new ExprContext(root);

        List<RuleViolation> violations = ruleEngine.executeRules(BO_CODE, TRIGGER_EVENT, ctx);

        assertEquals(2, violations.size(), "两条规则均应违反");
        assertTrue(violations.stream().allMatch(RuleViolation::isBlock),
                "所有 violation 应 block=true");
        assertEquals("R_BLK_01", violations.get(0).getRuleCode());
        assertEquals("R_BLK_02", violations.get(1).getRuleCode());
    }

    @Test
    @DisplayName("无规则时返回空违反列表")
    void testNoRules() {
        when(metaEntityRuleService.list(any(Wrapper.class))).thenReturn(Collections.emptyList());

        ExprContext ctx = new ExprContext(new HashMap<>());
        List<RuleViolation> violations = ruleEngine.executeRules(BO_CODE, TRIGGER_EVENT, ctx);

        assertNotNull(violations);
        assertTrue(violations.isEmpty());
    }

    @Test
    @DisplayName("规则无 items 时返回 null（不违反）")
    void testRuleWithoutItems() {
        MetaEntityRule rule = buildRule("R_EMPTY", "validate", 100, null, null);
        rule.setItems(null);
        stubRules(rule);

        ExprContext ctx = new ExprContext(new HashMap<>());
        List<RuleViolation> violations = ruleEngine.executeRules(BO_CODE, TRIGGER_EVENT, ctx);

        assertTrue(violations.isEmpty());
    }

    // ============ 辅助构造 ============

    /** 桩：metaEntityRuleService.list 返回指定规则，itemMapper 按 ruleCode 返回规则 items */
    private void stubRules(MetaEntityRule... rules) {
        when(metaEntityRuleService.list(any(Wrapper.class))).thenReturn(Arrays.asList(rules));
        for (MetaEntityRule r : rules) {
            lenient().when(metaEntityRuleItemMapper.listByRuleCode(eq(r.getRuleCode())))
                    .thenReturn(r.getItems() == null ? Collections.emptyList() : r.getItems());
        }
    }

    /** 构造规则 + 单个 item（actionExpr） */
    private MetaEntityRule buildRule(String ruleCode, String ruleType, int priority,
                                     String actionExpr, String errorMsg) {
        MetaEntityRule rule = new MetaEntityRule();
        rule.setId(System.currentTimeMillis());
        rule.setRuleCode(ruleCode);
        rule.setRuleName("测试规则-" + ruleCode);
        rule.setBoCode(BO_CODE);
        rule.setEntityCode("main");
        rule.setRuleType(ruleType);
        rule.setTriggerEvent(TRIGGER_EVENT);
        rule.setPriority(priority);
        rule.setIsEnabled(1);
        if (actionExpr != null) {
            MetaEntityRuleItem item = buildItem(1, actionExpr, errorMsg);
            rule.setItems(new ArrayList<>(Collections.singletonList(item)));
        } else {
            rule.setItems(new ArrayList<>());
        }
        return rule;
    }

    private MetaEntityRuleItem buildItem(int seq, String actionExpr, String errorMsg) {
        MetaEntityRuleItem item = new MetaEntityRuleItem();
        item.setId(System.currentTimeMillis() + seq);
        item.setRuleCode("R");
        item.setItemSeq(seq);
        item.setActionExpr(actionExpr);
        item.setErrorMsg(errorMsg);
        return item;
    }

    /** 构造含 detail 子表的上下文：3 行，amount=[10.0,20.0,30.0] */
    private ExprContext buildDetailContext() {
        Map<String, Object> root = new HashMap<>();
        root.put("bill_no", "SO202607170001");

        Map<String, Object> row1 = new LinkedHashMap<>();
        row1.put("qty", 2);
        row1.put("amount", 10.0);

        Map<String, Object> row2 = new LinkedHashMap<>();
        row2.put("qty", 3);
        row2.put("amount", 20.0);

        Map<String, Object> row3 = new LinkedHashMap<>();
        row3.put("qty", 4);
        row3.put("amount", 30.0);

        List<Map<String, Object>> detail = Arrays.asList(row1, row2, row3);
        Map<String, List<Map<String, Object>>> subData = new HashMap<>();
        subData.put("detail", detail);

        return new ExprContext(root, subData);
    }
}
