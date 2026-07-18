package com.eerp.integration.wf;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 工作流对接实例实体（对应 wf_instance 表）。
 *
 * <p>wf_instance 表无公共审计字段，故独立声明，不继承 BaseEntity。
 * 字段对齐 database/schema/00-平台元数据表.sql：
 * id / instance_id(本地实例ID) / request_id(外部工作流实例ID，即 wf_request_id) /
 * bill_type(=bo_code) / bill_id / status / submit_by / submit_time / callback_time。</p>
 */
@Data
@TableName("wf_instance")
public class WfInstanceEntity {

    @TableId(type = IdType.ASSIGN_ID)
    private Long id;

    /** 本地实例ID */
    private Long instanceId;

    /** 外部工作流实例ID（即 wf_request_id） */
    private String requestId;

    /** 单据类型（bo_code） */
    private String billType;

    /** 单据ID */
    private Long billId;

    /** 审批状态：approving审批中/approved通过/rejected驳回/canceled已取消 */
    private String status;

    /** 提交人 */
    private String submitBy;

    /** 提交时间 */
    private LocalDateTime submitTime;

    /** 工作流回调时间 */
    private LocalDateTime callbackTime;
}
