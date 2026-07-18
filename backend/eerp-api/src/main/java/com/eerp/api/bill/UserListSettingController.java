package com.eerp.api.bill;

import com.eerp.bos.list.QuerySchemeService;
import com.eerp.common.api.Result;
import com.eerp.common.exception.ServiceException;
import com.eerp.common.security.SecurityContext;
import com.eerp.common.security.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/user-list-setting")
public class UserListSettingController {

    private final QuerySchemeService querySchemeService;

    public UserListSettingController(QuerySchemeService querySchemeService) {
        this.querySchemeService = querySchemeService;
    }

    @GetMapping
    public Result<Map<String, Object>> get(@RequestParam String boCode) {
        SecurityContext ctx = currentUser();
        return Result.ok(querySchemeService.getUserListSetting(boCode, ctx.getUserId()));
    }

    @PostMapping
    public Result<Void> save(@RequestBody Map<String, Object> setting) {
        SecurityContext ctx = currentUser();
        Map<String, Object> data = new HashMap<>(setting);
        data.putIfAbsent("user_id", ctx.getUserId());
        querySchemeService.saveUserListSetting(data);
        return Result.ok();
    }

    private SecurityContext currentUser() {
        SecurityContext ctx = SecurityContextHolder.get();
        if (ctx == null) {
            throw new ServiceException("AUTH_001", "未登录");
        }
        return ctx;
    }
}
