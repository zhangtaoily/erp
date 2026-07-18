package com.eerp.meta.statemachine.dto;

import lombok.Data;

/**
 * 状态节点 DTO
 */
@Data
public class StateNodeDTO {

    private Long id;

    /** 状态机ID */
    private Long machineId;

    /** 状态值（0暂存 1已创建 2已提交 3已审核 4已驳回） */
    private Integer stateValue;

    /** 状态名 */
    private String stateName;

    /** 状态色 hex */
    private String stateColor;

    /** 是否初始状态 */
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
}
