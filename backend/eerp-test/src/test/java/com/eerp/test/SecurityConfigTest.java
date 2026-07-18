package com.eerp.test;

import com.eerp.common.security.JwtAuthenticationFilter;
import com.eerp.common.security.JwtUtil;
import com.eerp.common.security.SecurityConfig;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfSystemProperty;
import org.springframework.security.crypto.password.PasswordEncoder;

import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * 安全配置单元测试
 * <p>
 * 注意：完整的 SecurityFilterChain 测试需要 Spring Web 上下文（HttpSecurity 依赖），
 * 此处仅测试可独立验证的部分（PasswordEncoder、配置类构造）。SecurityFilterChain 集成测试
 * 需通过 @SpringBootTest 在 eerp-api 模块完成。
 */
class SecurityConfigTest {

    private SecurityConfig securityConfig;

    @BeforeEach
    void setUp() {
        JwtUtil jwtUtil = new JwtUtil();
        JwtAuthenticationFilter filter = new JwtAuthenticationFilter(jwtUtil);
        securityConfig = new SecurityConfig(filter);
    }

    @Test
    @DisplayName("PasswordEncoder使用BCrypt并能验证密码")
    void testPasswordEncoder() {
        PasswordEncoder encoder = securityConfig.passwordEncoder();
        assertNotNull(encoder, "PasswordEncoder不应为空");

        String rawPassword = "admin123";
        String encoded = encoder.encode(rawPassword);
        assertNotNull(encoded);
        assertTrue(encoder.matches(rawPassword, encoded), "BCrypt应能匹配编码后的密码");
        assertTrue(!rawPassword.equals(encoded), "编码后密码不应与原文相同");
    }

    @Test
    @DisplayName("SecurityConfig可正常构造")
    void testSecurityConfigConstruction() {
        assertNotNull(securityConfig, "SecurityConfig实例应正常创建");
    }
}
