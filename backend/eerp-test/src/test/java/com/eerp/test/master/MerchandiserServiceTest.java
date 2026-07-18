package com.eerp.test.master;

import com.eerp.bos.bill.BillDataAccessor;
import com.eerp.bos.bill.BillOperationContext;
import com.eerp.bos.bill.BillOperationResult;
import com.eerp.bos.list.AbstractListService;
import com.eerp.master.entity.SysMerchandiser;
import com.eerp.master.mapper.SysMerchandiserMapper;
import com.eerp.master.service.MerchandiserService;
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
class MerchandiserServiceTest {

    @Mock private BillDataAccessor billDataAccessor;
    @Mock private AbstractListService listService;
    @Mock private SysMerchandiserMapper sysMerchandiserMapper;

    @InjectMocks private MerchandiserService merchandiserService;

    private static final String BO_CODE = "MD_MERCHANDISER";
    private static final Long ID = 1001L;

    @Test
    @DisplayName("保存跟单员：委托 BillDataAccessor 返回ID")
    void testSave() {
        Map<String, Object> billData = new HashMap<>();
        billData.put("main", new HashMap<>());
        BillOperationContext ctx = BillOperationContext.builder()
                .boCode(BO_CODE).operation("save").billData(billData).userName("admin").build();
        when(billDataAccessor.saveBill(eq(BO_CODE), any())).thenReturn(ID);

        BillOperationResult result = merchandiserService.save(ctx);

        assertTrue(result.isSuccess());
        assertEquals(ID, result.getData());
        verify(billDataAccessor).saveBill(eq(BO_CODE), any());
    }

    @Test
    @DisplayName("保存跟单员数据为空时返回失败")
    void testSaveNullData() {
        BillOperationContext ctx = BillOperationContext.builder().boCode(BO_CODE).operation("save").build();
        BillOperationResult result = merchandiserService.save(ctx);
        assertFalse(result.isSuccess());
    }

    @Test
    @DisplayName("启用跟单员：更新enabled=1")
    void testEnable() {
        SysMerchandiser merchandiser = new SysMerchandiser();
        merchandiser.setId(ID);
        merchandiser.setEnabled(0);
        when(sysMerchandiserMapper.selectById(ID)).thenReturn(merchandiser);

        merchandiserService.enable(ID);

        assertEquals(1, merchandiser.getEnabled());
        verify(sysMerchandiserMapper).updateById(merchandiser);
    }

    @Test
    @DisplayName("查询跟单员详情：委托 BillDataAccessor")
    void testGetBillDetail() {
        Map<String, Object> detail = new HashMap<>();
        when(billDataAccessor.loadBill(BO_CODE, ID)).thenReturn(detail);

        Map<String, Object> result = merchandiserService.getBillDetail(BO_CODE, ID);

        assertSame(detail, result);
        verify(billDataAccessor).loadBill(BO_CODE, ID);
    }

    @Test
    @DisplayName("按ID查询跟单员：委托 Mapper")
    void testFindById() {
        SysMerchandiser merchandiser = new SysMerchandiser();
        merchandiser.setId(ID);
        when(sysMerchandiserMapper.selectById(ID)).thenReturn(merchandiser);

        SysMerchandiser result = merchandiserService.findById(ID);

        assertNotNull(result);
        assertEquals(ID, result.getId());
    }
}
