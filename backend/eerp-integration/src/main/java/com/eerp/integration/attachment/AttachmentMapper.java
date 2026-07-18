package com.eerp.integration.attachment;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Mapper;

/**
 * 附件 Mapper（MyBatis-Plus BaseMapper）。
 *
 * <p>当前 {@link AttachmentServiceImpl} 基于 JdbcTemplate 实现，
 * 此 Mapper 供后续扩展或 MyBatis-Plus 通用查询使用。</p>
 */
@Mapper
public interface AttachmentMapper extends BaseMapper<AttachmentEntity> {
}
