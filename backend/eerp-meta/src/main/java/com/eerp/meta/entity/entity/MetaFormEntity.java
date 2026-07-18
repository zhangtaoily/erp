package com.eerp.meta.entity.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import com.eerp.common.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * 实体层级（主/子/孙三级嵌套）
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("meta_form_entity")
public class MetaFormEntity extends BaseEntity {

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

    /** 该表无审计字段，排除映射 */
    @TableField(exist = false)
    private String createBy;

    @TableField(exist = false)
    private LocalDateTime createTime;

    @TableField(exist = false)
    private String updateBy;

    @TableField(exist = false)
    private LocalDateTime updateTime;
}
