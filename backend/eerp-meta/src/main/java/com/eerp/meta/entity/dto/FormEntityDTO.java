package com.eerp.meta.entity.dto;

import com.eerp.meta.field.entity.MetaFormField;
import lombok.Data;

import java.util.List;

/**
 * 表单实体 DTO（包含实体下所有字段）
 */
@Data
public class FormEntityDTO {

    private Long id;

    /** 所属业务对象编码 */
    private String boCode;

    /** 实体编码（如 sal_order / sal_order_goods / sal_order_goods_assign） */
    private String entityCode;

    /** 实体名称（如 单据头 / 明细 / 指定用料） */
    private String entityName;

    /** 实体类型：main主表/sub子表/grandchild孙表 */
    private String entityType;

    /** 层级（0主 1子 2孙） */
    private Integer entityLevel;

    /** 物理表名 */
    private String tableName;

    /** 父实体编码（子表填主表编码，孙表填子表编码） */
    private String parentEntityCode;

    /** 关联父表的外键字段（如 order_id） */
    private String linkField;

    /** 页签排序 */
    private Integer sortIndex;

    /** 实体下字段列表 */
    private List<MetaFormField> fields;
}
