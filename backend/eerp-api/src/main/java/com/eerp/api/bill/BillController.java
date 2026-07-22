package com.eerp.api.bill;

import com.eerp.bos.bill.AbstractBillLinkService;
import com.eerp.bos.bill.BillOperationContext;
import com.eerp.bos.bill.BillOperationResult;
import com.eerp.bos.bill.GenericBillService;
import com.eerp.bos.bill.TraceTree;
import com.eerp.bos.print.AbstractPrintTemplateService;
import com.eerp.bos.push.AbstractPushService;
import com.eerp.bos.push.PushContext;
import com.eerp.bos.push.PushLine;
import com.eerp.bos.push.PushResult;
import com.eerp.common.api.PageRequest;
import com.eerp.common.api.PageResult;
import com.eerp.common.api.QueryCondition;
import com.eerp.common.api.Result;
import com.eerp.common.exception.ServiceException;
import com.eerp.common.security.SecurityContext;
import com.eerp.common.security.SecurityContextHolder;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 单据 Controller（对齐设计文档 02 §6 API 端点）。
 *
 * <p>端点清单：</p>
 * <ul>
 *   <li>{@code GET  /api/bill/{boCode}/list} — 分页查询单据列表</li>
 *   <li>{@code GET  /api/bill/{boCode}/{id}} — 查询单据详情（主子孙三表）</li>
 *   <li>{@code POST /api/bill/{boCode}} — 保存（含新增/编辑）</li>
 *   <li>{@code POST /api/bill/{boCode}/{id}/{action}} — 操作（submit/audit/reject/revoke/close/cancel/delete/...）</li>
 *   <li>{@code DELETE /api/bill/{boCode}/{id}} — 删除单据</li>
 *   <li>{@code POST /api/bill/{boCode}/push} — 下推生成目标单（B1 新增）</li>
 *   <li>{@code GET  /api/bill/{boCode}/{id}/trace} — 单据追溯树（B1 新增）</li>
 *   <li>{@code GET  /api/bill/{boCode}/{id}/print} — 打印渲染（B1 新增）</li>
 * </ul>
 */
@RestController
@RequestMapping("/api/bill/{boCode}")
public class BillController {

    private final GenericBillService billService;
    private final AbstractPushService pushService;
    private final AbstractBillLinkService billLinkService;
    private final AbstractPrintTemplateService printTemplateService;

    public BillController(GenericBillService billService,
                          AbstractPushService pushService,
                          AbstractBillLinkService billLinkService,
                          AbstractPrintTemplateService printTemplateService) {
        this.billService = billService;
        this.pushService = pushService;
        this.billLinkService = billLinkService;
        this.printTemplateService = printTemplateService;
    }

    /**
     * 单据列表查询（GET，兼容旧版扁平参数）。结构化的查询条件请使用 POST /list。
     */
    @GetMapping("/list")
    public Result<PageResult<Map<String, Object>>> list(@PathVariable String boCode,
                                                        PageRequest pageRequest,
                                                        @RequestParam(required = false) Map<String, Object> params) {
        Map<String, Object> queryParams = params != null ? new HashMap<>(params) : new HashMap<>();
        return Result.ok(billService.listBills(boCode, pageRequest, queryParams));
    }

    /**
     * 单据列表查询（POST，结构化查询条件）。
     * <pre>
     * {
     *   "conditions": [
     *     {"field_code": "code", "operator": "like", "value": "0007"},
     *     {"field_code": "pact_state", "operator": "eq", "value": 1},
     *     {"field_code": "pact_date", "operator": "between", "value_start": "2026-07-01", "value_end": "2026-07-31"}
     *   ],
     *   "pageNum": 1,
     *   "pageSize": 20
     * }
     * </pre>
     */
    @PostMapping("/list")
    public Result<PageResult<Map<String, Object>>> listPost(@PathVariable String boCode,
                                                             @RequestBody Map<String, Object> body) {
        // 提取分页参数
        int pageNum = 1;
        int pageSize = 20;
        Object pn = body.get("pageNum");
        Object ps = body.get("pageSize");
        if (pn instanceof Number) pageNum = ((Number) pn).intValue();
        if (ps instanceof Number) pageSize = ((Number) ps).intValue();
        PageRequest pageRequest = new PageRequest();
        pageRequest.setPageNum(pageNum);
        pageRequest.setPageSize(pageSize);

        // 提取 conditions 数组，转换为后端 buildWhere 期望的 Map<String, Object> 格式
        Map<String, Object> queryParams = toFlatQueryParams(body.get("conditions"));
        return Result.ok(billService.listBills(boCode, pageRequest, queryParams));
    }

    /**
     * 将结构化查询条件转换为后端 buildWhere 期望的扁平 Map 格式。
     * <p>每个条件的 value 为 {"op":"like","value":"0007"} 的 Map 结构，
     * 与 resolveOp / buildCondition 中的 Map 处理逻辑对齐。</p>
     */
    @SuppressWarnings("unchecked")
    private Map<String, Object> toFlatQueryParams(Object conditionsObj) {
        Map<String, Object> result = new HashMap<>();
        if (conditionsObj instanceof List) {
            List<?> list = (List<?>) conditionsObj;
            for (Object item : list) {
                if (item instanceof Map) {
                    Map<String, Object> raw = (Map<String, Object>) item;
                    QueryCondition cond = new QueryCondition();
                    cond.setFieldCode(str(raw, "field_code"));
                    cond.setOperator(str(raw, "operator"));
                    cond.setValue(raw.get("value"));
                    cond.setValueStart(raw.get("value_start"));
                    cond.setValueEnd(raw.get("value_end"));
                    if (cond.isValid() && cond.hasValue()) {
                        result.put(cond.getFieldCode(), cond.toConditionMap());
                    }
                }
            }
        }
        return result;
    }

    private String str(Map<String, Object> map, String key) {
        Object v = map.get(key);
        return v == null ? null : v.toString();
    }

    @GetMapping("/{id}")
    public Result<Map<String, Object>> detail(@PathVariable String boCode, @PathVariable Long id) {
        return Result.ok(billService.getBillDetail(boCode, id));
    }

    @PostMapping
    public Result<Object> save(@PathVariable String boCode, @RequestBody Map<String, Object> data) {
        SecurityContext ctx = currentUser();
        BillOperationContext opCtx = BillOperationContext.builder()
                .boCode(boCode)
                .operation("save")
                .billData(data)
                .userId(ctx.getUserId())
                .userName(ctx.getUserName())
                .build();
        BillOperationResult result = billService.save(opCtx);
        if (!result.isSuccess()) {
            throw new ServiceException("SYS_500", result.getMessage());
        }
        return Result.ok(result.getData());
    }

    @PostMapping("/{id}/{action}")
    public Result<Object> operate(@PathVariable String boCode,
                                  @PathVariable Long id,
                                  @PathVariable String action,
                                  @RequestBody(required = false) Map<String, Object> data) {
        SecurityContext ctx = currentUser();
        String reason = null;
        if (data != null) {
            Object reasonObj = data.get("reason");
            if (reasonObj != null) {
                reason = reasonObj.toString();
            }
        }
        BillOperationContext opCtx = BillOperationContext.builder()
                .boCode(boCode)
                .billId(id)
                .operation(action)
                .billData(data)
                .userId(ctx.getUserId())
                .userName(ctx.getUserName())
                .reason(reason)
                .build();
        BillOperationResult result = billService.operate(opCtx);
        if (!result.isSuccess()) {
            throw new ServiceException("SYS_500", result.getMessage());
        }
        return Result.ok(result.getData() != null ? result.getData() : result.getMessage());
    }

    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable String boCode, @PathVariable Long id) {
        SecurityContext ctx = currentUser();
        BillOperationContext opCtx = BillOperationContext.builder()
                .boCode(boCode)
                .billId(id)
                .operation("delete")
                .userId(ctx.getUserId())
                .userName(ctx.getUserName())
                .build();
        BillOperationResult result = billService.operate(opCtx);
        if (!result.isSuccess()) {
            throw new ServiceException("SYS_500", result.getMessage());
        }
        return Result.ok();
    }

    // ==================== B1 新增端点：下推/追溯/打印 ====================

    /**
     * 下推生成目标单据（对齐设计文档 02 §3.7 / §6.3）。
     *
     * <p>请求体示例：</p>
     * <pre>{
     *   "srcBillId": 1001,
     *   "tgtBoCode": "pur_order",
     *   "ruleCode": "sal_order_to_pur_order",
     *   "lines": [{"lineId": 5001, "pushQty": 10}],
     *   "allowMerge": false,
     *   "allowSplit": false
     * }</pre>
     */
    @PostMapping("/push")
    public Result<PushResult> push(@PathVariable String boCode, @RequestBody PushRequest req) {
        if (req == null || req.getSrcBillId() == null) {
            throw new ServiceException("BILL_001", "下推请求缺少源单ID");
        }
        SecurityContext ctx = currentUser();
        PushContext pushCtx = new PushContext();
        pushCtx.setSrcBoCode(boCode);
        pushCtx.setSrcBillId(req.getSrcBillId());
        pushCtx.setTgtBoCode(req.getTgtBoCode());
        pushCtx.setRuleCode(req.getRuleCode());
        pushCtx.setLines(req.getLines());
        pushCtx.setAllowMerge(req.getAllowMerge());
        pushCtx.setAllowSplit(req.getAllowSplit());
        pushCtx.setUserId(ctx.getUserId());
        pushCtx.setUserName(ctx.getUserName());
        PushResult result = pushService.push(pushCtx);
        if (!result.isSuccess()) {
            throw new ServiceException("BILL_501", result.getMessage());
        }
        return Result.ok(result);
    }

    /**
     * 单据追溯树（对齐设计文档 02 §3.6）。
     *
     * @param direction 方向：up=上查源单 / down=下查目标单（默认 down）
     * @param maxDepth  最大深度（默认 5）
     */
    @GetMapping("/{id}/trace")
    public Result<TraceTree> trace(@PathVariable String boCode,
                                   @PathVariable Long id,
                                   @RequestParam(required = false, defaultValue = "down") String direction,
                                   @RequestParam(required = false) Integer maxDepth) {
        TraceTree tree;
        if (maxDepth != null && maxDepth > 0) {
            tree = billLinkService.buildTraceTree(boCode, id, direction, maxDepth);
        } else {
            tree = billLinkService.buildTraceTree(boCode, id, direction);
        }
        return Result.ok(tree);
    }

    /**
     * 打印渲染（对齐设计文档 02 §3.8）。
     *
     * <p>查询参数：</p>
     * <ul>
     *   <li>{@code templateId}：模板ID（指定渲染）；不传则取 boCode 的默认模板</li>
     *   <li>{@code billIds}：批量套打单据ID列表（逗号分隔，如 1001,1002）；不传则单据渲染当前 id</li>
     * </ul>
     */
    @GetMapping("/{id}/print")
    public ResponseEntity<byte[]> print(@PathVariable String boCode,
                                        @PathVariable Long id,
                                        @RequestParam(required = false) Long templateId,
                                        @RequestParam(required = false) String billIds) {
        Long tplId = templateId;
        if (tplId == null) {
            tplId = printTemplateService.getDefault(boCode) != null
                    ? printTemplateService.getDefault(boCode).getId()
                    : null;
        }
        if (tplId == null) {
            throw new ServiceException("PRINT_001", "未找到业务对象 [" + boCode + "] 的打印模板");
        }

        byte[] bytes;
        if (billIds != null && !billIds.isEmpty()) {
            // 批量套打
            List<Long> ids = parseBillIds(billIds);
            bytes = printTemplateService.renderBatch(tplId, ids);
        } else {
            bytes = printTemplateService.render(tplId, id);
        }

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.TEXT_HTML);
        headers.setContentDispositionFormData("inline", boCode + "_" + id + ".html");
        return new ResponseEntity<>(bytes, headers, org.springframework.http.HttpStatus.OK);
    }

    // ==================== 内部工具 ====================

    private SecurityContext currentUser() {
        SecurityContext ctx = SecurityContextHolder.get();
        if (ctx == null) {
            throw new ServiceException("AUTH_001", "未登录");
        }
        return ctx;
    }

    private List<Long> parseBillIds(String billIds) {
        List<Long> result = new java.util.ArrayList<>();
        for (String s : billIds.split(",")) {
            String trimmed = s.trim();
            if (!trimmed.isEmpty()) {
                try {
                    result.add(Long.parseLong(trimmed));
                } catch (NumberFormatException e) {
                    throw new ServiceException("BILL_002", "无效的单据ID: " + trimmed);
                }
            }
        }
        return result;
    }

    // ==================== 下推请求 DTO ====================

    /**
     * 下推请求体（对齐 PushContext 字段，前端提交）。
     */
    @lombok.Data
    public static class PushRequest {
        private Long srcBillId;
        private String tgtBoCode;
        private String ruleCode;
        private List<PushLine> lines;
        private Boolean allowMerge;
        private Boolean allowSplit;
    }
}
