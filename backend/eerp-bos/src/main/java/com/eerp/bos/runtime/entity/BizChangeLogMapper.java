package com.eerp.bos.runtime.entity;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Mapper;

/**
 * 字段级变更日志 Mapper
 */
@Mapper
public interface BizChangeLogMapper extends BaseMapper<BizChangeLog> {
}
