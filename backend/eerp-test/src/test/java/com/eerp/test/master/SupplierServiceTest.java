package com.eerp.test.master;

import com.eerp.bos.bill.BillDataAccessor;
import com.eerp.bos.bill.BillOperationContext;
import com.eerp.bos.bill.BillOperationResult;
import com.eerp.bos.list.AbstractListService;
import com.eerp.master.entity.MdSupplier;
import com.eerp.master.mapper.MdSupplierMapper;
import com.eerp.master.service.SupplierService;
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
class SupplierServiceTest {

    @Mock private BillDataAccessor billDataAccessor;
    @Mock private AbstractListService listService;
    @Mock private MdSupplierMapper mdSupplierMapper;

    @InjectMocks private SupplierService supplierService;

    private static final String BO_CODE = "MD_SUPPLIER";
    private static final Long ID = 1001L;

    @Test
    @DisplayName("保存供应商：委托 BillDataAccessor 返回ID")
    void testSave() {
        Map<String, Object> billData = new HashMap<>();
        billData.put("main", new HashMap<>());
        BillOperationContext ctx = BillOperationContext.builder()
                .boCode(BO_CODE).operation("save").billData(billData).userName("admin").build();
        when(billDataAccessor.saveBill(eq(BO_CODE), any())).thenReturn(ID);

        BillOperationResult result = supplierService.save(ctx);

        assertTrue(result.isSuccess());
        assertEquals(ID, result.getData());
        verify(billDataAccessor).saveBill(eq(BO_CODE), any());
    }

    @Test
    @DisplayName("保存供应商数据为空时返回失败")
    void testSaveNullData() {
        BillOperationContext ctx = BillOperationContext.builder().boCode(BO_CODE).operation("save").build();
        BillOperationResult result = supplierService.save(ctx);
        assertFalse(result.isSuccess());
    }

    @Test
    @DisplayName("启用供应商：更新status=1")
    void testEnable() {
        MdSupplier supplier = new MdSupplier();
        supplier.setId(ID);
        supplier.setStatus(0);
        when(mdSupplierMapper.selectById(ID)).thenReturn(supplier);

        supplierService.enable(ID);

        assertEquals(1, supplier.getStatus());
        verify(mdSupplierMapper).updateById(supplier);
    }

    @Test
    @DisplayName("查询供应商详情：委托 BillDataAccessor")
    void testGetBillDetail() {
        Map<String, Object> detail = new HashMap<>();
        when(billDataAccessor.loadBill(BO_CODE, ID)).thenReturn(detail);

        Map<String, Object> result = supplierService.getBillDetail(BO_CODE, ID);

        assertSame(detail, result);
        verify(billDataAccessor).loadBill(BO_CODE, ID);
    }

    @Test
    @DisplayName("按ID查询供应商：委托 Mapper")
    void testFindById() {
        MdSupplier supplier = new MdSupplier();
        supplier.setId(ID);
        when(mdSupplierMapper.selectById(ID)).thenReturn(supplier);

        MdSupplier result = supplierService.findById(ID);

        assertNotNull(result);
        assertEquals(ID, result.getId());
    }
}
