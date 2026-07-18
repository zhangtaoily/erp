package com.eerp.meta.plugin.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.eerp.meta.plugin.entity.MetaFormPlugin;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;

/**
 * 插件绑定 Mapper
 */
@Mapper
public interface MetaFormPluginMapper extends BaseMapper<MetaFormPlugin> {

    @Select("SELECT * FROM meta_form_plugin WHERE bo_code = #{boCode} AND status = 1 ORDER BY exec_order ASC")
    List<MetaFormPlugin> listByBoCode(@Param("boCode") String boCode);
}
