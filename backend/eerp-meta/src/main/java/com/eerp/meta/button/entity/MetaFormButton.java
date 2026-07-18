package com.eerp.meta.button.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import com.eerp.common.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * 表单按钮绑定（含可用性矩阵）
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("meta_form_button")
public class MetaFormButton extends BaseEntity {

    /** 业务对象编码 */
    private String boCode;

    /** 按钮编码 */
    private String buttonCode;

    /** 可用性矩阵JSON（5状态对应的enabled/disabled/hidden/readonly） */
    private String availabilityJson;

    /** 点击触发的插件事件（如 BarItemClick） */
    private String pluginEvent;

    /** 二次确认提示 */
    private String confirmMsg;

    /** 排序 */
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
