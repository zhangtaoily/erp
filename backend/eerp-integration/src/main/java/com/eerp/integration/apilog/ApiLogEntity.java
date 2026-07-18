package com.eerp.integration.apilog;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * API 调用日志实体（对应 sys_api_log 表）。
 *
 * <p>sys_api_log 表无公共审计字段，故独立声明，不继承 BaseEntity。</p>
 */
@Data
@TableName("sys_api_log")
public class ApiLogEntity {

    @TableId(type = IdType.ASSIGN_ID)
    private Long id;

    /** 接口分类：wf/mes/qms/report/tax/bank/other */
    private String category;

    /** 接口类型：plugin/wf/third_party */
    private String apiType;

    /** 来源编码（插件编码/工作流编码） */
    private String sourceCode;

    /** 业务对象编码 */
    private String boCode;

    /** 单据ID */
    private Long billId;

    /** 请求URL */
    private String apiUrl;

    /** HTTP方法 */
    private String apiMethod;

    /** 请求体 */
    private String requestBody;

    /** 响应体 */
    private String responseBody;

    /** HTTP状态码 */
    private Integer statusCode;

    /** 耗时(毫秒) */
    private Integer durationMs;

    /** 是否成功（0否 1是） */
    private Integer isSuccess;

    /** 错误信息 */
    private String errorMsg;

    /** 调用人 */
    private String callBy;

    /** 调用时间 */
    private LocalDateTime callTime;
}
