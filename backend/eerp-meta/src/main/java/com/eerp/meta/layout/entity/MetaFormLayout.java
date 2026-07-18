package com.eerp.meta.layout.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import com.eerp.common.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * 表单布局元数据
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("meta_form_layout")
public class MetaFormLayout extends BaseEntity {

    /** 业务对象编码 */
    private String boCode;

    /** 布局编码 */
    private String layoutCode;

    /** 布局名称 */
    private String layoutName;

    /** 布局JSON（页签/分组/字段位置/列宽） */
    private String layoutJson;

    /** 是否默认布局 */
    private Integer isDefault;

    /** update_by 列不存在，排除映射 */
    @TableField(exist = false)
    private String updateBy;

    /** update_time 列不存在，排除映射 */
    @TableField(exist = false)
    private LocalDateTime updateTime;
}
