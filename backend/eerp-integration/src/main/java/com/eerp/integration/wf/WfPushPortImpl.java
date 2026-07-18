package com.eerp.integration.wf;

import com.eerp.bos.operation.service.WfPushPort;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Map;

/**
 * 工作流推送端口实现（适配 eerp-bos → eerp-integration 解耦）。
 *
 * <p>实现 {@link WfPushPort} SPI 接口，包装 {@link WfIntegrationService#pushWf}。
 * 由 eerp-bos 的 {@code AbstractOperationService} 在事务后阶段通过
 * {@code @Autowired(required = false)} 注入。</p>
 *
 * <p>异常处理：事务后调用，实现方捕获所有异常并返回 null（不抛出），
 * 确保不影响已提交的主操作结果（对齐设计文档"事务后失败仅记日志"约束）。</p>
 */
@Service
public class WfPushPortImpl implements WfPushPort {

    private static final Logger log = LoggerFactory.getLogger(WfPushPortImpl.class);

    @Autowired
    private WfIntegrationService wfIntegrationService;

    @Override
    public String pushWf(String boCode, Long billId, String wfPushApi,
                         Map<String, Object> formData, Long userId) {
        try {
            return wfIntegrationService.pushWf(boCode, billId, wfPushApi, formData, userId);
        } catch (Exception e) {
            log.warn("工作流推送失败（事务后，不影响主操作）: boCode={}, billId={}, error={}",
                    boCode, billId, e.getMessage(), e);
            return null;
        }
    }
}
