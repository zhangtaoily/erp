package com.eerp.test.master;

import com.eerp.bos.bill.BillDataAccessor;
import com.eerp.bos.bill.BillOperationContext;
import com.eerp.bos.bill.BillOperationResult;
import com.eerp.bos.list.AbstractListService;
import com.eerp.master.entity.MdPrintColor;
import com.eerp.master.mapper.MdPrintColorMapper;
import com.eerp.master.service.PrintColorService;
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
class PrintColorServiceTest {

    @Mock private BillDataAccessor billDataAccessor;
    @Mock private AbstractListService listService;
    @Mock private MdPrintColorMapper mdPrintColorMapper;

    @InjectMocks private PrintColorService printColorService;

    private static final String BO_CODE = "MD_PRINT_COLOR";
    private static final Long ID = 1001L;

    @Test
    @DisplayName("保存印花色：委托 BillDataAccessor 返回ID")
    void testSave() {
        Map<String, Object> billData = new HashMap<>();
        billData.put("main", new HashMap<>());
        BillOperationContext ctx = BillOperationContext.builder()
                .boCode(BO_CODE).operation("save").billData(billData).userName("admin").build();
        when(billDataAccessor.saveBill(eq(BO_CODE), any())).thenReturn(ID);

        BillOperationResult result = printColorService.save(ctx);

        assertTrue(result.isSuccess());
        assertEquals(ID, result.getData());
        verify(billDataAccessor).saveBill(eq(BO_CODE), any());
    }

    @Test
    @DisplayName("保存印花色数据为空时返回失败")
    void testSaveNullData() {
        BillOperationContext ctx = BillOperationContext.builder().boCode(BO_CODE).operation("save").build();
        BillOperationResult result = printColorService.save(ctx);
        assertFalse(result.isSuccess());
    }

    @Test
    @DisplayName("启用印花色：更新enabled=1")
    void testEnable() {
        MdPrintColor printColor = new MdPrintColor();
        printColor.setId(ID);
        printColor.setEnabled(0);
        when(mdPrintColorMapper.selectById(ID)).thenReturn(printColor);

        printColorService.enable(ID);

        assertEquals(1, printColor.getEnabled());
        verify(mdPrintColorMapper).updateById(printColor);
    }

    @Test
    @DisplayName("查询印花色详情：委托 BillDataAccessor")
    void testGetBillDetail() {
        Map<String, Object> detail = new HashMap<>();
        when(billDataAccessor.loadBill(BO_CODE, ID)).thenReturn(detail);

        Map<String, Object> result = printColorService.getBillDetail(BO_CODE, ID);

        assertSame(detail, result);
        verify(billDataAccessor).loadBill(BO_CODE, ID);
    }

    @Test
    @DisplayName("按ID查询印花色：委托 Mapper")
    void testFindById() {
        MdPrintColor printColor = new MdPrintColor();
        printColor.setId(ID);
        when(mdPrintColorMapper.selectById(ID)).thenReturn(printColor);

        MdPrintColor result = printColorService.findById(ID);

        assertNotNull(result);
        assertEquals(ID, result.getId());
    }
}
