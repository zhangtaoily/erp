package com.eerp.test.master;

import com.eerp.bos.bill.BillDataAccessor;
import com.eerp.bos.bill.BillOperationContext;
import com.eerp.bos.bill.BillOperationResult;
import com.eerp.bos.list.AbstractListService;
import com.eerp.master.entity.SysOrg;
import com.eerp.master.mapper.MdOrgMapper;
import com.eerp.master.service.OrgService;
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
class OrgServiceTest {

    @Mock private BillDataAccessor billDataAccessor;
    @Mock private AbstractListService listService;
    @Mock private JdbcTemplate jdbcTemplate;
    @Mock private MdOrgMapper mdOrgMapper;

    @InjectMocks private OrgService orgService;

    private static final String BO_CODE = "MD_ORG";
    private static final Long ID = 1001L;

    @Test
    @DisplayName("保存组织：委托 BillDataAccessor 返回ID")
    void testSave() {
        Map<String, Object> billData = new HashMap<>();
        billData.put("main", new HashMap<>());
        BillOperationContext ctx = BillOperationContext.builder()
                .boCode(BO_CODE).operation("save").billData(billData).userName("admin").build();
        when(billDataAccessor.saveBill(eq(BO_CODE), any())).thenReturn(ID);

        BillOperationResult result = orgService.save(ctx);

        assertTrue(result.isSuccess());
        assertEquals(ID, result.getData());
        verify(billDataAccessor).saveBill(eq(BO_CODE), any());
    }

    @Test
    @DisplayName("保存组织数据为空时返回失败")
    void testSaveNullData() {
        BillOperationContext ctx = BillOperationContext.builder().boCode(BO_CODE).operation("save").build();
        BillOperationResult result = orgService.save(ctx);
        assertFalse(result.isSuccess());
    }

    @Test
    @DisplayName("启用组织：更新status=1")
    void testEnable() {
        SysOrg org = new SysOrg();
        org.setId(ID);
        org.setStatus(0);
        when(mdOrgMapper.selectById(ID)).thenReturn(org);

        orgService.enable(ID);

        assertEquals(1, org.getStatus());
        verify(mdOrgMapper).updateById(org);
    }

    @Test
    @DisplayName("查询组织详情：委托 BillDataAccessor")
    void testGetBillDetail() {
        Map<String, Object> detail = new HashMap<>();
        when(billDataAccessor.loadBill(BO_CODE, ID)).thenReturn(detail);

        Map<String, Object> result = orgService.getBillDetail(BO_CODE, ID);

        assertSame(detail, result);
        verify(billDataAccessor).loadBill(BO_CODE, ID);
    }

    @Test
    @DisplayName("按ID查询组织：委托 Mapper")
    void testFindById() {
        SysOrg org = new SysOrg();
        org.setId(ID);
        when(mdOrgMapper.selectById(ID)).thenReturn(org);

        SysOrg result = orgService.findById(ID);

        assertNotNull(result);
        assertEquals(ID, result.getId());
    }
}
