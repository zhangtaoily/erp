package com.eerp.meta.rule.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.eerp.meta.rule.entity.MetaEntityRuleItem;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;

/**
 * 实体服务规则条目 Mapper
 */
@Mapper
public interface MetaEntityRuleItemMapper extends BaseMapper<MetaEntityRuleItem> {

    @Select("SELECT * FROM meta_entity_rule_item WHERE rule_code = #{ruleCode} ORDER BY item_seq ASC")
    List<MetaEntityRuleItem> listByRuleCode(@Param("ruleCode") String ruleCode);
}
