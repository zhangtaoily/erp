package com.eerp.test.inv;

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
 * 库存管理模块集成测试（Phase 2c，对齐设计文档 04）。
 *
 * <p>验证 9 个库存业务单据的元数据注册、状态机配置、CRUD 端到端流程、
 * 含子表的主数据保存、状态流转（save → submit → audit）。</p>
 *
 * <p>测试范围：</p>
 * <ul>
 *   <li>9 个库存 bo_code 在 meta_business_object 中正确注册</li>
 *   <li>7 个有状态机的 bo_code 注册独立状态机（5 节点 + 17 流转，code=bo_code）</li>
 *   <li>INV_STOCK / INV_BATCH 为台账（is_stateful=0），无状态机</li>
 *   <li>meta_form_entity 实体层级（9 主 + 7 子 = 16）</li>
 *   <li>meta_form_field 字段元数据（>= 80 个关键字段）</li>
 *   <li>盘点单 CRUD：保存 → 提交 → 审核（pact_state=3）</li>
 *   <li>调拨单含子表保存：主表 + 明细（inv_transfer_goods）</li>
 *   <li>其他入库含子表保存（INV_OTHER_IN，共享 inv_other_stock 表）</li>
 *   <li>锁库单 CRUD：保存 → 提交 → 审核</li>
 *   <li>INV_STOCK 无状态机：保存即落库，不走状态流转</li>
 *   <li>盘点单删除（暂存/已创建状态可删除）</li>
 *   <li>盘点单关闭/取消（审核后 close→is_closed=1，cancel→is_cancel=1 需 reason）</li>
 * </ul>
 */
@SpringBootTest(classes = EerpTestApplication.class)
@ActiveProfiles("test")
@AutoConfigureMockMvc
class InvIntegrationTest extends AbstractIntegrationTest {

    /** 9 个库存 bo_code */
    private static final String[] ALL_INV_BO_CODES = {
            "INV_STOCK", "INV_BATCH", "INV_STOCKTAKE", "INV_TRANSFER", "INV_FORM_CONV",
            "INV_OTHER_IN", "INV_OTHER_OUT", "INV_LOCK", "INV_LOCK_APPLY"
    };

    /** 7 个有状态机的 bo_code（INV_STOCK / INV_BATCH 无状态机） */
    private static final String[] STATEFUL_INV_BO_CODES = {
            "INV_STOCKTAKE", "INV_TRANSFER", "INV_FORM_CONV",
            "INV_OTHER_IN", "INV_OTHER_OUT", "INV_LOCK", "INV_LOCK_APPLY"
    };

    // ==================== 元数据注册验证 ====================

    @Test
    @DisplayName("9 个库存 bo_code 在 meta_business_object 中注册")
    void testInvBoCodesRegistered() {
        for (String boCode : ALL_INV_BO_CODES) {
            Integer count = jdbcTemplate.queryForObject(
                    "SELECT COUNT(*) FROM meta_business_object WHERE bo_code = ?", Integer.class, boCode);
            assertEquals(1, count, "业务对象 " + boCode + " 应已注册");
        }
    }

    @Test
    @DisplayName("库存 bo_code 总数为 9")
    void testInvBoCount() {
        Integer count = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM meta_business_object WHERE bo_code LIKE 'INV|_%' ESCAPE '|'", Integer.class);
        assertEquals(9, count, "应注册 9 个库存业务对象");
    }

    @Test
    @DisplayName("有状态机的库存 bo_code 数为 7（is_stateful=1）")
    void testStatefulBoCount() {
        Integer statefulCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM meta_business_object WHERE bo_code LIKE 'INV|_%' ESCAPE '|' AND is_stateful = 1",
                Integer.class);
        assertEquals(7, statefulCount, "应有 7 个 is_stateful=1 的库存业务对象");

        Integer statelessCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM meta_business_object WHERE bo_code LIKE 'INV|_%' ESCAPE '|' AND is_stateful = 0",
                Integer.class);
        assertEquals(2, statelessCount, "应有 2 个 is_stateful=0 的库存台账（INV_STOCK/INV_BATCH）");
    }

    // ==================== 状态机配置验证 ====================

    @Test
    @DisplayName("7 个有状态机的 bo_code 注册独立状态机（code=bo_code）")
    void testStateMachineRegistered() {
        for (String boCode : STATEFUL_INV_BO_CODES) {
            Integer count = jdbcTemplate.queryForObject(
                    "SELECT COUNT(*) FROM meta_state_machine WHERE code = ?", Integer.class, boCode);
            assertEquals(1, count, "状态机 " + boCode + " 应已注册（code=bo_code）");
        }
        // INV_STOCK / INV_BATCH 不应有状态机
        for (String boCode : new String[]{"INV_STOCK", "INV_BATCH"}) {
            Integer count = jdbcTemplate.queryForObject(
                    "SELECT COUNT(*) FROM meta_state_machine WHERE code = ?", Integer.class, boCode);
            assertEquals(0, count, "台账 " + boCode + " 不应注册状态机");
        }
    }

    @Test
    @DisplayName("每个库存状态机有 5 个节点")
    void testStateNodeCount() {
        for (String boCode : STATEFUL_INV_BO_CODES) {
            Integer nodeCount = jdbcTemplate.queryForObject(
                    "SELECT COUNT(*) FROM meta_state_node n " +
                            "JOIN meta_state_machine m ON n.machine_id = m.id " +
                            "WHERE m.code = ?", Integer.class, boCode);
            assertEquals(5, nodeCount, "状态机 " + boCode + " 应有 5 个节点");
        }
    }

    @Test
    @DisplayName("每个库存状态机有 17 条流转")
    void testStateTransitionCount() {
        for (String boCode : STATEFUL_INV_BO_CODES) {
            Integer transitionCount = jdbcTemplate.queryForObject(
                    "SELECT COUNT(*) FROM meta_state_transition t " +
                            "JOIN meta_state_machine m ON t.machine_id = m.id " +
                            "WHERE m.code = ?", Integer.class, boCode);
            assertEquals(17, transitionCount, "状态机 " + boCode + " 应有 17 条流转");
        }
    }

    // ==================== 实体层级验证 ====================

    @Test
    @DisplayName("库存实体注册数量正确（9 主 + 7 子 = 16）")
    void testFormEntityCount() {
        Integer totalCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM meta_form_entity WHERE bo_code LIKE 'INV|_%' ESCAPE '|'", Integer.class);
        assertEquals(16, totalCount, "应注册 16 个库存实体（9 主 + 7 子）");

        Integer mainCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM meta_form_entity WHERE bo_code LIKE 'INV|_%' ESCAPE '|' AND entity_type = 'main'",
                Integer.class);
        assertEquals(9, mainCount, "应注册 9 个主实体");

        Integer subCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM meta_form_entity WHERE bo_code LIKE 'INV|_%' ESCAPE '|' AND entity_type = 'sub'",
                Integer.class);
        assertEquals(7, subCount, "应注册 7 个子实体");
    }

    @Test
    @DisplayName("INV_TRANSFER 有 2 个实体（主表 + 明细子表），子表 link_field=transfer_id")
    void testInvTransferEntityHierarchy() {
        List<Map<String, Object>> entities = jdbcTemplate.queryForList(
                "SELECT entity_code, entity_type, entity_level, table_name, parent_entity_code, link_field " +
                        "FROM meta_form_entity WHERE bo_code = 'INV_TRANSFER' ORDER BY sort_index");
        assertEquals(2, entities.size(), "INV_TRANSFER 应有 2 个实体");

        // 主表
        Map<String, Object> main = entities.get(0);
        assertEquals("inv_transfer", main.get("entity_code"));
        assertEquals("main", main.get("entity_type"));
        assertEquals(0, ((Number) main.get("entity_level")).intValue());
        assertEquals("inv_transfer", main.get("table_name"));

        // 子表
        Map<String, Object> sub = entities.get(1);
        assertEquals("goods", sub.get("entity_code"));
        assertEquals("sub", sub.get("entity_type"));
        assertEquals(1, ((Number) sub.get("entity_level")).intValue());
        assertEquals("inv_transfer_goods", sub.get("table_name"));
        assertEquals("inv_transfer", sub.get("parent_entity_code"));
        assertEquals("transfer_id", sub.get("link_field"));
    }

    // ==================== 字段元数据验证 ====================

    @Test
    @DisplayName("库存字段元数据已注册（>= 80 个）")
    void testFormFieldMetadataExists() {
        Integer fieldCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM meta_form_field WHERE bo_code LIKE 'INV|_%' ESCAPE '|'", Integer.class);
        assertNotNull(fieldCount);
        assertTrue(fieldCount >= 80, "应至少注册 80 个字段元数据，实际: " + fieldCount);
    }

    @Test
    @DisplayName("INV_STOCK 主表字段包含关键字段 warehouse_id/mat_id/qty")
    void testInvStockFieldsRegistered() {
        List<String> fieldCodes = jdbcTemplate.queryForList(
                "SELECT field_code FROM meta_form_field WHERE bo_code = 'INV_STOCK' AND entity_code = 'inv_stock'",
                String.class);
        assertTrue(fieldCodes.contains("warehouse_id"), "INV_STOCK 应包含 warehouse_id 字段");
        assertTrue(fieldCodes.contains("mat_id"), "INV_STOCK 应包含 mat_id 字段");
        assertTrue(fieldCodes.contains("qty"), "INV_STOCK 应包含 qty 字段");
    }

    // ==================== 盘点单 CRUD 端到端验证 ====================

    @Test
    @DisplayName("盘点单 CRUD：保存 → 提交 → 审核，pact_state=3")
    void testInvStocktakeCrud() throws Exception {
        Map<String, Object> main = new HashMap<>();
        main.put("code", "TEST_ST_001");
        main.put("stocktake_date", "2026-07-17");
        main.put("pact_state", 0);
        main.put("org_id", 1);
        main.put("warehouse_id", 1);
        main.put("stocktake_type", "full");
        main.put("total_qty", "100.00");

        Map<String, Object> billData = new HashMap<>();
        billData.put("main", main);

        // 1. 保存（save 操作：0 → 1 已创建）
        Long id = createBill("INV_STOCKTAKE", billData);
        assertNotNull(id, "保存盘点单应返回 ID");

        // 2. 验证主表存在且状态为 1（save 流转后）
        Integer mainCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM inv_stocktake WHERE id = ?", Integer.class, id);
        assertEquals(1, mainCount, "盘点单主表应存在");

        // 3. 提交（submit：1 → 2 已提交）
        operate("INV_STOCKTAKE", id, "submit");

        // 4. 审核（audit：2 → 3 已审核）
        operate("INV_STOCKTAKE", id, "audit");

        // 5. 验证最终状态为 3（已审核）
        Integer state = jdbcTemplate.queryForObject(
                "SELECT pact_state FROM inv_stocktake WHERE id = ?", Integer.class, id);
        assertEquals(3, state, "审核后 pact_state 应为 3");
    }

    // ==================== 含子表的调拨单保存 ====================

    @Test
    @DisplayName("调拨单含子表保存：主表 + 明细子表（inv_transfer_goods）")
    void testInvTransferWithDetail() throws Exception {
        Map<String, Object> main = new HashMap<>();
        main.put("code", "TEST_TR_001");
        main.put("transfer_date", "2026-07-17");
        main.put("pact_state", 0);
        main.put("from_org_id", 1);
        main.put("from_warehouse_id", 1);
        main.put("to_warehouse_id", 2);
        main.put("transfer_type", "normal");
        main.put("total_qty", "200.00");

        Map<String, Object> goods = new HashMap<>();
        goods.put("mat_id", 1);
        goods.put("batch_no", "LOT_TR_001");
        goods.put("qty", "200.00");
        goods.put("unit", "kg");

        Map<String, Object> subs = new HashMap<>();
        subs.put("goods", List.of(goods));

        Map<String, Object> billData = new HashMap<>();
        billData.put("main", main);
        billData.put("subs", subs);

        Long id = createBill("INV_TRANSFER", billData);
        assertNotNull(id, "保存调拨单应返回 ID");

        // 验证主表
        Integer mainCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM inv_transfer WHERE id = ?", Integer.class, id);
        assertEquals(1, mainCount, "调拨单主表应存在");

        // 验证子表（transfer_id 外键关联）
        Integer detailCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM inv_transfer_goods WHERE transfer_id = ?", Integer.class, id);
        assertTrue(detailCount >= 1, "调拨单明细应至少 1 条");
    }

    // ==================== 锁库单 CRUD 端到端验证 ====================

    @Test
    @DisplayName("锁库单 CRUD：保存 → 提交 → 审核")
    void testInvLockCrud() throws Exception {
        Map<String, Object> main = new HashMap<>();
        main.put("code", "TEST_LK_001");
        main.put("pact_date", "2026-07-17");
        main.put("pact_state", 0);
        main.put("org_id", 1);
        main.put("warehouse_id", 1);
        main.put("mat_id", 1);
        main.put("total_lock_qty", "100.00");

        Map<String, Object> billData = new HashMap<>();
        billData.put("main", main);

        Long id = createBill("INV_LOCK", billData);
        assertNotNull(id, "保存锁库单应返回 ID");

        // 状态流转：submit → audit
        operate("INV_LOCK", id, "submit");
        operate("INV_LOCK", id, "audit");

        Integer state = jdbcTemplate.queryForObject(
                "SELECT pact_state FROM inv_lock WHERE id = ?", Integer.class, id);
        assertEquals(3, state, "锁库单审核后 pact_state 应为 3");
    }

    // ==================== 其他入库含子表验证（共享 inv_other_stock 表） ====================

    @Test
    @DisplayName("其他入库含子表保存（INV_OTHER_IN），验证 inv_other_stock_goods 表有记录")
    void testInvOtherInWithDetail() throws Exception {
        Map<String, Object> main = new HashMap<>();
        main.put("code", "TEST_OIN_001");
        main.put("bill_date", "2026-07-17");
        main.put("pact_state", 0);
        main.put("org_id", 1);
        main.put("warehouse_id", 1);
        main.put("stock_direction", "in");
        main.put("total_qty", "300.00");

        Map<String, Object> goods = new HashMap<>();
        goods.put("mat_id", 1);
        goods.put("batch_no", "LOT_OIN_001");
        goods.put("qty", "300.00");
        goods.put("unit", "kg");
        goods.put("cost_price", "100.00");

        Map<String, Object> subs = new HashMap<>();
        subs.put("goods", List.of(goods));

        Map<String, Object> billData = new HashMap<>();
        billData.put("main", main);
        billData.put("subs", subs);

        Long id = createBill("INV_OTHER_IN", billData);
        assertNotNull(id, "保存其他入库应返回 ID");

        // 验证主表（inv_other_stock）
        Integer mainCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM inv_other_stock WHERE id = ?", Integer.class, id);
        assertEquals(1, mainCount, "其他入库主表应存在");

        // 验证子表（bill_id 外键关联，link_field=bill_id 对齐 schema 实际列名）
        Integer detailCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM inv_other_stock_goods WHERE bill_id = ?", Integer.class, id);
        assertTrue(detailCount >= 1, "其他入库明细应至少 1 条");

        // 验证 stock_direction='in'
        String direction = jdbcTemplate.queryForObject(
                "SELECT stock_direction FROM inv_other_stock WHERE id = ?", String.class, id);
        assertEquals("in", direction, "INV_OTHER_IN 的 stock_direction 应为 in");
    }

    // ==================== INV_STOCK 无状态机验证 ====================

    @Test
    @DisplayName("INV_STOCK 保存后不触发状态流转（保存即可查到，无需 submit/audit）")
    void testInvStockNoState() throws Exception {
        Map<String, Object> main = new HashMap<>();
        main.put("org_id", 1);
        main.put("warehouse_id", 1);
        main.put("mat_id", 1);
        main.put("batch_no", "STK_TEST_001");
        main.put("unit", "kg");
        main.put("qty", "100.00");
        main.put("cost_price", "50.00");
        main.put("cost_amount", "5000.00");
        // 注意：INV_STOCK 无状态机，main 中不需要 pact_state/code

        Map<String, Object> billData = new HashMap<>();
        billData.put("main", main);

        Long id = createBill("INV_STOCK", billData);
        assertNotNull(id, "保存即时库存应返回 ID");

        // 验证记录存在
        Integer count = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM inv_stock WHERE id = ?", Integer.class, id);
        assertEquals(1, count, "即时库存记录应存在");

        // 验证 qty 已落库
        Object qty = jdbcTemplate.queryForObject(
                "SELECT qty FROM inv_stock WHERE id = ?", Object.class, id);
        assertNotNull(qty, "qty 应已落库");
    }

    // ==================== 删除操作验证 ====================

    @Test
    @DisplayName("盘点单删除：已创建状态可删除")
    void testInvStocktakeDelete() throws Exception {
        Map<String, Object> main = new HashMap<>();
        main.put("code", "TEST_ST_DEL_001");
        main.put("stocktake_date", "2026-07-17");
        main.put("pact_state", 0);
        main.put("warehouse_id", 1);

        Map<String, Object> billData = new HashMap<>();
        billData.put("main", main);

        Long id = createBill("INV_STOCKTAKE", billData);

        // 删除（delete 操作：物理删除）
        operate("INV_STOCKTAKE", id, "delete");

        Integer count = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM inv_stocktake WHERE id = ?", Integer.class, id);
        assertEquals(0, count, "删除后记录不应存在");
    }

    // ==================== 关闭/取消操作验证 ====================

    @Test
    @DisplayName("盘点单关闭/取消：审核后可关闭和取消（cancel 需传 reason）")
    void testInvStocktakeCloseAndCancel() throws Exception {
        Map<String, Object> main = new HashMap<>();
        main.put("code", "TEST_ST_CC_001");
        main.put("stocktake_date", "2026-07-17");
        main.put("pact_state", 0);
        main.put("warehouse_id", 1);

        Map<String, Object> billData = new HashMap<>();
        billData.put("main", main);

        Long id = createBill("INV_STOCKTAKE", billData);

        // 状态流转到已审核
        operate("INV_STOCKTAKE", id, "submit");
        operate("INV_STOCKTAKE", id, "audit");

        // 关闭（close：post_action='is_closed=1'）
        operate("INV_STOCKTAKE", id, "close");
        Integer isClosed = jdbcTemplate.queryForObject(
                "SELECT is_closed FROM inv_stocktake WHERE id = ?", Integer.class, id);
        assertEquals(1, isClosed, "关闭后 is_closed 应为 1");

        // 取消（cancel：post_action='is_cancel=1'，require_reason=1）
        operate("INV_STOCKTAKE", id, "cancel", "测试取消原因");
        Integer isCancel = jdbcTemplate.queryForObject(
                "SELECT is_cancel FROM inv_stocktake WHERE id = ?", Integer.class, id);
        assertEquals(1, isCancel, "取消后 is_cancel 应为 1");
    }
}
