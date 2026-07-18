package com.eerp.plugin.validator;

import com.eerp.plugin.context.PluginContext;

/**
 * 校验器基类（对齐 PRD 6.2.8 / GAP-D05-006）。
 *
 * <p>仅在 {@code OnAddValidators} 阶段挂载。校验失败时调用
 * {@link PluginContext#addValidationError(String)} 收集错误信息。</p>
 */
public abstract class AbstractValidator {

    /**
     * 校验入口。
     *
     * @param ctx 插件上下文
     */
    public abstract void validate(PluginContext ctx);
}
