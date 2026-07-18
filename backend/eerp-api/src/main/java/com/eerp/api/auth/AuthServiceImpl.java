package com.eerp.api.auth;

import com.eerp.common.exception.ServiceException;
import com.eerp.common.security.JwtUtil;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.Map;

@Service
public class AuthServiceImpl implements AuthService {

    private final JdbcTemplate jdbcTemplate;
    private final JwtUtil jwtUtil;
    private final PasswordEncoder passwordEncoder;

    public AuthServiceImpl(JdbcTemplate jdbcTemplate, JwtUtil jwtUtil, PasswordEncoder passwordEncoder) {
        this.jdbcTemplate = jdbcTemplate;
        this.jwtUtil = jwtUtil;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    public LoginResponse login(LoginRequest request) {
        if (request == null || request.getUsername() == null || request.getPassword() == null) {
            throw new ServiceException("AUTH_001", "用户名或密码不能为空");
        }

        Map<String, Object> user;
        try {
            user = jdbcTemplate.queryForMap(
                    "SELECT id, username, password, real_name, org_id, dept_id, status FROM sys_user WHERE username = ?",
                    request.getUsername());
        } catch (EmptyResultDataAccessException e) {
            throw new ServiceException("AUTH_001", "用户不存在或密码错误");
        }

        Integer status = toInt(user.get("status"));
        if (status == null || status != 1) {
            throw new ServiceException("AUTH_001", "账号已停用");
        }

        String dbPassword = (String) user.get("password");
        if (dbPassword == null || !passwordEncoder.matches(request.getPassword(), dbPassword)) {
            throw new ServiceException("AUTH_001", "用户不存在或密码错误");
        }

        Long userId = toLong(user.get("id"));
        String username = (String) user.get("username");
        String realName = (String) user.get("real_name");

        Long orgId = toLong(user.get("org_id"));
        String orgName = resolveOrgName(userId, orgId);

        String token = jwtUtil.generateToken(userId, username);

        return LoginResponse.builder()
                .token(token)
                .userId(userId)
                .username(username)
                .realName(realName)
                .orgId(orgId)
                .orgName(orgName)
                .build();
    }

    @Override
    public void logout() {
        // 无状态 JWT：客户端丢弃 token 即可
    }

    private String resolveOrgName(Long userId, Long defaultOrgId) {
        Long orgId = defaultOrgId;
        if (userId != null) {
            try {
                Map<String, Object> row = jdbcTemplate.queryForMap(
                        "SELECT org_id FROM sys_user_org WHERE user_id = ? AND is_main = 1 LIMIT 1", userId);
                Long mainOrg = toLong(row.get("org_id"));
                if (mainOrg != null) {
                    orgId = mainOrg;
                }
            } catch (EmptyResultDataAccessException ignored) {
                // 无主组织记录，使用 sys_user.org_id
            }
        }
        if (orgId == null) {
            return null;
        }
        try {
            Map<String, Object> org = jdbcTemplate.queryForMap(
                    "SELECT name FROM sys_org WHERE id = ?", orgId);
            return (String) org.get("name");
        } catch (EmptyResultDataAccessException e) {
            return null;
        }
    }

    private Long toLong(Object v) {
        if (v == null) {
            return null;
        }
        if (v instanceof Number) {
            return ((Number) v).longValue();
        }
        try {
            return Long.parseLong(v.toString().trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private Integer toInt(Object v) {
        if (v == null) {
            return null;
        }
        if (v instanceof Number) {
            return ((Number) v).intValue();
        }
        try {
            return Integer.parseInt(v.toString().trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }
}
