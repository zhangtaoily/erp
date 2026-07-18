package com.eerp.api.integration;

import com.eerp.common.api.PageRequest;
import com.eerp.common.api.PageResult;
import com.eerp.common.api.Result;
import com.eerp.common.exception.ServiceException;
import com.eerp.integration.apilog.ApiLogEntity;
import com.eerp.integration.apilog.ApiLogServiceImpl;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

/**
 * API 日志 Controller（B1 新增，对齐设计文档 07 §5）。
 *
 * <p>端点清单：</p>
 * <ul>
 *   <li>{@code GET /api/api-log} — 分页查询 API 日志（支持 apiPath/method/userId/errorCode/costMin/costMax 过滤）</li>
 *   <li>{@code GET /api/api-log/{id}} — 查询日志详情</li>
 * </ul>
 *
 * <p>注：日志记录由各调用方通过 {@code ApiLogServiceImpl.log()} 写入，
 * Controller 仅提供查询能力（对齐设计文档「日志查询与运维监控」要求）。</p>
 */
@RestController
@RequestMapping("/api/api-log")
public class ApiLogController {

    private final ApiLogServiceImpl apiLogService;

    public ApiLogController(ApiLogServiceImpl apiLogService) {
        this.apiLogService = apiLogService;
    }

    /**
     * 分页查询 API 日志。
     *
     * @param pageRequest 分页参数（pageNum/pageSize/orderBy）
     * @param apiPath     请求路径模糊匹配（可选）
     * @param method      HTTP 方法（可选）
     * @param userId      调用人ID（可选）
     * @param errorCode   错误码模糊匹配（可选）
     * @param costMin     最小耗时ms（可选）
     * @param costMax     最大耗时ms（可选）
     */
    @GetMapping
    public Result<PageResult<ApiLogEntity>> page(PageRequest pageRequest,
                                                  @RequestParam(required = false) String apiPath,
                                                  @RequestParam(required = false) String method,
                                                  @RequestParam(required = false) Long userId,
                                                  @RequestParam(required = false) String errorCode,
                                                  @RequestParam(required = false) Long costMin,
                                                  @RequestParam(required = false) Long costMax) {
        Map<String, Object> filters = new HashMap<>();
        if (apiPath != null && !apiPath.isEmpty()) {
            filters.put("apiPath", apiPath);
        }
        if (method != null && !method.isEmpty()) {
            filters.put("method", method);
        }
        if (userId != null) {
            filters.put("userId", userId);
        }
        if (errorCode != null && !errorCode.isEmpty()) {
            filters.put("errorCode", errorCode);
        }
        if (costMin != null) {
            filters.put("costMin", costMin);
        }
        if (costMax != null) {
            filters.put("costMax", costMax);
        }
        return Result.ok(apiLogService.page(pageRequest, filters));
    }

    /**
     * 查询日志详情。
     */
    @GetMapping("/{id}")
    public Result<ApiLogEntity> detail(@PathVariable Long id) {
        ApiLogEntity entity = apiLogService.getById(id);
        if (entity == null) {
            throw new ServiceException("APILOG_001", "API 日志不存在: " + id);
        }
        return Result.ok(entity);
    }
}
