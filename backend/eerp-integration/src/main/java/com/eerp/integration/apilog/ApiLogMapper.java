package com.eerp.integration.apilog;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Mapper;

/**
 * API 日志 Mapper（MyBatis-Plus BaseMapper）。
 *
 * <p>当前 {@link ApiLogServiceImpl} 基于 JdbcTemplate 实现，
 * 此 Mapper 供后续扩展或 MyBatis-Plus 通用查询使用。</p>
 */
@Mapper
public interface ApiLogMapper extends BaseMapper<ApiLogEntity> {
}
