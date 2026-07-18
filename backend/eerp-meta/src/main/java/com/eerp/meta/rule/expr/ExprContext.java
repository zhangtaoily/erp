package com.eerp.meta.rule.expr;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 表达式求值上下文。
 *
 * <p>持有主表数据（rootData）、子表数据（subData，按实体编码分组）、变量（variables，
 * 赋值表达式目标）、函数注册表（functions）、LOOKUP 数据源回调（lookupCallback）。
 * 提供字段取值 {@link #getFieldValue(String)} 与子表数据访问 {@link #getSubData(String)}。</p>
 *
 * <p>字段引用解析规则（对齐任务规范与设计文档 08 §3.2.3）：</p>
 * <ul>
 *   <li>{@code $field}（无点号）：先查 variables（赋值目标），再查 subData（返回行列表，
 *       供 COUNT 等聚合），再查 rootData（主表字段）。</li>
 *   <li>{@code $entity.field}（有点号）：取 subData[entity] 各行的 field 值聚合为 List
 *       （供 SUM/AVG/MAX/MIN 聚合）；若 entity 不在 subData，回退按 rootData 嵌套 Map 导航。</li>
 * </ul>
 *
 * <p>线程安全说明：variables 与 functions 使用 ConcurrentHashMap，支持并发求值；
 * rootData / subData / lookupCallback 由调用方保证不可变或线程安全。</p>
 */
public class ExprContext {

    /** 主表数据 */
    private Map<String, Object> rootData;

    /** 子表数据：entityCode -&gt; 行列表（每行为字段名-&gt;值的 Map） */
    private Map<String, List<Map<String, Object>>> subData;

    /** 变量（赋值表达式目标，求值期间可读写） */
    private final Map<String, Object> variables = new ConcurrentHashMap<>();

    /** 函数注册表（默认内置全部内置函数） */
    private ExprFunctionRegistry functions;

    /** LOOKUP 数据源回调（可选，LOOKUP 函数使用） */
    private LookupCallback lookupCallback;

    public ExprContext() {
        this.rootData = Collections.emptyMap();
        this.subData = Collections.emptyMap();
        this.functions = new ExprFunctionRegistry();
    }

    public ExprContext(Map<String, Object> rootData) {
        this.rootData = rootData == null ? Collections.emptyMap() : rootData;
        this.subData = Collections.emptyMap();
        this.functions = new ExprFunctionRegistry();
    }

    public ExprContext(Map<String, Object> rootData,
                       Map<String, List<Map<String, Object>>> subData) {
        this.rootData = rootData == null ? Collections.emptyMap() : rootData;
        this.subData = subData == null ? Collections.emptyMap() : subData;
        this.functions = new ExprFunctionRegistry();
    }

    /**
     * 解析字段引用路径（不含前导 $）。
     *
     * @param path 字段路径，如 "qty" 或 "detail.qty"
     * @return 字段值；子实体字段返回 {@code List<Object>}（各行该字段值）；
     *         子实体编码（无点号）返回 {@code List<Map<String,Object>>}（行列表）
     */
    @SuppressWarnings("unchecked")
    public Object getFieldValue(String path) {
        if (path == null || path.isEmpty()) {
            return null;
        }
        // 1. 变量优先（赋值表达式目标）
        if (variables.containsKey(path)) {
            return variables.get(path);
        }
        int dot = path.indexOf('.');
        if (dot < 0) {
            // 无点号：可能是子实体编码（COUNT($detail)）或主表字段
            if (subData != null && subData.containsKey(path)) {
                return subData.get(path);
            }
            return rootData == null ? null : rootData.get(path);
        }
        // 有点号：$entity.field —— 子表行集合按字段聚合
        String entityCode = path.substring(0, dot);
        String fieldPath = path.substring(dot + 1);
        List<Map<String, Object>> rows = subData == null ? null : subData.get(entityCode);
        if (rows == null) {
            // 回退：rootData 上的嵌套 Map 导航（如 $cust.name）
            Object nested = rootData == null ? null : rootData.get(entityCode);
            if (nested instanceof Map) {
                return navigateMap((Map<String, Object>) nested, fieldPath);
            }
            return null;
        }
        List<Object> values = new ArrayList<>(rows.size());
        for (Map<String, Object> row : rows) {
            values.add(row == null ? null : navigateMap(row, fieldPath));
        }
        return values;
    }

    /** 沿点号路径导航嵌套 Map */
    @SuppressWarnings("unchecked")
    private Object navigateMap(Map<String, Object> map, String path) {
        Object current = map;
        for (String seg : path.split("\\.")) {
            if (current instanceof Map) {
                current = ((Map<String, Object>) current).get(seg);
            } else {
                return null;
            }
            if (current == null) {
                return null;
            }
        }
        return current;
    }

    /**
     * 返回子表行列表。
     *
     * @param entityCode 实体编码
     * @return 行列表；不存在返回 null
     */
    public List<Map<String, Object>> getSubData(String entityCode) {
        return subData == null ? null : subData.get(entityCode);
    }

    /** 设置变量（赋值表达式调用） */
    public void setVariable(String name, Object value) {
        variables.put(name, value);
    }

    /** 读取变量 */
    public Object getVariable(String name) {
        return variables.get(name);
    }

    /** 注册或覆盖变量批量（链式） */
    public ExprContext withVariables(Map<String, Object> vars) {
        if (vars != null) {
            variables.putAll(vars);
        }
        return this;
    }

    public Map<String, Object> getRootData() {
        return rootData;
    }

    public void setRootData(Map<String, Object> rootData) {
        this.rootData = rootData == null ? Collections.emptyMap() : rootData;
    }

    public Map<String, List<Map<String, Object>>> getSubDataMap() {
        return subData;
    }

    public void setSubData(Map<String, List<Map<String, Object>>> subData) {
        this.subData = subData == null ? Collections.emptyMap() : subData;
    }

    public Map<String, Object> getVariables() {
        return new LinkedHashMap<>(variables);
    }

    public ExprFunctionRegistry getFunctions() {
        if (functions == null) {
            functions = new ExprFunctionRegistry();
        }
        return functions;
    }

    public void setFunctions(ExprFunctionRegistry functions) {
        this.functions = functions;
    }

    public LookupCallback getLookupCallback() {
        return lookupCallback;
    }

    public void setLookupCallback(LookupCallback lookupCallback) {
        this.lookupCallback = lookupCallback;
    }
}
