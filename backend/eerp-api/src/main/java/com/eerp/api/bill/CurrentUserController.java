package com.eerp.api.bill;

import com.eerp.common.api.Result;
import com.eerp.common.exception.ServiceException;
import com.eerp.common.security.SecurityContext;
import com.eerp.common.security.SecurityContextHolder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/current-user")
public class CurrentUserController {

    @GetMapping
    public Result<Map<String, Object>> get() {
        SecurityContext ctx = SecurityContextHolder.get();
        if (ctx == null) {
            throw new ServiceException("AUTH_001", "未登录");
        }
        Map<String, Object> info = new HashMap<>();
        info.put("id", ctx.getUserId());
        info.put("user_code", ctx.getUserName());
        info.put("user_name", ctx.getUserName());
        info.put("org_id", ctx.getOrgId());
        info.put("org_name", ctx.getOrgName());
        info.put("dept_id", ctx.getDeptId());
        info.put("current_org_id", ctx.getCurrentOrgId());
        return Result.ok(info);
    }
}
