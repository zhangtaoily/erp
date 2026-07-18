package com.eerp.test.master;

import com.eerp.bos.bill.BillDataAccessor;
import com.eerp.bos.bill.BillOperationContext;
import com.eerp.bos.bill.BillOperationResult;
import com.eerp.bos.list.AbstractListService;
import com.eerp.master.entity.MdCompColor;
import com.eerp.master.mapper.MdCompColorMapper;
import com.eerp.master.service.CompColorService;
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
class CompColorServiceTest {

    @Mock private BillDataAccessor billDataAccessor;
    @Mock private AbstractListService listService;
    @Mock private MdCompColorMapper mdCompColorMapper;

    @InjectMocks private CompColorService compColorService;

    private static final String BO_CODE = "MD_COMP_COLOR";
    private static final Long ID = 1001L;

    @Test
    @DisplayName("保存成分色：委托 BillDataAccessor 返回ID")
    void testSave() {
        Map<String, Object> billData = new HashMap<>();
        billData.put("main", new HashMap<>());
        BillOperationContext ctx = BillOperationContext.builder()
                .boCode(BO_CODE).operation("save").billData(billData).userName("admin").build();
        when(billDataAccessor.saveBill(eq(BO_CODE), any())).thenReturn(ID);

        BillOperationResult result = compColorService.save(ctx);

        assertTrue(result.isSuccess());
        assertEquals(ID, result.getData());
        verify(billDataAccessor).saveBill(eq(BO_CODE), any());
    }

    @Test
    @DisplayName("保存成分色数据为空时返回失败")
    void testSaveNullData() {
        BillOperationContext ctx = BillOperationContext.builder().boCode(BO_CODE).operation("save").build();
        BillOperationResult result = compColorService.save(ctx);
        assertFalse(result.isSuccess());
    }

    @Test
    @DisplayName("启用成分色：更新enabled=1")
    void testEnable() {
        MdCompColor compColor = new MdCompColor();
        compColor.setId(ID);
        compColor.setEnabled(0);
        when(mdCompColorMapper.selectById(ID)).thenReturn(compColor);

        compColorService.enable(ID);

        assertEquals(1, compColor.getEnabled());
        verify(mdCompColorMapper).updateById(compColor);
    }

    @Test
    @DisplayName("查询成分色详情：委托 BillDataAccessor")
    void testGetBillDetail() {
        Map<String, Object> detail = new HashMap<>();
        when(billDataAccessor.loadBill(BO_CODE, ID)).thenReturn(detail);

        Map<String, Object> result = compColorService.getBillDetail(BO_CODE, ID);

        assertSame(detail, result);
        verify(billDataAccessor).loadBill(BO_CODE, ID);
    }

    @Test
    @DisplayName("按ID查询成分色：委托 Mapper")
    void testFindById() {
        MdCompColor compColor = new MdCompColor();
        compColor.setId(ID);
        when(mdCompColorMapper.selectById(ID)).thenReturn(compColor);

        MdCompColor result = compColorService.findById(ID);

        assertNotNull(result);
        assertEquals(ID, result.getId());
    }
}
