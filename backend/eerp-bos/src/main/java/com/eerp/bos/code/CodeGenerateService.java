package com.eerp.bos.code;

import com.eerp.common.id.SnowflakeIdGenerator;
import com.eerp.meta.code.entity.MetaCodeRule;
import com.eerp.meta.code.service.MetaCodeRuleService;
import cn.hutool.json.JSONArray;
import cn.hutool.json.JSONObject;
import cn.hutool.json.JSONUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;

/**
 * 编码生成服务：解析段式编码规则（prefix/date/serial/fixed/variable）生成业务编码
 * <p>
 * 流水号按 reset_type 重置周期管理（meta_code_serial），使用行锁保证并发安全。
 */
@Service
public class CodeGenerateService {

    @Autowired
    private MetaCodeRuleService metaCodeRuleService;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Autowired
    private SnowflakeIdGenerator snowflakeIdGenerator;

    /**
     * 生成业务对象编码
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW, rollbackFor = Exception.class)
    public String generateCode(String boCode) {
        return generateCode(boCode, 0L);
    }

    /**
     * 生成业务对象编码（按组织）
     *
     * @param boCode 业务对象编码
     * @param orgId  组织ID（无组织传 0）
     */
    @Transactional(rollbackFor = Exception.class)
    public String generateCode(String boCode, Long orgId) {
        MetaCodeRule rule = metaCodeRuleService.getByBoCode(boCode);
        if (rule == null) {
            throw new IllegalStateException("业务对象[" + boCode + "]未配置编码规则");
        }
        String segmentsJson = rule.getSegmentsJson();
        if (segmentsJson == null || segmentsJson.trim().isEmpty()) {
            throw new IllegalStateException("业务对象[" + boCode + "]编码规则段定义为空");
        }

        JSONArray segments = JSONUtil.parseArray(segmentsJson);
        StringBuilder code = new StringBuilder();

        for (int i = 0; i < segments.size(); i++) {
            JSONObject seg = segments.getJSONObject(i);
            String type = seg.getStr("type");
            if (type == null) {
                continue;
            }
            switch (type.toLowerCase()) {
                case "prefix":
                case "fixed":
                    code.append(seg.getStr("value", ""));
                    break;
                case "date":
                    code.append(formatDate(seg.getStr("format")));
                    break;
                case "serial":
                    code.append(nextSerial(rule, orgId, seg.getInt("digits", 4)));
                    break;
                case "variable":
                    // Phase 1：无运行时上下文，取段定义 value 作为字面量
                    code.append(seg.getStr("value", ""));
                    break;
                default:
                    break;
            }
        }
        return code.toString();
    }

    /**
     * 按重置周期取下一流水号（行锁并发安全）
     */
    private String nextSerial(MetaCodeRule rule, Long orgId, int digits) {
        Long effectiveOrg = orgId == null ? 0L : orgId;
        String period = resolvePeriod(rule.getResetType());
        String ruleCode = rule.getRuleCode();

        Long current = lockCurrentSerial(ruleCode, effectiveOrg, period);
        long next;
        if (current == null) {
            next = 1L;
            long id = snowflakeIdGenerator.nextId();
            jdbcTemplate.update(
                    "INSERT INTO meta_code_serial (id, rule_code, org_id, period, current_serial) VALUES (?, ?, ?, ?, ?)",
                    id, ruleCode, effectiveOrg, period, next);
        } else {
            next = current + 1;
            jdbcTemplate.update(
                    "UPDATE meta_code_serial SET current_serial = ? WHERE rule_code = ? AND org_id = ? AND period = ?",
                    next, ruleCode, effectiveOrg, period);
        }
        return padSerial(next, digits);
    }

    private Long lockCurrentSerial(String ruleCode, Long orgId, String period) {
        try {
            return jdbcTemplate.queryForObject(
                    "SELECT current_serial FROM meta_code_serial "
                            + "WHERE rule_code = ? AND org_id = ? AND period = ? FOR UPDATE",
                    Long.class, ruleCode, orgId, period);
        } catch (EmptyResultDataAccessException e) {
            return null;
        }
    }

    private String resolvePeriod(String resetType) {
        if (resetType == null) {
            return "NEVER";
        }
        LocalDate now = LocalDate.now();
        switch (resetType.toLowerCase()) {
            case "year":
            case "org_year":
                return now.format(DateTimeFormatter.ofPattern("yyyy"));
            case "month":
                return now.format(DateTimeFormatter.ofPattern("yyyyMM"));
            case "daily":
                return now.format(DateTimeFormatter.ofPattern("yyyyMMdd"));
            case "none":
            default:
                return "NEVER";
        }
    }

    private String formatDate(String format) {
        String pattern = (format == null || format.isEmpty()) ? "yyyyMMdd" : format;
        try {
            return LocalDate.now().format(DateTimeFormatter.ofPattern(pattern));
        } catch (IllegalArgumentException e) {
            return LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMMdd"));
        }
    }

    private String padSerial(long serial, int digits) {
        if (digits <= 0) {
            return String.valueOf(serial);
        }
        return String.format("%0" + digits + "d", serial);
    }
}
