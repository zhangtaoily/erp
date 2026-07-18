package com.eerp.meta.code.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import com.eerp.common.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 编码规则定义（段式编排）
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("meta_code_rule")
public class MetaCodeRule extends BaseEntity {

    /** 规则编码（唯一） */
    private String ruleCode;

    /** 规则名称 */
    private String ruleName;

    /** 业务对象编码 */
    private String boCode;

    /** 适用组织（空=全组织通用） */
    private Long orgId;

    /** 段定义JSON（数组，每段含 type/value/format/digits/var_code/sort） */
    private String segmentsJson;

    /** 流水重置类型：none不重置/year按年/month按月/org_year按组织+年 */
    private String resetType;

    /** 是否允许手动录入（0否 1是） */
    private Integer isManual;

    /** 状态：0停用 1启用 */
    private Integer status;

    /** 备注 */
    private String remark;
}
