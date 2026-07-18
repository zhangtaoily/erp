package com.eerp.test.master;

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
 * 基础资料模块集成测试（对齐设计文档 06）。
 *
 * <p>验证主数据元数据注册、CRUD 端到端流程、树形主数据操作。</p>
 *
 * <p>测试范围：</p>
 * <ul>
 *   <li>44 个主数据 bo_code 在 meta_business_object 中正确注册（30 基础资料 + 9 财务主数据 + 5 税务主数据）</li>
 *   <li>meta_form_entity 实体层级（主表 + 子表）配置完整</li>
 *   <li>meta_form_field 字段元数据可查询</li>
 *   <li>主数据 CRUD：通过 BillController 保存 → 查询详情 → 启用/停用</li>
 *   <li>树形主数据：组织树构建、子节点查询、环路检测</li>
 * </ul>
 */
@SpringBootTest(classes = EerpTestApplication.class)
@ActiveProfiles("test")
@AutoConfigureMockMvc
class MasterIntegrationTest extends AbstractIntegrationTest {

    // ==================== 元数据注册验证 ====================

    @Test
    @DisplayName("52 个主数据 bo_code 在 meta_business_object 中注册")
    void testMasterBoCodesRegistered() {
        Integer count = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM meta_business_object WHERE bo_type = 'master'", Integer.class);
        assertNotNull(count, "主数据 BO 计数不应为 null");
        assertEquals(52, count, "应注册 52 个主数据业务对象（30 基础资料 + 9 财务主数据 + 5 税务主数据 + 8 系统管理/消息）");
    }

    @Test
    @DisplayName("关键主数据 bo_code 注册正确")
    void testKeyBoCodesExist() {
        String[] expectedBoCodes = {
                "MD_ORG", "MD_DEPT", "MD_EMPLOYEE", "MD_CUSTOMER", "MD_SUPPLIER",
                "MD_MATERIAL", "MD_CURRENCY", "MD_WAREHOUSE", "MD_UNIT",
                "MD_CREDIT", "MD_SPIN_FEE", "SYS_DICT"
        };
        for (String boCode : expectedBoCodes) {
            Integer count = jdbcTemplate.queryForObject(
                    "SELECT COUNT(*) FROM meta_business_object WHERE bo_code = ?", Integer.class, boCode);
            assertEquals(1, count, "业务对象 " + boCode + " 应已注册");
        }
    }

    @Test
    @DisplayName("主数据 bo_type 全部为 master")
    void testAllMasterBoType() {
        Integer nonMasterCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM meta_business_object WHERE bo_type != 'master' " +
                        "AND bo_code LIKE 'MD_%'", Integer.class);
        assertEquals(0, nonMasterCount, "所有 MD_ 前缀的 bo_code 应为 master 类型");
    }

    @Test
    @DisplayName("主数据 is_stateful 全部为 0（无状态机）")
    void testAllMasterNotStateful() {
        Integer statefulCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM meta_business_object WHERE bo_type = 'master' AND is_stateful = 1", Integer.class);
        assertEquals(0, statefulCount, "主数据应全部无状态机（is_stateful=0）");
    }

    // ==================== 实体层级验证 ====================

    @Test
    @DisplayName("meta_form_entity 注册数量正确（30 MAIN + 5 SUB = 35）")
    void testFormEntityCount() {
        Integer totalCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM meta_form_entity WHERE bo_code LIKE 'MD_%' OR bo_code = 'SYS_DICT'", Integer.class);
        assertNotNull(totalCount);
        assertTrue(totalCount >= 35, "应至少注册 35 个实体（30 MAIN + 5 SUB），实际: " + totalCount);

        Integer mainCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM meta_form_entity WHERE entity_type = 'main' " +
                        "AND (bo_code LIKE 'MD_%' OR bo_code = 'SYS_DICT')", Integer.class);
        assertEquals(30, mainCount, "应注册 30 个主实体");
    }

    @Test
    @DisplayName("含子表的主数据 bo_code 实体层级正确")
    void testSubEntityRegistration() {
        // MD_RAW_MATERIAL 应有 1 个子表（md_raw_material_detail）
        Integer rawMatSubCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM meta_form_entity WHERE bo_code = 'MD_RAW_MATERIAL' AND entity_type = 'sub'",
                Integer.class);
        assertEquals(1, rawMatSubCount, "MD_RAW_MATERIAL 应有 1 个子表");

        // MD_SPIN_FEE 应有 2 个子表
        Integer spinFeeSubCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM meta_form_entity WHERE bo_code = 'MD_SPIN_FEE' AND entity_type = 'sub'",
                Integer.class);
        assertEquals(2, spinFeeSubCount, "MD_SPIN_FEE 应有 2 个子表");

        // MD_CREDIT 应有 1 个子表
        Integer creditSubCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM meta_form_entity WHERE bo_code = 'MD_CREDIT' AND entity_type = 'sub'",
                Integer.class);
        assertEquals(1, creditSubCount, "MD_CREDIT 应有 1 个子表");

        // SYS_DICT 应有 1 个子表
        Integer dictSubCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM meta_form_entity WHERE bo_code = 'SYS_DICT' AND entity_type = 'sub'",
                Integer.class);
        assertEquals(1, dictSubCount, "SYS_DICT 应有 1 个子表");
    }

    // ==================== 字段元数据验证 ====================

    @Test
    @DisplayName("meta_form_field 字段元数据已注册")
    void testFormFieldMetadataExists() {
        Integer fieldCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM meta_form_field WHERE bo_code LIKE 'MD_%' OR bo_code = 'SYS_DICT'",
                Integer.class);
        assertNotNull(fieldCount);
        assertTrue(fieldCount >= 150, "应至少注册 150 个字段元数据，实际: " + fieldCount);
    }

    @Test
    @DisplayName("MD_ORG 字段元数据包含关键字段")
    void testOrgFieldsRegistered() {
        List<String> fieldCodes = jdbcTemplate.queryForList(
                "SELECT field_code FROM meta_form_field WHERE bo_code = 'MD_ORG'", String.class);
        assertTrue(fieldCodes.contains("code"), "MD_ORG 应包含 code 字段");
        assertTrue(fieldCodes.contains("name"), "MD_ORG 应包含 name 字段");
    }

    // ==================== 主数据 CRUD 端到端验证 ====================

    @Test
    @DisplayName("主数据 CRUD：保存币别 → 查询详情 → 启用/停用")
    void testCurrencyCrud() throws Exception {
        // 1. 保存新币别
        Map<String, Object> main = new HashMap<>();
        main.put("code", "TEST_CUR");
        main.put("name", "测试币别");
        main.put("symbol", "TC");
        main.put("is_base", 0);
        main.put("decimal_digits", 2);
        main.put("status", 1);

        Map<String, Object> billData = new HashMap<>();
        billData.put("main", main);

        // 通过 BillController 保存
        Long id = createBill("MD_CURRENCY", billData);
        assertNotNull(id, "保存应返回 ID");

        // 2. 查询详情
        Map<String, Object> detail = getBillDetail("MD_CURRENCY", id);
        assertNotNull(detail, "详情不应为 null");
        Map<String, Object> mainData = (Map<String, Object>) detail.get("main");
        assertNotNull(mainData, "main 数据不应为 null");
        assertEquals("TEST_CUR", mainData.get("code"), "编码应一致");
        assertEquals("测试币别", mainData.get("name"), "名称应一致");

        // 3. 验证数据库中确实存在
        Integer dbCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM md_currency WHERE id = ?", Integer.class, id);
        assertEquals(1, dbCount, "数据库中应存在该记录");

        // 4. 停用
        operate("MD_CURRENCY", id, "disable");
        Integer status = jdbcTemplate.queryForObject(
                "SELECT status FROM md_currency WHERE id = ?", Integer.class, id);
        assertEquals(0, status, "停用后 status 应为 0");

        // 5. 启用
        operate("MD_CURRENCY", id, "enable");
        status = jdbcTemplate.queryForObject(
                "SELECT status FROM md_currency WHERE id = ?", Integer.class, id);
        assertEquals(1, status, "启用后 status 应为 1");
    }

    @Test
    @DisplayName("主数据 CRUD：保存品牌 → 查询列表 → 删除")
    void testBrandCrud() throws Exception {
        // 1. 保存品牌
        Map<String, Object> main = new HashMap<>();
        main.put("code", "TEST_BRAND");
        main.put("name", "测试品牌");
        main.put("status", 1);

        Map<String, Object> billData = new HashMap<>();
        billData.put("main", main);

        Long id = createBill("MD_BRAND", billData);
        assertNotNull(id, "保存应返回 ID");

        // 2. 验证存在
        String name = jdbcTemplate.queryForObject(
                "SELECT name FROM md_brand WHERE id = ?", String.class, id);
        assertEquals("测试品牌", name, "品牌名称应一致");

        // 3. 删除
        operate("MD_BRAND", id, "delete");

        // 4. 验证已删除
        Integer count = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM md_brand WHERE id = ?", Integer.class, id);
        assertEquals(0, count, "删除后记录不应存在");
    }

    @Test
    @DisplayName("主数据 CRUD：保存仓库 → 更新")
    void testWarehouseSaveAndUpdate() throws Exception {
        // 1. 保存
        Map<String, Object> main = new HashMap<>();
        main.put("code", "TEST_WH");
        main.put("name", "测试仓库");
        main.put("wh_type", "raw");
        main.put("batch_flag", 1);
        main.put("status", 1);

        Map<String, Object> billData = new HashMap<>();
        billData.put("main", main);

        Long id = createBill("MD_WAREHOUSE", billData);
        assertNotNull(id, "保存应返回 ID");

        // 2. 更新
        main.put("id", id);
        main.put("name", "测试仓库-已更新");
        createBill("MD_WAREHOUSE", billData);

        // 3. 验证更新
        String updatedName = jdbcTemplate.queryForObject(
                "SELECT name FROM md_warehouse WHERE id = ?", String.class, id);
        assertEquals("测试仓库-已更新", updatedName, "更新后名称应一致");
    }

    // ==================== 树形主数据验证 ====================

    @Test
    @DisplayName("树形主数据：保存组织 → 查询子节点")
    void testOrgTreeSave() throws Exception {
        // 1. 保存顶级组织
        Map<String, Object> parentMain = new HashMap<>();
        parentMain.put("code", "TEST_ORG_ROOT");
        parentMain.put("name", "测试根组织");
        parentMain.put("org_type", "company");
        parentMain.put("status", 1);

        Map<String, Object> billData = new HashMap<>();
        billData.put("main", parentMain);

        Long parentId = createBill("MD_ORG", billData);
        assertNotNull(parentId, "保存父组织应返回 ID");

        // 2. 保存子组织
        Map<String, Object> childMain = new HashMap<>();
        childMain.put("code", "TEST_ORG_CHILD");
        childMain.put("name", "测试子组织");
        childMain.put("org_type", "factory");
        childMain.put("parent_id", parentId);
        childMain.put("status", 1);

        billData.put("main", childMain);
        Long childId = createBill("MD_ORG", billData);
        assertNotNull(childId, "保存子组织应返回 ID");

        // 3. 验证父子关系
        Long dbParentId = jdbcTemplate.queryForObject(
                "SELECT parent_id FROM sys_org WHERE id = ?", Long.class, childId);
        assertEquals(parentId, dbParentId, "子组织的 parent_id 应指向父组织");

        // 4. 验证子节点查询
        Integer childCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM sys_org WHERE parent_id = ?", Integer.class, parentId);
        assertEquals(1, childCount, "父组织应有 1 个子节点");
    }

    // ==================== 含子表的主数据验证 ====================

    @Test
    @DisplayName("含子表主数据：保存信用管理 + 明细")
    void testCreditWithDetail() throws Exception {
        // 1. 保存信用管理主表
        Map<String, Object> main = new HashMap<>();
        main.put("code", "TEST_CREDIT");
        main.put("org_id", 1);
        main.put("is_group_credit", 0);
        main.put("cust_type", 0);

        // 2. 明细子表（BillDataAccessor.saveBill 从 billData["subs"][entity_code] 读取子表）
        Map<String, Object> detail = new HashMap<>();
        detail.put("cust_id", 1);
        detail.put("curr_id", 1);
        detail.put("amount", "100000.00");

        Map<String, Object> subs = new HashMap<>();
        subs.put("detail", List.of(detail));

        Map<String, Object> billData = new HashMap<>();
        billData.put("main", main);
        billData.put("subs", subs);

        Long id = createBill("MD_CREDIT", billData);
        assertNotNull(id, "保存信用管理应返回 ID");

        // 3. 验证主表
        Integer mainCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM md_credit WHERE id = ?", Integer.class, id);
        assertEquals(1, mainCount, "信用管理主表应存在");

        // 4. 验证子表
        Integer detailCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM md_credit_detail WHERE credit_id = ?", Integer.class, id);
        assertTrue(detailCount >= 1, "信用管理明细应至少 1 条");
    }

    // ==================== 数据字典验证 ====================

    @Test
    @DisplayName("数据字典：保存字典 + 字典项")
    void testDictSave() throws Exception {
        // 1. 保存字典
        Map<String, Object> main = new HashMap<>();
        main.put("dict_code", "TEST_DICT");
        main.put("dict_name", "测试字典");
        main.put("status", 1);

        // 2. 字典项（BillDataAccessor.saveBill 从 billData["subs"][entity_code] 读取子表）
        Map<String, Object> item1 = new HashMap<>();
        item1.put("item_code", "ITEM1");
        item1.put("item_name", "选项1");
        item1.put("sort_index", 1);
        item1.put("enabled", 1);

        Map<String, Object> subs = new HashMap<>();
        subs.put("item", List.of(item1));

        Map<String, Object> billData = new HashMap<>();
        billData.put("main", main);
        billData.put("subs", subs);

        Long id = createBill("SYS_DICT", billData);
        assertNotNull(id, "保存字典应返回 ID");

        // 3. 验证字典
        String dictName = jdbcTemplate.queryForObject(
                "SELECT dict_name FROM sys_dict WHERE id = ?", String.class, id);
        assertEquals("测试字典", dictName, "字典名称应一致");

        // 4. 验证字典项
        Integer itemCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM sys_dict_item WHERE dict_id = ?", Integer.class, id);
        assertEquals(1, itemCount, "应有 1 个字典项");
    }
}
