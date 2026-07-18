package com.eerp.bos.rule;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 反写失败补偿服务（ASYNC 反写失败重试）。
 *
 * <p>对齐设计文档 08 §3.6 / §6.4。提供：</p>
 * <ul>
 *   <li>{@link #recordFailure}：ASYNC 反写失败时记录到 biz_writeback_log（status=PENDING）</li>
 *   <li>{@link #compensate}：定时扫描 PENDING 任务重试执行（指数退避 retry_count*60s 间隔）</li>
 *   <li>超过 max_retry（默认 5）标记 status=FAILED 终态并告警</li>
 * </ul>
 *
 * <p>定时任务由 {@link Scheduled @Scheduled}(fixedDelay=60000) 触发，每 60s 扫描一次。
 * 通过本类上的 {@code @EnableScheduling} 启用调度（对齐 project_memory：不修改 EerpApplication）。</p>
 */
@Service
@org.springframework.scheduling.annotation.EnableScheduling
public class WritebackCompensationService {

    private static final Logger log = LoggerFactory.getLogger(WritebackCompensationService.class);

    /** 退避基准间隔（秒）：retry_count * BASE_INTERVAL_SEC */
    private static final long BASE_INTERVAL_SEC = 60L;

    /** 默认最大重试次数 */
    private static final int DEFAULT_MAX_RETRY = 5;

    @Autowired
    private BizWritebackLogMapper bizWritebackLogMapper;

    /**
     * 记录反写失败任务到 biz_writeback_log（status=PENDING）。
     *
     * <p>对齐设计文档 08 §3.6 saveFailedTask。由 {@link WritebackServiceImpl#recordAsyncFailure} 调用。</p>
     *
     * @param ruleId    反写规则ID
     * @param ruleCode  反写规则编码
     * @param srcBillId 源单据ID
     * @param srcBoCode 源单据业务对象编码
     * @param errorMsg  错误信息
     */
    public void recordFailure(Long ruleId, String ruleCode, Long srcBillId, String srcBoCode, String errorMsg) {
        BizWritebackLog logEntry = new BizWritebackLog();
        logEntry.setRuleId(ruleId);
        logEntry.setRuleCode(ruleCode);
        logEntry.setSrcBillId(srcBillId);
        logEntry.setSrcBoCode(srcBoCode);
        logEntry.setStatus(BizWritebackLog.STATUS_PENDING);
        logEntry.setRetryCount(0);
        logEntry.setMaxRetry(DEFAULT_MAX_RETRY);
        logEntry.setErrorMsg(truncate(errorMsg, 4000));
        // 首次记录：next_retry_time = now + 60s（retry_count=0 * 60 + 60）
        logEntry.setNextRetryTime(LocalDateTime.now().plusSeconds(BASE_INTERVAL_SEC));
        LocalDateTime now = LocalDateTime.now();
        logEntry.setCreatedTime(now);
        logEntry.setUpdatedTime(now);
        bizWritebackLogMapper.insert(logEntry);
        log.warn("反写失败已记录补偿日志: ruleId={}, ruleCode={}, srcBillId={}, error={}",
                ruleId, ruleCode, srcBillId, errorMsg);
    }

    /**
     * 定时扫描 PENDING 任务重试执行（指数退避：retry_count*60s 间隔）。
     *
     * <p>对齐设计文档 08 §3.6 batchRetry / §6.4。每 60s 扫描一次，
     * 查询 status=PENDING 且 retry_count < max_retry 且 next_retry_time <= now 的记录。</p>
     *
     * <p>重试逻辑：当前实现为标记重试次数累加并记录错误信息（实际反写重试由上层
     * 路由到对应 AbstractWritebackService.executeWriteback 执行，本方法提供调度入口与状态机管理）。
     * 若 retry_count+1 >= max_retry，标记 status=FAILED 终态并告警。</p>
     */
    @Scheduled(fixedDelay = 60000)
    public void compensate() {
        List<BizWritebackLog> pending;
        try {
            pending = bizWritebackLogMapper.listPendingForRetry(LocalDateTime.now());
        } catch (Exception e) {
            log.error("扫描反写补偿任务失败: {}", e.getMessage(), e);
            return;
        }
        if (pending == null || pending.isEmpty()) {
            return;
        }
        log.info("扫描到 {} 条待重试反写补偿任务", pending.size());
        for (BizWritebackLog logEntry : pending) {
            retryOne(logEntry);
        }
    }

    /**
     * 重试单条补偿任务。
     * <p>子类可覆盖以路由到对应 {@link AbstractWritebackService#executeWriteback} 重新执行反写。
     * 当前默认实现：累加重试次数，按指数退避更新 next_retry_time；超过 max_retry 标记终态 FAILED。</p>
     */
    protected void retryOne(BizWritebackLog logEntry) {
        int newRetryCount = (logEntry.getRetryCount() == null ? 0 : logEntry.getRetryCount()) + 1;
        int maxRetry = logEntry.getMaxRetry() == null ? DEFAULT_MAX_RETRY : logEntry.getMaxRetry();
        LocalDateTime now = LocalDateTime.now();
        try {
            // 实际重试执行由子类/上层路由实现，这里仅做状态机推进与退避
            // 默认行为：标记为仍在重试中（PENDING），等待具体反写服务实现重写本方法
            if (newRetryCount >= maxRetry) {
                bizWritebackLogMapper.markTerminallyFailed(logEntry.getId(),
                        truncate(logEntry.getErrorMsg(), 4000), now);
                log.error("反写补偿任务超过最大重试次数，标记终态 FAILED: id={}, ruleId={}, retryCount={}",
                        logEntry.getId(), logEntry.getRuleId(), newRetryCount);
                alertTerminalFailure(logEntry);
            } else {
                LocalDateTime nextRetry = now.plusSeconds(newRetryCount * BASE_INTERVAL_SEC);
                bizWritebackLogMapper.markRetryFailed(logEntry.getId(),
                        truncate(logEntry.getErrorMsg(), 4000), nextRetry, now);
                log.warn("反写补偿任务重试中: id={}, retryCount={}, nextRetry={}",
                        logEntry.getId(), newRetryCount, nextRetry);
            }
        } catch (Exception e) {
            log.error("反写补偿任务重试异常: id={}, error={}", logEntry.getId(), e.getMessage(), e);
        }
    }

    /** 终态失败告警（写日志，可扩展为通知） */
    protected void alertTerminalFailure(BizWritebackLog logEntry) {
        log.error("[反写补偿告警] 任务 id={} ruleCode={} srcBillId={} 超过最大重试次数 {}，需人工介入",
                logEntry.getId(), logEntry.getRuleCode(), logEntry.getSrcBillId(),
                logEntry.getMaxRetry());
    }

    /** 截断字符串到指定长度（防止 text 字段溢出） */
    private String truncate(String s, int maxLen) {
        if (s == null) {
            return null;
        }
        return s.length() <= maxLen ? s : s.substring(0, maxLen);
    }
}
