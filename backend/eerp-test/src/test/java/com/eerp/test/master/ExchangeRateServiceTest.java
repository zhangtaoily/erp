package com.eerp.test.master;

import com.eerp.bos.bill.BillDataAccessor;
import com.eerp.bos.bill.BillOperationContext;
import com.eerp.bos.bill.BillOperationResult;
import com.eerp.bos.list.AbstractListService;
import com.eerp.common.exception.ServiceException;
import com.eerp.master.entity.MdExchangeRate;
import com.eerp.master.mapper.MdExchangeRateMapper;
import com.eerp.master.service.ExchangeRateService;
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
class ExchangeRateServiceTest {

    @Mock private BillDataAccessor billDataAccessor;
    @Mock private AbstractListService listService;
    @Mock private MdExchangeRateMapper mdExchangeRateMapper;

    @InjectMocks private ExchangeRateService exchangeRateService;

    private static final String BO_CODE = "MD_EXCHANGE_RATE";
    private static final Long ID = 1001L;

    @Test
    @DisplayName("保存汇率：委托 BillDataAccessor 返回ID")
    void testSave() {
        Map<String, Object> billData = new HashMap<>();
        billData.put("main", new HashMap<>());
        BillOperationContext ctx = BillOperationContext.builder()
                .boCode(BO_CODE).operation("save").billData(billData).userName("admin").build();
        when(billDataAccessor.saveBill(eq(BO_CODE), any())).thenReturn(ID);

        BillOperationResult result = exchangeRateService.save(ctx);

        assertTrue(result.isSuccess());
        assertEquals(ID, result.getData());
        verify(billDataAccessor).saveBill(eq(BO_CODE), any());
    }

    @Test
    @DisplayName("保存汇率数据为空时返回失败")
    void testSaveNullData() {
        BillOperationContext ctx = BillOperationContext.builder().boCode(BO_CODE).operation("save").build();
        BillOperationResult result = exchangeRateService.save(ctx);
        assertFalse(result.isSuccess());
    }

    @Test
    @DisplayName("启用汇率：实体缺少 status/enabled 字段时抛出异常")
    void testEnable() {
        MdExchangeRate rate = new MdExchangeRate();
        rate.setId(ID);
        when(mdExchangeRateMapper.selectById(ID)).thenReturn(rate);

        assertThrows(ServiceException.class, () -> exchangeRateService.enable(ID));
    }

    @Test
    @DisplayName("查询汇率详情：委托 BillDataAccessor")
    void testGetBillDetail() {
        Map<String, Object> detail = new HashMap<>();
        when(billDataAccessor.loadBill(BO_CODE, ID)).thenReturn(detail);

        Map<String, Object> result = exchangeRateService.getBillDetail(BO_CODE, ID);

        assertSame(detail, result);
        verify(billDataAccessor).loadBill(BO_CODE, ID);
    }

    @Test
    @DisplayName("按ID查询汇率：委托 Mapper")
    void testFindById() {
        MdExchangeRate rate = new MdExchangeRate();
        rate.setId(ID);
        when(mdExchangeRateMapper.selectById(ID)).thenReturn(rate);

        MdExchangeRate result = exchangeRateService.findById(ID);

        assertNotNull(result);
        assertEquals(ID, result.getId());
    }
}
