package com.eerp.meta.enum_.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import com.eerp.common.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * 枚举定义
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("meta_enum")
public class MetaEnum extends BaseEntity {

    /** 枚举编码（唯一，如 PACT_STATE） */
    private String enumCode;

    /** 枚举名称 */
    private String enumName;

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
