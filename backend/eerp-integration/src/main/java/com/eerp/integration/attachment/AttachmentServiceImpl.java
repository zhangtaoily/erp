package com.eerp.integration.attachment;

import com.eerp.common.exception.ServiceException;
import com.eerp.common.id.SnowflakeIdGenerator;
import com.eerp.integration.storage.StorageAdapterRegistry;
import com.eerp.integration.storage.StorageOperations;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.BeanPropertyRowMapper;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.InputStream;
import java.time.LocalDateTime;
import java.util.List;

/**
 * 附件服务实现。
 *
 * <p>依赖 {@link StorageAdapterRegistry} 路由存储后端，{@link JdbcTemplate} 落库 sys_attachment。
 * 删除采用逻辑删除（is_deleted=1），不物理删除文件（对齐设计文档「逻辑删除不物理删」）。</p>
 */
@Service
public class AttachmentServiceImpl extends AbstractAttachmentService {

    @Autowired
    private StorageAdapterRegistry storageAdapterRegistry;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Autowired
    private SnowflakeIdGenerator snowflakeIdGenerator;

    /**
     * 上传附件：调存储适配器写入文件，写 sys_attachment 记录。
     *
     * @param boCode 业务对象编码
     * @param billId 单据ID
     * @param file   上传文件
     * @param userId 上传用户ID
     * @return 附件记录
     */
    @Transactional(rollbackFor = Exception.class)
    public AttachmentEntity upload(String boCode, Long billId, MultipartFile file, Long userId) {
        if (file == null || file.isEmpty()) {
            throw new ServiceException("ATTACH_001", "上传文件为空");
        }
        StorageOperations adapter = storageAdapterRegistry.getAdapter();
        String filePath;
        try {
            filePath = adapter.upload(file.getInputStream(), file.getOriginalFilename(), file.getContentType());
        } catch (Exception e) {
            if (e instanceof ServiceException se) {
                throw se;
            }
            throw new ServiceException("ATTACH_002", "文件上传存储失败", e);
        }

        long id = snowflakeIdGenerator.nextId();
        AttachmentEntity entity = new AttachmentEntity();
        entity.setId(id);
        entity.setBillType(boCode);
        entity.setBillId(billId);
        entity.setFileName(file.getOriginalFilename());
        entity.setFilePath(filePath);
        entity.setFileSize(file.getSize());
        entity.setFileType(file.getContentType());
        entity.setStorageType(adapter.getType());
        entity.setVersion(1);
        entity.setUploadBy(userId == null ? null : String.valueOf(userId));
        entity.setUploadTime(LocalDateTime.now());
        entity.setIsDeleted(0);

        jdbcTemplate.update(
                "INSERT INTO sys_attachment (id, bill_type, bill_id, file_name, file_path, file_size, " +
                        "file_type, storage_type, version, upload_by, upload_time, is_deleted) " +
                        "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                entity.getId(), entity.getBillType(), entity.getBillId(), entity.getFileName(),
                entity.getFilePath(), entity.getFileSize(), entity.getFileType(), entity.getStorageType(),
                entity.getVersion(), entity.getUploadBy(), entity.getUploadTime(), entity.getIsDeleted());

        return entity;
    }

    /**
     * 查询单据的附件列表（未删除）。
     *
     * @param boCode 业务对象编码
     * @param billId 单据ID
     * @return 附件列表
     */
    public List<AttachmentEntity> list(String boCode, Long billId) {
        return jdbcTemplate.query(
                "SELECT id, bill_type, bill_id, file_name, file_path, file_size, file_type, " +
                        "storage_type, version, upload_by, upload_time, is_deleted FROM sys_attachment " +
                        "WHERE bill_type = ? AND bill_id = ? AND is_deleted = 0 ORDER BY upload_time DESC",
                new BeanPropertyRowMapper<>(AttachmentEntity.class), boCode, billId);
    }

    /**
     * 下载附件：查 sys_attachment 取 path，调存储适配器下载返回输入流。
     *
     * @param attachmentId 附件ID
     * @return 文件输入流
     */
    public InputStream download(Long attachmentId) {
        AttachmentEntity entity = getById(attachmentId);
        if (entity == null) {
            throw new ServiceException("ATTACH_003", "附件不存在: " + attachmentId);
        }
        return storageAdapterRegistry.getAdapter().download(entity.getFilePath());
    }

    /**
     * 软删除附件（is_deleted=1），不物理删除文件。
     *
     * @param attachmentId 附件ID
     */
    @Transactional(rollbackFor = Exception.class)
    public void delete(Long attachmentId) {
        int rows = jdbcTemplate.update(
                "UPDATE sys_attachment SET is_deleted = 1 WHERE id = ? AND is_deleted = 0", attachmentId);
        if (rows == 0) {
            throw new ServiceException("ATTACH_004", "附件不存在或已删除: " + attachmentId);
        }
    }

    /**
     * 查询附件详情（含已删除）。
     *
     * @param attachmentId 附件ID
     * @return 附件记录，不存在返回 null
     */
    public AttachmentEntity getById(Long attachmentId) {
        List<AttachmentEntity> list = jdbcTemplate.query(
                "SELECT id, bill_type, bill_id, file_name, file_path, file_size, file_type, " +
                        "storage_type, version, upload_by, upload_time, is_deleted FROM sys_attachment " +
                        "WHERE id = ?",
                new BeanPropertyRowMapper<>(AttachmentEntity.class), attachmentId);
        return list.isEmpty() ? null : list.get(0);
    }
}
