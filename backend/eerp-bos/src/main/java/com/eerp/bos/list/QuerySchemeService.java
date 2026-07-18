package com.eerp.bos.list;

import com.eerp.common.id.SnowflakeIdGenerator;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 查询方案与用户列设置服务，管理 user_query_scheme 与 user_list_setting 表
 */
@Service
public class QuerySchemeService {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Autowired
    private SnowflakeIdGenerator snowflakeIdGenerator;

    /**
     * 查询用户可见方案（私有 + 公共）
     */
    public List<Map<String, Object>> listSchemes(String boCode, Long userId) {
        String sql = "SELECT * FROM user_query_scheme WHERE bo_code = ? AND (user_id = ? OR is_public = 1) "
                + "ORDER BY is_default DESC, is_favorite DESC, update_time DESC";
        return jdbcTemplate.queryForList(sql, boCode, userId);
    }

    /**
     * 保存方案（新增或更新）
     */
    @Transactional(rollbackFor = Exception.class)
    public Map<String, Object> saveScheme(Map<String, Object> scheme) {
        Long id = toLong(scheme.get("id"));
        if (id != null && exists(id)) {
            StringBuilder sql = new StringBuilder("UPDATE user_query_scheme SET ");
            buildSetClause(sql, scheme, id);
            jdbcTemplate.update(sql.toString());
        } else {
            id = snowflakeIdGenerator.nextId();
            scheme.put("id", id);
            scheme.putIfAbsent("create_time", LocalDateTime.now());
            scheme.putIfAbsent("update_time", LocalDateTime.now());
            jdbcTemplate.update(
                    "INSERT INTO user_query_scheme (id, user_id, bo_code, scheme_name, condition_json, columns_json, "
                            + "order_by, page_size, is_default, is_favorite, is_public, create_time, update_time) "
                            + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                    id, scheme.get("user_id"), scheme.get("bo_code"), scheme.get("scheme_name"),
                    scheme.get("condition_json"), scheme.get("columns_json"), scheme.get("order_by"),
                    toInt(scheme.get("page_size"), 20), toInt(scheme.get("is_default"), 0),
                    toInt(scheme.get("is_favorite"), 0), toInt(scheme.get("is_public"), 0),
                    scheme.get("create_time"), scheme.get("update_time"));
        }
        return getScheme(id);
    }

    /**
     * 删除方案
     */
    @Transactional(rollbackFor = Exception.class)
    public void deleteScheme(Long id) {
        jdbcTemplate.update("DELETE FROM user_query_scheme WHERE id = ?", id);
    }

    /**
     * 设为默认（同用户同业务对象下仅一个默认）
     */
    @Transactional(rollbackFor = Exception.class)
    public void setDefault(Long id) {
        Map<String, Object> scheme = getScheme(id);
        if (scheme == null) {
            return;
        }
        Object userId = scheme.get("user_id");
        Object boCode = scheme.get("bo_code");
        jdbcTemplate.update(
                "UPDATE user_query_scheme SET is_default = 0, update_time = ? WHERE user_id = ? AND bo_code = ?",
                LocalDateTime.now(), userId, boCode);
        jdbcTemplate.update(
                "UPDATE user_query_scheme SET is_default = 1, update_time = ? WHERE id = ?",
                LocalDateTime.now(), id);
    }

    public Map<String, Object> getScheme(Long id) {
        try {
            return jdbcTemplate.queryForMap("SELECT * FROM user_query_scheme WHERE id = ?", id);
        } catch (EmptyResultDataAccessException e) {
            return null;
        }
    }

    /**
     * 获取用户列设置
     */
    public Map<String, Object> getUserListSetting(String boCode, Long userId) {
        try {
            return jdbcTemplate.queryForMap(
                    "SELECT * FROM user_list_setting WHERE user_id = ? AND bo_code = ?", userId, boCode);
        } catch (EmptyResultDataAccessException e) {
            return new LinkedHashMap<>();
        }
    }

    /**
     * 保存用户列设置（按 user_id + bo_code 唯一键 upsert）
     */
    @Transactional(rollbackFor = Exception.class)
    public void saveUserListSetting(Map<String, Object> setting) {
        Object userId = setting.get("user_id");
        Object boCode = setting.get("bo_code");
        boolean exists = existsUserListSetting(userId, boCode);
        LocalDateTime now = LocalDateTime.now();
        if (exists) {
            jdbcTemplate.update(
                    "UPDATE user_list_setting SET columns_json = ?, page_size = ?, update_time = ? "
                            + "WHERE user_id = ? AND bo_code = ?",
                    setting.get("columns_json"), toInt(setting.get("page_size"), 20), now, userId, boCode);
        } else {
            long id = snowflakeIdGenerator.nextId();
            jdbcTemplate.update(
                    "INSERT INTO user_list_setting (id, user_id, bo_code, columns_json, page_size, update_time) "
                            + "VALUES (?, ?, ?, ?, ?, ?)",
                    id, userId, boCode, setting.get("columns_json"), toInt(setting.get("page_size"), 20), now);
        }
    }

    // ---------------- 内部工具方法 ----------------

    private boolean exists(Long id) {
        Integer cnt = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM user_query_scheme WHERE id = ?", Integer.class, id);
        return cnt != null && cnt > 0;
    }

    private boolean existsUserListSetting(Object userId, Object boCode) {
        Integer cnt = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM user_list_setting WHERE user_id = ? AND bo_code = ?",
                Integer.class, userId, boCode);
        return cnt != null && cnt > 0;
    }

    private void buildSetClause(StringBuilder sql, Map<String, Object> scheme, Long id) {
        List<String> cols = java.util.Arrays.asList(
                "scheme_name", "condition_json", "columns_json", "order_by",
                "page_size", "is_default", "is_favorite", "is_public");
        List<Object> args = new java.util.ArrayList<>();
        boolean first = true;
        for (String c : cols) {
            if (scheme.containsKey(c)) {
                if (!first) {
                    sql.append(", ");
                }
                sql.append(c).append(" = ?");
                args.add(scheme.get(c));
                first = false;
            }
        }
        if (!first) {
            sql.append(", ");
        }
        sql.append("update_time = ?");
        args.add(LocalDateTime.now());
        sql.append(" WHERE id = ?");
        args.add(id);
        jdbcTemplate.update(sql.toString(), args.toArray());
    }

    private Long toLong(Object v) {
        if (v == null) {
            return null;
        }
        if (v instanceof Number) {
            return ((Number) v).longValue();
        }
        String s = v.toString().trim();
        if (s.isEmpty()) {
            return null;
        }
        try {
            return Long.parseLong(s);
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private int toInt(Object v, int def) {
        if (v == null) {
            return def;
        }
        if (v instanceof Number) {
            return ((Number) v).intValue();
        }
        try {
            return Integer.parseInt(v.toString().trim());
        } catch (NumberFormatException e) {
            return def;
        }
    }
}
