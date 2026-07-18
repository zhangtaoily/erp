package com.eerp.api.sys;

import com.eerp.api.sys.entity.SysDept;
import com.eerp.api.sys.service.SysDeptService;
import com.eerp.common.api.Result;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/dept")
public class DeptController {

    private final SysDeptService deptService;

    public DeptController(SysDeptService deptService) {
        this.deptService = deptService;
    }

    @GetMapping("/list")
    public Result<List<SysDept>> list(@RequestParam(required = false) Map<String, Object> params) {
        return Result.ok(deptService.list(params));
    }

    @PostMapping
    public Result<SysDept> create(@RequestBody SysDept data) {
        deptService.save(data);
        return Result.ok(data);
    }

    @PutMapping("/{id}")
    public Result<SysDept> update(@PathVariable Long id, @RequestBody SysDept data) {
        data.setId(id);
        deptService.updateById(data);
        return Result.ok(data);
    }

    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        deptService.removeById(id);
        return Result.ok();
    }
}
