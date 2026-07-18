package com.eerp.bos.bill;

import com.eerp.bos.list.AbstractListService;
import com.eerp.bos.operation.service.GenericOperationService;
import com.eerp.bos.operation.service.OperationContext;
import com.eerp.bos.operation.service.OperationResult;
import com.eerp.common.api.PageRequest;
import com.eerp.common.api.PageResult;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;

/**
 * 通用单据服务（兼容入口，对齐设计文档 02 §3.5）。
 *
 * <p>Phase 2（A5）后改为委托 {@link GenericOperationService} 执行 6 阶段流水线，
 * 保留 save/operate/getBillDetail/listBills/deleteBill 方法签名以兼容现有 Controller 与测试。</p>
 *
 * <p>{@link #save} / {@link #operate} 内部转发到
 * {@link GenericOperationService#executeOperation}；
 * {@link #getBillDetail} / {@link #listBills} / {@link #deleteBill} 直接委托
 * {@link BillDataAccessor} / {@link AbstractListService}。</p>
 */
@Service
public class GenericBillService extends AbstractBillService {

    @Autowired
    private GenericOperationService genericOperationService;

    @Autowired
    private BillDataAccessor billDataAccessor;

    @Autowired
    private AbstractListService listService;

    @Override
    public BillOperationResult save(BillOperationContext ctx) {
        if (ctx.getBillData() == null) {
            return BillOperationResult.fail("单据数据为空");
        }

        OperationContext opCtx = toOperationContext(ctx);
        OperationResult result = genericOperationService.executeOperation(opCtx);
        return toBillResult(result);
    }

    @Override
    public BillOperationResult operate(BillOperationContext ctx) {
        if (ctx.getBillId() == null && !"save".equals(ctx.getOperation())
                && !"draft".equals(ctx.getOperation())) {
            return BillOperationResult.fail("单据ID为空，无法执行操作");
        }

        OperationContext opCtx = toOperationContext(ctx);
        OperationResult result = genericOperationService.executeOperation(opCtx);
        return toBillResult(result);
    }

    @Override
    public Map<String, Object> getBillDetail(String boCode, Long billId) {
        return billDataAccessor.loadBill(boCode, billId);
    }

    @Override
    public PageResult<Map<String, Object>> listBills(String boCode, PageRequest pageRequest, Map<String, Object> queryParams) {
        return listService.page(boCode, pageRequest, queryParams);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void deleteBill(String boCode, Long billId) {
        billDataAccessor.deleteBill(boCode, billId);
    }

    // ---------------- 内部转换方法 ----------------

    /** BillOperationContext → OperationContext */
    private OperationContext toOperationContext(BillOperationContext ctx) {
        return OperationContext.builder()
                .boCode(ctx.getBoCode())
                .billId(ctx.getBillId())
                .operation(ctx.getOperation())
                .billData(ctx.getBillData())
                .userId(ctx.getUserId())
                .userName(ctx.getUserName())
                .reason(ctx.getReason())
                .build();
    }

    /** OperationResult → BillOperationResult */
    private BillOperationResult toBillResult(OperationResult result) {
        if (result.isSuccess()) {
            if (result.getBillId() != null) {
                return BillOperationResult.ok(result.getBillId());
            }
            return BillOperationResult.ok();
        }
        return BillOperationResult.fail(result.getMessage());
    }
}
