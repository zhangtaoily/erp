package com.eerp.bos.rule;

import com.eerp.meta.rule.entity.MetaEntityRuleItem;
import com.eerp.meta.rule.expr.ExprContext;
import com.eerp.meta.rule.expr.ExprEvaluator;
import com.eerp.meta.rule.expr.ExprException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

/**
 * 规则条目执行器（单条 item 求值）。
 *
 * <p>委托 {@link ExprEvaluator} 对单个 {@link MetaEntityRuleItem} 的 actionExpr 求值。
 * 由 {@link RuleEngineImpl#executeRule} 调用，隔离单条 item 的求值逻辑，
 * 便于后续扩展（如预编译缓存、沙箱校验等）。</p>
 */
@Service
public class RuleItemExecutor {

    @Autowired
    private ExprEvaluator exprEvaluator;

    /**
     * 执行单条规则项。
     *
     * @param item 规则项（含 actionExpr 表达式）
     * @param ctx  表达式上下文
     * @return 求值结果（validate 返回 Boolean；linkage 返回赋值后的值；aggregate 返回聚合值）
     * @throws ExprException 表达式解析或求值错误（含 error() 函数抛出）
     */
    public Object execute(MetaEntityRuleItem item, ExprContext ctx) {
        if (item == null) {
            return null;
        }
        String expr = item.getActionExpr();
        if (expr == null || expr.trim().isEmpty()) {
            // actionExpr 为空时回退到 conditionExpr（兼容配置）
            expr = item.getConditionExpr();
        }
        return exprEvaluator.evaluate(expr, ctx);
    }
}
