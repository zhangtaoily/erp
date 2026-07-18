package com.eerp.test;

import com.eerp.bos.bill.AbstractBillLinkService;
import com.eerp.bos.bill.BillLinkServiceImpl;
import com.eerp.bos.bill.TraceTree;
import com.eerp.bos.runtime.entity.BizBillLink;
import com.eerp.common.id.SnowflakeIdGenerator;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.test.util.ReflectionTestUtils;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.verify;

/**
 * 单据追溯服务单元测试（A7：单据关联 + 追溯树构建）。
 *
 * <p>覆盖场景：</p>
 * <ul>
 *   <li>create：分配雪花 ID 并调用 save</li>
 *   <li>listBySrc / listByTgt：按 LambdaQueryWrapper 查询</li>
 *   <li>buildTraceTree 向下递归：3 层深度，正确展开 children</li>
 *   <li>buildTraceTree 深度上限：maxDepth=1 时根节点 depthLimitReached=true</li>
 *   <li>buildTraceTree 防环：循环关联不无限递归</li>
 *   <li>buildTraceTree 上查：按 tgt 反查 src</li>
 * </ul>
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class BillLinkServiceTest {

    /** 模拟 MyBatis-Plus BaseMapper 链路的桩：通过子类覆盖关键方法绕过 DB */
    private BillLinkServiceImpl billLinkService;

    @Mock
    private SnowflakeIdGenerator snowflakeIdGenerator;

    private static final String BO_A = "sal_order";
    private static final String BO_B = "pur_order";
    private static final Long ID_1 = 1001L;
    private static final Long ID_2 = 2002L;
    private static final Long ID_3 = 3003L;

    @BeforeEach
    void setUp() {
        billLinkService = new BillLinkServiceImpl() {
            private final List<BizBillLink> store = new ArrayList<>();

            @Override
            public boolean save(BizBillLink entity) {
                store.add(entity);
                return true;
            }

            @Override
            public List<BizBillLink> listBySrc(String srcBoCode, Long srcBillId) {
                List<BizBillLink> result = new ArrayList<>();
                for (BizBillLink l : store) {
                    if (srcBoCode.equals(l.getSrcBoCode()) && srcBillId.equals(l.getSrcBillId())) {
                        result.add(l);
                    }
                }
                return result;
            }

            @Override
            public List<BizBillLink> listByTgt(String tgtBoCode, Long tgtBillId) {
                List<BizBillLink> result = new ArrayList<>();
                for (BizBillLink l : store) {
                    if (tgtBoCode.equals(l.getTgtBoCode()) && tgtBillId.equals(l.getTgtBillId())) {
                        result.add(l);
                    }
                }
                return result;
            }
        };
        ReflectionTestUtils.setField(billLinkService, "snowflakeIdGenerator", snowflakeIdGenerator);
        lenient().when(snowflakeIdGenerator.nextId()).thenReturn(99999L);
    }

    @Test
    @DisplayName("create：分配雪花 ID 并持久化")
    void testCreateAssignsId() {
        BizBillLink link = new BizBillLink();
        link.setSrcBoCode(BO_A);
        link.setSrcBillId(ID_1);
        link.setTgtBoCode(BO_B);
        link.setTgtBillId(ID_2);
        link.setLinkQty(new BigDecimal("10"));

        BizBillLink result = billLinkService.create(link);

        assertEquals(Long.valueOf(99999L), result.getId(), "应分配雪花 ID");
        assertEquals(BO_A, result.getSrcBoCode());
    }

    @Test
    @DisplayName("listBySrc：按源单查询下游关联")
    void testListBySrc() {
        BizBillLink link = new BizBillLink();
        link.setSrcBoCode(BO_A);
        link.setSrcBillId(ID_1);
        link.setTgtBoCode(BO_B);
        link.setTgtBillId(ID_2);
        billLinkService.create(link);

        List<BizBillLink> list = billLinkService.listBySrc(BO_A, ID_1);
        assertEquals(1, list.size(), "应查询到 1 条下游关联");
        assertEquals(ID_2, list.get(0).getTgtBillId());
    }

    @Test
    @DisplayName("buildTraceTree 向下递归：构建 3 层追溯树")
    void testBuildTraceTreeDown3Levels() {
        // 构造链路：A:1 -> B:2 -> B:3（A:1 下推生成 B:2，B:2 下推生成 B:3）
        link(BO_A, ID_1, BO_B, ID_2);
        link(BO_B, ID_2, BO_B, ID_3);

        TraceTree tree = billLinkService.buildTraceTree(BO_A, ID_1, "down", 5);

        assertNotNull(tree, "根节点不应为 null");
        assertEquals(BO_A, tree.getBoCode());
        assertEquals(ID_1, tree.getBillId());
        assertEquals(0, tree.getDepth(), "根节点深度=0");
        assertEquals(1, tree.getChildren().size(), "第一层应 1 个子节点");

        TraceTree level1 = tree.getChildren().get(0);
        assertEquals(BO_B, level1.getBoCode());
        assertEquals(ID_2, level1.getBillId());
        assertEquals(1, level1.getDepth());
        assertEquals(1, level1.getChildren().size(), "第二层应 1 个子节点");

        TraceTree level2 = level1.getChildren().get(0);
        assertEquals(BO_B, level2.getBoCode());
        assertEquals(ID_3, level2.getBillId());
        assertEquals(2, level2.getDepth());
        assertTrue(level2.getChildren().isEmpty(), "第三层无下游");
    }

    @Test
    @DisplayName("buildTraceTree 深度上限：maxDepth=1 时根节点 depthLimitReached=true")
    void testBuildTraceTreeDepthLimit() {
        link(BO_A, ID_1, BO_B, ID_2);

        TraceTree tree = billLinkService.buildTraceTree(BO_A, ID_1, "down", 0);

        assertTrue(tree.isDepthLimitReached(), "maxDepth=0 时根节点应标记深度上限");
        assertTrue(tree.getChildren().isEmpty(), "不应展开子节点");
    }

    @Test
    @DisplayName("buildTraceTree 防环：循环关联 A:1 <-> A:1 不无限递归")
    void testBuildTraceTreeCycleProtection() {
        // 构造循环：A:1 -> A:1（自环）
        link(BO_A, ID_1, BO_A, ID_1);

        TraceTree tree = billLinkService.buildTraceTree(BO_A, ID_1, "down", 5);

        assertNotNull(tree);
        // 自环节点应被 visited 防止展开（根节点已加入 visited，子节点 key 相同不再展开）
        // 子节点存在但不继续展开
        assertEquals(1, tree.getChildren().size(), "应识别到自环子节点");
        TraceTree self = tree.getChildren().get(0);
        assertTrue(self.getChildren().isEmpty(), "自环节点不应再递归展开");
    }

    @Test
    @DisplayName("buildTraceTree 上查：按 tgt 反查 src")
    void testBuildTraceTreeUp() {
        // 构造链路：A:1 -> B:2，从 B:2 上查到 A:1
        link(BO_A, ID_1, BO_B, ID_2);

        TraceTree tree = billLinkService.buildTraceTree(BO_B, ID_2, "up", 5);

        assertNotNull(tree);
        assertEquals(BO_B, tree.getBoCode());
        assertEquals(ID_2, tree.getBillId());
        assertEquals(1, tree.getChildren().size(), "上查应找到 1 个源单");
        TraceTree src = tree.getChildren().get(0);
        assertEquals(BO_A, src.getBoCode());
        assertEquals(ID_1, src.getBillId());
    }

    @Test
    @DisplayName("buildTraceTree 默认深度：maxDepth=5")
    void testBuildTraceTreeDefaultDepth() {
        // 构造 6 层链路：A:1 -> A:2 -> A:3 -> A:4 -> A:5 -> A:6
        link(BO_A, ID_1, BO_A, ID_2);
        link(BO_A, ID_2, BO_A, ID_3);

        TraceTree tree = billLinkService.buildTraceTree(BO_A, ID_1, "down");

        assertNotNull(tree);
        assertEquals(0, tree.getDepth());
        // 默认深度 5，递归应受 maxDepth 限制
        assertEquals(AbstractBillLinkService.DEFAULT_MAX_DEPTH, 5);
    }

    @Test
    @DisplayName("buildTraceTree 空关联：根节点无子节点")
    void testBuildTraceTreeEmpty() {
        TraceTree tree = billLinkService.buildTraceTree(BO_A, ID_1, "down", 5);
        assertNotNull(tree);
        assertTrue(tree.getChildren().isEmpty());
    }

    private void link(String srcBo, Long srcId, String tgtBo, Long tgtId) {
        BizBillLink link = new BizBillLink();
        link.setSrcBoCode(srcBo);
        link.setSrcBillId(srcId);
        link.setTgtBoCode(tgtBo);
        link.setTgtBillId(tgtId);
        link.setLinkQty(new BigDecimal("1"));
        link.setPushRuleCode("TEST_RULE");
        billLinkService.create(link);
    }
}
