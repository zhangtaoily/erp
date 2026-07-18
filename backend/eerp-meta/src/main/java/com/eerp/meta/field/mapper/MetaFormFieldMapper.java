package com.eerp.meta.field.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.eerp.meta.field.entity.MetaFormField;
import org.apache.ibatis.annotations.Mapper;

/**
 * 表单字段 Mapper
 * <p>查询统一走 MyBatis-Plus 的 lambdaQuery 链式 API（在 ServiceImpl 中），
 * 此处仅保留 BaseMapper 默认能力。</p>
 */
@Mapper
public interface MetaFormFieldMapper extends BaseMapper<MetaFormField> {
}
