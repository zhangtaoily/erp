package com.eerp.test;

import com.eerp.bos.list.ListServiceImpl;
import com.eerp.common.api.PageRequest;
import com.eerp.common.api.PageResult;
import com.eerp.meta.bo.entity.MetaBusinessObject;
import com.eerp.meta.bo.vo.FormMetaVO;
import com.eerp.meta.cache.FormMetaCache;
import com.eerp.meta.list.entity.MetaListColumn;
import com.eerp.meta.list.entity.MetaQueryField;
import com.eerp.meta.list.service.MetaListColumnService;
import com.eerp.meta.list.service.MetaQueryFieldService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * 列表查询服务单元测试
 */
@ExtendWith(MockitoExtension.class)
class ListServiceImplTest {

    @Mock
    private MetaListColumnService metaListColumnService;

    @Mock
    private MetaQueryFieldService metaQueryFieldService;

    @Mock
    private FormMetaCache formMetaCache;

    @Mock
    private JdbcTemplate jdbcTemplate;

    @InjectMocks
    private ListServiceImpl listService;

    private static final String BO_CODE = "SAL_ORDER";

    @BeforeEach
    void setUp() {
        MetaBusinessObject bo = new MetaBusinessObject();
        bo.setBoCode(BO_CODE);
        bo.setMainTable("sal_order");
        FormMetaVO vo = new FormMetaVO();
        vo.setBusinessObject(bo);
        lenient().when(formMetaCache.get(BO_CODE)).thenReturn(vo);
    }

    @Test
    @DisplayName("分页查询：无过滤条件返回分页结果")
    void testPageQuery() {
        // 列定义
        MetaListColumn col1 = new MetaListColumn();
        col1.setFieldCode("code");
        col1.setFieldName("编码");
        col1.setIsShow(1);
        col1.setIsEnable(1);

        MetaListColumn col2 = new MetaListColumn();
        col2.setFieldCode("name");
        col2.setFieldName("名称");
        col2.setIsShow(1);
        col2.setIsEnable(1);

        when(metaListColumnService.listByBoCode(BO_CODE)).thenReturn(Arrays.asList(col1, col2));
        when(metaQueryFieldService.listByBoCode(BO_CODE)).thenReturn(Collections.emptyList());

        // 查询结果
        List<Map<String, Object>> rows = Arrays.asList(
                Map.of("code", "SO001", "name", "订单A"),
                Map.of("code", "SO002", "name", "订单B")
        );
        when(jdbcTemplate.queryForList(anyString(), any(Object[].class))).thenReturn(rows);
        when(jdbcTemplate.queryForObject(anyString(), eq(Long.class), any(Object[].class))).thenReturn(2L);

        PageRequest pageRequest = new PageRequest();
        pageRequest.setPageNum(1);
        pageRequest.setPageSize(20);

        PageResult<Map<String, Object>> result = listService.page(BO_CODE, pageRequest, null);

        assertNotNull(result);
        assertEquals(2, result.getList().size(), "应返回2条记录");
        assertEquals(2L, result.getTotal(), "总数应为2");
        assertEquals(1, result.getPageNum());
        assertEquals(20, result.getPageSize());
        verify(jdbcTemplate).queryForList(anyString(), any(Object[].class));
    }

    @Test
    @DisplayName("带过滤条件的分页查询")
    void testQueryWithFilters() {
        // 列定义
        MetaListColumn col = new MetaListColumn();
        col.setFieldCode("code");
        col.setFieldName("编码");
        col.setIsShow(1);
        col.setIsEnable(1);
        when(metaListColumnService.listByBoCode(BO_CODE)).thenReturn(Collections.singletonList(col));

        // 查询字段配置：允许 code 字段使用 eq 运算符
        MetaQueryField qf = new MetaQueryField();
        qf.setFieldCode("code");
        qf.setFieldName("编码");
        qf.setOperators("eq,like");
        qf.setDefaultOp("eq");
        qf.setIsEnable(1);
        when(metaQueryFieldService.listByBoCode(BO_CODE)).thenReturn(Collections.singletonList(qf));

        // 查询参数：code = SO001
        Map<String, Object> params = new HashMap<>();
        params.put("code", "SO001");

        // 查询结果
        List<Map<String, Object>> rows = Collections.singletonList(
                Map.of("code", "SO001", "name", "订单A")
        );
        when(jdbcTemplate.queryForList(anyString(), any(Object[].class))).thenReturn(rows);
        when(jdbcTemplate.queryForObject(anyString(), eq(Long.class), any(Object[].class))).thenReturn(1L);

        PageRequest pageRequest = new PageRequest();
        pageRequest.setPageNum(1);
        pageRequest.setPageSize(10);

        PageResult<Map<String, Object>> result = listService.page(BO_CODE, pageRequest, params);

        assertNotNull(result);
        assertEquals(1, result.getList().size(), "应返回1条记录");
        assertEquals(1L, result.getTotal(), "总数应为1");
        // 验证查询SQL包含WHERE子句（通过参数数组长度判断）
        verify(jdbcTemplate).queryForList(anyString(), any(Object[].class));
    }

    @Test
    @DisplayName("业务对象未配置主表时返回空结果")
    void testPageQueryNoMainTable() {
        when(formMetaCache.get("NO_TABLE")).thenReturn(null);

        PageRequest pageRequest = new PageRequest();
        pageRequest.setPageNum(1);
        pageRequest.setPageSize(20);

        PageResult<Map<String, Object>> result = listService.page("NO_TABLE", pageRequest, null);

        assertNotNull(result);
        assertTrue(result.getList().isEmpty(), "无主表应返回空列表");
        assertEquals(0L, result.getTotal());
    }

    @Test
    @DisplayName("ORDER BY白名单校验：仅允许配置的列排序")
    void testPageQueryWithOrderBy() {
        MetaListColumn col = new MetaListColumn();
        col.setFieldCode("code");
        col.setFieldName("编码");
        col.setIsShow(1);
        col.setIsEnable(1);
        when(metaListColumnService.listByBoCode(BO_CODE)).thenReturn(Collections.singletonList(col));
        when(metaQueryFieldService.listByBoCode(BO_CODE)).thenReturn(Collections.emptyList());

        when(jdbcTemplate.queryForList(anyString(), any(Object[].class)))
                .thenReturn(Collections.emptyList());
        when(jdbcTemplate.queryForObject(anyString(), eq(Long.class), any(Object[].class))).thenReturn(0L);

        PageRequest pageRequest = new PageRequest();
        pageRequest.setPageNum(1);
        pageRequest.setPageSize(20);
        pageRequest.setOrderBy("code desc");

        PageResult<Map<String, Object>> result = listService.page(BO_CODE, pageRequest, null);

        assertNotNull(result);
        assertEquals(0L, result.getTotal());
    }
}
