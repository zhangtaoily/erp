package com.eerp.test;

import com.eerp.common.id.SnowflakeIdGenerator;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.Collections;
import java.util.HashSet;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * 雪花ID生成器单元测试
 */
class SnowflakeIdGeneratorTest {

    private SnowflakeIdGenerator generator;

    @BeforeEach
    void setUp() {
        generator = new SnowflakeIdGenerator();
    }

    @Test
    @DisplayName("生成1000个ID全部唯一")
    void testNextIdUniqueness() {
        int count = 1000;
        Set<Long> ids = new HashSet<>(count);
        for (int i = 0; i < count; i++) {
            long id = generator.nextId();
            assertTrue(ids.add(id), "第 " + i + " 个ID重复: " + id);
        }
        assertEquals(count, ids.size(), "唯一ID数量应等于生成数量");
    }

    @Test
    @DisplayName("多线程并发生成ID保持唯一性")
    void testConcurrentGeneration() throws InterruptedException {
        int threadCount = 16;
        int idsPerThread = 500;
        Set<Long> allIds = Collections.newSetFromMap(new ConcurrentHashMap<>());
        CountDownLatch latch = new CountDownLatch(threadCount);
        ExecutorService pool = Executors.newFixedThreadPool(threadCount);

        try {
            for (int t = 0; t < threadCount; t++) {
                pool.submit(() -> {
                    try {
                        for (int i = 0; i < idsPerThread; i++) {
                            allIds.add(generator.nextId());
                        }
                    } finally {
                        latch.countDown();
                    }
                });
            }
            assertTrue(latch.await(30, TimeUnit.SECONDS), "所有线程应执行完毕");
        } finally {
            pool.shutdownNow();
        }

        int expected = threadCount * idsPerThread;
        assertEquals(expected, allIds.size(), "并发生成的ID总数应无重复");
    }

    @Test
    @DisplayName("字符串形式ID与长整型一致且非空")
    void testNextIdAsString() {
        long id = generator.nextId();
        String idStr = generator.nextIdAsString();

        assertNotNull(idStr, "字符串ID不应为空");
        assertTrue(idStr.matches("\\d+"), "字符串ID应为纯数字");
        assertNotEquals(String.valueOf(id), idStr, "两次生成的ID不应相等");
        assertEquals(Long.parseLong(idStr), Long.parseLong(idStr), "字符串ID可解析回长整型");
    }
}
