package com.eerp.api.bos;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.eerp.common.api.Result;
import com.eerp.meta.layout.entity.MetaFormLayout;
import com.eerp.meta.layout.service.MetaFormLayoutService;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/form-layout")
public class FormLayoutController {

    private final MetaFormLayoutService formLayoutService;

    public FormLayoutController(MetaFormLayoutService formLayoutService) {
        this.formLayoutService = formLayoutService;
    }

    @GetMapping("/{boCode}")
    public Result<MetaFormLayout> getDefault(@PathVariable String boCode) {
        return Result.ok(formLayoutService.getDefault(boCode));
    }

    @GetMapping("/{boCode}/list")
    public Result<List<MetaFormLayout>> list(@PathVariable String boCode) {
        LambdaQueryWrapper<MetaFormLayout> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(MetaFormLayout::getBoCode, boCode);
        wrapper.orderByDesc(MetaFormLayout::getCreateTime);
        return Result.ok(formLayoutService.list(wrapper));
    }

    @PostMapping
    public Result<MetaFormLayout> save(@RequestBody MetaFormLayout data) {
        formLayoutService.save(data);
        return Result.ok(data);
    }

    @PutMapping("/{id}")
    public Result<MetaFormLayout> update(@PathVariable Long id, @RequestBody MetaFormLayout data) {
        data.setId(id);
        formLayoutService.updateById(data);
        return Result.ok(data);
    }
}
