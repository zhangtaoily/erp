package com.eerp.meta.plugin.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.eerp.meta.plugin.entity.MetaPluginParam;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;

/**
 * 插件参数 Mapper
 */
@Mapper
public interface MetaPluginParamMapper extends BaseMapper<MetaPluginParam> {

    @Select("SELECT * FROM meta_plugin_param WHERE plugin_code = #{pluginCode} ORDER BY sort_index ASC")
    List<MetaPluginParam> listByPluginCode(@Param("pluginCode") String pluginCode);
}
