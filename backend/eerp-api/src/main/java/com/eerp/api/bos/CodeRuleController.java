package com.eerp.api.bos;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.eerp.bos.code.CodeGenerateService;
import com.eerp.common.api.Result;
import com.eerp.meta.code.entity.MetaCodeRule;
import com.eerp.meta.code.service.MetaCodeRuleService;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/code-rule")
public class CodeRuleController {

    private final MetaCodeRuleService codeRuleService;
    private final CodeGenerateService codeGenerateService;

    public CodeRuleController(MetaCodeRuleService codeRuleService, CodeGenerateService codeGenerateService) {
        this.codeRuleService = codeRuleService;
        this.codeGenerateService = codeGenerateService;
    }

    @GetMapping
    public Result<List<MetaCodeRule>> list(@RequestParam(required = false) String boCode,
                                           @RequestParam(required = false) String ruleCode) {
        LambdaQueryWrapper<MetaCodeRule> wrapper = new LambdaQueryWrapper<>();
        if (boCode != null && !boCode.isEmpty()) {
            wrapper.eq(MetaCodeRule::getBoCode, boCode);
        }
        if (ruleCode != null && !ruleCode.isEmpty()) {
            wrapper.eq(MetaCodeRule::getRuleCode, ruleCode);
        }
        wrapper.orderByDesc(MetaCodeRule::getCreateTime);
        return Result.ok(codeRuleService.list(wrapper));
    }

    @GetMapping("/{id}")
    public Result<MetaCodeRule> detail(@PathVariable Long id) {
        return Result.ok(codeRuleService.getById(id));
    }

    @PostMapping
    public Result<MetaCodeRule> create(@RequestBody MetaCodeRule data) {
        codeRuleService.save(data);
        return Result.ok(data);
    }

    @PutMapping("/{id}")
    public Result<MetaCodeRule> update(@PathVariable Long id, @RequestBody MetaCodeRule data) {
        data.setId(id);
        codeRuleService.updateById(data);
        return Result.ok(data);
    }

    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        codeRuleService.removeById(id);
        return Result.ok();
    }

    @GetMapping("/{ruleId}/preview")
    public Result<String> preview(@PathVariable Long ruleId) {
        MetaCodeRule rule = codeRuleService.getById(ruleId);
        if (rule == null || rule.getBoCode() == null) {
            return Result.ok("");
        }
        return Result.ok(codeGenerateService.generateCode(rule.getBoCode()));
    }
}
