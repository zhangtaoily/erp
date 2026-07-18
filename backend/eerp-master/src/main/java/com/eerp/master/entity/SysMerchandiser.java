package com.eerp.master.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import com.eerp.common.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * 跟单员主数据实体（对应表 sys_merchandiser，平铺结构，bo_code=MD_MERCHANDISER）。
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("sys_merchandiser")
public class SysMerchandiser extends BaseEntity {

    private String code;

    private Long staffId;

    private Integer enabled;

    private String auditor;

    private LocalDateTime auditTime;

    private String remark;
}
