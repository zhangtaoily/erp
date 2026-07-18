package com.eerp.bos.operation.service;

import java.util.Map;

/**
 * 工作流推送 SPI 端口（解耦 eerp-bos → eerp-integration 的编译期依赖）。
 *
 * <p>eerp-bos 的 {@link AbstractOperationService} 在事务后阶段（阶段 6 之后）调用此端口
 * 推送审批实例到外部工作流系统。实际实现 {@code WfPushPortImpl} 位于 eerp-integration 模块，
 * 包装 {@code WfIntegrationService.pushWf}。</p>
 *
 * <p>当 eerp-integration 不在 classpath（如单元测试）时，此端口为 null，
 * {@link AbstractOperationService} 跳过 WF 推送（对齐设计文档"事务后失败仅记日志"约束）。</p>
 */
public interface WfPushPort {

    /**
     * 推送审批实例到外部工作流系统。
     *
     * <p>此方法在事务后调用，实现方应捕获异常并返回 null（不抛出），
     * 确保不影响已提交的主操作结果。</p>
     *
     * @param boCode    业务对象编码
     * @param billId    单据 ID
     * @param wfPushApi 工作流推送 API 地址（来自 meta_state_transition.wf_push_api）
     * @param formData  表单数据
     * @param userId    操作用户 ID
     * @return 外部工作流实例 ID（wf_request_id）；失败返回 null
     */
    String pushWf(String boCode, Long billId, String wfPushApi,
                  Map<String, Object> formData, Long userId);
}
