package com.eerp.bos.print;

import com.eerp.bos.bill.BillDataAccessor;
import com.eerp.meta.print.entity.MetaPrintTemplate;
import com.eerp.meta.print.service.MetaPrintTemplateService;
import com.eerp.meta.rule.expr.ExprContext;
import com.eerp.meta.rule.expr.ExprEvaluator;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 打印模板服务实现（@Service，对齐设计文档 02 §3.8）。
 *
 * <p>依赖：
 * <ul>
 *   <li>{@link MetaPrintTemplateService}：模板 CRUD</li>
 *   <li>{@link BillDataAccessor}：加载单据数据</li>
 *   <li>{@link ExprEvaluator}：公式求值（=SUM / =AVG 等）</li>
 *   <li>{@link PrintRendererFactory}：按 cell_type 选择渲染策略</li>
 * </ul>
 * </p>
 *
 * <p>渲染输出：简化实现输出 HTML 字节流（UTF-8）。完整 PDF 渲染需引入 iText/PDFBox，
 * 当前实现为 MVP 占位，{@link #render} 返回 HTML 字节流供前端预览或浏览器打印。</p>
 *
 * <p>模板 JSON 结构约定：</p>
 * <ul>
 *   <li>{@code cells_json}：{@code Map<"r_c", {content, cell_type, field_code, entity_code, expand, style}>}</li>
 *   <li>{@code merges_json}：{@code Map<"r_c", {rowspan, colspan}>}</li>
 *   <li>{@code row_bands_json}：{@code List<{band, row}>}（band=title/header/detail/summary）</li>
 * </ul>
 */
@Service
public class PrintTemplateServiceImpl extends AbstractPrintTemplateService {

    private static final Logger log = LoggerFactory.getLogger(PrintTemplateServiceImpl.class);
    private static final ObjectMapper MAPPER = new ObjectMapper();

    @Autowired
    private MetaPrintTemplateService metaPrintTemplateService;

    @Autowired
    private BillDataAccessor billDataAccessor;

    @Autowired
    private ExprEvaluator exprEvaluator;

    private final PrintRendererFactory rendererFactory = new PrintRendererFactory();

    // ==================== CRUD 委托 ====================

    @Override
    public List<MetaPrintTemplate> listByBoCode(String boCode) {
        return metaPrintTemplateService.listByBoCode(boCode);
    }

    @Override
    public MetaPrintTemplate getDefault(String boCode) {
        return metaPrintTemplateService.getDefault(boCode);
    }

    // ==================== 渲染入口 ====================

    @Override
    public byte[] render(Long templateId, Long billId) {
        if (templateId == null || billId == null) {
            return new byte[0];
        }
        MetaPrintTemplate tpl = loadTemplate(templateId);
        if (tpl == null) {
            return new byte[0];
        }
        PrintContext ctx = buildContext(tpl.getBoCode(), billId);
        if (ctx == null) {
            return new byte[0];
        }
        return renderHtml(tpl, ctx).getBytes(StandardCharsets.UTF_8);
    }

    @Override
    public byte[] renderBatch(Long templateId, List<Long> billIds) {
        if (templateId == null || billIds == null || billIds.isEmpty()) {
            return new byte[0];
        }
        MetaPrintTemplate tpl = loadTemplate(templateId);
        if (tpl == null) {
            return new byte[0];
        }
        StringBuilder html = new StringBuilder();
        html.append("<html><head><meta charset='UTF-8'></head><body>");
        for (Long billId : billIds) {
            PrintContext ctx = buildContext(tpl.getBoCode(), billId);
            if (ctx != null) {
                html.append(renderHtml(tpl, ctx));
                html.append("<div style='page-break-after:always;'></div>");
            }
        }
        html.append("</body></html>");
        return html.toString().getBytes(StandardCharsets.UTF_8);
    }

    // ==================== 抽象钩子实现 ====================

    @Override
    protected void renderRowBand(MetaPrintTemplate tpl, String band, PrintContext ctx) {
        // 由 renderHtml 驱动，此处为钩子占位（子类可覆盖以扩展）
    }

    @Override
    protected String evalFormula(String formula, PrintContext ctx) {
        if (formula == null || formula.trim().isEmpty()) {
            return "";
        }
        String expr = formula.trim();
        if (expr.startsWith("=")) {
            expr = expr.substring(1);
        }
        // 构造 ExprContext：variables 含 detail 子表行数据
        ExprContext exprCtx = buildExprContext(ctx);
        try {
            Object result = exprEvaluator.evaluate(expr, exprCtx);
            return result == null ? "" : String.valueOf(result);
        } catch (Exception e) {
            log.warn("公式求值失败: {} | {}", formula, e.getMessage());
            return "";
        }
    }

    @Override
    protected String evalField(String entityCode, String fieldCode, PrintContext ctx) {
        if (fieldCode == null || fieldCode.isEmpty()) {
            return "";
        }
        String path = (entityCode == null || entityCode.isEmpty()) ? fieldCode : entityCode + "." + fieldCode;
        Object value = ctx.getFieldValue(path);
        return value == null ? "" : String.valueOf(value);
    }

    // ==================== 内部渲染逻辑 ====================

    @SuppressWarnings("unchecked")
    private PrintContext buildContext(String boCode, Long billId) {
        Map<String, Object> bill = billDataAccessor.loadBill(boCode, billId);
        if (bill == null || bill.isEmpty()) {
            return null;
        }
        PrintContext ctx = new PrintContext();
        ctx.setBoCode(boCode);
        ctx.setBillId(billId);
        Map<String, Object> main = (Map<String, Object>) bill.getOrDefault("main", new HashMap<>());
        ctx.setMainData(main);
        Object billCode = main.get("code");
        if (billCode != null) {
            ctx.setBillCode(String.valueOf(billCode));
        }
        Map<String, List<Map<String, Object>>> subs = (Map<String, List<Map<String, Object>>>)
                bill.getOrDefault("subs", new HashMap<>());
        ctx.setSubData(subs);
        return ctx;
    }

    private ExprContext buildExprContext(PrintContext ctx) {
        ExprContext exprCtx = new ExprContext(ctx.getMainData(), ctx.getSubData());
        // 注入当前行到 variables（detail.field 取值）
        if (ctx.getCurrentRow() != null) {
            exprCtx.setVariable("detail", ctx.getCurrentRow());
        }
        return exprCtx;
    }

    @SuppressWarnings("unchecked")
    private String renderHtml(MetaPrintTemplate tpl, PrintContext ctx) {
        Map<String, Map<String, Object>> cells = parseJson(tpl.getCellsJson(), new TypeReference<>() {});
        Map<String, Map<String, Object>> merges = parseJson(tpl.getMergesJson(), new TypeReference<>() {});
        List<Map<String, Object>> rowBands = parseJson(tpl.getRowBandsJson(), new TypeReference<>() {});

        int rowCount = tpl.getRowCount() == null ? 0 : tpl.getRowCount();
        int colCount = tpl.getColCount() == null ? 0 : tpl.getColCount();

        // 确定明细行展开行数（取子表最大行数）
        int detailExpandRows = countMaxSubRows(ctx);

        StringBuilder html = new StringBuilder();
        html.append("<html><head><meta charset='UTF-8'><title>")
                .append(escapeHtml(tpl.getTemplateName()))
                .append("</title><style>")
                .append("table{border-collapse:collapse;width:100%;}")
                .append("td,th{border:1px solid #333;padding:4px;font-size:12px;}")
                .append("</style></head><body>");
        html.append("<table>");

        // 渲染每行
        int currentDetailIndex = 0;
        for (int r = 0; r < rowCount; r++) {
            String band = resolveBand(rowBands, r);
            if ("detail".equalsIgnoreCase(band) && detailExpandRows > 0) {
                // 明细行扩展：每个子表行渲染一次
                for (int i = 0; i < detailExpandRows; i++) {
                    ctx.setCurrentRowIndex(i);
                    List<Map<String, Object>> firstSubRows = firstSubRows(ctx);
                    if (firstSubRows != null && i < firstSubRows.size()) {
                        ctx.setCurrentRow(firstSubRows.get(i));
                    }
                    renderRow(html, cells, merges, r, colCount, ctx);
                    renderRowBand(tpl, band, ctx);
                }
                currentDetailIndex++;
                // 跳过原始 detail 行（已被展开行替代）
                continue;
            }
            ctx.setCurrentRowIndex(-1);
            ctx.setCurrentRow(null);
            renderRow(html, cells, merges, r, colCount, ctx);
            renderRowBand(tpl, band, ctx);
        }

        html.append("</table></body></html>");
        return html.toString();
    }

    private void renderRow(StringBuilder html, Map<String, Map<String, Object>> cells,
                           Map<String, Map<String, Object>> merges,
                           int row, int colCount, PrintContext ctx) {
        html.append("<tr>");
        for (int c = 0; c < colCount; c++) {
            String key = row + "_" + c;
            // 合并单元格的从属位置跳过
            if (isMergedSlave(merges, row, c)) {
                continue;
            }
            Map<String, Object> mergeInfo = merges == null ? null : merges.get(key);
            String colspan = "";
            String rowspan = "";
            if (mergeInfo != null) {
                Object cs = mergeInfo.get("colspan");
                Object rs = mergeInfo.get("rowspan");
                if (cs != null && Integer.parseInt(cs.toString()) > 1) {
                    colspan = " colspan='" + cs + "'";
                }
                if (rs != null && Integer.parseInt(rs.toString()) > 1) {
                    rowspan = " rowspan='" + rs + "'";
                }
            }
            Map<String, Object> cell = cells == null ? null : cells.get(key);
            String content = renderCell(cell, ctx);
            html.append("<td").append(colspan).append(rowspan).append(">")
                    .append(content)
                    .append("</td>");
        }
        html.append("</tr>");
    }

    private String renderCell(Map<String, Object> cell, PrintContext ctx) {
        if (cell == null) {
            return "";
        }
        String cellTypeStr = cell.get("cell_type") == null ? "text" : String.valueOf(cell.get("cell_type"));
        PrintCellType cellType = PrintCellType.fromCode(cellTypeStr);
        String content = cell.get("content") == null ? "" : String.valueOf(cell.get("content"));
        String fieldCode = cell.get("field_code") == null ? null : String.valueOf(cell.get("field_code"));
        String entityCode = cell.get("entity_code") == null ? null : String.valueOf(cell.get("entity_code"));
        return rendererFactory.renderCell(cellType, content, fieldCode, entityCode, ctx, this);
    }

    /** 判断 (row, col) 是否被某个合并单元格覆盖（作为从属位置） */
    private boolean isMergedSlave(Map<String, Map<String, Object>> merges, int row, int col) {
        if (merges == null || merges.isEmpty()) {
            return false;
        }
        for (Map.Entry<String, Map<String, Object>> entry : merges.entrySet()) {
            String[] rc = entry.getKey().split("_");
            if (rc.length != 2) {
                continue;
            }
            int sr = Integer.parseInt(rc[0]);
            int sc = Integer.parseInt(rc[1]);
            Map<String, Object> m = entry.getValue();
            int rs = m.get("rowspan") == null ? 1 : Integer.parseInt(m.get("rowspan").toString());
            int cs = m.get("colspan") == null ? 1 : Integer.parseInt(m.get("colspan").toString());
            if (row >= sr && row < sr + rs && col >= sc && col < sc + cs && !(row == sr && col == sc)) {
                return true;
            }
        }
        return false;
    }

    private String resolveBand(List<Map<String, Object>> rowBands, int row) {
        if (rowBands == null) {
            return "";
        }
        for (Map<String, Object> b : rowBands) {
            Object r = b.get("row");
            Object band = b.get("band");
            if (r != null && band != null && Integer.parseInt(r.toString()) == row) {
                return band.toString();
            }
        }
        return "";
    }

    @SuppressWarnings("unchecked")
    private int countMaxSubRows(PrintContext ctx) {
        if (ctx.getSubData() == null || ctx.getSubData().isEmpty()) {
            return 0;
        }
        int max = 0;
        for (List<Map<String, Object>> rows : ctx.getSubData().values()) {
            if (rows != null && rows.size() > max) {
                max = rows.size();
            }
        }
        return max;
    }

    @SuppressWarnings("unchecked")
    private List<Map<String, Object>> firstSubRows(PrintContext ctx) {
        if (ctx.getSubData() == null || ctx.getSubData().isEmpty()) {
            return null;
        }
        for (List<Map<String, Object>> rows : ctx.getSubData().values()) {
            return rows;
        }
        return null;
    }

    private <T> T parseJson(String json, TypeReference<T> typeRef) {
        if (json == null || json.trim().isEmpty()) {
            return (T) (typeRef.getType() instanceof List ? new ArrayList<>() : new HashMap<>());
        }
        try {
            return MAPPER.readValue(json, typeRef);
        } catch (Exception e) {
            log.warn("JSON 解析失败: {} | {}", json, e.getMessage());
            try {
                return (T) (typeRef.getType() instanceof List ? new ArrayList<>() : new HashMap<>());
            } catch (ClassCastException ex) {
                return null;
            }
        }
    }

    private String escapeHtml(String s) {
        if (s == null) {
            return "";
        }
        return s.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;");
    }
}
