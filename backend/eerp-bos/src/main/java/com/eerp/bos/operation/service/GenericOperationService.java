package com.eerp.bos.operation.service;

import com.eerp.bos.bill.BillDataAccessor;
import com.eerp.common.id.SnowflakeIdGenerator;
import com.eerp.meta.bo.vo.FormMetaVO;
import com.eerp.meta.cache.FormMetaCache;
import com.eerp.meta.cache.StateMachineCache;
import com.eerp.meta.rule.expr.ExprContext;
import com.eerp.meta.statemachine.dto.StateTransitionResult;
import com.eerp.meta.statemachine.vo.StateMachineMetaVO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 通用操作编排服务实现（@Service，对齐设计文档 02 §3.5）。
 *
 * <p>继承 {@link AbstractOperationService} 的 6 阶段流水线模板，提供基于
 * {@link BillDataAccessor} + {@link JdbcTemplate} 的 JDBC 落库实现，
 * 替代 {@code GenericBillService} 的 Phase 1 简化路径。</p>
 *
 * <p>依赖：
 * <ul>
 *   <li>{@link BillDataAccessor}：动态 SQL 读写主子孙三表（完整保留）</li>
 *   <li>{@link JdbcTemplate}：状态字段 UPDATE + 操作日志 INSERT</li>
 *   <li>{@link FormMetaCache}：解析主表名</li>
 *   <li>{@link StateMachineCache}：解析状态字段名</li>
 *   <li>{@link SnowflakeIdGenerator}：操作日志 ID 生成</li>
 * </ul>
 * </p>
 */
@Service
public class GenericOperationService extends AbstractOperationService {

    @Autowired
    private BillDataAccessor billDataAccessor;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Autowired
    private FormMetaCache formMetaCache;

    @Autowired
    private StateMachineCache stateMachineCache;

    @Autowired
    private SnowflakeIdGenerator snowflakeIdGenerator;

    // ==================== 抽象钩子实现 ====================

    @Override
    protected Map<String, Object> loadBillData(OperationContext ctx) {
        // save 操作：直接使用 ctx.billData
        if (ctx.getBillId() == null) {
            return ctx.getBillData();
        }
        // operate 操作：从 DB 加载完整单据
        return billDataAccessor.loadBill(ctx.getBoCode(), ctx.getBillId());
    }

    @Override
    protected Long doSave(OperationContext ctx) {
        String boCode = ctx.getBoCode();
        Map<String, Object> billData = ctx.getBillData();
        Long billId = billDataAccessor.saveBill(boCode, billData);

        // 更新状态字段（draft→0 暂存，save→1 已创建）
        String stateField = resolveStateField(boCode);
        String mainTable = resolveMainTable(boCode);
        if (stateField != null && mainTable != null) {
            Integer toState = "draft".equals(ctx.getOperation()) ? 0 : 1;
            jdbcTemplate.update(
                    "UPDATE `" + mainTable + "` SET `" + stateField + "` = ? WHERE `id` = ?",
                    toState, billId);
        }
        return billId;
    }

    @Override
    protected void doStateChange(OperationContext ctx, StateTransitionResult transition) {
        String boCode = ctx.getBoCode();
        Long billId = ctx.getBillId();
        String operation = ctx.getOperation();
        Integer toState = transition.getToState();
        String stateField = resolveStateField(boCode);
        String mainTable = resolveMainTable(boCode);

        if (mainTable == null || stateField == null) {
            return;
        }

        // 构建 UPDATE SQL：状态字段 + is_closed/is_cancel（按操作类型）
        StringBuilder sql = new StringBuilder("UPDATE `").append(mainTable).append("` SET ");
        List<Object> params = new ArrayList<>();

        if (toState != null) {
            sql.append("`").append(stateField).append("` = ?");
            params.add(toState);
        }

        if ("close".equals(operation)) {
            if (!params.isEmpty()) {
                sql.append(", ");
            }
            sql.append("`is_closed` = 1");
        } else if ("cancel".equals(operation)) {
            if (!params.isEmpty()) {
                sql.append(", ");
            }
            sql.append("`is_cancel` = 1");
        }

        sql.append(" WHERE `id` = ?");
        params.add(billId);

        jdbcTemplate.update(sql.toString(), params.toArray());
    }

    @Override
    protected void doDelete(OperationContext ctx) {
        billDataAccessor.deleteBill(ctx.getBoCode(), ctx.getBillId());
    }

    @Override
    protected void doStatusChange(OperationContext ctx, int targetStatus) {
        String boCode = ctx.getBoCode();
        Long billId = ctx.getBillId();
        String mainTable = resolveMainTable(boCode);
        if (mainTable == null || billId == null) {
            return;
        }

        // 从元数据字段中查找状态字段名（status 或 enabled）
        String statusField = resolveStatusFieldName(boCode);
        if (statusField == null) {
            statusField = "status"; // 兜底默认
        }

        jdbcTemplate.update(
                "UPDATE `" + mainTable + "` SET `" + statusField + "` = ? WHERE `id` = ?",
                targetStatus, billId);
    }

    /**
     * 从主实体字段元数据中解析状态字段名（status 或 enabled）。
     */
    private String resolveStatusFieldName(String boCode) {
        FormMetaVO meta = formMetaCache.get(boCode);
        if (meta == null || meta.getEntities() == null) {
            return null;
        }
        for (com.eerp.meta.entity.dto.FormEntityDTO entity : meta.getEntities()) {
            if (entity.getFields() == null) {
                continue;
            }
            for (com.eerp.meta.field.entity.MetaFormField field : entity.getFields()) {
                String code = field.getFieldCode();
                if ("status".equals(code)) {
                    return "status";
                }
                if ("enabled".equals(code)) {
                    return "enabled";
                }
            }
        }
        return null;
    }

    @Override
    @SuppressWarnings("unchecked")
    protected ExprContext buildExprContext(OperationContext ctx, Map<String, Object> billData) {
        if (billData == null) {
            return new ExprContext();
        }
        Map<String, Object> main = (Map<String, Object>) billData.getOrDefault("main", new HashMap<>());
        Map<String, List<Map<String, Object>>> subs = (Map<String, List<Map<String, Object>>>)
                billData.getOrDefault("subs", new HashMap<>());
        return new ExprContext(main, subs);
    }

    @Override
    protected void recordOpLog(String boCode, Long billId, String billCode,
                               String opType, Integer fromState, Integer toState,
                               String remark, String userName) {
        long id = snowflakeIdGenerator.nextId();
        jdbcTemplate.update(
                "INSERT INTO biz_op_log (id, bo_code, bill_id, bill_code, op_type, from_state, to_state, op_remark, op_by, op_time) "
                        + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                id, boCode, billId, billCode, opType, fromState, toState, remark, userName, LocalDateTime.now());
    }

    @Override
    protected String resolveStateField(String boCode) {
        StateMachineMetaVO sm = stateMachineCache.get(boCode);
        if (sm == null || sm.getStateMachine() == null) {
            return null;
        }
        String sf = sm.getStateMachine().getStateField();
        return (sf == null || sf.isEmpty()) ? "pact_state" : sf;
    }

    @Override
    protected String resolveMainTable(String boCode) {
        FormMetaVO meta = formMetaCache.get(boCode);
        if (meta == null || meta.getBusinessObject() == null) {
            return null;
        }
        return meta.getBusinessObject().getMainTable();
    }

    @Override
    protected Integer readState(String boCode, Long billId, String stateField) {
        if (stateField == null || billId == null) {
            return null;
        }
        String mainTable = resolveMainTable(boCode);
        if (mainTable == null) {
            return null;
        }
        try {
            Map<String, Object> row = jdbcTemplate.queryForMap(
                    "SELECT `" + stateField + "` AS s FROM `" + mainTable + "` WHERE `id` = ?", billId);
            Object v = row.get("s");
            if (v == null) {
                return null;
            }
            if (v instanceof Number) {
                return ((Number) v).intValue();
            }
            return Integer.valueOf(v.toString());
        } catch (EmptyResultDataAccessException e) {
            return null;
        } catch (NumberFormatException e) {
            return null;
        }
    }

    @Override
    protected String readBillCode(String boCode, Long billId) {
        if (billId == null) {
            return null;
        }
        String mainTable = resolveMainTable(boCode);
        if (mainTable == null) {
            return null;
        }
        // 从字段元数据中解析业务编码字段（优先 code，其次以 _code 结尾的字段）
        String codeField = resolveBillCodeField(boCode);
        if (codeField == null) {
            return null; // 主表无编码字段，跳过（不影响主流程，仅日志记录）
        }
        try {
            Map<String, Object> row = jdbcTemplate.queryForMap(
                    "SELECT `" + codeField + "` AS c FROM `" + mainTable + "` WHERE `id` = ?", billId);
            Object v = row.get("c");
            return v == null ? null : v.toString();
        } catch (EmptyResultDataAccessException e) {
            return null;
        }
    }

    /**
     * 从主实体字段元数据中解析业务编码字段名。
     *
     * <p>优先匹配 field_code='code'；否则匹配以 '_code' 结尾的字段（如 dict_code、cust_code）。
     * 若主实体无编码字段，返回 null（readBillCode 跳过 DB 查询，避免列不存在异常）。</p>
     */
    private String resolveBillCodeField(String boCode) {
        FormMetaVO meta = formMetaCache.get(boCode);
        if (meta == null || meta.getEntities() == null) {
            return null;
        }
        String fallback = null;
        for (com.eerp.meta.entity.dto.FormEntityDTO entity : meta.getEntities()) {
            // 仅扫描主实体
            if (!"MAIN".equalsIgnoreCase(entity.getEntityType())
                    && (entity.getEntityLevel() == null || entity.getEntityLevel() != 0)) {
                continue;
            }
            if (entity.getFields() == null) {
                continue;
            }
            for (com.eerp.meta.field.entity.MetaFormField field : entity.getFields()) {
                String code = field.getFieldCode();
                if ("code".equals(code)) {
                    return "code";
                }
                if (fallback == null && code != null && code.endsWith("_code")) {
                    fallback = code;
                }
            }
        }
        return fallback;
    }
}
