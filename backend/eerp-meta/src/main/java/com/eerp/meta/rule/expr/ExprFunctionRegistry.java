package com.eerp.meta.rule.expr;

import com.eerp.meta.rule.expr.functions.AbsFunction;
import com.eerp.meta.rule.expr.functions.AndFunction;
import com.eerp.meta.rule.expr.functions.AvgFunction;
import com.eerp.meta.rule.expr.functions.CountFunction;
import com.eerp.meta.rule.expr.functions.ErrorFunction;
import com.eerp.meta.rule.expr.functions.FormatFunction;
import com.eerp.meta.rule.expr.functions.IfFunction;
import com.eerp.meta.rule.expr.functions.LenFunction;
import com.eerp.meta.rule.expr.functions.LookupFunction;
import com.eerp.meta.rule.expr.functions.LowerFunction;
import com.eerp.meta.rule.expr.functions.MaxFunction;
import com.eerp.meta.rule.expr.functions.MinFunction;
import com.eerp.meta.rule.expr.functions.NotFunction;
import com.eerp.meta.rule.expr.functions.NowFunction;
import com.eerp.meta.rule.expr.functions.OrFunction;
import com.eerp.meta.rule.expr.functions.RoundFunction;
import com.eerp.meta.rule.expr.functions.SumFunction;
import com.eerp.meta.rule.expr.functions.UpperFunction;

import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 函数注册表。
 *
 * <p>注册全部内置函数：SUM/COUNT/AVG/MAX/MIN/IF/AND/OR/NOT/LOOKUP/ERROR/ROUND/ABS/LEN/
 * UPPER/LOWER/NOW/FORMAT。函数名大小写不敏感（统一大写存储）。</p>
 *
 * <p>对齐设计文档 08 §5.4 11 内置函数 + 任务规范扩展（IF/AND/OR/NOT/ERROR/LEN/UPPER/
 * LOWER/FORMAT）。沙箱白名单即本注册表的 keySet，未注册函数调用会被
 * {@link ExprAstVisitor} 拒绝（抛 ExprException）。</p>
 */
public class ExprFunctionRegistry {

    private final Map<String, ExprFunction> functions = new ConcurrentHashMap<>();

    public ExprFunctionRegistry() {
        registerBuiltins();
    }

    /** 注册函数（name 转大写） */
    public void register(ExprFunction function) {
        if (function == null || function.name() == null) {
            return;
        }
        functions.put(function.name().toUpperCase(), function);
    }

    /** 按名取函数 */
    public ExprFunction get(String name) {
        if (name == null) {
            return null;
        }
        return functions.get(name.toUpperCase());
    }

    /** 是否存在 */
    public boolean exists(String name) {
        return name != null && functions.containsKey(name.toUpperCase());
    }

    /** 已注册函数名集合（大写） */
    public Set<String> names() {
        return functions.keySet();
    }

    private void registerBuiltins() {
        register(new SumFunction());
        register(new CountFunction());
        register(new AvgFunction());
        register(new MaxFunction());
        register(new MinFunction());
        register(new IfFunction());
        register(new AndFunction());
        register(new OrFunction());
        register(new NotFunction());
        register(new LookupFunction());
        register(new ErrorFunction());
        register(new RoundFunction());
        register(new AbsFunction());
        register(new LenFunction());
        register(new UpperFunction());
        register(new LowerFunction());
        register(new NowFunction());
        register(new FormatFunction());
    }
}
