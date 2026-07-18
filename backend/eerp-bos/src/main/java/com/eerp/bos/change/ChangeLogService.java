package com.eerp.bos.change;

import com.eerp.common.id.SnowflakeIdGenerator;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.LinkedHashSet;
import java.util.Map;
import java.util.Objects;
import java.util.Set;

/**
 * 字段级变更日志服务：对比新旧数据，对变更字段写入 biz_change_log
 */
@Service
public class ChangeLogService {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Autowired
    private SnowflakeIdGenerator snowflakeIdGenerator;

    /**
     * 记录主表字段变更日志
     *
     * @param boCode   业务对象编码
     * @param billId   单据ID
     * @param oldData  旧数据（主表字段映射）
     * @param newData  新数据（主表字段映射）
     * @param userId   操作用户ID
     * @param userName 操作用户名
     */
    @Transactional(rollbackFor = Exception.class)
    public void logChange(String boCode, Long billId, Map<String, Object> oldData, Map<String, Object> newData,
                          Long userId, String userName) {
        if (oldData == null || newData == null) {
            return;
        }
        Set<String> keys = new LinkedHashSet<>();
        keys.addAll(oldData.keySet());
        keys.addAll(newData.keySet());

        for (String fieldCode : keys) {
            if (fieldCode == null) {
                continue;
            }
            // 系统字段与主键不记录变更
            if ("id".equals(fieldCode) || "create_by".equals(fieldCode) || "create_time".equals(fieldCode)
                    || "update_by".equals(fieldCode) || "update_time".equals(fieldCode)) {
                continue;
            }
            Object oldVal = oldData.get(fieldCode);
            Object newVal = newData.get(fieldCode);
            if (equalsValue(oldVal, newVal)) {
                continue;
            }
            recordOne(boCode, billId, fieldCode, oldVal, newVal, userName);
        }
    }

    private void recordOne(String boCode, Long billId, String fieldCode,
                           Object oldVal, Object newVal, String userName) {
        long id = snowflakeIdGenerator.nextId();
        jdbcTemplate.update(
                "INSERT INTO biz_change_log (id, bo_code, bill_id, field_code, field_name, old_value, new_value, change_by, change_time) "
                        + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                id, boCode, billId, fieldCode, fieldCode,
                toStr(oldVal), toStr(newVal), userName, LocalDateTime.now());
    }

    private boolean equalsValue(Object a, Object b) {
        if (a == null && b == null) {
            return true;
        }
        if (a == null || b == null) {
            // 空字符串视为 null
            if (a == null && b instanceof String s && s.isEmpty()) {
                return true;
            }
            if (b == null && a instanceof String s && s.isEmpty()) {
                return true;
            }
            return false;
        }
        return Objects.equals(toStr(a), toStr(b));
    }

    private String toStr(Object v) {
        return v == null ? null : v.toString();
    }
}
