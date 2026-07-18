package com.eerp.bos.push;

import com.eerp.bos.bill.AbstractBillLinkService;
import com.eerp.bos.runtime.entity.BizBillLink;
import com.eerp.meta.push.entity.MetaPushRule;

import java.util.List;
import java.util.Map;

/**
 * 下推服务抽象基类（对齐设计文档 02 §3.7）。
 *
 * <p>职责：下推生成目标单 + 回写源单下游量 + 写 {@code biz_bill_link}。
 * 按 {@code meta_push_rule} 配置执行 {@code filter_expr} 过滤、{@code vp_check_expr}
 * 校验可下推量、{@code field_mapping_json} 字段映射、{@code pushed_field} 回写。</p>
 *
 * <h3>事务边界</h3>
 * <p>{@code push} 整事务，含目标单生成 + {@code biz_bill_link} 写入 + 源单 {@code pushed_field} 回写；
 * 任一环节失败回滚整事务（对齐设计文档 02 §3.7 + project_memory 硬约束）。</p>
 *
 * <h3>执行流程</h3>
 * <ol>
 *   <li>加载下推规则 {@link #loadRule}</li>
 *   <li>{@code filter_expr} 过滤源单行 {@link #filterSourceLines}</li>
 *   <li>逐行 {@code vp_check_expr} 校验可下推量 {@link #validatePushQty}（超额抛 ServiceException）</li>
 *   <li>{@code field_mapping_json} 字段映射生成目标单 {@link #mapToTarget}</li>
 *   <li>持久化目标单 {@link #saveTargetBill}</li>
 *   <li>写 {@code biz_bill_link} 关联记录（每个勾选行一条）</li>
 *   <li>回写源单 {@code pushed_field} {@link #writebackPushedField}</li>
 * </ol>
 */
public abstract class AbstractPushService {

    /** 单据关联服务（写 biz_bill_link） */
    protected AbstractBillLinkService billLinkService;

    /**
     * 下推入口。
     *
     * @param ctx 下推上下文
     * @return 下推结果
     */
    public abstract PushResult push(PushContext ctx);

    /**
     * 加载下推规则。
     *
     * @param ruleCode 规则编码
     * @return 下推规则；不存在返回 null
     */
    protected abstract MetaPushRule loadRule(String ruleCode);

    /**
     * 按下推规则过滤源单行。
     * <p>对 {@code ctx.lines} 应用 {@code filterExpr}，返回通过过滤的行。</p>
     *
     * @param ctx        下推上下文
     * @param rule       下推规则
     * @return 通过过滤的源单行数据列表（每行含完整字段）
     */
    protected abstract List<Map<String, Object>> filterSourceLines(PushContext ctx, MetaPushRule rule);

    /**
     * 校验单行可下推量。
     * <p>对单行应用 {@code vp_check_expr}，超额返回 false。</p>
     *
     * @param line      源单行数据
     * @param pushQty   本次下推量
     * @param rule      下推规则
     * @return true=通过 / false=超额
     */
    protected abstract boolean validatePushQty(Map<String, Object> line, java.math.BigDecimal pushQty, MetaPushRule rule);

    /**
     * 按 {@code field_mapping_json} 字段映射生成目标单数据。
     *
     * @param ctx        下推上下文
     * @param srcLines   源单行数据列表
     * @param rule       下推规则
     * @return 目标单数据（结构：{main: {...}, subs: {entity_code: [...]}}）
     */
    protected abstract Map<String, Object> mapToTarget(PushContext ctx, List<Map<String, Object>> srcLines, MetaPushRule rule);

    /**
     * 持久化目标单据（调用目标 bo 的 BillService.save）。
     *
     * @param ctx          下推上下文
     * @param targetBillData 目标单数据
     * @return 目标单ID
     */
    protected abstract Long saveTargetBill(PushContext ctx, Map<String, Object> targetBillData);

    /**
     * 回写源单 {@code pushed_field}（累加本次下推量）。
     *
     * @param ctx      下推上下文
     * @param srcLines 源单行数据列表
     * @param rule     下推规则
     */
    protected abstract void writebackPushedField(PushContext ctx, List<Map<String, Object>> srcLines, MetaPushRule rule);

    /**
     * 创建单据关联记录（默认实现，子类可覆盖）。
     */
    protected void createBillLink(BizBillLink link) {
        if (billLinkService != null) {
            billLinkService.create(link);
        }
    }

    /** 设置单据关联服务（用于注入） */
    public void setBillLinkService(AbstractBillLinkService billLinkService) {
        this.billLinkService = billLinkService;
    }
}
