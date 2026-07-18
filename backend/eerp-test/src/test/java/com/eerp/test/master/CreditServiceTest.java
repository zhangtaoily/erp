package com.eerp.test.master;

import com.eerp.bos.bill.BillDataAccessor;
import com.eerp.bos.bill.BillOperationContext;
import com.eerp.bos.bill.BillOperationResult;
import com.eerp.bos.list.AbstractListService;
import com.eerp.common.exception.ServiceException;
import com.eerp.master.entity.MdCredit;
import com.eerp.master.mapper.MdCreditMapper;
import com.eerp.master.service.CreditService;
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
class CreditServiceTest {

    @Mock private BillDataAccessor billDataAccessor;
    @Mock private AbstractListService listService;
    @Mock private MdCreditMapper mdCreditMapper;

    @InjectMocks private CreditService creditService;

    private static final String BO_CODE = "MD_CREDIT";
    private static final Long ID = 1001L;

    @Test
    @DisplayName("保存信用额度：委托 BillDataAccessor 返回ID")
    void testSave() {
        Map<String, Object> billData = new HashMap<>();
        billData.put("main", new HashMap<>());
        BillOperationContext ctx = BillOperationContext.builder()
                .boCode(BO_CODE).operation("save").billData(billData).userName("admin").build();
        when(billDataAccessor.saveBill(eq(BO_CODE), any())).thenReturn(ID);

        BillOperationResult result = creditService.save(ctx);

        assertTrue(result.isSuccess());
        assertEquals(ID, result.getData());
        verify(billDataAccessor).saveBill(eq(BO_CODE), any());
    }

    @Test
    @DisplayName("保存信用额度数据为空时返回失败")
    void testSaveNullData() {
        BillOperationContext ctx = BillOperationContext.builder().boCode(BO_CODE).operation("save").build();
        BillOperationResult result = creditService.save(ctx);
        assertFalse(result.isSuccess());
    }

    @Test
    @DisplayName("启用信用额度：实体缺少 status/enabled 字段时抛出异常")
    void testEnable() {
        MdCredit credit = new MdCredit();
        credit.setId(ID);
        when(mdCreditMapper.selectById(ID)).thenReturn(credit);

        assertThrows(ServiceException.class, () -> creditService.enable(ID));
    }

    @Test
    @DisplayName("查询信用额度详情：委托 BillDataAccessor")
    void testGetBillDetail() {
        Map<String, Object> detail = new HashMap<>();
        when(billDataAccessor.loadBill(BO_CODE, ID)).thenReturn(detail);

        Map<String, Object> result = creditService.getBillDetail(BO_CODE, ID);

        assertSame(detail, result);
        verify(billDataAccessor).loadBill(BO_CODE, ID);
    }

    @Test
    @DisplayName("按ID查询信用额度：委托 Mapper")
    void testFindById() {
        MdCredit credit = new MdCredit();
        credit.setId(ID);
        when(mdCreditMapper.selectById(ID)).thenReturn(credit);

        MdCredit result = creditService.findById(ID);

        assertNotNull(result);
        assertEquals(ID, result.getId());
    }
}
