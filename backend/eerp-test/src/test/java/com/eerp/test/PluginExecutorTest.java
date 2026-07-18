package com.eerp.test;

import com.eerp.meta.plugin.entity.MetaFormPlugin;
import com.eerp.meta.plugin.mapper.MetaPluginParamMapper;
import com.eerp.meta.plugin.service.MetaFormPluginService;
import com.eerp.meta.rule.expr.ExprContext;
import com.eerp.meta.rule.expr.ExprEvaluator;
import com.eerp.plugin.annotation.FormParam;
import com.eerp.plugin.base.AbstractOperationServicePlugin;
import com.eerp.plugin.context.PluginContext;
import com.eerp.plugin.context.PluginResult;
import com.eerp.plugin.core.LoadedPlugin;
import com.eerp.plugin.core.PluginContextFactory;
import com.eerp.plugin.core.PluginExecutor;
import com.eerp.plugin.core.PluginExecutorResult;
import com.eerp.plugin.core.PluginLoader;
import com.eerp.plugin.script.Antlr4ScriptEngine;
import com.eerp.plugin.script.ScriptEngine;
import com.eerp.plugin.script.ScriptPluginAdapter;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * 插件执行器与相关组件单元测试（A3: 插件系统）。
 *
 * <p>覆盖：
 * <ul>
 *   <li>PluginResult 静态工厂 ok/ok(data)/fail/block；</li>
 *   <li>PluginContext addValidationError/hasValidationErrors/get/set；</li>
 *   <li>PluginContextFactory.create 初始化；</li>
 *   <li>PluginExecutor 顺序执行、block 阻断、@FormParam 注入、PascalCase 兼容、异常阻断、空列表；</li>
 *   <li>Antlr4ScriptEngine eval/evalBoolean（含空脚本）；</li>
 *   <li>ScriptPluginAdapter 通过/阻断/空脚本；</li>
 *   <li>PluginLoader Java/SCRIPT 类型加载、事件过滤、execOrder 升序排序、status 过滤。</li>
 * </ul>
 * </p>
 *
 * <p>使用 manual {@code Mockito.mock()} 避免 {@code @ExtendWith(MockitoExtension.class)} 的
 * strict stubbing 问题；测试插件类作为 public static nested class 声明。</p>
 */
class PluginExecutorTest {

    private PluginExecutor executor;
    private PluginContextFactory contextFactory;

    @BeforeEach
    void setUp() {
        executor = new PluginExecutor();
        contextFactory = new PluginContextFactory();
    }

    // ============ PluginResult ============

    @Test
    @DisplayName("PluginResult.ok: success=true, block=false")
    void testResultOk() {
        PluginResult r = PluginResult.ok();
        assertTrue(r.isSuccess());
        assertFalse(r.isBlock());
        assertNull(r.getData());
    }

    @Test
    @DisplayName("PluginResult.ok(data): 携带数据")
    void testResultOkWithData() {
        PluginResult r = PluginResult.ok("payload");
        assertTrue(r.isSuccess());
        assertFalse(r.isBlock());
        assertEquals("payload", r.getData());
    }

    @Test
    @DisplayName("PluginResult.fail: success=false, block=false")
    void testResultFail() {
        PluginResult r = PluginResult.fail("失败原因");
        assertFalse(r.isSuccess());
        assertFalse(r.isBlock());
        assertEquals("失败原因", r.getMessage());
    }

    @Test
    @DisplayName("PluginResult.block: success=false, block=true")
    void testResultBlock() {
        PluginResult r = PluginResult.block("阻断原因");
        assertFalse(r.isSuccess());
        assertTrue(r.isBlock());
        assertEquals("阻断原因", r.getMessage());
    }

    // ============ PluginContext ============

    @Test
    @DisplayName("PluginContext.addValidationError/hasValidationErrors")
    void testContextValidationErrors() {
        PluginContext ctx = new PluginContext();
        assertFalse(ctx.hasValidationErrors());
        ctx.addValidationError("数量必须大于0");
        ctx.addValidationError("客户信用不足");
        assertTrue(ctx.hasValidationErrors());
        assertEquals(2, ctx.getValidationErrors().size());
    }

    @Test
    @DisplayName("PluginContext.get/set 共享变量")
    void testContextVariables() {
        PluginContext ctx = new PluginContext();
        assertNull(ctx.get("k1"));
        ctx.set("k1", "v1");
        assertEquals("v1", ctx.get("k1"));
    }

    // ============ PluginContextFactory ============

    @Test
    @DisplayName("PluginContextFactory.create 初始化所有字段")
    void testContextFactoryCreate() {
        Map<String, Object> billData = new HashMap<>();
        billData.put("qty", 10);
        Map<String, Object> userInfo = new HashMap<>();
        userInfo.put("userId", "U1");
        PluginContext ctx = contextFactory.create("SO", 100L, "audit", billData, userInfo);
        assertEquals("SO", ctx.getBoCode());
        assertEquals(100L, ctx.getBillId());
        assertEquals("audit", ctx.getOperation());
        assertEquals(billData, ctx.getBillData());
        assertEquals(userInfo, ctx.getUserInfo());
        assertNotNull(ctx.getVariables());
        assertNotNull(ctx.getExtras());
        assertNotNull(ctx.getValidationErrors());
        assertFalse(ctx.hasValidationErrors());
    }

    // ============ PluginExecutor 顺序执行 ============

    @Test
    @DisplayName("PluginExecutor: 3 个插件顺序执行全部成功")
    void testExecutorOrderedOk() {
        PluginContext ctx = contextFactory.create("SO", 1L, "audit", new HashMap<>(), new HashMap<>());
        List<LoadedPlugin> plugins = Arrays.asList(
                loaded(new OkBeforePlugin(), 1),
                loaded(new OkBeforePlugin(), 2),
                loaded(new ThirdPlugin(), 3)
        );
        PluginExecutorResult result = executor.execute(plugins, "beforeExecuteOperationTransaction", ctx);
        assertTrue(result.isSuccess());
        assertFalse(result.isBlock());
        assertEquals(3, result.getResults().size());
        assertEquals(Boolean.TRUE, ctx.get("executed"));
        assertEquals(Boolean.TRUE, ctx.get("thirdExecuted"));
    }

    @Test
    @DisplayName("PluginExecutor: 第 2 个插件阻断，第 3 个不执行")
    void testExecutorBlockStops() {
        PluginContext ctx = contextFactory.create("SO", 1L, "audit", new HashMap<>(), new HashMap<>());
        List<LoadedPlugin> plugins = Arrays.asList(
                loaded(new OkBeforePlugin(), 1),
                loaded(new BlockPlugin(), 2),
                loaded(new ThirdPlugin(), 3)
        );
        PluginExecutorResult result = executor.execute(plugins, "beforeExecuteOperationTransaction", ctx);
        assertFalse(result.isSuccess());
        assertTrue(result.isBlock());
        assertEquals(2, result.getResults().size());
        assertEquals("阻断测试", result.getMessage());
        // 第 1 个执行，第 3 个未执行
        assertEquals(Boolean.TRUE, ctx.get("executed"));
        assertNull(ctx.get("thirdExecuted"));
    }

    @Test
    @DisplayName("PluginExecutor: @FormParam 注入从 billData 取值（qty=5 通过）")
    void testExecutorInjectFormParamsOk() {
        Map<String, Object> billData = new HashMap<>();
        billData.put("qty", new BigDecimal("5"));
        PluginContext ctx = contextFactory.create("SO", 1L, "audit", billData, new HashMap<>());
        List<LoadedPlugin> plugins = Collections.singletonList(loaded(new TestAuditPlugin(), 1));
        PluginExecutorResult result = executor.execute(plugins, "beforeExecuteOperationTransaction", ctx);
        assertTrue(result.isSuccess());
        assertFalse(result.isBlock());
    }

    @Test
    @DisplayName("PluginExecutor: @FormParam 注入 qty=-1 阻断")
    void testExecutorInjectFormParamsBlock() {
        Map<String, Object> billData = new HashMap<>();
        billData.put("qty", new BigDecimal("-1"));
        PluginContext ctx = contextFactory.create("SO", 1L, "audit", billData, new HashMap<>());
        List<LoadedPlugin> plugins = Collections.singletonList(loaded(new TestAuditPlugin(), 1));
        PluginExecutorResult result = executor.execute(plugins, "beforeExecuteOperationTransaction", ctx);
        assertFalse(result.isSuccess());
        assertTrue(result.isBlock());
    }

    @Test
    @DisplayName("PluginExecutor: 事件名 PascalCase 兼容 camelCase 方法")
    void testExecutorPascalCaseEvent() {
        PluginContext ctx = contextFactory.create("SO", 1L, "audit", new HashMap<>(), new HashMap<>());
        List<LoadedPlugin> plugins = Collections.singletonList(loaded(new OkBeforePlugin(), 1));
        // PascalCase 事件名应能匹配 camelCase 方法 beforeExecuteOperationTransaction
        PluginExecutorResult result = executor.execute(plugins, "BeforeExecuteOperationTransaction", ctx);
        assertTrue(result.isSuccess());
        assertEquals(Boolean.TRUE, ctx.get("executed"));
    }

    @Test
    @DisplayName("PluginExecutor: 方法抛异常视为阻断")
    void testExecutorExceptionBlock() {
        PluginContext ctx = contextFactory.create("SO", 1L, "audit", new HashMap<>(), new HashMap<>());
        List<LoadedPlugin> plugins = Collections.singletonList(loaded(new ExceptionPlugin(), 1));
        PluginExecutorResult result = executor.execute(plugins, "beforeExecuteOperationTransaction", ctx);
        assertFalse(result.isSuccess());
        assertTrue(result.isBlock());
        assertNotNull(result.getMessage());
    }

    @Test
    @DisplayName("PluginExecutor: 空插件列表直接返回成功")
    void testExecutorEmptyPlugins() {
        PluginContext ctx = contextFactory.create("SO", 1L, "audit", new HashMap<>(), new HashMap<>());
        PluginExecutorResult result = executor.execute(new ArrayList<>(), "beforeExecuteOperationTransaction", ctx);
        assertTrue(result.isSuccess());
        assertFalse(result.isBlock());
        assertEquals(0, result.getResults().size());
    }

    @Test
    @DisplayName("PluginExecutor: null 插件列表直接返回成功")
    void testExecutorNullPlugins() {
        PluginContext ctx = contextFactory.create("SO", 1L, "audit", new HashMap<>(), new HashMap<>());
        PluginExecutorResult result = executor.execute(null, "beforeExecuteOperationTransaction", ctx);
        assertTrue(result.isSuccess());
        assertEquals(0, result.getResults().size());
    }

    @Test
    @DisplayName("PluginExecutor: execOrder 乱序输入会按升序执行")
    void testExecutorResortByExecOrder() {
        PluginContext ctx = contextFactory.create("SO", 1L, "audit", new HashMap<>(), new HashMap<>());
        // 故意乱序：3, 1, 2
        List<LoadedPlugin> plugins = Arrays.asList(
                loaded(new OrderMarkPlugin("c"), 3),
                loaded(new OrderMarkPlugin("a"), 1),
                loaded(new OrderMarkPlugin("b"), 2)
        );
        PluginExecutorResult result = executor.execute(plugins, "beforeExecuteOperationTransaction", ctx);
        assertTrue(result.isSuccess());
        // 应按 a → b → c 顺序执行
        assertEquals("a,b,c", ctx.get("orderLog"));
    }

    // ============ Antlr4ScriptEngine ============

    @Test
    @DisplayName("Antlr4ScriptEngine.eval: $qty > 0 → Boolean.TRUE")
    void testScriptEngineEvalTrue() {
        Antlr4ScriptEngine engine = new Antlr4ScriptEngine(new ExprEvaluator());
        Map<String, Object> root = new HashMap<>();
        root.put("qty", 10);
        Object result = engine.eval("$qty > 0", new ExprContext(root));
        assertEquals(Boolean.TRUE, result);
    }

    @Test
    @DisplayName("Antlr4ScriptEngine.evalBoolean: $qty > 0 在 qty=10 时 true")
    void testScriptEngineEvalBooleanTrue() {
        Antlr4ScriptEngine engine = new Antlr4ScriptEngine(new ExprEvaluator());
        Map<String, Object> root = new HashMap<>();
        root.put("qty", 10);
        assertTrue(engine.evalBoolean("$qty > 0", new ExprContext(root)));
    }

    @Test
    @DisplayName("Antlr4ScriptEngine.evalBoolean: $qty > 0 在 qty=-5 时 false")
    void testScriptEngineEvalBooleanFalse() {
        Antlr4ScriptEngine engine = new Antlr4ScriptEngine(new ExprEvaluator());
        Map<String, Object> root = new HashMap<>();
        root.put("qty", -5);
        assertFalse(engine.evalBoolean("$qty > 0", new ExprContext(root)));
    }

    @Test
    @DisplayName("Antlr4ScriptEngine.evalBoolean: 空脚本/null 返回 false")
    void testScriptEngineEvalBooleanEmpty() {
        Antlr4ScriptEngine engine = new Antlr4ScriptEngine(new ExprEvaluator());
        assertFalse(engine.evalBoolean("", new ExprContext()));
        assertFalse(engine.evalBoolean(null, new ExprContext()));
    }

    @Test
    @DisplayName("Antlr4ScriptEngine.eval: 空脚本返回 null")
    void testScriptEngineEvalEmpty() {
        Antlr4ScriptEngine engine = new Antlr4ScriptEngine(new ExprEvaluator());
        assertNull(engine.eval("", new ExprContext()));
        assertNull(engine.eval(null, new ExprContext()));
    }

    // ============ ScriptPluginAdapter ============

    @Test
    @DisplayName("ScriptPluginAdapter: 脚本求值 true 通过")
    void testAdapterPass() {
        ScriptEngine mockEngine = mock(ScriptEngine.class);
        when(mockEngine.evalBoolean(anyString(), any())).thenReturn(true);
        Map<String, String> scripts = new HashMap<>();
        scripts.put("beforeExecuteOperationTransaction", "$qty > 0");
        ScriptPluginAdapter adapter = new ScriptPluginAdapter(scripts, mockEngine);
        PluginContext ctx = contextFactory.create("SO", 1L, "audit", new HashMap<>(), new HashMap<>());
        PluginResult result = adapter.beforeExecuteOperationTransaction(ctx);
        assertTrue(result.isSuccess());
        assertFalse(result.isBlock());
    }

    @Test
    @DisplayName("ScriptPluginAdapter: 脚本求值 false 阻断")
    void testAdapterBlock() {
        ScriptEngine mockEngine = mock(ScriptEngine.class);
        when(mockEngine.evalBoolean(anyString(), any())).thenReturn(false);
        Map<String, String> scripts = new HashMap<>();
        scripts.put("beforeExecuteOperationTransaction", "$qty > 0");
        ScriptPluginAdapter adapter = new ScriptPluginAdapter(scripts, mockEngine);
        PluginContext ctx = contextFactory.create("SO", 1L, "audit", new HashMap<>(), new HashMap<>());
        PluginResult result = adapter.beforeExecuteOperationTransaction(ctx);
        assertFalse(result.isSuccess());
        assertTrue(result.isBlock());
    }

    @Test
    @DisplayName("ScriptPluginAdapter: 空脚本通过")
    void testAdapterEmptyScript() {
        ScriptEngine mockEngine = mock(ScriptEngine.class);
        ScriptPluginAdapter adapter = new ScriptPluginAdapter(new HashMap<>(), mockEngine);
        PluginContext ctx = contextFactory.create("SO", 1L, "audit", new HashMap<>(), new HashMap<>());
        PluginResult result = adapter.beforeExecuteOperationTransaction(ctx);
        assertTrue(result.isSuccess());
        assertFalse(result.isBlock());
    }

    @Test
    @DisplayName("ScriptPluginAdapter: afterExecuteOperationTransaction 为 void 不阻断")
    void testAdapterAfterIsVoid() {
        ScriptEngine mockEngine = mock(ScriptEngine.class);
        when(mockEngine.evalBoolean(anyString(), any())).thenReturn(false);
        Map<String, String> scripts = new HashMap<>();
        scripts.put("afterExecuteOperationTransaction", "$qty > 0");
        ScriptPluginAdapter adapter = new ScriptPluginAdapter(scripts, mockEngine);
        PluginContext ctx = contextFactory.create("SO", 1L, "audit", new HashMap<>(), new HashMap<>());
        // after 阶段为 void，不抛异常即视为通过
        adapter.afterExecuteOperationTransaction(ctx);
        // 若调用未抛异常则视为成功
        assertTrue(true);
    }

    @Test
    @DisplayName("ScriptPluginAdapter: 集成真实 Antlr4ScriptEngine（qty=10 通过）")
    void testAdapterWithRealEnginePass() {
        Antlr4ScriptEngine engine = new Antlr4ScriptEngine(new ExprEvaluator());
        Map<String, String> scripts = new HashMap<>();
        scripts.put("beforeExecuteOperationTransaction", "$qty > 0");
        ScriptPluginAdapter adapter = new ScriptPluginAdapter(scripts, engine);
        Map<String, Object> billData = new HashMap<>();
        billData.put("qty", 10);
        PluginContext ctx = contextFactory.create("SO", 1L, "audit", billData, new HashMap<>());
        PluginResult result = adapter.beforeExecuteOperationTransaction(ctx);
        assertTrue(result.isSuccess());
    }

    @Test
    @DisplayName("ScriptPluginAdapter: 集成真实 Antlr4ScriptEngine（qty=-1 阻断）")
    void testAdapterWithRealEngineBlock() {
        Antlr4ScriptEngine engine = new Antlr4ScriptEngine(new ExprEvaluator());
        Map<String, String> scripts = new HashMap<>();
        scripts.put("beforeExecuteOperationTransaction", "$qty > 0");
        ScriptPluginAdapter adapter = new ScriptPluginAdapter(scripts, engine);
        Map<String, Object> billData = new HashMap<>();
        billData.put("qty", -1);
        PluginContext ctx = contextFactory.create("SO", 1L, "audit", billData, new HashMap<>());
        PluginResult result = adapter.beforeExecuteOperationTransaction(ctx);
        assertFalse(result.isSuccess());
        assertTrue(result.isBlock());
    }

    // ============ PluginLoader ============

    @Test
    @DisplayName("PluginLoader: 加载 Java 类型插件（识别 OPERATION_SERVICE 基类）")
    void testLoaderJavaType() {
        MetaFormPluginService mockService = mock(MetaFormPluginService.class);
        MetaPluginParamMapper mockParamMapper = mock(MetaPluginParamMapper.class);
        ScriptEngine mockEngine = mock(ScriptEngine.class);
        PluginLoader loader = new PluginLoader(mockService, mockParamMapper, mockEngine);

        MetaFormPlugin cfg = new MetaFormPlugin();
        cfg.setPluginCode("P1");
        cfg.setPluginName("测试审计插件");
        cfg.setBoCode("SO");
        cfg.setBaseClass("OperationServicePlugin");
        cfg.setEventName("beforeExecuteOperationTransaction");
        cfg.setPluginType("JAVA");
        cfg.setExecOrder(1);
        cfg.setStatus(1);
        cfg.setClassName(TestAuditPlugin.class.getName());

        when(mockService.listByBoCode("SO")).thenReturn(Collections.singletonList(cfg));
        when(mockParamMapper.listByPluginCode("P1")).thenReturn(Collections.emptyList());

        List<LoadedPlugin> loaded = loader.loadPlugins("SO", "beforeExecuteOperationTransaction");
        assertEquals(1, loaded.size());
        LoadedPlugin lp = loaded.get(0);
        assertEquals("OPERATION_SERVICE", lp.getBaseClass());
        assertEquals(1, lp.getExecOrder());
        assertTrue(lp.getPluginInstance() instanceof TestAuditPlugin);
        // 应扫描到 1 个 @FormParam
        assertEquals(1, lp.getParams().size());
        assertEquals("qty", lp.getParams().get(0).getParamName());
        assertEquals("NUMBER", lp.getParams().get(0).getParamType());
        assertTrue(lp.getParams().get(0).isRequired());
    }

    @Test
    @DisplayName("PluginLoader: 加载 SCRIPT 类型插件")
    void testLoaderScriptType() {
        MetaFormPluginService mockService = mock(MetaFormPluginService.class);
        MetaPluginParamMapper mockParamMapper = mock(MetaPluginParamMapper.class);
        ScriptEngine mockEngine = mock(ScriptEngine.class);
        PluginLoader loader = new PluginLoader(mockService, mockParamMapper, mockEngine);

        MetaFormPlugin cfg = new MetaFormPlugin();
        cfg.setPluginCode("P2");
        cfg.setBoCode("SO");
        cfg.setEventName("beforeExecuteOperationTransaction");
        cfg.setPluginType("SCRIPT");
        cfg.setExecOrder(2);
        cfg.setStatus(1);
        cfg.setScriptContent("$qty > 0");

        when(mockService.listByBoCode("SO")).thenReturn(Collections.singletonList(cfg));

        List<LoadedPlugin> loaded = loader.loadPlugins("SO", "beforeExecuteOperationTransaction");
        assertEquals(1, loaded.size());
        LoadedPlugin lp = loaded.get(0);
        assertEquals("OPERATION_SERVICE", lp.getBaseClass());
        assertTrue(lp.getPluginInstance() instanceof ScriptPluginAdapter);
    }

    @Test
    @DisplayName("PluginLoader: 事件过滤 + status 过滤 + execOrder 升序排序")
    void testLoaderFilterAndOrder() {
        MetaFormPluginService mockService = mock(MetaFormPluginService.class);
        MetaPluginParamMapper mockParamMapper = mock(MetaPluginParamMapper.class);
        ScriptEngine mockEngine = mock(ScriptEngine.class);
        PluginLoader loader = new PluginLoader(mockService, mockParamMapper, mockEngine);

        MetaFormPlugin cfg1 = new MetaFormPlugin();
        cfg1.setPluginCode("P1");
        cfg1.setBoCode("SO");
        cfg1.setEventName("beforeExecuteOperationTransaction");
        cfg1.setPluginType("JAVA");
        cfg1.setExecOrder(2);
        cfg1.setStatus(1);
        cfg1.setClassName(OkBeforePlugin.class.getName());

        MetaFormPlugin cfg2 = new MetaFormPlugin();
        cfg2.setPluginCode("P2");
        cfg2.setBoCode("SO");
        cfg2.setEventName("onPreparePropertys"); // 不同事件，应被过滤
        cfg2.setPluginType("JAVA");
        cfg2.setExecOrder(1);
        cfg2.setStatus(1);
        cfg2.setClassName(OkBeforePlugin.class.getName());

        MetaFormPlugin cfg3 = new MetaFormPlugin();
        cfg3.setPluginCode("P3");
        cfg3.setBoCode("SO");
        cfg3.setEventName("beforeExecuteOperationTransaction");
        cfg3.setPluginType("JAVA");
        cfg3.setExecOrder(3);
        cfg3.setStatus(0); // 停用，应被过滤

        MetaFormPlugin cfg4 = new MetaFormPlugin();
        cfg4.setPluginCode("P4");
        cfg4.setBoCode("SO");
        cfg4.setEventName("BeforeExecuteOperationTransaction"); // PascalCase 事件名（大小写不敏感匹配）
        cfg4.setPluginType("JAVA");
        cfg4.setExecOrder(1);
        cfg4.setStatus(1);
        cfg4.setClassName(OkBeforePlugin.class.getName());

        when(mockService.listByBoCode("SO")).thenReturn(Arrays.asList(cfg1, cfg2, cfg3, cfg4));
        when(mockParamMapper.listByPluginCode(anyString())).thenReturn(Collections.emptyList());

        List<LoadedPlugin> loaded = loader.loadPlugins("SO", "beforeExecuteOperationTransaction");
        // 应过滤掉 cfg2（事件不匹配）和 cfg3（停用），剩 cfg4（order=1）和 cfg1（order=2）
        assertEquals(2, loaded.size());
        assertEquals(1, loaded.get(0).getExecOrder());
        assertEquals(2, loaded.get(1).getExecOrder());
    }

    @Test
    @DisplayName("PluginLoader: 无配置返回空列表")
    void testLoaderEmptyConfig() {
        MetaFormPluginService mockService = mock(MetaFormPluginService.class);
        MetaPluginParamMapper mockParamMapper = mock(MetaPluginParamMapper.class);
        ScriptEngine mockEngine = mock(ScriptEngine.class);
        PluginLoader loader = new PluginLoader(mockService, mockParamMapper, mockEngine);

        when(mockService.listByBoCode("UNKNOWN")).thenReturn(Collections.emptyList());
        List<LoadedPlugin> loaded = loader.loadPlugins("UNKNOWN", "beforeExecuteOperationTransaction");
        assertNotNull(loaded);
        assertTrue(loaded.isEmpty());
    }

    @Test
    @DisplayName("PluginLoader: null 配置返回空列表")
    void testLoaderNullConfig() {
        MetaFormPluginService mockService = mock(MetaFormPluginService.class);
        MetaPluginParamMapper mockParamMapper = mock(MetaPluginParamMapper.class);
        ScriptEngine mockEngine = mock(ScriptEngine.class);
        PluginLoader loader = new PluginLoader(mockService, mockParamMapper, mockEngine);

        when(mockService.listByBoCode("NULL")).thenReturn(null);
        List<LoadedPlugin> loaded = loader.loadPlugins("NULL", "beforeExecuteOperationTransaction");
        assertNotNull(loaded);
        assertTrue(loaded.isEmpty());
    }

    // ============ 测试辅助 ============

    /** 构造 LoadedPlugin 实例 */
    private LoadedPlugin loaded(Object instance, int execOrder) {
        LoadedPlugin lp = new LoadedPlugin();
        lp.setPluginInstance(instance);
        lp.setBaseClass("OPERATION_SERVICE");
        lp.setExecOrder(execOrder);
        lp.setParams(new ArrayList<>());
        return lp;
    }

    // ============ 测试插件嵌套类 ============

    /** 通过插件：标记 executed */
    public static class OkBeforePlugin extends AbstractOperationServicePlugin {
        @Override
        public PluginResult beforeExecuteOperationTransaction(PluginContext ctx) {
            ctx.set("executed", Boolean.TRUE);
            return PluginResult.ok();
        }
    }

    /** 第三个插件：标记 thirdExecuted */
    public static class ThirdPlugin extends AbstractOperationServicePlugin {
        @Override
        public PluginResult beforeExecuteOperationTransaction(PluginContext ctx) {
            ctx.set("thirdExecuted", Boolean.TRUE);
            return PluginResult.ok();
        }
    }

    /** 阻断插件 */
    public static class BlockPlugin extends AbstractOperationServicePlugin {
        @Override
        public PluginResult beforeExecuteOperationTransaction(PluginContext ctx) {
            return PluginResult.block("阻断测试");
        }
    }

    /** 抛异常插件 */
    public static class ExceptionPlugin extends AbstractOperationServicePlugin {
        @Override
        public PluginResult beforeExecuteOperationTransaction(PluginContext ctx) {
            throw new RuntimeException("插件抛异常");
        }
    }

    /** 顺序标记插件：将自身标记追加到 orderLog */
    public static class OrderMarkPlugin extends AbstractOperationServicePlugin {
        private final String mark;

        OrderMarkPlugin(String mark) {
            this.mark = mark;
        }

        @Override
        public PluginResult beforeExecuteOperationTransaction(PluginContext ctx) {
            Object prev = ctx.get("orderLog");
            String next = prev == null ? mark : prev + "," + mark;
            ctx.set("orderLog", next);
            return PluginResult.ok();
        }
    }

    /** 审计插件：声明 @FormParam("qty")，运行时从 billData 注入；qty<=0 阻断 */
    public static class TestAuditPlugin extends AbstractOperationServicePlugin {
        @FormParam(value = "qty", description = "数量", required = true)
        private BigDecimal qty;

        @Override
        public PluginResult beforeExecuteOperationTransaction(PluginContext ctx) {
            if (qty == null || qty.compareTo(BigDecimal.ZERO) <= 0) {
                return PluginResult.block("数量必须大于0");
            }
            return PluginResult.ok();
        }
    }
}
