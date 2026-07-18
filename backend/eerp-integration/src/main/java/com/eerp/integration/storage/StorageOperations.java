package com.eerp.integration.storage;

import com.eerp.common.exception.ServiceException;

import java.io.InputStream;

/**
 * 存储操作契约接口。
 *
 * <p>由于 {@link AbstractStorageAdapter} 为 Phase 1 空骨架（不可修改），
 * 此接口定义存储原语方法签名，供各适配器实现并由 {@link StorageAdapterRegistry} 统一路由。</p>
 */
public interface StorageOperations {

    /**
     * 上传文件流，返回存储路径（key）。
     *
     * @param stream      文件输入流
     * @param fileName    原始文件名
     * @param contentType 内容类型
     * @return 存储路径（如 /data/attachments/2026/07/uuid_filename 或 minio 的 object key）
     */
    String upload(InputStream stream, String fileName, String contentType) throws ServiceException;

    /**
     * 按存储路径下载文件，返回输入流。
     *
     * @param path 存储路径
     * @return 文件输入流
     */
    InputStream download(String path) throws ServiceException;

    /**
     * 按存储路径删除文件。
     *
     * @param path 存储路径
     */
    void delete(String path) throws ServiceException;

    /**
     * 判断存储路径对应的文件是否存在。
     *
     * @param path 存储路径
     * @return true 表示存在
     */
    boolean exists(String path);

    /**
     * 返回存储类型标识：local / oss / minio。
     *
     * @return 存储类型
     */
    String getType();
}
