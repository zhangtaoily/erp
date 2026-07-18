package com.eerp.api.bos;

import com.eerp.bos.form.FormMetaServiceImpl;
import com.eerp.bos.form.FormRenderService;
import com.eerp.common.api.Result;
import com.eerp.meta.bo.vo.FormMetaVO;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/form")
public class FormMetaController {

    private final FormMetaServiceImpl formMetaService;
    private final FormRenderService formRenderService;

    public FormMetaController(FormMetaServiceImpl formMetaService, FormRenderService formRenderService) {
        this.formMetaService = formMetaService;
        this.formRenderService = formRenderService;
    }

    @GetMapping("/{boCode}/meta")
    public Result<FormMetaVO> getMeta(@PathVariable String boCode) {
        return Result.ok(formMetaService.getFormMeta(boCode));
    }

    @PutMapping("/{boCode}/meta")
    public Result<Void> saveMeta(@PathVariable String boCode, @RequestBody Map<String, Object> data) {
        // 表单元数据通过 bo/entity/field/form-layout 各独立端点持久化，
        // 此处统一失效缓存，保证后续读取拿到最新元数据
        formMetaService.evictCache(boCode);
        return Result.ok();
    }

    @GetMapping("/{boCode}/preview")
    public Result<Map<String, Object>> preview(@PathVariable String boCode,
                                               @RequestParam(required = false, defaultValue = "view") String mode) {
        Map<String, Object> result;
        switch (mode == null ? "view" : mode.toLowerCase()) {
            case "add":
                result = formRenderService.renderForNew(boCode);
                break;
            case "edit":
                result = formRenderService.renderForEdit(boCode, null);
                break;
            case "view":
            default:
                result = formRenderService.renderForView(boCode, null);
                break;
        }
        return Result.ok(result);
    }
}
