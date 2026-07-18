package com.eerp.test;

import com.eerp.meta.bo.entity.MetaBusinessObject;
import com.eerp.meta.bo.mapper.MetaBusinessObjectMapper;
import com.eerp.meta.bo.service.impl.MetaBusinessObjectServiceImpl;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * 业务对象 Service 单元测试
 */
@ExtendWith(MockitoExtension.class)
class MetaBusinessObjectServiceTest {

    @Mock
    private MetaBusinessObjectMapper baseMapper;

    @InjectMocks
    private MetaBusinessObjectServiceImpl service;

    @BeforeEach
    void setUp() {
        // MyBatis-Plus ServiceImpl 的 baseMapper 字段由泛型擦除导致 @InjectMocks 无法注入，
        // 需通过反射手动设置父类 ServiceImpl 的 protected baseMapper 字段
        ReflectionTestUtils.setField(service, "baseMapper", baseMapper);
    }

    @Test
    @DisplayName("getByBoCode根据编码查询业务对象")
    void testGetByBoCode() {
        MetaBusinessObject bo = new MetaBusinessObject();
        bo.setId(1L);
        bo.setBoCode("SAL_ORDER");
        bo.setBoName("销售订单");
        bo.setMainTable("sal_order");
        when(baseMapper.getByBoCode("SAL_ORDER")).thenReturn(bo);

        MetaBusinessObject result = service.getByBoCode("SAL_ORDER");

        assertNotNull(result, "查询结果不应为空");
        assertEquals("SAL_ORDER", result.getBoCode());
        assertEquals("销售订单", result.getBoName());
        assertEquals("sal_order", result.getMainTable());
        verify(baseMapper).getByBoCode("SAL_ORDER");
    }

    @Test
    @DisplayName("getByBoCode查询不存在的编码返回null")
    void testGetByBoCodeNotFound() {
        when(baseMapper.getByBoCode("NOT_EXIST")).thenReturn(null);

        MetaBusinessObject result = service.getByBoCode("NOT_EXIST");
        assertNull(result, "不存在的编码应返回null");
    }

    @Test
    @DisplayName("save调用baseMapper插入并返回成功")
    void testSave() {
        MetaBusinessObject bo = new MetaBusinessObject();
        bo.setBoCode("PUR_ORDER");
        bo.setBoName("采购订单");
        bo.setMainTable("pur_order");
        when(baseMapper.insert(bo)).thenReturn(1);

        boolean result = service.save(bo);

        assertTrue(result, "保存应返回成功");
        verify(baseMapper).insert(bo);
    }
}
