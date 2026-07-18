package com.eerp.meta.bo.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.eerp.meta.bo.entity.MetaBusinessObject;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

/**
 * 业务对象 Mapper
 */
@Mapper
public interface MetaBusinessObjectMapper extends BaseMapper<MetaBusinessObject> {

    @Select("SELECT * FROM meta_business_object WHERE bo_code = #{boCode} LIMIT 1")
    MetaBusinessObject getByBoCode(@Param("boCode") String boCode);
}
