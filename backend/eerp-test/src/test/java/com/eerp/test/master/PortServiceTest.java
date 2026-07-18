package com.eerp.test.master;

import com.eerp.bos.bill.BillDataAccessor;
import com.eerp.bos.bill.BillOperationContext;
import com.eerp.bos.bill.BillOperationResult;
import com.eerp.bos.list.AbstractListService;
import com.eerp.master.entity.MdHarbour;
import com.eerp.master.mapper.MdHarbourMapper;
import com.eerp.master.service.PortService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.util.HashMap;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class PortServiceTest {

    @Mock private BillDataAccessor billDataAccessor;
    @Mock private AbstractListService listService;
    @Mock private MdHarbourMapper mdHarbourMapper;

    @InjectMocks private PortService portService;

    private static final String BO_CODE = "MD_PORT";
    private static final Long ID = 1001L;

    @Test
    @DisplayName("保存港口：委托 BillDataAccessor 返回ID")
    void testSave() {
        Map<String, Object> billData = new HashMap<>();
        billData.put("main", new HashMap<>());
        BillOperationContext ctx = BillOperationContext.builder()
                .boCode(BO_CODE).operation("save").billData(billData).userName("admin").build();
        when(billDataAccessor.saveBill(eq(BO_CODE), any())).thenReturn(ID);

        BillOperationResult result = portService.save(ctx);

        assertTrue(result.isSuccess());
        assertEquals(ID, result.getData());
        verify(billDataAccessor).saveBill(eq(BO_CODE), any());
    }

    @Test
    @DisplayName("保存港口数据为空时返回失败")
    void testSaveNullData() {
        BillOperationContext ctx = BillOperationContext.builder().boCode(BO_CODE).operation("save").build();
        BillOperationResult result = portService.save(ctx);
        assertFalse(result.isSuccess());
    }

    @Test
    @DisplayName("启用港口：更新status=1")
    void testEnable() {
        MdHarbour port = new MdHarbour();
        port.setId(ID);
        port.setStatus(0);
        when(mdHarbourMapper.selectById(ID)).thenReturn(port);

        portService.enable(ID);

        assertEquals(1, port.getStatus());
        verify(mdHarbourMapper).updateById(port);
    }

    @Test
    @DisplayName("查询港口详情：委托 BillDataAccessor")
    void testGetBillDetail() {
        Map<String, Object> detail = new HashMap<>();
        when(billDataAccessor.loadBill(BO_CODE, ID)).thenReturn(detail);

        Map<String, Object> result = portService.getBillDetail(BO_CODE, ID);

        assertSame(detail, result);
        verify(billDataAccessor).loadBill(BO_CODE, ID);
    }

    @Test
    @DisplayName("按ID查询港口：委托 Mapper")
    void testFindById() {
        MdHarbour port = new MdHarbour();
        port.setId(ID);
        when(mdHarbourMapper.selectById(ID)).thenReturn(port);

        MdHarbour result = portService.findById(ID);

        assertNotNull(result);
        assertEquals(ID, result.getId());
    }
}
