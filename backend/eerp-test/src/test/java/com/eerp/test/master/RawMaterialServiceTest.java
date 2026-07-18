package com.eerp.test.master;

import com.eerp.bos.bill.BillDataAccessor;
import com.eerp.bos.bill.BillOperationContext;
import com.eerp.bos.bill.BillOperationResult;
import com.eerp.bos.list.AbstractListService;
import com.eerp.master.entity.MdRawMaterial;
import com.eerp.master.mapper.MdRawMaterialMapper;
import com.eerp.master.service.RawMaterialService;
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
class RawMaterialServiceTest {

    @Mock private BillDataAccessor billDataAccessor;
    @Mock private AbstractListService listService;
    @Mock private MdRawMaterialMapper mdRawMaterialMapper;

    @InjectMocks private RawMaterialService rawMaterialService;

    private static final String BO_CODE = "MD_RAW_MATERIAL";
    private static final Long ID = 1001L;

    @Test
    @DisplayName("保存原料：委托 BillDataAccessor 返回ID")
    void testSave() {
        Map<String, Object> billData = new HashMap<>();
        billData.put("main", new HashMap<>());
        BillOperationContext ctx = BillOperationContext.builder()
                .boCode(BO_CODE).operation("save").billData(billData).userName("admin").build();
        when(billDataAccessor.saveBill(eq(BO_CODE), any())).thenReturn(ID);

        BillOperationResult result = rawMaterialService.save(ctx);

        assertTrue(result.isSuccess());
        assertEquals(ID, result.getData());
        verify(billDataAccessor).saveBill(eq(BO_CODE), any());
    }

    @Test
    @DisplayName("保存原料数据为空时返回失败")
    void testSaveNullData() {
        BillOperationContext ctx = BillOperationContext.builder().boCode(BO_CODE).operation("save").build();
        BillOperationResult result = rawMaterialService.save(ctx);
        assertFalse(result.isSuccess());
    }

    @Test
    @DisplayName("启用原料：更新enabled=1")
    void testEnable() {
        MdRawMaterial rawMaterial = new MdRawMaterial();
        rawMaterial.setId(ID);
        rawMaterial.setEnabled(0);
        when(mdRawMaterialMapper.selectById(ID)).thenReturn(rawMaterial);

        rawMaterialService.enable(ID);

        assertEquals(1, rawMaterial.getEnabled());
        verify(mdRawMaterialMapper).updateById(rawMaterial);
    }

    @Test
    @DisplayName("查询原料详情：委托 BillDataAccessor")
    void testGetBillDetail() {
        Map<String, Object> detail = new HashMap<>();
        when(billDataAccessor.loadBill(BO_CODE, ID)).thenReturn(detail);

        Map<String, Object> result = rawMaterialService.getBillDetail(BO_CODE, ID);

        assertSame(detail, result);
        verify(billDataAccessor).loadBill(BO_CODE, ID);
    }

    @Test
    @DisplayName("按ID查询原料：委托 Mapper")
    void testFindById() {
        MdRawMaterial rawMaterial = new MdRawMaterial();
        rawMaterial.setId(ID);
        when(mdRawMaterialMapper.selectById(ID)).thenReturn(rawMaterial);

        MdRawMaterial result = rawMaterialService.findById(ID);

        assertNotNull(result);
        assertEquals(ID, result.getId());
    }
}
