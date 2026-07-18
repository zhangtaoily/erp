package com.eerp.meta.code.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.eerp.meta.code.entity.MetaCodeRule;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

/**
 * 编码规则 Mapper
 */
@Mapper
public interface MetaCodeRuleMapper extends BaseMapper<MetaCodeRule> {

    @Select("SELECT * FROM meta_code_rule WHERE bo_code = #{boCode} AND status = 1 LIMIT 1")
    MetaCodeRule getByBoCode(@Param("boCode") String boCode);
}
