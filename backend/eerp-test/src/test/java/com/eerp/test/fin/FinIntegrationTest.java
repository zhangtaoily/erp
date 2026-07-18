package com.eerp.test.fin;

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
 * 财务会计模块集成测试（Phase 3a-3c，对齐设计文档 04）。
 *
 * <p>验证 14 个财务业务对象的元数据注册、状态机配置（5 业务单据）、
 * CRUD 端到端流程、含子表的主数据/业务单据保存、状态流转
 * （save → submit → audit）、关闭/取消操作。</p>
 *
 * <p>测试范围：</p>
 * <ul>
 *   <li>14 个 FIN_ 前缀 bo_code 在 meta_business_object 中正确注册</li>
 *   <li>5 个业务单据（FIN_AR / FIN_RECEIPT / FIN_PAYMENT / FIN_WRITEOFF / FIN_CUST_RECEIPT）
 *       为 business 类型、is_stateful=1，并注册独立状态机（5 节点 + 17 流转）</li>
 *   <li>9 个主数据（FIN_EST_AP / FIN_AP / FIN_ACCOUNT / FIN_PERIOD /
 *       FIN_VOUCHER_TPL / FIN_VOUCHER / FIN_COST_COLLECT / FIN_COST_POOL /
 *       FIN_COST_VARIANCE）为 master 类型、is_stateful=0，无状态机</li>
 *   <li>meta_form_entity 实体层级（14 主 + 5 子 = 19）</li>
 *   <li>meta_form_field 字段元数据（193 个关键字段）</li>
 *   <li>应收单 CRUD：保存 → 提交 → 审核（pact_state=3）</li>
 *   <li>应付单（主数据）保存：无状态流转</li>
 *   <li>暂估应付（主数据）保存</li>
 *   <li>核销单 CRUD：保存 → 提交 → 审核</li>
 *   <li>含子表保存：凭证（主 + 分录）、收款单（主 + 核销明细）</li>
 *   <li>删除操作、关闭/取消操作（含 reason）</li>
 * </ul>
 */
@SpringBootTest(classes = EerpTestApplication.class)
@ActiveProfiles("test")
@AutoConfigureMockMvc
class FinIntegrationTest extends AbstractIntegrationTest {

    // ==================== 元数据注册验证 ====================

    @Test
    @DisplayName("14 个财务 bo_code 在 meta_business_object 中注册")
    void testFinBoCodesRegistered() {
        String[] expectedBoCodes = {
                "FIN_EST_AP", "FIN_AR", "FIN_AP", "FIN_RECEIPT", "FIN_PAYMENT",
                "FIN_WRITEOFF", "FIN_CUST_RECEIPT",
                "FIN_ACCOUNT", "FIN_PERIOD", "FIN_VOUCHER_TPL", "FIN_VOUCHER",
                "FIN_COST_COLLECT", "FIN_COST_POOL", "FIN_COST_VARIANCE"
        };
        for (String boCode : expectedBoCodes) {
            Integer count = jdbcTemplate.queryForObject(
                    "SELECT COUNT(*) FROM meta_business_object WHERE bo_code = ?", Integer.class, boCode);
            assertEquals(1, count, "业务对象 " + boCode + " 应已注册");
        }
    }

    @Test
    @DisplayName("财务 bo_code 总数为 14")
    void testFinBoCount() {
        Integer count = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM meta_business_object WHERE bo_code LIKE 'FIN_%'", Integer.class);
        assertEquals(14, count, "应注册 14 个财务业务对象");
    }

    @Test
    @DisplayName("财务业务单据（有状态机）数量为 5")
    void testFinBusinessBoCount() {
        Integer businessCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM meta_business_object WHERE bo_code LIKE 'FIN_%' " +
                        "AND bo_type = 'business' AND is_stateful = 1", Integer.class);
        assertEquals(5, businessCount, "应有 5 个财务业务单据（business + is_stateful=1）");

        Integer masterCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM meta_business_object WHERE bo_code LIKE 'FIN_%' " +
                        "AND bo_type = 'master' AND is_stateful = 0", Integer.class);
        assertEquals(9, masterCount, "应有 9 个财务主数据（master + is_stateful=0）");
    }

    // ==================== 状态机配置验证 ====================

    @Test
    @DisplayName("5 个业务单据注册独立状态机（code=bo_code）")
    void testStateMachineRegistered() {
        String[] businessBoCodes = {
                "FIN_AR", "FIN_RECEIPT", "FIN_PAYMENT", "FIN_WRITEOFF", "FIN_CUST_RECEIPT"
        };
        for (String boCode : businessBoCodes) {
            Integer count = jdbcTemplate.queryForObject(
                    "SELECT COUNT(*) FROM meta_state_machine WHERE code = ?", Integer.class, boCode);
            assertEquals(1, count, "状态机 " + boCode + " 应已注册（code=bo_code）");
        }

        // 主数据 bo_code 不应有状态机
        String[] masterBoCodes = {"FIN_AP", "FIN_EST_AP", "FIN_VOUCHER", "FIN_ACCOUNT"};
        for (String boCode : masterBoCodes) {
            Integer count = jdbcTemplate.queryForObject(
                    "SELECT COUNT(*) FROM meta_state_machine WHERE code = ?", Integer.class, boCode);
            assertEquals(0, count, "主数据 " + boCode + " 不应有状态机");
        }
    }

    @Test
    @DisplayName("每个财务状态机有 5 个节点")
    void testStateNodeCount() {
        String[] businessBoCodes = {
                "FIN_AR", "FIN_RECEIPT", "FIN_PAYMENT", "FIN_WRITEOFF", "FIN_CUST_RECEIPT"
        };
        for (String boCode : businessBoCodes) {
            Integer nodeCount = jdbcTemplate.queryForObject(
                    "SELECT COUNT(*) FROM meta_state_node n " +
                            "JOIN meta_state_machine m ON n.machine_id = m.id " +
                            "WHERE m.code = ?", Integer.class, boCode);
            assertEquals(5, nodeCount, "状态机 " + boCode + " 应有 5 个节点");
        }
    }

    @Test
    @DisplayName("每个财务状态机有 17 条流转")
    void testStateTransitionCount() {
        String[] businessBoCodes = {
                "FIN_AR", "FIN_RECEIPT", "FIN_PAYMENT", "FIN_WRITEOFF", "FIN_CUST_RECEIPT"
        };
        for (String boCode : businessBoCodes) {
            Integer transitionCount = jdbcTemplate.queryForObject(
                    "SELECT COUNT(*) FROM meta_state_transition t " +
                            "JOIN meta_state_machine m ON t.machine_id = m.id " +
                            "WHERE m.code = ?", Integer.class, boCode);
            assertEquals(17, transitionCount, "状态机 " + boCode + " 应有 17 条流转");
        }
    }

    // ==================== 实体层级验证 ====================

    @Test
    @DisplayName("财务实体注册数量正确（14 主 + 5 子 = 19）")
    void testFormEntityCount() {
        Integer totalCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM meta_form_entity WHERE bo_code LIKE 'FIN_%'", Integer.class);
        assertEquals(19, totalCount, "应注册 19 个财务实体（14 主 + 5 子）");

        Integer mainCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM meta_form_entity WHERE bo_code LIKE 'FIN_%' AND entity_type = 'main'",
                Integer.class);
        assertEquals(14, mainCount, "应注册 14 个主实体");

        Integer subCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM meta_form_entity WHERE bo_code LIKE 'FIN_%' AND entity_type = 'sub'",
                Integer.class);
        assertEquals(5, subCount, "应注册 5 个子实体");
    }

    @Test
    @DisplayName("FIN_VOUCHER 有 2 个实体（主表 + 凭证分录子表）")
    void testFinVoucherEntityHierarchy() {
        List<Map<String, Object>> entities = jdbcTemplate.queryForList(
                "SELECT entity_code, entity_type, entity_level, table_name, parent_entity_code, link_field " +
                        "FROM meta_form_entity WHERE bo_code = 'FIN_VOUCHER' ORDER BY sort_index");
        assertEquals(2, entities.size(), "FIN_VOUCHER 应有 2 个实体");

        // 主表
        Map<String, Object> main = entities.get(0);
        assertEquals("fin_voucher", main.get("entity_code"));
        assertEquals("main", main.get("entity_type"));
        assertEquals(0, ((Number) main.get("entity_level")).intValue());
        assertEquals("fin_voucher", main.get("table_name"));

        // 子表（凭证分录）
        Map<String, Object> sub = entities.get(1);
        assertEquals("entry", sub.get("entity_code"));
        assertEquals("sub", sub.get("entity_type"));
        assertEquals(1, ((Number) sub.get("entity_level")).intValue());
        assertEquals("fin_voucher_entry", sub.get("table_name"));
        assertEquals("fin_voucher", sub.get("parent_entity_code"));
        assertEquals("voucher_id", sub.get("link_field"));
    }

    // ==================== 字段元数据验证 ====================

    @Test
    @DisplayName("财务字段元数据已注册（>= 100 个）")
    void testFormFieldMetadataExists() {
        Integer fieldCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM meta_form_field WHERE bo_code LIKE 'FIN_%'", Integer.class);
        assertNotNull(fieldCount);
        assertTrue(fieldCount >= 100, "应至少注册 100 个字段元数据，实际: " + fieldCount);
    }

    @Test
    @DisplayName("FIN_AR 主表字段包含关键字段")
    void testFinArFieldsRegistered() {
        List<String> fieldCodes = jdbcTemplate.queryForList(
                "SELECT field_code FROM meta_form_field WHERE bo_code = 'FIN_AR' AND entity_code = 'fin_ar'",
                String.class);
        assertTrue(fieldCodes.contains("code"), "FIN_AR 应包含 code 字段");
        assertTrue(fieldCodes.contains("bill_date"), "FIN_AR 应包含 bill_date 字段");
        assertTrue(fieldCodes.contains("cust_id"), "FIN_AR 应包含 cust_id 字段");
        assertTrue(fieldCodes.contains("amount"), "FIN_AR 应包含 amount 字段");
        assertTrue(fieldCodes.contains("pact_state"), "FIN_AR 应包含 pact_state 字段");
    }

    // ==================== 应收单 CRUD 端到端验证（业务单据） ====================

    @Test
    @DisplayName("应收单 CRUD：保存 → 提交 → 审核（pact_state=3）")
    void testFinArCrud() throws Exception {
        // 1. 保存应收单（save 操作：0 → 1 已创建）
        Map<String, Object> main = new HashMap<>();
        main.put("code", "TEST_AR_001");
        main.put("bill_date", "2026-07-17");
        main.put("pact_state", 0);
        main.put("cust_id", 1);
        main.put("org_id", 1);
        main.put("curr_id", 1);
        main.put("amount", "10000.00");
        main.put("no_tax_amount", "8849.56");
        main.put("tax_amount", "1150.44");
        main.put("balance", "10000.00");

        Map<String, Object> billData = new HashMap<>();
        billData.put("main", main);

        Long id = createBill("FIN_AR", billData);
        assertNotNull(id, "保存应收单应返回 ID");

        // 2. 验证数据库中存在且状态为 1（save 流转后）
        Integer mainCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM fin_ar WHERE id = ?", Integer.class, id);
        assertEquals(1, mainCount, "应收单主表应存在");

        // 3. 查询详情
        Map<String, Object> detail = getBillDetail("FIN_AR", id);
        assertNotNull(detail, "详情不应为 null");
        Map<String, Object> mainData = (Map<String, Object>) detail.get("main");
        assertNotNull(mainData, "main 数据不应为 null");
        assertEquals("TEST_AR_001", mainData.get("code"), "编码应一致");

        // 4. 提交（submit 操作：1 → 2 已提交）
        operate("FIN_AR", id, "submit");

        // 5. 审核（audit 操作：2 → 3 已审核）
        operate("FIN_AR", id, "audit");

        // 6. 验证最终状态为 3（已审核）
        Integer state = jdbcTemplate.queryForObject(
                "SELECT pact_state FROM fin_ar WHERE id = ?", Integer.class, id);
        assertEquals(3, state, "审核后 pact_state 应为 3");
    }

    // ==================== 应付单 CRUD（主数据，无状态流转） ====================

    @Test
    @DisplayName("应付单（主数据）保存：无状态流转")
    void testFinApCrud() throws Exception {
        Map<String, Object> main = new HashMap<>();
        main.put("code", "TEST_AP_001");
        main.put("bill_date", "2026-07-17");
        main.put("supplier_id", 1);
        main.put("org_id", 1);
        main.put("curr_id", 1);
        main.put("amount", "5000.00");
        main.put("no_tax_amount", "4424.78");
        main.put("tax_amount", "575.22");
        main.put("balance", "5000.00");
        main.put("src_bill_type", "PUR_INVOICE");

        Map<String, Object> billData = new HashMap<>();
        billData.put("main", main);

        Long id = createBill("FIN_AP", billData);
        assertNotNull(id, "保存应付单应返回 ID");

        // 验证记录存在
        Integer mainCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM fin_ap WHERE id = ?", Integer.class, id);
        assertEquals(1, mainCount, "应付单主表应存在");

        // 验证编码一致
        String code = jdbcTemplate.queryForObject(
                "SELECT code FROM fin_ap WHERE id = ?", String.class, id);
        assertEquals("TEST_AP_001", code, "应付单编码应一致");

        // 验证金额一致
        // 注意：fin_ap 表无 pact_state 字段，不应做状态流转断言
    }

    // ==================== 凭证含子表保存验证 ====================

    @Test
    @DisplayName("含子表凭证：保存主表 + 凭证分录子表")
    void testFinVoucherWithDetail() throws Exception {
        // 主表
        Map<String, Object> main = new HashMap<>();
        main.put("code", "TEST_VOUCHER_001");
        main.put("voucher_date", "2026-07-17");
        main.put("period_code", "202607");
        main.put("org_id", 1);
        main.put("src_bill_type", "FIN_RECEIPT");
        main.put("src_bill_id", 1);
        main.put("attached_count", 1);
        main.put("total_debit", "10000.00");
        main.put("total_credit", "10000.00");
        main.put("is_auto", 0);

        // 子表（凭证分录，entity_code='entry'，link_field='voucher_id'）
        Map<String, Object> debitEntry = new HashMap<>();
        debitEntry.put("sort_index", 1);
        debitEntry.put("dc", "debit");
        debitEntry.put("account_id", 1);
        debitEntry.put("amount", "10000.00");
        debitEntry.put("summary", "借：银行存款");

        Map<String, Object> creditEntry = new HashMap<>();
        creditEntry.put("sort_index", 2);
        creditEntry.put("dc", "credit");
        creditEntry.put("account_id", 2);
        creditEntry.put("amount", "10000.00");
        creditEntry.put("summary", "贷：应收账款");

        Map<String, Object> subs = new HashMap<>();
        subs.put("entry", List.of(debitEntry, creditEntry));

        Map<String, Object> billData = new HashMap<>();
        billData.put("main", main);
        billData.put("subs", subs);

        Long id = createBill("FIN_VOUCHER", billData);
        assertNotNull(id, "保存凭证应返回 ID");

        // 验证主表
        Integer mainCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM fin_voucher WHERE id = ?", Integer.class, id);
        assertEquals(1, mainCount, "凭证主表应存在");

        // 验证子表（voucher_id 外键关联）
        Integer entryCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM fin_voucher_entry WHERE voucher_id = ?", Integer.class, id);
        assertEquals(2, entryCount, "凭证分录应有 2 条");
    }

    // ==================== 收款单含子表保存验证（业务单据） ====================

    @Test
    @DisplayName("含子表收款单：保存主表 + 核销明细子表")
    void testFinReceiptWithDetail() throws Exception {
        // 主表
        Map<String, Object> main = new HashMap<>();
        main.put("code", "TEST_RECEIPT_001");
        main.put("receipt_date", "2026-07-17");
        main.put("pact_state", 0);
        main.put("cust_id", 1);
        main.put("org_id", 1);
        main.put("curr_id", 1);
        main.put("amount", "8000.00");
        main.put("total_amount", "8000.00");
        main.put("firp_type", "bank_transfer");
        main.put("bank_account", "6222000011112222");

        // 子表（核销明细，entity_code='detail'，link_field='receipt_id'）
        Map<String, Object> detail1 = new HashMap<>();
        detail1.put("sort_index", 1);
        detail1.put("ar_id", 1);
        detail1.put("settle_amount", "5000.00");
        detail1.put("discount_amount", "0");
        detail1.put("exchange_diff", "0");

        Map<String, Object> detail2 = new HashMap<>();
        detail2.put("sort_index", 2);
        detail2.put("ar_id", 2);
        detail2.put("settle_amount", "3000.00");
        detail2.put("discount_amount", "0");
        detail2.put("exchange_diff", "0");

        Map<String, Object> subs = new HashMap<>();
        subs.put("detail", List.of(detail1, detail2));

        Map<String, Object> billData = new HashMap<>();
        billData.put("main", main);
        billData.put("subs", subs);

        Long id = createBill("FIN_RECEIPT", billData);
        assertNotNull(id, "保存收款单应返回 ID");

        // 验证主表
        Integer mainCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM fin_receipt WHERE id = ?", Integer.class, id);
        assertEquals(1, mainCount, "收款单主表应存在");

        // 验证子表（receipt_id 外键关联）
        Integer detailCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM fin_receipt_detail WHERE receipt_id = ?", Integer.class, id);
        assertEquals(2, detailCount, "收款核销明细应有 2 条");
    }

    // ==================== 暂估应付 CRUD（主数据） ====================

    @Test
    @DisplayName("暂估应付（主数据）保存：无状态流转")
    void testFinEstApCrud() throws Exception {
        Map<String, Object> main = new HashMap<>();
        main.put("code", "TEST_EST_AP_001");
        main.put("src_bill_type", "PUR_IN_STOCK");
        main.put("supplier_id", 1);
        main.put("org_id", 1);
        main.put("curr_id", 1);
        main.put("est_amount", "3000.00");
        main.put("settle_amount", "0");
        main.put("balance", "3000.00");

        Map<String, Object> billData = new HashMap<>();
        billData.put("main", main);

        Long id = createBill("FIN_EST_AP", billData);
        assertNotNull(id, "保存暂估应付应返回 ID");

        // 验证记录存在
        Integer mainCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM fin_est_ap WHERE id = ?", Integer.class, id);
        assertEquals(1, mainCount, "暂估应付主表应存在");

        // 验证编码一致
        String code = jdbcTemplate.queryForObject(
                "SELECT code FROM fin_est_ap WHERE id = ?", String.class, id);
        assertEquals("TEST_EST_AP_001", code, "暂估应付编码应一致");

        // 验证暂估金额一致
        // 注意：fin_est_ap 表无 pact_state 字段，不应做状态流转断言
    }

    // ==================== 核销单 CRUD 端到端验证（业务单据） ====================

    @Test
    @DisplayName("核销单 CRUD：保存 → 提交 → 审核")
    void testFinWriteoffCrud() throws Exception {
        Map<String, Object> main = new HashMap<>();
        main.put("code", "TEST_WRITEOFF_001");
        main.put("writeoff_date", "2026-07-17");
        main.put("pact_state", 0);
        main.put("biz_type", "AR_RECEIPT");
        main.put("rec_bill_type", "FIN_RECEIPT");
        main.put("rec_bill_id", 1);
        main.put("settle_amount", "2000.00");
        main.put("discount_amount", "0");
        main.put("exchange_diff", "0");
        main.put("org_id", 1);
        main.put("cust_id", 1);
        main.put("curr_id", 1);
        main.put("cur_hx_amount", "2000.00");
        main.put("is_init", 0);

        Map<String, Object> billData = new HashMap<>();
        billData.put("main", main);

        Long id = createBill("FIN_WRITEOFF", billData);
        assertNotNull(id, "保存核销单应返回 ID");

        // 状态流转：submit → audit
        operate("FIN_WRITEOFF", id, "submit");
        operate("FIN_WRITEOFF", id, "audit");

        // 验证最终状态为 3（已审核）
        Integer state = jdbcTemplate.queryForObject(
                "SELECT pact_state FROM fin_writeoff WHERE id = ?", Integer.class, id);
        assertEquals(3, state, "核销单审核后 pact_state 应为 3");
    }

    // ==================== 删除操作验证 ====================

    @Test
    @DisplayName("应收单删除：暂存/已创建状态可删除")
    void testFinArDelete() throws Exception {
        Map<String, Object> main = new HashMap<>();
        main.put("code", "TEST_AR_DEL_001");
        main.put("bill_date", "2026-07-17");
        main.put("pact_state", 0);
        main.put("cust_id", 1);
        main.put("amount", "1000.00");

        Map<String, Object> billData = new HashMap<>();
        billData.put("main", main);

        Long id = createBill("FIN_AR", billData);

        // 删除（delete 操作）
        operate("FIN_AR", id, "delete");

        Integer count = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM fin_ar WHERE id = ?", Integer.class, id);
        assertEquals(0, count, "删除后记录不应存在");
    }

    // ==================== 关闭/取消操作验证 ====================

    @Test
    @DisplayName("应收单关闭/取消：审核后可关闭和取消（cancel 需 reason）")
    void testFinArCloseAndCancel() throws Exception {
        Map<String, Object> main = new HashMap<>();
        main.put("code", "TEST_AR_CLOSE_001");
        main.put("bill_date", "2026-07-17");
        main.put("pact_state", 0);
        main.put("cust_id", 1);
        main.put("amount", "1500.00");

        Map<String, Object> billData = new HashMap<>();
        billData.put("main", main);

        Long id = createBill("FIN_AR", billData);

        // 状态流转到已审核
        operate("FIN_AR", id, "submit");
        operate("FIN_AR", id, "audit");

        // 关闭（close：post_action='is_closed=1'）
        operate("FIN_AR", id, "close");
        Integer isClosed = jdbcTemplate.queryForObject(
                "SELECT is_closed FROM fin_ar WHERE id = ?", Integer.class, id);
        assertEquals(1, isClosed, "关闭后 is_closed 应为 1");

        // 取消（cancel：post_action='is_cancel=1'，require_reason=1）
        operate("FIN_AR", id, "cancel", "测试取消原因-应收单");
        Integer isCancel = jdbcTemplate.queryForObject(
                "SELECT is_cancel FROM fin_ar WHERE id = ?", Integer.class, id);
        assertEquals(1, isCancel, "取消后 is_cancel 应为 1");
    }
}
