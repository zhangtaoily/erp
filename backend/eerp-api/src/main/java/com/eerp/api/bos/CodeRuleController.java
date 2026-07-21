package com.eerp.api.bos;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.eerp.bos.code.CodeGenerateService;
import com.eerp.common.api.Result;
import com.eerp.meta.code.entity.MetaCodeRule;
import com.eerp.meta.code.service.MetaCodeRuleService;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.List;

@RestController
@RequestMapping("/api/code-rule")
public class CodeRuleController {

    private final MetaCodeRuleService codeRuleService;
    private final CodeGenerateService codeGenerateService;
    private final ObjectMapper objectMapper;

    public CodeRuleController(MetaCodeRuleService codeRuleService,
                              CodeGenerateService codeGenerateService,
                              ObjectMapper objectMapper) {
        this.codeRuleService = codeRuleService;
        this.codeGenerateService = codeGenerateService;
        this.objectMapper = objectMapper;
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
        List<MetaCodeRule> rules = codeRuleService.list(wrapper);
        rules.forEach(this::fillSegments);
        return Result.ok(rules);
    }

    @GetMapping("/{id}")
    public Result<MetaCodeRule> detail(@PathVariable Long id) {
        MetaCodeRule rule = codeRuleService.getById(id);
        fillSegments(rule);
        return Result.ok(rule);
    }

    @PostMapping
    public Result<MetaCodeRule> create(@RequestBody MetaCodeRule data) {
        serializeSegments(data);
        codeRuleService.save(data);
        fillSegments(data);
        return Result.ok(data);
    }

    @PutMapping("/{id}")
    public Result<MetaCodeRule> update(@PathVariable Long id, @RequestBody MetaCodeRule data) {
        data.setId(id);
        serializeSegments(data);
        codeRuleService.updateById(data);
        fillSegments(data);
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

    /**
     * 把前端传来的 segments 数组序列化为 segmentsJson 字符串，供 MyBatis-Plus 持久化。
     */
    private void serializeSegments(MetaCodeRule rule) {
        if (rule == null) return;
        if (rule.getSegments() != null) {
            try {
                rule.setSegmentsJson(objectMapper.writeValueAsString(rule.getSegments()));
            } catch (Exception e) {
                throw new IllegalArgumentException("segments 序列化失败", e);
            }
        }
    }

    /**
     * 把数据库的 segmentsJson 字符串反序列化为 segments 数组，供前端使用。
     */
    private void fillSegments(MetaCodeRule rule) {
        if (rule == null || rule.getSegmentsJson() == null || rule.getSegmentsJson().isEmpty()) {
            if (rule != null) rule.setSegments(new ArrayList<>());
            return;
        }
        try {
            rule.setSegments(objectMapper.readValue(rule.getSegmentsJson(),
                    new TypeReference<List<java.util.Map<String, Object>>>() {}));
        } catch (Exception e) {
            rule.setSegments(new ArrayList<>());
        }
    }
}

