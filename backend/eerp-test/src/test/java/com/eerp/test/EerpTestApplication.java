package com.eerp.test;

import org.apache.ibatis.annotations.Mapper;
import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.data.redis.RedisAutoConfiguration;
import org.springframework.boot.autoconfigure.data.redis.RedisRepositoriesAutoConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.core.RedisTemplate;

/**
 * 集成测试专用 Spring Boot 启动类。
 *
 * <p>排除 Redis 自动配置（测试环境无 Redis），并提供 Mock 的 RedisConnectionFactory
 * 与 RedisTemplate Bean，使 {@code com.eerp.common.config.RedisConfig} 能正常装配。</p>
 *
 * <p>扫描所有 {@code com.eerp} 包，使业务模块的 Service/Controller/Mapper 均可注入。</p>
 */
@SpringBootApplication(exclude = {
        RedisAutoConfiguration.class,
        RedisRepositoriesAutoConfiguration.class
})
@ComponentScan(basePackages = {"com.eerp"})
@MapperScan(basePackages = {"com.eerp"}, annotationClass = Mapper.class)
public class EerpTestApplication {

    public static void main(String[] args) {
        SpringApplication.run(EerpTestApplication.class, args);
    }

    /**
     * 提供 Mock RedisConnectionFactory，避免 RedisConfig 因缺少连接工厂而装配失败。
     * 测试中无代码实际使用 Redis，故 Mock 即可。
     */
    @Bean
    public RedisConnectionFactory redisConnectionFactory() {
        return org.mockito.Mockito.mock(RedisConnectionFactory.class);
    }
}
