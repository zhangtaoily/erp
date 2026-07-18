package com.eerp.bos.button;

import com.eerp.meta.button.vo.ButtonDefVO;
import com.eerp.meta.cache.ButtonMetaCache;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * 按钮可用性矩阵解析器（责任链模式）
 *
 * 三层叠加取「最严」档位（HIDDEN > DISABLED > READONLY > ENABLED）：
 * 1. 状态机层：meta_form_button.availability_json[pactState]
 * 2. 角色权限层：sys_role_button（通过 sys_user_role 关联用户角色）
 * 3. 业务层：is_closed / is_cancel 动态切换 close / cancel 按钮档位与标签
 */
@Service
public class AvailabilityMatrixResolver {

    private static final Logger log = LoggerFactory.getLogger(AvailabilityMatrixResolver.class);

    /** 角色按钮权限查询 SQL（sys_role_button.control_level 字段） */
    private static final String SQL_ROLE_BUTTON_LEVEL =
            "SELECT rb.control_level FROM sys_role_button rb " +
            "JOIN sys_user_role ur ON rb.role_id = ur.role_id " +
            "WHERE ur.user_id = ? AND rb.bo_code = ? AND rb.button_code = ?";

    /** 业务层特殊处理的按钮编码 */
    private static final String BTN_CLOSE = "close";
    private static final String BTN_UNCLOSE = "unclose";
    private static final String BTN_CANCEL = "cancel";
    private static final String BTN_UNCANCEL = "uncancel";

    private static final ObjectMapper MAPPER = new ObjectMapper();

    @Autowired
    private ButtonMetaCache buttonMetaCache;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    /**
     * 解析单个按钮可用性
     *
     * @param boCode     业务对象编码
     * @param buttonCode 按钮编码
     * @param pactState  当前单据状态（0暂存/1已创建/2已提交/3已审核/4已驳回）
     * @param isClosed   是否已关闭
     * @param isCancel   是否已取消
     * @param userId     当前用户ID
     */
    public ButtonAvailability resolve(String boCode, String buttonCode, Integer pactState,
                                       Boolean isClosed, Boolean isCancel, Long userId) {
        ButtonDefVO buttonDef = findButtonDef(boCode, buttonCode);
        String buttonName = buttonDef != null ? buttonDef.getButtonName() : buttonCode;
        Integer orderNo = buttonDef != null && buttonDef.getSortIndex() != null
                ? buttonDef.getSortIndex() : 0;

        // 层1：状态机层（availability_json[pactState]）
        LevelResult stateResult = resolveStateLevel(buttonDef, pactState);

        // 层2：角色权限层（sys_role_button.control_level）
        LevelResult roleResult = resolveRoleLevel(boCode, buttonCode, userId);

        // 层3：业务层（is_closed / is_cancel 动态切换标签与档位）
        LevelResult bizResult = resolveBusinessLevel(buttonCode, isClosed, isCancel);

        // 三层叠加取最严档位
        ButtonLevel merged = ButtonLevel.strictest(stateResult.level,
                ButtonLevel.strictest(roleResult.level, bizResult.level));

        // 选取叠加后档位对应的 reason（优先业务层 > 角色层 > 状态机层）
        String reason = pickReason(merged, bizResult, roleResult, stateResult);

        // 标签：业务层对 close/cancel 有动态切换，否则使用按钮名
        String label = bizResult.label != null ? bizResult.label : buttonName;

        return buildAvailability(buttonCode, buttonName, merged, label, reason, orderNo);
    }

    /**
     * 解析该 bo 在当前状态下所有按钮的可用性（供前端工具栏渲染）
     */
    public List<ButtonAvailability> resolveAll(String boCode, Integer pactState,
                                                Boolean isClosed, Boolean isCancel, Long userId) {
        List<ButtonDefVO> buttons = buttonMetaCache.get(boCode);
        if (buttons == null || buttons.isEmpty()) {
            return Collections.emptyList();
        }
        List<ButtonAvailability> result = new ArrayList<>(buttons.size());
        for (ButtonDefVO btn : buttons) {
            result.add(resolve(boCode, btn.getButtonCode(), pactState, isClosed, isCancel, userId));
        }
        return result;
    }

    // ==================== 三层解析 ====================

    /**
     * 层1：状态机层——从 availability_json 按 pactState 取档位
     * 支持数组格式 ["hidden","enabled",...] 与对象格式 {"0":"hidden","1":"enabled",...}
     * 未配置或解析失败默认 ENABLED
     */
    private LevelResult resolveStateLevel(ButtonDefVO buttonDef, Integer pactState) {
        if (buttonDef == null || buttonDef.getAvailabilityJson() == null
                || buttonDef.getAvailabilityJson().trim().isEmpty()) {
            return LevelResult.of(ButtonLevel.ENABLED, null);
        }
        if (pactState == null) {
            return LevelResult.of(ButtonLevel.ENABLED, null);
        }
        try {
            JsonNode root = MAPPER.readTree(buttonDef.getAvailabilityJson());
            String code = null;
            if (root.isArray()) {
                // 数组格式：下标对应 pactState（0-4）
                if (pactState >= 0 && pactState < root.size()) {
                    JsonNode node = root.get(pactState);
                    if (node != null && !node.isNull()) {
                        code = node.asText();
                    }
                }
            } else if (root.isObject()) {
                // 对象格式：key 为 pactState 字符串
                JsonNode node = root.get(String.valueOf(pactState));
                if (node != null && !node.isNull()) {
                    code = node.asText();
                }
            }
            ButtonLevel level = ButtonLevel.fromCode(code);
            String reason = level == ButtonLevel.ENABLED ? null
                    : "状态[" + pactState + "]下按钮不可用";
            return LevelResult.of(level, reason);
        } catch (Exception e) {
            log.warn("解析 availability_json 失败, json={}, err={}",
                    buttonDef.getAvailabilityJson(), e.getMessage());
            return LevelResult.of(ButtonLevel.ENABLED, null);
        }
    }

    /**
     * 层2：角色权限层——查 sys_role_button 取该按钮的角色档位
     * 用户多角色时取「最宽松」档位（标准 RBAC：任一角色授予即生效）
     * 未配置默认 ENABLED
     */
    private LevelResult resolveRoleLevel(String boCode, String buttonCode, Long userId) {
        if (jdbcTemplate == null || userId == null) {
            return LevelResult.of(ButtonLevel.ENABLED, null);
        }
        try {
            List<String> levels = jdbcTemplate.queryForList(
                    SQL_ROLE_BUTTON_LEVEL, String.class, userId, boCode, buttonCode);
            if (levels == null || levels.isEmpty()) {
                // 未配置角色权限，默认 ENABLED
                return LevelResult.of(ButtonLevel.ENABLED, null);
            }
            // 多角色取最宽松档位
            ButtonLevel merged = null;
            for (String code : levels) {
                merged = ButtonLevel.mostPermissive(merged, ButtonLevel.fromCode(code));
            }
            String reason = merged == null || merged == ButtonLevel.ENABLED
                    ? null : "无操作权限";
            return LevelResult.of(merged, reason);
        } catch (Exception e) {
            log.warn("查询角色按钮权限失败, boCode={}, buttonCode={}, userId={}, err={}",
                    boCode, buttonCode, userId, e.getMessage());
            return LevelResult.of(ButtonLevel.ENABLED, null);
        }
    }

    /**
     * 层3：业务层——is_closed / is_cancel 动态切换 close / cancel 按钮档位与标签
     * - close：is_closed=true → DISABLED + 标签「已关闭」；is_closed=false → ENABLED + 标签「关闭」
     * - unclose：is_closed=true → ENABLED + 标签「反关闭」；is_closed=false → DISABLED + 标签「反关闭」
     * - cancel：is_cancel=true → DISABLED + 标签「已取消」；is_cancel=false → ENABLED + 标签「取消」
     * - uncancel：is_cancel=true → ENABLED + 标签「反取消」；is_cancel=false → DISABLED + 标签「反取消」
     */
    private LevelResult resolveBusinessLevel(String buttonCode, Boolean isClosed, Boolean isCancel) {
        boolean closed = Boolean.TRUE.equals(isClosed);
        boolean cancelled = Boolean.TRUE.equals(isCancel);

        if (BTN_CLOSE.equals(buttonCode)) {
            if (closed) {
                return LevelResult.of(ButtonLevel.DISABLED, "已关闭", "单据已关闭");
            }
            return LevelResult.of(ButtonLevel.ENABLED, "关闭", null);
        }
        if (BTN_UNCLOSE.equals(buttonCode)) {
            if (closed) {
                return LevelResult.of(ButtonLevel.ENABLED, "反关闭", null);
            }
            return LevelResult.of(ButtonLevel.DISABLED, "反关闭", "单据未关闭");
        }
        if (BTN_CANCEL.equals(buttonCode)) {
            if (cancelled) {
                return LevelResult.of(ButtonLevel.DISABLED, "已取消", "单据已取消");
            }
            return LevelResult.of(ButtonLevel.ENABLED, "取消", null);
        }
        if (BTN_UNCANCEL.equals(buttonCode)) {
            if (cancelled) {
                return LevelResult.of(ButtonLevel.ENABLED, "反取消", null);
            }
            return LevelResult.of(ButtonLevel.DISABLED, "反取消", "单据未取消");
        }
        // 非业务层特殊按钮，默认 ENABLED
        return LevelResult.of(ButtonLevel.ENABLED, null, null);
    }

    // ==================== 辅助方法 ====================

    private ButtonDefVO findButtonDef(String boCode, String buttonCode) {
        List<ButtonDefVO> buttons = buttonMetaCache.get(boCode);
        if (buttons == null || buttonCode == null) {
            return null;
        }
        for (ButtonDefVO btn : buttons) {
            if (buttonCode.equals(btn.getButtonCode())) {
                return btn;
            }
        }
        return null;
    }

    /**
     * 选取叠加后档位对应的 reason，优先级：业务层 > 角色层 > 状态机层
     */
    private String pickReason(ButtonLevel merged, LevelResult biz, LevelResult role, LevelResult state) {
        if (merged == ButtonLevel.ENABLED) {
            return null;
        }
        if (biz.level == merged && biz.reason != null) {
            return biz.reason;
        }
        if (role.level == merged && role.reason != null) {
            return role.reason;
        }
        if (state.level == merged && state.reason != null) {
            return state.reason;
        }
        return merged.getLabel();
    }

    private ButtonAvailability buildAvailability(String code, String name, ButtonLevel level,
                                                  String label, String reason, Integer orderNo) {
        ButtonAvailability a = new ButtonAvailability();
        a.setButtonCode(code);
        a.setButtonName(name);
        a.setLevel(level);
        a.setLabel(label);
        a.setReason(reason);
        a.setOrderNo(orderNo);
        return a;
    }

    /**
     * 层解析结果（档位 + 标签 + 原因）
     */
    private static class LevelResult {
        final ButtonLevel level;
        final String label;
        final String reason;

        private LevelResult(ButtonLevel level, String label, String reason) {
            this.level = level;
            this.label = label;
            this.reason = reason;
        }

        static LevelResult of(ButtonLevel level, String reason) {
            return new LevelResult(level, null, reason);
        }

        static LevelResult of(ButtonLevel level, String label, String reason) {
            return new LevelResult(level, label, reason);
        }
    }
}
