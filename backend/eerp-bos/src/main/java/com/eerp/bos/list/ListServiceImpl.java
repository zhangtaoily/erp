package com.eerp.bos.list;

import com.eerp.common.api.PageRequest;
import com.eerp.common.api.PageResult;
import com.eerp.meta.bo.vo.FormMetaVO;
import com.eerp.meta.cache.FormMetaCache;
import com.eerp.meta.list.entity.MetaListColumn;
import com.eerp.meta.list.entity.MetaQueryField;
import com.eerp.meta.list.service.MetaListColumnService;
import com.eerp.meta.list.service.MetaQueryFieldService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * 列表查询服务实现：基于元数据动态构建分页查询 SQL
 * <p>
 * 列名/表名来自元数据（可信），数据值参数化。ORDER BY 字段经白名单校验。
 */
@Service
public class ListServiceImpl extends AbstractListService {

    @Autowired
    private MetaListColumnService metaListColumnService;

    @Autowired
    private MetaQueryFieldService metaQueryFieldService;

    @Autowired
    private FormMetaCache formMetaCache;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    private static final Set<String> ALLOWED_OPS = new HashSet<>(Arrays.asList(
            "eq", "ne", "gt", "lt", "ge", "le", "like", "not_like",
            "begin_with", "end_with", "is_null", "is_not_null", "in", "between"));

    private static final Set<String> SYSTEM_ORDER_COLS = new HashSet<>(Arrays.asList(
            "id", "create_time", "update_time", "pact_state", "code"));

    @Override
    public PageResult<Map<String, Object>> page(String boCode, PageRequest pageRequest, Map<String, Object> params) {
        String mainTable = resolveMainTable(boCode);
        if (mainTable == null) {
            return new PageResult<>(Collections.emptyList(), 0, pageRequest.getPageNum(), pageRequest.getPageSize());
        }

        // 列定义
        List<MetaListColumn> columns = metaListColumnService.listByBoCode(boCode);
        List<String> selectCols = new ArrayList<>();
        Set<String> colWhitelist = new HashSet<>(SYSTEM_ORDER_COLS);
        if (columns != null) {
            for (MetaListColumn c : columns) {
                Integer isShow = c.getIsShow();
                Integer isEnable = c.getIsEnable();
                if (c.getFieldCode() != null
                        && (isShow == null || isShow == 1)
                        && (isEnable == null || isEnable == 1)) {
                    selectCols.add(c.getFieldCode());
                }
                if (c.getFieldCode() != null) {
                    colWhitelist.add(c.getFieldCode());
                }
            }
        }

        String selectSql = selectCols.isEmpty() ? "*" : buildColumnList(selectCols);

        // 查询字段配置
        List<MetaQueryField> queryFields = metaQueryFieldService.listByBoCode(boCode);
        Map<String, MetaQueryField> queryFieldMap = new HashMap<>();
        if (queryFields != null) {
            for (MetaQueryField qf : queryFields) {
                if (qf.getIsEnable() == null || qf.getIsEnable() == 1) {
                    queryFieldMap.put(qf.getFieldCode(), qf);
                }
            }
        }

        // 构建 WHERE
        List<Object> args = new ArrayList<>();
        String whereSql = buildWhere(params, queryFieldMap, args);

        // ORDER BY
        String orderSql = buildOrderBy(pageRequest.getOrderBy(), colWhitelist);

        // 分页
        int pageNum = pageRequest.getPageNum() <= 0 ? 1 : pageRequest.getPageNum();
        int pageSize = pageRequest.getPageSize() <= 0 ? 20 : pageRequest.getPageSize();
        int offset = (pageNum - 1) * pageSize;

        String query = "SELECT " + selectSql + " FROM `" + mainTable + "`"
                + (whereSql.isEmpty() ? "" : " WHERE " + whereSql)
                + (orderSql.isEmpty() ? "" : " ORDER BY " + orderSql)
                + " LIMIT ?, ?";

        List<Object> queryArgs = new ArrayList<>(args);
        queryArgs.add(offset);
        queryArgs.add(pageSize);

        List<Map<String, Object>> list = jdbcTemplate.queryForList(query, queryArgs.toArray());

        String countSql = "SELECT COUNT(*) FROM `" + mainTable + "`"
                + (whereSql.isEmpty() ? "" : " WHERE " + whereSql);
        Long total = jdbcTemplate.queryForObject(countSql, Long.class, args.toArray());
        if (total == null) {
            total = 0L;
        }

        return new PageResult<>(list, total, pageNum, pageSize);
    }

    private String resolveMainTable(String boCode) {
        FormMetaVO meta = formMetaCache.get(boCode);
        if (meta == null || meta.getBusinessObject() == null) {
            return null;
        }
        return meta.getBusinessObject().getMainTable();
    }

    private String buildColumnList(List<String> cols) {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < cols.size(); i++) {
            if (i > 0) {
                sb.append(", ");
            }
            sb.append("`").append(cols.get(i)).append("`");
        }
        return sb.toString();
    }

    /**
     * 构建参数化 WHERE 子句。仅允许查询字段配置中声明的字段参与过滤。
     */
    @SuppressWarnings("unchecked")
    private String buildWhere(Map<String, Object> params, Map<String, MetaQueryField> queryFieldMap,
                              List<Object> args) {
        if (params == null || params.isEmpty()) {
            return "";
        }
        StringBuilder sb = new StringBuilder();
        for (Map.Entry<String, Object> entry : params.entrySet()) {
            String fieldCode = entry.getKey();
            MetaQueryField qf = queryFieldMap.get(fieldCode);
            if (qf == null) {
                // 未在查询字段配置中声明，跳过（防注入）
                continue;
            }
            String op = resolveOp(qf, entry.getValue());
            if (op == null || !ALLOWED_OPS.contains(op)) {
                continue;
            }
            String fragment = buildCondition(fieldCode, op, entry.getValue(), args);
            if (fragment != null) {
                if (sb.length() > 0) {
                    sb.append(" AND ");
                }
                sb.append(fragment);
            }
        }
        return sb.toString();
    }

    @SuppressWarnings("unchecked")
    private String resolveOp(MetaQueryField qf, Object value) {
        String allowed = qf.getOperators();
        Set<String> allowedSet = new HashSet<>();
        if (allowed != null) {
            for (String s : allowed.split(",")) {
                String t = s.trim().toLowerCase();
                if (!t.isEmpty()) {
                    allowedSet.add(t);
                }
            }
        }
        String op = null;
        Object rawValue = value;
        if (value instanceof Map) {
            Object opObj = ((Map<String, Object>) value).get("op");
            if (opObj != null) {
                op = opObj.toString().trim().toLowerCase();
            }
            rawValue = ((Map<String, Object>) value).get("value");
        }
        if (op == null || op.isEmpty()) {
            op = qf.getDefaultOp();
            if (op != null) {
                op = op.trim().toLowerCase();
            }
        }
        if (op == null || op.isEmpty()) {
            op = "eq";
        }
        if (!allowedSet.isEmpty() && !allowedSet.contains(op)) {
            return null;
        }
        // is_null / is_not_null 不需要值；其余要求值非空
        if (!"is_null".equals(op) && !"is_not_null".equals(op)) {
            if (rawValue == null || (rawValue instanceof String && ((String) rawValue).isEmpty())) {
                return null;
            }
        }
        return op;
    }

    @SuppressWarnings("unchecked")
    private String buildCondition(String fieldCode, String op, Object value, List<Object> args) {
        String col = "`" + fieldCode + "`";
        Object rawValue = value;
        if (value instanceof Map) {
            rawValue = ((Map<String, Object>) value).get("value");
        }
        switch (op) {
            case "eq":
                args.add(rawValue);
                return col + " = ?";
            case "ne":
                args.add(rawValue);
                return col + " <> ?";
            case "gt":
                args.add(rawValue);
                return col + " > ?";
            case "lt":
                args.add(rawValue);
                return col + " < ?";
            case "ge":
                args.add(rawValue);
                return col + " >= ?";
            case "le":
                args.add(rawValue);
                return col + " <= ?";
            case "like":
                args.add("%" + rawValue + "%");
                return col + " LIKE ?";
            case "not_like":
                args.add("%" + rawValue + "%");
                return col + " NOT LIKE ?";
            case "begin_with":
                args.add(rawValue + "%");
                return col + " LIKE ?";
            case "end_with":
                args.add("%" + rawValue);
                return col + " LIKE ?";
            case "is_null":
                return col + " IS NULL";
            case "is_not_null":
                return col + " IS NOT NULL";
            case "in": {
                Collection<Object> items;
                if (rawValue instanceof Collection) {
                    items = new ArrayList<>((Collection<Object>) rawValue);
                } else if (rawValue.getClass().isArray()) {
                    items = new ArrayList<>(Arrays.asList((Object[]) rawValue));
                } else {
                    items = Collections.singletonList(rawValue);
                }
                if (items.isEmpty()) {
                    return null;
                }
                StringBuilder placeholders = new StringBuilder();
                int i = 0;
                for (Object it : items) {
                    if (i++ > 0) {
                        placeholders.append(",");
                    }
                    placeholders.append("?");
                    args.add(it);
                }
                return col + " IN (" + placeholders + ")";
            }
            case "between": {
                List<Object> pair;
                if (rawValue instanceof Collection) {
                    pair = new ArrayList<>((Collection<Object>) rawValue);
                } else if (rawValue.getClass().isArray()) {
                    pair = Arrays.asList((Object[]) rawValue);
                } else {
                    return null;
                }
                if (pair.size() < 2) {
                    return null;
                }
                args.add(pair.get(0));
                args.add(pair.get(1));
                return col + " BETWEEN ? AND ?";
            }
            default:
                return null;
        }
    }

    /**
     * 构建安全 ORDER BY：仅允许白名单列名与 asc/desc 方向
     */
    private String buildOrderBy(String orderBy, Set<String> whitelist) {
        if (orderBy == null || orderBy.trim().isEmpty()) {
            return "";
        }
        StringBuilder sb = new StringBuilder();
        for (String part : orderBy.split(",")) {
            String p = part.trim();
            if (p.isEmpty()) {
                continue;
            }
            String direction = "ASC";
            String col = p;
            int sp = p.lastIndexOf(' ');
            if (sp > 0) {
                col = p.substring(0, sp).trim();
                String dir = p.substring(sp + 1).trim().toLowerCase();
                if ("desc".equals(dir)) {
                    direction = "DESC";
                } else if (!"asc".equals(dir)) {
                    continue;
                }
            }
            if (!whitelist.contains(col)) {
                continue;
            }
            if (sb.length() > 0) {
                sb.append(", ");
            }
            sb.append("`").append(col).append("` ").append(direction);
        }
        return sb.toString();
    }
}
