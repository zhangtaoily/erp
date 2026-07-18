package com.eerp.bos.bill;

import com.eerp.common.api.PageRequest;
import com.eerp.common.api.PageResult;

import java.util.Map;

/**
 * 单据操作服务抽象基类，定义单据操作模板
 */
public abstract class AbstractBillService {

    /** 保存（新增/更新） */
    public abstract BillOperationResult save(BillOperationContext ctx);

    /** 状态流转操作（submit/audit/reject/revoke/close/cancel/delete） */
    public abstract BillOperationResult operate(BillOperationContext ctx);

    /** 获取单据明细（主表 + 子表 + 孙表） */
    public abstract Map<String, Object> getBillDetail(String boCode, Long billId);

    /** 分页查询单据列表 */
    public abstract PageResult<Map<String, Object>> listBills(String boCode, PageRequest pageRequest, Map<String, Object> queryParams);

    /** 删除单据 */
    public abstract void deleteBill(String boCode, Long billId);
}
