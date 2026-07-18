package com.eerp.common.cache;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 元数据缓存抽象基类
 */
public abstract class AbstractMetaCache<K, V> {

    protected final Map<K, V> cache = new ConcurrentHashMap<>();

    protected final Map<K, Long> loadTimeMap = new ConcurrentHashMap<>();

    /** 过期时间 (毫秒)，默认 5 分钟 */
    protected long expireMs = 300000L;

    /**
     * 获取缓存值：命中且未过期直接返回，否则调用 {@link #load} 加载并缓存
     */
    public V get(K key) {
        V value = cache.get(key);
        Long loadTime = loadTimeMap.get(key);
        if (value != null && loadTime != null
                && (System.currentTimeMillis() - loadTime) < expireMs) {
            return value;
        }
        V loaded = load(key);
        if (loaded != null) {
            cache.put(key, loaded);
            loadTimeMap.put(key, System.currentTimeMillis());
        }
        return loaded;
    }

    /**
     * 刷新指定 key 的缓存
     */
    public void refresh(K key) {
        V value = load(key);
        cache.put(key, value);
        loadTimeMap.put(key, System.currentTimeMillis());
    }

    /**
     * 移除指定 key 的缓存
     */
    public void evict(K key) {
        cache.remove(key);
        loadTimeMap.remove(key);
    }

    /**
     * 清空所有缓存
     */
    public void evictAll() {
        cache.clear();
        loadTimeMap.clear();
    }

    /**
     * 加载指定 key 对应的数据 (由子类实现)
     */
    protected abstract V load(K key);
}
