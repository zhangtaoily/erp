package com.eerp.meta.button.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import com.eerp.common.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * 按钮定义（标准+自定义）
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("meta_button")
public class MetaButton extends BaseEntity {

    /** 按钮编码（唯一） */
    private String buttonCode;

    /** 按钮名称 */
    private String buttonName;

    /** 按钮类型：standard标准 custom自定义 */
    private String buttonType;

    /** 图标 */
    private String icon;

    /** 位置：form表单/list列表/both均显示 */
    private String location;

    /** 排序 */
    private Integer execOrder;

    /** 备注 */
    private String remark;

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
