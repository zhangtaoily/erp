package com.eerp.integration.attachment;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 附件实体（对应 sys_attachment 表）。
 *
 * <p>sys_attachment 表无公共审计字段（create_by/create_time 等），
 * 故不继承 BaseEntity，独立声明字段。</p>
 */
@Data
@TableName("sys_attachment")
public class AttachmentEntity {

    @TableId(type = IdType.ASSIGN_ID)
    private Long id;

    /** 单据类型（bo_code） */
    private String billType;

    /** 单据ID */
    private Long billId;

    /** 文件名 */
    private String fileName;

    /** 存储路径（适配器返回的 key） */
    private String filePath;

    /** 文件大小(字节) */
    private Long fileSize;

    /** 文件类型（contentType） */
    private String fileType;

    /** 存储类型：local/oss/minio */
    private String storageType;

    /** 版本号 */
    private Integer version;

    /** 上传人 */
    private String uploadBy;

    /** 上传时间 */
    private LocalDateTime uploadTime;

    /** 是否删除（0否 1是） */
    private Integer isDeleted;
}
