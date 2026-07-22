package com.eerp.common.api;

import java.util.Objects;

/**
 * 结构化查询条件 DTO。
 * <p>
 * 前端发送：
 * <pre>
 * { "field_code": "code", "operator": "like", "value": "0007" }
 * // 日期区间（between）：
 * { "field_code": "pact_date", "operator": "between", "value_start": "2026-07-01", "value_end": "2026-07-31" }
 * </pre>
 * 后端转换后交给 buildWhere 处理。
 */
public class QueryCondition {

    /** 字段编码 */
    private String fieldCode;

    /** 比较操作符：eq/ne/gt/lt/ge/le/like/not_like/begin_with/end_with/is_null/is_not_null/in/between */
    private String operator;

    /** 比较值（is_null/is_not_null 时可为空） */
    private Object value;

    /** between 区间起始值 */
    private Object valueStart;

    /** between 区间结束值 */
    private Object valueEnd;

    public QueryCondition() {
    }

    public QueryCondition(String fieldCode, String operator, Object value) {
        this.fieldCode = fieldCode;
        this.operator = operator;
        this.value = value;
    }

    public String getFieldCode() {
        return fieldCode;
    }

    public void setFieldCode(String fieldCode) {
        this.fieldCode = fieldCode;
    }

    public String getOperator() {
        return operator;
    }

    public void setOperator(String operator) {
        this.operator = operator;
    }

    public Object getValue() {
        return value;
    }

    public void setValue(Object value) {
        this.value = value;
    }

    public Object getValueStart() {
        return valueStart;
    }

    public void setValueStart(Object valueStart) {
        this.valueStart = valueStart;
    }

    public Object getValueEnd() {
        return valueEnd;
    }

    public void setValueEnd(Object valueEnd) {
        this.valueEnd = valueEnd;
    }

    /**
     * 构建后端 buildWhere 期望的 Map 值格式。
     * <p>普通操作符 → {"op":"like","value":"0007"}，
     * between → {"op":"between","value":["2026-07-01","2026-07-31"]}</p>
     */
    public java.util.Map<String, Object> toConditionMap() {
        java.util.Map<String, Object> map = new java.util.LinkedHashMap<>();
        map.put("op", operator);
        if ("between".equals(operator)) {
            // 后端 buildCondition 中 between 期望 value 为 Collection 或数组 [start, end]
            java.util.List<Object> pair = new java.util.ArrayList<>(2);
            pair.add(valueStart);
            pair.add(valueEnd);
            map.put("value", pair);
        } else if ("is_null".equals(operator) || "is_not_null".equals(operator)) {
            // 不需要 value
        } else {
            map.put("value", value);
        }
        return map;
    }

    /** 是否有效（有字段编码） */
    public boolean isValid() {
        return fieldCode != null && !fieldCode.trim().isEmpty();
    }

    /** 是否需要值（非 null 检查操作符 + 有值） */
    public boolean hasValue() {
        if ("is_null".equals(operator) || "is_not_null".equals(operator)) {
            return true; // 不需要值也是有效的
        }
        if ("between".equals(operator)) {
            return valueStart != null && !"".equals(valueStart.toString().trim())
                    && valueEnd != null && !"".equals(valueEnd.toString().trim());
        }
        return value != null && !"".equals(value.toString().trim());
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof QueryCondition)) return false;
        QueryCondition that = (QueryCondition) o;
        return Objects.equals(fieldCode, that.fieldCode)
                && Objects.equals(operator, that.operator)
                && Objects.equals(value, that.value);
    }

    @Override
    public int hashCode() {
        return Objects.hash(fieldCode, operator, value);
    }

    @Override
    public String toString() {
        return "QueryCondition{fieldCode='" + fieldCode + "', operator='" + operator + "', value=" + value + "}";
    }
}
