package com.eerp.meta.enum_.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import com.eerp.common.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * 枚举项
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("meta_enum_item")
public class MetaEnumItem extends BaseEntity {

    /** 枚举编码 */
    private String enumCode;

    /** 枚举值 */
    private Integer itemValue;

    /** 枚举名 */
    private String itemName;

    /** 色系（如 info/primary/warning/success/danger） */
    private String itemColor;

    /** 排序 */
    private Integer sortIndex;

    /** 是否默认 */
    private Integer isDefault;

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
