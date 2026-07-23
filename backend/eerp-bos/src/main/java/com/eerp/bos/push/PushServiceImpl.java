package com.eerp.bos.push;

import com.eerp.bos.bill.AbstractBillLinkService;
import com.eerp.bos.bill.BillDataAccessor;
import com.eerp.bos.runtime.entity.BizBillLink;
import com.eerp.common.exception.ServiceException;
import com.eerp.common.id.SnowflakeIdGenerator;
import com.eerp.meta.push.entity.MetaPushRule;
import com.eerp.meta.push.service.MetaPushRuleService;
import com.eerp.meta.rule.expr.ExprContext;
import com.eerp.meta.rule.expr.ExprEvaluator;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Pattern;

/**
 * 下推服务实现（@Service，对齐设计文档 02 §3.7 + §6.3）。
 *
 * <p>依赖：
 * <ul>
 *   <li>{@link MetaPushRuleService}：加载下推规则</li>
 *   <li>{@link BillDataAccessor}：加载源单据 + 持久化目标单据</li>
 *   <li>{@link ExprEvaluator}：求 {@code filter_expr} / {@code vp_check_expr}</li>
 *   <li>{@link JdbcTemplate}：回写源单 {@code pushed_field}</li>
 *   <li>{@link AbstractBillLinkService}：写 {@code biz_bill_link}</li>
 *   <li>{@link SnowflakeIdGenerator}：目标单行 ID 生成</li>
 * </ul>
 * </p>
 *
 * <p>字段映射 JSON 格式（{@code meta_push_rule.field_mapping_json}）：
 * <pre>[{"src_field":"code","target_field":"src_code","is_main":true,"transform_expr":null}, ...]</pre>
 * 映射时若 {@code transform_expr} 非空，使用 ExprEvaluator 求值（context 含 {@code $src} 指向源行数据）。</p>
 *
 * <p>SQL 注入防护：表名/字段名通过 {@link #IDENT_PATTERN} 校验为合法标识符。</p>
 */
@Service
public class PushServiceImpl extends AbstractPushService {

    private static final Logger log = LoggerFactory.getLogger(PushServiceImpl.class);

    /** 合法标识符正则（防 SQL 注入） */
    private static final Pattern IDENT_PATTERN = Pattern.compile("^[a-zA-Z_][a-zA-Z0-9_]*$");

    private static final ObjectMapper MAPPER = new ObjectMapper()
            .setPropertyNamingStrategy(com.fasterxml.jackson.databind.PropertyNamingStrategies.SNAKE_CASE);

    @Autowired
    private MetaPushRuleService metaPushRuleService;

    @Autowired
    private BillDataAccessor billDataAccessor;

    @Autowired
    private ExprEvaluator exprEvaluator;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Autowired
    private SnowflakeIdGenerator snowflakeIdGenerator;

    @Override
    @Autowired
    public void setBillLinkService(AbstractBillLinkService billLinkService) {
        super.setBillLinkService(billLinkService);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public PushResult push(PushContext ctx) {
        if (ctx == null || ctx.getRuleCode() == null) {
            return PushResult.fail("下推上下文或规则编码为空");
        }
        if (ctx.getLines() == null || ctx.getLines().isEmpty()) {
            return PushResult.fail("未勾选下推行");
        }

        // 1. 加载下推规则
        MetaPushRule rule = loadRule(ctx.getRuleCode());
        if (rule == null) {
            return PushResult.fail("下推规则[" + ctx.getRuleCode() + "]不存在或未启用");
        }

        // 校验目标 bo 一致
        if (ctx.getTgtBoCode() != null && !ctx.getTgtBoCode().equals(rule.getTgtBoCode())) {
            return PushResult.fail("目标 bo 与规则配置不一致");
        }
        ctx.setTgtBoCode(rule.getTgtBoCode());

        // 2. 加载源单数据（含主表 + 子表）
        Map<String, Object> srcBill = billDataAccessor.loadBill(ctx.getSrcBoCode(), ctx.getSrcBillId());
        if (srcBill == null || srcBill.isEmpty()) {
            return PushResult.fail("源单据[" + ctx.getSrcBoCode() + ":" + ctx.getSrcBillId() + "]不存在");
        }

        // 3. 过滤源单行（应用 filter_expr）
        List<Map<String, Object>> srcLines = filterSourceLines(ctx, rule);
        if (srcLines == null || srcLines.isEmpty()) {
            return PushResult.fail("过滤后无可下推源单行");
        }

        // 4. 逐行 vp_check_expr 校验可下推量
        for (PushLine pushLine : ctx.getLines()) {
            Map<String, Object> matchedLine = findLineById(srcLines, pushLine.getLineId());
            if (matchedLine == null) {
                return PushResult.fail("勾选行[" + pushLine.getLineId() + "]不在过滤结果中");
            }
            if (!validatePushQty(matchedLine, pushLine.getPushQty(), rule)) {
                throw new ServiceException("PUSH_QTY_OVER_LIMIT",
                        "行[" + pushLine.getLineId() + "]可下推量不足，本次下推量=" + pushLine.getPushQty());
            }
        }

        // 5. field_mapping_json 字段映射生成目标单
        Map<String, Object> targetBillData = mapToTarget(ctx, srcLines, rule);

        // 6. 持久化目标单
        Long targetBillId = saveTargetBill(ctx, targetBillData);

        // 7. 写 biz_bill_link 关联记录（每个勾选行一条）
        int linkCount = 0;
        for (PushLine pushLine : ctx.getLines()) {
            Map<String, Object> matchedLine = findLineById(srcLines, pushLine.getLineId());
            BizBillLink link = new BizBillLink();
            link.setSrcBoCode(ctx.getSrcBoCode());
            link.setSrcBillId(ctx.getSrcBillId());
            link.setSrcLineId(pushLine.getLineId());
            link.setTgtBoCode(ctx.getTgtBoCode());
            link.setTgtBillId(targetBillId);
            // 目标行ID：从目标单子表按映射反查（简化实现：取目标单第一行的 ID）
            link.setTgtLineId(resolveTargetLineId(targetBillData, matchedLine));
            link.setLinkQty(pushLine.getPushQty());
            link.setPushRuleCode(rule.getRuleCode());
            createBillLink(link);
            linkCount++;
        }

        // 8. 回写源单 pushed_field
        writebackPushedField(ctx, srcLines, rule);

        return PushResult.ok(targetBillId, linkCount);
    }

    @Override
    protected MetaPushRule loadRule(String ruleCode) {
        com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<MetaPushRule> wrapper =
                new com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<>();
        wrapper.eq(MetaPushRule::getRuleCode, ruleCode)
                .eq(MetaPushRule::getIsEnable, 1)
                .last("LIMIT 1");
        return metaPushRuleService.getOne(wrapper);
    }

    @Override
    @SuppressWarnings("unchecked")
    protected List<Map<String, Object>> filterSourceLines(PushContext ctx, MetaPushRule rule) {
        // 加载源单完整数据
        Map<String, Object> srcBill = billDataAccessor.loadBill(ctx.getSrcBoCode(), ctx.getSrcBillId());
        Map<String, Object> main = (Map<String, Object>) srcBill.getOrDefault("main", new HashMap<>());
        Map<String, Object> subs = (Map<String, Object>) srcBill.getOrDefault("subs", new HashMap<>());

        // main scope（主表总量下推）：源"行"即为主表，PushLine.lineId 约定 = 源单 billId
        if (isMainScope(rule)) {
            List<Map<String, Object>> filtered = new ArrayList<>();
            for (PushLine pushLine : ctx.getLines()) {
                Object mainId = main.get("id");
                if (mainId == null
                        || pushLine.getLineId() == null
                        || !mainId.toString().equals(String.valueOf(pushLine.getLineId()))) {
                    continue;
                }
                if (!passFilterExpr(main, rule)) {
                    continue;
                }
                filtered.add(main);
                break; // 主表只有一行
            }
            return filtered;
        }

        // sub scope（子表明细下推，默认）：按下推勾选的 lineId 过滤子表行
        List<Map<String, Object>> allLines = new ArrayList<>();
        for (Object entityRows : subs.values()) {
            if (entityRows instanceof List) {
                for (Object row : (List<?>) entityRows) {
                    if (row instanceof Map) {
                        allLines.add((Map<String, Object>) row);
                    }
                }
            }
        }

        // 按 ctx.lines 中的 lineId 过滤
        List<Map<String, Object>> filtered = new ArrayList<>();
        for (PushLine pushLine : ctx.getLines()) {
            for (Map<String, Object> line : allLines) {
                Object lineId = line.get("id");
                if (lineId != null && lineId.toString().equals(String.valueOf(pushLine.getLineId()))) {
                    if (!passFilterExpr(line, rule)) {
                        continue; // 过滤掉
                    }
                    filtered.add(line);
                    break;
                }
            }
        }
        return filtered;
    }

    /** 应用 filter_expr，返回 true 表示放行 */
    private boolean passFilterExpr(Map<String, Object> line, MetaPushRule rule) {
        if (rule.getFilterExpr() == null || rule.getFilterExpr().trim().isEmpty()) {
            return true;
        }
        ExprContext exprCtx = new ExprContext(line);
        try {
            Object result = exprEvaluator.evaluate(rule.getFilterExpr(), exprCtx);
            if (Boolean.FALSE.equals(result) || "false".equals(String.valueOf(result))) {
                return false;
            }
            return true;
        } catch (Exception e) {
            log.warn("filter_expr 求值失败，默认放行: {}", e.getMessage());
            return true;
        }
    }

    /** main scope = 主表总量下推；否则按子表明细下推 */
    private boolean isMainScope(MetaPushRule rule) {
        return rule != null && "main".equalsIgnoreCase(rule.getQtyFieldScope());
    }

    @Override
    protected boolean validatePushQty(Map<String, Object> line, BigDecimal pushQty, MetaPushRule rule) {
        if (pushQty == null || pushQty.compareTo(BigDecimal.ZERO) <= 0) {
            return false;
        }
        String vpCheck = rule.getVpCheckExpr();
        if (vpCheck == null || vpCheck.trim().isEmpty()) {
            return true; // 未配置校验表达式，默认通过
        }

        // 构造 ExprContext：$qty_field、$pushed_field、$push_qty 可被表达式引用
        ExprContext exprCtx = new ExprContext(line);
        exprCtx.setVariable("push_qty", pushQty);

        try {
            Object result = exprEvaluator.evaluate(vpCheck, exprCtx);
            if (result == null) {
                return true;
            }
            if (Boolean.FALSE.equals(result)) {
                return false;
            }
            if ("false".equals(String.valueOf(result))) {
                return false;
            }
            // 数值比较：>0 视为通过
            if (result instanceof Number) {
                return ((Number) result).doubleValue() > 0;
            }
            return Boolean.TRUE.equals(result) || "true".equals(String.valueOf(result));
        } catch (Exception e) {
            log.warn("vp_check_expr 求值失败，默认拒绝: {}", e.getMessage());
            return false;
        }
    }

    @Override
    @SuppressWarnings("unchecked")
    protected Map<String, Object> mapToTarget(PushContext ctx, List<Map<String, Object>> srcLines, MetaPushRule rule) {
        List<FieldMapping> mappings = parseFieldMapping(rule.getFieldMappingJson());

        Map<String, Object> targetMain = new LinkedHashMap<>();
        Map<String, Object> targetSubs = new LinkedHashMap<>();
        List<Map<String, Object>> targetSubLines = new ArrayList<>();

        // 主表字段映射（取源单主表数据，按 src_field → target_field）
        Map<String, Object> srcMain = (Map<String, Object>) billDataAccessor
                .loadBill(ctx.getSrcBoCode(), ctx.getSrcBillId())
                .getOrDefault("main", new HashMap<>());

        for (FieldMapping m : mappings) {
            if (!m.isMain || m.targetField == null) {
                continue;
            }
            Object value = resolveMappingValue(m, srcMain, null);
            if (value != null) {
                targetMain.put(m.targetField, value);
            }
        }

        // main scope（主表总量下推）：qty_field 写到目标主表，子表行从源单全部 subs 携带
        if (isMainScope(rule)) {
            // 目标主表数量 = 本次下推总量（取 PushLine 之和）
            BigDecimal totalPushQty = sumPushQty(ctx);
            if (totalPushQty != null && rule.getQtyField() != null && !rule.getQtyField().isEmpty()) {
                targetMain.put(rule.getQtyField(), totalPushQty);
            }
            // 源单主表 ID 回填到目标主表，便于追溯
            Object srcMainId = srcMain.get("id");
            if (srcMainId != null) {
                targetMain.put("src_bill_id", srcMainId);
            }

            // 子表行：从源单全部 subs 携带（按下推子表字段映射）
            List<Map<String, Object>> allSrcSubLines = collectAllSubLines(ctx);
            for (Map<String, Object> srcLine : allSrcSubLines) {
                Map<String, Object> targetLine = new LinkedHashMap<>();
                for (FieldMapping m : mappings) {
                    if (m.isMain || m.targetField == null) {
                        continue;
                    }
                    Object value = resolveMappingValue(m, srcLine, srcMain);
                    if (value != null) {
                        targetLine.put(m.targetField, value);
                    }
                }
                // 源行ID 回填（用于追溯）
                targetLine.put("src_line_id", srcLine.get("id"));
                targetSubLines.add(targetLine);
            }

            String tgtSubEntityCode = "default";
            if (!targetSubLines.isEmpty()) {
                targetSubs.put(tgtSubEntityCode, targetSubLines);
            }

            Map<String, Object> targetBill = new LinkedHashMap<>();
            targetBill.put("main", targetMain);
            targetBill.put("subs", targetSubs);
            return targetBill;
        }

        // sub scope（默认）：子表字段映射按下推勾选行生成目标子表行
        for (Map<String, Object> srcLine : srcLines) {
            Map<String, Object> targetLine = new LinkedHashMap<>();
            for (FieldMapping m : mappings) {
                if (m.isMain || m.targetField == null) {
                    continue;
                }
                Object value = resolveMappingValue(m, srcLine, srcMain);
                if (value != null) {
                    targetLine.put(m.targetField, value);
                }
            }
            // 关联本次下推量
            PushLine pushLine = findPushLine(ctx, srcLine);
            if (pushLine != null && pushLine.getPushQty() != null) {
                // 按 qty_field 配置目标单数量字段
                if (rule.getQtyField() != null && !rule.getQtyField().isEmpty()) {
                    targetLine.put(rule.getQtyField(), pushLine.getPushQty());
                }
            }
            // 源行ID 回填（用于追溯）
            targetLine.put("src_line_id", srcLine.get("id"));
            targetSubLines.add(targetLine);
        }

        // 目标子表实体编码：约定为第一个非主实体的 entityCode（简化实现）
        // 完整实现应通过 FormMetaCache 解析目标 bo 的子表实体编码
        String tgtSubEntityCode = "default";
        if (!targetSubLines.isEmpty()) {
            targetSubs.put(tgtSubEntityCode, targetSubLines);
        }

        Map<String, Object> targetBill = new LinkedHashMap<>();
        targetBill.put("main", targetMain);
        targetBill.put("subs", targetSubs);
        return targetBill;
    }

    /** 汇总 ctx.lines 中所有 pushQty */
    private BigDecimal sumPushQty(PushContext ctx) {
        if (ctx.getLines() == null || ctx.getLines().isEmpty()) {
            return null;
        }
        BigDecimal total = BigDecimal.ZERO;
        for (PushLine pl : ctx.getLines()) {
            if (pl.getPushQty() != null) {
                total = total.add(pl.getPushQty());
            }
        }
        return total;
    }

    /** 收集源单全部子表行（main scope 下用于携带明细到目标单） */
    @SuppressWarnings("unchecked")
    private List<Map<String, Object>> collectAllSubLines(PushContext ctx) {
        Map<String, Object> srcBill = billDataAccessor.loadBill(ctx.getSrcBoCode(), ctx.getSrcBillId());
        Map<String, Object> subs = (Map<String, Object>) srcBill.getOrDefault("subs", new HashMap<>());
        List<Map<String, Object>> allLines = new ArrayList<>();
        for (Object entityRows : subs.values()) {
            if (entityRows instanceof List) {
                for (Object row : (List<?>) entityRows) {
                    if (row instanceof Map) {
                        allLines.add((Map<String, Object>) row);
                    }
                }
            }
        }
        return allLines;
    }

    @Override
    protected Long saveTargetBill(PushContext ctx, Map<String, Object> targetBillData) {
        // 调用 BillDataAccessor.saveBill 持久化目标单（pact_state=1 已创建）
        return billDataAccessor.saveBill(ctx.getTgtBoCode(), targetBillData);
    }

    @Override
    @SuppressWarnings("unchecked")
    protected void writebackPushedField(PushContext ctx, List<Map<String, Object>> srcLines, MetaPushRule rule) {
        String pushedField = rule.getPushedField();
        if (pushedField == null || pushedField.isEmpty()) {
            return;
        }
        validateIdentifier(pushedField, "pushed_field");

        // main scope：回写到源主表（约定表名 = bo_code，WHERE id = srcBillId）
        if (isMainScope(rule)) {
            String srcMainTable = resolveSrcMainTable(ctx.getSrcBoCode());
            if (srcMainTable == null) {
                log.warn("无法解析源单主表名，跳过 pushed_field 回写");
                return;
            }
            validateIdentifier(srcMainTable, "源主表名");
            // main scope 下 pushLine.lineId 约定 = srcBillId；累加本次下推总量到主表
            for (PushLine pushLine : ctx.getLines()) {
                if (pushLine.getPushQty() == null) {
                    continue;
                }
                String sql = "UPDATE `" + srcMainTable + "` SET `" + pushedField
                        + "` = COALESCE(`" + pushedField + "`, 0) + ? WHERE `id` = ?";
                jdbcTemplate.update(sql, pushLine.getPushQty(), pushLine.getLineId());
            }
            return;
        }

        // sub scope（默认）：回写到源子表
        Map<String, Object> srcBill = billDataAccessor.loadBill(ctx.getSrcBoCode(), ctx.getSrcBillId());
        Map<String, Object> subs = (Map<String, Object>) srcBill.getOrDefault("subs", new HashMap<>());

        // 找到包含 srcLine 的子表实体编码 → 解析表名（简化：按约定子表名 = src_bo_code + "_goods"）
        // 完整实现应通过 FormMetaCache 解析
        String srcSubTable = resolveSrcSubTable(ctx.getSrcBoCode());
        if (srcSubTable == null) {
            log.warn("无法解析源单子表名，跳过 pushed_field 回写");
            return;
        }
        validateIdentifier(srcSubTable, "源子表名");

        for (PushLine pushLine : ctx.getLines()) {
            if (pushLine.getPushQty() == null) {
                continue;
            }
            String sql = "UPDATE `" + srcSubTable + "` SET `" + pushedField
                    + "` = COALESCE(`" + pushedField + "`, 0) + ? WHERE `id` = ?";
            jdbcTemplate.update(sql, pushLine.getPushQty(), pushLine.getLineId());
        }
    }

    /** 解析源主表名（main scope 回写用），约定 = bo_code */
    private String resolveSrcMainTable(String srcBoCode) {
        if (srcBoCode == null || srcBoCode.isEmpty()) {
            return null;
        }
        return srcBoCode;
    }

    // ==================== 内部工具方法 ====================

    private PushLine findPushLine(PushContext ctx, Map<String, Object> srcLine) {
        Object lineId = srcLine.get("id");
        if (lineId == null) {
            return null;
        }
        for (PushLine pl : ctx.getLines()) {
            if (pl.getLineId() != null && pl.getLineId().toString().equals(lineId.toString())) {
                return pl;
            }
        }
        return null;
    }

    private Map<String, Object> findLineById(List<Map<String, Object>> srcLines, Long lineId) {
        if (lineId == null) {
            return null;
        }
        for (Map<String, Object> line : srcLines) {
            Object id = line.get("id");
            if (id != null && id.toString().equals(lineId.toString())) {
                return line;
            }
        }
        return null;
    }

    private Long resolveTargetLineId(Map<String, Object> targetBillData, Map<String, Object> srcLine) {
        // 简化实现：从目标单子表查找含 src_line_id 的行的 id
        Map<String, Object> subs = (Map<String, Object>) targetBillData.getOrDefault("subs", new HashMap<>());
        Object srcLineId = srcLine.get("id");
        for (Object entityRows : subs.values()) {
            if (entityRows instanceof List) {
                for (Object row : (List<?>) entityRows) {
                    if (row instanceof Map) {
                        Map<String, Object> targetLine = (Map<String, Object>) row;
                        Object tgtSrcLineId = targetLine.get("src_line_id");
                        if (tgtSrcLineId != null && srcLineId != null
                                && tgtSrcLineId.toString().equals(srcLineId.toString())) {
                            Object id = targetLine.get("id");
                            if (id instanceof Number) {
                                return ((Number) id).longValue();
                            }
                            return null;
                        }
                    }
                }
            }
        }
        return null;
    }

    private String resolveSrcSubTable(String srcBoCode) {
        // 简化实现：按约定子表名 = src_bo_code + "_goods"
        // 完整实现应通过 FormMetaCache 解析源 bo 的子表实体表名
        if (srcBoCode == null || srcBoCode.isEmpty()) {
            return null;
        }
        return srcBoCode + "_goods";
    }

    private Object resolveMappingValue(FieldMapping m, Map<String, Object> srcLine, Map<String, Object> srcMain) {
        if (m.transformExpr != null && !m.transformExpr.trim().isEmpty()) {
            // 转换表达式求值：context 含 $src（源行）+ $main（源主表）
            Map<String, Object> root = new HashMap<>();
            if (srcLine != null) {
                root.put("src", srcLine);
            }
            if (srcMain != null) {
                root.put("main", srcMain);
            }
            ExprContext exprCtx = new ExprContext(root);
            try {
                return exprEvaluator.evaluate(m.transformExpr, exprCtx);
            } catch (Exception e) {
                log.warn("transform_expr 求值失败: {} | {}", m.transformExpr, e.getMessage());
                return null;
            }
        }
        if (m.srcField == null) {
            return null;
        }
        return srcLine == null ? null : srcLine.get(m.srcField);
    }

    private List<FieldMapping> parseFieldMapping(String json) {
        if (json == null || json.trim().isEmpty()) {
            return new ArrayList<>();
        }
        try {
            List<FieldMapping> list = MAPPER.readValue(json, new TypeReference<List<FieldMapping>>() {
            });
            return list == null ? new ArrayList<>() : list;
        } catch (Exception e) {
            log.warn("field_mapping_json 解析失败: {} | {}", json, e.getMessage());
            return new ArrayList<>();
        }
    }

    private void validateIdentifier(String ident, String label) {
        if (ident == null || !IDENT_PATTERN.matcher(ident).matches()) {
            throw new ServiceException("IDENT_INVALID", label + " 非法: " + ident);
        }
    }

    /** 字段映射 DTO（与 field_mapping_json 结构对齐） */
    public static class FieldMapping {
        public String srcField;
        public String targetField;
        public boolean isMain;
        public String transformExpr;

        public String getSrcField() { return srcField; }
        public void setSrcField(String srcField) { this.srcField = srcField; }
        public String getTargetField() { return targetField; }
        public void setTargetField(String targetField) { this.targetField = targetField; }
        public boolean isMain() { return isMain; }
        public void setMain(boolean main) { isMain = main; }
        public String getTransformExpr() { return transformExpr; }
        public void setTransformExpr(String transformExpr) { this.transformExpr = transformExpr; }
    }
}
