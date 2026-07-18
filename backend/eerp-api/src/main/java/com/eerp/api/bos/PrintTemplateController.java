package com.eerp.api.bos;

import com.eerp.bos.print.AbstractPrintTemplateService;
import com.eerp.common.api.Result;
import com.eerp.common.exception.ServiceException;
import com.eerp.meta.print.entity.MetaPrintTemplate;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 打印模板 Controller（B1 新增，对齐设计文档 02 §3.8 / §6.4）。
 *
 * <p>端点清单：</p>
 * <ul>
 *   <li>{@code GET    /api/print-template} — 列表查询（按 boCode 过滤）</li>
 *   <li>{@code GET    /api/print-template/{id}} — 详情</li>
 *   <li>{@code GET    /api/print-template/default} — 按 boCode 取默认模板</li>
 *   <li>{@code POST   /api/print-template} — 新建模板</li>
 *   <li>{@code PUT    /api/print-template/{id}} — 更新模板</li>
 *   <li>{@code DELETE /api/print-template/{id}} — 删除模板</li>
 *   <li>{@code GET    /api/print-template/{id}/render?billId=xxx} — 渲染单据（HTML 字节流）</li>
 *   <li>{@code POST   /api/print-template/{id}/render-batch} — 批量套打（请求体 billIds 数组）</li>
 * </ul>
 */
@RestController
@RequestMapping("/api/print-template")
public class PrintTemplateController {

    private final AbstractPrintTemplateService printTemplateService;

    public PrintTemplateController(AbstractPrintTemplateService printTemplateService) {
        this.printTemplateService = printTemplateService;
    }

    @GetMapping
    public Result<List<MetaPrintTemplate>> list(@RequestParam(required = false) String boCode) {
        if (boCode == null || boCode.isEmpty()) {
            return Result.ok(printTemplateService.list());
        }
        return Result.ok(printTemplateService.listByBoCode(boCode));
    }

    @GetMapping("/{id}")
    public Result<MetaPrintTemplate> detail(@PathVariable Long id) {
        MetaPrintTemplate tpl = printTemplateService.getById(id);
        if (tpl == null) {
            throw new ServiceException("PRINT_002", "打印模板不存在: " + id);
        }
        return Result.ok(tpl);
    }

    @GetMapping("/default")
    public Result<MetaPrintTemplate> getDefault(@RequestParam String boCode) {
        return Result.ok(printTemplateService.getDefault(boCode));
    }

    @PostMapping
    public Result<MetaPrintTemplate> create(@RequestBody MetaPrintTemplate data) {
        printTemplateService.save(data);
        return Result.ok(data);
    }

    @PutMapping("/{id}")
    public Result<MetaPrintTemplate> update(@PathVariable Long id, @RequestBody MetaPrintTemplate data) {
        data.setId(id);
        printTemplateService.updateById(data);
        return Result.ok(data);
    }

    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        printTemplateService.removeById(id);
        return Result.ok();
    }

    /**
     * 渲染单据（返回 HTML 字节流，浏览器可直接预览/打印）。
     */
    @GetMapping("/{id}/render")
    public ResponseEntity<byte[]> render(@PathVariable Long id,
                                         @RequestParam Long billId) {
        byte[] bytes = printTemplateService.render(id, billId);
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.TEXT_HTML);
        headers.setContentDispositionFormData("inline", "print_" + billId + ".html");
        return new ResponseEntity<>(bytes, headers, org.springframework.http.HttpStatus.OK);
    }

    /**
     * 批量套打（请求体：单据ID数组）。
     */
    @PostMapping("/{id}/render-batch")
    public ResponseEntity<byte[]> renderBatch(@PathVariable Long id,
                                              @RequestBody RenderBatchRequest req) {
        if (req == null || req.getBillIds() == null || req.getBillIds().isEmpty()) {
            throw new ServiceException("PRINT_003", "套打单据ID列表为空");
        }
        byte[] bytes = printTemplateService.renderBatch(id, req.getBillIds());
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.TEXT_HTML);
        headers.setContentDispositionFormData("inline", "print_batch.html");
        return new ResponseEntity<>(bytes, headers, org.springframework.http.HttpStatus.OK);
    }

    /** 批量套打请求体 */
    @lombok.Data
    public static class RenderBatchRequest {
        private List<Long> billIds;
    }
}
