package com.eerp.bos.rule;

import com.eerp.meta.rule.entity.MetaEntityRule;
import com.eerp.meta.rule.expr.ExprContext;

import java.util.ArrayList;
import java.util.List;

/**
 * 规则引擎抽象基类（模板方法模式）。
 *
 * <p>对齐设计文档 08 §3.2.2。负责按 {@code boCode + triggerEvent} 加载规则（{@link #loadRules}），
 * 按 {@code priority} 升序串行执行（{@link #executeRule}），先于脚本插件执行
 * （对齐 project_memory 硬约束 + 设计文档 08 §2.1 / §3.5）。</p>
 *
 * <p>执行流程：</p>
 * <ol>
 *   <li>{@link #loadRules} 子类实现：查询启用的规则并按 priority 升序排序</li>
 *   <li>逐条调用 {@link #executeRule}（子类实现）：对每个 item 调 ExprEvaluator 求值</li>
 *   <li>收集返回的 {@link RuleViolation}，block=true 的 violation 由上层负责回滚事务</li>
 * </ol>
 */
public abstract class AbstractRuleEngine {

    /**
     * 加载并执行规则。
     *
     * @param boCode       业务对象编码
     * @param triggerEvent 触发事件（OnBeforeSave/OnAfterSave/OnBeforeSubmit/OnBeforeAudit/OnFieldValueChange）
     * @param exprCtx      表达式求值上下文（持有 rootData / subData / variables）
     * @return 违反列表（按规则 priority 顺序）；空列表表示全部通过
     */
    public List<RuleViolation> executeRules(String boCode, String triggerEvent, ExprContext exprCtx) {
        List<RuleViolation> violations = new ArrayList<>();
        List<MetaEntityRule> rules = loadRules(boCode, triggerEvent);
        if (rules == null || rules.isEmpty()) {
            return violations;
        }
        for (MetaEntityRule rule : rules) {
            RuleViolation violation = executeRule(rule, exprCtx);
            if (violation != null) {
                violations.add(violation);
            }
        }
        return violations;
    }

    /**
     * 加载规则列表（子类实现）。
     *
     * <p>约定：查询 {@code meta_entity_rule} where bo_code=? and trigger_event=? and is_enabled=1
     * order by priority asc，并填充每条规则的 items（{@link MetaEntityRule#getItems()}）。</p>
     *
     * @param boCode       业务对象编码
     * @param triggerEvent 触发事件
     * @return 规则列表（按 priority 升序）
     */
    protected abstract List<MetaEntityRule> loadRules(String boCode, String triggerEvent);

    /**
     * 执行单条规则（子类实现）。
     *
     * <p>遍历 {@link MetaEntityRule#getItems()}，对每个 item 调 ExprEvaluator 求值：
     * validate 类型返回 false 或抛 ExprException 收集为 RuleViolation；
     * linkage 类型执行赋值并更新 exprCtx.rootData；
     * aggregate 类型执行聚合并将结果写入 exprCtx。</p>
     *
     * @param rule    规则定义（含 items）
     * @param exprCtx 表达式上下文
     * @return 违反信息；规则通过返回 null
     */
    protected abstract RuleViolation executeRule(MetaEntityRule rule, ExprContext exprCtx);
}
