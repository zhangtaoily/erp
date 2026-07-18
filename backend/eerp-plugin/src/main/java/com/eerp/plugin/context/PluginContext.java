package com.eerp.plugin.context;

import lombok.Data;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 插件运行上下文。
 *
 * <p>统一承载单据运行时上下文（业务对象、单据、操作、用户、单据数据）、插件间共享变量、
 * 额外参数与校验错误收集。插件通过方法入参获取本对象。</p>
 */
@Data
public class PluginContext {

    /** 业务对象编码 */
    private String boCode;

    /** 单据 ID */
    private Long billId;

    /** 操作类型：save/submit/audit/reject/revoke/delete/... */
    private String operation;

    /** 单据数据（主表 + 子表） */
    private Map<String, Object> billData;

    /** 用户信息：userId/userName/orgId */
    private Map<String, Object> userInfo;

    /** 插件间共享变量 */
    private Map<String, Object> variables;

    /** 额外参数 */
    private Map<String, Object> extras;

    /** 校验错误收集（OnAddValidators 阶段由校验器写入） */
    private List<String> validationErrors;

    /**
     * 获取插件间共享变量。
     *
     * @param key 变量名
     * @return 变量值；不存在返回 null
     */
    public Object get(String key) {
        return variables == null ? null : variables.get(key);
    }

    /**
     * 设置插件间共享变量。
     *
     * @param key 变量名
     * @param val 变量值
     */
    public void set(String key, Object val) {
        if (variables == null) {
            variables = new HashMap<>();
        }
        variables.put(key, val);
    }

    /** 收集校验错误 */
    public void addValidationError(String msg) {
        if (validationErrors == null) {
            validationErrors = new ArrayList<>();
        }
        validationErrors.add(msg);
    }

    /** 是否存在校验错误 */
    public boolean hasValidationErrors() {
        return validationErrors != null && !validationErrors.isEmpty();
    }
}
