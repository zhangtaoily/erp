package com.eerp.common.config;

import com.baomidou.mybatisplus.core.handlers.MetaObjectHandler;
import com.eerp.common.security.SecurityContext;
import com.eerp.common.security.SecurityContextHolder;
import org.apache.ibatis.reflection.MetaObject;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;

/**
 * MyBatis-Plus 自动填充处理器
 */
@Component
public class MetaObjectHandlerImpl implements MetaObjectHandler {

    @Override
    public void insertFill(MetaObject metaObject) {
        String currentUser = currentUser();
        this.strictInsertFill(metaObject, "createBy", String.class, currentUser);
        this.strictInsertFill(metaObject, "createTime", LocalDateTime.class, LocalDateTime.now());
        this.strictInsertFill(metaObject, "updateBy", String.class, currentUser);
        this.strictInsertFill(metaObject, "updateTime", LocalDateTime.class, LocalDateTime.now());
    }

    @Override
    public void updateFill(MetaObject metaObject) {
        String currentUser = currentUser();
        this.strictUpdateFill(metaObject, "updateBy", String.class, currentUser);
        this.strictUpdateFill(metaObject, "updateTime", LocalDateTime.class, LocalDateTime.now());
    }

    private String currentUser() {
        try {
            SecurityContext ctx = SecurityContextHolder.get();
            if (ctx != null && ctx.getUserName() != null) {
                return ctx.getUserName();
            }
        } catch (Exception ignored) {
            // 上下文不可用时回退到默认值
        }
        return "system";
    }
}
