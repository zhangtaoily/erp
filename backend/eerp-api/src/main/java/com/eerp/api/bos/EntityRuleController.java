package com.eerp.api.bos;

import com.eerp.common.api.Result;
import com.eerp.meta.rule.entity.MetaEntityRule;
import com.eerp.meta.rule.service.MetaEntityRuleService;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class EntityRuleController {

    private final MetaEntityRuleService entityRuleService;

    public EntityRuleController(MetaEntityRuleService entityRuleService) {
        this.entityRuleService = entityRuleService;
    }

    @GetMapping("/bo/{boCode}/entity-rules")
    public Result<List<MetaEntityRule>> list(@PathVariable String boCode) {
        return Result.ok(entityRuleService.listByBoCode(boCode));
    }

    @GetMapping("/entity-rule/{id}")
    public Result<MetaEntityRule> detail(@PathVariable Long id) {
        return Result.ok(entityRuleService.getById(id));
    }

    @PostMapping("/entity-rule")
    public Result<MetaEntityRule> create(@RequestBody MetaEntityRule data) {
        entityRuleService.save(data);
        return Result.ok(data);
    }

    @PutMapping("/entity-rule/{id}")
    public Result<MetaEntityRule> update(@PathVariable Long id, @RequestBody MetaEntityRule data) {
        data.setId(id);
        entityRuleService.updateById(data);
        return Result.ok(data);
    }

    @DeleteMapping("/entity-rule/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        entityRuleService.removeById(id);
        return Result.ok();
    }

    @PostMapping("/entity-rule/validate")
    public Result<Map<String, Object>> validate(@RequestBody Map<String, Object> body) {
        Map<String, Object> result = new HashMap<>();
        Object expr = body.get("expr");
        if (expr == null || expr.toString().trim().isEmpty()) {
            result.put("valid", false);
            result.put("error", "表达式不能为空");
        } else {
            // Phase 1：仅做非空校验，表达式引擎校验后续完善
            result.put("valid", true);
        }
        return Result.ok(result);
    }
}
