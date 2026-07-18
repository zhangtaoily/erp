package com.eerp.bos.runtime.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import com.eerp.common.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * 字段级变更日志（变更单留痕），对应表 biz_change_log
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("biz_change_log")
public class BizChangeLog extends BaseEntity {

    /** 业务对象编码 */
    private String boCode;

    /** 单据ID */
    private Long billId;

    /** 实体编码 */
    private String entityCode;

    /** 行ID */
    private Long lineId;

    /** 字段编码 */
    private String fieldCode;

    /** 字段名 */
    private String fieldName;

    /** 旧值 */
    private String oldValue;

    /** 新值 */
    private String newValue;

    /** 变更单号 */
    private String changeCode;

    /** 变更原因 */
    private String changeReason;

    /** 变更人 */
    private String changeBy;

    /** 变更时间 */
    private LocalDateTime changeTime;

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
