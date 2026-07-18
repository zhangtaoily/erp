package com.eerp.meta.field.dto;

import lombok.Data;

/**
 * 字段 DTO（对齐前端 FormField）
 */
@Data
public class FormFieldDTO {

    private Long id;

    /** 所属业务对象编码 */
    private String boCode;

    /** 所属实体编码 */
    private String entityCode;

    /** 字段编码（即物理列名） */
    private String fieldCode;

    /** 字段显示名 */
    private String fieldName;

    /** 字段数据类型：text/number/date/datetime/enum/ref/bool/amount/qty/attachment */
    private String fieldType;

    /** 控件类型：text/textarea/number/date/datetime/select/ref/amount/qty/checkbox/attachment/subtable/grandchild */
    private String ctrlType;

    /** 数据库类型（varchar/decimal/datetime/int） */
    private String dataType;

    /** 长度 */
    private Integer dataLength;

    /** 精度（总位数） */
    private Integer dataPrecision;

    /** 小数位 */
    private Integer dataScale;

    /** 是否必填（0否 1是） */
    private Integer isRequired;

    /** 是否只读（0否 1是） */
    private Integer isReadonly;

    /** 是否隐藏（0否 1是） */
    private Integer isHidden;

    /** 是否系统字段（不可删，如 id/pact_state/create_by） */
    private Integer isSystem;

    /** 默认值（可为基础数据值 TODAY/CNY/1 或表达式） */
    private String defaultValue;

    /** 校验规则表达式 */
    private String validateRule;

    /** 引用基础资料的业务对象编码（field_type=ref 时填写） */
    private String refBoCode;

    /** 枚举编码（field_type=enum 时关联 meta_enum） */
    private String enumCode;

    /** 计算公式（如 qty*price，由实体服务规则calc类型执行） */
    private String formula;

    /** 汇总到主表字段（如 amount 汇总到 total_amount） */
    private String summaryTo;

    /** 字段分组（如 基本信息/汇总/系统/其他） */
    private String groupName;

    /** 列表列宽 */
    private Integer colWidth;

    /** 排序 */
    private Integer sortIndex;

    /** 备注 */
    private String remark;
}
