package com.eerp.test.scm;

import com.eerp.test.AbstractIntegrationTest;
import com.eerp.test.EerpTestApplication;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

/**
 * 供应链管理模块（采购）集成测试（Phase 2a，对齐设计文档 03）。
 *
 * <p>验证 7 个采购业务单据的元数据注册、状态机配置、CRUD 端到端流程、
 * 含子表/孙表的主数据保存、状态流转（save → submit → audit）。</p>
 *
 * <p>测试范围：</p>
 * <ul>
 *   <li>7 个采购 bo_code 在 meta_business_object 中正确注册（bo_type='business', is_stateful=1）</li>
 *   <li>每个 bo_code 独立状态机（5 节点 + 17 流转，code=bo_code）</li>
 *   <li>meta_form_entity 实体层级（7 主 + 7 子 + 1 孙 = 15）</li>
 *   <li>meta_form_field 字段元数据（148 个关键字段）</li>
 *   <li>采购订单 CRUD：保存 → 查询详情 → 状态流转</li>
 *   <li>含子表保存：采购订单主表 + 明细子表</li>
 *   <li>含孙表保存：采购合同主表 + 明细子表 + 配额孙表</li>
 * </ul>
 */
@SpringBootTest(classes = EerpTestApplication.class)
@ActiveProfiles("test")
@AutoConfigureMockMvc
class ScmIntegrationTest extends AbstractIntegrationTest {

    // ==================== 元数据注册验证 ====================

    @Test
    @DisplayName("7 个采购 bo_code 在 meta_business_object 中注册")
    void testPurBoCodesRegistered() {
        String[] expectedBoCodes = {
                "PUR_APPLY", "PUR_CONT", "PUR_ORDER", "PUR_RECEIVE_NOTICE",
                "PUR_IN_STOCK", "PUR_RETURN", "PUR_INVOICE"
        };
        for (String boCode : expectedBoCodes) {
            Integer count = jdbcTemplate.queryForObject(
                    "SELECT COUNT(*) FROM meta_business_object WHERE bo_code = ?", Integer.class, boCode);
            assertEquals(1, count, "业务对象 " + boCode + " 应已注册");
        }
    }

    @Test
    @DisplayName("采购 bo_code 全部为 business 类型且有状态机")
    void testPurBoTypeAndStateful() {
        Integer nonBusinessCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM meta_business_object WHERE bo_code LIKE 'PUR_%' " +
                        "AND (bo_type != 'business' OR is_stateful != 1)", Integer.class);
        assertEquals(0, nonBusinessCount, "所有 PUR_ 前缀的 bo_code 应为 business 类型且 is_stateful=1");
    }

    @Test
    @DisplayName("采购 bo_code 总数为 7")
    void testPurBoCount() {
        Integer count = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM meta_business_object WHERE bo_code LIKE 'PUR_%'", Integer.class);
        assertEquals(7, count, "应注册 7 个采购业务对象");
    }

    // ==================== 状态机配置验证 ====================

    @Test
    @DisplayName("每个采购 bo_code 注册独立状态机（code=bo_code）")
    void testStateMachineRegistered() {
        String[] expectedBoCodes = {
                "PUR_APPLY", "PUR_CONT", "PUR_ORDER", "PUR_RECEIVE_NOTICE",
                "PUR_IN_STOCK", "PUR_RETURN", "PUR_INVOICE"
        };
        for (String boCode : expectedBoCodes) {
            Integer count = jdbcTemplate.queryForObject(
                    "SELECT COUNT(*) FROM meta_state_machine WHERE code = ?", Integer.class, boCode);
            assertEquals(1, count, "状态机 " + boCode + " 应已注册（code=bo_code）");
        }
    }

    @Test
    @DisplayName("每个采购状态机有 5 个节点")
    void testStateNodeCount() {
        String[] expectedBoCodes = {
                "PUR_APPLY", "PUR_CONT", "PUR_ORDER", "PUR_RECEIVE_NOTICE",
                "PUR_IN_STOCK", "PUR_RETURN", "PUR_INVOICE"
        };
        for (String boCode : expectedBoCodes) {
            Integer nodeCount = jdbcTemplate.queryForObject(
                    "SELECT COUNT(*) FROM meta_state_node n " +
                            "JOIN meta_state_machine m ON n.machine_id = m.id " +
                            "WHERE m.code = ?", Integer.class, boCode);
            assertEquals(5, nodeCount, "状态机 " + boCode + " 应有 5 个节点");
        }
    }

    @Test
    @DisplayName("每个采购状态机有 17 条流转")
    void testStateTransitionCount() {
        String[] expectedBoCodes = {
                "PUR_APPLY", "PUR_CONT", "PUR_ORDER", "PUR_RECEIVE_NOTICE",
                "PUR_IN_STOCK", "PUR_RETURN", "PUR_INVOICE"
        };
        for (String boCode : expectedBoCodes) {
            Integer transitionCount = jdbcTemplate.queryForObject(
                    "SELECT COUNT(*) FROM meta_state_transition t " +
                            "JOIN meta_state_machine m ON t.machine_id = m.id " +
                            "WHERE m.code = ?", Integer.class, boCode);
            assertEquals(17, transitionCount, "状态机 " + boCode + " 应有 17 条流转");
        }
    }

    @Test
    @DisplayName("状态机包含 save/submit/audit/reject/revoke/delete/close/cancel 关键按钮")
    void testKeyTransitionsExist() {
        String[] keyButtons = {"save", "submit", "audit", "reject", "revoke", "delete", "close", "cancel"};
        for (String boCode : new String[]{"PUR_ORDER", "PUR_APPLY"}) {
            for (String button : keyButtons) {
                Integer count = jdbcTemplate.queryForObject(
                        "SELECT COUNT(*) FROM meta_state_transition t " +
                                "JOIN meta_state_machine m ON t.machine_id = m.id " +
                                "WHERE m.code = ? AND t.button_code = ?", Integer.class, boCode, button);
                assertTrue(count >= 1, boCode + " 状态机应包含按钮 " + button);
            }
        }
    }

    // ==================== 实体层级验证 ====================

    @Test
    @DisplayName("采购实体注册数量正确（7 主 + 7 子 + 1 孙 = 15）")
    void testFormEntityCount() {
        Integer totalCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM meta_form_entity WHERE bo_code LIKE 'PUR_%'", Integer.class);
        assertEquals(15, totalCount, "应注册 15 个采购实体（7 主 + 7 子 + 1 孙）");

        Integer mainCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM meta_form_entity WHERE bo_code LIKE 'PUR_%' AND entity_type = 'main'",
                Integer.class);
        assertEquals(7, mainCount, "应注册 7 个主实体");

        Integer subCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM meta_form_entity WHERE bo_code LIKE 'PUR_%' AND entity_type = 'sub'",
                Integer.class);
        assertEquals(8, subCount, "应注册 8 个子/孙实体（7 子 + 1 孙）");
    }

    @Test
    @DisplayName("PUR_CONT 有 3 个实体（主表 + 明细 + 配额孙表）")
    void testPurContEntityHierarchy() {
        List<Map<String, Object>> entities = jdbcTemplate.queryForList(
                "SELECT entity_code, entity_type, entity_level, table_name, parent_entity_code, link_field " +
                        "FROM meta_form_entity WHERE bo_code = 'PUR_CONT' ORDER BY sort_index");
        assertEquals(3, entities.size(), "PUR_CONT 应有 3 个实体");

        // 主表
        Map<String, Object> main = entities.get(0);
        assertEquals("pur_cont", main.get("entity_code"));
        assertEquals("main", main.get("entity_type"));
        assertEquals(0, ((Number) main.get("entity_level")).intValue());

        // 子表
        Map<String, Object> sub = entities.get(1);
        assertEquals("goods", sub.get("entity_code"));
        assertEquals("sub", sub.get("entity_type"));
        assertEquals(1, ((Number) sub.get("entity_level")).intValue());
        assertEquals("cont_id", sub.get("link_field"));

        // 孙表
        Map<String, Object> grand = entities.get(2);
        assertEquals("assign", grand.get("entity_code"));
        assertEquals("sub", grand.get("entity_type"));
        assertEquals(2, ((Number) grand.get("entity_level")).intValue());
        assertEquals("goods", grand.get("parent_entity_code"));
        assertEquals("cont_goods_id", grand.get("link_field"));
    }

    // ==================== 字段元数据验证 ====================

    @Test
    @DisplayName("采购字段元数据已注册（>= 100 个）")
    void testFormFieldMetadataExists() {
        Integer fieldCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM meta_form_field WHERE bo_code LIKE 'PUR_%'", Integer.class);
        assertNotNull(fieldCount);
        assertTrue(fieldCount >= 100, "应至少注册 100 个字段元数据，实际: " + fieldCount);
    }

    @Test
    @DisplayName("PUR_ORDER 主表字段包含关键字段")
    void testPurOrderFieldsRegistered() {
        List<String> fieldCodes = jdbcTemplate.queryForList(
                "SELECT field_code FROM meta_form_field WHERE bo_code = 'PUR_ORDER' AND entity_code = 'pur_order'",
                String.class);
        assertTrue(fieldCodes.contains("code"), "PUR_ORDER 应包含 code 字段");
        assertTrue(fieldCodes.contains("supplier_id"), "PUR_ORDER 应包含 supplier_id 字段");
        assertTrue(fieldCodes.contains("total_amount"), "PUR_ORDER 应包含 total_amount 字段");
    }

    // ==================== 采购订单 CRUD 端到端验证 ====================

    @Test
    @DisplayName("采购订单 CRUD：保存 → 查询详情 → 状态流转")
    void testPurOrderCrud() throws Exception {
        // 1. 保存采购订单（save 操作：0 → 1 已创建）
        Map<String, Object> main = new HashMap<>();
        main.put("code", "TEST_PO_001");
        main.put("order_date", "2026-07-17");
        main.put("pact_state", 0);
        main.put("supplier_id", 1);
        main.put("pur_org_id", 1);
        main.put("curr_id", 1);
        main.put("total_qty", "100.00");
        main.put("total_amount", "10000.00");

        Map<String, Object> billData = new HashMap<>();
        billData.put("main", main);

        Long id = createBill("PUR_ORDER", billData);
        assertNotNull(id, "保存采购订单应返回 ID");

        // 2. 验证数据库中存在且状态为 1（save 流转后）
        Integer mainCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM pur_order WHERE id = ?", Integer.class, id);
        assertEquals(1, mainCount, "采购订单主表应存在");

        // 3. 查询详情
        Map<String, Object> detail = getBillDetail("PUR_ORDER", id);
        assertNotNull(detail, "详情不应为 null");
        Map<String, Object> mainData = (Map<String, Object>) detail.get("main");
        assertNotNull(mainData, "main 数据不应为 null");
        assertEquals("TEST_PO_001", mainData.get("code"), "编码应一致");

        // 4. 提交（submit 操作：1 → 2 已提交）
        operate("PUR_ORDER", id, "submit");

        // 5. 审核（audit 操作：2 → 3 已审核）
        operate("PUR_ORDER", id, "audit");

        // 6. 验证最终状态为 3（已审核）
        Integer state = jdbcTemplate.queryForObject(
                "SELECT pact_state FROM pur_order WHERE id = ?", Integer.class, id);
        assertEquals(3, state, "审核后 pact_state 应为 3");
    }

    // ==================== 含子表的采购订单保存 ====================

    @Test
    @DisplayName("含子表采购订单：保存主表 + 明细子表")
    void testPurOrderWithDetail() throws Exception {
        // 主表
        Map<String, Object> main = new HashMap<>();
        main.put("code", "TEST_PO_DETAIL_001");
        main.put("order_date", "2026-07-17");
        main.put("pact_state", 0);
        main.put("supplier_id", 1);
        main.put("pur_org_id", 1);
        main.put("curr_id", 1);
        main.put("total_qty", "200.00");
        main.put("total_amount", "20000.00");

        // 子表（entity_code='goods'）
        Map<String, Object> goods = new HashMap<>();
        goods.put("mat_id", 1);
        goods.put("qty", "200.00");
        goods.put("unit", "kg");
        goods.put("price", "100.00");
        goods.put("amount", "20000.00");

        Map<String, Object> subs = new HashMap<>();
        subs.put("goods", List.of(goods));

        Map<String, Object> billData = new HashMap<>();
        billData.put("main", main);
        billData.put("subs", subs);

        Long id = createBill("PUR_ORDER", billData);
        assertNotNull(id, "保存含子表采购订单应返回 ID");

        // 验证主表
        Integer mainCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM pur_order WHERE id = ?", Integer.class, id);
        assertEquals(1, mainCount, "采购订单主表应存在");

        // 验证子表（order_id 外键关联）
        Integer detailCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM pur_order_goods WHERE order_id = ?", Integer.class, id);
        assertTrue(detailCount >= 1, "采购订单明细应至少 1 条");
    }

    // ==================== 含孙表的采购合同保存 ====================

    @Test
    @DisplayName("含孙表采购合同：保存主表 + 明细子表 + 配额孙表")
    void testPurContWithGrandChild() throws Exception {
        // 主表
        Map<String, Object> main = new HashMap<>();
        main.put("code", "TEST_PC_001");
        main.put("pact_date", "2026-07-17");
        main.put("pact_state", 0);
        main.put("supplier_id", 1);
        main.put("pur_org_id", 1);
        main.put("curr_id", 1);
        main.put("total_qty", "500.00");
        main.put("total_amount", "50000.00");

        // 孙表行（配额，entity_code='assign', link_field='cont_goods_id'）
        Map<String, Object> assign = new HashMap<>();
        assign.put("mat_id", 1);
        assign.put("qty", "100.00");
        assign.put("price", "100.00");

        // 子表行（明细，entity_code='goods', link_field='cont_id'）
        Map<String, Object> goods = new HashMap<>();
        goods.put("mat_id", 1);
        goods.put("qty", "500.00");
        goods.put("unit", "kg");
        goods.put("price", "100.00");
        goods.put("amount", "50000.00");
        // 嵌套孙表：子表行中包含 assign 列表（层级嵌套）
        goods.put("assign", List.of(assign));

        Map<String, Object> subs = new HashMap<>();
        subs.put("goods", List.of(goods));

        Map<String, Object> billData = new HashMap<>();
        billData.put("main", main);
        billData.put("subs", subs);

        Long id = createBill("PUR_CONT", billData);
        assertNotNull(id, "保存含孙表采购合同应返回 ID");

        // 验证主表
        Integer mainCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM pur_cont WHERE id = ?", Integer.class, id);
        assertEquals(1, mainCount, "采购合同主表应存在");

        // 验证子表
        Integer goodsCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM pur_cont_goods WHERE cont_id = ?", Integer.class, id);
        assertTrue(goodsCount >= 1, "采购合同明细应至少 1 条");

        // 验证孙表（通过子表 ID 关联）
        Long contGoodsId = jdbcTemplate.queryForObject(
                "SELECT id FROM pur_cont_goods WHERE cont_id = ? LIMIT 1", Long.class, id);
        Integer assignCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM pur_cont_goods_assign WHERE cont_goods_id = ?", Integer.class, contGoodsId);
        assertTrue(assignCount >= 1, "采购合同配额孙表应至少 1 条");
    }

    // ==================== 采购退料 CRUD（验证多单据类型） ====================

    @Test
    @DisplayName("采购退料 CRUD：保存 → 验证状态机流转")
    void testPurReturnCrud() throws Exception {
        Map<String, Object> main = new HashMap<>();
        main.put("code", "TEST_PR_001");
        main.put("return_date", "2026-07-17");
        main.put("pact_state", 0);
        main.put("supplier_id", 1);
        main.put("pur_org_id", 1);
        main.put("warehouse_id", 1);
        main.put("total_qty", "50.00");
        main.put("total_amount", "5000.00");

        Map<String, Object> billData = new HashMap<>();
        billData.put("main", main);

        Long id = createBill("PUR_RETURN", billData);
        assertNotNull(id, "保存采购退料应返回 ID");

        // 状态流转：submit → audit
        operate("PUR_RETURN", id, "submit");
        operate("PUR_RETURN", id, "audit");

        Integer state = jdbcTemplate.queryForObject(
                "SELECT pact_state FROM pur_return WHERE id = ?", Integer.class, id);
        assertEquals(3, state, "采购退料审核后 pact_state 应为 3");
    }

    // ==================== 采购入库含子表验证 ====================

    @Test
    @DisplayName("采购入库：保存主表 + 明细子表")
    void testPurInStockWithDetail() throws Exception {
        Map<String, Object> main = new HashMap<>();
        main.put("code", "TEST_PIS_001");
        main.put("in_date", "2026-07-17");
        main.put("pact_state", 0);
        main.put("supplier_id", 1);
        main.put("pur_org_id", 1);
        main.put("warehouse_id", 1);
        main.put("curr_id", 1);
        main.put("total_qty", "300.00");
        main.put("total_amount", "30000.00");

        Map<String, Object> goods = new HashMap<>();
        goods.put("mat_id", 1);
        goods.put("lot_no", "LOT001");
        goods.put("qty", "300.00");
        goods.put("unit", "kg");
        goods.put("price", "100.00");
        goods.put("amount", "30000.00");

        Map<String, Object> subs = new HashMap<>();
        subs.put("goods", List.of(goods));

        Map<String, Object> billData = new HashMap<>();
        billData.put("main", main);
        billData.put("subs", subs);

        Long id = createBill("PUR_IN_STOCK", billData);
        assertNotNull(id, "保存采购入库应返回 ID");

        Integer detailCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM pur_in_stock_goods WHERE in_stock_id = ?", Integer.class, id);
        assertTrue(detailCount >= 1, "采购入库明细应至少 1 条");
    }

    // ==================== 删除操作验证 ====================

    @Test
    @DisplayName("采购订单删除：暂存状态可删除")
    void testPurOrderDelete() throws Exception {
        Map<String, Object> main = new HashMap<>();
        main.put("code", "TEST_PO_DEL_001");
        main.put("order_date", "2026-07-17");
        main.put("pact_state", 0);
        main.put("supplier_id", 1);

        Map<String, Object> billData = new HashMap<>();
        billData.put("main", main);

        Long id = createBill("PUR_ORDER", billData);

        // 删除（delete 操作：0 → -1 物理删除）
        operate("PUR_ORDER", id, "delete");

        Integer count = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM pur_order WHERE id = ?", Integer.class, id);
        assertEquals(0, count, "删除后记录不应存在");
    }

    // ==================== 关闭/取消操作验证 ====================

    @Test
    @DisplayName("采购订单关闭/取消：审核后可关闭和取消")
    void testPurOrderCloseAndCancel() throws Exception {
        Map<String, Object> main = new HashMap<>();
        main.put("code", "TEST_PO_CLOSE_001");
        main.put("order_date", "2026-07-17");
        main.put("pact_state", 0);
        main.put("supplier_id", 1);

        Map<String, Object> billData = new HashMap<>();
        billData.put("main", main);

        Long id = createBill("PUR_ORDER", billData);

        // 状态流转到已审核
        operate("PUR_ORDER", id, "submit");
        operate("PUR_ORDER", id, "audit");

        // 关闭（close：post_action='is_closed=1'）
        operate("PUR_ORDER", id, "close");
        Integer isClosed = jdbcTemplate.queryForObject(
                "SELECT is_closed FROM pur_order WHERE id = ?", Integer.class, id);
        assertEquals(1, isClosed, "关闭后 is_closed 应为 1");

        // 取消（cancel：post_action='is_cancel=1'，require_reason=1）
        operate("PUR_ORDER", id, "cancel", "测试取消原因");
        Integer isCancel = jdbcTemplate.queryForObject(
                "SELECT is_cancel FROM pur_order WHERE id = ?", Integer.class, id);
        assertEquals(1, isCancel, "取消后 is_cancel 应为 1");
    }
}
