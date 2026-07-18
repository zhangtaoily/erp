package com.eerp.meta.list.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.eerp.meta.list.entity.MetaListColumn;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;

/**
 * 列表列定义 Mapper
 */
@Mapper
public interface MetaListColumnMapper extends BaseMapper<MetaListColumn> {

    @Select("SELECT * FROM meta_list_column WHERE bo_code = #{boCode} AND is_enable = 1 ORDER BY sort_index ASC")
    List<MetaListColumn> listByBoCode(@Param("boCode") String boCode);
}
