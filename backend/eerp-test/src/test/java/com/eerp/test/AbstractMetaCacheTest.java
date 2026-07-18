package com.eerp.test;

import com.eerp.common.cache.AbstractMetaCache;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertSame;

/**
 * 元数据缓存抽象基类单元测试
 */
class AbstractMetaCacheTest {

    /** 测试用缓存子类：每次 load 计数并返回模拟数据 */
    static class TestMetaCache extends AbstractMetaCache<String, String> {
        final AtomicInteger loadCount = new AtomicInteger(0);

        @Override
        protected String load(String key) {
            loadCount.incrementAndGet();
            return "value-for-" + key;
        }

        void setExpireMs(long expireMs) {
            this.expireMs = expireMs;
        }
    }

    private TestMetaCache cache;

    @BeforeEach
    void setUp() {
        cache = new TestMetaCache();
        // 设置较短过期时间便于测试
        cache.setExpireMs(50L);
    }

    @Test
    @DisplayName("缓存命中时不重复load，未命中时触发load")
    void testCacheHitAndMiss() {
        // 首次获取：未命中，触发load
        String v1 = cache.get("k1");
        assertNotNull(v1, "首次获取不应返回null");
        assertEquals("value-for-k1", v1, "返回值应正确");
        assertEquals(1, cache.loadCount.get(), "首次获取应触发1次load");

        // 第二次获取：命中缓存，不触发load
        String v2 = cache.get("k1");
        assertEquals(v1, v2, "两次返回值应相同");
        assertEquals(1, cache.loadCount.get(), "命中缓存不应再触发load");

        // 获取不存在的key：未命中
        cache.get("k2");
        assertEquals(2, cache.loadCount.get(), "不同key应再次触发load");
    }

    @Test
    @DisplayName("缓存过期后重新加载")
    void testCacheExpiration() throws InterruptedException {
        cache.get("exp-key");
        assertEquals(1, cache.loadCount.get(), "首次应触发load");

        // 等待过期
        Thread.sleep(80);

        cache.get("exp-key");
        assertEquals(2, cache.loadCount.get(), "过期后应重新触发load");
    }

    @Test
    @DisplayName("evict移除指定key的缓存")
    void testCacheEvict() {
        cache.get("evict-key");
        assertEquals(1, cache.loadCount.get());

        cache.evict("evict-key");

        cache.get("evict-key");
        assertEquals(2, cache.loadCount.get(), "evict后再次获取应重新触发load");
    }

    @Test
    @DisplayName("refresh强制刷新缓存")
    void testCacheRefresh() {
        cache.get("refresh-key");
        assertEquals(1, cache.loadCount.get());

        // 命中缓存，不触发load
        cache.get("refresh-key");
        assertEquals(1, cache.loadCount.get());

        // refresh强制刷新
        cache.refresh("refresh-key");
        assertEquals(2, cache.loadCount.get(), "refresh应触发load");

        // 刷新后命中
        cache.get("refresh-key");
        assertEquals(2, cache.loadCount.get(), "刷新后应命中缓存");
    }

    @Test
    @DisplayName("evictAll清空所有缓存")
    void testCacheEvictAll() {
        cache.get("a");
        cache.get("b");
        assertEquals(2, cache.loadCount.get());

        cache.evictAll();

        cache.get("a");
        cache.get("b");
        assertEquals(4, cache.loadCount.get(), "evictAll后所有key应重新加载");
    }

    @Test
    @DisplayName("load返回null时不缓存")
    void testLoadReturnNull() {
        AbstractMetaCache<String, String> nullCache = new AbstractMetaCache<>() {
            @Override
            protected String load(String key) {
                return null;
            }
        };

        assertNull(nullCache.get("null-key"), "load返回null时get应返回null");
    }
}
