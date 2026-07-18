package com.eerp.test;

import com.eerp.bos.code.CodeGenerateService;
import com.eerp.common.id.SnowflakeIdGenerator;
import com.eerp.meta.code.entity.MetaCodeRule;
import com.eerp.meta.code.service.MetaCodeRuleService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * 编码生成服务单元测试
 */
@ExtendWith(MockitoExtension.class)
class CodeGenerateServiceTest {

    @Mock
    private MetaCodeRuleService metaCodeRuleService;

    @Mock
    private JdbcTemplate jdbcTemplate;

    @Mock
    private SnowflakeIdGenerator snowflakeIdGenerator;

    @InjectMocks
    private CodeGenerateService codeGenerateService;

    private static final String BO_CODE = "SAL_ORDER";

    private MetaCodeRule buildRule(String ruleCode, String segmentsJson, String resetType) {
        MetaCodeRule rule = new MetaCodeRule();
        rule.setId(1L);
        rule.setRuleCode(ruleCode);
        rule.setBoCode(BO_CODE);
        rule.setSegmentsJson(segmentsJson);
        rule.setResetType(resetType);
        return rule;
    }

    @Test
    @DisplayName("前缀+流水号生成编码格式正确（首次生成）")
    void testGenerateCodeWithPrefixAndSerial() {
        String segments = "[{\"type\":\"prefix\",\"value\":\"SO\"},{\"type\":\"serial\",\"digits\":4}]";
        when(metaCodeRuleService.getByBoCode(BO_CODE)).thenReturn(buildRule("RC_SAL_ORDER", segments, "none"));
        // 首次生成：流水号记录不存在，抛 EmptyResultDataAccessException
        when(jdbcTemplate.queryForObject(anyString(), eq(Long.class),
                any(), any(), any()))
                .thenThrow(new EmptyResultDataAccessException(1));
        when(snowflakeIdGenerator.nextId()).thenReturn(9001L);
        when(jdbcTemplate.update(anyString(), any(Object[].class)))
                .thenReturn(1);

        String code = codeGenerateService.generateCode(BO_CODE);

        assertEquals("SO0001", code, "首次生成编码应为 SO0001");
    }

    @Test
    @DisplayName("流水号递增：当前值为5时生成0006")
    void testSerialIncrement() {
        String segments = "[{\"type\":\"prefix\",\"value\":\"PO\"},{\"type\":\"serial\",\"digits\":4}]";
        MetaCodeRule rule = buildRule("RC_PUR_ORDER", segments, "none");
        rule.setBoCode("PUR_ORDER");
        when(metaCodeRuleService.getByBoCode("PUR_ORDER")).thenReturn(rule);
        // 当前流水号为5
        when(jdbcTemplate.queryForObject(anyString(), eq(Long.class),
                any(), any(), any()))
                .thenReturn(5L);
        when(jdbcTemplate.update(anyString(), any(Object[].class)))
                .thenReturn(1);

        String code = codeGenerateService.generateCode("PUR_ORDER");

        assertEquals("PO0006", code, "当前值5递增后应为0006");
    }

    @Test
    @DisplayName("前缀+日期+流水号组合编码")
    void testGenerateCodeWithPrefixDateSerial() {
        String segments = "[{\"type\":\"prefix\",\"value\":\"SO\"},{\"type\":\"date\",\"format\":\"yyyyMMdd\"},{\"type\":\"serial\",\"digits\":4}]";
        when(metaCodeRuleService.getByBoCode(BO_CODE)).thenReturn(buildRule("RC_SAL_ORDER", segments, "daily"));
        when(jdbcTemplate.queryForObject(anyString(), eq(Long.class),
                any(), any(), any()))
                .thenThrow(new EmptyResultDataAccessException(1));
        when(snowflakeIdGenerator.nextId()).thenReturn(1L);
        when(jdbcTemplate.update(anyString(), any(Object[].class)))
                .thenReturn(1);

        String code = codeGenerateService.generateCode(BO_CODE);

        assertTrue(code.startsWith("SO"), "编码应以SO开头");
        assertTrue(code.endsWith("0001"), "编码应以0001结尾");
        assertEquals(14, code.length(), "编码总长度应为14（2+8+4）");
    }

    @Test
    @DisplayName("未配置编码规则时抛出异常")
    void testNoCodeRule() {
        when(metaCodeRuleService.getByBoCode("NO_RULE")).thenReturn(null);

        assertThrows(IllegalStateException.class, () -> codeGenerateService.generateCode("NO_RULE"),
                "未配置编码规则应抛出IllegalStateException");
    }

    @Test
    @DisplayName("编码规则段定义为空时抛出异常")
    void testEmptySegments() {
        when(metaCodeRuleService.getByBoCode(BO_CODE)).thenReturn(buildRule("RC_SAL_ORDER", "", "none"));

        assertThrows(IllegalStateException.class, () -> codeGenerateService.generateCode(BO_CODE),
                "段定义为空应抛出IllegalStateException");
    }
}
