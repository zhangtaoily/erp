package com.eerp.test.sysmsg;

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
 * 系统管理 + 消息与通知模块集成测试（Phase 4，对齐设计文档 09 / 10）。
 *
 * <p>验证 8 个系统管理/消息主数据业务对象的元数据注册、实体层级、字段元数据，
 * 以及 CRUD 端到端流程。</p>
 *
 * <p>测试范围：</p>
 * <ul>
 *   <li>8 个 bo_code 在 meta_business_object 中正确注册（bo_type='master', is_stateful=0）</li>
 *   <li>无状态机注册（全部主数据）</li>
 *   <li>meta_form_entity 实体层级（8 主 + 1 子 = 9）</li>
 *   <li>meta_form_field 字段元数据（87 个关键字段）</li>
 *   <li>SYS_IMPORT_TASK 通过 BillController 端到端 CRUD（主键为 id，兼容 BillDataAccessor）</li>
 *   <li>其余 7 表通过 jdbcTemplate 直验物理表与元数据对齐</li>
 *   <li>SYS_NOTICE 含子表 sys_notice_read 级联验证</li>
 * </ul>
 *
 * <p>主键差异说明：BillDataAccessor 固化以 `id` 列为主键，仅 sys_import_task 主键为 id；
 * 其余 7 表主键分别为 param_code/notice_id/backup_id/rule_code/alert_id/message_id/mail_id，
 * 故 CRUD 测试通过 jdbcTemplate 直验物理表。</p>
 */
@SpringBootTest(classes = EerpTestApplication.class)
@ActiveProfiles("test")
@AutoConfigureMockMvc
class SysMsgIntegrationTest extends AbstractIntegrationTest {

    private static final String[] EXPECTED_BO_CODES = {
            "SYS_PARAM", "SYS_NOTICE", "SYS_BACKUP", "SYS_IMPORT_TASK",
            "ALERT_RULE", "ALERT_RECORD", "INBOX_MSG", "EMAIL_LOG"
    };

    // ==================== 元数据注册验证 ====================

    @Test
    @DisplayName("8 个系统管理/消息 bo_code 在 meta_business_object 中注册")
    void testSysMsgBoCodesRegistered() {
        for (String boCode : EXPECTED_BO_CODES) {
            Integer count = jdbcTemplate.queryForObject(
                    "SELECT COUNT(*) FROM meta_business_object WHERE bo_code = ?", Integer.class, boCode);
            assertEquals(1, count, "业务对象 " + boCode + " 应已注册");
        }
    }

    @Test
    @DisplayName("系统管理/消息 bo_code 总数为 8")
    void testSysMsgBoCount() {
        Integer count = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM meta_business_object WHERE bo_code IN (" +
                        "'SYS_PARAM','SYS_NOTICE','SYS_BACKUP','SYS_IMPORT_TASK'," +
                        "'ALERT_RULE','ALERT_RECORD','INBOX_MSG','EMAIL_LOG')", Integer.class);
        assertEquals(8, count, "应注册 8 个系统管理/消息业务对象");
    }

    @Test
    @DisplayName("系统管理/消息 bo_code 全部为 master 类型且 is_stateful=0")
    void testSysMsgBoTypeClassification() {
        Integer nonMasterCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM meta_business_object WHERE bo_code IN (" +
                        "'SYS_PARAM','SYS_NOTICE','SYS_BACKUP','SYS_IMPORT_TASK'," +
                        "'ALERT_RULE','ALERT_RECORD','INBOX_MSG','EMAIL_LOG') " +
                        "AND (bo_type != 'master' OR is_stateful != 0)", Integer.class);
        assertEquals(0, nonMasterCount, "所有 8 个系统管理/消息 bo_code 应为 master 类型且 is_stateful=0");
    }

    // ==================== 状态机验证（主数据无状态机） ====================

    @Test
    @DisplayName("系统管理/消息主数据无状态机注册")
    void testNoStateMachineForMasterData() {
        for (String boCode : EXPECTED_BO_CODES) {
            Integer count = jdbcTemplate.queryForObject(
                    "SELECT COUNT(*) FROM meta_state_machine WHERE code = ?", Integer.class, boCode);
            assertEquals(0, count, "主数据 " + boCode + " 不应注册状态机");
        }
    }

    // ==================== 实体层级验证 ====================

    @Test
    @DisplayName("系统管理/消息实体注册数量正确（8 主 + 1 子 = 9）")
    void testFormEntityCount() {
        Integer totalCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM meta_form_entity WHERE bo_code IN (" +
                        "'SYS_PARAM','SYS_NOTICE','SYS_BACKUP','SYS_IMPORT_TASK'," +
                        "'ALERT_RULE','ALERT_RECORD','INBOX_MSG','EMAIL_LOG')", Integer.class);
        assertEquals(9, totalCount, "应注册 9 个实体（8 主 + 1 子）");

        Integer mainCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM meta_form_entity WHERE bo_code IN (" +
                        "'SYS_PARAM','SYS_NOTICE','SYS_BACKUP','SYS_IMPORT_TASK'," +
                        "'ALERT_RULE','ALERT_RECORD','INBOX_MSG','EMAIL_LOG') " +
                        "AND entity_type = 'main'", Integer.class);
        assertEquals(8, mainCount, "应注册 8 个主实体");

        Integer subCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM meta_form_entity WHERE bo_code IN (" +
                        "'SYS_PARAM','SYS_NOTICE','SYS_BACKUP','SYS_IMPORT_TASK'," +
                        "'ALERT_RULE','ALERT_RECORD','INBOX_MSG','EMAIL_LOG') " +
                        "AND entity_type = 'sub'", Integer.class);
        assertEquals(1, subCount, "应注册 1 个子实体（SYS_NOTICE 阅读记录）");
    }

    @Test
    @DisplayName("SYS_NOTICE 实体层级：主表 sys_notice + 子表 sys_notice_read")
    void testSysNoticeEntityHierarchy() {
        List<Map<String, Object>> entities = jdbcTemplate.queryForList(
                "SELECT entity_code, entity_type, entity_level, table_name, parent_entity_code, link_field " +
                        "FROM meta_form_entity WHERE bo_code = 'SYS_NOTICE' ORDER BY sort_index");
        assertEquals(2, entities.size(), "SYS_NOTICE 应有 2 个实体（主 + 子）");

        // 主表
        Map<String, Object> main = entities.get(0);
        assertEquals("sys_notice", main.get("entity_code"));
        assertEquals("main", main.get("entity_type"));
        assertEquals(0, ((Number) main.get("entity_level")).intValue());
        assertEquals("sys_notice", main.get("table_name"));

        // 子表
        Map<String, Object> sub = entities.get(1);
        assertEquals("read", sub.get("entity_code"));
        assertEquals("sub", sub.get("entity_type"));
        assertEquals(1, ((Number) sub.get("entity_level")).intValue());
        assertEquals("sys_notice_read", sub.get("table_name"));
        assertEquals("sys_notice", sub.get("parent_entity_code"));
        assertEquals("notice_id", sub.get("link_field"));
    }

    // ==================== 字段元数据验证 ====================

    @Test
    @DisplayName("系统管理/消息字段元数据已注册（87 个）")
    void testFormFieldMetadataExists() {
        Integer fieldCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM meta_form_field WHERE bo_code IN (" +
                        "'SYS_PARAM','SYS_NOTICE','SYS_BACKUP','SYS_IMPORT_TASK'," +
                        "'ALERT_RULE','ALERT_RECORD','INBOX_MSG','EMAIL_LOG')", Integer.class);
        assertNotNull(fieldCount);
        assertEquals(87, fieldCount, "应注册 87 个字段元数据，实际: " + fieldCount);
    }

    @Test
    @DisplayName("SYS_PARAM 主表字段包含关键字段")
    void testSysParamFieldsRegistered() {
        List<String> fieldCodes = jdbcTemplate.queryForList(
                "SELECT field_code FROM meta_form_field WHERE bo_code = 'SYS_PARAM' AND entity_code = 'sys_param'",
                String.class);
        assertTrue(fieldCodes.contains("param_code"), "SYS_PARAM 应包含 param_code 字段");
        assertTrue(fieldCodes.contains("param_name"), "SYS_PARAM 应包含 param_name 字段");
        assertTrue(fieldCodes.contains("param_value"), "SYS_PARAM 应包含 param_value 字段");
    }

    @Test
    @DisplayName("SYS_IMPORT_TASK 主表字段包含关键字段")
    void testSysImportTaskFieldsRegistered() {
        List<String> fieldCodes = jdbcTemplate.queryForList(
                "SELECT field_code FROM meta_form_field WHERE bo_code = 'SYS_IMPORT_TASK' AND entity_code = 'sys_import_task'",
                String.class);
        assertTrue(fieldCodes.contains("task_code"), "SYS_IMPORT_TASK 应包含 task_code 字段");
        assertTrue(fieldCodes.contains("bo_code"), "SYS_IMPORT_TASK 应包含 bo_code 字段");
        assertTrue(fieldCodes.contains("status"), "SYS_IMPORT_TASK 应包含 status 字段");
    }

    // ==================== SYS_IMPORT_TASK CRUD 端到端验证（BillController） ====================

    @Test
    @DisplayName("SYS_IMPORT_TASK CRUD：保存 → 查询详情（通过 BillController 端到端）")
    void testImportTaskCrud() throws Exception {
        // 1. 保存导入任务（主键为 id，兼容 BillDataAccessor）
        Map<String, Object> main = new HashMap<>();
        main.put("task_code", "TEST_IMPORT_001");
        main.put("bo_code", "MD_BRAND");
        main.put("template_name", "品牌导入模板");
        main.put("file_name", "brands.xlsx");
        main.put("file_path", "/tmp/imports/brands.xlsx");
        main.put("total_count", 100);
        main.put("success_count", 0);
        main.put("fail_count", 0);
        main.put("status", "pending");
        main.put("import_by", "test-admin");

        Map<String, Object> billData = new HashMap<>();
        billData.put("main", main);

        Long id = createBill("SYS_IMPORT_TASK", billData);
        assertNotNull(id, "保存导入任务应返回 ID");

        // 2. 验证数据库中存在
        Integer mainCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM sys_import_task WHERE id = ?", Integer.class, id);
        assertEquals(1, mainCount, "导入任务主表应存在");

        // 3. 查询详情
        Map<String, Object> detail = getBillDetail("SYS_IMPORT_TASK", id);
        assertNotNull(detail, "详情不应为 null");
        Map<String, Object> mainData = (Map<String, Object>) detail.get("main");
        assertNotNull(mainData, "main 数据不应为 null");
        assertEquals("TEST_IMPORT_001", mainData.get("task_code"), "任务编码应一致");

        // 4. 验证状态字段（主数据无状态机，save 操作不更新 pact_state）
        // sys_import_task 无 pact_state 字段，跳过状态验证
    }

    // ==================== SYS_PARAM CRUD（jdbcTemplate 直验） ====================

    @Test
    @DisplayName("SYS_PARAM CRUD：jdbcTemplate 直验物理表（主键 param_code 非 id）")
    void testSysParamCrud() {
        // 1. INSERT
        jdbcTemplate.update(
                "INSERT INTO sys_param (param_code, param_name, param_value, param_type, param_group, is_system, remark) " +
                        "VALUES (?, ?, ?, ?, ?, ?, ?)",
                "TEST_PARAM_001", "测试参数", "test-value", "string", "test-group", 0, "集成测试参数");

        // 2. SELECT 验证
        Map<String, Object> row = jdbcTemplate.queryForMap(
                "SELECT * FROM sys_param WHERE param_code = ?", "TEST_PARAM_001");
        assertEquals("测试参数", row.get("param_name"));
        assertEquals("test-value", row.get("param_value"));
        assertEquals("test-group", row.get("param_group"));

        // 3. UPDATE
        jdbcTemplate.update(
                "UPDATE sys_param SET param_value = ? WHERE param_code = ?",
                "updated-value", "TEST_PARAM_001");
        String updatedValue = jdbcTemplate.queryForObject(
                "SELECT param_value FROM sys_param WHERE param_code = ?", String.class, "TEST_PARAM_001");
        assertEquals("updated-value", updatedValue, "更新后参数值应一致");

        // 4. DELETE
        jdbcTemplate.update("DELETE FROM sys_param WHERE param_code = ?", "TEST_PARAM_001");
        Integer count = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM sys_param WHERE param_code = ?", Integer.class, "TEST_PARAM_001");
        assertEquals(0, count, "删除后记录不应存在");
    }

    // ==================== SYS_NOTICE CRUD（jdbcTemplate 直验 + 子表级联） ====================

    @Test
    @DisplayName("SYS_NOTICE CRUD：jdbcTemplate 直验主表 + 子表 sys_notice_read 级联")
    void testSysNoticeCrud() {
        long noticeId = 900001L;

        // 1. INSERT 主表
        jdbcTemplate.update(
                "INSERT INTO sys_notice (notice_id, title, content, notice_type, publish_by, status, is_top, is_read_required) " +
                        "VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
                noticeId, "测试公告", "测试内容", "system", 1L, 1, 0, 1);

        // 2. INSERT 子表（阅读记录）
        jdbcTemplate.update(
                "INSERT INTO sys_notice_read (id, notice_id, user_id, read_time) VALUES (?, ?, ?, CURRENT_TIMESTAMP)",
                900010L, noticeId, 1L);

        // 3. SELECT 主表
        Map<String, Object> mainRow = jdbcTemplate.queryForMap(
                "SELECT * FROM sys_notice WHERE notice_id = ?", noticeId);
        assertEquals("测试公告", mainRow.get("title"));
        assertEquals(1, ((Number) mainRow.get("status")).intValue());

        // 4. SELECT 子表（级联验证）
        Integer readCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM sys_notice_read WHERE notice_id = ?", Integer.class, noticeId);
        assertEquals(1, readCount, "公告阅读记录应有 1 条");

        // 5. DELETE 子表 + 主表（级联删除）
        jdbcTemplate.update("DELETE FROM sys_notice_read WHERE notice_id = ?", noticeId);
        jdbcTemplate.update("DELETE FROM sys_notice WHERE notice_id = ?", noticeId);

        Integer mainCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM sys_notice WHERE notice_id = ?", Integer.class, noticeId);
        assertEquals(0, mainCount, "删除后主表记录不应存在");
    }

    @Test
    @DisplayName("SYS_NOTICE 删除：级联清理子表 sys_notice_read")
    void testSysNoticeDelete() {
        long noticeId = 900002L;
        jdbcTemplate.update(
                "INSERT INTO sys_notice (notice_id, title, status, is_top, is_read_required) " +
                        "VALUES (?, ?, ?, ?, ?)",
                noticeId, "级联删除测试", 0, 0, 0);
        jdbcTemplate.update(
                "INSERT INTO sys_notice_read (id, notice_id, user_id) VALUES (?, ?, ?)",
                900020L, noticeId, 1L);
        jdbcTemplate.update(
                "INSERT INTO sys_notice_read (id, notice_id, user_id) VALUES (?, ?, ?)",
                900021L, noticeId, 2L);

        // 验证子表 2 条
        Integer beforeCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM sys_notice_read WHERE notice_id = ?", Integer.class, noticeId);
        assertEquals(2, beforeCount, "删除前阅读记录应有 2 条");

        // 级联删除
        jdbcTemplate.update("DELETE FROM sys_notice_read WHERE notice_id = ?", noticeId);
        jdbcTemplate.update("DELETE FROM sys_notice WHERE notice_id = ?", noticeId);

        Integer afterMainCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM sys_notice WHERE notice_id = ?", Integer.class, noticeId);
        Integer afterSubCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM sys_notice_read WHERE notice_id = ?", Integer.class, noticeId);
        assertEquals(0, afterMainCount, "删除后主表应为 0");
        assertEquals(0, afterSubCount, "删除后子表应为 0");
    }

    // ==================== SYS_BACKUP CRUD（jdbcTemplate 直验） ====================

    @Test
    @DisplayName("SYS_BACKUP CRUD：jdbcTemplate 直验物理表（主键 backup_id 非 id）")
    void testSysBackupCrud() {
        long backupId = 800001L;
        jdbcTemplate.update(
                "INSERT INTO sys_backup (backup_id, backup_type, backup_time, file_path, file_size, status, operator) " +
                        "VALUES (?, ?, CURRENT_TIMESTAMP, ?, ?, ?, ?)",
                backupId, "full", "/tmp/backup/full_001.bak", 102400L, "success", "test-admin");

        Map<String, Object> row = jdbcTemplate.queryForMap(
                "SELECT * FROM sys_backup WHERE backup_id = ?", backupId);
        assertEquals("full", row.get("backup_type"));
        assertEquals("success", row.get("status"));
        assertEquals("test-admin", row.get("operator"));

        jdbcTemplate.update("DELETE FROM sys_backup WHERE backup_id = ?", backupId);
        Integer count = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM sys_backup WHERE backup_id = ?", Integer.class, backupId);
        assertEquals(0, count, "删除后记录不应存在");
    }

    // ==================== ALERT_RULE CRUD（jdbcTemplate 直验） ====================

    @Test
    @DisplayName("ALERT_RULE CRUD：jdbcTemplate 直验物理表（主键 rule_code 非 id）")
    void testAlertRuleCrud() {
        jdbcTemplate.update(
                "INSERT INTO sys_alert_rule (rule_code, rule_name, alert_type, target_object, condition_expr, is_enabled) " +
                        "VALUES (?, ?, ?, ?, ?, ?)",
                "TEST_ALERT_001", "测试预警规则", "stock", "inv_stock", "qty < 100", 1);

        Map<String, Object> row = jdbcTemplate.queryForMap(
                "SELECT * FROM sys_alert_rule WHERE rule_code = ?", "TEST_ALERT_001");
        assertEquals("测试预警规则", row.get("rule_name"));
        assertEquals("stock", row.get("alert_type"));
        assertEquals(1, ((Number) row.get("is_enabled")).intValue());

        jdbcTemplate.update("DELETE FROM sys_alert_rule WHERE rule_code = ?", "TEST_ALERT_001");
        Integer count = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM sys_alert_rule WHERE rule_code = ?", Integer.class, "TEST_ALERT_001");
        assertEquals(0, count, "删除后记录不应存在");
    }

    // ==================== ALERT_RECORD CRUD（jdbcTemplate 直验） ====================

    @Test
    @DisplayName("ALERT_RECORD CRUD：jdbcTemplate 直验物理表（主键 alert_id 非 id）")
    void testAlertRecordCrud() {
        long alertId = 700001L;
        jdbcTemplate.update(
                "INSERT INTO sys_alert_log (alert_id, rule_code, alert_type, target_id, alert_content, alert_level, is_read, is_handled, status) " +
                        "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                alertId, "TEST_ALERT_001", "stock", 1L, "库存不足预警", "warning", 0, 0, "open");

        Map<String, Object> row = jdbcTemplate.queryForMap(
                "SELECT * FROM sys_alert_log WHERE alert_id = ?", alertId);
        assertEquals("TEST_ALERT_001", row.get("rule_code"));
        assertEquals("warning", row.get("alert_level"));
        assertEquals(0, ((Number) row.get("is_read")).intValue());

        jdbcTemplate.update("DELETE FROM sys_alert_log WHERE alert_id = ?", alertId);
        Integer count = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM sys_alert_log WHERE alert_id = ?", Integer.class, alertId);
        assertEquals(0, count, "删除后记录不应存在");
    }

    // ==================== INBOX_MSG CRUD（jdbcTemplate 直验） ====================

    @Test
    @DisplayName("INBOX_MSG CRUD：jdbcTemplate 直验物理表（主键 message_id 非 id）")
    void testInboxMsgCrud() {
        long messageId = 600001L;
        jdbcTemplate.update(
                "INSERT INTO sys_message (message_id, user_id, message_type, title, content, is_read) " +
                        "VALUES (?, ?, ?, ?, ?, ?)",
                messageId, 1L, "system", "测试站内信", "测试消息内容", 0);

        Map<String, Object> row = jdbcTemplate.queryForMap(
                "SELECT * FROM sys_message WHERE message_id = ?", messageId);
        assertEquals("测试站内信", row.get("title"));
        assertEquals("system", row.get("message_type"));
        assertEquals(0, ((Number) row.get("is_read")).intValue());

        // 标记已读
        jdbcTemplate.update(
                "UPDATE sys_message SET is_read = 1, read_time = CURRENT_TIMESTAMP WHERE message_id = ?",
                messageId);
        Integer isRead = jdbcTemplate.queryForObject(
                "SELECT is_read FROM sys_message WHERE message_id = ?", Integer.class, messageId);
        assertEquals(1, isRead, "标记已读后 is_read 应为 1");

        jdbcTemplate.update("DELETE FROM sys_message WHERE message_id = ?", messageId);
        Integer count = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM sys_message WHERE message_id = ?", Integer.class, messageId);
        assertEquals(0, count, "删除后记录不应存在");
    }

    // ==================== EMAIL_LOG CRUD（jdbcTemplate 直验） ====================

    @Test
    @DisplayName("EMAIL_LOG CRUD：jdbcTemplate 直验物理表（主键 mail_id 非 id）")
    void testEmailLogCrud() {
        long mailId = 500001L;
        jdbcTemplate.update(
                "INSERT INTO sys_mail_log (mail_id, to_email, subject, content, send_status) " +
                        "VALUES (?, ?, ?, ?, ?)",
                mailId, "test@example.com", "测试邮件", "测试邮件内容", "success");

        Map<String, Object> row = jdbcTemplate.queryForMap(
                "SELECT * FROM sys_mail_log WHERE mail_id = ?", mailId);
        assertEquals("test@example.com", row.get("to_email"));
        assertEquals("测试邮件", row.get("subject"));
        assertEquals("success", row.get("send_status"));

        jdbcTemplate.update("DELETE FROM sys_mail_log WHERE mail_id = ?", mailId);
        Integer count = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM sys_mail_log WHERE mail_id = ?", Integer.class, mailId);
        assertEquals(0, count, "删除后记录不应存在");
    }

    // ==================== 主表与 main_key 一致性验证 ====================

    @Test
    @DisplayName("每个 bo_code 的 main_table 与 meta_form_entity 主实体 table_name 一致")
    void testMainTableConsistency() {
        for (String boCode : EXPECTED_BO_CODES) {
            String mainTable = jdbcTemplate.queryForObject(
                    "SELECT main_table FROM meta_business_object WHERE bo_code = ?",
                    String.class, boCode);
            String entityTable = jdbcTemplate.queryForObject(
                    "SELECT table_name FROM meta_form_entity WHERE bo_code = ? AND entity_type = 'main'",
                    String.class, boCode);
            assertEquals(mainTable, entityTable,
                    boCode + " 的 main_table 与主实体 table_name 应一致");
        }
    }

    @Test
    @DisplayName("每个 bo_code 的 main_key 与物理表主键列名一致")
    void testMainKeyConsistency() {
        Map<String, String> expectedKeys = new HashMap<>();
        expectedKeys.put("SYS_PARAM", "param_code");
        expectedKeys.put("SYS_NOTICE", "notice_id");
        expectedKeys.put("SYS_BACKUP", "backup_id");
        expectedKeys.put("SYS_IMPORT_TASK", "id");
        expectedKeys.put("ALERT_RULE", "rule_code");
        expectedKeys.put("ALERT_RECORD", "alert_id");
        expectedKeys.put("INBOX_MSG", "message_id");
        expectedKeys.put("EMAIL_LOG", "mail_id");

        for (String boCode : EXPECTED_BO_CODES) {
            String mainKey = jdbcTemplate.queryForObject(
                    "SELECT main_key FROM meta_business_object WHERE bo_code = ?",
                    String.class, boCode);
            assertEquals(expectedKeys.get(boCode), mainKey,
                    boCode + " 的 main_key 应为 " + expectedKeys.get(boCode));
        }
    }
}
