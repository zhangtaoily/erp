package com.eerp.test;

import com.eerp.common.security.JwtUtil;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.Jwts;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import javax.crypto.SecretKey;
import java.lang.reflect.Field;
import java.util.Date;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * JWT 工具单元测试
 */
class JwtUtilTest {

    private JwtUtil jwtUtil;
    private SecretKey signingKey;

    @BeforeEach
    void setUp() throws Exception {
        jwtUtil = new JwtUtil();
        // 通过反射获取签名密钥，用于构造过期/自定义 token
        Field keyField = JwtUtil.class.getDeclaredField("key");
        keyField.setAccessible(true);
        signingKey = (SecretKey) keyField.get(jwtUtil);
    }

    @Test
    @DisplayName("生成并解析token，userId与userName一致")
    void testGenerateAndParseToken() {
        Long userId = 1001L;
        String userName = "admin";

        String token = jwtUtil.generateToken(userId, userName);
        assertNotNull(token, "生成的token不应为空");
        assertEquals(3, token.split("\\.").length, "JWT应由三段组成");

        Claims claims = jwtUtil.parseToken(token);
        assertEquals(String.valueOf(userId), claims.getSubject(), "userId应一致");
        assertEquals(userName, claims.get("userName", String.class), "userName应一致");
        assertNotNull(claims.getIssuedAt(), "签发时间不应为空");
        assertNotNull(claims.getExpiration(), "过期时间不应为空");
    }

    @Test
    @DisplayName("过期token解析失败")
    void testTokenExpiration() {
        // 用相同密钥构造一个已过期的token
        String expiredToken = Jwts.builder()
                .subject("2002")
                .claim("userName", "tester")
                .issuedAt(new Date(System.currentTimeMillis() - 10000))
                .expiration(new Date(System.currentTimeMillis() - 1000))
                .signWith(signingKey)
                .compact();

        assertThrows(ExpiredJwtException.class, () -> jwtUtil.parseToken(expiredToken),
                "过期token应抛出ExpiredJwtException");
        assertFalse(jwtUtil.validateToken(expiredToken), "过期token校验应返回false");
    }

    @Test
    @DisplayName("无效token解析失败")
    void testInvalidToken() {
        String invalidToken = "invalid.token.value";
        assertFalse(jwtUtil.validateToken(invalidToken), "无效token校验应返回false");
        assertThrows(Exception.class, () -> jwtUtil.parseToken(invalidToken),
                "无效token解析应抛出异常");
    }

    @Test
    @DisplayName("validateToken对有效token返回true")
    void testValidateToken() {
        String token = jwtUtil.generateToken(3003L, "operator");
        assertTrue(jwtUtil.validateToken(token), "有效token校验应返回true");
    }

    @Test
    @DisplayName("不同用户生成不同token")
    void testDifferentUsersDifferentTokens() {
        String token1 = jwtUtil.generateToken(1L, "user1");
        String token2 = jwtUtil.generateToken(2L, "user2");
        assertFalse(token1.equals(token2), "不同用户的token应不同");
    }
}
