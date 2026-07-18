package com.eerp.bos.print;

import lombok.Data;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.Map;

/**
 * 打印渲染上下文（对齐设计文档 02 §3.8）。
 *
 * <p>持有当前渲染单据的数据（主表 + 子表）、当前渲染行索引、变量表，
 * 供 {@link AbstractPrintTemplateService} 渲染单元格时引用。</p>
 */
@Data
public class PrintContext {

    /** 业务对象编码 */
    private String boCode;

    /** 单据ID */
    private Long billId;

    /** 单据编号（展示用） */
    private String billCode;

    /** 主表数据 */
    private Map<String, Object> mainData = new HashMap<>();

    /** 子表数据：entityCode -&gt; 行列表 */
    private Map<String, java.util.List<Map<String, Object>>> subData = new HashMap<>();

    /** 当前 detail 行带展开的行索引（从 0 开始） */
    private int currentRowIndex = -1;

    /** 当前 detail 行数据（展开时填充） */
    private Map<String, Object> currentRow;

    /** 变量表（公式求值期间可读写） */
    private final Map<String, Object> variables = new HashMap<>();

    /** 设置变量 */
    public void setVariable(String name, Object value) {
        variables.put(name, value);
    }

    /** 读取变量 */
    public Object getVariable(String name) {
        return variables.get(name);
    }

    /** 按字段路径取值：main.field / detail.field / $var */
    @SuppressWarnings("unchecked")
    public Object getFieldValue(String path) {
        if (path == null || path.isEmpty()) {
            return null;
        }
        if (path.startsWith("$")) {
            return variables.get(path.substring(1));
        }
        int dot = path.indexOf('.');
        if (dot < 0) {
            return mainData == null ? null : mainData.get(path);
        }
        String entityCode = path.substring(0, dot);
        String field = path.substring(dot + 1);
        // main.entity → 直接从主表取字段
        if ("main".equalsIgnoreCase(entityCode)) {
            return mainData == null ? null : mainData.get(field);
        }
        // 优先从当前 detail 行取值
        if ("detail".equalsIgnoreCase(entityCode) && currentRow != null) {
            return currentRow.get(field);
        }
        // 从子表数据按行索引取值
        java.util.List<Map<String, Object>> rows = subData == null ? null : subData.get(entityCode);
        if (rows != null && !rows.isEmpty() && currentRowIndex >= 0 && currentRowIndex < rows.size()) {
            return rows.get(currentRowIndex).get(field);
        }
        // 从主表嵌套 Map 取值
        if (mainData != null) {
            Object nested = mainData.get(entityCode);
            if (nested instanceof Map) {
                return ((Map<String, Object>) nested).get(field);
            }
        }
        return null;
    }

    /** 数字工具：将任意值转为 BigDecimal（null 返回 0） */
    public static BigDecimal toBigDecimal(Object v) {
        if (v == null) {
            return BigDecimal.ZERO;
        }
        if (v instanceof BigDecimal) {
            return (BigDecimal) v;
        }
        if (v instanceof Number) {
            return new BigDecimal(v.toString());
        }
        try {
            return new BigDecimal(v.toString());
        } catch (NumberFormatException e) {
            return BigDecimal.ZERO;
        }
    }
}
