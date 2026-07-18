package com.eerp.api.bos;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.eerp.common.api.Result;
import com.eerp.meta.push.entity.MetaPushRule;
import com.eerp.meta.push.service.MetaPushRuleService;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/push-rule")
public class PushRuleController {

    private final MetaPushRuleService pushRuleService;

    public PushRuleController(MetaPushRuleService pushRuleService) {
        this.pushRuleService = pushRuleService;
    }

    @GetMapping
    public Result<List<MetaPushRule>> list(@RequestParam(required = false) String srcBoCode,
                                           @RequestParam(required = false) String tgtBoCode) {
        LambdaQueryWrapper<MetaPushRule> wrapper = new LambdaQueryWrapper<>();
        if (srcBoCode != null && !srcBoCode.isEmpty()) {
            wrapper.eq(MetaPushRule::getSrcBoCode, srcBoCode);
        }
        if (tgtBoCode != null && !tgtBoCode.isEmpty()) {
            wrapper.eq(MetaPushRule::getTgtBoCode, tgtBoCode);
        }
        wrapper.orderByDesc(MetaPushRule::getCreateTime);
        return Result.ok(pushRuleService.list(wrapper));
    }

    @GetMapping("/{id}")
    public Result<MetaPushRule> detail(@PathVariable Long id) {
        return Result.ok(pushRuleService.getById(id));
    }

    @PostMapping
    public Result<MetaPushRule> create(@RequestBody MetaPushRule data) {
        pushRuleService.save(data);
        return Result.ok(data);
    }

    @PutMapping("/{id}")
    public Result<MetaPushRule> update(@PathVariable Long id, @RequestBody MetaPushRule data) {
        data.setId(id);
        pushRuleService.updateById(data);
        return Result.ok(data);
    }

    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        pushRuleService.removeById(id);
        return Result.ok();
    }
}
