package com.eerp.integration.storage;

import com.eerp.common.exception.ServiceException;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;

import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.UUID;

/**
 * 本地磁盘存储适配器。
 *
 * <p>默认激活（{@code eerp.storage.type=local} 或缺省）。
 * 文件按年月子目录（yyyy/MM）组织，文件名前追加 UUID 防冲突。</p>
 */
@Service
@ConditionalOnProperty(name = "eerp.storage.type", havingValue = "local", matchIfMissing = true)
public class LocalStorageAdapter extends AbstractStorageAdapter implements StorageOperations {

    private static final DateTimeFormatter YM_FORMATTER = DateTimeFormatter.ofPattern("yyyy/MM");

    @Value("${eerp.storage.local.base-path:./data/attachments}")
    private String basePath;

    @PostConstruct
    public void init() {
        // 启动时确保根目录存在
        try {
            Files.createDirectories(resolveRoot());
        } catch (Exception e) {
            throw new ServiceException("STORAGE_001", "初始化本地存储根目录失败: " + basePath, e);
        }
    }

    /**
     * 供单元测试注入 basePath。
     */
    public void setBasePath(String basePath) {
        this.basePath = basePath;
    }

    private Path resolveRoot() {
        return Paths.get(basePath).toAbsolutePath().normalize();
    }

    @Override
    public String upload(InputStream stream, String fileName, String contentType) throws ServiceException {
        try {
            String ym = LocalDate.now().format(YM_FORMATTER);
            String safeName = sanitizeFileName(fileName);
            String storedName = UUID.randomUUID().toString().replace("-", "") + "_" + safeName;

            Path dir = resolveRoot().resolve(ym);
            Files.createDirectories(dir);

            Path target = dir.resolve(storedName);
            Files.copy(stream, target, StandardCopyOption.REPLACE_EXISTING);
            return target.toString();
        } catch (Exception e) {
            throw new ServiceException("STORAGE_002", "本地文件上传失败: " + fileName, e);
        }
    }

    @Override
    public InputStream download(String path) throws ServiceException {
        try {
            return Files.newInputStream(Paths.get(path));
        } catch (Exception e) {
            throw new ServiceException("STORAGE_003", "本地文件下载失败: " + path, e);
        }
    }

    @Override
    public void delete(String path) throws ServiceException {
        try {
            Files.deleteIfExists(Paths.get(path));
        } catch (Exception e) {
            throw new ServiceException("STORAGE_004", "本地文件删除失败: " + path, e);
        }
    }

    @Override
    public boolean exists(String path) {
        return Files.exists(Paths.get(path));
    }

    @Override
    public String getType() {
        return "local";
    }

    /**
     * 清理文件名中的路径分隔符，避免目录穿越。
     */
    private String sanitizeFileName(String fileName) {
        if (fileName == null || fileName.isEmpty()) {
            return "unnamed";
        }
        return fileName.replaceAll("[\\\\/]", "_");
    }
}
