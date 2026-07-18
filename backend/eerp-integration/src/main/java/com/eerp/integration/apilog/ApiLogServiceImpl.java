package com.eerp.integration.apilog;

import com.eerp.common.api.PageRequest;
import com.eerp.common.api.PageResult;
import com.eerp.common.id.SnowflakeIdGenerator;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.BeanPropertyRowMapper;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * API 日志服务实现。
 *
 * <p>依赖 {@link JdbcTemplate} 写入/查询 sys_api_log。
 * {@link #log} 写入主流程之外的调用日志，支持按 apiPath/method/userId/errorCode/耗时区间分页检索。</p>
 */
@Service
public class ApiLogServiceImpl extends AbstractApiLogService {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Autowired
    private SnowflakeIdGenerator snowflakeIdGenerator;

    /**
     * 记录一条 API 调用日志。
     *
     * @param apiPath        请求路径（写入 api_url）
     * @param method         HTTP 方法
     * @param userId         调用人ID（写入 call_by）
     * @param requestParams  请求参数（写入 request_body）
     * @param responseResult 响应结果（写入 response_body）
     * @param costMs         耗时毫秒
     * @param errorCode      错误码（非空表示失败，写入 error_msg；is_success=0）
     */
    public void log(String apiPath, String method, Long userId, String requestParams,
                    String responseResult, Long costMs, String errorCode) {
        long id = snowflakeIdGenerator.nextId();
        int isSuccess = StringUtils.hasText(errorCode) ? 0 : 1;
        Integer duration = costMs == null ? null : costMs.intValue();
        String callBy = userId == null ? null : String.valueOf(userId);

        jdbcTemplate.update(
                "INSERT INTO sys_api_log (id, api_url, api_method, request_body, response_body, " +
                        "duration_ms, is_success, error_msg, call_by, call_time) " +
                        "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                id, apiPath, method, requestParams, responseResult,
                duration, isSuccess, errorCode, callBy, LocalDateTime.now());
    }

    /**
     * 分页查询 API 日志，支持按 apiPath/method/userId/errorCode/耗时区间过滤。
     *
     * @param pageRequest 分页请求
     * @param filters     过滤条件，支持的 key：apiPath、method、userId、errorCode、costMin、costMax
     * @return 分页结果
     */
    public PageResult<ApiLogEntity> page(PageRequest pageRequest, Map<String, Object> filters) {
        int pageNum = pageRequest.getPageNum() <= 0 ? 1 : pageRequest.getPageNum();
        int pageSize = pageRequest.getPageSize() <= 0 ? 20 : pageRequest.getPageSize();
        int offset = (pageNum - 1) * pageSize;

        StringBuilder where = new StringBuilder(" WHERE 1=1 ");
        List<Object> args = new ArrayList<>();
        applyFilters(where, args, filters);

        Long total = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM sys_api_log" + where, Long.class, args.toArray());

        String orderBy = StringUtils.hasText(pageRequest.getOrderBy())
                ? " ORDER BY " + sanitizeOrderBy(pageRequest.getOrderBy())
                : " ORDER BY call_time DESC";

        List<ApiLogEntity> list = jdbcTemplate.query(
                "SELECT id, category, api_type, source_code, bo_code, bill_id, api_url, api_method, " +
                        "request_body, response_body, status_code, duration_ms, is_success, error_msg, " +
                        "call_by, call_time FROM sys_api_log" + where + orderBy + " LIMIT ? OFFSET ?",
                new BeanPropertyRowMapper<>(ApiLogEntity.class),
                appendArgs(args, pageSize, offset));

        long totalVal = total == null ? 0L : total;
        return new PageResult<>(list, totalVal, pageNum, pageSize);
    }

    /**
     * 查询日志详情。
     *
     * @param id 日志ID
     * @return 日志记录，不存在返回 null
     */
    public ApiLogEntity getById(Long id) {
        List<ApiLogEntity> list = jdbcTemplate.query(
                "SELECT id, category, api_type, source_code, bo_code, bill_id, api_url, api_method, " +
                        "request_body, response_body, status_code, duration_ms, is_success, error_msg, " +
                        "call_by, call_time FROM sys_api_log WHERE id = ?",
                new BeanPropertyRowMapper<>(ApiLogEntity.class), id);
        return list.isEmpty() ? null : list.get(0);
    }

    // ---------------- 内部工具方法 ----------------

    private void applyFilters(StringBuilder where, List<Object> args, Map<String, Object> filters) {
        if (filters == null || filters.isEmpty()) {
            return;
        }
        Object apiPath = filters.get("apiPath");
        if (apiPath != null && StringUtils.hasText(apiPath.toString())) {
            where.append(" AND api_url LIKE ? ");
            args.add("%" + apiPath + "%");
        }
        Object method = filters.get("method");
        if (method != null && StringUtils.hasText(method.toString())) {
            where.append(" AND api_method = ? ");
            args.add(method.toString());
        }
        Object userId = filters.get("userId");
        if (userId != null && StringUtils.hasText(userId.toString())) {
            where.append(" AND call_by = ? ");
            args.add(String.valueOf(userId));
        }
        Object errorCode = filters.get("errorCode");
        if (errorCode != null && StringUtils.hasText(errorCode.toString())) {
            where.append(" AND error_msg LIKE ? ");
            args.add("%" + errorCode + "%");
        }
        Object costMin = filters.get("costMin");
        if (costMin != null) {
            where.append(" AND duration_ms >= ? ");
            args.add(((Number) costMin).longValue());
        }
        Object costMax = filters.get("costMax");
        if (costMax != null) {
            where.append(" AND duration_ms <= ? ");
            args.add(((Number) costMax).longValue());
        }
    }

    private Object[] appendArgs(List<Object> args, int pageSize, int offset) {
        List<Object> all = new ArrayList<>(args);
        all.add(pageSize);
        all.add(offset);
        return all.toArray();
    }

    /**
     * 简单过滤排序字段，仅允许字母、数字、下划线、点、空格、逗号，避免 SQL 注入。
     */
    private String sanitizeOrderBy(String orderBy) {
        return orderBy.replaceAll("[^a-zA-Z0-9_., ]", "");
    }
}
