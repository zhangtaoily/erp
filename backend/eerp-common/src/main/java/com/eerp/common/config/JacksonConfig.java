package com.eerp.common.config;

import com.fasterxml.jackson.databind.Module;
import com.fasterxml.jackson.databind.module.SimpleModule;
import com.fasterxml.jackson.databind.ser.std.ToStringSerializer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Jackson 配置：将 Long 序列化为字符串，避免前端精度丢失。
 *
 * <p>使用 {@code @Bean Module} 方式注册（比 {@code Jackson2ObjectMapperBuilderCustomizer} 更可靠），
 * 确保 {@code Map<String, Object>} 中的 Long 值也能正确序列化为字符串。
 * Spring Boot 自动检测 Module Bean 并注册到 ObjectMapper。</p>
 */
@Configuration
public class JacksonConfig {

    @Bean
    public Module longToStringModule() {
        SimpleModule module = new SimpleModule("LongToStringModule");
        module.addSerializer(Long.class, ToStringSerializer.instance);
        module.addSerializer(Long.TYPE, ToStringSerializer.instance);
        return module;
    }
}
