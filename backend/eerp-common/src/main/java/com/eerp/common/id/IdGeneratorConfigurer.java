package com.eerp.common.id;

import com.baomidou.mybatisplus.core.incrementer.IdentifierGenerator;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

/**
 * MyBatis-Plus ID 生成器适配
 */
@Component
public class IdGeneratorConfigurer implements IdentifierGenerator {

    private final SnowflakeIdGenerator snowflakeIdGenerator;

    @Autowired
    public IdGeneratorConfigurer(SnowflakeIdGenerator snowflakeIdGenerator) {
        this.snowflakeIdGenerator = snowflakeIdGenerator;
    }

    @Override
    public Number nextId(Object entity) {
        return snowflakeIdGenerator.nextId();
    }
}
