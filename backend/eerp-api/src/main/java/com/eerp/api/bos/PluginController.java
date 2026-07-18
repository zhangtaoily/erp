package com.eerp.api.bos;

import com.eerp.common.api.Result;
import com.eerp.meta.plugin.entity.MetaFormPlugin;
import com.eerp.meta.plugin.service.MetaFormPluginService;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class PluginController {

    private final MetaFormPluginService formPluginService;

    public PluginController(MetaFormPluginService formPluginService) {
        this.formPluginService = formPluginService;
    }

    @GetMapping("/form/{boCode}/plugins")
    public Result<List<MetaFormPlugin>> list(@PathVariable String boCode) {
        return Result.ok(formPluginService.listByBoCode(boCode));
    }

    @PostMapping("/plugin")
    public Result<MetaFormPlugin> create(@RequestBody MetaFormPlugin data) {
        formPluginService.save(data);
        return Result.ok(data);
    }

    @PutMapping("/plugin/{id}")
    public Result<MetaFormPlugin> update(@PathVariable Long id, @RequestBody MetaFormPlugin data) {
        data.setId(id);
        formPluginService.updateById(data);
        return Result.ok(data);
    }

    @DeleteMapping("/plugin/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        formPluginService.removeById(id);
        return Result.ok();
    }

    @PutMapping("/plugin/{id}/status")
    public Result<Void> toggleStatus(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        MetaFormPlugin existing = formPluginService.getById(id);
        if (existing != null) {
            Object status = body.get("status");
            if (status != null) {
                existing.setStatus(Integer.parseInt(status.toString()));
                formPluginService.updateById(existing);
            }
        }
        return Result.ok();
    }

    @GetMapping("/plugin/class-meta")
    public Result<Map<String, Object>> getClassMeta(@RequestParam String file,
                                                    @RequestParam(required = false) String boCode) {
        // Phase 1：返回空元数据，反射扫描能力后续完善
        Map<String, Object> empty = new HashMap<>();
        empty.put("baseClass", null);
        empty.put("params", List.of());
        empty.put("events", List.of());
        return Result.ok(empty);
    }
}
