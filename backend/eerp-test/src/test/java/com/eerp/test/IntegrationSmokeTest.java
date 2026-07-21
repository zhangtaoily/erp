package com.eerp.test;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * 集成测试基座冒烟测试。
 *
 * <p>验证 Phase 0 基础设施：H2 内存数据库启动、schema-h2.sql 建表、data-h2-seed.sql 种子数据加载。
 * 通过此测试即证明后续业务模块集成测试可在此基座上运行。</p>
 */
@DisplayName("Phase 0 集成测试基座冒烟验证")
class IntegrationSmokeTest extends AbstractIntegrationTest {

    @Test
    @DisplayName("H2 表结构加载：核心元数据表可查询")
    void testCoreMetaTablesExist() {
        JdbcTemplate jdbc = jdbcTemplate;
        // 直接查询每张表 COUNT(*)，若表不存在会抛出异常
        for (String table : new String[]{
                "meta_business_object", "meta_form_entity", "meta_form_field",
                "meta_state_machine", "meta_state_node", "meta_state_transition",
                "meta_button", "meta_form_button", "meta_push_rule", "biz_bill_link",
                "meta_code_rule", "meta_form_plugin", "meta_plugin_param",
                "meta_entity_rule", "meta_entity_rule_item",
                "meta_writeback_rule", "meta_writeback_field",
                "meta_list_column", "meta_query_field", "meta_print_template",
                "sys_user", "sys_role", "sys_org", "sys_dept", "sys_employee",
                "md_customer", "md_supplier", "md_material", "md_currency", "md_warehouse", "md_unit"
        }) {
            Integer cnt = jdbc.queryForObject("SELECT COUNT(*) FROM " + table, Integer.class);
            assertTrue(cnt != null, "表 " + table + " 应可查询");
        }
    }

    @Test
    @DisplayName("种子数据：15 个标准按钮已加载")
    void testSeedButtons() {
        Integer count = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM meta_button", Integer.class);
        assertEquals(15, count, "meta_button 应有 15 条标准按钮");
    }

    @Test
    @DisplayName("种子数据：标准状态机 + 5 节点 + 17 流转已加载")
    void testSeedStateMachine() {
        Integer machineCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM meta_state_machine WHERE code = 'STD_5STATE'", Integer.class);
        assertEquals(1, machineCount, "应有 1 个 STD_5STATE 状态机");

        Integer nodeCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM meta_state_node n " +
                        "JOIN meta_state_machine m ON n.machine_id = m.id " +
                        "WHERE m.code = 'STD_5STATE'", Integer.class);
        assertEquals(5, nodeCount, "STD_5STATE 应有 5 个状态节点");

        Integer transitionCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM meta_state_transition t " +
                        "JOIN meta_state_machine m ON t.machine_id = m.id " +
                        "WHERE m.code = 'STD_5STATE'", Integer.class);
        assertEquals(17, transitionCount, "STD_5STATE 应有 17 条状态流转");
    }

    @Test
    @DisplayName("种子数据：测试主数据已加载")
    void testSeedMasterData() {
        // 组织
        assertEquals(1, jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM sys_org WHERE code = 'TEST_ORG'", Integer.class));
        // 部门 / 员工（data-h2-master-data-seed.sql 替换了最小化行并扩充至 5 行，用 >= 容纳扩展）
        assertTrue(jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM sys_dept", Integer.class) >= 2);
        assertTrue(jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM sys_employee", Integer.class) >= 2);
        // 用户
        assertEquals(1, jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM sys_user WHERE username = 'admin'", Integer.class));
        // 客户/供应商/物料
        assertTrue(jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM md_customer", Integer.class) >= 2);
        assertTrue(jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM md_supplier", Integer.class) >= 2);
        assertTrue(jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM md_material", Integer.class) >= 3);
        // 币别/仓库/单位
        assertTrue(jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM md_currency", Integer.class) >= 2);
        assertTrue(jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM md_warehouse", Integer.class) >= 2);
        assertTrue(jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM md_unit", Integer.class) >= 3);
    }

    @Test
    @DisplayName("H2 建表完整性：抽样各模块业务表可查询")
    void testTableCoverage() {
        // 抽样验证各模块业务表已建表（表名与 schema-h2.sql 实际定义一致）
        String[] sampleTables = {
                // 平台元数据
                "meta_business_object", "meta_form_field", "meta_state_transition", "meta_button",
                "meta_form_plugin", "meta_writeback_rule", "meta_print_template", "biz_bill_link",
                // 基础资料
                "md_customer", "md_supplier", "md_material", "md_currency", "md_warehouse", "md_unit",
                "md_brand", "md_color", "md_raw_material", "md_credit",
                // CRM 销售
                "sal_int_cont", "sal_cont", "sal_quote", "sal_order",
                "sal_delivery_notice", "sal_out_stock", "sal_ret_notice",
                // 采购
                "pur_apply", "pur_order", "pur_in_stock", "pur_return",
                // 库存
                "inv_stock", "inv_lock", "inv_transfer", "inv_stocktake",
                // 生产
                "mfg_bom", "mfg_order", "mfg_pick",
                // 财务
                "fin_ar", "fin_ap", "fin_receipt", "fin_payment",
                // 税务
                "tax_declaration", "tax_invoice_certify",
                // 系统管理/消息
                "sys_message", "sys_alert_rule"
        };
        int existing = 0;
        for (String t : sampleTables) {
            try {
                jdbcTemplate.queryForObject("SELECT COUNT(*) FROM " + t, Integer.class);
                existing++;
            } catch (Exception e) {
                // 不应发生
            }
        }
        assertEquals(sampleTables.length, existing,
                "抽样业务表应全部可查询，缺失 " + (sampleTables.length - existing) + " 张");
    }
}
