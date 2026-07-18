package com.eerp.bos.button;

import lombok.Data;

/**
 * 按钮可用性 DTO（供前端工具栏渲染）
 */
@Data
public class ButtonAvailability {

    /** 按钮编码 */
    private String buttonCode;

    /** 按钮名称 */
    private String buttonName;

    /** 可用性档位 */
    private ButtonLevel level;

    /** 显示标签（如「关闭」/「已关闭」动态切换） */
    private String label;

    /** 禁用/隐藏原因 */
    private String reason;

    /** 排序号 */
    private Integer orderNo;

    public static ButtonAvailability enabled(String code, String name, Integer order) {
        ButtonAvailability a = new ButtonAvailability();
        a.buttonCode = code;
        a.buttonName = name;
        a.level = ButtonLevel.ENABLED;
        a.label = name;
        a.orderNo = order;
        return a;
    }

    public static ButtonAvailability disabled(String code, String name, String reason, Integer order) {
        ButtonAvailability a = new ButtonAvailability();
        a.buttonCode = code;
        a.buttonName = name;
        a.level = ButtonLevel.DISABLED;
        a.label = name;
        a.reason = reason;
        a.orderNo = order;
        return a;
    }

    public static ButtonAvailability hidden(String code, String name, String reason, Integer order) {
        ButtonAvailability a = new ButtonAvailability();
        a.buttonCode = code;
        a.buttonName = name;
        a.level = ButtonLevel.HIDDEN;
        a.label = name;
        a.reason = reason;
        a.orderNo = order;
        return a;
    }

    public static ButtonAvailability readonly(String code, String name, String reason, Integer order) {
        ButtonAvailability a = new ButtonAvailability();
        a.buttonCode = code;
        a.buttonName = name;
        a.level = ButtonLevel.READONLY;
        a.label = name;
        a.reason = reason;
        a.orderNo = order;
        return a;
    }
}
