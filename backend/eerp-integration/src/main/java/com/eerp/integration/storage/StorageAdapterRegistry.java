package com.eerp.integration.storage;

import com.eerp.common.exception.ServiceException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 存储适配器注册中心。
 *
 * <p>Spring 自动注入所有 {@link AbstractStorageAdapter} 实现（每适配器按
 * {@code @ConditionalOnProperty} 激活），按 {@code eerp.storage.type} 配置选择当前激活的适配器。</p>
 */
@Service
public class StorageAdapterRegistry {

    private final Map<String, StorageOperations> adapters = new HashMap<>();

    @Value("${eerp.storage.type:local}")
    private String type;

    public StorageAdapterRegistry(List<AbstractStorageAdapter> adapterList) {
        // 注入所有 AbstractStorageAdapter 实现，按其声明的存储类型建立索引
        if (adapterList != null) {
            for (AbstractStorageAdapter adapter : adapterList) {
                if (adapter instanceof StorageOperations ops) {
                    adapters.put(ops.getType(), ops);
                }
            }
        }
    }

    /**
     * 返回当前激活的存储适配器。
     *
     * @return 存储适配器
     */
    public StorageOperations getAdapter() {
        StorageOperations adapter = adapters.get(type);
        if (adapter == null) {
            throw new ServiceException("STORAGE_001", "未找到匹配的存储适配器: eerp.storage.type=" + type);
        }
        return adapter;
    }

    /**
     * 返回当前激活的存储类型标识。
     *
     * @return 存储类型（local/oss/minio）
     */
    public String getType() {
        return type;
    }
}
