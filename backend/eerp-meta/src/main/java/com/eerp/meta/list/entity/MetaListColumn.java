package com.eerp.meta.list.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import com.eerp.common.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * 列表列定义
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("meta_list_column")
public class MetaListColumn extends BaseEntity {

    /** 业务对象编码 */
    private String boCode;

    /** 字段编码 */
    private String fieldCode;

    /** 列名 */
    private String fieldName;

    /** 所属实体 */
    private String entityCode;

    /** 控件类型（用于格式化：amount/qty/date/enum） */
    private String ctrlType;

    /** 是否显示 */
    private Integer isShow;

    /** 冻结列：none不冻结/left左冻结/right右冻结 */
    private String isFixed;

    /** 是否列尾合计 */
    private Integer isSum;

    /** 是否列尾平均 */
    private Integer isAvg;

    /** 列宽 */
    private Integer colWidth;

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
