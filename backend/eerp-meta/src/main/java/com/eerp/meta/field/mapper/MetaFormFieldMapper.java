package com.eerp.meta.field.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.eerp.meta.field.entity.MetaFormField;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;

/**
 * 表单字段 Mapper
 */
@Mapper
public interface MetaFormFieldMapper extends BaseMapper<MetaFormField> {

    @Select("SELECT * FROM meta_form_field WHERE entity_code = #{entityCode} ORDER BY sort_index ASC")
    List<MetaFormField> listByEntityCode(@Param("entityCode") String entityCode);
}
