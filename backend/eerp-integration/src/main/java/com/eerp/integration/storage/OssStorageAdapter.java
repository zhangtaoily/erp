package com.eerp.integration.storage;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;

import java.io.InputStream;

/**
 * 阿里云 OSS 存储适配器。
 *
 * <p>当前工程未引入 {@code com.aliyun.oss:aliyun-sdk-oss} 依赖，
 * 故所有操作抛出 {@link UnsupportedOperationException} 提示需补充依赖后实现。</p>
 *
 * <p>如需启用，请在 eerp-integration/pom.xml 增加：
 * <pre>
 * &lt;dependency&gt;
 *   &lt;groupId&gt;com.aliyun.oss&lt;/groupId&gt;
 *   &lt;artifactId&gt;aliyun-sdk-oss&lt;/artifactId&gt;
 * &lt;/dependency&gt;
 * </pre>
 * 并基于 OSS SDK 实现 {@link StorageOperations} 各方法。</p>
 */
@Service
@ConditionalOnProperty(name = "eerp.storage.type", havingValue = "oss")
public class OssStorageAdapter extends AbstractStorageAdapter implements StorageOperations {

    private static final String NOT_SUPPORTED_MSG =
            "OSS 存储适配器未实现：请在 eerp-integration/pom.xml 引入 com.aliyun.oss:aliyun-sdk-oss 依赖后完成实现";

    @Override
    public String upload(InputStream stream, String fileName, String contentType) {
        throw new UnsupportedOperationException(NOT_SUPPORTED_MSG);
    }

    @Override
    public InputStream download(String path) {
        throw new UnsupportedOperationException(NOT_SUPPORTED_MSG);
    }

    @Override
    public void delete(String path) {
        throw new UnsupportedOperationException(NOT_SUPPORTED_MSG);
    }

    @Override
    public boolean exists(String path) {
        throw new UnsupportedOperationException(NOT_SUPPORTED_MSG);
    }

    @Override
    public String getType() {
        return "oss";
    }
}
