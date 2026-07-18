package com.eerp.integration.wf;

import cn.hutool.http.HttpRequest;
import cn.hutool.http.HttpResponse;
import cn.hutool.json.JSONObject;
import cn.hutool.json.JSONUtil;
import com.eerp.common.exception.ServiceException;
import com.eerp.common.id.SnowflakeIdGenerator;
import com.eerp.integration.apilog.ApiLogServiceImpl;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

/**
 * 工作流集成服务：推送审批实例到外部工作流系统、查询状态、取消审批。
 *
 * <p>HTTP 调用事务外执行（对齐设计文档 §3.3），失败抛 {@link ServiceException}，
 * 不回滚主操作。所有调用经 {@link ApiLogServiceImpl} 记录 sys_api_log。</p>
 */
@Service
public class WfIntegrationService {

    @Autowired
    private WfInstanceService wfInstanceService;

    @Autowired
    private ApiLogServiceImpl apiLogService;

    @Autowired
    private SnowflakeIdGenerator snowflakeIdGenerator;

    @Value("${eerp.wf.push-timeout-ms:10000}")
    private int pushTimeoutMs;

    /**
     * 推送审批实例到外部工作流系统，返回 wf_request_id。
     *
     * @param boCode    业务对象编码
     * @param billId    单据ID
     * @param wfPushApi 工作流推送 API 地址
     * @param formData  表单数据
     * @param userId    操作用户ID
     * @return 外部工作流实例ID（wf_request_id）
     */
    public String pushWf(String boCode, Long billId, String wfPushApi,
                         Map<String, Object> formData, Long userId) {
        if (wfPushApi == null || wfPushApi.isEmpty()) {
            throw new ServiceException("WF_001", "工作流推送 API 地址未配置");
        }

        Map<String, Object> payload = new HashMap<>();
        payload.put("boCode", boCode);
        payload.put("billId", billId);
        payload.put("userId", userId);
        payload.put("formData", formData);
        payload.put("callbackUrl", "/api/wf/callback");
        String requestJson = JSONUtil.toJsonStr(payload);

        long start = System.currentTimeMillis();
        String respBody = null;
        String errorCode = null;
        try {
            HttpResponse response = HttpRequest.post(wfPushApi)
                    .header("Content-Type", "application/json")
                    .timeout(pushTimeoutMs)
                    .body(requestJson)
                    .execute();
            respBody = response.body();
            long cost = System.currentTimeMillis() - start;

            if (response.getStatus() < 200 || response.getStatus() >= 300) {
                errorCode = "WF_HTTP_" + response.getStatus();
                apiLogService.log(wfPushApi, "POST", userId, requestJson, respBody, cost, errorCode);
                throw new ServiceException("WF_002", "工作流推送失败，HTTP " + response.getStatus() + ": " + respBody);
            }

            String requestId = extractRequestId(respBody);
            if (requestId == null || requestId.isEmpty()) {
                errorCode = "WF_RESP_NO_REQUEST_ID";
                apiLogService.log(wfPushApi, "POST", userId, requestJson, respBody, cost, errorCode);
                throw new ServiceException("WF_002", "工作流推送响应缺少 requestId: " + respBody);
            }

            // 记录日志（成功）
            apiLogService.log(wfPushApi, "POST", userId, requestJson, respBody, cost, null);

            // 落库 wf_instance（独立事务，由 WfInstanceService.save 控制）
            WfInstanceEntity inst = new WfInstanceEntity();
            inst.setId(snowflakeIdGenerator.nextId());
            inst.setInstanceId(snowflakeIdGenerator.nextId());
            inst.setRequestId(requestId);
            inst.setBillType(boCode);
            inst.setBillId(billId);
            inst.setStatus("approving");
            inst.setSubmitBy(userId == null ? null : String.valueOf(userId));
            inst.setSubmitTime(LocalDateTime.now());
            wfInstanceService.save(inst);

            return requestId;
        } catch (ServiceException se) {
            throw se;
        } catch (Exception e) {
            long cost = System.currentTimeMillis() - start;
            errorCode = "WF_PUSH_ERROR";
            apiLogService.log(wfPushApi, "POST", userId, requestJson, respBody, cost, errorCode);
            throw new ServiceException("WF_002", "工作流推送异常: " + e.getMessage(), e);
        }
    }

    /**
     * 查询审批状态（查本地 wf_instance 表）。
     *
     * @param wfRequestId 外部工作流实例ID
     * @return 审批状态：approving/approved/rejected/canceled
     */
    public String queryWfStatus(String wfRequestId) {
        WfInstanceEntity inst = wfInstanceService.getByRequestId(wfRequestId);
        if (inst == null) {
            throw new ServiceException("WF_003", "工作流实例不存在: " + wfRequestId);
        }
        return inst.getStatus();
    }

    /**
     * 取消审批：更新本地 wf_instance 状态为 canceled。
     *
     * <p>外部工作流系统的取消接口地址未在配置中固化，如需联动外部请扩展此方法。</p>
     *
     * @param wfRequestId 外部工作流实例ID
     */
    public void cancelWf(String wfRequestId) {
        WfInstanceEntity inst = wfInstanceService.getByRequestId(wfRequestId);
        if (inst == null) {
            throw new ServiceException("WF_003", "工作流实例不存在: " + wfRequestId);
        }
        inst.setStatus("canceled");
        inst.setCallbackTime(LocalDateTime.now());
        wfInstanceService.updateById(inst);
    }

    /**
     * 从响应体中提取 wf_request_id：优先 data.requestId，其次顶层 requestId。
     */
    private String extractRequestId(String respBody) {
        if (respBody == null || respBody.isEmpty()) {
            return null;
        }
        try {
            JSONObject json = JSONUtil.parseObj(respBody);
            Object data = json.get("data");
            if (data instanceof JSONObject dataObj && dataObj.getStr("requestId") != null) {
                return dataObj.getStr("requestId");
            }
            return json.getStr("requestId");
        } catch (Exception e) {
            return null;
        }
    }
}
