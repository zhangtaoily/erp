package com.eerp.test.mfg;

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
 * 生产制造模块集成测试（Phase 2e-2g，对齐设计文档 03）。
 *
 * <p>验证 8 个生产制造业务单据的元数据注册、状态机配置、CRUD 端到端流程、
 * 含子表/孙表的主数据保存、状态流转（save → submit → audit）。</p>
 *
 * <p>测试范围：</p>
 * <ul>
 *   <li>8 个生产制造 bo_code 在 meta_business_object 中正确注册（bo_type='business', is_stateful=1）</li>
 *   <li>每个 bo_code 独立状态机（5 节点 + 17 流转，code=bo_code）</li>
 *   <li>meta_form_entity 实体层级（8 主 + 8 子 + 1 孙 = 17）</li>
 *   <li>meta_form_field 字段元数据（158 个关键字段）</li>
 *   <li>生产订单 CRUD：保存 → 查询详情 → 状态流转</li>
 *   <li>含子表保存：生产订单主表 + 投料明细子表</li>
 *   <li>含孙表保存：BOM 主表 + 原料明细子表 + 替代料孙表</li>
 *   <li>删除/关闭/取消操作（post_action 验证）</li>
 * </ul>
 */
@SpringBootTest(classes = EerpTestApplication.class)
@ActiveProfiles("test")
@AutoConfigureMockMvc
class MfgIntegrationTest extends AbstractIntegrationTest {

    private static final String[] EXPECTED_BO_CODES = {
            "MFG_BOM", "MFG_ROUTE", "MFG_NOTICE", "MFG_ORDER",
            "MFG_PICK", "MFG_IN_STOCK", "MFG_MRP_PLAN", "MFG_OUTSOURCE"
    };

    // ==================== 元数据注册验证 ====================

    @Test
    @DisplayName("8 个生产制造 bo_code 在 meta_business_object 中注册")
    void testMfgBoCodesRegistered() {
        for (String boCode : EXPECTED_BO_CODES) {
            Integer count = jdbcTemplate.queryForObject(
                    "SELECT COUNT(*) FROM meta_business_object WHERE bo_code = ?", Integer.class, boCode);
            assertEquals(1, count, "业务对象 " + boCode + " 应已注册");
        }
    }

    @Test
    @DisplayName("生产制造 bo_code 全部为 business 类型且有状态机")
    void testMfgBoTypeAndStateful() {
        Integer nonBusinessCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM meta_business_object WHERE bo_code LIKE 'MFG_%' " +
                        "AND (bo_type != 'business' OR is_stateful != 1)", Integer.class);
        assertEquals(0, nonBusinessCount, "所有 MFG_ 前缀的 bo_code 应为 business 类型且 is_stateful=1");
    }

    @Test
    @DisplayName("生产制造 bo_code 总数为 8")
    void testMfgBoCount() {
        Integer count = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM meta_business_object WHERE bo_code LIKE 'MFG_%'", Integer.class);
        assertEquals(8, count, "应注册 8 个生产制造业务对象");
    }

    // ==================== 状态机配置验证 ====================

    @Test
    @DisplayName("每个生产制造 bo_code 注册独立状态机（code=bo_code）")
    void testStateMachineRegistered() {
        for (String boCode : EXPECTED_BO_CODES) {
            Integer count = jdbcTemplate.queryForObject(
                    "SELECT COUNT(*) FROM meta_state_machine WHERE code = ?", Integer.class, boCode);
            assertEquals(1, count, "状态机 " + boCode + " 应已注册（code=bo_code）");
        }
    }

    @Test
    @DisplayName("每个生产制造状态机有 5 个节点")
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
    @DisplayName("每个生产制造状态机有 17 条流转")
    void testStateTransitionCount() {
        for (String boCode : EXPECTED_BO_CODES) {
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
        for (String boCode : new String[]{"MFG_ORDER", "MFG_BOM"}) {
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
    @DisplayName("生产制造实体注册数量正确（8 主 + 8 子 + 1 孙 = 17）")
    void testFormEntityCount() {
        Integer totalCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM meta_form_entity WHERE bo_code LIKE 'MFG_%'", Integer.class);
        assertEquals(17, totalCount, "应注册 17 个生产制造实体（8 主 + 8 子 + 1 孙）");

        Integer mainCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM meta_form_entity WHERE bo_code LIKE 'MFG_%' AND entity_type = 'main'",
                Integer.class);
        assertEquals(8, mainCount, "应注册 8 个主实体");

        Integer subCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM meta_form_entity WHERE bo_code LIKE 'MFG_%' AND entity_type = 'sub'",
                Integer.class);
        assertEquals(8, subCount, "应注册 8 个子实体（孙表 entity_type=grandchild 不计入）");
    }

    @Test
    @DisplayName("MFG_BOM 有 3 个实体（主表 + 原料明细 + 替代料孙表）")
    void testMfgBomEntityHierarchy() {
        List<Map<String, Object>> entities = jdbcTemplate.queryForList(
                "SELECT entity_code, entity_type, entity_level, table_name, parent_entity_code, link_field " +
                        "FROM meta_form_entity WHERE bo_code = 'MFG_BOM' ORDER BY sort_index");
        assertEquals(3, entities.size(), "MFG_BOM 应有 3 个实体");

        // 主表
        Map<String, Object> main = entities.get(0);
        assertEquals("mfg_bom", main.get("entity_code"));
        assertEquals("main", main.get("entity_type"));
        assertEquals(0, ((Number) main.get("entity_level")).intValue());

        // 子表
        Map<String, Object> sub = entities.get(1);
        assertEquals("material", sub.get("entity_code"));
        assertEquals("sub", sub.get("entity_type"));
        assertEquals(1, ((Number) sub.get("entity_level")).intValue());
        assertEquals("bom_id", sub.get("link_field"));

        // 孙表
        Map<String, Object> grand = entities.get(2);
        assertEquals("sub", grand.get("entity_code"));
        assertEquals("grandchild", grand.get("entity_type"));
        assertEquals(2, ((Number) grand.get("entity_level")).intValue());
        assertEquals("material", grand.get("parent_entity_code"));
        assertEquals("bom_material_id", grand.get("link_field"));
    }

    // ==================== 字段元数据验证 ====================

    @Test
    @DisplayName("生产制造字段元数据已注册（>= 150 个）")
    void testFormFieldMetadataExists() {
        Integer fieldCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM meta_form_field WHERE bo_code LIKE 'MFG_%'", Integer.class);
        assertNotNull(fieldCount);
        assertTrue(fieldCount >= 150, "应至少注册 150 个字段元数据，实际: " + fieldCount);
    }

    @Test
    @DisplayName("MFG_ORDER 主表字段包含关键字段")
    void testMfgOrderFieldsRegistered() {
        List<String> fieldCodes = jdbcTemplate.queryForList(
                "SELECT field_code FROM meta_form_field WHERE bo_code = 'MFG_ORDER' AND entity_code = 'mfg_order'",
                String.class);
        assertTrue(fieldCodes.contains("code"), "MFG_ORDER 应包含 code 字段");
        assertTrue(fieldCodes.contains("mat_id"), "MFG_ORDER 应包含 mat_id 字段");
        assertTrue(fieldCodes.contains("plan_qty"), "MFG_ORDER 应包含 plan_qty 字段");
        assertTrue(fieldCodes.contains("bom_id"), "MFG_ORDER 应包含 bom_id 字段");
    }

    // ==================== 生产订单 CRUD 端到端验证 ====================

    @Test
    @DisplayName("生产订单 CRUD：保存 → 查询详情 → 状态流转")
    void testMfgOrderCrud() throws Exception {
        // 1. 保存生产订单（save 操作：0 → 1 已创建）
        Map<String, Object> main = new HashMap<>();
        main.put("code", "TEST_MO_001");
        main.put("order_date", "2026-07-17");
        main.put("pact_state", 0);
        main.put("org_id", 1);
        main.put("mat_id", 1);
        main.put("plan_qty", "1000.00");
        main.put("unit", "kg");
        main.put("plan_start", "2026-07-18");
        main.put("plan_end", "2026-07-25");

        Map<String, Object> billData = new HashMap<>();
        billData.put("main", main);

        Long id = createBill("MFG_ORDER", billData);
        assertNotNull(id, "保存生产订单应返回 ID");

        // 2. 验证数据库中存在
        Integer mainCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM mfg_order WHERE id = ?", Integer.class, id);
        assertEquals(1, mainCount, "生产订单主表应存在");

        // 3. 查询详情
        Map<String, Object> detail = getBillDetail("MFG_ORDER", id);
        assertNotNull(detail, "详情不应为 null");
        Map<String, Object> mainData = (Map<String, Object>) detail.get("main");
        assertNotNull(mainData, "main 数据不应为 null");
        assertEquals("TEST_MO_001", mainData.get("code"), "编码应一致");

        // 4. 提交（submit 操作：1 → 2 已提交）
        operate("MFG_ORDER", id, "submit");

        // 5. 审核（audit 操作：2 → 3 已审核）
        operate("MFG_ORDER", id, "audit");

        // 6. 验证最终状态为 3（已审核）
        Integer state = jdbcTemplate.queryForObject(
                "SELECT pact_state FROM mfg_order WHERE id = ?", Integer.class, id);
        assertEquals(3, state, "审核后 pact_state 应为 3");
    }

    // ==================== 含子表的生产订单保存 ====================

    @Test
    @DisplayName("含子表生产订单：保存主表 + 投料明细子表")
    void testMfgOrderWithDetail() throws Exception {
        // 主表
        Map<String, Object> main = new HashMap<>();
        main.put("code", "TEST_MO_DETAIL_001");
        main.put("order_date", "2026-07-17");
        main.put("pact_state", 0);
        main.put("org_id", 1);
        main.put("mat_id", 1);
        main.put("plan_qty", "2000.00");
        main.put("unit", "kg");

        // 子表（entity_code='material'）
        Map<String, Object> material = new HashMap<>();
        material.put("mat_id", 1);
        material.put("batch_no", "B20260717001");
        material.put("std_qty", "200.00");
        material.put("actual_qty", "200.00");
        material.put("loss_rate", "0.05");

        Map<String, Object> subs = new HashMap<>();
        subs.put("material", List.of(material));

        Map<String, Object> billData = new HashMap<>();
        billData.put("main", main);
        billData.put("subs", subs);

        Long id = createBill("MFG_ORDER", billData);
        assertNotNull(id, "保存含子表生产订单应返回 ID");

        // 验证主表
        Integer mainCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM mfg_order WHERE id = ?", Integer.class, id);
        assertEquals(1, mainCount, "生产订单主表应存在");

        // 验证子表（order_id 外键关联）
        Integer detailCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM mfg_order_material WHERE order_id = ?", Integer.class, id);
        assertTrue(detailCount >= 1, "生产订单投料明细应至少 1 条");
    }

    // ==================== 含孙表的 BOM 保存 ====================

    @Test
    @DisplayName("含孙表 BOM：保存主表 + 原料明细子表 + 替代料孙表")
    void testMfgBomWithGrandChild() throws Exception {
        // 主表
        Map<String, Object> main = new HashMap<>();
        main.put("code", "TEST_MB_001");
        main.put("pact_state", 0);
        main.put("mat_id", 1);
        main.put("bom_type", "standard");
        main.put("base_qty", "1000.00");

        // 孙表行（替代料，entity_code='sub', link_field='bom_material_id'）
        Map<String, Object> subRow = new HashMap<>();
        subRow.put("mat_id", 1);
        subRow.put("sub_ratio", "0.30");
        subRow.put("priority", 1);

        // 子表行（原料明细，entity_code='material', link_field='bom_id'）
        Map<String, Object> material = new HashMap<>();
        material.put("mat_id", 1);
        material.put("mat_type", "main");
        material.put("ratio", "0.50");
        material.put("unit_qty", "500.00");
        material.put("loss_rate", "0.02");
        // 嵌套孙表：子表行中包含 sub 列表（层级嵌套）
        material.put("sub", List.of(subRow));

        Map<String, Object> subs = new HashMap<>();
        subs.put("material", List.of(material));

        Map<String, Object> billData = new HashMap<>();
        billData.put("main", main);
        billData.put("subs", subs);

        Long id = createBill("MFG_BOM", billData);
        assertNotNull(id, "保存含孙表 BOM 应返回 ID");

        // 验证主表
        Integer mainCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM mfg_bom WHERE id = ?", Integer.class, id);
        assertEquals(1, mainCount, "BOM 主表应存在");

        // 验证子表
        Integer goodsCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM mfg_bom_material WHERE bom_id = ?", Integer.class, id);
        assertTrue(goodsCount >= 1, "BOM 原料明细应至少 1 条");

        // 验证孙表（通过子表 ID 关联）
        Long bomMaterialId = jdbcTemplate.queryForObject(
                "SELECT id FROM mfg_bom_material WHERE bom_id = ? LIMIT 1", Long.class, id);
        Integer subCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM mfg_bom_material_sub WHERE bom_material_id = ?", Integer.class, bomMaterialId);
        assertTrue(subCount >= 1, "BOM 替代料孙表应至少 1 条");
    }

    // ==================== 生产入库 CRUD（验证多单据类型） ====================

    @Test
    @DisplayName("生产入库 CRUD：保存 → 验证状态机流转")
    void testMfgInStockCrud() throws Exception {
        Map<String, Object> main = new HashMap<>();
        main.put("code", "TEST_MIS_001");
        main.put("in_date", "2026-07-17");
        main.put("pact_state", 0);
        main.put("org_id", 1);
        main.put("warehouse_id", 1);
        main.put("in_type", "finish");
        main.put("total_qty", "500.00");
        main.put("total_cost", "50000.00");

        Map<String, Object> billData = new HashMap<>();
        billData.put("main", main);

        Long id = createBill("MFG_IN_STOCK", billData);
        assertNotNull(id, "保存生产入库应返回 ID");

        // 状态流转：submit → audit
        operate("MFG_IN_STOCK", id, "submit");
        operate("MFG_IN_STOCK", id, "audit");

        Integer state = jdbcTemplate.queryForObject(
                "SELECT pact_state FROM mfg_in_stock WHERE id = ?", Integer.class, id);
        assertEquals(3, state, "生产入库审核后 pact_state 应为 3");
    }

    // ==================== 领料单含子表验证 ====================

    @Test
    @DisplayName("领料单：保存主表 + 领料明细子表")
    void testMfgPickWithDetail() throws Exception {
        Map<String, Object> main = new HashMap<>();
        main.put("code", "TEST_MP_001");
        main.put("pick_date", "2026-07-17");
        main.put("pact_state", 0);
        main.put("org_id", 1);
        main.put("warehouse_id", 1);
        main.put("pick_type", "normal");
        main.put("total_qty", "300.00");
        main.put("total_cost", "30000.00");

        Map<String, Object> goods = new HashMap<>();
        goods.put("mat_id", 1);
        goods.put("batch_no", "B20260717002");
        goods.put("qty", "300.00");
        goods.put("unit", "kg");
        goods.put("cost_price", "100.00");
        goods.put("cost_amount", "30000.00");

        Map<String, Object> subs = new HashMap<>();
        subs.put("goods", List.of(goods));

        Map<String, Object> billData = new HashMap<>();
        billData.put("main", main);
        billData.put("subs", subs);

        Long id = createBill("MFG_PICK", billData);
        assertNotNull(id, "保存领料单应返回 ID");

        Integer detailCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM mfg_pick_goods WHERE pick_id = ?", Integer.class, id);
        assertTrue(detailCount >= 1, "领料单明细应至少 1 条");
    }

    // ==================== 删除操作验证 ====================

    @Test
    @DisplayName("生产订单删除：暂存状态可删除")
    void testMfgOrderDelete() throws Exception {
        Map<String, Object> main = new HashMap<>();
        main.put("code", "TEST_MO_DEL_001");
        main.put("order_date", "2026-07-17");
        main.put("pact_state", 0);
        main.put("org_id", 1);

        Map<String, Object> billData = new HashMap<>();
        billData.put("main", main);

        Long id = createBill("MFG_ORDER", billData);

        // 删除（delete 操作：0 → -1 物理删除）
        operate("MFG_ORDER", id, "delete");

        Integer count = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM mfg_order WHERE id = ?", Integer.class, id);
        assertEquals(0, count, "删除后记录不应存在");
    }

    // ==================== 关闭/取消操作验证 ====================

    @Test
    @DisplayName("生产订单关闭/取消：审核后可关闭和取消")
    void testMfgOrderCloseAndCancel() throws Exception {
        Map<String, Object> main = new HashMap<>();
        main.put("code", "TEST_MO_CLOSE_001");
        main.put("order_date", "2026-07-17");
        main.put("pact_state", 0);
        main.put("org_id", 1);

        Map<String, Object> billData = new HashMap<>();
        billData.put("main", main);

        Long id = createBill("MFG_ORDER", billData);

        // 状态流转到已审核
        operate("MFG_ORDER", id, "submit");
        operate("MFG_ORDER", id, "audit");

        // 关闭（close：post_action='is_closed=1'）
        operate("MFG_ORDER", id, "close");
        Integer isClosed = jdbcTemplate.queryForObject(
                "SELECT is_closed FROM mfg_order WHERE id = ?", Integer.class, id);
        assertEquals(1, isClosed, "关闭后 is_closed 应为 1");

        // 取消（cancel：post_action='is_cancel=1'，require_reason=1）
        operate("MFG_ORDER", id, "cancel", "测试取消原因");
        Integer isCancel = jdbcTemplate.queryForObject(
                "SELECT is_cancel FROM mfg_order WHERE id = ?", Integer.class, id);
        assertEquals(1, isCancel, "取消后 is_cancel 应为 1");
    }
}
