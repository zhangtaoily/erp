package com.eerp.bos.rule;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.eerp.meta.rule.entity.MetaEntityRule;
import com.eerp.meta.rule.entity.MetaEntityRuleItem;
import com.eerp.meta.rule.expr.ExprContext;
import com.eerp.meta.rule.expr.ExprException;
import com.eerp.meta.rule.mapper.MetaEntityRuleItemMapper;
import com.eerp.meta.rule.service.MetaEntityRuleService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

/**
 * 规则引擎实现（@Service）。
 *
 * <p>对齐设计文档 08 §3.2.2 / §3.2.4。依赖 {@link MetaEntityRuleService} 加载规则与 items，
 * 委托 {@link RuleItemExecutor}（内含 {@link com.eerp.meta.rule.expr.ExprEvaluator}）求值。</p>
 *
 * <p>规则类型执行策略（按 {@link MetaEntityRule#getRuleType()} 分发）：</p>
 * <ul>
 *   <li>validate（校验）：item.actionExpr 求值返回 false 或抛 ExprException → 收集为 RuleViolation
 *       （severity 取 ERROR，block=true）</li>
 *   <li>linkage（联动）：执行赋值表达式（如 {@code $total = $qty * $price}），
 *       将新写入的变量同步回 exprCtx.rootData（对齐任务规范"更新 exprCtx 的 rootData"）</li>
 *   <li>aggregate（聚合）/ calc（计算）：执行聚合表达式（如 {@code SUM($detail.amount)}），
 *       结果写入 exprCtx 变量 {@code _aggregate_result} 供后续引用</li>
 *   <li>available（可用量）：按 validate 语义处理（条件 false 或抛异常 → violation）</li>
 * </ul>
 */
@Service
public class RuleEngineImpl extends AbstractRuleEngine {

    @Autowired
    private MetaEntityRuleService metaEntityRuleService;

    @Autowired
    private MetaEntityRuleItemMapper metaEntityRuleItemMapper;

    @Autowired
    private RuleItemExecutor ruleItemExecutor;

    /** aggregate/calc 执行后写入 ctx 的结果变量名 */
    public static final String AGGREGATE_RESULT_VAR = "_aggregate_result";

    @Override
    protected List<MetaEntityRule> loadRules(String boCode, String triggerEvent) {
        LambdaQueryWrapper<MetaEntityRule> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(MetaEntityRule::getBoCode, boCode)
                .eq(MetaEntityRule::getTriggerEvent, triggerEvent)
                .eq(MetaEntityRule::getIsEnabled, 1)
                .orderByAsc(MetaEntityRule::getPriority);
        List<MetaEntityRule> rules = metaEntityRuleService.list(wrapper);
        if (rules == null || rules.isEmpty()) {
            return rules;
        }
        // 填充每条规则的 items（按 item_seq 升序）
        for (MetaEntityRule rule : rules) {
            List<MetaEntityRuleItem> items = metaEntityRuleItemMapper.listByRuleCode(rule.getRuleCode());
            rule.setItems(items);
        }
        return rules;
    }

    @Override
    protected RuleViolation executeRule(MetaEntityRule rule, ExprContext exprCtx) {
        List<MetaEntityRuleItem> items = rule.getItems();
        if (items == null || items.isEmpty()) {
            return null;
        }
        String ruleType = rule.getRuleType() == null ? "" : rule.getRuleType().toLowerCase();
        // 按 ruleType 分发
        switch (ruleType) {
            case "validate":
            case "available":
                return executeValidateRule(rule, exprCtx);
            case "linkage":
                return executeLinkageRule(rule, exprCtx);
            case "calc":
            case "aggregate":
                return executeAggregateRule(rule, exprCtx);
            default:
                // 未知类型按 validate 语义处理（向后兼容）
                return executeValidateRule(rule, exprCtx);
        }
    }

    /**
     * 校验类规则：item.actionExpr 返回 false 或抛 ExprException → RuleViolation（block=true）。
     */
    private RuleViolation executeValidateRule(MetaEntityRule rule, ExprContext exprCtx) {
        for (MetaEntityRuleItem item : rule.getItems()) {
            try {
                Object result = ruleItemExecutor.execute(item, exprCtx);
                if (isFalsy(result)) {
                    // 条件不满足 → 校验失败
                    return buildViolation(rule, item, "ERROR", true);
                }
            } catch (ExprException ex) {
                // error() 函数或求值异常 → 校验失败
                return buildViolation(rule, item, "ERROR", true, ex.getErrorMessage());
            }
        }
        return null;
    }

    /**
     * 联动类规则：执行赋值表达式，将新增/变更的变量同步回 rootData。
     */
    private RuleViolation executeLinkageRule(MetaEntityRule rule, ExprContext exprCtx) {
        // 记录执行前的变量快照，便于识别新增/变更的变量
        Map<String, Object> varsBefore = new HashMap<>(exprCtx.getVariables());
        for (MetaEntityRuleItem item : rule.getItems()) {
            try {
                ruleItemExecutor.execute(item, exprCtx);
            } catch (ExprException ex) {
                return buildViolation(rule, item, "ERROR", true, ex.getErrorMessage());
            }
        }
        // 将赋值产生的新增/变更变量写回 rootData（任务规范：更新 exprCtx 的 rootData）
        syncVariablesToRootData(exprCtx, varsBefore);
        return null;
    }

    /**
     * 聚合/计算类规则：执行聚合表达式，结果写入 ctx 变量 {@link #AGGREGATE_RESULT_VAR}。
     */
    private RuleViolation executeAggregateRule(MetaEntityRule rule, ExprContext exprCtx) {
        for (MetaEntityRuleItem item : rule.getItems()) {
            try {
                Object result = ruleItemExecutor.execute(item, exprCtx);
                // 聚合结果写入上下文变量，供后续规则或上层引用
                if (result != null) {
                    exprCtx.setVariable(AGGREGATE_RESULT_VAR, result);
                }
            } catch (ExprException ex) {
                return buildViolation(rule, item, "ERROR", true, ex.getErrorMessage());
            }
        }
        return null;
    }

    /**
     * 将执行后新增/变更的变量同步回 rootData。
     * <p>ExprEvaluator 的赋值表达式只写入 ctx.variables，不直接修改 rootData。
     * 本方法在 linkage 规则执行后调用，识别 variables 中新增或值变更的 key，
     * 写入 rootData 使其可被上层访问（对齐任务规范"更新 exprCtx 的 rootData"）。</p>
     */
    private void syncVariablesToRootData(ExprContext exprCtx, Map<String, Object> varsBefore) {
        Map<String, Object> varsAfter = exprCtx.getVariables();
        Map<String, Object> rootData = exprCtx.getRootData();
        // 若 rootData 不可变（如 Collections.emptyMap()），创建可变副本
        Map<String, Object> mutableRoot = (rootData == null) ? new HashMap<>() : new HashMap<>(rootData);
        boolean changed = false;
        for (Map.Entry<String, Object> entry : varsAfter.entrySet()) {
            String key = entry.getKey();
            Object val = entry.getValue();
            Object oldVal = varsBefore.get(key);
            if (!Objects.equals(oldVal, val)) {
                mutableRoot.put(key, val);
                changed = true;
            }
        }
        if (changed) {
            exprCtx.setRootData(mutableRoot);
        }
    }

    /** 构造 RuleViolation（消息优先取 item.errorMsg，其次 rule.ruleName） */
    private RuleViolation buildViolation(MetaEntityRule rule, MetaEntityRuleItem item,
                                         String severity, boolean block) {
        return buildViolation(rule, item, severity, block, null);
    }

    private RuleViolation buildViolation(MetaEntityRule rule, MetaEntityRuleItem item,
                                         String severity, boolean block, String overrideMsg) {
        String message = overrideMsg;
        if (message == null || message.isEmpty()) {
            message = item.getErrorMsg();
        }
        if (message == null || message.isEmpty()) {
            message = "规则[" + rule.getRuleCode() + "]校验失败";
        }
        return new RuleViolation(rule.getRuleCode(), message, severity, block);
    }

    /** 判断求值结果是否为"假"（false / null / 0 / 空字符串） */
    private boolean isFalsy(Object result) {
        if (result == null) {
            return true;
        }
        if (result instanceof Boolean) {
            return !(Boolean) result;
        }
        if (result instanceof Number) {
            return ((Number) result).doubleValue() == 0d;
        }
        if (result instanceof String) {
            return ((String) result).isEmpty();
        }
        return false;
    }
}
