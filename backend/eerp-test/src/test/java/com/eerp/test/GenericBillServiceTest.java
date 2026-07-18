package com.eerp.test;

import com.eerp.bos.bill.BillDataAccessor;
import com.eerp.bos.bill.BillOperationContext;
import com.eerp.bos.bill.BillOperationResult;
import com.eerp.bos.bill.GenericBillService;
import com.eerp.bos.list.AbstractListService;
import com.eerp.bos.operation.service.GenericOperationService;
import com.eerp.bos.operation.service.OperationContext;
import com.eerp.bos.operation.service.OperationResult;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.HashMap;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * 通用单据服务单元测试（A5 后版本，mock GenericOperationService 而非底层组件）。
 *
 * <p>验证 {@link GenericBillService} 作为兼容入口正确委托
 * {@link GenericOperationService#executeOperation}，并保持 getBillDetail/listBills 直接委托。</p>
 */
@ExtendWith(MockitoExtension.class)
class GenericBillServiceTest {

    @Mock
    private GenericOperationService genericOperationService;

    @Mock
    private BillDataAccessor billDataAccessor;

    @Mock
    private AbstractListService listService;

    @InjectMocks
    private GenericBillService genericBillService;

    private static final String BO_CODE = "SAL_ORDER";
    private static final Long BILL_ID = 1001L;

    @Test
    @DisplayName("保存新单据：委托 GenericOperationService，返回单据ID")
    void testSaveNewBill() {
        Map<String, Object> billData = new HashMap<>();
        billData.put("main", new HashMap<String, Object>());

        BillOperationContext ctx = BillOperationContext.builder()
                .boCode(BO_CODE)
                .operation("save")
                .billData(billData)
                .userName("admin")
                .build();

        when(genericOperationService.executeOperation(any(OperationContext.class)))
                .thenReturn(OperationResult.ok(BILL_ID));

        BillOperationResult result = genericBillService.save(ctx);

        assertTrue(result.isSuccess(), "保存应成功");
        assertEquals(BILL_ID, result.getData(), "返回的单据ID应一致");
        verify(genericOperationService).executeOperation(any(OperationContext.class));
    }

    @Test
    @DisplayName("保存单据数据为空时返回失败")
    void testSaveNullBillData() {
        BillOperationContext ctx = BillOperationContext.builder()
                .boCode(BO_CODE)
                .operation("save")
                .billData(null)
                .build();

        BillOperationResult result = genericBillService.save(ctx);

        assertFalse(result.isSuccess(), "数据为空应返回失败");
        assertTrue(result.getMessage().contains("空"), "失败信息应提示数据为空");
    }

    @Test
    @DisplayName("提交操作：委托 GenericOperationService，操作成功")
    void testOperateSubmit() {
        BillOperationContext ctx = BillOperationContext.builder()
                .boCode(BO_CODE)
                .billId(BILL_ID)
                .operation("submit")
                .userName("admin")
                .build();

        when(genericOperationService.executeOperation(any(OperationContext.class)))
                .thenReturn(OperationResult.ok(BILL_ID, "操作[提交]校验通过"));

        BillOperationResult result = genericBillService.operate(ctx);

        assertTrue(result.isSuccess(), "提交应成功");
        verify(genericOperationService).executeOperation(any(OperationContext.class));
    }

    @Test
    @DisplayName("非法状态操作：GenericOperationService 返回失败")
    void testOperateInvalidState() {
        BillOperationContext ctx = BillOperationContext.builder()
                .boCode(BO_CODE)
                .billId(BILL_ID)
                .operation("audit")
                .userName("admin")
                .build();

        when(genericOperationService.executeOperation(any(OperationContext.class)))
                .thenReturn(OperationResult.fail("当前状态不允许审核"));

        BillOperationResult result = genericBillService.operate(ctx);

        assertFalse(result.isSuccess(), "非法状态应返回失败");
        assertEquals("当前状态不允许审核", result.getMessage());
    }

    @Test
    @DisplayName("操作时单据ID为空返回失败")
    void testOperateNullBillId() {
        BillOperationContext ctx = BillOperationContext.builder()
                .boCode(BO_CODE)
                .billId(null)
                .operation("submit")
                .build();

        BillOperationResult result = genericBillService.operate(ctx);

        assertFalse(result.isSuccess(), "单据ID为空应返回失败");
        assertTrue(result.getMessage().contains("ID为空"));
    }

    @Test
    @DisplayName("删除操作委托 GenericOperationService")
    void testOperateDelete() {
        BillOperationContext ctx = BillOperationContext.builder()
                .boCode(BO_CODE)
                .billId(BILL_ID)
                .operation("delete")
                .reason("作废删除")
                .userName("admin")
                .build();

        when(genericOperationService.executeOperation(any(OperationContext.class)))
                .thenReturn(OperationResult.ok("删除成功"));

        BillOperationResult result = genericBillService.operate(ctx);

        assertTrue(result.isSuccess(), "删除应成功");
        verify(genericOperationService).executeOperation(any(OperationContext.class));
    }

    @Test
    @DisplayName("getBillDetail委托billDataAccessor加载单据")
    void testGetBillDetail() {
        Map<String, Object> detail = new HashMap<>();
        Map<String, Object> main = new HashMap<>();
        main.put("id", BILL_ID);
        main.put("code", "SO001");
        detail.put("main", main);
        when(billDataAccessor.loadBill(BO_CODE, BILL_ID)).thenReturn(detail);

        Map<String, Object> result = genericBillService.getBillDetail(BO_CODE, BILL_ID);

        assertNotNull(result);
        assertEquals(BILL_ID, ((Map<?, ?>) result.get("main")).get("id"));
        verify(billDataAccessor).loadBill(BO_CODE, BILL_ID);
    }
}
