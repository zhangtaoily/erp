package com.eerp.common.config;

import com.baomidou.mybatisplus.annotation.DbType;
import com.baomidou.mybatisplus.extension.plugins.MybatisPlusInterceptor;
import com.baomidou.mybatisplus.extension.plugins.inner.PaginationInnerInterceptor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * MyBatis-Plus 配置
 *
 * <p>说明：{@code IdentifierGenerator} 由 {@link com.eerp.common.id.IdGeneratorConfigurer}
 * 以 {@code @Component} 形式注册，MyBatis-Plus 会通过 ObjectProvider 自动发现并使用它，
 * 因此此处无需重复声明 {@code @Bean IdentifierGenerator}（重复声明会导致
 * NoUniqueBeanDefinitionException）。</p>
 */
@Configuration
public class MyBatisPlusConfig {

    @Bean
    public MybatisPlusInterceptor mybatisPlusInterceptor() {
        MybatisPlusInterceptor interceptor = new MybatisPlusInterceptor();
        interceptor.addInnerInterceptor(new PaginationInnerInterceptor(DbType.MYSQL));
        return interceptor;
    }
}
