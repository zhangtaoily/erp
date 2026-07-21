package com.eerp.test.sal;

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
 * 销售管理模块集成测试（Phase 2b，对齐设计文档 02-CRM销售表）。
 *
 * <p>验证 11 个销售/打样业务单据的元数据注册、状态机配置、CRUD 端到端流程、
 * 含子表/孙表的主数据保存、状态流转（save → submit → audit）。</p>
 *
 * <p>测试范围：</p>
 * <ul>
 *   <li>11 个 bo_code（9 个 SAL_ + 2 个 PP_）在 meta_business_object 中正确注册</li>
 *   <li>每个 bo_code 独立状态机（5 节点 + 17 流转，code=bo_code）</li>
 *   <li>meta_form_entity 实体层级（11 主 + 11 子 + 7 孙 = 29）</li>
 *   <li>meta_form_field 字段元数据（270 个关键字段）</li>
 *   <li>销售订单 CRUD：保存 → 查询详情 → 状态流转</li>
 *   <li>含子表保存：销售订单主表 + 明细子表</li>
 *   <li>含孙表保存：销售合同主表 + 明细子表 + 配额孙表</li>
 *   <li>销售退货 CRUD、销售出库含子表</li>
 *   <li>删除操作、关闭/取消操作</li>
 * </ul>
 */
@SpringBootTest(classes = EerpTestApplication.class)
@ActiveProfiles("test")
@AutoConfigureMockMvc
class SalIntegrationTest extends AbstractIntegrationTest {

    private static final String[] EXPECTED_BO_CODES = {
            "SAL_INT_CONT", "SAL_QUOTE", "SAL_CONTRACT", "SAL_ORDER",
            "SAL_DELIVERY_NOTICE", "SAL_OUT_STOCK", "SAL_RETURN",
            "SAL_RETURN_NOTICE", "SAL_INVOICE", "PP_NOTICE", "PP_RECORD"
    };

    // ==================== 元数据注册验证 ====================

    @Test
    @DisplayName("11 个销售/打样 bo_code 在 meta_business_object 中注册")
    void testSalBoCodesRegistered() {
        for (String boCode : EXPECTED_BO_CODES) {
            Integer count = jdbcTemplate.queryForObject(
                    "SELECT COUNT(*) FROM meta_business_object WHERE bo_code = ?", Integer.class, boCode);
            assertEquals(1, count, "业务对象 " + boCode + " 应已注册");
        }
    }

    @Test
    @DisplayName("销售/打样 bo_code 全部为 business 类型且有状态机")
    void testSalBoTypeAndStateful() {
        Integer nonBusinessCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM meta_business_object " +
                        "WHERE (bo_code LIKE 'SAL_%' OR bo_code LIKE 'PP_%') " +
                        "AND (bo_type != 'business' OR is_stateful != 1)", Integer.class);
        assertEquals(0, nonBusinessCount, "所有 SAL_/PP_ 前缀的 bo_code 应为 business 类型且 is_stateful=1");
    }

    @Test
    @DisplayName("销售/打样 bo_code 总数为 11")
    void testSalBoCount() {
        Integer count = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM meta_business_object " +
                        "WHERE bo_code LIKE 'SAL_%' OR bo_code LIKE 'PP_%'", Integer.class);
        assertEquals(11, count, "应注册 11 个销售/打样业务对象");
    }

    // ==================== 状态机配置验证 ====================

    @Test
    @DisplayName("每个销售/打样 bo_code 注册独立状态机（code=bo_code）")
    void testStateMachineRegistered() {
        for (String boCode : EXPECTED_BO_CODES) {
            Integer count = jdbcTemplate.queryForObject(
                    "SELECT COUNT(*) FROM meta_state_machine WHERE code = ?", Integer.class, boCode);
            assertEquals(1, count, "状态机 " + boCode + " 应已注册（code=bo_code）");
        }
    }

    @Test
    @DisplayName("每个销售/打样状态机有 5 个节点")
    void testStateNodeCount() {
        for (String boCode : EXPECTED_BO_CODES) {
            Integer nodeCount = jdbcTemplate.queryForObject(
                    "SELECT COUNT(*) FROM meta_state_node n " +
                            "JOIN meta_state_machine m ON n.machine_id = m.id " +
                            "WHERE m.code = ?", Integer.class, boCode);
            assertEquals(5, nodeCount, "状态机 " + boCode + " 应有 5 个节点");
        }
    }

    @Test
    @DisplayName("每个销售/打样状态机有 17 条流转")
    void testStateTransitionCount() {
        for (String boCode : EXPECTED_BO_CODES) {
            Integer transitionCount = jdbcTemplate.queryForObject(
                    "SELECT COUNT(*) FROM meta_state_transition t " +
                            "JOIN meta_state_machine m ON t.machine_id = m.id " +
                            "WHERE m.code = ?", Integer.class, boCode);
            assertEquals(17, transitionCount, "状态机 " + boCode + " 应有 17 条流转");
        }
    }

    // ==================== 实体层级验证 ====================

    @Test
    @DisplayName("销售实体注册数量正确（11 主 + 18 子/孙 = 29）")
    void testFormEntityCount() {
        Integer totalCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM meta_form_entity " +
                        "WHERE bo_code LIKE 'SAL_%' OR bo_code LIKE 'PP_%'", Integer.class);
        assertEquals(29, totalCount, "应注册 29 个销售/打样实体（11 主 + 11 子 + 7 孙）");

        Integer mainCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM meta_form_entity " +
                        "WHERE (bo_code LIKE 'SAL_%' OR bo_code LIKE 'PP_%') AND entity_type = 'main'",
                Integer.class);
        assertEquals(11, mainCount, "应注册 11 个主实体");

        Integer subCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM meta_form_entity " +
                        "WHERE (bo_code LIKE 'SAL_%' OR bo_code LIKE 'PP_%') AND entity_type = 'sub'",
                Integer.class);
        assertEquals(11, subCount, "应注册 11 个子实体（孙表 entity_type=grandchild 不计入）");

        Integer grandCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM meta_form_entity " +
                        "WHERE (bo_code LIKE 'SAL_%' OR bo_code LIKE 'PP_%') AND entity_type = 'grandchild'",
                Integer.class);
        assertEquals(7, grandCount, "应注册 7 个孙实体（SAL_INT_CONT 2 + SAL_CONTRACT 2 + SAL_ORDER 3）");
    }

    @Test
    @DisplayName("SAL_ORDER 有 5 个实体（主表 + 明细 + 3 孙表：craft/assign/pack）")
    void testSalOrderEntityHierarchy() {
        List<Map<String, Object>> entities = jdbcTemplate.queryForList(
                "SELECT entity_code, entity_type, entity_level, table_name, parent_entity_code, link_field " +
                        "FROM meta_form_entity WHERE bo_code = 'SAL_ORDER' ORDER BY sort_index, entity_code");
        assertEquals(5, entities.size(), "SAL_ORDER 应有 5 个实体");

        // 主表
        Map<String, Object> main = entities.get(0);
        assertEquals("sal_order", main.get("entity_code"));
        assertEquals("main", main.get("entity_type"));
        assertEquals(0, ((Number) main.get("entity_level")).intValue());

        // 子表
        Map<String, Object> sub = entities.get(1);
        assertEquals("goods", sub.get("entity_code"));
        assertEquals("sub", sub.get("entity_type"));
        assertEquals(1, ((Number) sub.get("entity_level")).intValue());
        assertEquals("order_id", sub.get("link_field"));

        // 孙表：assign / craft / pack（按 entity_code 字母序）
        Map<String, Object> assign = entities.get(2);
        assertEquals("assign", assign.get("entity_code"));
        assertEquals("grandchild", assign.get("entity_type"));
        assertEquals("sal_order_goods_assign", assign.get("table_name"));

        Map<String, Object> craft = entities.get(3);
        assertEquals("craft", craft.get("entity_code"));
        assertEquals("grandchild", craft.get("entity_type"));
        assertEquals("sal_order_goods_craft", craft.get("table_name"));

        Map<String, Object> pack = entities.get(4);
        assertEquals("pack", pack.get("entity_code"));
        assertEquals("grandchild", pack.get("entity_type"));
        assertEquals("sal_order_goods_pack", pack.get("table_name"));
    }

    @Test
    @DisplayName("SAL_INT_CONT 有 4 个实体（主表 + 明细 + 2 孙表：assign/craft）")
    void testSalIntContEntityHierarchy() {
        List<Map<String, Object>> entities = jdbcTemplate.queryForList(
                "SELECT entity_code, entity_type, entity_level, table_name, parent_entity_code, link_field " +
                        "FROM meta_form_entity WHERE bo_code = 'SAL_INT_CONT' ORDER BY sort_index, entity_code");
        assertEquals(4, entities.size(), "SAL_INT_CONT 应有 4 个实体");

        // 主表
        assertEquals("sal_int_cont", entities.get(0).get("entity_code"));
        assertEquals("main", entities.get(0).get("entity_type"));

        // 子表
        assertEquals("goods", entities.get(1).get("entity_code"));
        assertEquals("sub", entities.get(1).get("entity_type"));

        // 孙表 assign（指定用料）
        Map<String, Object> assign = entities.get(2);
        assertEquals("assign", assign.get("entity_code"));
        assertEquals("grandchild", assign.get("entity_type"));
        assertEquals("sal_int_cont_goods_assign", assign.get("table_name"));

        // 孙表 craft（特殊工艺）
        Map<String, Object> craft = entities.get(3);
        assertEquals("craft", craft.get("entity_code"));
        assertEquals("grandchild", craft.get("entity_type"));
        assertEquals("sal_int_cont_goods_craft", craft.get("table_name"));
    }

    @Test
    @DisplayName("SAL_CONTRACT 有 4 个实体（主表 + 明细 + 2 孙表：assign/craft）")
    void testSalContractEntityHierarchy() {
        List<Map<String, Object>> entities = jdbcTemplate.queryForList(
                "SELECT entity_code, entity_type, entity_level, table_name, parent_entity_code, link_field " +
                        "FROM meta_form_entity WHERE bo_code = 'SAL_CONTRACT' ORDER BY sort_index, entity_code");
        assertEquals(4, entities.size(), "SAL_CONTRACT 应有 4 个实体");

        // 主表
        assertEquals("sal_cont", entities.get(0).get("entity_code"));
        assertEquals("main", entities.get(0).get("entity_type"));

        // 子表
        assertEquals("goods", entities.get(1).get("entity_code"));
        assertEquals("sub", entities.get(1).get("entity_type"));

        // 孙表 assign（指定用料）
        Map<String, Object> assign = entities.get(2);
        assertEquals("assign", assign.get("entity_code"));
        assertEquals("grandchild", assign.get("entity_type"));
        assertEquals("sal_cont_goods_assign", assign.get("table_name"));

        // 孙表 craft（特殊工艺）
        Map<String, Object> craft = entities.get(3);
        assertEquals("craft", craft.get("entity_code"));
        assertEquals("grandchild", craft.get("entity_type"));
        assertEquals("sal_cont_goods_craft", craft.get("table_name"));
    }

    // ==================== 字段元数据验证 ====================

    @Test
    @DisplayName("销售/打样字段元数据已注册（>= 250 个）")
    void testFormFieldMetadataExists() {
        Integer fieldCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM meta_form_field " +
                        "WHERE bo_code LIKE 'SAL_%' OR bo_code LIKE 'PP_%'", Integer.class);
        assertNotNull(fieldCount);
        assertTrue(fieldCount >= 250, "应至少注册 250 个字段元数据，实际: " + fieldCount);
    }

    @Test
    @DisplayName("SAL_ORDER 主表字段包含关键字段")
    void testSalOrderFieldsRegistered() {
        List<String> fieldCodes = jdbcTemplate.queryForList(
                "SELECT field_code FROM meta_form_field WHERE bo_code = 'SAL_ORDER' AND entity_code = 'sal_order'",
                String.class);
        assertTrue(fieldCodes.contains("code"), "SAL_ORDER 应包含 code 字段");
        assertTrue(fieldCodes.contains("cust_id"), "SAL_ORDER 应包含 cust_id 字段");
        assertTrue(fieldCodes.contains("total_amount"), "SAL_ORDER 应包含 total_amount 字段");
    }

    // ==================== 销售订单 CRUD 端到端验证 ====================

    @Test
    @DisplayName("销售订单 CRUD：保存 → 查询详情 → 状态流转")
    void testSalOrderCrud() throws Exception {
        // 1. 保存销售订单（save 操作：0 → 1 已创建）
        Map<String, Object> main = new HashMap<>();
        main.put("code", "TEST_SO_001");
        main.put("order_date", "2026-07-17");
        main.put("pact_state", 0);
        main.put("cust_id", 1);
        main.put("sal_org_id", 1);
        main.put("curr_id", 1);
        main.put("total_qty", "100.00");
        main.put("total_amount", "10000.00");

        Map<String, Object> billData = new HashMap<>();
        billData.put("main", main);

        Long id = createBill("SAL_ORDER", billData);
        assertNotNull(id, "保存销售订单应返回 ID");

        // 2. 验证数据库中存在
        Integer mainCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM sal_order WHERE id = ?", Integer.class, id);
        assertEquals(1, mainCount, "销售订单主表应存在");

        // 3. 查询详情
        Map<String, Object> detail = getBillDetail("SAL_ORDER", id);
        assertNotNull(detail, "详情不应为 null");
        Map<String, Object> mainData = (Map<String, Object>) detail.get("main");
        assertNotNull(mainData, "main 数据不应为 null");
        assertEquals("TEST_SO_001", mainData.get("code"), "编码应一致");

        // 4. 提交（submit 操作：1 → 2 已提交）
        operate("SAL_ORDER", id, "submit");

        // 5. 审核（audit 操作：2 → 3 已审核）
        operate("SAL_ORDER", id, "audit");

        // 6. 验证最终状态为 3（已审核）
        Integer state = jdbcTemplate.queryForObject(
                "SELECT pact_state FROM sal_order WHERE id = ?", Integer.class, id);
        assertEquals(3, state, "审核后 pact_state 应为 3");
    }

    // ==================== 含子表的销售订单保存 ====================

    @Test
    @DisplayName("含子表销售订单：保存主表 + 明细子表")
    void testSalOrderWithDetail() throws Exception {
        // 主表
        Map<String, Object> main = new HashMap<>();
        main.put("code", "TEST_SO_DETAIL_001");
        main.put("order_date", "2026-07-17");
        main.put("pact_state", 0);
        main.put("cust_id", 1);
        main.put("sal_org_id", 1);
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

        Long id = createBill("SAL_ORDER", billData);
        assertNotNull(id, "保存含子表销售订单应返回 ID");

        // 验证主表
        Integer mainCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM sal_order WHERE id = ?", Integer.class, id);
        assertEquals(1, mainCount, "销售订单主表应存在");

        // 验证子表（order_id 外键关联）
        Integer detailCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM sal_order_goods WHERE order_id = ?", Integer.class, id);
        assertTrue(detailCount >= 1, "销售订单明细应至少 1 条");
    }

    // ==================== 含孙表的销售合同保存 ====================

    @Test
    @DisplayName("含孙表销售合同：保存主表 + 明细子表 + 配额孙表")
    void testSalContractWithGrandChild() throws Exception {
        // 主表
        Map<String, Object> main = new HashMap<>();
        main.put("code", "TEST_SC_001");
        main.put("pact_date", "2026-07-17");
        main.put("pact_state", 0);
        main.put("cust_id", 1);
        main.put("sal_org_id", 1);
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

        Long id = createBill("SAL_CONTRACT", billData);
        assertNotNull(id, "保存含孙表销售合同应返回 ID");

        // 验证主表
        Integer mainCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM sal_cont WHERE id = ?", Integer.class, id);
        assertEquals(1, mainCount, "销售合同主表应存在");

        // 验证子表
        Integer goodsCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM sal_cont_goods WHERE cont_id = ?", Integer.class, id);
        assertTrue(goodsCount >= 1, "销售合同明细应至少 1 条");

        // 验证孙表（通过子表 ID 关联）
        Long contGoodsId = jdbcTemplate.queryForObject(
                "SELECT id FROM sal_cont_goods WHERE cont_id = ? LIMIT 1", Long.class, id);
        Integer assignCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM sal_cont_goods_assign WHERE cont_goods_id = ?", Integer.class, contGoodsId);
        assertTrue(assignCount >= 1, "销售合同配额孙表应至少 1 条");
    }

    // ==================== 销售退货 CRUD（验证多单据类型） ====================

    @Test
    @DisplayName("销售退货 CRUD：保存 → 验证状态机流转")
    void testSalReturnCrud() throws Exception {
        Map<String, Object> main = new HashMap<>();
        main.put("code", "TEST_SR_001");
        main.put("return_date", "2026-07-17");
        main.put("pact_state", 0);
        main.put("cust_id", 1);
        main.put("sal_org_id", 1);
        main.put("warehouse_id", 1);
        main.put("curr_id", 1);
        main.put("total_qty", "50.00");
        main.put("total_amount", "5000.00");

        Map<String, Object> billData = new HashMap<>();
        billData.put("main", main);

        Long id = createBill("SAL_RETURN", billData);
        assertNotNull(id, "保存销售退货应返回 ID");

        // 状态流转：submit → audit
        operate("SAL_RETURN", id, "submit");
        operate("SAL_RETURN", id, "audit");

        Integer state = jdbcTemplate.queryForObject(
                "SELECT pact_state FROM sal_return WHERE id = ?", Integer.class, id);
        assertEquals(3, state, "销售退货审核后 pact_state 应为 3");
    }

    // ==================== 销售出库含子表验证 ====================

    @Test
    @DisplayName("销售出库：保存主表 + 明细子表")
    void testSalOutStockWithDetail() throws Exception {
        Map<String, Object> main = new HashMap<>();
        main.put("code", "TEST_OS_001");
        main.put("out_date", "2026-07-17");
        main.put("pact_state", 0);
        main.put("cust_id", 1);
        main.put("sal_org_id", 1);
        main.put("warehouse_id", 1);
        main.put("curr_id", 1);
        main.put("total_qty", "300.00");
        main.put("total_amount", "30000.00");

        Map<String, Object> goods = new HashMap<>();
        goods.put("mat_id", 1);
        goods.put("qty", "300.00");
        goods.put("unit", "kg");
        goods.put("price", "100.00");
        goods.put("amount", "30000.00");

        Map<String, Object> subs = new HashMap<>();
        subs.put("goods", List.of(goods));

        Map<String, Object> billData = new HashMap<>();
        billData.put("main", main);
        billData.put("subs", subs);

        Long id = createBill("SAL_OUT_STOCK", billData);
        assertNotNull(id, "保存销售出库应返回 ID");

        Integer detailCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM sal_out_stock_goods WHERE out_stock_id = ?", Integer.class, id);
        assertTrue(detailCount >= 1, "销售出库明细应至少 1 条");
    }

    // ==================== 删除操作验证 ====================

    @Test
    @DisplayName("销售订单删除：已创建状态可删除")
    void testSalOrderDelete() throws Exception {
        Map<String, Object> main = new HashMap<>();
        main.put("code", "TEST_SO_DEL_001");
        main.put("order_date", "2026-07-17");
        main.put("pact_state", 0);
        main.put("cust_id", 1);

        Map<String, Object> billData = new HashMap<>();
        billData.put("main", main);

        Long id = createBill("SAL_ORDER", billData);

        // 删除（delete 操作：1 → -1 物理删除）
        operate("SAL_ORDER", id, "delete");

        Integer count = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM sal_order WHERE id = ?", Integer.class, id);
        assertEquals(0, count, "删除后记录不应存在");
    }

    // ==================== 关闭/取消操作验证 ====================

    @Test
    @DisplayName("销售订单关闭/取消：审核后可关闭和取消")
    void testSalOrderCloseAndCancel() throws Exception {
        Map<String, Object> main = new HashMap<>();
        main.put("code", "TEST_SO_CLOSE_001");
        main.put("order_date", "2026-07-17");
        main.put("pact_state", 0);
        main.put("cust_id", 1);

        Map<String, Object> billData = new HashMap<>();
        billData.put("main", main);

        Long id = createBill("SAL_ORDER", billData);

        // 状态流转到已审核
        operate("SAL_ORDER", id, "submit");
        operate("SAL_ORDER", id, "audit");

        // 关闭（close：post_action='is_closed=1'）
        operate("SAL_ORDER", id, "close");
        Integer isClosed = jdbcTemplate.queryForObject(
                "SELECT is_closed FROM sal_order WHERE id = ?", Integer.class, id);
        assertEquals(1, isClosed, "关闭后 is_closed 应为 1");

        // 取消（cancel：post_action='is_cancel=1'，require_reason=1）
        operate("SAL_ORDER", id, "cancel", "测试取消原因");
        Integer isCancel = jdbcTemplate.queryForObject(
                "SELECT is_cancel FROM sal_order WHERE id = ?", Integer.class, id);
        assertEquals(1, isCancel, "取消后 is_cancel 应为 1");
    }
}
