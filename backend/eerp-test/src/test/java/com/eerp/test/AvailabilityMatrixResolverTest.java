package com.eerp.test;

import com.eerp.bos.button.AvailabilityMatrixResolver;
import com.eerp.bos.button.ButtonAvailability;
import com.eerp.bos.button.ButtonLevel;
import com.eerp.meta.button.vo.ButtonDefVO;
import com.eerp.meta.cache.ButtonMetaCache;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.when;

/**
 * 按钮可用性矩阵解析器单元测试
 *
 * 验证三层责任链叠加逻辑：
 * 1. 状态机层：availability_json[pactState]
 * 2. 角色权限层：sys_role_button.control_level
 * 3. 业务层：is_closed / is_cancel 动态切换
 */
@ExtendWith(MockitoExtension.class)
class AvailabilityMatrixResolverTest {

    @Mock
    private ButtonMetaCache buttonMetaCache;

    @Mock
    private JdbcTemplate jdbcTemplate;

    @InjectMocks
    private AvailabilityMatrixResolver resolver;

    private static final String BO_CODE = "SAL_ORDER";
    private static final Long USER_ID = 1001L;

    /** audit 按钮 availability_json：pactState=0 hidden, pactState=2 enabled */
    private static final String AUDIT_AVAILABILITY_JSON =
            "[\"hidden\",\"hidden\",\"enabled\",\"hidden\",\"hidden\"]";

    /** close 按钮 availability_json：所有状态 enabled（业务层控制） */
    private static final String CLOSE_AVAILABILITY_JSON =
            "[\"enabled\",\"enabled\",\"enabled\",\"enabled\",\"enabled\"]";

    // ==================== 状态机层测试 ====================

    @Test
    @DisplayName("状态机层：pactState=0 时 audit 按钮 HIDDEN")
    void testStateMachine_HiddenAtState0() {
        mockButtonCache("audit", "审核", AUDIT_AVAILABILITY_JSON, 10);
        mockRoleLevelEmpty();

        ButtonAvailability result = resolver.resolve(
                BO_CODE, "audit", 0, false, false, USER_ID);

        assertEquals(ButtonLevel.HIDDEN, result.getLevel(), "pactState=0 时 audit 应为 HIDDEN");
    }

    @Test
    @DisplayName("状态机层：pactState=2 时 audit 按钮 ENABLED")
    void testStateMachine_EnabledAtState2() {
        mockButtonCache("audit", "审核", AUDIT_AVAILABILITY_JSON, 10);
        mockRoleLevelEmpty();

        ButtonAvailability result = resolver.resolve(
                BO_CODE, "audit", 2, false, false, USER_ID);

        assertEquals(ButtonLevel.ENABLED, result.getLevel(), "pactState=2 时 audit 应为 ENABLED");
    }

    // ==================== 角色权限层测试 ====================

    @Test
    @DisplayName("角色权限层：用户无 audit 权限时 DISABLED")
    void testRolePermission_Disabled() {
        // 状态机层在 pactState=2 时 ENABLED，角色层 DISABLED，叠加后应 DISABLED
        mockButtonCache("audit", "审核", AUDIT_AVAILABILITY_JSON, 10);
        mockRoleLevel("audit", "disabled");

        ButtonAvailability result = resolver.resolve(
                BO_CODE, "audit", 2, false, false, USER_ID);

        assertEquals(ButtonLevel.DISABLED, result.getLevel(), "用户无 audit 权限时应为 DISABLED");
    }

    @Test
    @DisplayName("角色权限层：用户无配置时默认 ENABLED")
    void testRolePermission_DefaultEnabled() {
        mockButtonCache("audit", "审核", AUDIT_AVAILABILITY_JSON, 10);
        mockRoleLevelEmpty();

        ButtonAvailability result = resolver.resolve(
                BO_CODE, "audit", 2, false, false, USER_ID);

        assertEquals(ButtonLevel.ENABLED, result.getLevel(), "无角色配置时默认 ENABLED");
    }

    // ==================== 业务层测试 ====================

    @Test
    @DisplayName("业务层：is_closed=true 时 close DISABLED + label「已关闭」")
    void testBusiness_CloseDisabledWhenClosed() {
        mockButtonCache("close", "关闭", CLOSE_AVAILABILITY_JSON, 50);
        mockRoleLevelEmpty();

        ButtonAvailability result = resolver.resolve(
                BO_CODE, "close", 3, true, false, USER_ID);

        assertEquals(ButtonLevel.DISABLED, result.getLevel(), "is_closed=true 时 close 应为 DISABLED");
        assertEquals("已关闭", result.getLabel(), "label 应为「已关闭」");
    }

    @Test
    @DisplayName("业务层：is_closed=false 时 close ENABLED + label「关闭」")
    void testBusiness_CloseEnabledWhenNotClosed() {
        mockButtonCache("close", "关闭", CLOSE_AVAILABILITY_JSON, 50);
        mockRoleLevelEmpty();

        ButtonAvailability result = resolver.resolve(
                BO_CODE, "close", 3, false, false, USER_ID);

        assertEquals(ButtonLevel.ENABLED, result.getLevel(), "is_closed=false 时 close 应为 ENABLED");
        assertEquals("关闭", result.getLabel(), "label 应为「关闭」");
    }

    @Test
    @DisplayName("业务层：is_cancel=true 时 cancel DISABLED")
    void testBusiness_CancelDisabledWhenCancelled() {
        mockButtonCache("cancel", "取消", CLOSE_AVAILABILITY_JSON, 60);
        mockRoleLevelEmpty();

        ButtonAvailability result = resolver.resolve(
                BO_CODE, "cancel", 3, false, true, USER_ID);

        assertEquals(ButtonLevel.DISABLED, result.getLevel(), "is_cancel=true 时 cancel 应为 DISABLED");
    }

    // ==================== 三层叠加测试 ====================

    @Test
    @DisplayName("三层叠加取最严：状态机 ENABLED + 角色 DISABLED + 业务 ENABLED = DISABLED")
    void testThreeLayerMerge_StrictestWins() {
        // audit 在 pactState=2 时状态机 ENABLED
        // 角色权限 DISABLED
        // 业务层无特殊处理（audit 非 close/cancel），ENABLED
        // 叠加结果应为 DISABLED
        mockButtonCache("audit", "审核", AUDIT_AVAILABILITY_JSON, 10);
        mockRoleLevel("audit", "disabled");

        ButtonAvailability result = resolver.resolve(
                BO_CODE, "audit", 2, false, false, USER_ID);

        assertEquals(ButtonLevel.DISABLED, result.getLevel(),
                "三层叠加：ENABLED + DISABLED + ENABLED = DISABLED");
        assertNotNull(result.getReason(), "禁用原因不应为空");
    }

    @Test
    @DisplayName("三层叠加：状态机 HIDDEN 优先级最高")
    void testThreeLayerMerge_HiddenIsStrictest() {
        // pactState=0 时状态机 HIDDEN，角色 DISABLED，业务 ENABLED
        // 叠加结果应为 HIDDEN
        mockButtonCache("audit", "审核", AUDIT_AVAILABILITY_JSON, 10);
        mockRoleLevel("audit", "disabled");

        ButtonAvailability result = resolver.resolve(
                BO_CODE, "audit", 0, false, false, USER_ID);

        assertEquals(ButtonLevel.HIDDEN, result.getLevel(),
                "三层叠加：HIDDEN + DISABLED + ENABLED = HIDDEN");
    }

    // ==================== resolveAll 测试 ====================

    @Test
    @DisplayName("resolveAll：返回该 bo 全部按钮可用性")
    void testResolveAll() {
        List<ButtonDefVO> buttons = new ArrayList<>();
        buttons.add(buildButton("audit", "审核", AUDIT_AVAILABILITY_JSON, 10));
        buttons.add(buildButton("close", "关闭", CLOSE_AVAILABILITY_JSON, 50));
        buttons.add(buildButton("cancel", "取消", CLOSE_AVAILABILITY_JSON, 60));
        lenient().when(buttonMetaCache.get(BO_CODE)).thenReturn(buttons);
        mockRoleLevelEmpty();

        List<ButtonAvailability> result = resolver.resolveAll(
                BO_CODE, 2, false, false, USER_ID);

        assertNotNull(result, "resolveAll 不应返回 null");
        assertEquals(3, result.size(), "应返回 3 个按钮可用性");

        // 验证每个按钮都被解析
        ButtonAvailability audit = findByCode(result, "audit");
        ButtonAvailability close = findByCode(result, "close");
        ButtonAvailability cancel = findByCode(result, "cancel");
        assertNotNull(audit, "audit 按钮应存在");
        assertNotNull(close, "close 按钮应存在");
        assertNotNull(cancel, "cancel 按钮应存在");

        // pactState=2 时 audit 状态机 ENABLED，无角色配置，业务无限制 → ENABLED
        assertEquals(ButtonLevel.ENABLED, audit.getLevel(), "audit 在 pactState=2 应为 ENABLED");
        // close 在 is_closed=false 时 ENABLED + label「关闭」
        assertEquals(ButtonLevel.ENABLED, close.getLevel(), "close 在 is_closed=false 应为 ENABLED");
        assertEquals("关闭", close.getLabel(), "close label 应为「关闭」");
    }

    // ==================== 辅助方法 ====================

    private ButtonDefVO buildButton(String code, String name, String availabilityJson, int sort) {
        ButtonDefVO vo = new ButtonDefVO();
        vo.setBoCode(BO_CODE);
        vo.setButtonCode(code);
        vo.setButtonName(name);
        vo.setAvailabilityJson(availabilityJson);
        vo.setSortIndex(sort);
        return vo;
    }

    private void mockButtonCache(String buttonCode, String buttonName,
                                  String availabilityJson, int sort) {
        List<ButtonDefVO> buttons = Collections.singletonList(
                buildButton(buttonCode, buttonName, availabilityJson, sort));
        lenient().when(buttonMetaCache.get(BO_CODE)).thenReturn(buttons);
    }

    /** mock 角色权限查询返回空列表（无配置 = ENABLED） */
    private void mockRoleLevelEmpty() {
        lenient().when(jdbcTemplate.queryForList(anyString(), eq(String.class), any(Object[].class)))
                .thenReturn(Collections.emptyList());
    }

    /** mock 指定按钮的角色权限返回指定档位列表 */
    private void mockRoleLevel(String buttonCode, String... levels) {
        when(jdbcTemplate.queryForList(anyString(), eq(String.class),
                eq(USER_ID), eq(BO_CODE), eq(buttonCode)))
                .thenReturn(Arrays.asList(levels));
    }

    private ButtonAvailability findByCode(List<ButtonAvailability> list, String code) {
        return list.stream()
                .filter(a -> code.equals(a.getButtonCode()))
                .findFirst()
                .orElse(null);
    }
}
