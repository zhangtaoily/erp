package com.eerp.meta.rule.expr.functions;

import com.eerp.meta.rule.expr.ExprContext;
import com.eerp.meta.rule.expr.ExprException;
import com.eerp.meta.rule.expr.ExprFunction;
import com.eerp.meta.rule.expr.LookupCallback;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Pattern;

/**
 * LOOKUP('table', {key:val}, 'returnField') —— 基础资料反查。
 *
 * <p>三参数：表名（字符串）、过滤条件（Map）、返回字段名（字符串）。对表名 / 返回字段名 /
 * 过滤 Map 的 key 做<b>合法标识符校验</b>（{@code ^[a-zA-Z_][a-zA-Z0-9_]*$}），防止
 * SQL 注入；过滤值由 {@link LookupCallback} 实现层使用参数化查询绑定。</p>
 *
 * <p>对齐设计文档 08 §3.2.3 LOOKUP 实现与 §5.4 LOOKUP(bo, filter, field)。</p>
 */
public class LookupFunction implements ExprFunction {

    /** 合法标识符正则（防 SQL 注入） */
    private static final Pattern IDENT = Pattern.compile("^[a-zA-Z_][a-zA-Z0-9_]*$");

    @Override
    public String name() {
        return "LOOKUP";
    }

    @Override
    public Object execute(List<Object> args, ExprContext ctx) throws ExprException {
        FuncUtil.checkArgs("LOOKUP", args, 3, 3);
        String table = FuncUtil.toStr(args.get(0));
        Object filterObj = args.get(1);
        String returnField = FuncUtil.toStr(args.get(2));

        if (table == null || !IDENT.matcher(table).matches()) {
            throw new ExprException("EXPR_EVAL_ERROR",
                    "LOOKUP 表名必须为合法标识符: " + table);
        }
        if (returnField == null || !IDENT.matcher(returnField).matches()) {
            throw new ExprException("EXPR_EVAL_ERROR",
                    "LOOKUP 返回字段名必须为合法标识符: " + returnField);
        }
        Map<String, Object> filter = toFilterMap(filterObj);

        LookupCallback callback = ctx.getLookupCallback();
        if (callback == null) {
            throw new ExprException("EXPR_EVAL_ERROR",
                    "LOOKUP 未配置数据源回调（LookupCallback），无法执行反查");
        }
        return callback.lookup(table, filter, returnField);
    }

    /** 将实参转为过滤 Map，并校验 key 为合法标识符 */
    @SuppressWarnings("unchecked")
    private Map<String, Object> toFilterMap(Object filterObj) {
        if (filterObj == null) {
            return new LinkedHashMap<>();
        }
        Map<String, Object> result = new LinkedHashMap<>();
        if (filterObj instanceof Map) {
            for (Map.Entry<Object, Object> e : ((Map<Object, Object>) filterObj).entrySet()) {
                String key = String.valueOf(e.getKey());
                if (!IDENT.matcher(key).matches()) {
                    throw new ExprException("EXPR_EVAL_ERROR",
                            "LOOKUP 过滤字段名必须为合法标识符: " + key);
                }
                result.put(key, e.getValue());
            }
            return result;
        }
        throw new ExprException("EXPR_EVAL_ERROR",
                "LOOKUP 第二参数必须为 Map 字面量 {key:val}");
    }
}
