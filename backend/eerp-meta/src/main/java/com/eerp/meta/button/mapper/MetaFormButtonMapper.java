package com.eerp.meta.button.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.eerp.meta.button.entity.MetaFormButton;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;

/**
 * 表单按钮绑定 Mapper
 */
@Mapper
public interface MetaFormButtonMapper extends BaseMapper<MetaFormButton> {

    @Select("SELECT * FROM meta_form_button WHERE bo_code = #{boCode} ORDER BY sort_index ASC")
    List<MetaFormButton> listByBoCode(@Param("boCode") String boCode);
}
