package com.eerp.integration.wf;

import com.eerp.bos.bill.BillOperationContext;
import com.eerp.bos.bill.BillOperationResult;
import com.eerp.bos.bill.GenericBillService;
import com.eerp.common.api.Result;
import com.eerp.common.exception.ServiceException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.Map;

/**
 * 工作流回调控制器：接收外部工作流系统的审批结果回调。
 *
 * <p>回调需校验 token（简单比对 {@code eerp.wf.callback-token}），
 * 通过后回写 wf_instance.status 并触发单据 pact_state 流转：
 * approved → pact_state=3（审核），rejected → pact_state=4（驳回）。</p>
 */
@RestController
@RequestMapping("/api/wf/callback")
public class WfCallbackController {

    @Autowired
    private WfInstanceService wfInstanceService;

    @Autowired
    private GenericBillService genericBillService;

    @Value("${eerp.wf.callback-token:eerp-wf-default-token}")
    private String callbackToken;

    /**
     * 审批通过回调：wf_instance.status=approved，触发单据审核（pact_state=3）。
     *
     * @param body 回调体，含 wfRequestId / opinion / token
     * @return 结果
     */
    @PostMapping("/approved")
    public Result<Void> approved(@RequestBody Map<String, String> body,
                                 @RequestHeader(value = "X-WF-Token", required = false) String headerToken) {
        return handleCallback(body, headerToken, "approved", "audit");
    }

    /**
     * 审批驳回回调：wf_instance.status=rejected，触发单据驳回（pact_state=4）。
     *
     * @param body 回调体，含 wfRequestId / opinion / token
     * @return 结果
     */
    @PostMapping("/rejected")
    public Result<Void> rejected(@RequestBody Map<String, String> body,
                                 @RequestHeader(value = "X-WF-Token", required = false) String headerToken) {
        return handleCallback(body, headerToken, "rejected", "reject");
    }

    /**
     * 统一回调处理：校验 token → 回写 wf_instance → 触发单据状态流转。
     *
     * @param body         回调体
     * @param headerToken  请求头中的 token（兜底）
     * @param newStatus    wf_instance 目标状态
     * @param operation    单据操作编码（audit/reject）
     */
    private Result<Void> handleCallback(Map<String, String> body, String headerToken,
                                        String newStatus, String operation) {
        if (body == null) {
            return Result.fail("WF_001", "回调请求体为空");
        }
        String token = body.get("token");
        if (!StringUtils.hasText(token)) {
            token = headerToken;
        }
        if (!StringUtils.hasText(token) || !token.equals(callbackToken)) {
            return Result.fail("WF_001", "回调签名校验失败");
        }

        String wfRequestId = body.get("wfRequestId");
        String opinion = body.get("opinion");
        if (!StringUtils.hasText(wfRequestId)) {
            return Result.fail("WF_001", "回调缺少 wfRequestId");
        }

        WfInstanceEntity inst = wfInstanceService.getByRequestId(wfRequestId);
        if (inst == null) {
            return Result.fail("WF_003", "工作流实例不存在: " + wfRequestId);
        }

        // 回写 wf_instance（外部审批决策）
        inst.setStatus(newStatus);
        inst.setCallbackTime(LocalDateTime.now());
        wfInstanceService.updateById(inst);

        // 触发单据状态流转：approved→audit(pact_state=3)，rejected→reject(pact_state=4)
        try {
            BillOperationContext ctx = BillOperationContext.builder()
                    .boCode(inst.getBillType())
                    .billId(inst.getBillId())
                    .operation(operation)
                    .userName("wf-callback")
                    .reason(opinion)
                    .build();
            BillOperationResult result = genericBillService.operate(ctx);
            if (!result.isSuccess()) {
                return Result.fail("WF_004", "单据状态回写失败: " + result.getMessage());
            }
        } catch (ServiceException se) {
            return Result.fail(se);
        } catch (Exception e) {
            return Result.fail("WF_004", "单据状态回写异常: " + e.getMessage());
        }

        return Result.ok();
    }
}
