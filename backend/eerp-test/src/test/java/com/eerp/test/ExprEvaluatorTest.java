package com.eerp.test;

import com.eerp.meta.rule.expr.ExprContext;
import com.eerp.meta.rule.expr.ExprEvaluator;
import com.eerp.meta.rule.expr.ExprException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.Arrays;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * 表达式引擎（A1: ANTLR4 表达式引擎 —— 当前采用手写递归下降解析器实现）单元测试。
 *
 * <p>覆盖任务要求的全部场景：算术 / 比较 / 逻辑 / 字段引用 / 子实体聚合 / 三元 /
 * 函数（SUM/IF/COUNT/MAX/MIN/AVG）/ 赋值 / 校验（error）/ LOOKUP（mock 数据源）。
 * 并补充 LOOKUP 防注入校验、短路语义、缓存等场景。</p>
 */
class ExprEvaluatorTest {

    private ExprEvaluator evaluator;

    @BeforeEach
    void setUp() {
        evaluator = new ExprEvaluator();
    }

    // ============ 基础运算 ============

    @Test
    @DisplayName("算术：1+2*3 == 7")
    void testArithmeticPrecedence() {
        Object result = evaluator.evaluate("1+2*3", new ExprContext());
        assertEquals(Integer.valueOf(7), result);
    }

    @Test
    @DisplayName("算术：括号分组 (1+2)*3 == 9")
    void testArithmeticParentheses() {
        Object result = evaluator.evaluate("(1+2)*3", new ExprContext());
        assertEquals(Integer.valueOf(9), result);
    }

    @Test
    @DisplayName("比较：5 > 3 == true")
    void testComparison() {
        Object result = evaluator.evaluate("5 > 3", new ExprContext());
        assertEquals(Boolean.TRUE, result);
    }

    @Test
    @DisplayName("逻辑：true && false == false")
    void testLogicAnd() {
        Object result = evaluator.evaluate("true && false", new ExprContext());
        assertEquals(Boolean.FALSE, result);
    }

    @Test
    @DisplayName("逻辑：true || false == true")
    void testLogicOr() {
        Object result = evaluator.evaluate("true || false", new ExprContext());
        assertEquals(Boolean.TRUE, result);
    }

    @Test
    @DisplayName("逻辑非：!false == true")
    void testLogicNot() {
        Object result = evaluator.evaluate("!false", new ExprContext());
        assertEquals(Boolean.TRUE, result);
    }

    // ============ 字段引用 ============

    @Test
    @DisplayName("字段引用：$qty * $price，qty=10 price=5.5 结果 55.0")
    void testFieldReference() {
        Map<String, Object> root = new HashMap<>();
        root.put("qty", 10);
        root.put("price", 5.5);
        ExprContext ctx = new ExprContext(root);
        Object result = evaluator.evaluate("$qty * $price", ctx);
        assertEquals(55.0, ((Number) result).doubleValue(), 0.0001);
    }

    @Test
    @DisplayName("子实体引用：$detail.qty 聚合为列表，SUM == 9")
    void testSubEntityFieldAggregation() {
        ExprContext ctx = buildDetailContext();
        // $detail.qty 直接求值返回各行 qty 的 List
        Object list = evaluator.evaluate("$detail.qty", ctx);
        assertTrue(list instanceof List, "$detail.qty 应聚合为 List");
        assertEquals(Arrays.asList(2, 3, 4), list);
        // SUM 聚合
        Object sum = evaluator.evaluate("SUM($detail.qty)", ctx);
        assertEquals(9.0, ((Number) sum).doubleValue(), 0.0001);
    }

    // ============ 三元 ============

    @Test
    @DisplayName("三元：$qty > 0 ? 'ok' : 'empty'")
    void testTernary() {
        Map<String, Object> root = new HashMap<>();
        root.put("qty", 10);
        ExprContext ctx = new ExprContext(root);
        assertEquals("ok", evaluator.evaluate("$qty > 0 ? 'ok' : 'empty'", ctx));

        root.put("qty", 0);
        assertEquals("empty", evaluator.evaluate("$qty > 0 ? 'ok' : 'empty'", ctx));
    }

    // ============ 函数 ============

    @Test
    @DisplayName("函数：SUM($detail.amount) == 60.0")
    void testSumFunction() {
        ExprContext ctx = buildDetailContext();
        Object result = evaluator.evaluate("SUM($detail.amount)", ctx);
        assertEquals(60.0, ((Number) result).doubleValue(), 0.0001);
    }

    @Test
    @DisplayName("函数：COUNT($detail) == 3")
    void testCountFunction() {
        ExprContext ctx = buildDetailContext();
        Object result = evaluator.evaluate("COUNT($detail)", ctx);
        assertEquals(Integer.valueOf(3), result);
    }

    @Test
    @DisplayName("函数：MAX/MIN/AVG($detail.amount)")
    void testAggregateFunctions() {
        ExprContext ctx = buildDetailContext();
        assertEquals(30.0, ((Number) evaluator.evaluate("MAX($detail.amount)", ctx)).doubleValue(), 0.0001);
        assertEquals(10.0, ((Number) evaluator.evaluate("MIN($detail.amount)", ctx)).doubleValue(), 0.0001);
        assertEquals(20.0, ((Number) evaluator.evaluate("AVG($detail.amount)", ctx)).doubleValue(), 0.0001);
    }

    @Test
    @DisplayName("函数：IF($qty>0, 'pos', 'neg')")
    void testIfFunction() {
        Map<String, Object> root = new HashMap<>();
        root.put("qty", 5);
        ExprContext ctx = new ExprContext(root);
        assertEquals("pos", evaluator.evaluate("IF($qty>0, 'pos', 'neg')", ctx));

        root.put("qty", -3);
        assertEquals("neg", evaluator.evaluate("IF($qty>0, 'pos', 'neg')", ctx));
    }

    @Test
    @DisplayName("函数：IF 惰性求值（不命中分支的 error 不触发）")
    void testIfLazyEvaluation() {
        Map<String, Object> root = new HashMap<>();
        root.put("qty", 5);
        ExprContext ctx = new ExprContext(root);
        // qty>0 为 true，命中 then 分支，else 分支的 error 不应被求值
        Object result = evaluator.evaluate("IF($qty>0, $qty, error('不应触发'))", ctx);
        assertEquals(5, result);
    }

    @Test
    @DisplayName("函数：AND/OR 短路求值")
    void testAndOrShortCircuit() {
        Map<String, Object> root = new HashMap<>();
        root.put("a", 0);
        ExprContext ctx = new ExprContext(root);
        // false && ... 短路，后续 error 不触发
        assertEquals(Boolean.FALSE, evaluator.evaluate("false && error('不应触发')", ctx));
        // true || ... 短路
        assertEquals(Boolean.TRUE, evaluator.evaluate("true || error('不应触发')", ctx));
        // AND 函数短路
        assertEquals(Boolean.FALSE, evaluator.evaluate("AND(false, error('不应触发'))", ctx));
        assertEquals(Boolean.TRUE, evaluator.evaluate("OR(true, error('不应触发'))", ctx));
    }

    @Test
    @DisplayName("函数：ROUND / ABS / LEN / UPPER / LOWER")
    void testStringAndMathFunctions() {
        ExprContext ctx = new ExprContext();
        assertEquals(3.14, ((Number) evaluator.evaluate("ROUND(3.14159, 2)", ctx)).doubleValue(), 0.0001);
        assertEquals(5.0, ((Number) evaluator.evaluate("ABS(-5)", ctx)).doubleValue(), 0.0001);
        assertEquals(Integer.valueOf(5), evaluator.evaluate("LEN('hello')", ctx));
        assertEquals("HELLO", evaluator.evaluate("UPPER('hello')", ctx));
        assertEquals("world", evaluator.evaluate("LOWER('WORLD')", ctx));
    }

    // ============ 赋值 ============

    @Test
    @DisplayName("赋值：$total = SUM($detail.amount)，再引用 $total == 60.0")
    void testAssignment() {
        ExprContext ctx = buildDetailContext();
        // 赋值表达式返回赋值后的值
        Object assigned = evaluator.evaluate("$total = SUM($detail.amount)", ctx);
        assertEquals(60.0, ((Number) assigned).doubleValue(), 0.0001);
        // 变量已写入上下文，后续引用 $total
        Object total = evaluator.evaluate("$total", ctx);
        assertEquals(60.0, ((Number) total).doubleValue(), 0.0001);
        // 赋值后参与运算
        Object plus1 = evaluator.evaluate("$total + 1", ctx);
        assertEquals(61.0, ((Number) plus1).doubleValue(), 0.0001);
    }

    // ============ 校验 ============

    @Test
    @DisplayName("校验：error('数量必须大于0') 抛 ExprException")
    void testErrorFunctionThrows() {
        ExprException ex = assertThrows(ExprException.class,
                () -> evaluator.evaluate("error('数量必须大于0')", new ExprContext()));
        assertEquals("RULE_VALIDATE_FAIL", ex.getErrorCode());
        assertEquals("数量必须大于0", ex.getErrorMessage());
    }

    @Test
    @DisplayName("校验：IF 条件不满足时通过 error 抛出")
    void testValidationViaIf() {
        Map<String, Object> root = new HashMap<>();
        root.put("qty", 0);
        ExprContext ctx = new ExprContext(root);
        ExprException ex = assertThrows(ExprException.class,
                () -> evaluator.evaluate("IF($qty <= 0, error('数量必须大于0'), $qty)", ctx));
        assertEquals("RULE_VALIDATE_FAIL", ex.getErrorCode());
        assertEquals("数量必须大于0", ex.getErrorMessage());

        // qty>0 时不抛错，返回 qty
        root.put("qty", 8);
        Object result = evaluator.evaluate("IF($qty <= 0, error('数量必须大于0'), $qty)", ctx);
        assertEquals(8, result);
    }

    // ============ LOOKUP ============

    @Test
    @DisplayName("LOOKUP 函数（mock 数据源返回）")
    void testLookupFunction() {
        Map<String, Object> root = new HashMap<>();
        root.put("cust_id", 1001);
        ExprContext ctx = new ExprContext(root);
        // mock 数据源回调（生产环境绑定 JdbcTemplate 参数化查询）
        ctx.setLookupCallback((table, filter, returnField) -> {
            assertEquals("MD_CUSTOMER", table);
            assertEquals("name", returnField);
            assertEquals(1001, filter.get("id"));
            return "ACME 科贸";
        });
        Object result = evaluator.evaluate("LOOKUP('MD_CUSTOMER', {id: $cust_id}, 'name')", ctx);
        assertEquals("ACME 科贸", result);
    }

    @Test
    @DisplayName("LOOKUP 防注入：非法表名/字段名/key 抛 ExprException")
    void testLookupSqlInjectionGuard() {
        Map<String, Object> root = new HashMap<>();
        root.put("cust_id", 1);
        ExprContext ctx = new ExprContext(root);
        ctx.setLookupCallback((table, filter, returnField) -> "x");
        // 非法表名（含分号注入）
        assertThrows(ExprException.class,
                () -> evaluator.evaluate("LOOKUP('MD_CUSTOMER; DROP TABLE t', {id: $cust_id}, 'name')", ctx));
        // 非法返回字段名
        assertThrows(ExprException.class,
                () -> evaluator.evaluate("LOOKUP('MD_CUSTOMER', {id: $cust_id}, 'name; --')", ctx));
        // 非法过滤字段名
        assertThrows(ExprException.class,
                () -> evaluator.evaluate("LOOKUP('MD_CUSTOMER', {'id OR 1=1': 1}, 'name')", ctx));
    }

    @Test
    @DisplayName("LOOKUP 未配置数据源回调抛 ExprException")
    void testLookupWithoutCallback() {
        Map<String, Object> root = new HashMap<>();
        root.put("cust_id", 1);
        ExprContext ctx = new ExprContext(root);
        assertThrows(ExprException.class,
                () -> evaluator.evaluate("LOOKUP('MD_CUSTOMER', {id: $cust_id}, 'name')", ctx));
    }

    // ============ 缓存 ============

    @Test
    @DisplayName("表达式 AST 缓存：重复求值命中缓存")
    void testExpressionCache() {
        ExprContext ctx = new ExprContext();
        evaluator.evaluate("1+2", ctx);
        evaluator.evaluate("1+2", ctx);
        evaluator.evaluate("3*4", ctx);
        assertEquals(2, evaluator.cacheSize());
    }

    @Test
    @DisplayName("未知函数拒绝（沙箱白名单）")
    void testUnknownFunctionRejected() {
        ExprException ex = assertThrows(ExprException.class,
                () -> evaluator.evaluate("RUNTIME_EXEC('evil')", new ExprContext()));
        assertTrue(ex.getErrorMessage().contains("RUNTIME_EXEC"));
    }

    @Test
    @DisplayName("evaluateFieldRef 直接字段取值")
    void testEvaluateFieldRef() {
        Map<String, Object> root = new HashMap<>();
        root.put("code", "SO001");
        ExprContext ctx = new ExprContext(root);
        assertEquals("SO001", evaluator.evaluateFieldRef("code", ctx));
        // 子实体字段聚合
        ExprContext ctx2 = buildDetailContext();
        Object list = evaluator.evaluateFieldRef("detail.qty", ctx2);
        assertTrue(list instanceof List);
        assertEquals(Arrays.asList(2, 3, 4), list);
    }

    @Test
    @DisplayName("数组与 Map 字面量")
    void testArrayAndMapLiteral() {
        ExprContext ctx = new ExprContext();
        Object arr = evaluator.evaluate("[1, 2, 3]", ctx);
        assertTrue(arr instanceof List);
        assertEquals(Arrays.asList(1, 2, 3), arr);

        Object map = evaluator.evaluate("{'a': 1, 'b': 2}", ctx);
        assertTrue(map instanceof Map);
        assertEquals(1, ((Map<?, ?>) map).get("a"));
        assertEquals(2, ((Map<?, ?>) map).get("b"));
    }

    @Test
    @DisplayName("字符串拼接（+ 任一为 String）")
    void testStringConcat() {
        ExprContext ctx = new ExprContext();
        assertEquals("a-b", evaluator.evaluate("'a' + '-' + 'b'", ctx));
    }

    @Test
    @DisplayName("NOW 函数返回当前时间")
    void testNowFunction() {
        Object result = evaluator.evaluate("NOW()", new ExprContext());
        assertNotNullNow(result);
    }

    private void assertNotNullNow(Object result) {
        assertTrue(result != null, "NOW() 不应返回 null");
        assertTrue(result instanceof java.time.temporal.TemporalAccessor,
                "NOW() 应返回时间类型");
    }

    @Test
    @DisplayName("FORMAT 数字格式化")
    void testFormatFunction() {
        ExprContext ctx = new ExprContext();
        Object result = evaluator.evaluate("FORMAT(1234.5, '#,##0.00')", ctx);
        assertEquals("1,234.50", result);
    }

    // ============ 辅助构造 ============

    /** 构造含 detail 子表的上下文：3 行，qty=[2,3,4]，amount=[10.0,20.0,30.0] */
    @SuppressWarnings("unchecked")
    private ExprContext buildDetailContext() {
        Map<String, Object> root = new HashMap<>();
        root.put("bill_no", "SO202607170001");

        Map<String, Object> row1 = new LinkedHashMap<>();
        row1.put("qty", 2);
        row1.put("amount", 10.0);

        Map<String, Object> row2 = new LinkedHashMap<>();
        row2.put("qty", 3);
        row2.put("amount", 20.0);

        Map<String, Object> row3 = new LinkedHashMap<>();
        row3.put("qty", 4);
        row3.put("amount", 30.0);

        List<Map<String, Object>> detail = Arrays.asList(row1, row2, row3);
        Map<String, List<Map<String, Object>>> subData = new HashMap<>();
        subData.put("detail", detail);

        return new ExprContext(root, subData);
    }
}
