package com.eerp.api;

import org.apache.ibatis.annotations.Mapper;
import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.ComponentScan;

@SpringBootApplication
@ComponentScan(basePackages = {"com.eerp"})
@MapperScan(basePackages = {"com.eerp"}, annotationClass = Mapper.class)
public class EerpApplication {
    public static void main(String[] args) {
        SpringApplication.run(EerpApplication.class, args);
    }
}
