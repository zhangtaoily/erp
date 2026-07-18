package com.eerp.test.master;

import com.eerp.bos.bill.BillDataAccessor;
import com.eerp.bos.bill.BillOperationContext;
import com.eerp.bos.bill.BillOperationResult;
import com.eerp.bos.list.AbstractListService;
import com.eerp.master.entity.MdWarehouse;
import com.eerp.master.mapper.MdWarehouseMapper;
import com.eerp.master.service.WarehouseService;
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
class WarehouseServiceTest {

    @Mock private BillDataAccessor billDataAccessor;
    @Mock private AbstractListService listService;
    @Mock private MdWarehouseMapper mdWarehouseMapper;

    @InjectMocks private WarehouseService warehouseService;

    private static final String BO_CODE = "MD_WAREHOUSE";
    private static final Long ID = 1001L;

    @Test
    @DisplayName("保存仓库：委托 BillDataAccessor 返回ID")
    void testSave() {
        Map<String, Object> billData = new HashMap<>();
        billData.put("main", new HashMap<>());
        BillOperationContext ctx = BillOperationContext.builder()
                .boCode(BO_CODE).operation("save").billData(billData).userName("admin").build();
        when(billDataAccessor.saveBill(eq(BO_CODE), any())).thenReturn(ID);

        BillOperationResult result = warehouseService.save(ctx);

        assertTrue(result.isSuccess());
        assertEquals(ID, result.getData());
        verify(billDataAccessor).saveBill(eq(BO_CODE), any());
    }

    @Test
    @DisplayName("保存仓库数据为空时返回失败")
    void testSaveNullData() {
        BillOperationContext ctx = BillOperationContext.builder().boCode(BO_CODE).operation("save").build();
        BillOperationResult result = warehouseService.save(ctx);
        assertFalse(result.isSuccess());
    }

    @Test
    @DisplayName("启用仓库：更新status=1")
    void testEnable() {
        MdWarehouse warehouse = new MdWarehouse();
        warehouse.setId(ID);
        warehouse.setStatus(0);
        when(mdWarehouseMapper.selectById(ID)).thenReturn(warehouse);

        warehouseService.enable(ID);

        assertEquals(1, warehouse.getStatus());
        verify(mdWarehouseMapper).updateById(warehouse);
    }

    @Test
    @DisplayName("查询仓库详情：委托 BillDataAccessor")
    void testGetBillDetail() {
        Map<String, Object> detail = new HashMap<>();
        when(billDataAccessor.loadBill(BO_CODE, ID)).thenReturn(detail);

        Map<String, Object> result = warehouseService.getBillDetail(BO_CODE, ID);

        assertSame(detail, result);
        verify(billDataAccessor).loadBill(BO_CODE, ID);
    }

    @Test
    @DisplayName("按ID查询仓库：委托 Mapper")
    void testFindById() {
        MdWarehouse warehouse = new MdWarehouse();
        warehouse.setId(ID);
        when(mdWarehouseMapper.selectById(ID)).thenReturn(warehouse);

        MdWarehouse result = warehouseService.findById(ID);

        assertNotNull(result);
        assertEquals(ID, result.getId());
    }
}
