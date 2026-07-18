package com.eerp.meta.list.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.eerp.meta.list.entity.MetaQueryField;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;

/**
 * 查询字段 Mapper
 */
@Mapper
public interface MetaQueryFieldMapper extends BaseMapper<MetaQueryField> {

    @Select("SELECT * FROM meta_query_field WHERE bo_code = #{boCode} AND is_enable = 1 ORDER BY sort_index ASC")
    List<MetaQueryField> listByBoCode(@Param("boCode") String boCode);
}
