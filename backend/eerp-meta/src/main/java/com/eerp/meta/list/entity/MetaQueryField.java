package com.eerp.meta.list.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import com.eerp.common.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * 查询字段配置（14种运算符）
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("meta_query_field")
public class MetaQueryField extends BaseEntity {

    /** 业务对象编码 */
    private String boCode;

    /** 字段编码 */
    private String fieldCode;

    /** 字段名 */
    private String fieldName;

    /** 是否普通查询字段（列表顶部常用筛选区） */
    private Integer isCommon;

    /** 是否高级查询字段（弹窗查询构造器） */
    private Integer isAdvanced;

    /** 支持的运算符（逗号分隔：eq/ne/gt/ge/lt/le/like/not_like/begin_with/end_with/is_null/is_not_null/in/between） */
    private String operators;

    /** 默认运算符 */
    private String defaultOp;

    /** 排序 */
    private Integer sortIndex;

    /** 是否启用 */
    private Integer isEnable;

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
