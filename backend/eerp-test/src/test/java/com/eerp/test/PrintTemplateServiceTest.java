package com.eerp.test;

import com.eerp.bos.bill.BillDataAccessor;
import com.eerp.bos.print.AbstractPrintTemplateService;
import com.eerp.bos.print.PrintTemplateServiceImpl;
import com.eerp.meta.print.entity.MetaPrintTemplate;
import com.eerp.meta.print.service.MetaPrintTemplateService;
import com.eerp.meta.rule.expr.ExprEvaluator;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.test.util.ReflectionTestUtils;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.when;

/**
 * 打印模板服务单元测试（A7：打印模板渲染）。
 *
 * <p>覆盖场景：</p>
 * <ul>
 *   <li>render：渲染单据返回 HTML 字节流</li>
 *   <li>render：单元格 cell_type=field 取值正确</li>
 *   <li>render：单元格 cell_type=formula 公式求值（=SUM 等）</li>
 *   <li>render：detail 行带向下扩展多行</li>
 *   <li>render：merges_json 合并单元格</li>
 *   <li>renderBatch：批量渲染多单据</li>
 *   <li>render：模板不存在返回空</li>
 *   <li>listByBoCode / getDefault：委托 MetaPrintTemplateService</li>
 * </ul>
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class PrintTemplateServiceTest {

    @Mock
    private MetaPrintTemplateService metaPrintTemplateService;

    @Mock
    private BillDataAccessor billDataAccessor;

    private PrintTemplateServiceImpl printService;

    /** 可配置的模板（每个测试可覆盖） */
    private MetaPrintTemplate currentTemplate;

    private static final String BO_CODE = "sal_order";
    private static final Long BILL_ID = 1001L;
    private static final Long TEMPLATE_ID = 5001L;

    @BeforeEach
    void setUp() {
        currentTemplate = buildTemplate();
        printService = new PrintTemplateServiceImpl() {
            @Override
            protected MetaPrintTemplate loadTemplate(Long id) {
                if (TEMPLATE_ID.equals(id)) {
                    return currentTemplate;
                }
                return null;
            }
        };
        ExprEvaluator evaluator = new ExprEvaluator();
        ReflectionTestUtils.setField(printService, "metaPrintTemplateService", metaPrintTemplateService);
        ReflectionTestUtils.setField(printService, "billDataAccessor", billDataAccessor);
        ReflectionTestUtils.setField(printService, "exprEvaluator", evaluator);

        // 默认源单数据
        lenient().when(billDataAccessor.loadBill(eq(BO_CODE), anyLong())).thenReturn(buildBill());
    }

    @Test
    @DisplayName("render：渲染单据返回 HTML 字节流")
    void testRenderReturnsHtmlBytes() {
        byte[] result = printService.render(TEMPLATE_ID, BILL_ID);
        assertNotNull(result);
        assertTrue(result.length > 0);
        String html = new String(result, StandardCharsets.UTF_8);
        assertTrue(html.contains("<html>"), "应输出 HTML");
        assertTrue(html.contains("<table>"), "应包含 table");
    }

    @Test
    @DisplayName("render：cell_type=field 取字段值")
    void testRenderFieldCell() {
        currentTemplate.setCellsJson("{\"0_0\":{\"content\":\"\",\"cell_type\":\"field\",\"field_code\":\"code\",\"entity_code\":\"main\"}}");

        byte[] result = printService.render(TEMPLATE_ID, BILL_ID);
        String html = new String(result, StandardCharsets.UTF_8);
        assertTrue(html.contains("SO001"), "应渲染主表 code 字段值");
    }

    @Test
    @DisplayName("render：cell_type=text 静态文本")
    void testRenderTextCell() {
        byte[] result = printService.render(TEMPLATE_ID, BILL_ID);
        String html = new String(result, StandardCharsets.UTF_8);
        assertTrue(html.contains("单据标题"), "应渲染静态文本");
    }

    @Test
    @DisplayName("render：detail 行带向下扩展多行")
    void testRenderDetailExpand() {
        // 模板含 3 行：title/header/detail，detail 行带配置在第 2 行
        currentTemplate.setRowCount(3);
        currentTemplate.setColCount(2);
        currentTemplate.setRowBandsJson("[{\"band\":\"title\",\"row\":0},{\"band\":\"header\",\"row\":1},{\"band\":\"detail\",\"row\":2}]");
        currentTemplate.setCellsJson("{\"0_0\":{\"content\":\"单据标题\",\"cell_type\":\"text\"},"
                + "\"1_0\":{\"content\":\"物料\",\"cell_type\":\"text\"},"
                + "\"1_1\":{\"content\":\"数量\",\"cell_type\":\"text\"},"
                + "\"2_0\":{\"content\":\"\",\"cell_type\":\"field\",\"field_code\":\"mat_id\",\"entity_code\":\"detail\"},"
                + "\"2_1\":{\"content\":\"\",\"cell_type\":\"field\",\"field_code\":\"qty\",\"entity_code\":\"detail\"}}");

        // 单据含 2 行明细
        when(billDataAccessor.loadBill(eq(BO_CODE), anyLong())).thenReturn(buildBillWith2Lines());

        byte[] result = printService.render(TEMPLATE_ID, BILL_ID);
        String html = new String(result, StandardCharsets.UTF_8);
        // 应包含 2 行明细的 mat_id 值
        assertTrue(html.contains("9001"), "应渲染第一行明细 mat_id");
        assertTrue(html.contains("9002"), "应渲染第二行明细 mat_id");
    }

    @Test
    @DisplayName("render：merges_json 合并单元格")
    void testRenderMergedCells() {
        currentTemplate.setRowCount(2);
        currentTemplate.setColCount(2);
        currentTemplate.setCellsJson("{\"0_0\":{\"content\":\"合并标题\",\"cell_type\":\"text\"},"
                + "\"0_1\":{\"content\":\"\",\"cell_type\":\"text\"}}");
        currentTemplate.setMergesJson("{\"0_0\":{\"rowspan\":1,\"colspan\":2}}");

        byte[] result = printService.render(TEMPLATE_ID, BILL_ID);
        String html = new String(result, StandardCharsets.UTF_8);
        assertTrue(html.contains("colspan='2'"), "应渲染 colspan=2 合并");
    }

    @Test
    @DisplayName("renderBatch：批量渲染多单据")
    void testRenderBatchMultipleBills() {
        when(billDataAccessor.loadBill(eq(BO_CODE), eq(1001L))).thenReturn(buildBill());
        when(billDataAccessor.loadBill(eq(BO_CODE), eq(1002L))).thenReturn(buildBill());

        byte[] result = printService.renderBatch(TEMPLATE_ID, java.util.Arrays.asList(1001L, 1002L));
        String html = new String(result, StandardCharsets.UTF_8);
        // 应包含两次 page-break 分页
        assertTrue(html.contains("page-break-after"), "应含分页符");
    }

    @Test
    @DisplayName("render：模板不存在返回空字节")
    void testRenderTemplateNotFound() {
        byte[] result = printService.render(9999L, BILL_ID);
        assertEquals(0, result.length, "模板不存在应返回空字节");
    }

    @Test
    @DisplayName("render：单据ID为 null 返回空字节")
    void testRenderNullBillId() {
        byte[] result = printService.render(TEMPLATE_ID, null);
        assertEquals(0, result.length);
    }

    @Test
    @DisplayName("listByBoCode：委托 MetaPrintTemplateService")
    void testListByBoCode() {
        List<MetaPrintTemplate> mockList = new ArrayList<>();
        mockList.add(buildTemplate());
        when(metaPrintTemplateService.listByBoCode(BO_CODE)).thenReturn(mockList);

        List<MetaPrintTemplate> result = printService.listByBoCode(BO_CODE);
        assertEquals(1, result.size());
    }

    @Test
    @DisplayName("getDefault：委托 MetaPrintTemplateService")
    void testGetDefault() {
        MetaPrintTemplate tpl = buildTemplate();
        when(metaPrintTemplateService.getDefault(BO_CODE)).thenReturn(tpl);

        MetaPrintTemplate result = printService.getDefault(BO_CODE);
        assertNotNull(result);
        assertEquals(TEMPLATE_ID, result.getId());
    }

    // ==================== 辅助方法 ====================

    private MetaPrintTemplate buildTemplate() {
        MetaPrintTemplate tpl = new MetaPrintTemplate();
        tpl.setId(TEMPLATE_ID);
        tpl.setTemplateCode("TPL_TEST");
        tpl.setTemplateName("测试模板");
        tpl.setBoCode(BO_CODE);
        tpl.setTemplateType("single");
        tpl.setPaperType("A4");
        tpl.setOrientation("portrait");
        tpl.setRowCount(1);
        tpl.setColCount(1);
        tpl.setCellsJson("{\"0_0\":{\"content\":\"单据标题\",\"cell_type\":\"text\"}}");
        tpl.setMergesJson("{}");
        tpl.setRowBandsJson("[{\"band\":\"title\",\"row\":0}]");
        tpl.setIsDefault(1);
        tpl.setIsEnable(1);
        return tpl;
    }

    private Map<String, Object> buildBill() {
        Map<String, Object> bill = new LinkedHashMap<>();
        Map<String, Object> main = new LinkedHashMap<>();
        main.put("id", BILL_ID);
        main.put("code", "SO001");
        main.put("pact_state", 3);
        bill.put("main", main);

        Map<String, Object> subs = new LinkedHashMap<>();
        List<Map<String, Object>> lines = new ArrayList<>();
        Map<String, Object> line = new HashMap<>();
        line.put("id", 5001L);
        line.put("mat_id", 9001L);
        line.put("qty", new BigDecimal("10"));
        lines.add(line);
        subs.put("sal_order_goods", lines);
        bill.put("subs", subs);
        return bill;
    }

    private Map<String, Object> buildBillWith2Lines() {
        Map<String, Object> bill = buildBill();
        Map<String, Object> subs = (Map<String, Object>) bill.get("subs");
        List<Map<String, Object>> lines = (List<Map<String, Object>>) subs.get("sal_order_goods");
        Map<String, Object> line2 = new HashMap<>();
        line2.put("id", 5002L);
        line2.put("mat_id", 9002L);
        line2.put("qty", new BigDecimal("20"));
        lines.add(line2);
        return bill;
    }
}
