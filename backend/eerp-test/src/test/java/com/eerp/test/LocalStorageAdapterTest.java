package com.eerp.test;

import com.eerp.integration.storage.LocalStorageAdapter;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.io.ByteArrayInputStream;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * 本地存储适配器单元测试。
 *
 * <p>不启动 Spring 容器，直接 new {@link LocalStorageAdapter} 并通过 {@code setBasePath}
 * 注入临时目录，验证 upload/download/delete/exists 及年月子目录自动创建。</p>
 */
class LocalStorageAdapterTest {

    private LocalStorageAdapter adapter;
    private Path tempRoot;

    @BeforeEach
    void setUp() throws Exception {
        tempRoot = Files.createTempDirectory("eerp-local-storage-test");
        adapter = new LocalStorageAdapter();
        adapter.setBasePath(tempRoot.toString());
        adapter.init();
    }

    @AfterEach
    void tearDown() throws Exception {
        // 递归清理临时目录
        if (tempRoot != null && Files.exists(tempRoot)) {
            Files.walk(tempRoot)
                    .sorted((a, b) -> b.compareTo(a))
                    .forEach(p -> {
                        try {
                            Files.deleteIfExists(p);
                        } catch (Exception ignored) {
                        }
                    });
        }
    }

    @Test
    @DisplayName("upload：上传字节流返回路径且文件存在")
    void testUpload() throws Exception {
        byte[] content = "hello-eerp-attachment".getBytes();
        String path = adapter.upload(
                new ByteArrayInputStream(content), "demo.txt", "text/plain");

        assertNotNull(path, "上传返回路径不应为空");
        assertTrue(adapter.exists(path), "上传后文件应存在");
        assertTrue(Files.exists(Paths.get(path)), "文件应实际写入磁盘");
    }

    @Test
    @DisplayName("download：下载返回原始内容")
    void testDownload() throws Exception {
        byte[] content = "download-content-原始内容".getBytes("UTF-8");
        String path = adapter.upload(
                new ByteArrayInputStream(content), "中文文件.txt", "text/plain");

        try (InputStream in = adapter.download(path)) {
            byte[] actual = in.readAllBytes();
            assertArrayEquals(content, actual, "下载内容应与上传内容一致");
        }
    }

    @Test
    @DisplayName("delete：删除后 exists=false")
    void testDelete() throws Exception {
        byte[] content = "to-be-deleted".getBytes();
        String path = adapter.upload(
                new ByteArrayInputStream(content), "temp.bin", "application/octet-stream");

        assertTrue(adapter.exists(path), "删除前文件应存在");

        adapter.delete(path);

        assertFalse(adapter.exists(path), "删除后文件应不存在");
        assertFalse(Files.exists(Paths.get(path)), "磁盘文件应已被删除");
    }

    @Test
    @DisplayName("年月子目录自动创建")
    void testYearMonthSubdirAutoCreated() throws Exception {
        byte[] content = "ym-check".getBytes();
        String path = adapter.upload(
                new ByteArrayInputStream(content), "ym.txt", "text/plain");

        Path file = Paths.get(path);
        // 结构：tempRoot/yyyy/MM/uuid_name
        Path monthDir = file.getParent();
        Path yearDir = monthDir.getParent();

        assertNotNull(monthDir, "月目录不应为空");
        assertNotNull(yearDir, "年目录不应为空");

        String expectedYearMonth = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyy/MM"));
        String actualYearMonth = yearDir.getFileName().toString() + "/" + monthDir.getFileName().toString();

        assertEquals(expectedYearMonth, actualYearMonth, "应自动创建当前年月子目录");
        assertEquals(tempRoot, yearDir.getParent(), "年目录应位于根目录下");
    }
}
