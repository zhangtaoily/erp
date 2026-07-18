package com.eerp.meta.rule.expr;

import java.util.Map;

/**
 * LOOKUP 函数数据源回调接口。
 *
 * <p>LOOKUP('table', {key:val}, 'returnField') 在求值时，由 {@link ExprContext} 持有的
 * 回调实例执行实际的数据反查。生产环境通常将其绑定为 JdbcTemplate 实现：</p>
 * <pre>
 *   ctx.setLookupCallback((table, filter, returnField) -&gt; {
 *       String sql = "SELECT " + returnField + " FROM " + table + " WHERE ...";
 *       return jdbcTemplate.queryForObject(sql, filter.values().toArray(), Object.class);
 *   });
 * </pre>
 *
 * <p><b>SQL 注入防护契约</b>：调用方 {@code LookupFunction} 已对 table / returnField /
 * filter 的 key 做合法标识符校验（{@code ^[a-zA-Z_][a-zA-Z0-9_]*$}），实现层可安全拼装
 * 这些标识符到 SQL；filter 的 value 必须使用参数化查询绑定，不得直接拼接到 SQL。</p>
 *
 * <p>对齐设计文档 08 §3.2.3 LOOKUP 实现与结果缓存（缓存由实现层负责）。</p>
 */
@FunctionalInterface
public interface LookupCallback {

    /**
     * 按表名 + 过滤条件 + 返回字段反查单值。
     *
     * @param table       表名（已校验为合法标识符）
     * @param filter      过滤条件（key 为字段名，已校验为合法标识符；value 为过滤值）
     * @param returnField 返回字段名（已校验为合法标识符）
     * @return 查询到的字段值；无匹配返回 null
     */
    Object lookup(String table, Map<String, Object> filter, String returnField);
}
