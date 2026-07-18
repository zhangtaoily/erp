package com.eerp.test;

import com.eerp.common.security.SecurityContext;
import com.eerp.common.security.SecurityContextHolder;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.AfterEach;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.util.HashMap;
import java.util.Map;

import java.nio.charset.StandardCharsets;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * 集成测试基类。
 *
 * <p>提供 H2 内存数据库 + MockMvc + JdbcTemplate 的集成测试基础设施。
 * 子类继承后可直接使用 {@link #mockMvc} / {@link #jdbcTemplate} 并调用辅助方法。</p>
 *
 * <p>所有子类自动应用 {@code test} profile（H2 数据源）与 {@link TestSecurityConfig}（放行所有请求）。</p>
 */
@SpringBootTest(classes = EerpTestApplication.class)
@ActiveProfiles("test")
@AutoConfigureMockMvc
public abstract class AbstractIntegrationTest {

    @Autowired
    protected MockMvc mockMvc;

    @Autowired
    protected JdbcTemplate jdbcTemplate;

    @Autowired
    protected ObjectMapper objectMapper;

    @BeforeEach
    void verifySeedDataLoaded() {
        // 验证种子数据已加载（meta_button 应有 15 条标准按钮）
        Integer count = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM meta_button", Integer.class);
        if (count == null || count == 0) {
            throw new IllegalStateException("种子数据未加载：meta_button 表为空");
        }
        // 初始化测试安全上下文（BillController.currentUser() 需要）
        ensureSecurityContext();
    }

    @AfterEach
    void clearSecurityContext() {
        SecurityContextHolder.clear();
    }

    // ============ 通用辅助方法 ============

    /**
     * 设置测试安全上下文。
     *
     * <p>JwtAuthenticationFilter 在每个 MockMvc 请求完成的 finally 块中会调用
     * {@link SecurityContextHolder#clear()}，导致同一测试方法内连续发起多个请求时，
     * 第二个请求的 SecurityContext 为 null，BillController.currentUser() 抛 "未登录"。
     * 故在每次 mockMvc.perform 前重新设置。</p>
     */
    protected void ensureSecurityContext() {
        SecurityContext ctx = new SecurityContext();
        ctx.setUserId(1L);
        ctx.setUserName("test-admin");
        SecurityContextHolder.set(ctx);
    }

    /**
     * 创建单据并返回单据 ID。
     *
     * @param boCode   业务对象编码
     * @param billData 单据数据（main/goods/assign 等结构）
     * @return 单据 ID
     */
    protected Long createBill(String boCode, Map<String, Object> billData) throws Exception {
        ensureSecurityContext();
        MvcResult result = mockMvc.perform(post("/api/bill/" + boCode)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(billData)))
                .andExpect(status().isOk())
                .andReturn();
        Map<String, Object> resp = objectMapper.readValue(
                result.getResponse().getContentAsString(StandardCharsets.UTF_8), Map.class);
        Object data = resp.get("data");
        if (data == null) {
            throw new IllegalStateException("创建单据失败：" + resp.get("message"));
        }
        return Long.valueOf(data.toString());
    }

    /**
     * 执行单据状态操作（submit/audit/reject/revoke/close/cancel/delete/enable/disable）。
     *
     * @param boCode    业务对象编码
     * @param billId    单据 ID
     * @param operation 操作名称
     */
    protected void operate(String boCode, Long billId, String operation) throws Exception {
        operate(boCode, billId, operation, null);
    }

    /**
     * 执行单据状态操作（支持 reason 参数，cancel/reject/change 等操作需要）。
     *
     * @param boCode    业务对象编码
     * @param billId    单据 ID
     * @param operation 操作名称
     * @param reason    操作原因（可为 null）
     */
    protected void operate(String boCode, Long billId, String operation, String reason) throws Exception {
        ensureSecurityContext();
        Map<String, Object> params = new HashMap<>();
        if (reason != null && !reason.isEmpty()) {
            params.put("reason", reason);
        }
        MvcResult result = mockMvc.perform(post("/api/bill/" + boCode + "/" + billId + "/" + operation)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(params)))
                .andExpect(status().isOk())
                .andReturn();
        // 检查业务成功（GlobalExceptionHandler 对所有错误返回 HTTP 200）
        Map<String, Object> resp = objectMapper.readValue(
                result.getResponse().getContentAsString(StandardCharsets.UTF_8), Map.class);
        Object code = resp.get("code");
        if (code != null && !"0".equals(code.toString())) {
            throw new IllegalStateException("操作失败 [" + operation + "]: " + resp.get("message"));
        }
    }

    /**
     * 获取单据明细。
     *
     * @param boCode 业务对象编码
     * @param billId 单据 ID
     * @return 单据明细 Map（含 main/goods 等）
     */
    protected Map<String, Object> getBillDetail(String boCode, Long billId) throws Exception {
        ensureSecurityContext();
        MvcResult result = mockMvc.perform(get("/api/bill/" + boCode + "/" + billId))
                .andExpect(status().isOk())
                .andReturn();
        Map<String, Object> resp = objectMapper.readValue(
                result.getResponse().getContentAsString(StandardCharsets.UTF_8), Map.class);
        return (Map<String, Object>) resp.get("data");
    }

    /**
     * 断言单据的 pact_state 字段值。
     *
     * @param mainTable     主表名
     * @param billId        单据 ID
     * @param expectedState 期望状态（0暂存/1已创建/2已提交/3已审核/4已驳回）
     */
    protected void assertPactState(String mainTable, Long billId, int expectedState) {
        Integer actualState = jdbcTemplate.queryForObject(
                "SELECT pact_state FROM " + mainTable + " WHERE id = ?",
                Integer.class, billId);
        org.junit.jupiter.api.Assertions.assertEquals(
                expectedState, actualState,
                "单据 " + mainTable + "#" + billId + " 状态应为 " + expectedState);
    }

    /**
     * 查询主表指定字段的值。
     *
     * @param mainTable 主表名
     * @param billId    单据 ID
     * @param fieldName 字段名
     * @return 字段值
     */
    protected Object getFieldValue(String mainTable, Long billId, String fieldName) {
        return jdbcTemplate.queryForObject(
                "SELECT " + fieldName + " FROM " + mainTable + " WHERE id = ?",
                Object.class, billId);
    }

    /**
     * 构造最小化的单据数据结构（main + goods）。
     *
     * @param mainFields 主表字段
     * @param goodsList  子表行列表
     * @return 完整单据数据 Map
     */
    protected static Map<String, Object> buildBillData(Map<String, Object> mainFields,
                                                       java.util.List<Map<String, Object>> goodsList) {
        Map<String, Object> billData = new HashMap<>();
        billData.put("main", mainFields);
        if (goodsList != null) {
            billData.put("goods", goodsList);
        }
        return billData;
    }
}
