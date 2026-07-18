package com.eerp.api.integration;

import com.eerp.common.api.Result;
import com.eerp.common.exception.ServiceException;
import com.eerp.common.security.SecurityContext;
import com.eerp.common.security.SecurityContextHolder;
import com.eerp.integration.attachment.AttachmentEntity;
import com.eerp.integration.attachment.AttachmentServiceImpl;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.io.InputStream;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.List;

/**
 * 附件 Controller（B1 新增，对齐设计文档 07 §4）。
 *
 * <p>端点清单：</p>
 * <ul>
 *   <li>{@code GET    /api/attachment} — 查询单据附件列表（按 boCode + billId）</li>
 *   <li>{@code GET    /api/attachment/{id}} — 查询附件详情</li>
 *   <li>{@code POST   /api/attachment/upload} — 上传附件（multipart/form-data）</li>
 *   <li>{@code GET    /api/attachment/{id}/download} — 下载附件</li>
 *   <li>{@code DELETE /api/attachment/{id}} — 删除附件（软删除 is_deleted=1）</li>
 * </ul>
 */
@RestController
@RequestMapping("/api/attachment")
public class AttachmentController {

    private final AttachmentServiceImpl attachmentService;

    public AttachmentController(AttachmentServiceImpl attachmentService) {
        this.attachmentService = attachmentService;
    }

    /**
     * 查询单据附件列表。
     */
    @GetMapping
    public Result<List<AttachmentEntity>> list(@RequestParam String boCode,
                                                @RequestParam Long billId) {
        return Result.ok(attachmentService.list(boCode, billId));
    }

    /**
     * 查询附件详情。
     */
    @GetMapping("/{id}")
    public Result<AttachmentEntity> detail(@PathVariable Long id) {
        AttachmentEntity entity = attachmentService.getById(id);
        if (entity == null) {
            throw new ServiceException("ATTACH_003", "附件不存在: " + id);
        }
        return Result.ok(entity);
    }

    /**
     * 上传附件（multipart/form-data）。
     *
     * @param boCode 业务对象编码
     * @param billId 单据ID
     * @param file   上传文件
     */
    @PostMapping("/upload")
    public Result<AttachmentEntity> upload(@RequestParam String boCode,
                                           @RequestParam Long billId,
                                           @RequestParam("file") MultipartFile file) {
        SecurityContext ctx = currentUser();
        AttachmentEntity entity = attachmentService.upload(boCode, billId, file, ctx.getUserId());
        return Result.ok(entity);
    }

    /**
     * 下载附件（返回文件字节流）。
     */
    @GetMapping("/{id}/download")
    public ResponseEntity<byte[]> download(@PathVariable Long id) {
        AttachmentEntity entity = attachmentService.getById(id);
        if (entity == null) {
            throw new ServiceException("ATTACH_003", "附件不存在: " + id);
        }
        try (InputStream is = attachmentService.download(id)) {
            byte[] bytes = is.readAllBytes();
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_OCTET_STREAM);
            String encodedName = URLEncoder.encode(entity.getFileName() == null ? "download" : entity.getFileName(),
                    StandardCharsets.UTF_8).replace("+", "%20");
            headers.set(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename*=UTF-8''" + encodedName);
            headers.setContentLength(bytes.length);
            return new ResponseEntity<>(bytes, headers, org.springframework.http.HttpStatus.OK);
        } catch (Exception e) {
            if (e instanceof ServiceException se) {
                throw se;
            }
            throw new ServiceException("ATTACH_005", "附件下载失败: " + e.getMessage(), e);
        }
    }

    /**
     * 删除附件（软删除 is_deleted=1，不物理删除文件）。
     */
    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        attachmentService.delete(id);
        return Result.ok();
    }

    private SecurityContext currentUser() {
        SecurityContext ctx = SecurityContextHolder.get();
        if (ctx == null) {
            throw new ServiceException("AUTH_001", "未登录");
        }
        return ctx;
    }
}
