package com.eerp.meta.entity.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.eerp.meta.entity.entity.MetaFormEntity;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;

/**
 * 表单实体 Mapper
 */
@Mapper
public interface MetaFormEntityMapper extends BaseMapper<MetaFormEntity> {

    @Select("SELECT * FROM meta_form_entity WHERE bo_code = #{boCode} ORDER BY entity_level ASC, sort_index ASC")
    List<MetaFormEntity> listByBoCode(@Param("boCode") String boCode);

    @Select("SELECT * FROM meta_form_entity WHERE bo_code = #{boCode} AND entity_code = #{entityCode} LIMIT 1")
    MetaFormEntity getByBoCodeAndEntityCode(@Param("boCode") String boCode,
                                            @Param("entityCode") String entityCode);
}
