package com.eerp.plugin.config;

import com.eerp.meta.rule.expr.ExprEvaluator;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * 插件引擎配置。
 *
 * <p>将 A1 表达式引擎 {@link ExprEvaluator} 注册为 Spring Bean，
 * 供 {@link com.eerp.plugin.script.Antlr4ScriptEngine} 注入。
 * A1 表达式引擎本身为纯 POJO，此处完成 Bean 装配。</p>
 */
@Configuration
public class PluginEngineConfiguration {

    @Bean
    public ExprEvaluator exprEvaluator() {
        return new ExprEvaluator();
    }
}
