package com.eerp.meta.writeback.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.eerp.meta.writeback.entity.MetaWritebackField;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;

/**
 * 反写字段映射 Mapper
 */
@Mapper
public interface MetaWritebackFieldMapper extends BaseMapper<MetaWritebackField> {

    @Select("SELECT * FROM meta_writeback_field WHERE rule_code = #{ruleCode} ORDER BY item_seq ASC")
    List<MetaWritebackField> listByRuleCode(@Param("ruleCode") String ruleCode);
}
