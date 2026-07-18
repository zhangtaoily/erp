package com.eerp.bos.statemachine.executors;

import com.eerp.bos.code.CodeGenerateService;
import com.eerp.bos.statemachine.AbstractStateTransitionExecutor;
import com.eerp.meta.rule.expr.ExprContext;
import com.eerp.meta.statemachine.entity.MetaStateTransition;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Map;

/**
 * 保存流转执行器（actionName=save）。
 * <p>
 * postAction：调用 {@link CodeGenerateService#generateCode(String)} 生成单据编码，
 * 写入主表数据 code/bill_no 字段，并回写 extras 供上层落库。
 * 对齐设计文档 02 §6.1（t1: 0暂存 → 1已创建，post_action=生成编码）。
 */
@Service
public class SaveTransitionExecutor extends AbstractStateTransitionExecutor {

    @Autowired
    private CodeGenerateService codeGenerateService;

    public SaveTransitionExecutor() {
        this.actionName = "save";
    }

    @Override
    public String getActionName() {
        return actionName;
    }

    @Override
    public void postAction(MetaStateTransition transition, Long billId, ExprContext exprCtx, Map<String, Object> extras) {
        // 先执行默认 post_action 表达式
        super.postAction(transition, billId, exprCtx, extras);

        // 生成单据编码
        String boCode = resolveBoCode(exprCtx, extras);
        if (boCode == null) {
            return;
        }
        String code = codeGenerateService.generateCode(boCode);

        // 回写 extras 供上层落库
        if (extras != null) {
            extras.put("code", code);
            extras.put("billNo", code);
        }
        // 写入主表数据
        if (exprCtx != null && exprCtx.getRootData() != null) {
            exprCtx.getRootData().put("code", code);
            exprCtx.getRootData().put("bill_no", code);
        }
    }

    /** 从 extras 或主表数据解析 boCode */
    private String resolveBoCode(ExprContext exprCtx, Map<String, Object> extras) {
        if (extras != null) {
            Object fromExtras = extras.get("boCode");
            if (fromExtras == null) {
                fromExtras = extras.get("bo_code");
            }
            if (fromExtras instanceof String) {
                return (String) fromExtras;
            }
        }
        if (exprCtx != null && exprCtx.getRootData() != null) {
            Object fromRoot = exprCtx.getRootData().get("boCode");
            if (fromRoot == null) {
                fromRoot = exprCtx.getRootData().get("bo_code");
            }
            if (fromRoot instanceof String) {
                return (String) fromRoot;
            }
        }
        return null;
    }
}
