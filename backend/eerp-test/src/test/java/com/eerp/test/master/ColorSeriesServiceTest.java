package com.eerp.test.master;

import com.eerp.bos.bill.BillDataAccessor;
import com.eerp.bos.bill.BillOperationContext;
import com.eerp.bos.bill.BillOperationResult;
import com.eerp.bos.list.AbstractListService;
import com.eerp.master.entity.MdColorSeries;
import com.eerp.master.mapper.MdColorSeriesMapper;
import com.eerp.master.service.ColorSeriesService;
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
class ColorSeriesServiceTest {

    @Mock private BillDataAccessor billDataAccessor;
    @Mock private AbstractListService listService;
    @Mock private MdColorSeriesMapper mdColorSeriesMapper;

    @InjectMocks private ColorSeriesService colorSeriesService;

    private static final String BO_CODE = "MD_COLOR_SERIES";
    private static final Long ID = 1001L;

    @Test
    @DisplayName("保存色系：委托 BillDataAccessor 返回ID")
    void testSave() {
        Map<String, Object> billData = new HashMap<>();
        billData.put("main", new HashMap<>());
        BillOperationContext ctx = BillOperationContext.builder()
                .boCode(BO_CODE).operation("save").billData(billData).userName("admin").build();
        when(billDataAccessor.saveBill(eq(BO_CODE), any())).thenReturn(ID);

        BillOperationResult result = colorSeriesService.save(ctx);

        assertTrue(result.isSuccess());
        assertEquals(ID, result.getData());
        verify(billDataAccessor).saveBill(eq(BO_CODE), any());
    }

    @Test
    @DisplayName("保存色系数据为空时返回失败")
    void testSaveNullData() {
        BillOperationContext ctx = BillOperationContext.builder().boCode(BO_CODE).operation("save").build();
        BillOperationResult result = colorSeriesService.save(ctx);
        assertFalse(result.isSuccess());
    }

    @Test
    @DisplayName("启用色系：更新enabled=1")
    void testEnable() {
        MdColorSeries colorSeries = new MdColorSeries();
        colorSeries.setId(ID);
        colorSeries.setEnabled(0);
        when(mdColorSeriesMapper.selectById(ID)).thenReturn(colorSeries);

        colorSeriesService.enable(ID);

        assertEquals(1, colorSeries.getEnabled());
        verify(mdColorSeriesMapper).updateById(colorSeries);
    }

    @Test
    @DisplayName("查询色系详情：委托 BillDataAccessor")
    void testGetBillDetail() {
        Map<String, Object> detail = new HashMap<>();
        when(billDataAccessor.loadBill(BO_CODE, ID)).thenReturn(detail);

        Map<String, Object> result = colorSeriesService.getBillDetail(BO_CODE, ID);

        assertSame(detail, result);
        verify(billDataAccessor).loadBill(BO_CODE, ID);
    }

    @Test
    @DisplayName("按ID查询色系：委托 Mapper")
    void testFindById() {
        MdColorSeries colorSeries = new MdColorSeries();
        colorSeries.setId(ID);
        when(mdColorSeriesMapper.selectById(ID)).thenReturn(colorSeries);

        MdColorSeries result = colorSeriesService.findById(ID);

        assertNotNull(result);
        assertEquals(ID, result.getId());
    }
}
