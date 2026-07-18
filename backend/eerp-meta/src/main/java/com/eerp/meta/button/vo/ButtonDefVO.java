package com.eerp.meta.button.vo;

import lombok.Data;

/**
 * 按钮定义 VO（对齐前端 ButtonDef，聚合 MetaButton + MetaFormButton 可用性矩阵）
 */
@Data
public class ButtonDefVO {

    private Long id;

    /** 业务对象编码 */
    private String boCode;

    /** 按钮编码（save/submit/audit/reject/revoke/delete/close/cancel/change/push/print/copy...） */
    private String buttonCode;

    /** 按钮名称 */
    private String buttonName;

    /** 图标 */
    private String icon;

    /** 位置：form表单/list列表/both均显示 */
    private String position;

    /** 排序 */
    private Integer sortIndex;

    /** 是否自定义按钮（0否 1是） */
    private Integer isCustom;

    /** 是否二次确认（0否 1是） */
    private Integer needConfirm;

    /** 二次确认提示 */
    private String confirmMsg;

    /** 绑定的插件事件（如 BarItemClick / OnCustomButtonClick） */
    private String bindPlugin;

    /** 可用性矩阵 JSON（5状态对应的 enabled/disabled/hidden/readonly） */
    private String availabilityJson;
}
