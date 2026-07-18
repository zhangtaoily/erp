package com.eerp.integration.wf;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * 工作流实例 CRUD 服务（基于 MyBatis-Plus {@link ServiceImpl}）。
 *
 * <p>提供按 request_id、按单据维度的便捷查询，供 {@link WfIntegrationService}
 * 与 {@link WfCallbackController} 使用。</p>
 */
@Service
public class WfInstanceService extends ServiceImpl<WfInstanceMapper, WfInstanceEntity> {

    /**
     * 按外部工作流实例ID查询实例。
     *
     * @param requestId 外部工作流实例ID（wf_request_id）
     * @return 实例记录，不存在返回 null
     */
    public WfInstanceEntity getByRequestId(String requestId) {
        if (requestId == null || requestId.isEmpty()) {
            return null;
        }
        return lambdaQuery()
                .eq(WfInstanceEntity::getRequestId, requestId)
                .one();
    }

    /**
     * 按单据查询工作流实例列表。
     *
     * @param boCode 业务对象编码
     * @param billId 单据ID
     * @return 实例列表（按提交时间倒序）
     */
    public List<WfInstanceEntity> listByBill(String boCode, Long billId) {
        return lambdaQuery()
                .eq(WfInstanceEntity::getBillType, boCode)
                .eq(WfInstanceEntity::getBillId, billId)
                .orderByDesc(WfInstanceEntity::getSubmitTime)
                .list();
    }
}
