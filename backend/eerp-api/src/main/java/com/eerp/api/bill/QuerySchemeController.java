package com.eerp.api.bill;

import com.eerp.bos.list.QuerySchemeService;
import com.eerp.common.api.Result;
import com.eerp.common.exception.ServiceException;
import com.eerp.common.security.SecurityContext;
import com.eerp.common.security.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/query-scheme")
public class QuerySchemeController {

    private final QuerySchemeService querySchemeService;

    public QuerySchemeController(QuerySchemeService querySchemeService) {
        this.querySchemeService = querySchemeService;
    }

    @GetMapping
    public Result<List<Map<String, Object>>> list(@RequestParam String boCode) {
        SecurityContext ctx = currentUser();
        return Result.ok(querySchemeService.listSchemes(boCode, ctx.getUserId()));
    }

    @PostMapping
    public Result<Map<String, Object>> create(@RequestBody Map<String, Object> data) {
        SecurityContext ctx = currentUser();
        data.putIfAbsent("user_id", ctx.getUserId());
        return Result.ok(querySchemeService.saveScheme(data));
    }

    @PutMapping("/{id}")
    public Result<Map<String, Object>> update(@PathVariable Long id, @RequestBody Map<String, Object> data) {
        data.put("id", id);
        return Result.ok(querySchemeService.saveScheme(data));
    }

    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        querySchemeService.deleteScheme(id);
        return Result.ok();
    }

    @PutMapping("/{id}/default")
    public Result<Void> setDefault(@PathVariable Long id) {
        querySchemeService.setDefault(id);
        return Result.ok();
    }

    @PutMapping("/{id}/favorite")
    public Result<Void> favorite(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        Map<String, Object> scheme = querySchemeService.getScheme(id);
        if (scheme == null) {
            throw new ServiceException("SYS_500", "查询方案不存在");
        }
        Map<String, Object> data = new HashMap<>(scheme);
        data.put("id", id);
        Object favorite = body.get("favorite");
        data.put("is_favorite", Boolean.TRUE.equals(favorite) ? 1 : 0);
        querySchemeService.saveScheme(data);
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
