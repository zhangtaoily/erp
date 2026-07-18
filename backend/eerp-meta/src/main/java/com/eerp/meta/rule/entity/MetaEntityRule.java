package com.eerp.meta.rule.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import com.eerp.common.domain.BaseEntity;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.util.List;

/**
 * 实体服务规则定义（声明式规则引擎）
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("meta_entity_rule")
public class MetaEntityRule extends BaseEntity {

    /** 规则编码（唯一） */
    private String ruleCode;

    /** 规则名称 */
    private String ruleName;

    /** 业务对象编码 */
    private String boCode;

    /** 实体编码（主表/子表） */
    private String entityCode;

    /** 规则类型：validate校验/calc计算/linkage联动/available可用量 */
    private String ruleType;

    /** 触发事件：OnBeforeSave/OnAfterSave/OnBeforeSubmit/OnBeforeAudit/OnFieldValueChange */
    private String triggerEvent;

    /** 触发字段（linkage类型必填，如 mat_id） */
    private String triggerField;

    /** 优先级（升序执行，先于脚本插件） */
    private Integer priority;

    /** 启用状态：0停用 1启用 */
    private Integer isEnabled;

    /** 备注 */
    private String remark;

    /** 规则条目列表（瞬态，由服务层加载填充，不映射数据库列） */
    @TableField(exist = false)
    private List<MetaEntityRuleItem> items;
}
