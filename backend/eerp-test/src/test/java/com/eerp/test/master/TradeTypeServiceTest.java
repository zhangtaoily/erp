package com.eerp.test.master;

import com.eerp.bos.bill.BillDataAccessor;
import com.eerp.bos.bill.BillOperationContext;
import com.eerp.bos.bill.BillOperationResult;
import com.eerp.bos.list.AbstractListService;
import com.eerp.master.entity.MdTradeType;
import com.eerp.master.mapper.MdTradeTypeMapper;
import com.eerp.master.service.TradeTypeService;
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
class TradeTypeServiceTest {

    @Mock private BillDataAccessor billDataAccessor;
    @Mock private AbstractListService listService;
    @Mock private MdTradeTypeMapper mdTradeTypeMapper;

    @InjectMocks private TradeTypeService tradeTypeService;

    private static final String BO_CODE = "MD_TRADE_TYPE";
    private static final Long ID = 1001L;

    @Test
    @DisplayName("保存贸易类型：委托 BillDataAccessor 返回ID")
    void testSave() {
        Map<String, Object> billData = new HashMap<>();
        billData.put("main", new HashMap<>());
        BillOperationContext ctx = BillOperationContext.builder()
                .boCode(BO_CODE).operation("save").billData(billData).userName("admin").build();
        when(billDataAccessor.saveBill(eq(BO_CODE), any())).thenReturn(ID);

        BillOperationResult result = tradeTypeService.save(ctx);

        assertTrue(result.isSuccess());
        assertEquals(ID, result.getData());
        verify(billDataAccessor).saveBill(eq(BO_CODE), any());
    }

    @Test
    @DisplayName("保存贸易类型数据为空时返回失败")
    void testSaveNullData() {
        BillOperationContext ctx = BillOperationContext.builder().boCode(BO_CODE).operation("save").build();
        BillOperationResult result = tradeTypeService.save(ctx);
        assertFalse(result.isSuccess());
    }

    @Test
    @DisplayName("启用贸易类型：更新status=1")
    void testEnable() {
        MdTradeType tradeType = new MdTradeType();
        tradeType.setId(ID);
        tradeType.setStatus(0);
        when(mdTradeTypeMapper.selectById(ID)).thenReturn(tradeType);

        tradeTypeService.enable(ID);

        assertEquals(1, tradeType.getStatus());
        verify(mdTradeTypeMapper).updateById(tradeType);
    }

    @Test
    @DisplayName("查询贸易类型详情：委托 BillDataAccessor")
    void testGetBillDetail() {
        Map<String, Object> detail = new HashMap<>();
        when(billDataAccessor.loadBill(BO_CODE, ID)).thenReturn(detail);

        Map<String, Object> result = tradeTypeService.getBillDetail(BO_CODE, ID);

        assertSame(detail, result);
        verify(billDataAccessor).loadBill(BO_CODE, ID);
    }

    @Test
    @DisplayName("按ID查询贸易类型：委托 Mapper")
    void testFindById() {
        MdTradeType tradeType = new MdTradeType();
        tradeType.setId(ID);
        when(mdTradeTypeMapper.selectById(ID)).thenReturn(tradeType);

        MdTradeType result = tradeTypeService.findById(ID);

        assertNotNull(result);
        assertEquals(ID, result.getId());
    }
}
