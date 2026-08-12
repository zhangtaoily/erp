package com.eerp.api.bos;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.eerp.common.api.Result;
import com.eerp.meta.writeback.entity.MetaWritebackField;
import com.eerp.meta.writeback.entity.MetaWritebackRule;
import com.eerp.meta.writeback.mapper.MetaWritebackFieldMapper;
import com.eerp.meta.writeback.service.MetaWritebackRuleService;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/writeback-rule")
public class WritebackRuleController {

    private final MetaWritebackRuleService writebackRuleService;
    private final MetaWritebackFieldMapper writebackFieldMapper;

    public WritebackRuleController(MetaWritebackRuleService writebackRuleService,
                                    MetaWritebackFieldMapper writebackFieldMapper) {
        this.writebackRuleService = writebackRuleService;
        this.writebackFieldMapper = writebackFieldMapper;
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
        List<MetaWritebackRule> rules = writebackRuleService.list(wrapper);
        // 加载每条规则的字段映射
        for (MetaWritebackRule rule : rules) {
            rule.setFields(writebackFieldMapper.listByRuleCode(rule.getRuleCode()));
        }
        return Result.ok(rules);
    }

    @GetMapping("/{id}")
    public Result<MetaWritebackRule> detail(@PathVariable Long id) {
        MetaWritebackRule rule = writebackRuleService.getById(id);
        if (rule != null) {
            rule.setFields(writebackFieldMapper.listByRuleCode(rule.getRuleCode()));
        }
        return Result.ok(rule);
    }

    @PostMapping
    @Transactional(rollbackFor = Exception.class)
    public Result<MetaWritebackRule> create(@RequestBody MetaWritebackRule data) {
        writebackRuleService.save(data);
        saveFields(data);
        return Result.ok(data);
    }

    @PutMapping("/{id}")
    @Transactional(rollbackFor = Exception.class)
    public Result<MetaWritebackRule> update(@PathVariable Long id, @RequestBody MetaWritebackRule data) {
        data.setId(id);
        writebackRuleService.updateById(data);
        saveFields(data);
        return Result.ok(data);
    }

    @DeleteMapping("/{id}")
    @Transactional(rollbackFor = Exception.class)
    public Result<Void> delete(@PathVariable Long id) {
        MetaWritebackRule rule = writebackRuleService.getById(id);
        if (rule != null) {
            // 先删字段映射，再删规则
            writebackFieldMapper.delete(new LambdaQueryWrapper<MetaWritebackField>()
                    .eq(MetaWritebackField::getRuleCode, rule.getRuleCode()));
            writebackRuleService.removeById(id);
        }
        return Result.ok();
    }

    /**
     * 保存字段映射：先删旧值再插入新值（全量替换）。
     */
    private void saveFields(MetaWritebackRule rule) {
        if (rule.getRuleCode() == null) {
            return;
        }
        // 先删除旧字段
        writebackFieldMapper.delete(new LambdaQueryWrapper<MetaWritebackField>()
                .eq(MetaWritebackField::getRuleCode, rule.getRuleCode()));
        // 再插入新字段
        List<MetaWritebackField> fields = rule.getFields();
        if (fields != null && !fields.isEmpty()) {
            for (int i = 0; i < fields.size(); i++) {
                MetaWritebackField field = fields.get(i);
                field.setRuleCode(rule.getRuleCode());
                field.setId(null); // 确保新增
                field.setItemSeq(i + 1);
                writebackFieldMapper.insert(field);
            }
        }
    }
}
