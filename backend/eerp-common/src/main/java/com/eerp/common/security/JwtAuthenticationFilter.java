package com.eerp.common.security;

import io.jsonwebtoken.Claims;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Collections;

/**
 * JWT 认证过滤器
 *
 * <p>注意：本类所在包 com.eerp.common.security 已存在业务侧
 * {@link SecurityContextHolder}，故 Spring Security 的同名类采用全限定名引用以避免歧义。</p>
 */
@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private static final String AUTH_HEADER = "Authorization";
    private static final String BEARER_PREFIX = "Bearer ";

    private final JwtUtil jwtUtil;

    public JwtAuthenticationFilter(JwtUtil jwtUtil) {
        this.jwtUtil = jwtUtil;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        try {
            String path = request.getRequestURI();
            // 放行登录/登出
            if ("/api/auth/login".equals(path) || "/api/auth/logout".equals(path)) {
                filterChain.doFilter(request, response);
                return;
            }

            String header = request.getHeader(AUTH_HEADER);
            if (header != null && header.startsWith(BEARER_PREFIX)) {
                String token = header.substring(BEARER_PREFIX.length());
                try {
                    if (jwtUtil.validateToken(token)) {
                        Claims claims = jwtUtil.parseToken(token);
                        Long userId = Long.parseLong(claims.getSubject());
                        String userName = claims.get("userName", String.class);

                        // 设置业务侧安全上下文
                        SecurityContext context = new SecurityContext();
                        context.setUserId(userId);
                        context.setUserName(userName);
                        SecurityContextHolder.set(context);

                        // 设置 Spring Security 上下文，用于后续授权
                        UsernamePasswordAuthenticationToken authentication =
                                new UsernamePasswordAuthenticationToken(
                                        userName, null,
                                        Collections.singletonList(new SimpleGrantedAuthority("ROLE_USER")));
                        org.springframework.security.core.context.SecurityContextHolder
                                .getContext().setAuthentication(authentication);
                    }
                } catch (Exception ignored) {
                    // token 无效时不设置上下文，交由后续 Security 链处理
                }
            }

            filterChain.doFilter(request, response);
        } finally {
            // 清理 ThreadLocal，避免线程池复用导致的上下文泄漏
            SecurityContextHolder.clear();
        }
    }
}
