package com.eerp.api.bos;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.eerp.common.api.Result;
import com.eerp.meta.writeback.entity.MetaWritebackRule;
import com.eerp.meta.writeback.service.MetaWritebackRuleService;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/writeback-rule")
public class WritebackRuleController {

    private final MetaWritebackRuleService writebackRuleService;

    public WritebackRuleController(MetaWritebackRuleService writebackRuleService) {
        this.writebackRuleService = writebackRuleService;
    }

    @GetMapping
    public Result<List<MetaWritebackRule>> list(@RequestParam(required = false) String srcBillType,
                                                @RequestParam(required = false) String targetBillType) {
        LambdaQueryWrapper<MetaWritebackRule> wrapper = new LambdaQueryWrapper<>();
        if (srcBillType != null && !srcBillType.isEmpty()) {
            wrapper.eq(MetaWritebackRule::getSrcBillType, srcBillType);
        }
        if (targetBillType != null && !targetBillType.isEmpty()) {
            wrapper.eq(MetaWritebackRule::getTargetBillType, targetBillType);
        }
        wrapper.orderByDesc(MetaWritebackRule::getCreateTime);
        return Result.ok(writebackRuleService.list(wrapper));
    }

    @GetMapping("/{id}")
    public Result<MetaWritebackRule> detail(@PathVariable Long id) {
        return Result.ok(writebackRuleService.getById(id));
    }

    @PostMapping
    public Result<MetaWritebackRule> create(@RequestBody MetaWritebackRule data) {
        writebackRuleService.save(data);
        return Result.ok(data);
    }

    @PutMapping("/{id}")
    public Result<MetaWritebackRule> update(@PathVariable Long id, @RequestBody MetaWritebackRule data) {
        data.setId(id);
        writebackRuleService.updateById(data);
        return Result.ok(data);
    }

    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        writebackRuleService.removeById(id);
        return Result.ok();
    }
}
