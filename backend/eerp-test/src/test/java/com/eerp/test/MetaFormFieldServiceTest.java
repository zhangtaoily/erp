package com.eerp.test;

import com.baomidou.mybatisplus.core.MybatisConfiguration;
import com.baomidou.mybatisplus.core.metadata.TableInfoHelper;
import com.eerp.meta.field.entity.MetaFormField;
import com.eerp.meta.field.mapper.MetaFormFieldMapper;
import com.eerp.meta.field.service.impl.MetaFormFieldServiceImpl;
import org.apache.ibatis.builder.MapperBuilderAssistant;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Spy;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyCollection;
import static org.mockito.Mockito.doReturn;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * 表单字段 Service 单元测试
 * <p>
 * 注意：listByBoAndEntity / batchSave 内部使用 MyBatis-Plus 的 lambdaQuery / lambdaUpdate 链式 API，
 * 链式调用的 .list() 最终委托 baseMapper.selectList(wrapper)，.remove() 委托 baseMapper.delete(wrapper)，
 * 因此只需 mock baseMapper 的 selectList / delete 即可。
 * </p>
 * <p>背景：entity_code 在不同 bo_code 下可能重复（如 SAL_INT_CONT 和 SAL_QUOTE 都有 goods 子表），
 * 必须用 bo_code + entity_code 联合定位。</p>
 */
@ExtendWith(MockitoExtension.class)
class MetaFormFieldServiceTest {

    @Mock
    private MetaFormFieldMapper baseMapper;

    @Spy
    @InjectMocks
    private MetaFormFieldServiceImpl service;

    /**
     * 手动初始化 MyBatis-Plus TableInfoCache，使 lambdaQuery/lambdaUpdate
     * 能通过 TableInfoHelper 解析 lambda 列名（正常由 SqlSessionFactory 初始化）。
     */
    @BeforeAll
    static void initTableInfo() {
        MybatisConfiguration configuration = new MybatisConfiguration();
        MapperBuilderAssistant assistant = new MapperBuilderAssistant(configuration, "");
        TableInfoHelper.initTableInfo(assistant, MetaFormField.class);
    }

    @BeforeEach
    void setUp() {
        // ServiceImpl 的 baseMapper 字段因泛型擦除 @InjectMocks 无法注入，通过反射手动设置
        ReflectionTestUtils.setField(service, "baseMapper", baseMapper);
    }

    @Test
    @DisplayName("listByBoAndEntity 按 bo_code + entity_code 查询字段列表")
    void testListByBoAndEntity() {
        MetaFormField f1 = new MetaFormField();
        f1.setId(1L);
        f1.setBoCode("SAL_QUOTE");
        f1.setEntityCode("goods");
        f1.setFieldCode("code");
        f1.setFieldName("编码");
        f1.setSortIndex(1);

        MetaFormField f2 = new MetaFormField();
        f2.setId(2L);
        f2.setBoCode("SAL_QUOTE");
        f2.setEntityCode("goods");
        f2.setFieldCode("name");
        f2.setFieldName("名称");
        f2.setSortIndex(2);

        List<MetaFormField> fields = Arrays.asList(f1, f2);
        when(baseMapper.selectList(any())).thenReturn(fields);

        List<MetaFormField> result = service.listByBoAndEntity("SAL_QUOTE", "goods");

        assertNotNull(result, "结果不应为空");
        assertEquals(2, result.size(), "应返回2个字段");
        assertEquals("code", result.get(0).getFieldCode());
        assertEquals("name", result.get(1).getFieldCode());
        verify(baseMapper).selectList(any());
    }

    @Test
    @DisplayName("listByBoAndEntity 无字段时返回空列表")
    void testListByBoAndEntityEmpty() {
        when(baseMapper.selectList(any())).thenReturn(Collections.emptyList());

        List<MetaFormField> result = service.listByBoAndEntity("SAL_QUOTE", "EMPTY_ENTITY");
        assertNotNull(result);
        assertTrue(result.isEmpty());
    }

    @Test
    @DisplayName("batchSave 清空旧字段后批量保存新字段，并归属到指定 bo_code + entity_code")
    void testBatchSave() {
        MetaFormField f1 = new MetaFormField();
        f1.setFieldCode("qty");
        f1.setFieldName("数量");

        MetaFormField f2 = new MetaFormField();
        f2.setFieldCode("price");
        f2.setFieldName("单价");

        List<MetaFormField> fields = new ArrayList<>(Arrays.asList(f1, f2));

        // mock delete（lambdaUpdate().remove() 委托 baseMapper.delete）
        when(baseMapper.delete(any())).thenReturn(1);
        // stub saveBatch 避免 MyBatis-Plus SqlHelper 依赖真实 SqlSessionFactory
        doReturn(true).when(service).saveBatch(anyCollection());

        service.batchSave("SAL_QUOTE", "goods", fields);

        // 验证先删除旧字段
        verify(baseMapper).delete(any());
        // 验证批量保存被调用
        verify(service).saveBatch(fields);
        // 验证字段已归属到指定 bo_code + 实体
        assertEquals("SAL_QUOTE", f1.getBoCode());
        assertEquals("goods", f1.getEntityCode());
        assertEquals("SAL_QUOTE", f2.getBoCode());
        assertEquals("goods", f2.getEntityCode());
    }

    @Test
    @DisplayName("batchSave 传入空列表时只执行删除")
    void testBatchSaveEmptyList() {
        when(baseMapper.delete(any())).thenReturn(0);

        service.batchSave("SAL_QUOTE", "goods", Collections.emptyList());

        verify(baseMapper).delete(any());
    }

    @Test
    @DisplayName("batchSave 传入 null 时只执行删除")
    void testBatchSaveNullList() {
        when(baseMapper.delete(any())).thenReturn(0);

        service.batchSave("SAL_QUOTE", "goods", null);

        verify(baseMapper).delete(any());
    }
}
