package com.eerp.bos.rule;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.eerp.common.exception.ServiceException;
import com.eerp.meta.rule.expr.ExprContext;
import com.eerp.meta.rule.expr.ExprEvaluator;
import com.eerp.meta.writeback.entity.MetaWritebackField;
import com.eerp.meta.writeback.entity.MetaWritebackRule;
import com.eerp.meta.writeback.mapper.MetaWritebackFieldMapper;
import com.eerp.meta.writeback.service.MetaWritebackRuleService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.regex.Pattern;

/**
 * 反写服务实现（@Service）。
 *
 * <p>对齐设计文档 08 §3.3.1 / §3.7。依赖 {@link MetaWritebackRuleService} 加载规则、
 * {@link MetaWritebackFieldMapper} 加载字段映射、{@link JdbcTemplate} 查询/更新目标表、
 * {@link ExprEvaluator} 求源值与超限表达式。</p>
 *
 * <p>反写执行流程（{@link #doWriteback}）：</p>
 * <ol>
 *   <li>加载 meta_writeback_field（规则的字段映射）</li>
 *   <li>用 ExprEvaluator 从 exprCtx 取源单据字段值（writebackExpr）</li>
 *   <li>查目标单据当前值（SELECT target_field FROM target_table WHERE id=?）</li>
 *   <li>按 {@link WritebackMode} 计算：ADD/SUBTRACT/COVER</li>
 *   <li>超限检查：over_limit_expr + {@link WritebackOverLimitPolicy}（BLOCK/WARN/ALLOW）</li>
 *   <li>UPDATE target_table SET target_field=? WHERE id=?</li>
 * </ol>
 *
 * <p>SQL 注入防护：目标表名 / 字段名通过 {@link #IDENT_PATTERN} 校验为合法标识符
 * （复用 A1 LOOKUP 函数校验逻辑，对齐任务规范"防 SQL 注入"）。</p>
 */
@Service
public class WritebackServiceImpl extends AbstractWritebackService {

    private static final Logger log = LoggerFactory.getLogger(WritebackServiceImpl.class);

    /** 合法标识符正则（防 SQL 注入，复用 A1 LookupFunction 校验逻辑） */
    private static final Pattern IDENT_PATTERN = Pattern.compile("^[a-zA-Z_][a-zA-Z0-9_]*$");

    /** over_limit_expr 求值结果变量名（表达式中通过 $result 引用反写后的新值） */
    public static final String OVER_LIMIT_RESULT_VAR = "result";

    @Autowired
    private MetaWritebackRuleService metaWritebackRuleService;

    @Autowired
    private MetaWritebackFieldMapper metaWritebackFieldMapper;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Autowired
    private ExprEvaluator exprEvaluator;

    @Autowired
    private WritebackCompensationService compensationService;

    @Override
    protected List<MetaWritebackRule> loadRules(String srcBoCode, String operation) {
        LambdaQueryWrapper<MetaWritebackRule> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(MetaWritebackRule::getSrcBillType, srcBoCode)
                .eq(MetaWritebackRule::getTriggerOp, operation)
                .eq(MetaWritebackRule::getIsEnabled, 1);
        return metaWritebackRuleService.list(wrapper);
    }

    @Override
    protected void doWriteback(MetaWritebackRule rule, Long srcBillId, ExprContext exprCtx) {
        // 1. 加载字段映射
        List<MetaWritebackField> fields = metaWritebackFieldMapper.listByRuleCode(rule.getRuleCode());
        if (fields == null || fields.isEmpty()) {
            log.warn("反写规则[{}]未配置字段映射，跳过", rule.getRuleCode());
            return;
        }

        // 解析反写模式
        WritebackMode mode = WritebackMode.fromCode(rule.getWritebackMode());
        if (mode == null) {
            throw new ServiceException("WB_MODE_INVALID",
                    "反写规则[" + rule.getRuleCode() + "]模式无效: " + rule.getWritebackMode());
        }

        // 目标表名（按约定：target_bill_type 即为目标表名；可扩展为 bo_code -> table_name 映射）
        String targetTable = rule.getTargetBillType();
        validateIdentifier(targetTable, "目标表名");

        // 目标单据ID：从 exprCtx.rootData 中按 srcLinkField 反查 targetBillId
        // 简化实现：约定 rootData 中含 targetBillId 字段（由上层从 biz_bill_link 解析后注入）
        Long targetBillId = resolveTargetBillId(rule, exprCtx);
        if (targetBillId == null) {
            log.warn("反写规则[{}]未解析到目标单据ID，跳过。srcBillId={}", rule.getRuleCode(), srcBillId);
            return;
        }

        // 2. 逐字段处理
        for (MetaWritebackField field : fields) {
            processOneField(rule, field, mode, targetTable, targetBillId, exprCtx);
        }
    }

    /**
     * 处理单个字段映射：取源值 → 查目标当前值 → 按 mode 计算 → 超限检查 → UPDATE。
     */
    private void processOneField(MetaWritebackRule rule, MetaWritebackField field,
                                 WritebackMode mode, String targetTable, Long targetBillId,
                                 ExprContext exprCtx) {
        String targetField = field.getTargetField();
        validateIdentifier(targetField, "目标字段名");

        // 2.1 用 ExprEvaluator 从 exprCtx 取源单据字段值（writebackExpr 或 srcField）
        Number srcValue = resolveSourceValue(field, exprCtx);

        // 2.2 查目标单据当前值
        Number currentValue = queryTargetCurrentValue(targetTable, targetField, targetBillId);

        // 2.3 按 mode 计算新值
        Number newValue = mode.compute(currentValue, srcValue);

        // 2.4 超限检查
        checkOverLimit(rule, newValue, exprCtx);

        // 2.5 UPDATE 目标表
        String updateSql = "UPDATE " + targetTable + " SET " + targetField + " = ? WHERE id = ?";
        jdbcTemplate.update(updateSql, newValue, targetBillId);
        log.debug("反写成功: rule={}, table={}, field={}, targetBillId={}, cur={}, src={}, new={}",
                rule.getRuleCode(), targetTable, targetField, targetBillId,
                currentValue, srcValue, newValue);
    }

    /**
     * 用 ExprEvaluator 求源单据字段值。
     * <p>优先使用 writebackExpr（完整表达式），否则按 srcField 直接取字段值。</p>
     */
    private Number resolveSourceValue(MetaWritebackField field, ExprContext exprCtx) {
        Object srcVal;
        String writebackExpr = field.getWritebackExpr();
        if (writebackExpr != null && !writebackExpr.trim().isEmpty()) {
            // 表达式可能形如 "target_field = target_field + src_field"，需提取 RHS 求值
            // 简化：若表达式含 '='，取 '=' 之后的 RHS；否则整体作为表达式求值
            String expr = extractRhs(writebackExpr);
            srcVal = exprEvaluator.evaluate(expr, exprCtx);
        } else if (field.getSrcField() != null && !field.getSrcField().trim().isEmpty()) {
            // 直接按字段引用取值（$field 形式）
            String fieldRef = field.getSrcField().startsWith("$")
                    ? field.getSrcField() : "$" + field.getSrcField();
            srcVal = exprEvaluator.evaluate(fieldRef, exprCtx);
        } else {
            srcVal = 0;
        }
        return toNumber(srcVal);
    }

    /** 从 "target = expr" 形式中提取 RHS 表达式 */
    private String extractRhs(String writebackExpr) {
        int eq = writebackExpr.indexOf('=');
        if (eq < 0) {
            return writebackExpr;
        }
        // 跳过 '==' '!=' '>=' '<='
        if (eq + 1 < writebackExpr.length() && writebackExpr.charAt(eq + 1) == '=') {
            return writebackExpr;
        }
        return writebackExpr.substring(eq + 1).trim();
    }

    /**
     * 查目标单据当前值。
     * <p>SELECT target_field FROM target_table WHERE id = ?</p>
     */
    private Number queryTargetCurrentValue(String targetTable, String targetField, Long targetBillId) {
        String sql = "SELECT " + targetField + " FROM " + targetTable + " WHERE id = ?";
        try {
            Object val = jdbcTemplate.queryForObject(sql, Object.class, targetBillId);
            return toNumber(val);
        } catch (Exception e) {
            // 目标行不存在或字段为 null，按 0 处理
            return 0;
        }
    }

    /**
     * 超限检查：若配置了 over_limit_expr，按 policy 处理。
     * <p>表达式形如 "$result > 20"，将计算后的新值作为 $result 注入 exprCtx 变量后求值。
     * 表达式返回 true 表示超限。</p>
     */
    private void checkOverLimit(MetaWritebackRule rule, Number newValue, ExprContext exprCtx) {
        WritebackOverLimitPolicy policy = WritebackOverLimitPolicy.fromCode(rule.getOverControl());
        if (policy == null || policy == WritebackOverLimitPolicy.ALLOW) {
            return;
        }
        String overExpr = rule.getOverExpr();
        if (overExpr == null || overExpr.trim().isEmpty()) {
            return;
        }
        // 将新值作为 $result 变量注入上下文
        exprCtx.setVariable(OVER_LIMIT_RESULT_VAR, newValue);
        boolean overLimit;
        try {
            Object result = exprEvaluator.evaluate(overExpr, exprCtx);
            overLimit = isTruthy(result);
        } catch (Exception e) {
            // 超限表达式求值异常按 BLOCK 处理（保守策略）
            log.warn("反写规则[{}]超限表达式求值异常，按 BLOCK 处理: {}", rule.getRuleCode(), e.getMessage());
            throw new ServiceExceptionBlock("反写超限校验异常: " + e.getMessage());
        }
        if (overLimit) {
            String msg = "反写超限: rule=" + rule.getRuleCode() + ", newValue=" + newValue;
            if (policy == WritebackOverLimitPolicy.BLOCK) {
                // 抛 ServiceException 触发事务回滚
                throw new ServiceExceptionBlock(msg);
            } else {
                // WARN：记录日志并通过父类 addWarning 收集到 WritebackResult.warnings
                log.warn(msg);
                addWarning(msg);
            }
        }
    }

    /**
     * 解析目标单据ID。
     * <p>约定：exprCtx.rootData 中含 {@code targetBillId} 字段（由上层从 biz_bill_link 解析后注入）；
     * 或通过 target_link_field 配置从 rootData 中按同名 key 取值。</p>
     */
    private Long resolveTargetBillId(MetaWritebackRule rule, ExprContext exprCtx) {
        // 优先从 rootData.targetBillId 取（约定注入字段）
        Object val = exprCtx.getFieldValue("targetBillId");
        if (val == null && rule.getTargetLinkField() != null) {
            // 按 targetLinkField 从 rootData 取
            String fieldRef = rule.getTargetLinkField().startsWith("$")
                    ? rule.getTargetLinkField() : "$" + rule.getTargetLinkField();
            Object evaluated = exprEvaluator.evaluate(fieldRef, exprCtx);
            val = evaluated;
        }
        return toLong(val);
    }

    /** ASYNC 失败记录到 biz_writeback_log（覆盖父类空实现） */
    @Override
    protected void recordAsyncFailure(MetaWritebackRule rule, Long srcBillId, String errorMsg) {
        try {
            compensationService.recordFailure(
                    rule.getId(), rule.getRuleCode(), srcBillId, rule.getSrcBillType(), errorMsg);
        } catch (Exception e) {
            log.error("记录反写补偿日志失败: ruleCode={}, srcBillId={}, error={}",
                    rule.getRuleCode(), srcBillId, e.getMessage(), e);
        }
    }

    // ============ 工具方法 ============

    /** 校验标识符（防 SQL 注入） */
    private void validateIdentifier(String identifier, String label) {
        if (identifier == null || !IDENT_PATTERN.matcher(identifier).matches()) {
            throw new ServiceException("WB_INVALID_IDENTIFIER",
                    label + "必须为合法标识符（字母/数字/下划线，首字符非数字）: " + identifier);
        }
    }

    /** 转为 Number（null 视为 0） */
    private Number toNumber(Object o) {
        if (o == null) {
            return 0d;
        }
        if (o instanceof Number) {
            return (Number) o;
        }
        if (o instanceof String) {
            try {
                return Double.valueOf((String) o);
            } catch (NumberFormatException e) {
                return 0d;
            }
        }
        if (o instanceof Boolean) {
            return ((Boolean) o) ? 1 : 0;
        }
        return 0d;
    }

    /** 转为 Long */
    private Long toLong(Object o) {
        if (o == null) {
            return null;
        }
        if (o instanceof Number) {
            return ((Number) o).longValue();
        }
        if (o instanceof String) {
            try {
                return Long.valueOf((String) o);
            } catch (NumberFormatException e) {
                return null;
            }
        }
        return null;
    }

    /** 判断求值结果是否为"真"（true / 非 0 数字 / 非空字符串） */
    private boolean isTruthy(Object result) {
        if (result == null) {
            return false;
        }
        if (result instanceof Boolean) {
            return (Boolean) result;
        }
        if (result instanceof Number) {
            return ((Number) result).doubleValue() != 0d;
        }
        if (result instanceof String) {
            return !((String) result).isEmpty();
        }
        return true;
    }
}
