package com.eerp.plugin.core;

import com.eerp.plugin.context.PluginContext;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

/**
 * 插件上下文工厂。
 *
 * <p>构建并初始化 {@link PluginContext}，填充业务对象、单据、操作、单据数据与用户信息，
 * 并初始化共享变量、额外参数与校验错误收集容器。</p>
 */
@Service
public class PluginContextFactory {

    /**
     * 创建插件上下文。
     *
     * @param boCode   业务对象编码
     * @param billId   单据 ID
     * @param operation 操作类型
     * @param billData 单据数据（主表 + 子表）
     * @param userInfo 用户信息（userId/userName/orgId）
     * @return 已初始化的插件上下文
     */
    public PluginContext create(String boCode, Long billId, String operation,
                                Map<String, Object> billData, Map<String, Object> userInfo) {
        PluginContext ctx = new PluginContext();
        ctx.setBoCode(boCode);
        ctx.setBillId(billId);
        ctx.setOperation(operation);
        ctx.setBillData(billData);
        ctx.setUserInfo(userInfo);
        ctx.setVariables(new HashMap<>());
        ctx.setExtras(new HashMap<>());
        ctx.setValidationErrors(new ArrayList<>());
        return ctx;
    }
}
