package com.eerp.api.bos;

import com.eerp.common.api.Result;
import com.eerp.meta.button.entity.MetaButton;
import com.eerp.meta.button.service.MetaButtonService;
import com.eerp.meta.button.vo.ButtonDefVO;
import com.eerp.meta.cache.ButtonMetaCache;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api")
public class ButtonController {

    private final MetaButtonService buttonService;
    private final ButtonMetaCache buttonMetaCache;

    public ButtonController(MetaButtonService buttonService, ButtonMetaCache buttonMetaCache) {
        this.buttonService = buttonService;
        this.buttonMetaCache = buttonMetaCache;
    }

    @GetMapping("/bo/{boCode}/buttons")
    public Result<List<ButtonDefVO>> list(@PathVariable String boCode) {
        return Result.ok(buttonMetaCache.get(boCode));
    }

    @PostMapping("/button")
    public Result<MetaButton> create(@RequestBody MetaButton data) {
        buttonService.save(data);
        evictByBoCode(data);
        return Result.ok(data);
    }

    @PutMapping("/button/{id}")
    public Result<MetaButton> update(@PathVariable Long id, @RequestBody MetaButton data) {
        data.setId(id);
        buttonService.updateById(data);
        evictByBoCode(data);
        return Result.ok(data);
    }

    @DeleteMapping("/button/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        MetaButton existing = buttonService.getById(id);
        buttonService.removeById(id);
        if (existing != null) {
            // 按钮定义无 boCode 字段，无法精确失效，清理整个缓存
            buttonMetaCache.evictAll();
        }
        return Result.ok();
    }

    private void evictByBoCode(MetaButton data) {
        // MetaButton 无 boCode 字段，按钮按 boCode 关联通过 MetaFormButton 表，
        // 此处清理整个按钮缓存以保证一致性
        buttonMetaCache.evictAll();
    }
}
