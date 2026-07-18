package com.eerp.master.service;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;

/**
 * 客户信用额度查询契约（对齐设计文档 06 §3.3）。
 *
 * <p>被销售管理（SAL_ORDER/SAL_OUT_STOCK）引用，提供统一的信用额度查询口径。</p>
 *
 * <p>信用管理支持两种模式：</p>
 * <ul>
 *   <li>单组织授信：每个客户在单个组织下有独立额度（md_credit.is_group_credit=0）</li>
 *   <li>集团授信：客户在集团层面共享额度（md_credit.is_group_credit=1，cust_type=1）</li>
 * </ul>
 */
public abstract class AbstractCreditQueryService {

    /**
     * 查询客户信用余额（单组织维度）。
     *
     * @param custId 客户ID
     * @return 信用余额信息 {creditLimit, usedAmount, balance, validTime, creditStatus}
     */
    public abstract Map<String, Object> getCreditBalance(Long custId);

    /**
     * 查询集团客户信用余额（集团维度聚合）。
     *
     * @param groupCustId 集团客户ID
     * @return 集团信用余额信息
     */
    public abstract Map<String, Object> getGroupCreditBalance(Long groupCustId);

    /**
     * 检查信用额度是否充足。
     *
     * @param custId 客户ID
     * @param amount 本次占用金额
     * @return true=可用，false=超额
     */
    public abstract boolean checkCreditAvailable(Long custId, BigDecimal amount);

    /**
     * 列出客户的信用明细（含额度和使用情况）。
     *
     * @param custId 客户ID
     * @return 信用明细列表
     */
    public abstract List<Map<String, Object>> listCreditDetails(Long custId);

    /**
     * 占用信用额度（销售出库审核时调用）。
     *
     * @param custId 客户ID
     * @param amount 占用金额
     * @param billId 关联单据ID
     */
    public abstract void occupyCredit(Long custId, BigDecimal amount, Long billId);

    /**
     * 释放信用额度（销售退货/取消时调用）。
     *
     * @param custId 客户ID
     * @param amount 释放金额
     * @param billId 关联单据ID
     */
    public abstract void releaseCredit(Long custId, BigDecimal amount, Long billId);
}
