package com.eerp.bos.rule;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 反写失败补偿日志实体（对应表 biz_writeback_log）。
 *
 * <p>对齐设计文档 08 §5.5 / §3.6。记录 ASYNC 反写失败任务供定时任务重试。</p>
 *
 * <p>状态流转：PENDING（初次记录）→ SUCCESS（重试成功）/ FAILED（重试中或超过 max_retry 终态）。</p>
 */
@Data
@TableName("biz_writeback_log")
public class BizWritebackLog {

    /** 主键（雪花ID） */
    @TableId(type = IdType.ASSIGN_ID)
    private Long id;

    /** 反写规则ID（关联 meta_writeback_rule.id） */
    private Long ruleId;

    /** 反写规则编码（冗余便于排查） */
    private String ruleCode;

    /** 源单据ID（下游单据） */
    private Long srcBillId;

    /** 源单据业务对象编码 */
    private String srcBoCode;

    /** 目标单据业务对象编码（上游单） */
    private String targetBoCode;

    /** 目标单据ID（上游单） */
    private Long targetBillId;

    /** 状态：PENDING/SUCCESS/FAILED */
    private String status;

    /** 已重试次数 */
    private Integer retryCount;

    /** 最大重试次数（默认5） */
    private Integer maxRetry;

    /** 最后一次错误信息 */
    private String errorMsg;

    /** 下次重试时间（指数退避：retry_count*60s） */
    private LocalDateTime nextRetryTime;

    /** 创建时间 */
    private LocalDateTime createdTime;

    /** 更新时间 */
    private LocalDateTime updatedTime;

    /** 该表无审计字段 create_by 等，排除映射 */
    @TableField(exist = false)
    private String createBy;

    @TableField(exist = false)
    private LocalDateTime createTime;

    @TableField(exist = false)
    private String updateBy;

    @TableField(exist = false)
    private LocalDateTime updateTime;

    /** 状态常量 */
    public static final String STATUS_PENDING = "PENDING";
    public static final String STATUS_SUCCESS = "SUCCESS";
    public static final String STATUS_FAILED = "FAILED";
}
