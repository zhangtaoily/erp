package com.eerp.bos.bill;

import lombok.Data;

import java.util.ArrayList;
import java.util.List;

/**
 * 单据追溯树节点（对齐设计文档 02 §3.6）。
 *
 * <p>由 {@link AbstractBillLinkService#buildTraceTree} 递归构建。
 * 支持上查（向上追溯源单）与下查（向下追溯目标单）两个方向。</p>
 */
@Data
public class TraceTree {

    /** 节点业务对象编码 */
    private String boCode;

    /** 节点单据ID */
    private Long billId;

    /** 节点单据编号（展示用，可空） */
    private String billCode;

    /** 节点单据名称（展示用，可空） */
    private String billName;

    /** 当前层级（根节点=0） */
    private int depth;

    /** 是否到达深度上限（depth>=maxDepth 时为 true） */
    private boolean depthLimitReached;

    /** 关联规则编码（根节点为 null） */
    private String pushRuleCode;

    /** 关联数量（根节点为 null） */
    private java.math.BigDecimal linkQty;

    /** 子节点列表 */
    private List<TraceTree> children = new ArrayList<>();

    /** 添加子节点 */
    public void addChild(TraceTree child) {
        if (children == null) {
            children = new ArrayList<>();
        }
        children.add(child);
    }
}
