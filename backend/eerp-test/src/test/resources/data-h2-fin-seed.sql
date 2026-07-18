-- ============================================================
-- EERP H2 FIN (财务会计) 元数据种子
-- ============================================================
-- 用途：集成测试 H2 内存数据库财务会计模块元数据种子（Phase 3a-3c）。
--       为 14 个财务业务对象 bo_code 注册业务对象、独立状态机
--       （5 节点 / 17 流转，复制 STD_5STATE 模型）、表单实体层级
--       （主/子）与关键字段元数据，驱动 GenericBillService →
--       GenericOperationService 的 6 阶段流水线，无需具体 Entity/Mapper。
-- 加载：spring.sql.init.data-locations 追加本文件。
-- 幂等：全部使用 REPLACE INTO ... VALUES (...)，可重复执行。
-- ID 约定（与 data-h2-master-seed.sql / data-h2-scm-seed.sql /
--       data-h2-sal-seed.sql / data-h2-inv-seed.sql / data-h2-mfg-seed.sql 不冲突）：
--   meta_business_object  200001-200014   (14 行)
--   meta_state_machine    200100-200104   (5 行，仅业务单据有状态机，code=bo_code)
--   meta_state_node       200200-200224   (5×5=25 行)
--   meta_state_transition 200300-200384   (5×17=85 行)
--   meta_form_entity      200600-200618   (14 主 + 5 子 = 19 行)
--   meta_form_field       240300-240492   (193 行)
-- 判断标准：表有 pact_state 字段 → 业务单据(bo_type='business', is_stateful=1)；
--           表无 pact_state 字段 → 主数据(bo_type='master', is_stateful=0)。
-- 业务单据（5）：FIN_AR / FIN_RECEIPT / FIN_PAYMENT / FIN_WRITEOFF / FIN_CUST_RECEIPT
-- 主数据（9）：FIN_EST_AP / FIN_AP / FIN_ACCOUNT / FIN_PERIOD /
--             FIN_VOUCHER_TPL / FIN_VOUCHER / FIN_COST_COLLECT /
--             FIN_COST_POOL / FIN_COST_VARIANCE
-- 业务单据约定：bo_type='business', is_stateful=1, is_pushable=1,
--               is_printable=1, pk_strategy='snowflake', main_key='id', status=1
-- 主数据约定：bo_type='master', is_stateful=0, is_pushable=0,
--             is_printable=0, pk_strategy='snowflake', main_key='id', status=1
-- 状态机复制：每业务 bo_code 复制 STD_5STATE（machine_id=100）的 5 节点
--             （id=101-105）与 17 流转（id=200-216），替换 machine_id。
--             t12-t15 含 post_action（is_closed/is_cancel 标记）。
-- 子表关联（以 schema-h2.sql 实际定义为准）：
--   FIN_RECEIPT     子表 fin_receipt_detail      link_field=receipt_id
--   FIN_PAYMENT     子表 fin_payment_detail      link_field=payment_id
--   FIN_VOUCHER     子表 fin_voucher_entry       link_field=voucher_id
--   FIN_VOUCHER_TPL 子表 fin_voucher_tpl_entry    link_field=tpl_id
--   FIN_CUST_RECEIPT 子表 fin_cust_receipt_detail link_field=cust_receipt_id
-- 兼容：H2 MODE=MySQL；时间戳使用 CURRENT_TIMESTAMP；布尔值统一用 1/0。
-- 依赖：schema-h2.sql；data-h2-seed.sql（STD_5STATE 及测试主数据）；
--       data-h2-master-seed.sql（主数据 bo_code，ref_bo_code 引用）；
--       data-h2-scm-seed.sql / data-h2-sal-seed.sql /
--       data-h2-inv-seed.sql / data-h2-mfg-seed.sql（不冲突）。
-- ============================================================


-- ============================================================
-- 1. 业务对象定义（meta_business_object）—— 14 个财务 BO
-- ============================================================

-- Phase 3a：应收应付（7 bo_code）
REPLACE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
VALUES (200001, 'FIN_EST_AP',       '暂估应付', 'master',  'fin_est_ap',        'id', 'snowflake', 0, 0, 0, NULL, 1, '暂估应付主数据',     'system', CURRENT_TIMESTAMP);
REPLACE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
VALUES (200002, 'FIN_AR',           '应收单',   'business', 'fin_ar',            'id', 'snowflake', 1, 1, 1, NULL, 1, '应收立账业务单据',   'system', CURRENT_TIMESTAMP);
REPLACE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
VALUES (200003, 'FIN_AP',           '应付单',   'master',  'fin_ap',            'id', 'snowflake', 0, 0, 0, NULL, 1, '应付立账主数据',     'system', CURRENT_TIMESTAMP);
REPLACE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
VALUES (200004, 'FIN_RECEIPT',      '收款单',   'business', 'fin_receipt',       'id', 'snowflake', 1, 1, 1, NULL, 1, '收款单业务单据',     'system', CURRENT_TIMESTAMP);
REPLACE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
VALUES (200005, 'FIN_PAYMENT',      '付款单',   'business', 'fin_payment',       'id', 'snowflake', 1, 1, 1, NULL, 1, '付款单业务单据',     'system', CURRENT_TIMESTAMP);
REPLACE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
VALUES (200006, 'FIN_WRITEOFF',     '核销单',   'business', 'fin_writeoff',      'id', 'snowflake', 1, 1, 1, NULL, 1, '核销单业务单据',     'system', CURRENT_TIMESTAMP);
REPLACE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
VALUES (200007, 'FIN_CUST_RECEIPT', '客户回款', 'business', 'fin_cust_receipt',  'id', 'snowflake', 1, 1, 1, NULL, 1, '客户回款单业务单据', 'system', CURRENT_TIMESTAMP);
-- Phase 3b：总账（4 bo_code）
REPLACE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
VALUES (200008, 'FIN_ACCOUNT',      '会计科目', 'master',  'fin_account',       'id', 'snowflake', 0, 0, 0, NULL, 1, '会计科目树形主数据', 'system', CURRENT_TIMESTAMP);
REPLACE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
VALUES (200009, 'FIN_PERIOD',       '会计期间', 'master',  'fin_period',        'id', 'snowflake', 0, 0, 0, NULL, 1, '会计期间主数据',     'system', CURRENT_TIMESTAMP);
REPLACE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
VALUES (200010, 'FIN_VOUCHER_TPL',  '凭证模板', 'master',  'fin_voucher_tpl',   'id', 'snowflake', 0, 0, 0, NULL, 1, '凭证模板主数据',     'system', CURRENT_TIMESTAMP);
REPLACE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
VALUES (200011, 'FIN_VOUCHER',      '凭证',     'master',  'fin_voucher',       'id', 'snowflake', 0, 0, 0, NULL, 1, '会计凭证主数据',     'system', CURRENT_TIMESTAMP);
-- Phase 3c：成本核算（3 bo_code）
REPLACE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
VALUES (200012, 'FIN_COST_COLLECT', '成本归集', 'master',  'fin_cost_collect',  'id', 'snowflake', 0, 0, 0, NULL, 1, '成本归集主数据',     'system', CURRENT_TIMESTAMP);
REPLACE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
VALUES (200013, 'FIN_COST_POOL',    '制造费用池', 'master', 'fin_mfg_cost_pool', 'id', 'snowflake', 0, 0, 0, NULL, 1, '制造费用池主数据',   'system', CURRENT_TIMESTAMP);
REPLACE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
VALUES (200014, 'FIN_COST_VARIANCE', '成本差异', 'master',  'fin_cost_variance', 'id', 'snowflake', 0, 0, 0, NULL, 1, '成本差异主数据',     'system', CURRENT_TIMESTAMP);


-- ============================================================
-- 2. 状态机定义（meta_state_machine）—— 5 行，仅业务单据
--    StateMachineCache.load(boCode) 通过 code=bo_code 查询
-- ============================================================

REPLACE INTO meta_state_machine (id, code, name, state_field, remark)
VALUES (200100, 'FIN_AR',           '应收单状态机',   'pact_state', '复制 STD_5STATE：0暂存/1已创建/2已提交/3已审核/4已驳回；is_closed/is_cancel 辅助标记');
REPLACE INTO meta_state_machine (id, code, name, state_field, remark)
VALUES (200101, 'FIN_RECEIPT',      '收款单状态机',   'pact_state', '复制 STD_5STATE：0暂存/1已创建/2已提交/3已审核/4已驳回；is_closed/is_cancel 辅助标记');
REPLACE INTO meta_state_machine (id, code, name, state_field, remark)
VALUES (200102, 'FIN_PAYMENT',      '付款单状态机',   'pact_state', '复制 STD_5STATE：0暂存/1已创建/2已提交/3已审核/4已驳回；is_closed/is_cancel 辅助标记');
REPLACE INTO meta_state_machine (id, code, name, state_field, remark)
VALUES (200103, 'FIN_WRITEOFF',     '核销单状态机',   'pact_state', '复制 STD_5STATE：0暂存/1已创建/2已提交/3已审核/4已驳回；is_closed/is_cancel 辅助标记');
REPLACE INTO meta_state_machine (id, code, name, state_field, remark)
VALUES (200104, 'FIN_CUST_RECEIPT', '客户回款状态机', 'pact_state', '复制 STD_5STATE：0暂存/1已创建/2已提交/3已审核/4已驳回；is_closed/is_cancel 辅助标记');


-- ============================================================
-- 3. 状态节点（meta_state_node）—— 5×5=25 行
--    复制 STD_5STATE 节点（machine_id=100 的 id=101-105），替换 machine_id
--    0暂存(初始) 1已创建 2已提交 3已审核 4已驳回
-- ============================================================

-- 3.1 FIN_AR (machine_id=200100) —— id=200200-200204
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (200200, 200100, 0, '暂存',   '#909399', 1, 0, 1, 1, 0);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (200201, 200100, 1, '已创建', '#409EFF', 0, 0, 1, 1, 1);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (200202, 200100, 2, '已提交', '#E6A23C', 0, 0, 0, 0, 2);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (200203, 200100, 3, '已审核', '#67C23A', 0, 0, 0, 0, 3);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (200204, 200100, 4, '已驳回', '#F56C6C', 0, 0, 1, 1, 4);

-- 3.2 FIN_RECEIPT (machine_id=200101) —— id=200205-200209
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (200205, 200101, 0, '暂存',   '#909399', 1, 0, 1, 1, 0);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (200206, 200101, 1, '已创建', '#409EFF', 0, 0, 1, 1, 1);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (200207, 200101, 2, '已提交', '#E6A23C', 0, 0, 0, 0, 2);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (200208, 200101, 3, '已审核', '#67C23A', 0, 0, 0, 0, 3);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (200209, 200101, 4, '已驳回', '#F56C6C', 0, 0, 1, 1, 4);

-- 3.3 FIN_PAYMENT (machine_id=200102) —— id=200210-200214
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (200210, 200102, 0, '暂存',   '#909399', 1, 0, 1, 1, 0);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (200211, 200102, 1, '已创建', '#409EFF', 0, 0, 1, 1, 1);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (200212, 200102, 2, '已提交', '#E6A23C', 0, 0, 0, 0, 2);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (200213, 200102, 3, '已审核', '#67C23A', 0, 0, 0, 0, 3);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (200214, 200102, 4, '已驳回', '#F56C6C', 0, 0, 1, 1, 4);

-- 3.4 FIN_WRITEOFF (machine_id=200103) —— id=200215-200219
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (200215, 200103, 0, '暂存',   '#909399', 1, 0, 1, 1, 0);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (200216, 200103, 1, '已创建', '#409EFF', 0, 0, 1, 1, 1);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (200217, 200103, 2, '已提交', '#E6A23C', 0, 0, 0, 0, 2);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (200218, 200103, 3, '已审核', '#67C23A', 0, 0, 0, 0, 3);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (200219, 200103, 4, '已驳回', '#F56C6C', 0, 0, 1, 1, 4);

-- 3.5 FIN_CUST_RECEIPT (machine_id=200104) —— id=200220-200224
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (200220, 200104, 0, '暂存',   '#909399', 1, 0, 1, 1, 0);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (200221, 200104, 1, '已创建', '#409EFF', 0, 0, 1, 1, 1);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (200222, 200104, 2, '已提交', '#E6A23C', 0, 0, 0, 0, 2);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (200223, 200104, 3, '已审核', '#67C23A', 0, 0, 0, 0, 3);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (200224, 200104, 4, '已驳回', '#F56C6C', 0, 0, 1, 1, 4);


-- ============================================================
-- 4. 状态流转（meta_state_transition）—— 5×17=85 行
--    复制 STD_5STATE 流转（machine_id=100 的 id=200-216），替换 machine_id
--    t1-t11+t16+t17 无 post_action；t12-t15 含 post_action
-- ============================================================

-- 4.1 FIN_AR (machine_id=200100) —— id=200300-200316
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200300, 200100, 0,  1, '保存',     'save',     0, 0, 1);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200301, 200100, 0,  0, '暂存',     'draft',    0, 0, 2);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200302, 200100, 1,  2, '提交',     'submit',   1, 0, 3);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200303, 200100, 2,  3, '审核',     'audit',    0, 0, 4);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200304, 200100, 2,  4, '驳回',     'reject',   0, 1, 5);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200305, 200100, 4,  2, '重新提交', 'resubmit', 1, 0, 6);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200306, 200100, 2,  1, '撤销',     'revoke',   0, 0, 7);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200307, 200100, 3,  1, '撤销',     'revoke',   0, 0, 8);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200308, 200100, 0, -1, '删除',     'delete',   0, 0, 9);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200309, 200100, 1, -1, '删除',     'delete',   0, 0, 10);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200310, 200100, 4, -1, '删除',     'delete',   0, 0, 11);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (200311, 200100, 3, 3, '关闭',   'close',  'is_closed=1', 0, 0, 12);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (200312, 200100, 3, 3, '反关闭', 'close',  'is_closed=0', 0, 0, 13);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (200313, 200100, 3, 3, '取消',   'cancel', 'is_cancel=1', 0, 1, 14);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (200314, 200100, 3, 3, '反取消', 'cancel', 'is_cancel=0', 0, 0, 15);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200315, 200100, 3,  3, '变更',     'change',   1, 1, 16);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200316, 200100, 3,  3, '下推',     'push',     0, 0, 17);

-- 4.2 FIN_RECEIPT (machine_id=200101) —— id=200317-200333
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200317, 200101, 0,  1, '保存',     'save',     0, 0, 1);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200318, 200101, 0,  0, '暂存',     'draft',    0, 0, 2);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200319, 200101, 1,  2, '提交',     'submit',   1, 0, 3);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200320, 200101, 2,  3, '审核',     'audit',    0, 0, 4);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200321, 200101, 2,  4, '驳回',     'reject',   0, 1, 5);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200322, 200101, 4,  2, '重新提交', 'resubmit', 1, 0, 6);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200323, 200101, 2,  1, '撤销',     'revoke',   0, 0, 7);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200324, 200101, 3,  1, '撤销',     'revoke',   0, 0, 8);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200325, 200101, 0, -1, '删除',     'delete',   0, 0, 9);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200326, 200101, 1, -1, '删除',     'delete',   0, 0, 10);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200327, 200101, 4, -1, '删除',     'delete',   0, 0, 11);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (200328, 200101, 3, 3, '关闭',   'close',  'is_closed=1', 0, 0, 12);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (200329, 200101, 3, 3, '反关闭', 'close',  'is_closed=0', 0, 0, 13);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (200330, 200101, 3, 3, '取消',   'cancel', 'is_cancel=1', 0, 1, 14);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (200331, 200101, 3, 3, '反取消', 'cancel', 'is_cancel=0', 0, 0, 15);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200332, 200101, 3,  3, '变更',     'change',   1, 1, 16);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200333, 200101, 3,  3, '下推',     'push',     0, 0, 17);

-- 4.3 FIN_PAYMENT (machine_id=200102) —— id=200334-200350
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200334, 200102, 0,  1, '保存',     'save',     0, 0, 1);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200335, 200102, 0,  0, '暂存',     'draft',    0, 0, 2);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200336, 200102, 1,  2, '提交',     'submit',   1, 0, 3);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200337, 200102, 2,  3, '审核',     'audit',    0, 0, 4);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200338, 200102, 2,  4, '驳回',     'reject',   0, 1, 5);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200339, 200102, 4,  2, '重新提交', 'resubmit', 1, 0, 6);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200340, 200102, 2,  1, '撤销',     'revoke',   0, 0, 7);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200341, 200102, 3,  1, '撤销',     'revoke',   0, 0, 8);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200342, 200102, 0, -1, '删除',     'delete',   0, 0, 9);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200343, 200102, 1, -1, '删除',     'delete',   0, 0, 10);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200344, 200102, 4, -1, '删除',     'delete',   0, 0, 11);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (200345, 200102, 3, 3, '关闭',   'close',  'is_closed=1', 0, 0, 12);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (200346, 200102, 3, 3, '反关闭', 'close',  'is_closed=0', 0, 0, 13);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (200347, 200102, 3, 3, '取消',   'cancel', 'is_cancel=1', 0, 1, 14);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (200348, 200102, 3, 3, '反取消', 'cancel', 'is_cancel=0', 0, 0, 15);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200349, 200102, 3,  3, '变更',     'change',   1, 1, 16);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200350, 200102, 3,  3, '下推',     'push',     0, 0, 17);

-- 4.4 FIN_WRITEOFF (machine_id=200103) —— id=200351-200367
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200351, 200103, 0,  1, '保存',     'save',     0, 0, 1);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200352, 200103, 0,  0, '暂存',     'draft',    0, 0, 2);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200353, 200103, 1,  2, '提交',     'submit',   1, 0, 3);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200354, 200103, 2,  3, '审核',     'audit',    0, 0, 4);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200355, 200103, 2,  4, '驳回',     'reject',   0, 1, 5);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200356, 200103, 4,  2, '重新提交', 'resubmit', 1, 0, 6);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200357, 200103, 2,  1, '撤销',     'revoke',   0, 0, 7);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200358, 200103, 3,  1, '撤销',     'revoke',   0, 0, 8);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200359, 200103, 0, -1, '删除',     'delete',   0, 0, 9);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200360, 200103, 1, -1, '删除',     'delete',   0, 0, 10);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200361, 200103, 4, -1, '删除',     'delete',   0, 0, 11);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (200362, 200103, 3, 3, '关闭',   'close',  'is_closed=1', 0, 0, 12);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (200363, 200103, 3, 3, '反关闭', 'close',  'is_closed=0', 0, 0, 13);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (200364, 200103, 3, 3, '取消',   'cancel', 'is_cancel=1', 0, 1, 14);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (200365, 200103, 3, 3, '反取消', 'cancel', 'is_cancel=0', 0, 0, 15);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200366, 200103, 3,  3, '变更',     'change',   1, 1, 16);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200367, 200103, 3,  3, '下推',     'push',     0, 0, 17);

-- 4.5 FIN_CUST_RECEIPT (machine_id=200104) —— id=200368-200384
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200368, 200104, 0,  1, '保存',     'save',     0, 0, 1);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200369, 200104, 0,  0, '暂存',     'draft',    0, 0, 2);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200370, 200104, 1,  2, '提交',     'submit',   1, 0, 3);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200371, 200104, 2,  3, '审核',     'audit',    0, 0, 4);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200372, 200104, 2,  4, '驳回',     'reject',   0, 1, 5);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200373, 200104, 4,  2, '重新提交', 'resubmit', 1, 0, 6);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200374, 200104, 2,  1, '撤销',     'revoke',   0, 0, 7);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200375, 200104, 3,  1, '撤销',     'revoke',   0, 0, 8);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200376, 200104, 0, -1, '删除',     'delete',   0, 0, 9);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200377, 200104, 1, -1, '删除',     'delete',   0, 0, 10);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200378, 200104, 4, -1, '删除',     'delete',   0, 0, 11);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (200379, 200104, 3, 3, '关闭',   'close',  'is_closed=1', 0, 0, 12);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (200380, 200104, 3, 3, '反关闭', 'close',  'is_closed=0', 0, 0, 13);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (200381, 200104, 3, 3, '取消',   'cancel', 'is_cancel=1', 0, 1, 14);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (200382, 200104, 3, 3, '反取消', 'cancel', 'is_cancel=0', 0, 0, 15);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200383, 200104, 3,  3, '变更',     'change',   1, 1, 16);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (200384, 200104, 3,  3, '下推',     'push',     0, 0, 17);


-- ============================================================
-- 5. 表单实体层级（meta_form_entity）—— 14 主 + 5 子 = 19 行
--    主表 entity_code=main_table；子表 entity_code 按业务命名（detail/entry）
-- ============================================================

-- 5.1 主实体（entity_type='main', entity_level=0）—— 14 行
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (200600, 'FIN_EST_AP',        'fin_est_ap',        '暂估应付',   'main', 0, 'fin_est_ap',        NULL, NULL, 1);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (200601, 'FIN_AR',            'fin_ar',            '应收单',     'main', 0, 'fin_ar',            NULL, NULL, 1);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (200602, 'FIN_AP',            'fin_ap',            '应付单',     'main', 0, 'fin_ap',            NULL, NULL, 1);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (200603, 'FIN_RECEIPT',       'fin_receipt',       '收款单',     'main', 0, 'fin_receipt',       NULL, NULL, 1);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (200605, 'FIN_PAYMENT',       'fin_payment',       '付款单',     'main', 0, 'fin_payment',       NULL, NULL, 1);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (200607, 'FIN_WRITEOFF',      'fin_writeoff',      '核销单',     'main', 0, 'fin_writeoff',      NULL, NULL, 1);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (200608, 'FIN_CUST_RECEIPT',  'fin_cust_receipt',  '客户回款',   'main', 0, 'fin_cust_receipt',  NULL, NULL, 1);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (200610, 'FIN_ACCOUNT',       'fin_account',       '会计科目',   'main', 0, 'fin_account',       NULL, NULL, 1);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (200611, 'FIN_PERIOD',        'fin_period',        '会计期间',   'main', 0, 'fin_period',        NULL, NULL, 1);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (200612, 'FIN_VOUCHER_TPL',   'fin_voucher_tpl',   '凭证模板',   'main', 0, 'fin_voucher_tpl',   NULL, NULL, 1);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (200614, 'FIN_VOUCHER',       'fin_voucher',       '凭证',       'main', 0, 'fin_voucher',       NULL, NULL, 1);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (200616, 'FIN_COST_COLLECT',  'fin_cost_collect',  '成本归集',   'main', 0, 'fin_cost_collect',  NULL, NULL, 1);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (200617, 'FIN_COST_POOL',     'fin_mfg_cost_pool', '制造费用池', 'main', 0, 'fin_mfg_cost_pool', NULL, NULL, 1);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (200618, 'FIN_COST_VARIANCE', 'fin_cost_variance', '成本差异',   'main', 0, 'fin_cost_variance', NULL, NULL, 1);

-- 5.2 子实体（entity_type='sub', entity_level=1）—— 5 行
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (200604, 'FIN_RECEIPT',       'detail', '收款核销明细', 'sub', 1, 'fin_receipt_detail',     'fin_receipt',      'receipt_id',      2);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (200606, 'FIN_PAYMENT',       'detail', '付款核销明细', 'sub', 1, 'fin_payment_detail',     'fin_payment',      'payment_id',      2);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (200609, 'FIN_CUST_RECEIPT',  'detail', '回款认领明细', 'sub', 1, 'fin_cust_receipt_detail', 'fin_cust_receipt', 'cust_receipt_id', 2);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (200613, 'FIN_VOUCHER_TPL',   'entry',  '凭证模板分录', 'sub', 1, 'fin_voucher_tpl_entry',  'fin_voucher_tpl',  'tpl_id',          2);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (200615, 'FIN_VOUCHER',       'entry',  '凭证分录',     'sub', 1, 'fin_voucher_entry',      'fin_voucher',      'voucher_id',      2);


-- ============================================================
-- 6. 表单字段元数据（meta_form_field）—— 193 行
--    仅注册关键字段（编码/日期/状态 + 组织/人员/客户/供应商外键 + 金额 + 备注 + 审计字段）
--    字段类型：text/number/date/datetime/enum/ref/qty/amount
--    控件类型：text/textarea/number/date/datetime/select/ref/qty/amount
--    ref 字段附带 ref_bo_code；ID 区间 240300-240492
-- ============================================================

-- ------------------------------------------------------------
-- 6.1 FIN_EST_AP 暂估应付（主表 fin_est_ap，10 字段）
-- ------------------------------------------------------------
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240300, 'FIN_EST_AP', 'fin_est_ap', 'code',          '单据编码', 'text',   'text',     1, 0, 1,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240301, 'FIN_EST_AP', 'fin_est_ap', 'src_bill_type', '来源单类型', 'text', 'text',     0, 0, 2,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (240302, 'FIN_EST_AP', 'fin_est_ap', 'supplier_id',   '供应商',   'ref',    'ref',      1, 0, 'MD_SUPPLIER', 3,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (240303, 'FIN_EST_AP', 'fin_est_ap', 'org_id',        '组织',     'ref',    'ref',      0, 0, 'MD_ORG',      4,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (240304, 'FIN_EST_AP', 'fin_est_ap', 'curr_id',       '币别',     'ref',    'ref',      0, 0, 'MD_CURRENCY', 5,  '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240305, 'FIN_EST_AP', 'fin_est_ap', 'est_amount',    '暂估金额', 'amount', 'amount',   0, 1, 6,  '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240306, 'FIN_EST_AP', 'fin_est_ap', 'settle_amount', '已结算金额', 'amount', 'amount', 0, 1, 7,  '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240307, 'FIN_EST_AP', 'fin_est_ap', 'balance',       '余额',     'amount', 'amount',   0, 1, 8,  '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240308, 'FIN_EST_AP', 'fin_est_ap', 'status',        '状态',     'enum',   'select',   0, 0, 9,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240309, 'FIN_EST_AP', 'fin_est_ap', 'voucher_id',    '凭证',     'number', 'number',   0, 1, 10, '业务信息');

-- ------------------------------------------------------------
-- 6.2 FIN_AR 应收单（主表 fin_ar，17 字段）
-- ------------------------------------------------------------
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240310, 'FIN_AR', 'fin_ar', 'code',           '单据编码', 'text',   'text',     1, 0, 1,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240311, 'FIN_AR', 'fin_ar', 'bill_date',      '单据日期', 'date',   'date',     1, 0, 2,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240312, 'FIN_AR', 'fin_ar', 'pact_state',     '单据状态', 'enum',   'select',   0, 1, 3,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (240313, 'FIN_AR', 'fin_ar', 'cust_id',        '客户',     'ref',    'ref',      1, 0, 'MD_CUSTOMER', 4,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (240314, 'FIN_AR', 'fin_ar', 'org_id',         '组织',     'ref',    'ref',      0, 0, 'MD_ORG',      5,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (240315, 'FIN_AR', 'fin_ar', 'curr_id',        '币别',     'ref',    'ref',      0, 0, 'MD_CURRENCY', 6,  '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240316, 'FIN_AR', 'fin_ar', 'amount',         '金额',     'amount', 'amount',   0, 1, 7,  '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240317, 'FIN_AR', 'fin_ar', 'no_tax_amount',  '不含税金额', 'amount', 'amount', 0, 1, 8,  '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240318, 'FIN_AR', 'fin_ar', 'tax_amount',     '税额',     'amount', 'amount',   0, 1, 9,  '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240319, 'FIN_AR', 'fin_ar', 'settled_amount', '已核销金额', 'amount', 'amount', 0, 1, 10, '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240320, 'FIN_AR', 'fin_ar', 'balance',        '余额',     'amount', 'amount',   0, 1, 11, '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240321, 'FIN_AR', 'fin_ar', 'due_date',       '到期日',   'date',   'date',     0, 0, 12, '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240322, 'FIN_AR', 'fin_ar', 'status',         '财务状态', 'enum',   'select',   0, 0, 13, '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (240323, 'FIN_AR', 'fin_ar', 'dept_id',        '部门',     'ref',    'ref',      0, 0, 'MD_DEPT',     14, '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (240324, 'FIN_AR', 'fin_ar', 'saler_id',       '业务员',   'ref',    'ref',      0, 0, 'MD_SALER',    15, '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240325, 'FIN_AR', 'fin_ar', 'remark',         '备注',     'text',   'textarea', 0, 0, 16, '其他');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (240326, 'FIN_AR', 'fin_ar', 'auditor',        '审核人',   'ref',    'ref',      0, 1, 'MD_EMPLOYEE', 17, '审计信息');

-- ------------------------------------------------------------
-- 6.3 FIN_AP 应付单（主表 fin_ap，14 字段）
-- ------------------------------------------------------------
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240327, 'FIN_AP', 'fin_ap', 'code',           '单据编码', 'text',   'text',     1, 0, 1,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240328, 'FIN_AP', 'fin_ap', 'bill_date',      '单据日期', 'date',   'date',     1, 0, 2,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (240329, 'FIN_AP', 'fin_ap', 'supplier_id',    '供应商',   'ref',    'ref',      1, 0, 'MD_SUPPLIER', 3,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (240330, 'FIN_AP', 'fin_ap', 'org_id',         '组织',     'ref',    'ref',      0, 0, 'MD_ORG',      4,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (240331, 'FIN_AP', 'fin_ap', 'curr_id',        '币别',     'ref',    'ref',      0, 0, 'MD_CURRENCY', 5,  '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240332, 'FIN_AP', 'fin_ap', 'amount',         '金额',     'amount', 'amount',   0, 1, 6,  '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240333, 'FIN_AP', 'fin_ap', 'no_tax_amount',  '不含税金额', 'amount', 'amount', 0, 1, 7,  '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240334, 'FIN_AP', 'fin_ap', 'tax_amount',     '税额',     'amount', 'amount',   0, 1, 8,  '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240335, 'FIN_AP', 'fin_ap', 'settled_amount', '已核销金额', 'amount', 'amount', 0, 1, 9,  '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240336, 'FIN_AP', 'fin_ap', 'balance',        '余额',     'amount', 'amount',   0, 1, 10, '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240337, 'FIN_AP', 'fin_ap', 'due_date',       '到期日',   'date',   'date',     0, 0, 11, '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240338, 'FIN_AP', 'fin_ap', 'status',         '财务状态', 'enum',   'select',   0, 0, 12, '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240339, 'FIN_AP', 'fin_ap', 'voucher_id',     '凭证',     'number', 'number',   0, 1, 13, '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240340, 'FIN_AP', 'fin_ap', 'src_bill_type',  '来源单类型', 'text', 'text',     0, 0, 14, '基本信息');

-- ------------------------------------------------------------
-- 6.4 FIN_RECEIPT 收款单（主表 fin_receipt 12 字段 + 子表 fin_receipt_detail 6 字段 = 18 字段）
-- ------------------------------------------------------------
-- 主表 fin_receipt（12 字段）
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240341, 'FIN_RECEIPT', 'fin_receipt', 'code',          '单据编码', 'text',   'text',     1, 0, 1,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240342, 'FIN_RECEIPT', 'fin_receipt', 'receipt_date',  '收款日期', 'date',   'date',     1, 0, 2,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240343, 'FIN_RECEIPT', 'fin_receipt', 'pact_state',    '单据状态', 'enum',   'select',   0, 1, 3,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (240344, 'FIN_RECEIPT', 'fin_receipt', 'cust_id',       '客户',     'ref',    'ref',      1, 0, 'MD_CUSTOMER', 4,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (240345, 'FIN_RECEIPT', 'fin_receipt', 'org_id',        '组织',     'ref',    'ref',      0, 0, 'MD_ORG',      5,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (240346, 'FIN_RECEIPT', 'fin_receipt', 'curr_id',       '币别',     'ref',    'ref',      0, 0, 'MD_CURRENCY', 6,  '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240347, 'FIN_RECEIPT', 'fin_receipt', 'amount',        '金额',     'amount', 'amount',   0, 1, 7,  '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240348, 'FIN_RECEIPT', 'fin_receipt', 'total_amount',  '总金额',   'amount', 'amount',   0, 1, 8,  '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240349, 'FIN_RECEIPT', 'fin_receipt', 'firp_type',     '结算方式', 'text',   'text',     0, 0, 9,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240350, 'FIN_RECEIPT', 'fin_receipt', 'bank_account',  '银行账号', 'text',   'text',     0, 0, 10, '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240351, 'FIN_RECEIPT', 'fin_receipt', 'remark',        '备注',     'text',   'textarea', 0, 0, 11, '其他');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (240352, 'FIN_RECEIPT', 'fin_receipt', 'auditor',       '审核人',   'ref',    'ref',      0, 1, 'MD_EMPLOYEE', 12, '审计信息');
-- 子表 fin_receipt_detail / detail（6 字段）
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240353, 'FIN_RECEIPT', 'detail', 'sort_index',       '行号',     'number', 'number',   0, 0, 1, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240354, 'FIN_RECEIPT', 'detail', 'receipt_id',       '收款单',   'number', 'number',   1, 1, 2, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240355, 'FIN_RECEIPT', 'detail', 'ar_id',            '应收单',   'number', 'number',   0, 0, 3, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240356, 'FIN_RECEIPT', 'detail', 'settle_amount',    '核销金额', 'amount', 'amount',   0, 0, 4, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240357, 'FIN_RECEIPT', 'detail', 'discount_amount',  '折扣金额', 'amount', 'amount',   0, 0, 5, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240358, 'FIN_RECEIPT', 'detail', 'exchange_diff',    '汇兑差额', 'amount', 'amount',   0, 0, 6, '明细信息');

-- ------------------------------------------------------------
-- 6.5 FIN_PAYMENT 付款单（主表 fin_payment 13 字段 + 子表 fin_payment_detail 5 字段 = 18 字段）
-- ------------------------------------------------------------
-- 主表 fin_payment（13 字段）
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240359, 'FIN_PAYMENT', 'fin_payment', 'code',          '单据编码', 'text',   'text',     1, 0, 1,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240360, 'FIN_PAYMENT', 'fin_payment', 'payment_date',  '付款日期', 'date',   'date',     1, 0, 2,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240361, 'FIN_PAYMENT', 'fin_payment', 'pact_state',    '单据状态', 'enum',   'select',   0, 1, 3,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (240362, 'FIN_PAYMENT', 'fin_payment', 'supplier_id',   '供应商',   'ref',    'ref',      1, 0, 'MD_SUPPLIER', 4,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (240363, 'FIN_PAYMENT', 'fin_payment', 'org_id',        '组织',     'ref',    'ref',      0, 0, 'MD_ORG',      5,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (240364, 'FIN_PAYMENT', 'fin_payment', 'curr_id',       '币别',     'ref',    'ref',      0, 0, 'MD_CURRENCY', 6,  '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240365, 'FIN_PAYMENT', 'fin_payment', 'amount',        '金额',     'amount', 'amount',   0, 1, 7,  '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240366, 'FIN_PAYMENT', 'fin_payment', 'pay_type',      '付款类型', 'text',   'text',     0, 0, 8,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240367, 'FIN_PAYMENT', 'fin_payment', 'bank_account',  '银行账号', 'text',   'text',     0, 0, 9,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240368, 'FIN_PAYMENT', 'fin_payment', 'is_pre',        '是否预付', 'enum',   'select',   0, 0, 10, '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240369, 'FIN_PAYMENT', 'fin_payment', 'voucher_id',    '凭证',     'number', 'number',   0, 1, 11, '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240370, 'FIN_PAYMENT', 'fin_payment', 'remark',        '备注',     'text',   'textarea', 0, 0, 12, '其他');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (240371, 'FIN_PAYMENT', 'fin_payment', 'auditor',       '审核人',   'ref',    'ref',      0, 1, 'MD_EMPLOYEE', 13, '审计信息');
-- 子表 fin_payment_detail / detail（5 字段）
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240372, 'FIN_PAYMENT', 'detail', 'sort_index',    '行号',     'number', 'number',   0, 0, 1, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240373, 'FIN_PAYMENT', 'detail', 'payment_id',    '付款单',   'number', 'number',   1, 1, 2, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240374, 'FIN_PAYMENT', 'detail', 'ap_id',         '应付单',   'number', 'number',   0, 0, 3, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240375, 'FIN_PAYMENT', 'detail', 'settle_amount', '核销金额', 'amount', 'amount',   0, 0, 4, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240376, 'FIN_PAYMENT', 'detail', 'exchange_diff', '汇兑差额', 'amount', 'amount',   0, 0, 5, '明细信息');

-- ------------------------------------------------------------
-- 6.6 FIN_WRITEOFF 核销单（主表 fin_writeoff，17 字段）
-- ------------------------------------------------------------
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240377, 'FIN_WRITEOFF', 'fin_writeoff', 'code',           '单据编码', 'text',   'text',     1, 0, 1,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240378, 'FIN_WRITEOFF', 'fin_writeoff', 'writeoff_date',  '核销日期', 'date',   'date',     1, 0, 2,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240379, 'FIN_WRITEOFF', 'fin_writeoff', 'pact_state',     '单据状态', 'enum',   'select',   0, 1, 3,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240380, 'FIN_WRITEOFF', 'fin_writeoff', 'biz_type',       '业务类型', 'text',   'text',     0, 0, 4,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240381, 'FIN_WRITEOFF', 'fin_writeoff', 'rec_bill_type',  '核销单类型', 'text', 'text',     0, 0, 5,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240382, 'FIN_WRITEOFF', 'fin_writeoff', 'rec_bill_id',    '核销单ID', 'number', 'number',   0, 1, 6,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240383, 'FIN_WRITEOFF', 'fin_writeoff', 'settle_amount',  '核销金额', 'amount', 'amount',   0, 1, 7,  '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240384, 'FIN_WRITEOFF', 'fin_writeoff', 'discount_amount', '折扣金额', 'amount', 'amount',   0, 0, 8,  '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240385, 'FIN_WRITEOFF', 'fin_writeoff', 'exchange_diff',  '汇兑差额', 'amount', 'amount',   0, 0, 9,  '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (240386, 'FIN_WRITEOFF', 'fin_writeoff', 'org_id',         '组织',     'ref',    'ref',      0, 0, 'MD_ORG',      10, '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (240387, 'FIN_WRITEOFF', 'fin_writeoff', 'cust_id',        '客户',     'ref',    'ref',      0, 0, 'MD_CUSTOMER', 11, '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (240388, 'FIN_WRITEOFF', 'fin_writeoff', 'curr_id',        '币别',     'ref',    'ref',      0, 0, 'MD_CURRENCY', 12, '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240389, 'FIN_WRITEOFF', 'fin_writeoff', 'cur_hx_amount',  '本币核销金额', 'amount', 'amount', 0, 1, 13, '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240390, 'FIN_WRITEOFF', 'fin_writeoff', 'status',         '状态',     'enum',   'select',   0, 0, 14, '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240391, 'FIN_WRITEOFF', 'fin_writeoff', 'is_init',        '是否期初', 'enum',   'select',   0, 0, 15, '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240392, 'FIN_WRITEOFF', 'fin_writeoff', 'remark',         '备注',     'text',   'textarea', 0, 0, 16, '其他');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (240393, 'FIN_WRITEOFF', 'fin_writeoff', 'auditor',        '审核人',   'ref',    'ref',      0, 1, 'MD_EMPLOYEE', 17, '审计信息');

-- ------------------------------------------------------------
-- 6.7 FIN_CUST_RECEIPT 客户回款（主表 fin_cust_receipt 13 字段 + 子表 fin_cust_receipt_detail 7 字段 = 20 字段）
-- ------------------------------------------------------------
-- 主表 fin_cust_receipt（13 字段）
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240394, 'FIN_CUST_RECEIPT', 'fin_cust_receipt', 'code',          '单据编码', 'text',   'text',     1, 0, 1,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240395, 'FIN_CUST_RECEIPT', 'fin_cust_receipt', 'pact_date',     '单据日期', 'date',   'date',     1, 0, 2,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240396, 'FIN_CUST_RECEIPT', 'fin_cust_receipt', 'pact_state',    '单据状态', 'enum',   'select',   0, 1, 3,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (240397, 'FIN_CUST_RECEIPT', 'fin_cust_receipt', 'sal_org_id',    '销售组织', 'ref',    'ref',      0, 0, 'MD_ORG',      4,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (240398, 'FIN_CUST_RECEIPT', 'fin_cust_receipt', 'cust_id',       '客户',     'ref',    'ref',      1, 0, 'MD_CUSTOMER', 5,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (240399, 'FIN_CUST_RECEIPT', 'fin_cust_receipt', 'curr_id',       '币别',     'ref',    'ref',      0, 0, 'MD_CURRENCY', 6,  '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240400, 'FIN_CUST_RECEIPT', 'fin_cust_receipt', 'rec_type',      '回款方式', 'text',   'text',     0, 0, 7,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240401, 'FIN_CUST_RECEIPT', 'fin_cust_receipt', 'rec_amount',    '回款金额', 'amount', 'amount',   0, 1, 8,  '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240402, 'FIN_CUST_RECEIPT', 'fin_cust_receipt', 'claim_amount',  '已认领金额', 'amount', 'amount', 0, 1, 9,  '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240403, 'FIN_CUST_RECEIPT', 'fin_cust_receipt', 'unclaim_amount', '未认领金额', 'amount', 'amount', 0, 1, 10, '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240404, 'FIN_CUST_RECEIPT', 'fin_cust_receipt', 'remark',        '备注',     'text',   'textarea', 0, 0, 11, '其他');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240405, 'FIN_CUST_RECEIPT', 'fin_cust_receipt', 'is_closed',     '是否关闭', 'enum',   'select',   0, 1, 12, '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (240406, 'FIN_CUST_RECEIPT', 'fin_cust_receipt', 'auditor',       '审核人',   'ref',    'ref',      0, 1, 'MD_EMPLOYEE', 13, '审计信息');
-- 子表 fin_cust_receipt_detail / detail（7 字段）
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240407, 'FIN_CUST_RECEIPT', 'detail', 'sort_index',     '行号',     'number', 'number',   0, 0, 1, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240408, 'FIN_CUST_RECEIPT', 'detail', 'cust_receipt_id', '回款单',   'number', 'number',   1, 1, 2, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (240409, 'FIN_CUST_RECEIPT', 'detail', 'saler_id',       '业务员',   'ref',    'ref',      0, 0, 'MD_SALER',    3, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (240410, 'FIN_CUST_RECEIPT', 'detail', 'dept_id',        '部门',     'ref',    'ref',      0, 0, 'MD_DEPT',     4, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240411, 'FIN_CUST_RECEIPT', 'detail', 'claim_date',     '认领日期', 'date',   'date',     0, 0, 5, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240412, 'FIN_CUST_RECEIPT', 'detail', 'claim_amount',   '认领金额', 'amount', 'amount',   0, 0, 6, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240413, 'FIN_CUST_RECEIPT', 'detail', 'claim_state',    '认领状态', 'text',   'text',     0, 0, 7, '明细信息');

-- ------------------------------------------------------------
-- 6.8 FIN_ACCOUNT 会计科目（主表 fin_account，8 字段）
-- ------------------------------------------------------------
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240414, 'FIN_ACCOUNT', 'fin_account', 'code',          '科目编码', 'text',   'text',     1, 0, 1,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240415, 'FIN_ACCOUNT', 'fin_account', 'name',          '科目名称', 'text',   'text',     1, 0, 2,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240416, 'FIN_ACCOUNT', 'fin_account', 'account_class', '科目类别', 'text',   'text',     0, 0, 3,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240417, 'FIN_ACCOUNT', 'fin_account', 'dc_direction',  '借贷方向', 'enum',   'select',   0, 0, 4,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240418, 'FIN_ACCOUNT', 'fin_account', 'parent_id',     '上级科目', 'number', 'number',   0, 0, 5,  '层级信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240419, 'FIN_ACCOUNT', 'fin_account', 'is_leaf',       '是否末级', 'enum',   'select',   0, 0, 6,  '层级信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240420, 'FIN_ACCOUNT', 'fin_account', 'aux_flag',      '辅助核算', 'enum',   'select',   0, 0, 7,  '辅助核算');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240421, 'FIN_ACCOUNT', 'fin_account', 'status',        '状态',     'enum',   'select',   0, 0, 8,  '基本信息');

-- ------------------------------------------------------------
-- 6.9 FIN_PERIOD 会计期间（主表 fin_period，7 字段）
-- ------------------------------------------------------------
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240422, 'FIN_PERIOD', 'fin_period', 'period_code',  '期间编码', 'text',   'text',     1, 0, 1,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240423, 'FIN_PERIOD', 'fin_period', 'year_no',      '年份',     'number', 'number',   1, 0, 2,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240424, 'FIN_PERIOD', 'fin_period', 'month_no',     '月份',     'number', 'number',   1, 0, 3,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240425, 'FIN_PERIOD', 'fin_period', 'start_date',   '开始日期', 'date',   'date',     0, 0, 4,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240426, 'FIN_PERIOD', 'fin_period', 'end_date',     '结束日期', 'date',   'date',     0, 0, 5,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240427, 'FIN_PERIOD', 'fin_period', 'status',       '期间状态', 'enum',   'select',   0, 0, 6,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (240428, 'FIN_PERIOD', 'fin_period', 'org_id',       '组织',     'ref',    'ref',      0, 0, 'MD_ORG', 7,  '业务信息');

-- ------------------------------------------------------------
-- 6.10 FIN_VOUCHER_TPL 凭证模板（主表 fin_voucher_tpl 7 字段 + 子表 fin_voucher_tpl_entry 6 字段 = 13 字段）
-- ------------------------------------------------------------
-- 主表 fin_voucher_tpl（7 字段）
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240429, 'FIN_VOUCHER_TPL', 'fin_voucher_tpl', 'code',          '模板编码', 'text',   'text',     1, 0, 1,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240430, 'FIN_VOUCHER_TPL', 'fin_voucher_tpl', 'name',          '模板名称', 'text',   'text',     1, 0, 2,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240431, 'FIN_VOUCHER_TPL', 'fin_voucher_tpl', 'src_bill_type', '来源单类型', 'text', 'text',     0, 0, 3,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (240432, 'FIN_VOUCHER_TPL', 'fin_voucher_tpl', 'org_id',        '组织',     'ref',    'ref',      0, 0, 'MD_ORG',      4,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240433, 'FIN_VOUCHER_TPL', 'fin_voucher_tpl', 'cur_type',      '币别类型', 'text',   'text',     0, 0, 5,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240434, 'FIN_VOUCHER_TPL', 'fin_voucher_tpl', 'status',        '状态',     'enum',   'select',   0, 0, 6,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240435, 'FIN_VOUCHER_TPL', 'fin_voucher_tpl', 'remark',        '备注',     'text',   'textarea', 0, 0, 7,  '其他');
-- 子表 fin_voucher_tpl_entry / entry（6 字段）
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240436, 'FIN_VOUCHER_TPL', 'entry', 'sort_index',     '行号',     'number', 'number',   0, 0, 1, '分录信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240437, 'FIN_VOUCHER_TPL', 'entry', 'tpl_id',         '模板',     'number', 'number',   1, 1, 2, '分录信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240438, 'FIN_VOUCHER_TPL', 'entry', 'dc',            '借贷方向', 'enum',   'select',   0, 0, 3, '分录信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240439, 'FIN_VOUCHER_TPL', 'entry', 'account_id',    '科目',     'number', 'number',   0, 0, 4, '分录信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240440, 'FIN_VOUCHER_TPL', 'entry', 'amount_source',  '金额来源', 'text',   'text',     0, 0, 5, '分录信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240441, 'FIN_VOUCHER_TPL', 'entry', 'summary',       '摘要',     'text',   'text',     0, 0, 6, '分录信息');

-- ------------------------------------------------------------
-- 6.11 FIN_VOUCHER 凭证（主表 fin_voucher 12 字段 + 子表 fin_voucher_entry 10 字段 = 22 字段）
-- ------------------------------------------------------------
-- 主表 fin_voucher（12 字段）
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240442, 'FIN_VOUCHER', 'fin_voucher', 'code',          '凭证编码', 'text',   'text',     1, 0, 1,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240443, 'FIN_VOUCHER', 'fin_voucher', 'voucher_date',  '凭证日期', 'date',   'date',     1, 0, 2,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240444, 'FIN_VOUCHER', 'fin_voucher', 'period_code',   '期间',     'text',   'text',     0, 0, 3,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (240445, 'FIN_VOUCHER', 'fin_voucher', 'org_id',        '组织',     'ref',    'ref',      0, 0, 'MD_ORG',      4,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240446, 'FIN_VOUCHER', 'fin_voucher', 'src_bill_type', '来源单类型', 'text', 'text',     0, 0, 5,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240447, 'FIN_VOUCHER', 'fin_voucher', 'src_bill_id',   '来源单ID', 'number', 'number',   0, 1, 6,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240448, 'FIN_VOUCHER', 'fin_voucher', 'attached_count', '附单据数', 'number', 'number',   0, 0, 7,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240449, 'FIN_VOUCHER', 'fin_voucher', 'total_debit',   '借方合计', 'amount', 'amount',   0, 1, 8,  '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240450, 'FIN_VOUCHER', 'fin_voucher', 'total_credit',  '贷方合计', 'amount', 'amount',   0, 1, 9,  '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240451, 'FIN_VOUCHER', 'fin_voucher', 'status',        '状态',     'enum',   'select',   0, 0, 10, '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240452, 'FIN_VOUCHER', 'fin_voucher', 'is_auto',       '是否自动', 'enum',   'select',   0, 1, 11, '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240453, 'FIN_VOUCHER', 'fin_voucher', 'remark',        '备注',     'text',   'textarea', 0, 0, 12, '其他');
-- 子表 fin_voucher_entry / entry（10 字段）
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240454, 'FIN_VOUCHER', 'entry', 'sort_index',   '行号',     'number', 'number',   0, 0, 1, '分录信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240455, 'FIN_VOUCHER', 'entry', 'voucher_id',   '凭证',     'number', 'number',   1, 1, 2, '分录信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240456, 'FIN_VOUCHER', 'entry', 'dc',          '借贷方向', 'enum',   'select',   0, 0, 3, '分录信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240457, 'FIN_VOUCHER', 'entry', 'account_id',  '科目',     'number', 'number',   0, 0, 4, '分录信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240458, 'FIN_VOUCHER', 'entry', 'amount',      '金额',     'amount', 'amount',   0, 0, 5, '分录信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240459, 'FIN_VOUCHER', 'entry', 'summary',     '摘要',     'text',   'text',     0, 0, 6, '分录信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240460, 'FIN_VOUCHER', 'entry', 'cust_id',     '客户',     'number', 'number',   0, 0, 7, '分录信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240461, 'FIN_VOUCHER', 'entry', 'supplier_id', '供应商',   'number', 'number',   0, 0, 8, '分录信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240462, 'FIN_VOUCHER', 'entry', 'mat_id',      '物料',     'number', 'number',   0, 0, 9, '分录信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240463, 'FIN_VOUCHER', 'entry', 'dept_id',     '部门',     'number', 'number',   0, 0, 10, '分录信息');

-- ------------------------------------------------------------
-- 6.12 FIN_COST_COLLECT 成本归集（主表 fin_cost_collect，13 字段）
-- ------------------------------------------------------------
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240464, 'FIN_COST_COLLECT', 'fin_cost_collect', 'period_code',  '期间',     'text',   'text',     1, 0, 1,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240465, 'FIN_COST_COLLECT', 'fin_cost_collect', 'mfg_order_id', '生产订单', 'number', 'number',   0, 0, 2,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240466, 'FIN_COST_COLLECT', 'fin_cost_collect', 'batch_no',     '批次号',   'text',   'text',     0, 0, 3,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240467, 'FIN_COST_COLLECT', 'fin_cost_collect', 'mat_cost',     '材料成本', 'amount', 'amount',   0, 1, 4,  '成本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240468, 'FIN_COST_COLLECT', 'fin_cost_collect', 'labor_cost',   '人工成本', 'amount', 'amount',   0, 1, 5,  '成本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240469, 'FIN_COST_COLLECT', 'fin_cost_collect', 'mfg_cost',     '制造费用', 'amount', 'amount',   0, 1, 6,  '成本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240470, 'FIN_COST_COLLECT', 'fin_cost_collect', 'total_cost',   '总成本',   'amount', 'amount',   0, 1, 7,  '成本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240471, 'FIN_COST_COLLECT', 'fin_cost_collect', 'wip_cost',     '在产品成本', 'amount', 'amount', 0, 1, 8,  '成本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240472, 'FIN_COST_COLLECT', 'fin_cost_collect', 'qty',          '数量',     'qty',    'qty',      0, 0, 9,  '成本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240473, 'FIN_COST_COLLECT', 'fin_cost_collect', 'unit_cost',    '单位成本', 'amount', 'amount',   0, 1, 10, '成本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240474, 'FIN_COST_COLLECT', 'fin_cost_collect', 'std_cost',     '标准成本', 'amount', 'amount',   0, 0, 11, '成本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240475, 'FIN_COST_COLLECT', 'fin_cost_collect', 'variance',     '差异',     'amount', 'amount',   0, 1, 12, '成本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240476, 'FIN_COST_COLLECT', 'fin_cost_collect', 'status',       '状态',     'enum',   'select',   0, 0, 13, '基本信息');

-- ------------------------------------------------------------
-- 6.13 FIN_COST_POOL 制造费用池（主表 fin_mfg_cost_pool，8 字段）
-- ------------------------------------------------------------
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240477, 'FIN_COST_POOL', 'fin_mfg_cost_pool', 'period_code',  '期间',     'text',   'text',     1, 0, 1,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240478, 'FIN_COST_POOL', 'fin_mfg_cost_pool', 'workshop_id', '车间',     'number', 'number',   0, 0, 2,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240479, 'FIN_COST_POOL', 'fin_mfg_cost_pool', 'cost_item',   '成本项目', 'text',   'text',     0, 0, 3,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240480, 'FIN_COST_POOL', 'fin_mfg_cost_pool', 'amount',      '金额',     'amount', 'amount',   0, 1, 4,  '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240481, 'FIN_COST_POOL', 'fin_mfg_cost_pool', 'alloc_base',  '分摊基数', 'text',   'text',     0, 0, 5,  '分摊信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240482, 'FIN_COST_POOL', 'fin_mfg_cost_pool', 'total_base',  '基数总量', 'amount', 'amount',   0, 0, 6,  '分摊信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240483, 'FIN_COST_POOL', 'fin_mfg_cost_pool', 'alloc_rate',  '分摊率',   'number', 'number',   0, 1, 7,  '分摊信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240484, 'FIN_COST_POOL', 'fin_mfg_cost_pool', 'voucher_id',  '凭证',     'number', 'number',   0, 1, 8,  '业务信息');

-- ------------------------------------------------------------
-- 6.14 FIN_COST_VARIANCE 成本差异（主表 fin_cost_variance，8 字段）
-- ------------------------------------------------------------
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240485, 'FIN_COST_VARIANCE', 'fin_cost_variance', 'period_code',     '期间',     'text',   'text',     1, 0, 1,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240486, 'FIN_COST_VARIANCE', 'fin_cost_variance', 'mfg_order_id',    '生产订单', 'number', 'number',   0, 0, 2,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240487, 'FIN_COST_VARIANCE', 'fin_cost_variance', 'variance_type',   '差异类型', 'text',   'text',     0, 0, 3,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240488, 'FIN_COST_VARIANCE', 'fin_cost_variance', 'std_value',       '标准值',   'amount', 'amount',   0, 0, 4,  '差异信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240489, 'FIN_COST_VARIANCE', 'fin_cost_variance', 'actual_value',    '实际值',   'amount', 'amount',   0, 0, 5,  '差异信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240490, 'FIN_COST_VARIANCE', 'fin_cost_variance', 'variance_amount', '差异金额', 'amount', 'amount',   0, 1, 6,  '差异信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240491, 'FIN_COST_VARIANCE', 'fin_cost_variance', 'alloc_to_stock',  '分摊至库存', 'amount', 'amount', 0, 0, 7,  '分摊信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (240492, 'FIN_COST_VARIANCE', 'fin_cost_variance', 'alloc_to_cogs',   '分摊至销售成本', 'amount', 'amount', 0, 0, 8, '分摊信息');
