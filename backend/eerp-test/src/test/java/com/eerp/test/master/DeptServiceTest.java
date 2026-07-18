package com.eerp.test.master;

import com.eerp.bos.bill.BillDataAccessor;
import com.eerp.bos.bill.BillOperationContext;
import com.eerp.bos.bill.BillOperationResult;
import com.eerp.bos.list.AbstractListService;
import com.eerp.master.entity.SysDept;
import com.eerp.master.mapper.MdDeptMapper;
import com.eerp.master.service.DeptService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.HashMap;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class DeptServiceTest {

    @Mock private BillDataAccessor billDataAccessor;
    @Mock private AbstractListService listService;
    @Mock private JdbcTemplate jdbcTemplate;
    @Mock private MdDeptMapper mdDeptMapper;

    @InjectMocks private DeptService deptService;

    private static final String BO_CODE = "MD_DEPT";
    private static final Long ID = 1001L;

    @Test
    @DisplayName("保存部门：委托 BillDataAccessor 返回ID")
    void testSave() {
        Map<String, Object> billData = new HashMap<>();
        billData.put("main", new HashMap<>());
        BillOperationContext ctx = BillOperationContext.builder()
                .boCode(BO_CODE).operation("save").billData(billData).userName("admin").build();
        when(billDataAccessor.saveBill(eq(BO_CODE), any())).thenReturn(ID);

        BillOperationResult result = deptService.save(ctx);

        assertTrue(result.isSuccess());
        assertEquals(ID, result.getData());
        verify(billDataAccessor).saveBill(eq(BO_CODE), any());
    }

    @Test
    @DisplayName("保存部门数据为空时返回失败")
    void testSaveNullData() {
        BillOperationContext ctx = BillOperationContext.builder().boCode(BO_CODE).operation("save").build();
        BillOperationResult result = deptService.save(ctx);
        assertFalse(result.isSuccess());
    }

    @Test
    @DisplayName("启用部门：更新status=1")
    void testEnable() {
        SysDept dept = new SysDept();
        dept.setId(ID);
        dept.setStatus(0);
        when(mdDeptMapper.selectById(ID)).thenReturn(dept);

        deptService.enable(ID);

        assertEquals(1, dept.getStatus());
        verify(mdDeptMapper).updateById(dept);
    }

    @Test
    @DisplayName("查询部门详情：委托 BillDataAccessor")
    void testGetBillDetail() {
        Map<String, Object> detail = new HashMap<>();
        when(billDataAccessor.loadBill(BO_CODE, ID)).thenReturn(detail);

        Map<String, Object> result = deptService.getBillDetail(BO_CODE, ID);

        assertSame(detail, result);
        verify(billDataAccessor).loadBill(BO_CODE, ID);
    }

    @Test
    @DisplayName("按ID查询部门：委托 Mapper")
    void testFindById() {
        SysDept dept = new SysDept();
        dept.setId(ID);
        when(mdDeptMapper.selectById(ID)).thenReturn(dept);

        SysDept result = deptService.findById(ID);

        assertNotNull(result);
        assertEquals(ID, result.getId());
    }
}
