package com.eerp.bos.bill;

import com.eerp.common.service.AbstractCrudService;
import com.eerp.bos.runtime.entity.BizBillLink;
import com.eerp.bos.runtime.entity.BizBillLinkMapper;

import java.util.List;

/**
 * 单据关联追溯服务抽象基类（对齐设计文档 02 §3.6）。
 *
 * <p>职责：{@code biz_bill_link} CRUD + 联查追溯树构建。下推时由
 * {@code AbstractPushService} 调用 {@link #create} 写入关联记录；
 * 联查时由前端 {@code BillTraceTree} 调用 {@link #buildTraceTree} 递归构建上下游树。</p>
 *
 * <p>追溯树构建约束（对齐 F2.4.2）：</p>
 * <ul>
 *   <li>默认 {@code maxDepth=5} 防止无限递归</li>
 *   <li>{@code visited} Set 按 {@code boCode + billId} 去重防环</li>
 *   <li>超过深度标记 {@code depth>=maxDepth} 节点为「深度上限」</li>
 * </ul>
 */
public abstract class AbstractBillLinkService extends AbstractCrudService<BizBillLinkMapper, BizBillLink> {

    /** 默认最大追溯深度（防无限递归） */
    public static final int DEFAULT_MAX_DEPTH = 5;

    /**
     * 创建单据关联记录（下推时调用）。
     */
    public BizBillLink create(BizBillLink link) {
        save(link);
        return link;
    }

    /**
     * 按源单查询下游关联（下查）。
     */
    public abstract List<BizBillLink> listBySrc(String srcBoCode, Long srcBillId);

    /**
     * 按目标单查询上游关联（上查）。
     */
    public abstract List<BizBillLink> listByTgt(String tgtBoCode, Long tgtBillId);

    /**
     * 递归构建追溯树（默认深度 5）。
     *
     * @param boCode    起始单据业务对象编码
     * @param billId    起始单据ID
     * @param direction 方向：up=上查（追溯源单）/ down=下查（追溯目标单）
     * @return 追溯树根节点
     */
    public TraceTree buildTraceTree(String boCode, Long billId, String direction) {
        return buildTraceTree(boCode, billId, direction, DEFAULT_MAX_DEPTH);
    }

    /**
     * 递归构建追溯树（指定最大深度）。
     *
     * @param boCode    起始单据业务对象编码
     * @param billId    起始单据ID
     * @param direction 方向：up=上查 / down=下查
     * @param maxDepth  最大深度（防无限递归）
     * @return 追溯树根节点
     */
    public abstract TraceTree buildTraceTree(String boCode, Long billId, String direction, int maxDepth);
}
