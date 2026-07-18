package com.eerp.bos.runtime.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import com.eerp.common.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * 业务操作日志（状态变更全记录），对应表 biz_op_log
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("biz_op_log")
public class BizOpLog extends BaseEntity {

    /** 业务对象编码 */
    private String boCode;

    /** 单据ID */
    private Long billId;

    /** 单据编号 */
    private String billCode;

    /** 操作类型（save/submit/audit/revoke/reject/delete/close/cancel/change/push/print） */
    private String opType;

    /** 操作前状态 */
    private Integer fromState;

    /** 操作后状态 */
    private Integer toState;

    /** 操作说明/原因 */
    private String opRemark;

    /** 操作人 */
    private String opBy;

    /** 操作时间 */
    private LocalDateTime opTime;

    /** IP */
    private String ip;

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
