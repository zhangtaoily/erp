package com.eerp.bos.rule;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 反写失败补偿日志 Mapper。
 *
 * <p>对齐设计文档 08 §5.5 / §3.6。提供基础 CRUD + 定时任务扫描查询。</p>
 */
@Mapper
public interface BizWritebackLogMapper extends BaseMapper<BizWritebackLog> {

    /**
     * 查询待重试的失败任务（status=PENDING 且 retry_count < max_retry 且 next_retry_time <= now）。
     *
     * @param now 当前时间
     * @return 待重试日志列表
     */
    @Select("SELECT * FROM biz_writeback_log " +
            "WHERE status = 'PENDING' AND retry_count < max_retry " +
            "AND (next_retry_time IS NULL OR next_retry_time <= #{now}) " +
            "ORDER BY created_time ASC")
    List<BizWritebackLog> listPendingForRetry(@Param("now") LocalDateTime now);

    /**
     * 重试成功：标记 SUCCESS 并累加 retry_count。
     */
    @Update("UPDATE biz_writeback_log SET status='SUCCESS', retry_count=retry_count+1, " +
            "error_msg=#{errorMsg}, updated_time=#{now} WHERE id=#{id}")
    int markSuccess(@Param("id") Long id, @Param("errorMsg") String errorMsg, @Param("now") LocalDateTime now);

    /**
     * 重试失败：累加 retry_count，更新错误信息与下次重试时间。
     */
    @Update("UPDATE biz_writeback_log SET retry_count=retry_count+1, " +
            "error_msg=#{errorMsg}, next_retry_time=#{nextRetryTime}, updated_time=#{now} WHERE id=#{id}")
    int markRetryFailed(@Param("id") Long id, @Param("errorMsg") String errorMsg,
                        @Param("nextRetryTime") LocalDateTime nextRetryTime, @Param("now") LocalDateTime now);

    /**
     * 标记终态 FAILED（超过 max_retry）。
     */
    @Update("UPDATE biz_writeback_log SET status='FAILED', retry_count=max_retry, " +
            "error_msg=#{errorMsg}, updated_time=#{now} WHERE id=#{id}")
    int markTerminallyFailed(@Param("id") Long id, @Param("errorMsg") String errorMsg,
                             @Param("now") LocalDateTime now);
}
