package com.eerp.meta.layout.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.eerp.meta.layout.entity.MetaFormLayout;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;

/**
 * 表单布局 Mapper
 */
@Mapper
public interface MetaFormLayoutMapper extends BaseMapper<MetaFormLayout> {

    @Select("SELECT * FROM meta_form_layout WHERE bo_code = #{boCode} ORDER BY is_default DESC, id ASC")
    List<MetaFormLayout> listByBoCode(@Param("boCode") String boCode);

    @Select("SELECT * FROM meta_form_layout WHERE bo_code = #{boCode} AND is_default = 1 LIMIT 1")
    MetaFormLayout getDefaultByBoCode(@Param("boCode") String boCode);
}
