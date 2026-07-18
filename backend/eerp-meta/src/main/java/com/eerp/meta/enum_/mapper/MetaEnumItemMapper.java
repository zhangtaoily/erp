package com.eerp.meta.enum_.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.eerp.meta.enum_.entity.MetaEnumItem;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;

/**
 * 枚举项 Mapper
 */
@Mapper
public interface MetaEnumItemMapper extends BaseMapper<MetaEnumItem> {

    @Select("SELECT * FROM meta_enum_item WHERE enum_code = #{enumCode} ORDER BY sort_index ASC")
    List<MetaEnumItem> listByEnumCode(@Param("enumCode") String enumCode);
}
