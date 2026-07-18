package com.eerp.test;

import com.eerp.bos.bill.BillDataAccessor;
import com.eerp.bos.bill.AbstractBillLinkService;
import com.eerp.bos.push.PushContext;
import com.eerp.bos.push.PushLine;
import com.eerp.bos.push.PushResult;
import com.eerp.bos.push.PushServiceImpl;
import com.eerp.bos.runtime.entity.BizBillLink;
import com.eerp.common.exception.ServiceException;
import com.eerp.common.id.SnowflakeIdGenerator;
import com.eerp.meta.push.entity.MetaPushRule;
import com.eerp.meta.push.service.MetaPushRuleService;
import com.eerp.meta.rule.expr.ExprEvaluator;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.util.ReflectionTestUtils;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.fail;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * 下推服务单元测试（A7：下推生成 + 回写 + 关联记录）。
 *
 * <p>覆盖场景：</p>
 * <ul>
 *   <li>下推成功：规则加载 → 过滤 → 校验 → 映射 → 持久化 → 关联 → 回写 全链路</li>
 *   <li>下推失败：规则不存在</li>
 *   <li>下推失败：未勾选行</li>
 *   <li>下推失败：可下推量不足（vp_check_expr 返回 false）抛 ServiceException</li>
 *   <li>下推成功：biz_bill_link 写入正确条数</li>
 *   <li>下推成功：源单 pushed_field 回写 UPDATE 调用</li>
 *   <li>field_mapping_json 解析：主表/子表字段映射</li>
 *   <li>transform_expr 转换表达式求值</li>
 * </ul>
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class PushServiceTest {

    @Mock
    private MetaPushRuleService metaPushRuleService;

    @Mock
    private BillDataAccessor billDataAccessor;

    @Mock
    private JdbcTemplate jdbcTemplate;

    @Mock
    private SnowflakeIdGenerator snowflakeIdGenerator;

    @Mock
    private AbstractBillLinkService billLinkService;

    private PushServiceImpl pushService;

    private static final String SRC_BO = "sal_order";
    private static final String TGT_BO = "pur_order";
    private static final Long SRC_BILL_ID = 1001L;
    private static final Long TGT_BILL_ID = 2002L;
    private static final Long LINE_ID = 5001L;
    private static final String RULE_CODE = "PUSH_SAL_TO_PUR";

    @BeforeEach
    void setUp() {
        pushService = new PushServiceImpl();
        ExprEvaluator evaluator = new ExprEvaluator();
        ReflectionTestUtils.setField(pushService, "metaPushRuleService", metaPushRuleService);
        ReflectionTestUtils.setField(pushService, "billDataAccessor", billDataAccessor);
        ReflectionTestUtils.setField(pushService, "exprEvaluator", evaluator);
        ReflectionTestUtils.setField(pushService, "jdbcTemplate", jdbcTemplate);
        ReflectionTestUtils.setField(pushService, "snowflakeIdGenerator", snowflakeIdGenerator);
        pushService.setBillLinkService(billLinkService);

        lenient().when(snowflakeIdGenerator.nextId()).thenReturn(TGT_BILL_ID);
        // BillDataAccessor.saveBill 返回目标单ID
        lenient().when(billDataAccessor.saveBill(eq(TGT_BO), any())).thenReturn(TGT_BILL_ID);
    }

    @Test
    @DisplayName("下推失败：规则编码为空")
    void testPushNullRuleCode() {
        PushContext ctx = new PushContext();
        PushResult result = pushService.push(ctx);
        assertEquals(false, result.isSuccess());
        assertTrue(result.getMessage().contains("规则编码"));
    }

    @Test
    @DisplayName("下推失败：未勾选行")
    void testPushNoLines() {
        PushContext ctx = buildCtx();
        ctx.setLines(new ArrayList<>());
        when(metaPushRuleService.getOne(any())).thenReturn(buildRule());

        PushResult result = pushService.push(ctx);
        assertEquals(false, result.isSuccess());
        assertTrue(result.getMessage().contains("未勾选"));
    }

    @Test
    @DisplayName("下推失败：规则不存在")
    void testPushRuleNotFound() {
        PushContext ctx = buildCtx();
        ctx.setLines(Arrays.asList(new PushLine(LINE_ID, new BigDecimal("5"))));
        when(metaPushRuleService.getOne(any())).thenReturn(null);

        PushResult result = pushService.push(ctx);
        assertEquals(false, result.isSuccess());
        assertTrue(result.getMessage().contains("不存在"));
    }

    @Test
    @DisplayName("下推成功：全链路（过滤+校验+映射+持久化+关联+回写）")
    void testPushSuccess() {
        PushContext ctx = buildCtx();
        ctx.setLines(Arrays.asList(new PushLine(LINE_ID, new BigDecimal("5"))));

        MetaPushRule rule = buildRule();
        when(metaPushRuleService.getOne(any())).thenReturn(rule);
        when(billDataAccessor.loadBill(eq(SRC_BO), eq(SRC_BILL_ID)))
                .thenReturn(buildSrcBill());

        PushResult result = pushService.push(ctx);

        assertTrue(result.isSuccess(), "下推应成功");
        assertEquals(TGT_BILL_ID, result.getTargetBillId());
        assertEquals(1, result.getLinkCount(), "应写入 1 条关联");

        // 验证 biz_bill_link 写入
        ArgumentCaptor<BizBillLink> linkCaptor = ArgumentCaptor.forClass(BizBillLink.class);
        verify(billLinkService).create(linkCaptor.capture());
        BizBillLink link = linkCaptor.getValue();
        assertEquals(SRC_BO, link.getSrcBoCode());
        assertEquals(SRC_BILL_ID, link.getSrcBillId());
        assertEquals(TGT_BO, link.getTgtBoCode());
        assertEquals(TGT_BILL_ID, link.getTgtBillId());
        assertEquals(RULE_CODE, link.getPushRuleCode());
        assertEquals(new BigDecimal("5"), link.getLinkQty());

        // 验证源单 pushed_field 回写 UPDATE
        verify(jdbcTemplate).update(anyString(), eq(new BigDecimal("5")), eq(LINE_ID));
    }

    @Test
    @DisplayName("下推失败：可下推量不足抛 ServiceException")
    void testPushQtyOverLimit() {
        PushContext ctx = buildCtx();
        // push_qty=100，但 vp_check_expr 校验 $qty - $out_qty >= $push_qty 应失败
        ctx.setLines(Arrays.asList(new PushLine(LINE_ID, new BigDecimal("100"))));

        MetaPushRule rule = buildRule();
        rule.setVpCheckExpr("$qty - $out_qty >= $push_qty");
        when(metaPushRuleService.getOne(any())).thenReturn(rule);
        when(billDataAccessor.loadBill(eq(SRC_BO), eq(SRC_BILL_ID)))
                .thenReturn(buildSrcBill());

        try {
            pushService.push(ctx);
            fail("应抛 ServiceException");
        } catch (ServiceException ex) {
            assertEquals("PUSH_QTY_OVER_LIMIT", ex.getCode());
        }
    }

    @Test
    @DisplayName("下推成功：filter_expr 过滤源单行")
    void testPushFilterExpr() {
        PushContext ctx = buildCtx();
        ctx.setLines(Arrays.asList(new PushLine(LINE_ID, new BigDecimal("3"))));

        MetaPushRule rule = buildRule();
        rule.setFilterExpr("$pact_state == 3");
        when(metaPushRuleService.getOne(any())).thenReturn(rule);
        // 源单行 pact_state=3，应通过过滤
        when(billDataAccessor.loadBill(eq(SRC_BO), eq(SRC_BILL_ID)))
                .thenReturn(buildSrcBill());

        PushResult result = pushService.push(ctx);
        assertTrue(result.isSuccess());
    }

    @Test
    @DisplayName("下推成功：field_mapping_json 主子表字段映射")
    void testPushFieldMapping() {
        PushContext ctx = buildCtx();
        ctx.setLines(Arrays.asList(new PushLine(LINE_ID, new BigDecimal("5"))));

        MetaPushRule rule = buildRule();
        rule.setFieldMappingJson("["
                + "{\"src_field\":\"code\",\"target_field\":\"src_code\",\"is_main\":true},"
                + "{\"src_field\":\"mat_id\",\"target_field\":\"material_id\",\"is_main\":false},"
                + "{\"src_field\":\"qty\",\"target_field\":\"order_qty\",\"is_main\":false}"
                + "]");
        when(metaPushRuleService.getOne(any())).thenReturn(rule);
        when(billDataAccessor.loadBill(eq(SRC_BO), eq(SRC_BILL_ID)))
                .thenReturn(buildSrcBill());

        PushResult result = pushService.push(ctx);
        assertTrue(result.isSuccess());

        // 验证 saveBill 被调用且包含映射字段
        ArgumentCaptor<Map> billCaptor = ArgumentCaptor.forClass(Map.class);
        verify(billDataAccessor).saveBill(eq(TGT_BO), billCaptor.capture());
        Map<String, Object> savedBill = billCaptor.getValue();
        Map<String, Object> main = (Map<String, Object>) savedBill.get("main");
        assertEquals("SO001", main.get("src_code"), "主表 src_code 应映射自源单 code");
    }

    @Test
    @DisplayName("下推成功：transform_expr 转换表达式")
    void testPushTransformExpr() {
        PushContext ctx = buildCtx();
        ctx.setLines(Arrays.asList(new PushLine(LINE_ID, new BigDecimal("5"))));

        MetaPushRule rule = buildRule();
        rule.setFieldMappingJson("["
                + "{\"target_field\":\"display_name\",\"is_main\":true,"
                + "\"transform_expr\":\"'ORDER-' + $main.code\"}"
                + "]");
        when(metaPushRuleService.getOne(any())).thenReturn(rule);
        when(billDataAccessor.loadBill(eq(SRC_BO), eq(SRC_BILL_ID)))
                .thenReturn(buildSrcBill());

        PushResult result = pushService.push(ctx);
        assertTrue(result.isSuccess());

        ArgumentCaptor<Map> billCaptor = ArgumentCaptor.forClass(Map.class);
        verify(billDataAccessor).saveBill(eq(TGT_BO), billCaptor.capture());
        Map<String, Object> savedBill = billCaptor.getValue();
        Map<String, Object> main = (Map<String, Object>) savedBill.get("main");
        // transform_expr 求值为字符串拼接
        assertNotNull(main.get("display_name"));
    }

    @Test
    @DisplayName("下推成功：目标 bo 一致性校验通过")
    void testPushTgtBoConsistency() {
        PushContext ctx = buildCtx();
        ctx.setTgtBoCode(TGT_BO);
        ctx.setLines(Arrays.asList(new PushLine(LINE_ID, new BigDecimal("5"))));

        MetaPushRule rule = buildRule();
        when(metaPushRuleService.getOne(any())).thenReturn(rule);
        when(billDataAccessor.loadBill(eq(SRC_BO), eq(SRC_BILL_ID)))
                .thenReturn(buildSrcBill());

        PushResult result = pushService.push(ctx);
        assertTrue(result.isSuccess());
    }

    @Test
    @DisplayName("下推失败：目标 bo 与规则配置不一致")
    void testPushTgtBoMismatch() {
        PushContext ctx = buildCtx();
        ctx.setTgtBoCode("wrong_bo");
        ctx.setLines(Arrays.asList(new PushLine(LINE_ID, new BigDecimal("5"))));

        MetaPushRule rule = buildRule();
        when(metaPushRuleService.getOne(any())).thenReturn(rule);

        PushResult result = pushService.push(ctx);
        assertEquals(false, result.isSuccess());
        assertTrue(result.getMessage().contains("不一致"));
    }

    // ==================== 辅助方法 ====================

    private PushContext buildCtx() {
        PushContext ctx = new PushContext();
        ctx.setSrcBoCode(SRC_BO);
        ctx.setSrcBillId(SRC_BILL_ID);
        ctx.setRuleCode(RULE_CODE);
        return ctx;
    }

    private MetaPushRule buildRule() {
        MetaPushRule rule = new MetaPushRule();
        rule.setRuleCode(RULE_CODE);
        rule.setSrcBoCode(SRC_BO);
        rule.setTgtBoCode(TGT_BO);
        rule.setQtyField("qty");
        rule.setPushedField("out_qty");
        rule.setAllowMerge(0);
        rule.setAllowSplit(0);
        rule.setIsEnable(1);
        rule.setFieldMappingJson("[{\"src_field\":\"code\",\"target_field\":\"src_code\",\"is_main\":true}]");
        rule.setVpCheckExpr("$qty - $out_qty >= $push_qty");
        return rule;
    }

    private Map<String, Object> buildSrcBill() {
        Map<String, Object> bill = new LinkedHashMap<>();
        Map<String, Object> main = new LinkedHashMap<>();
        main.put("id", SRC_BILL_ID);
        main.put("code", "SO001");
        main.put("pact_state", 3);
        bill.put("main", main);

        Map<String, Object> subs = new LinkedHashMap<>();
        List<Map<String, Object>> lines = new ArrayList<>();
        Map<String, Object> line = new LinkedHashMap<>();
        line.put("id", LINE_ID);
        line.put("mat_id", 9001L);
        line.put("qty", new BigDecimal("10"));
        line.put("out_qty", new BigDecimal("2"));
        line.put("pact_state", 3);
        lines.add(line);
        subs.put("sal_order_goods", lines);
        bill.put("subs", subs);
        return bill;
    }
}
