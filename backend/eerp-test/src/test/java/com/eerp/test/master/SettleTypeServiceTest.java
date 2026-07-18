package com.eerp.test.master;

import com.eerp.bos.bill.BillDataAccessor;
import com.eerp.bos.bill.BillOperationContext;
import com.eerp.bos.bill.BillOperationResult;
import com.eerp.bos.list.AbstractListService;
import com.eerp.master.entity.MdFirpType;
import com.eerp.master.mapper.MdFirpTypeMapper;
import com.eerp.master.service.SettleTypeService;
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
class SettleTypeServiceTest {

    @Mock private BillDataAccessor billDataAccessor;
    @Mock private AbstractListService listService;
    @Mock private MdFirpTypeMapper mdFirpTypeMapper;

    @InjectMocks private SettleTypeService settleTypeService;

    private static final String BO_CODE = "MD_SETTLE_TYPE";
    private static final Long ID = 1001L;

    @Test
    @DisplayName("保存结算类型：委托 BillDataAccessor 返回ID")
    void testSave() {
        Map<String, Object> billData = new HashMap<>();
        billData.put("main", new HashMap<>());
        BillOperationContext ctx = BillOperationContext.builder()
                .boCode(BO_CODE).operation("save").billData(billData).userName("admin").build();
        when(billDataAccessor.saveBill(eq(BO_CODE), any())).thenReturn(ID);

        BillOperationResult result = settleTypeService.save(ctx);

        assertTrue(result.isSuccess());
        assertEquals(ID, result.getData());
        verify(billDataAccessor).saveBill(eq(BO_CODE), any());
    }

    @Test
    @DisplayName("保存结算类型数据为空时返回失败")
    void testSaveNullData() {
        BillOperationContext ctx = BillOperationContext.builder().boCode(BO_CODE).operation("save").build();
        BillOperationResult result = settleTypeService.save(ctx);
        assertFalse(result.isSuccess());
    }

    @Test
    @DisplayName("启用结算类型：更新status=1")
    void testEnable() {
        MdFirpType settleType = new MdFirpType();
        settleType.setId(ID);
        settleType.setStatus(0);
        when(mdFirpTypeMapper.selectById(ID)).thenReturn(settleType);

        settleTypeService.enable(ID);

        assertEquals(1, settleType.getStatus());
        verify(mdFirpTypeMapper).updateById(settleType);
    }

    @Test
    @DisplayName("查询结算类型详情：委托 BillDataAccessor")
    void testGetBillDetail() {
        Map<String, Object> detail = new HashMap<>();
        when(billDataAccessor.loadBill(BO_CODE, ID)).thenReturn(detail);

        Map<String, Object> result = settleTypeService.getBillDetail(BO_CODE, ID);

        assertSame(detail, result);
        verify(billDataAccessor).loadBill(BO_CODE, ID);
    }

    @Test
    @DisplayName("按ID查询结算类型：委托 Mapper")
    void testFindById() {
        MdFirpType settleType = new MdFirpType();
        settleType.setId(ID);
        when(mdFirpTypeMapper.selectById(ID)).thenReturn(settleType);

        MdFirpType result = settleTypeService.findById(ID);

        assertNotNull(result);
        assertEquals(ID, result.getId());
    }
}
