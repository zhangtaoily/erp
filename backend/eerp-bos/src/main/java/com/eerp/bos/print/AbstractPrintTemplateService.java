package com.eerp.bos.print;

import com.eerp.meta.print.entity.MetaPrintTemplate;
import com.eerp.common.service.AbstractCrudService;
import com.eerp.meta.print.mapper.MetaPrintTemplateMapper;

import java.util.List;

/**
 * 打印模板服务抽象基类（对齐设计文档 02 §3.8）。
 *
 * <p>职责：类 Excel 模板 CRUD + 渲染。按 {@code row_bands}（title/header/detail/summary）
 * 渲染行带，{@code detail} 行带按 {@code expand}（none/vertical/horizontal）扩展，
 * {@code cell_type=formula} 按 {@code content} 求值，{@code merges_json} 按左上角
 * {@code rowspan}/{@code colspan} 合并。</p>
 *
 * <h3>渲染流程</h3>
 * <ol>
 *   <li>加载模板 + 加载单据数据</li>
 *   <li>title/header/summary 静态渲染一次</li>
 *   <li>detail 行带按 {@code expand=vertical} 向下扩展多行（按子表行数）</li>
 *   <li>字段单元格按 {@code entity_code}+{@code field_code} 取值</li>
 *   <li>公式单元格按 {@code content} 求值</li>
 *   <li>合并单元格按 {@code rowspan}/{@code colspan} 合并</li>
 *   <li>输出渲染结果字节流</li>
 * </ol>
 */
public abstract class AbstractPrintTemplateService extends AbstractCrudService<MetaPrintTemplateMapper, MetaPrintTemplate> {

    /**
     * 按业务对象编码查询启用的模板列表。
     */
    public abstract List<MetaPrintTemplate> listByBoCode(String boCode);

    /**
     * 获取业务对象的默认模板（is_default=1）。
     */
    public abstract MetaPrintTemplate getDefault(String boCode);

    /**
     * 加载模板（子类可覆盖以支持测试 mock）。
     * 默认委托 MyBatis-Plus {@code getById}。
     */
    protected MetaPrintTemplate loadTemplate(Long templateId) {
        return getById(templateId);
    }

    /**
     * 渲染单据（输出字节流）。
     *
     * @param templateId 模板ID
     * @param billId     单据ID
     * @return 渲染结果字节流（HTML/文本/PDF，由子类决定）
     */
    public abstract byte[] render(Long templateId, Long billId);

    /**
     * 套打批量渲染（对齐 F2.6.7）。
     *
     * @param templateId 模板ID
     * @param billIds    单据ID列表
     * @return 渲染结果字节流
     */
    public abstract byte[] renderBatch(Long templateId, List<Long> billIds);

    /**
     * 渲染行带（子类实现具体渲染逻辑）。
     *
     * @param tpl  打印模板
     * @param band 行带类型：title/header/detail/summary
     * @param ctx  渲染上下文
     */
    protected abstract void renderRowBand(MetaPrintTemplate tpl, String band, PrintContext ctx);

    /**
     * 求公式表达式（如 =SUM(detail.qty) / =AVG(detail.amount)）。
     *
     * @param formula 公式表达式（可带前导 =）
     * @param ctx     渲染上下文
     * @return 求值结果字符串
     */
    protected abstract String evalFormula(String formula, PrintContext ctx);

    /**
     * 取字段值（按 entity_code + field_code）。
     *
     * @param entityCode 实体编码（main/detail 等）
     * @param fieldCode  字段编码
     * @param ctx        渲染上下文
     * @return 字段值字符串
     */
    protected abstract String evalField(String entityCode, String fieldCode, PrintContext ctx);
}
