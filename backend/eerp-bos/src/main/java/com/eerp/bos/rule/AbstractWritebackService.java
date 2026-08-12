package com.eerp.bos.rule;

import com.eerp.common.exception.ServiceException;
import com.eerp.meta.rule.expr.ExprContext;
import com.eerp.meta.writeback.entity.MetaWritebackRule;

import java.util.ArrayList;
import java.util.List;

/**
 * 反写服务抽象基类（模板方法模式）。
 *
 * <p>对齐设计文档 08 §3.3.1。按 {@code srcBoCode + operation} 加载反写规则（{@link #loadRules}），
 * 逐条执行反写（{@link #doWriteback}），支持 SYNC（事务内同步）/ ASYNC（事务后异步，失败补偿）两种模式
 * （对齐设计文档 08 §3.7 + project_memory 硬约束）。</p>
 *
 * <p>执行流程：</p>
 * <ol>
 *   <li>{@link #loadRules} 子类实现：查询启用的反写规则</li>
 *   <li>逐条调用 {@link #doWriteback}（子类实现）：加载字段映射 → 求源值 → 查目标当前值 →
 *       按 mode 计算 → 超限检查 → UPDATE 目标表</li>
 *   <li>SYNC 模式同步执行（失败抛 ServiceException 回滚）；ASYNC 模式失败记录到 biz_writeback_log</li>
 * </ol>
 */
public abstract class AbstractWritebackService {

    /** 当前执行线程的告警收集器（doWriteback 期间通过 {@link #addWarning} 写入，executeOneRule 收集到 result） */
    private static final ThreadLocal<List<String>> WARNINGS_HOLDER = ThreadLocal.withInitial(ArrayList::new);

    /**
     * 加载并执行反写规则。
     *
     * @param srcBoCode 源单据业务对象编码（下游单据）
     * @param srcBillId 源单据ID
     * @param operation 触发操作（save/delete/cancel/audit/revoke）
     * @param exprCtx   表达式上下文（持有源单据字段值）
     * @return 反写执行结果
     */
    public WritebackResult executeWriteback(String srcBoCode, Long srcBillId, String operation, ExprContext exprCtx) {
        List<MetaWritebackRule> rules = loadRules(srcBoCode, operation);
        WritebackResult result = new WritebackResult();
        result.setTotalRules(rules == null ? 0 : rules.size());
        if (rules == null || rules.isEmpty()) {
            result.setSuccess(true);
            return result;
        }
        for (MetaWritebackRule rule : rules) {
            executeOneRule(rule, srcBillId, operation, exprCtx, result);
        }
        result.setSuccess(result.getErrors().isEmpty());
        return result;
    }

    /**
     * 执行单条反写规则（按 exec_mode 分发）。
     * <p>子类可覆盖以调整 SYNC/ASYNC 路由逻辑。</p>
     */
    protected void executeOneRule(MetaWritebackRule rule, Long srcBillId, String operation,
                                   ExprContext exprCtx, WritebackResult result) {
        WritebackExecMode mode = resolveExecMode(rule);
        // 清空当前线程告警收集器，准备收集本次 doWriteback 期间的告警
        WARNINGS_HOLDER.get().clear();
        try {
            doWriteback(rule, srcBillId, operation, exprCtx);
            // 收集 doWriteback 期间产生的告警（如超限 WARN）到 result
            List<String> warnings = WARNINGS_HOLDER.get();
            if (!warnings.isEmpty()) {
                result.getWarnings().addAll(warnings);
            }
            result.setSuccessRules(result.getSuccessRules() + 1);
        } catch (ServiceExceptionBlock ex) {
            // 超限 BLOCK：SYNC 直接抛出，ASYNC 记录补偿
            if (mode == WritebackExecMode.SYNC) {
                result.addError("规则[" + rule.getRuleCode() + "]超限阻断: " + ex.getMessage());
                result.setSuccess(false);
                throw ex;
            } else {
                result.addError("规则[" + rule.getRuleCode() + "]异步超限阻断: " + ex.getMessage());
                recordAsyncFailure(rule, srcBillId, ex.getMessage());
            }
        } catch (Exception ex) {
            String errorMsg = ex.getMessage() == null ? ex.getClass().getSimpleName() : ex.getMessage();
            if (mode == WritebackExecMode.SYNC) {
                // SYNC 模式：失败抛异常，主事务回滚
                result.addError("规则[" + rule.getRuleCode() + "]同步执行失败: " + errorMsg);
                result.setSuccess(false);
                throw ex instanceof RuntimeException re ? re : new RuntimeException(ex);
            } else {
                // ASYNC 模式：失败记录到 biz_writeback_log，补偿服务重试
                result.addError("规则[" + rule.getRuleCode() + "]异步执行失败已记录补偿: " + errorMsg);
                recordAsyncFailure(rule, srcBillId, errorMsg);
            }
        } finally {
            WARNINGS_HOLDER.remove();
        }
    }

    /**
     * 添加告警信息到当前线程收集器（供 doWriteback 子类实现调用，如超限 WARN）。
     */
    protected void addWarning(String warning) {
        WARNINGS_HOLDER.get().add(warning);
    }

    /**
     * 解析规则执行模式（子类可覆盖以从 DB 读取 exec_mode）。
     * <p>默认读取 {@link MetaWritebackRule#getExecMode()}，未配置返回 SYNC。</p>
     */
    protected WritebackExecMode resolveExecMode(MetaWritebackRule rule) {
        return WritebackExecMode.fromCode(rule == null ? null : rule.getExecMode());
    }

    /**
     * ASYNC 失败时记录到 biz_writeback_log（由子类或补偿服务实现）。
     * <p>默认实现为空，子类可注入 {@link WritebackCompensationService} 委托。</p>
     */
    protected void recordAsyncFailure(MetaWritebackRule rule, Long srcBillId, String errorMsg) {
        // 默认空实现，由 WritebackServiceImpl 覆盖
    }

    /**
     * 加载反写规则列表（子类实现）。
     *
     * <p>约定：查询 {@code meta_writeback_rule} where src_bill_type=? and FIND_IN_SET(?, trigger_op) > 0 and is_enabled=1</p>
     * <p>trigger_op 为逗号分隔多选（如 "save,delete,cancel"），支持一个规则匹配多种操作。</p>
     *
     * @param srcBoCode 源单据业务对象编码
     * @param operation 触发操作（save/delete/cancel/audit/revoke）
     * @return 反写规则列表
     */
    protected abstract List<MetaWritebackRule> loadRules(String srcBoCode, String operation);

    /**
     * 执行单条反写规则（子类实现）。
     *
     * <p>对每条规则：</p>
     * <ol>
     *   <li>加载 meta_writeback_field（规则的字段映射）</li>
     *   <li>用 ExprEvaluator 从 exprCtx 取源单据字段值</li>
     *   <li>查目标单据当前值（SELECT target_field FROM target_table WHERE id=?）</li>
     *   <li>按 mode + operation 计算：正向操作(save/audit)用 compute，反向操作(delete/cancel/revoke)用 revert</li>
     *   <li>超限检查：over_limit_expr + policy（BLOCK/WARN/ALLOW）</li>
     *   <li>UPDATE target_table SET target_field=? WHERE id=?</li>
     * </ol>
     *
     * @param rule      反写规则
     * @param srcBillId 源单据ID
     * @param operation 触发操作（save/delete/cancel/audit/revoke），决定正向 compute 还是反向 revert
     * @param exprCtx   表达式上下文
     */
    protected abstract void doWriteback(MetaWritebackRule rule, Long srcBillId, String operation, ExprContext exprCtx);

    /**
     * 超限 BLOCK 信号异常（继承 ServiceException，对齐任务规范"抛 ServiceException"）。
     * <p>错误码 WB_OVER_LIMIT（对齐 ErrorCode.WB_OVER_LIMIT）。</p>
     */
    public static class ServiceExceptionBlock extends ServiceException {
        public ServiceExceptionBlock(String message) {
            super("WB_OVER_LIMIT", message);
        }
    }
}
