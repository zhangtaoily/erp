package com.eerp.meta.statemachine.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import com.eerp.common.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * 状态节点（0暂存1已创建2已提交3已审核4已驳回；关闭/取消用 is_closed/is_cancel）
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("meta_state_node")
public class MetaStateNode extends BaseEntity {

    /** 状态机ID */
    private Long machineId;

    /** 状态值（0暂存 1已创建 2已提交 3已审核 4已驳回；自定义状态码可 >=5） */
    private Integer stateValue;

    /** 状态名 */
    private String stateName;

    /** 状态色 hex（如 #909399） */
    private String stateColor;

    /** 是否初始状态（暂存为初始态） */
    private Integer isInitial;

    /** 是否终态 */
    private Integer isFinal;

    /** 该状态下单据是否可编辑 */
    private Integer isEditable;

    /** 该状态下单据是否可删除 */
    private Integer isDeletable;

    /** 画布 X 坐标 */
    private Integer posX;

    /** 画布 Y 坐标 */
    private Integer posY;

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
