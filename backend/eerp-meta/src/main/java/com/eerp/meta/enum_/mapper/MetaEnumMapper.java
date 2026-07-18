package com.eerp.meta.enum_.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.eerp.meta.enum_.entity.MetaEnum;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

/**
 * 枚举 Mapper
 */
@Mapper
public interface MetaEnumMapper extends BaseMapper<MetaEnum> {

    @Select("SELECT * FROM meta_enum WHERE enum_code = #{enumCode} LIMIT 1")
    MetaEnum getByEnumCode(@Param("enumCode") String enumCode);
}
