package com.eerp.bos.print;

/**
 * 打印渲染器工厂（对齐设计文档 02 §3.8 / 工厂模式）。
 *
 * <p>按 {@link PrintCellType} 选择渲染策略。当前为简化实现，
 * 内置 TEXT/FIELD/FORMULA 三种渲染逻辑；IMAGE/BARCODE 走 TEXT 兜底。</p>
 */
public class PrintRendererFactory {

    /**
     * 渲染单个单元格。
     *
     * @param cellType   单元格类型
     * @param content    单元格内容（静态文本/公式表达式）
     * @param fieldCode  字段编码（FIELD 类型使用）
     * @param entityCode 实体编码（FIELD 类型使用，main/detail 等）
     * @param ctx        渲染上下文
     * @param service    父打印服务（用于调 evalFormula/evalField）
     * @return 渲染后字符串
     */
    public String renderCell(PrintCellType cellType, String content, String fieldCode,
                             String entityCode, PrintContext ctx, AbstractPrintTemplateService service) {
        if (cellType == null) {
            return content == null ? "" : content;
        }
        switch (cellType) {
            case FIELD:
                return service.evalField(entityCode, fieldCode, ctx);
            case FORMULA:
                return service.evalFormula(content, ctx);
            case TEXT:
            case IMAGE:
            case BARCODE:
            default:
                return content == null ? "" : content;
        }
    }
}
