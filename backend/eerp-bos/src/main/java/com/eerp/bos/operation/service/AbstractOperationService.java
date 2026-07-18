package com.eerp.bos.operation.service;

import com.eerp.bos.rule.RuleEngineImpl;
import com.eerp.bos.rule.RuleViolation;
import com.eerp.bos.rule.WritebackResult;
import com.eerp.bos.rule.WritebackServiceImpl;
import com.eerp.bos.statemachine.AbstractStateTransitionExecutor;
import com.eerp.bos.statemachine.TransitionExecutorFactory;
import com.eerp.common.exception.ServiceException;
import com.eerp.meta.rule.expr.ExprContext;
import com.eerp.meta.statemachine.StateMachineEngineImpl;
import com.eerp.meta.statemachine.dto.StateTransitionResult;
import com.eerp.meta.statemachine.entity.MetaStateTransition;
import com.eerp.plugin.context.PluginContext;
import com.eerp.plugin.context.PluginResult;
import com.eerp.plugin.core.PluginContextFactory;
import com.eerp.plugin.core.PluginExecutorResult;
import com.eerp.plugin.core.PluginManager;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 操作编排服务抽象基类（模板方法模式，对齐设计文档 02 §3.5）。
 *
 * <p>固化单据操作的 6 阶段流水线骨架，串联已实现的各核心引擎：
 * <ol>
 *   <li>状态机校验（{@link StateMachineEngineImpl}）</li>
 *   <li>实体规则（{@link RuleEngineImpl}，事务内先于插件）</li>
 *   <li>插件 6 阶段流水线（{@link PluginManager}）</li>
 *   <li>主流程落库（{@link #doSave} / {@link #doStateChange} / {@link #doDelete}）</li>
 *   <li>反写规则（{@link WritebackServiceImpl}，SYNC 事务内 / ASYNC 事务后补偿）</li>
 *   <li>工作流推送（{@link WfPushPort}，事务后）</li>
 *   <li>操作日志（{@link #recordOpLog}）</li>
 * </ol>
 *
 * <h3>事务边界（对齐 project_memory 硬约束）</h3>
 * <ul>
 *   <li>阶段 1-3（onPreparePropertys / onAddValidators / beforeExecuteOperationTransaction）：事务外执行，
 *       {@code block=true} 时中止主操作</li>
 *   <li>阶段 4-5（beginOperationTransaction / endOperationTransaction）+ 实体规则 + 主流程落库 +
 *       反写（SYNC）+ 操作日志：事务内执行，异常回滚</li>
 *   <li>阶段 6（afterExecuteOperationTransaction）+ 工作流推送：事务后执行，仅记日志，不影响主操作</li>
 * </ul>
 *
 * <h3>6 阶段流水线执行顺序</h3>
 * <pre>
 *   [事务外]
 *     1. onPreparePropertys       — 预加载字段值
 *     2. onAddValidators          — 挂载校验器（校验错误收集到 PluginContext.validationErrors）
 *     3. beforeExecuteOperationTransaction — 事务前校验
 *     → 校验错误检查 → 状态机校验 → 流转执行器 postAction（收集 needWf/needWriteback 标记）
 *   [事务内]
 *     → 实体规则（OnBeforeSave/OnBeforeSubmit/OnBeforeAudit，block=true 回滚）
 *     4. beginOperationTransaction — 事务内前置
 *     → 主流程落库（save/stateChange/delete）
 *     5. endOperationTransaction   — 事务内后置
 *     → 反写规则（SYNC 模式，needWriteback=true 时）
 *     → 操作日志
 *   [事务后]
 *     6. afterExecuteOperationTransaction — 事务后通知（异常仅记日志）
 *     → 工作流推送（needWf=true 时，异常仅记日志）
 * </pre>
 */
public abstract class AbstractOperationService {

    private static final Logger log = LoggerFactory.getLogger(AbstractOperationService.class);

    /** 插件 6 阶段事件名（对齐 AbstractOperationServicePlugin 方法名） */
    public static final String EVENT_PREPARE_PROPERTYS = "onPreparePropertys";
    public static final String EVENT_ADD_VALIDATORS = "onAddValidators";
    public static final String EVENT_BEFORE_TX = "beforeExecuteOperationTransaction";
    public static final String EVENT_BEGIN_TX = "beginOperationTransaction";
    public static final String EVENT_END_TX = "endOperationTransaction";
    public static final String EVENT_AFTER_TX = "afterExecuteOperationTransaction";

    @Autowired
    protected PluginManager pluginManager;

    @Autowired
    protected PluginContextFactory pluginContextFactory;

    @Autowired
    protected RuleEngineImpl ruleEngine;

    @Autowired
    protected WritebackServiceImpl writebackService;

    @Autowired
    protected StateMachineEngineImpl stateMachineEngine;

    @Autowired
    protected TransitionExecutorFactory transitionExecutorFactory;

    /** 工作流推送端口（eerp-integration 提供 impl；单元测试环境为 null） */
    @Autowired(required = false)
    protected WfPushPort wfPushPort;

    @Autowired
    protected PlatformTransactionManager transactionManager;

    // ==================== 模板方法 ====================

    /**
     * 执行单据操作（模板方法入口）。
     *
     * <p>按 operation 类型分发到 {@link #executeSave} / {@link #executeStateTransition} /
     * {@link #executeDelete}，各自固化 6 阶段流水线事务边界。</p>
     *
     * @param ctx 操作上下文
     * @return 操作结果
     */
    public OperationResult executeOperation(OperationContext ctx) {
        if (ctx == null || ctx.getBoCode() == null) {
            return OperationResult.fail("操作上下文或业务对象编码为空");
        }
        String operation = ctx.getOperation();
        if (operation == null || operation.isEmpty()) {
            return OperationResult.fail("操作类型为空");
        }

        if ("delete".equals(operation)) {
            return executeDelete(ctx);
        }
        if ("save".equals(operation) || "draft".equals(operation)) {
            return executeSave(ctx);
        }
        if ("enable".equals(operation) || "disable".equals(operation)) {
            return executeStatusChange(ctx);
        }
        return executeStateTransition(ctx);
    }

    // ==================== 保存操作 ====================

    /**
     * 执行保存操作（save/draft），固化 6 阶段流水线。
     *
     * <p>事务边界：阶段 1-3 事务外 → 实体规则 + 阶段 4-5 + 主流程落库 + 操作日志 事务内 → 阶段 6 事务后。</p>
     */
    protected OperationResult executeSave(OperationContext ctx) {
        String boCode = ctx.getBoCode();
        Map<String, Object> billData = ctx.getBillData();
        if (billData == null) {
            return OperationResult.fail("单据数据为空");
        }

        // 构建插件上下文（贯穿全阶段，插件间共享 variables）
        PluginContext pluginCtx = buildPluginContext(ctx, billData);

        // === 事务外：阶段 1-3 ===
        OperationResult preResult = runPreTransactionStages(boCode, pluginCtx);
        if (preResult != null) {
            return preResult;
        }

        // === 事务内：实体规则 + 阶段 4-5 + 主流程落库 + 操作日志 ===
        final ExprContext exprCtx = buildExprContext(ctx, billData);
        final Long[] billIdHolder = new Long[1];
        try {
            runInTransaction(() -> {
                // 实体规则（事务内，先于插件阶段 4）
                String triggerEvent = mapOperationToRuleEvent(ctx.getOperation());
                List<RuleViolation> violations = ruleEngine.executeRules(boCode, triggerEvent, exprCtx);
                checkBlockingViolations(violations);

                // 阶段 4：beginOperationTransaction
                PluginExecutorResult r4 = pluginManager.fire(boCode, EVENT_BEGIN_TX, pluginCtx);
                checkPluginBlock(r4);

                // 主流程落库
                Long billId = doSave(ctx);
                billIdHolder[0] = billId;
                pluginCtx.setBillId(billId);

                // 阶段 5：endOperationTransaction
                PluginExecutorResult r5 = pluginManager.fire(boCode, EVENT_END_TX, pluginCtx);
                checkPluginBlock(r5);

                // 操作日志
                recordOpLog(boCode, billId, readBillCode(boCode, billId),
                        ctx.getOperation(), null, null, null, ctx.getUserName());
            });
        } catch (ServiceException e) {
            return OperationResult.fail(e.getMessage());
        }

        Long billId = billIdHolder[0];

        // === 事务后：阶段 6 ===
        runAfterTransactionStage(boCode, pluginCtx);

        return OperationResult.ok(billId);
    }

    // ==================== 状态流转操作 ====================

    /**
     * 执行状态流转操作（submit/audit/reject/revoke/close/cancel），固化 6 阶段流水线。
     *
     * <p>事务边界：阶段 1-3 事务外 → 状态机校验 + 流转执行器 postAction 事务外 →
     * 实体规则 + 阶段 4-5 + 主流程落库 + 反写 + 操作日志 事务内 → 阶段 6 + WF 推送 事务后。</p>
     */
    protected OperationResult executeStateTransition(OperationContext ctx) {
        String boCode = ctx.getBoCode();
        Long billId = ctx.getBillId();
        String operation = ctx.getOperation();
        if (billId == null) {
            return OperationResult.fail("单据ID为空，无法执行操作");
        }

        // 加载单据数据（供插件上下文 + 表达式上下文使用）
        Map<String, Object> billData = loadBillData(ctx);
        PluginContext pluginCtx = buildPluginContext(ctx, billData);

        // === 事务外：阶段 1-3 ===
        OperationResult preResult = runPreTransactionStages(boCode, pluginCtx);
        if (preResult != null) {
            return preResult;
        }

        // === 事务外：状态机校验 ===
        String buttonCode = operation; // submit/audit/reject/revoke/close/cancel 与按钮编码一一对应
        StateTransitionResult transition = stateMachineEngine.execute(boCode, billId, buttonCode, ctx.getReason());
        if (!transition.isSuccess()) {
            return OperationResult.fail(transition.getMessage());
        }

        // 获取匹配的流转定义（供 postAction 执行器使用）
        MetaStateTransition matched = stateMachineEngine.matchTransition(boCode, buttonCode);

        // 执行流转执行器 postAction（收集 needWf/needWriteback 标记）
        final Map<String, Object> extras = new HashMap<>();
        final ExprContext exprCtx = buildExprContext(ctx, billData);
        if (matched != null) {
            AbstractStateTransitionExecutor executor = transitionExecutorFactory.getExecutor(transition.getActionName());
            executor.postAction(matched, billId, exprCtx, extras);
        }

        // 读取当前状态 + 单据编号（供操作日志）
        String stateField = resolveStateField(boCode);
        Integer fromState = readState(boCode, billId, stateField);
        String billCode = readBillCode(boCode, billId);

        // === 事务内：实体规则 + 阶段 4-5 + 主流程落库 + 反写 + 操作日志 ===
        try {
            runInTransaction(() -> {
                // 实体规则（事务内，先于插件阶段 4）
                String triggerEvent = mapOperationToRuleEvent(operation);
                List<RuleViolation> violations = ruleEngine.executeRules(boCode, triggerEvent, exprCtx);
                checkBlockingViolations(violations);

                // 阶段 4：beginOperationTransaction
                PluginExecutorResult r4 = pluginManager.fire(boCode, EVENT_BEGIN_TX, pluginCtx);
                checkPluginBlock(r4);

                // 主流程落库：状态变更
                doStateChange(ctx, transition);

                // 阶段 5：endOperationTransaction
                PluginExecutorResult r5 = pluginManager.fire(boCode, EVENT_END_TX, pluginCtx);
                checkPluginBlock(r5);

                // 反写规则（SYNC 模式事务内执行，失败抛异常回滚）
                if (Boolean.TRUE.equals(extras.get("needWriteback"))) {
                    WritebackResult wbResult = writebackService.executeWriteback(boCode, billId, operation, exprCtx);
                    if (wbResult != null && !wbResult.isSuccess()) {
                        // SYNC 模式失败已由 AbstractWritebackService 抛异常；此处兜底
                        throw new ServiceException("WB_FAIL", "反写执行失败");
                    }
                }

                // 操作日志
                recordOpLog(boCode, billId, billCode, operation, fromState,
                        transition.getToState(), ctx.getReason(), ctx.getUserName());
            });
        } catch (ServiceException e) {
            return OperationResult.fail(e.getMessage());
        }

        // === 事务后：阶段 6 + 工作流推送 ===
        runAfterTransactionStage(boCode, pluginCtx);

        if (Boolean.TRUE.equals(extras.get("needWf")) && wfPushPort != null && matched != null) {
            String wfPushApi = matched.getWfPushApi();
            if (wfPushApi != null && !wfPushApi.isEmpty()) {
                try {
                    wfPushPort.pushWf(boCode, billId, wfPushApi, billData, ctx.getUserId());
                } catch (Exception e) {
                    log.warn("工作流推送失败（事务后，不影响主操作）: boCode={}, billId={}, error={}",
                            boCode, billId, e.getMessage(), e);
                }
            }
        }

        OperationResult result = OperationResult.ok(billId, transition.getMessage());
        result.getExtras().putAll(extras);
        return result;
    }

    // ==================== 删除操作 ====================

    /**
     * 执行删除操作，固化 6 阶段流水线。
     *
     * <p>事务边界：阶段 1-3 事务外 → 阶段 4-5 + 删除 + 操作日志 事务内 → 阶段 6 事务后。
     * 删除无状态机校验、无实体规则、无反写、无工作流推送。</p>
     */
    protected OperationResult executeDelete(OperationContext ctx) {
        String boCode = ctx.getBoCode();
        Long billId = ctx.getBillId();
        if (billId == null) {
            return OperationResult.fail("单据ID为空，无法删除");
        }

        Map<String, Object> billData = loadBillData(ctx);
        PluginContext pluginCtx = buildPluginContext(ctx, billData);

        // === 事务外：阶段 1-3 ===
        OperationResult preResult = runPreTransactionStages(boCode, pluginCtx);
        if (preResult != null) {
            return preResult;
        }

        // 读取当前状态 + 单据编号（供操作日志，删除前读取）
        String stateField = resolveStateField(boCode);
        Integer fromState = readState(boCode, billId, stateField);
        String billCode = readBillCode(boCode, billId);

        // === 事务内：阶段 4-5 + 删除 + 操作日志 ===
        try {
            runInTransaction(() -> {
                // 阶段 4：beginOperationTransaction
                PluginExecutorResult r4 = pluginManager.fire(boCode, EVENT_BEGIN_TX, pluginCtx);
                checkPluginBlock(r4);

                // 主流程落库：删除
                doDelete(ctx);

                // 阶段 5：endOperationTransaction
                PluginExecutorResult r5 = pluginManager.fire(boCode, EVENT_END_TX, pluginCtx);
                checkPluginBlock(r5);

                // 操作日志
                recordOpLog(boCode, billId, billCode, "delete", fromState, null,
                        ctx.getReason(), ctx.getUserName());
            });
        } catch (ServiceException e) {
            return OperationResult.fail(e.getMessage());
        }

        // === 事务后：阶段 6 ===
        runAfterTransactionStage(boCode, pluginCtx);

        return OperationResult.ok("删除成功");
    }

    // ==================== 启用/停用操作 ====================

    /**
     * 执行启用/停用操作（enable/disable），固化 6 阶段流水线。
     *
     * <p>主数据（bo_type=master）无状态机，enable/disable 直接更新 status 字段。
     * 事务边界：阶段 1-3 事务外 → 阶段 4-5 + 状态更新 + 操作日志 事务内 → 阶段 6 事务后。</p>
     */
    protected OperationResult executeStatusChange(OperationContext ctx) {
        String boCode = ctx.getBoCode();
        Long billId = ctx.getBillId();
        if (billId == null) {
            return OperationResult.fail("单据ID为空，无法执行操作");
        }

        Map<String, Object> billData = loadBillData(ctx);
        PluginContext pluginCtx = buildPluginContext(ctx, billData);

        // === 事务外：阶段 1-3 ===
        OperationResult preResult = runPreTransactionStages(boCode, pluginCtx);
        if (preResult != null) {
            return preResult;
        }

        String billCode = readBillCode(boCode, billId);
        int targetStatus = "enable".equals(ctx.getOperation()) ? 1 : 0;

        // === 事务内：阶段 4-5 + 状态更新 + 操作日志 ===
        try {
            runInTransaction(() -> {
                // 阶段 4：beginOperationTransaction
                PluginExecutorResult r4 = pluginManager.fire(boCode, EVENT_BEGIN_TX, pluginCtx);
                checkPluginBlock(r4);

                // 主流程落库：状态字段更新
                doStatusChange(ctx, targetStatus);

                // 阶段 5：endOperationTransaction
                PluginExecutorResult r5 = pluginManager.fire(boCode, EVENT_END_TX, pluginCtx);
                checkPluginBlock(r5);

                // 操作日志
                recordOpLog(boCode, billId, billCode, ctx.getOperation(), null, null,
                        ctx.getReason(), ctx.getUserName());
            });
        } catch (ServiceException e) {
            return OperationResult.fail(e.getMessage());
        }

        // === 事务后：阶段 6 ===
        runAfterTransactionStage(boCode, pluginCtx);

        return OperationResult.ok(billId);
    }

    // ==================== 6 阶段流水线辅助方法 ====================

    /**
     * 执行事务外阶段 1-3（onPreparePropertys → onAddValidators → beforeExecuteOperationTransaction）。
     *
     * @return 阻断时返回失败结果；通过返回 null
     */
    private OperationResult runPreTransactionStages(String boCode, PluginContext pluginCtx) {
        // 阶段 1：onPreparePropertys
        PluginExecutorResult r1 = pluginManager.fire(boCode, EVENT_PREPARE_PROPERTYS, pluginCtx);
        if (r1.isBlock()) {
            return OperationResult.fail(r1.getMessage());
        }

        // 阶段 2：onAddValidators
        PluginExecutorResult r2 = pluginManager.fire(boCode, EVENT_ADD_VALIDATORS, pluginCtx);
        if (r2.isBlock()) {
            return OperationResult.fail(r2.getMessage());
        }
        if (pluginCtx.hasValidationErrors()) {
            return OperationResult.fail(String.join("; ", pluginCtx.getValidationErrors()));
        }

        // 阶段 3：beforeExecuteOperationTransaction
        PluginExecutorResult r3 = pluginManager.fire(boCode, EVENT_BEFORE_TX, pluginCtx);
        if (r3.isBlock()) {
            return OperationResult.fail(r3.getMessage());
        }

        return null;
    }

    /**
     * 执行事务后阶段 6（afterExecuteOperationTransaction），异常仅记日志。
     */
    private void runAfterTransactionStage(String boCode, PluginContext pluginCtx) {
        try {
            pluginManager.fire(boCode, EVENT_AFTER_TX, pluginCtx);
        } catch (Exception e) {
            log.warn("阶段6（afterExecuteOperationTransaction）执行异常（事务后，仅记日志）: boCode={}, error={}",
                    boCode, e.getMessage(), e);
        }
    }

    /**
     * 检查插件阻断：block=true 时抛 ServiceException 触发事务回滚。
     */
    private void checkPluginBlock(PluginExecutorResult result) {
        if (result.isBlock()) {
            throw new ServiceException("PLUGIN_BLOCK", result.getMessage());
        }
    }

    /**
     * 检查实体规则阻断：block=true 的 violation 抛 ServiceException 触发事务回滚。
     */
    private void checkBlockingViolations(List<RuleViolation> violations) {
        if (violations == null || violations.isEmpty()) {
            return;
        }
        for (RuleViolation v : violations) {
            if (v.isBlock()) {
                throw new ServiceException("RULE_BLOCK", v.getMessage());
            }
        }
    }

    /**
     * 映射操作类型到实体规则触发事件。
     */
    private String mapOperationToRuleEvent(String operation) {
        if (operation == null) {
            return null;
        }
        switch (operation) {
            case "save":
            case "draft":
                return "OnBeforeSave";
            case "submit":
                return "OnBeforeSubmit";
            case "audit":
                return "OnBeforeAudit";
            case "reject":
                return "OnBeforeReject";
            case "revoke":
                return "OnBeforeRevoke";
            case "close":
                return "OnBeforeClose";
            case "cancel":
                return "OnBeforeCancel";
            default:
                return null;
        }
    }

    /**
     * 构建插件上下文。
     */
    private PluginContext buildPluginContext(OperationContext ctx, Map<String, Object> billData) {
        Map<String, Object> userInfo = new HashMap<>();
        userInfo.put("userId", ctx.getUserId());
        userInfo.put("userName", ctx.getUserName());
        return pluginContextFactory.create(ctx.getBoCode(), ctx.getBillId(),
                ctx.getOperation(), billData, userInfo);
    }

    /**
     * 在事务中执行（模板方法，子类可覆盖以支持测试 mock）。
     *
     * <p>使用 {@link TransactionTemplate} + PROPAGATION_REQUIRED：
     * 无现有事务时开启新事务，有现有事务时加入。异常自动回滚。</p>
     */
    protected void runInTransaction(Runnable action) {
        TransactionTemplate txTemplate = new TransactionTemplate(transactionManager);
        txTemplate.executeWithoutResult(status -> action.run());
    }

    // ==================== 子类实现的抽象钩子 ====================

    /**
     * 加载单据数据（主表 + 子表）。
     *
     * <p>save 操作可直接返回 ctx.billData；operate 操作从 DB 加载。</p>
     *
     * @param ctx 操作上下文
     * @return 单据数据（{main: {...}, subs: {entity_code: [...]}}）
     */
    protected abstract Map<String, Object> loadBillData(OperationContext ctx);

    /**
     * 主流程落库：保存单据（新增/更新主表 + 子表 + 孙表）。
     *
     * @param ctx 操作上下文
     * @return 单据 ID
     */
    protected abstract Long doSave(OperationContext ctx);

    /**
     * 主流程落库：状态变更（UPDATE 主表状态字段 + is_closed/is_cancel）。
     *
     * @param ctx        操作上下文
     * @param transition 状态流转结果
     */
    protected abstract void doStateChange(OperationContext ctx, StateTransitionResult transition);

    /**
     * 主流程落库：删除单据（子表 + 孙表 + 主表）。
     *
     * @param ctx 操作上下文
     */
    protected abstract void doDelete(OperationContext ctx);

    /**
     * 主流程落库：启用/停用主数据（UPDATE 主表 status 字段）。
     *
     * @param ctx           操作上下文
     * @param targetStatus  目标状态（1启用/0停用）
     */
    protected abstract void doStatusChange(OperationContext ctx, int targetStatus);

    /**
     * 构建表达式求值上下文（从 billData 提取 rootData + subData）。
     *
     * @param ctx      操作上下文
     * @param billData 单据数据
     * @return 表达式上下文
     */
    protected abstract ExprContext buildExprContext(OperationContext ctx, Map<String, Object> billData);

    /**
     * 记录操作日志到 biz_op_log 表。
     */
    protected abstract void recordOpLog(String boCode, Long billId, String billCode,
                                        String opType, Integer fromState, Integer toState,
                                        String remark, String userName);

    /** 解析状态字段名 */
    protected abstract String resolveStateField(String boCode);

    /** 解析主表名 */
    protected abstract String resolveMainTable(String boCode);

    /** 读取单据当前状态 */
    protected abstract Integer readState(String boCode, Long billId, String stateField);

    /** 读取单据编号 */
    protected abstract String readBillCode(String boCode, Long billId);
}
