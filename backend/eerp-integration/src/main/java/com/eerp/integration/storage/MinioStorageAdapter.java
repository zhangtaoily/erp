package com.eerp.integration.storage;

import com.eerp.common.exception.ServiceException;
import io.minio.BucketExistsArgs;
import io.minio.GetObjectArgs;
import io.minio.MakeBucketArgs;
import io.minio.MinioClient;
import io.minio.PutObjectArgs;
import io.minio.RemoveObjectArgs;
import io.minio.StatObjectArgs;
import io.minio.errors.ErrorResponseException;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;

import java.io.InputStream;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.UUID;

/**
 * MinIO 存储适配器。
 *
 * <p>当 {@code eerp.storage.type=minio} 时激活。
 * 配置项：endpoint / access-key / secret-key / bucket-name。</p>
 */
@Service
@ConditionalOnProperty(name = "eerp.storage.type", havingValue = "minio")
public class MinioStorageAdapter extends AbstractStorageAdapter implements StorageOperations {

    private static final DateTimeFormatter YM_FORMATTER = DateTimeFormatter.ofPattern("yyyy/MM");
    private static final long UNKNOWN_SIZE = -1L;
    private static final long PART_SIZE = 10L * 1024 * 1024;

    @Value("${eerp.storage.minio.endpoint:http://localhost:9000}")
    private String endpoint;

    @Value("${eerp.storage.minio.access-key:minioadmin}")
    private String accessKey;

    @Value("${eerp.storage.minio.secret-key:minioadmin}")
    private String secretKey;

    @Value("${eerp.storage.minio.bucket-name:eerp-attachments}")
    private String bucketName;

    private MinioClient client;

    @PostConstruct
    public void init() {
        try {
            client = MinioClient.builder()
                    .endpoint(endpoint)
                    .credentials(accessKey, secretKey)
                    .build();
            if (!client.bucketExists(BucketExistsArgs.builder().bucket(bucketName).build())) {
                client.makeBucket(MakeBucketArgs.builder().bucket(bucketName).build());
            }
        } catch (Exception e) {
            throw new ServiceException("STORAGE_001", "初始化 MinIO 客户端失败: " + endpoint, e);
        }
    }

    @Override
    public String upload(InputStream stream, String fileName, String contentType) throws ServiceException {
        try {
            String ym = LocalDate.now().format(YM_FORMATTER);
            String safeName = sanitizeFileName(fileName);
            String objectKey = ym + "/" + UUID.randomUUID().toString().replace("-", "") + "_" + safeName;

            client.putObject(PutObjectArgs.builder()
                    .bucket(bucketName)
                    .object(objectKey)
                    .stream(stream, UNKNOWN_SIZE, PART_SIZE)
                    .contentType(contentType == null ? "application/octet-stream" : contentType)
                    .build());
            return objectKey;
        } catch (Exception e) {
            throw new ServiceException("STORAGE_002", "MinIO 文件上传失败: " + fileName, e);
        }
    }

    @Override
    public InputStream download(String path) throws ServiceException {
        try {
            return client.getObject(GetObjectArgs.builder()
                    .bucket(bucketName)
                    .object(path)
                    .build());
        } catch (Exception e) {
            throw new ServiceException("STORAGE_003", "MinIO 文件下载失败: " + path, e);
        }
    }

    @Override
    public void delete(String path) throws ServiceException {
        try {
            client.removeObject(RemoveObjectArgs.builder()
                    .bucket(bucketName)
                    .object(path)
                    .build());
        } catch (Exception e) {
            throw new ServiceException("STORAGE_004", "MinIO 文件删除失败: " + path, e);
        }
    }

    @Override
    public boolean exists(String path) {
        try {
            client.statObject(StatObjectArgs.builder()
                    .bucket(bucketName)
                    .object(path)
                    .build());
            return true;
        } catch (ErrorResponseException e) {
            // NoSuchKey 表示对象不存在
            return false;
        } catch (Exception e) {
            throw new ServiceException("STORAGE_005", "MinIO 文件存在性校验失败: " + path, e);
        }
    }

    @Override
    public String getType() {
        return "minio";
    }

    private String sanitizeFileName(String fileName) {
        if (fileName == null || fileName.isEmpty()) {
            return "unnamed";
        }
        return fileName.replaceAll("[\\\\/]", "_");
    }
}
