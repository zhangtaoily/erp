package com.eerp.meta.plugin.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import com.eerp.common.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * Java类插件传入参数（自描述模型：参数零配置，全部由注解自动发现，运行时系统自动注入）
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("meta_plugin_param")
public class MetaPluginParam extends BaseEntity {

    /** 插件编码 */
    private String pluginCode;

    /** 参数键（注解自动发现）：form类型=单据字段编码；behavior类型=参数名 */
    private String paramKey;

    /** 参数标签（注解自动发现，来自注解 label 属性） */
    private String paramLabel;

    /** 参数类型（注解自动发现）：form表单参数 / behavior行为参数 */
    private String paramType;

    /** 运行时值（注解自动发现，来自 @BehaviorParam.defaultValue） */
    private String defaultValue;

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
