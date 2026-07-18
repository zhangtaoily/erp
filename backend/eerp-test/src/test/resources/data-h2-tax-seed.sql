-- ============================================================
-- EERP H2 TAX (税务管理) 元数据种子
-- ============================================================
-- 用途：集成测试 H2 内存数据库税务管理模块元数据种子（Phase 3e）。
--       为 7 个税务业务对象 bo_code 注册业务对象、独立状态机
--       （5 节点 / 17 流转，复制 STD_5STATE 模型）、表单实体层级
--       （主/子）与关键字段元数据，驱动 GenericBillService →
--       GenericOperationService 的 6 阶段流水线，无需具体 Entity/Mapper。
-- 加载：spring.sql.init.data-locations 追加本文件。
-- 幂等：全部使用 REPLACE INTO ... VALUES (...)，可重复执行。
-- ID 约定（与 data-h2-master-seed.sql / data-h2-scm-seed.sql /
--       data-h2-sal-seed.sql / data-h2-inv-seed.sql / data-h2-mfg-seed.sql /
--       data-h2-fin-seed.sql 不冲突）：
--   meta_business_object  210001-210007   (7 行)
--   meta_state_machine    210100-210101   (2 行，仅业务单据，code=bo_code)
--   meta_state_node       210200-210209   (2×5=10 行)
--   meta_state_transition 210300-210333   (2×17=34 行)
--   meta_form_entity      210500-210508   (7 主 + 2 子 = 9 行)
--   meta_form_field       250300-250381   (82 行)
-- 判断标准：表有 pact_state 字段 → 业务单据(bo_type='business', is_stateful=1)；
--           表无 pact_state 字段 → 主数据(bo_type='master', is_stateful=0)。
-- 业务单据（2）：TAX_PROVIDE / TAX_DECLARE
-- 主数据（5）：TAX_RATE / INVOICE_AUTH / OUTPUT_SUM / INPUT_SUM / VAT_CALC
-- 业务单据约定：bo_type='business', is_stateful=1, is_pushable=1,
--               is_printable=1, pk_strategy='snowflake', main_key='id', status=1
-- 主数据约定：bo_type='master', is_stateful=0, is_pushable=0,
--             is_printable=0, pk_strategy='snowflake', main_key='id', status=1
-- 状态机复制：每业务 bo_code 复制 STD_5STATE（machine_id=100）的 5 节点
--             （id=101-105）与 17 流转（id=200-216），替换 machine_id。
--             t12-t15 含 post_action（is_closed/is_cancel 标记）。
-- 子表关联（以 schema-h2.sql 实际定义为准）：
--   TAX_PROVIDE  子表 tax_accrual_detail        link_field=accrual_id
--   TAX_DECLARE  子表 tax_declaration_history   link_field=declaration_id
-- 表列特征（以 schema-h2.sql 实际定义为准）：
--   tax_accrual     有 pact_state + is_closed（支持 close，无 is_cancel）
--   tax_declaration 有 pact_state（无 is_closed/is_cancel）
-- 兼容：H2 MODE=MySQL；时间戳使用 CURRENT_TIMESTAMP；布尔值统一用 1/0。
-- 依赖：schema-h2.sql；data-h2-seed.sql（STD_5STATE 及测试主数据）；
--       data-h2-master-seed.sql（主数据 bo_code，ref_bo_code 引用）；
--       data-h2-scm/sal/inv/mfg/fin-seed.sql（不冲突）。
-- ============================================================


-- ============================================================
-- 1. 业务对象定义（meta_business_object）—— 7 个税务 BO
-- ============================================================

REPLACE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
VALUES (210001, 'TAX_RATE',     '税率配置', 'master',  'tax_rate_config',     'id', 'snowflake', 0, 0, 0, NULL, 1, '税率配置主数据',     'system', CURRENT_TIMESTAMP);
REPLACE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
VALUES (210002, 'TAX_PROVIDE',  '税务计提', 'business', 'tax_accrual',        'id', 'snowflake', 1, 1, 1, NULL, 1, '税务计提业务单据',   'system', CURRENT_TIMESTAMP);
REPLACE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
VALUES (210003, 'TAX_DECLARE',  '纳税申报', 'business', 'tax_declaration',    'id', 'snowflake', 1, 1, 1, NULL, 1, '纳税申报业务单据',   'system', CURRENT_TIMESTAMP);
REPLACE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
VALUES (210004, 'INVOICE_AUTH', '发票认证', 'master',  'tax_invoice_certify', 'id', 'snowflake', 0, 0, 0, NULL, 1, '发票认证台账主数据', 'system', CURRENT_TIMESTAMP);
REPLACE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
VALUES (210005, 'OUTPUT_SUM',   '销项汇总', 'master',  'tax_output_summary',  'id', 'snowflake', 0, 0, 0, NULL, 1, '销项汇总主数据',     'system', CURRENT_TIMESTAMP);
REPLACE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
VALUES (210006, 'INPUT_SUM',    '进项汇总', 'master',  'tax_input_summary',   'id', 'snowflake', 0, 0, 0, NULL, 1, '进项汇总主数据',     'system', CURRENT_TIMESTAMP);
REPLACE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
VALUES (210007, 'VAT_CALC',     '增值税计算', 'master', 'tax_vat_calc',       'id', 'snowflake', 0, 0, 0, NULL, 1, '增值税计算主数据',   'system', CURRENT_TIMESTAMP);


-- ============================================================
-- 2. 状态机定义（meta_state_machine）—— 2 行，仅业务单据
--    StateMachineCache.load(boCode) 通过 code=bo_code 查询
-- ============================================================

REPLACE INTO meta_state_machine (id, code, name, state_field, remark)
VALUES (210100, 'TAX_PROVIDE', '税务计提状态机', 'pact_state', '复制 STD_5STATE：0暂存/1已创建/2已提交/3已审核/4已驳回；is_closed/is_cancel 辅助标记');
REPLACE INTO meta_state_machine (id, code, name, state_field, remark)
VALUES (210101, 'TAX_DECLARE', '纳税申报状态机', 'pact_state', '复制 STD_5STATE：0暂存/1已创建/2已提交/3已审核/4已驳回；is_closed/is_cancel 辅助标记');


-- ============================================================
-- 3. 状态节点（meta_state_node）—— 2×5=10 行
--    复制 STD_5STATE 节点（machine_id=100 的 id=101-105），替换 machine_id
--    0暂存(初始) 1已创建 2已提交 3已审核 4已驳回
-- ============================================================

-- 3.1 TAX_PROVIDE (machine_id=210100) —— id=210200-210204
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (210200, 210100, 0, '暂存',   '#909399', 1, 0, 1, 1, 0);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (210201, 210100, 1, '已创建', '#409EFF', 0, 0, 1, 1, 1);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (210202, 210100, 2, '已提交', '#E6A23C', 0, 0, 0, 0, 2);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (210203, 210100, 3, '已审核', '#67C23A', 0, 0, 0, 0, 3);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (210204, 210100, 4, '已驳回', '#F56C6C', 0, 0, 1, 1, 4);

-- 3.2 TAX_DECLARE (machine_id=210101) —— id=210205-210209
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (210205, 210101, 0, '暂存',   '#909399', 1, 0, 1, 1, 0);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (210206, 210101, 1, '已创建', '#409EFF', 0, 0, 1, 1, 1);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (210207, 210101, 2, '已提交', '#E6A23C', 0, 0, 0, 0, 2);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (210208, 210101, 3, '已审核', '#67C23A', 0, 0, 0, 0, 3);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (210209, 210101, 4, '已驳回', '#F56C6C', 0, 0, 1, 1, 4);


-- ============================================================
-- 4. 状态流转（meta_state_transition）—— 2×17=34 行
--    复制 STD_5STATE 流转（machine_id=100 的 id=200-216），替换 machine_id
--    t1-t11+t16+t17 无 post_action；t12-t15 含 post_action
--    删除 to_state=-1（物理删除）；关闭/取消/变更/下推 to_state=3（保持原状态）
-- ============================================================

-- 4.1 TAX_PROVIDE (machine_id=210100) —— id=210300-210316
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (210300, 210100, 0,  1, '保存',     'save',     0, 0, 1);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (210301, 210100, 0,  0, '暂存',     'draft',    0, 0, 2);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (210302, 210100, 1,  2, '提交',     'submit',   1, 0, 3);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (210303, 210100, 2,  3, '审核',     'audit',    0, 0, 4);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (210304, 210100, 2,  4, '驳回',     'reject',   0, 1, 5);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (210305, 210100, 4,  2, '重新提交', 'resubmit', 1, 0, 6);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (210306, 210100, 2,  1, '撤销',     'revoke',   0, 0, 7);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (210307, 210100, 3,  1, '撤销',     'revoke',   0, 0, 8);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (210308, 210100, 0, -1, '删除',     'delete',   0, 0, 9);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (210309, 210100, 1, -1, '删除',     'delete',   0, 0, 10);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (210310, 210100, 4, -1, '删除',     'delete',   0, 0, 11);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (210311, 210100, 3, 3, '关闭',   'close',  'is_closed=1', 0, 0, 12);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (210312, 210100, 3, 3, '反关闭', 'close',  'is_closed=0', 0, 0, 13);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (210313, 210100, 3, 3, '取消',   'cancel', 'is_cancel=1', 0, 1, 14);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (210314, 210100, 3, 3, '反取消', 'cancel', 'is_cancel=0', 0, 0, 15);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (210315, 210100, 3,  3, '变更',     'change',   1, 1, 16);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (210316, 210100, 3,  3, '下推',     'push',     0, 0, 17);

-- 4.2 TAX_DECLARE (machine_id=210101) —— id=210317-210333
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (210317, 210101, 0,  1, '保存',     'save',     0, 0, 1);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (210318, 210101, 0,  0, '暂存',     'draft',    0, 0, 2);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (210319, 210101, 1,  2, '提交',     'submit',   1, 0, 3);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (210320, 210101, 2,  3, '审核',     'audit',    0, 0, 4);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (210321, 210101, 2,  4, '驳回',     'reject',   0, 1, 5);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (210322, 210101, 4,  2, '重新提交', 'resubmit', 1, 0, 6);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (210323, 210101, 2,  1, '撤销',     'revoke',   0, 0, 7);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (210324, 210101, 3,  1, '撤销',     'revoke',   0, 0, 8);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (210325, 210101, 0, -1, '删除',     'delete',   0, 0, 9);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (210326, 210101, 1, -1, '删除',     'delete',   0, 0, 10);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (210327, 210101, 4, -1, '删除',     'delete',   0, 0, 11);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (210328, 210101, 3, 3, '关闭',   'close',  'is_closed=1', 0, 0, 12);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (210329, 210101, 3, 3, '反关闭', 'close',  'is_closed=0', 0, 0, 13);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (210330, 210101, 3, 3, '取消',   'cancel', 'is_cancel=1', 0, 1, 14);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (210331, 210101, 3, 3, '反取消', 'cancel', 'is_cancel=0', 0, 0, 15);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (210332, 210101, 3,  3, '变更',     'change',   1, 1, 16);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (210333, 210101, 3,  3, '下推',     'push',     0, 0, 17);


-- ============================================================
-- 5. 表单实体层级（meta_form_entity）—— 7 主 + 2 子 = 9 行
--    主表 entity_code=main_table；子表 entity_code='detail'/'history'
-- ============================================================

-- 5.1 主实体（entity_type='main', entity_level=0）—— 7 行
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (210500, 'TAX_RATE',     'tax_rate_config',     '税率配置', 'main', 0, 'tax_rate_config',     NULL, NULL, 1);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (210501, 'TAX_PROVIDE',  'tax_accrual',         '税务计提', 'main', 0, 'tax_accrual',         NULL, NULL, 1);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (210503, 'TAX_DECLARE',  'tax_declaration',     '纳税申报', 'main', 0, 'tax_declaration',     NULL, NULL, 1);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (210505, 'INVOICE_AUTH', 'tax_invoice_certify', '发票认证', 'main', 0, 'tax_invoice_certify', NULL, NULL, 1);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (210506, 'OUTPUT_SUM',   'tax_output_summary',  '销项汇总', 'main', 0, 'tax_output_summary',  NULL, NULL, 1);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (210507, 'INPUT_SUM',    'tax_input_summary',   '进项汇总', 'main', 0, 'tax_input_summary',   NULL, NULL, 1);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (210508, 'VAT_CALC',     'tax_vat_calc',        '增值税计算', 'main', 0, 'tax_vat_calc',       NULL, NULL, 1);

-- 5.2 子实体（entity_type='sub', entity_level=1）—— 2 行
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (210502, 'TAX_PROVIDE', 'detail',  '税务计提明细', 'sub', 1, 'tax_accrual_detail',      'tax_accrual',     'accrual_id',     2);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (210504, 'TAX_DECLARE', 'history', '申报历史明细', 'sub', 1, 'tax_declaration_history', 'tax_declaration', 'declaration_id', 2);


-- ============================================================
-- 6. 表单字段元数据（meta_form_field）—— 82 行
--    仅注册关键字段（编码/日期/状态 + 组织/供应商/客户外键 + 金额 + 备注 + 审计字段）
--    字段类型：text/number/date/datetime/enum/ref/qty/amount
--    控件类型：text/textarea/number/date/datetime/select/ref/qty/amount
--    ref 字段附带 ref_bo_code；ID 区间 250300-250381
-- ============================================================

-- ------------------------------------------------------------
-- 6.1 TAX_RATE 税率配置（主表 tax_rate_config，8 字段）
-- ------------------------------------------------------------
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (250300, 'TAX_RATE', 'tax_rate_config', 'org_id',        '组织',     'ref',    'ref',      0, 0, 'MD_ORG',      1,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250301, 'TAX_RATE', 'tax_rate_config', 'mat_category',  '物料分类', 'text',   'text',     0, 0, 2,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250302, 'TAX_RATE', 'tax_rate_config', 'tax_type',      '税种',     'text',   'text',     1, 0, 3,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250303, 'TAX_RATE', 'tax_rate_config', 'tax_rate',      '税率',     'number', 'number',   1, 0, 4,  '税率信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250304, 'TAX_RATE', 'tax_rate_config', 'valid_start',   '生效开始', 'date',   'date',     0, 0, 5,  '税率信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250305, 'TAX_RATE', 'tax_rate_config', 'valid_end',     '生效结束', 'date',   'date',     0, 0, 6,  '税率信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250306, 'TAX_RATE', 'tax_rate_config', 'special_flag',  '特殊标记', 'text',   'text',     0, 0, 7,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250307, 'TAX_RATE', 'tax_rate_config', 'remark',        '备注',     'text',   'textarea', 0, 0, 8,  '其他');

-- ------------------------------------------------------------
-- 6.2 TAX_PROVIDE 税务计提（主表 tax_accrual 10 字段 + 子表 tax_accrual_detail 9 字段 = 19 字段）
-- ------------------------------------------------------------
-- 主表 tax_accrual（10 字段）
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250308, 'TAX_PROVIDE', 'tax_accrual', 'code',         '单据编码', 'text',   'text',     1, 0, 1,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250309, 'TAX_PROVIDE', 'tax_accrual', 'period_code',  '期间',     'text',   'text',     1, 0, 2,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (250310, 'TAX_PROVIDE', 'tax_accrual', 'org_id',       '组织',     'ref',    'ref',      0, 0, 'MD_ORG',      3,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250311, 'TAX_PROVIDE', 'tax_accrual', 'pact_state',   '单据状态', 'enum',   'select',   0, 1, 4,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250312, 'TAX_PROVIDE', 'tax_accrual', 'total_amount', '总金额',   'amount', 'amount',   0, 1, 5,  '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250313, 'TAX_PROVIDE', 'tax_accrual', 'voucher_id',   '凭证',     'number', 'number',   0, 1, 6,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250314, 'TAX_PROVIDE', 'tax_accrual', 'is_closed',    '是否关闭', 'enum',   'select',   0, 1, 7,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250315, 'TAX_PROVIDE', 'tax_accrual', 'remark',       '备注',     'text',   'textarea', 0, 0, 8,  '其他');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (250316, 'TAX_PROVIDE', 'tax_accrual', 'auditor',      '审核人',   'ref',    'ref',      0, 1, 'MD_EMPLOYEE', 9,  '审计信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250317, 'TAX_PROVIDE', 'tax_accrual', 'audit_time',   '审核时间', 'datetime','datetime', 0, 1, 10, '审计信息');
-- 子表 tax_accrual_detail / detail（9 字段）
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250318, 'TAX_PROVIDE', 'detail', 'sort_index',      '行号',       'number', 'number',   0, 0, 1, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250319, 'TAX_PROVIDE', 'detail', 'accrual_id',      '计提单',     'number', 'number',   1, 1, 2, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250320, 'TAX_PROVIDE', 'detail', 'tax_type',        '税种',       'text',   'text',     1, 0, 3, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250321, 'TAX_PROVIDE', 'detail', 'base_amount',     '计税基数',   'amount', 'amount',   0, 0, 4, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250322, 'TAX_PROVIDE', 'detail', 'tax_rate',        '税率',       'number', 'number',   0, 0, 5, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250323, 'TAX_PROVIDE', 'detail', 'tax_amount',      '税额',       'amount', 'amount',   0, 0, 6, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250324, 'TAX_PROVIDE', 'detail', 'deduct_amount',   '抵扣额',     'amount', 'amount',   0, 0, 7, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250325, 'TAX_PROVIDE', 'detail', 'payable_amount',  '应纳税额',   'amount', 'amount',   0, 1, 8, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250326, 'TAX_PROVIDE', 'detail', 'remark',          '备注',       'text',   'textarea', 0, 0, 9, '明细信息');

-- ------------------------------------------------------------
-- 6.3 TAX_DECLARE 纳税申报（主表 tax_declaration 13 字段 + 子表 tax_declaration_history 6 字段 = 19 字段）
-- ------------------------------------------------------------
-- 主表 tax_declaration（13 字段）
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250327, 'TAX_DECLARE', 'tax_declaration', 'code',             '单据编码', 'text',   'text',     1, 0, 1,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250328, 'TAX_DECLARE', 'tax_declaration', 'period_code',      '期间',     'text',   'text',     1, 0, 2,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (250329, 'TAX_DECLARE', 'tax_declaration', 'org_id',           '组织',     'ref',    'ref',      0, 0, 'MD_ORG',      3,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250330, 'TAX_DECLARE', 'tax_declaration', 'declaration_type', '申报类型', 'text',   'text',     1, 0, 4,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250331, 'TAX_DECLARE', 'tax_declaration', 'declare_date',     '申报日期', 'date',   'date',     0, 0, 5,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250332, 'TAX_DECLARE', 'tax_declaration', 'pact_state',       '单据状态', 'enum',   'select',   0, 1, 6,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250333, 'TAX_DECLARE', 'tax_declaration', 'total_amount',     '总金额',   'amount', 'amount',   0, 1, 7,  '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250334, 'TAX_DECLARE', 'tax_declaration', 'data_json',        '申报数据', 'text',   'textarea', 0, 0, 8,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250335, 'TAX_DECLARE', 'tax_declaration', 'file_url',         '附件',     'text',   'text',     0, 0, 9,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250336, 'TAX_DECLARE', 'tax_declaration', 'submit_status',    '提交状态', 'text',   'text',     0, 0, 10, '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250337, 'TAX_DECLARE', 'tax_declaration', 'remark',           '备注',     'text',   'textarea', 0, 0, 11, '其他');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (250338, 'TAX_DECLARE', 'tax_declaration', 'auditor',          '审核人',   'ref',    'ref',      0, 1, 'MD_EMPLOYEE', 12, '审计信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250339, 'TAX_DECLARE', 'tax_declaration', 'audit_time',       '审核时间', 'datetime','datetime', 0, 1, 13, '审计信息');
-- 子表 tax_declaration_history / history（6 字段）
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250340, 'TAX_DECLARE', 'history', 'declaration_id', '申报单',   'number', 'number',   1, 1, 1, '历史信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250341, 'TAX_DECLARE', 'history', 'op_type',         '操作类型', 'text',   'text',     0, 0, 2, '历史信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250342, 'TAX_DECLARE', 'history', 'op_amount',       '操作金额', 'amount', 'amount',   0, 0, 3, '历史信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250343, 'TAX_DECLARE', 'history', 'op_by',           '操作人',   'text',   'text',     0, 0, 4, '历史信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250344, 'TAX_DECLARE', 'history', 'op_time',         '操作时间', 'datetime','datetime', 0, 0, 5, '历史信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250345, 'TAX_DECLARE', 'history', 'op_remark',       '操作备注', 'text',   'textarea', 0, 0, 6, '历史信息');

-- ------------------------------------------------------------
-- 6.4 INVOICE_AUTH 发票认证（主表 tax_invoice_certify，14 字段）
-- ------------------------------------------------------------
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250346, 'INVOICE_AUTH', 'tax_invoice_certify', 'invoice_type',    '发票类型', 'text',   'text',     1, 0, 1,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250347, 'INVOICE_AUTH', 'tax_invoice_certify', 'src_bill_type',   '来源单类型', 'text', 'text',    0, 0, 2,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250348, 'INVOICE_AUTH', 'tax_invoice_certify', 'src_bill_id',     '来源单ID', 'number', 'number',   0, 1, 3,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250349, 'INVOICE_AUTH', 'tax_invoice_certify', 'invoice_code',    '发票代码', 'text',   'text',     1, 0, 4,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250350, 'INVOICE_AUTH', 'tax_invoice_certify', 'invoice_no',      '发票号码', 'text',   'text',     1, 0, 5,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250351, 'INVOICE_AUTH', 'tax_invoice_certify', 'invoice_date',    '开票日期', 'date',   'date',     0, 0, 6,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (250352, 'INVOICE_AUTH', 'tax_invoice_certify', 'supplier_id',     '供应商',   'ref',    'ref',      0, 0, 'MD_SUPPLIER', 7,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250353, 'INVOICE_AUTH', 'tax_invoice_certify', 'tax_amount',      '税额',     'amount', 'amount',   0, 1, 8,  '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250354, 'INVOICE_AUTH', 'tax_invoice_certify', 'deduct_amount',   '抵扣额',   'amount', 'amount',   0, 0, 9,  '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250355, 'INVOICE_AUTH', 'tax_invoice_certify', 'certify_status',  '认证状态', 'text',   'text',     0, 0, 10, '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250356, 'INVOICE_AUTH', 'tax_invoice_certify', 'certify_date',    '认证日期', 'date',   'date',     0, 0, 11, '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250357, 'INVOICE_AUTH', 'tax_invoice_certify', 'certify_period',  '认证期间', 'text',   'text',     0, 0, 12, '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250358, 'INVOICE_AUTH', 'tax_invoice_certify', 'is_agri',         '是否农产品', 'enum', 'select',  0, 0, 13, '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250359, 'INVOICE_AUTH', 'tax_invoice_certify', 'remark',          '备注',     'text',   'textarea', 0, 0, 14, '其他');

-- ------------------------------------------------------------
-- 6.5 OUTPUT_SUM 销项汇总（主表 tax_output_summary，7 字段）
-- ------------------------------------------------------------
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250360, 'OUTPUT_SUM', 'tax_output_summary', 'period_code',    '期间',       'text',   'text',     1, 0, 1,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (250361, 'OUTPUT_SUM', 'tax_output_summary', 'org_id',         '组织',       'ref',    'ref',      0, 0, 'MD_ORG',      2,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (250362, 'OUTPUT_SUM', 'tax_output_summary', 'cust_id',        '客户',       'ref',    'ref',      0, 0, 'MD_CUSTOMER', 3,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250363, 'OUTPUT_SUM', 'tax_output_summary', 'invoice_count',  '发票数量',   'number', 'number',   0, 0, 4,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250364, 'OUTPUT_SUM', 'tax_output_summary', 'no_tax_amount',  '不含税金额', 'amount', 'amount',   0, 1, 5,  '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250365, 'OUTPUT_SUM', 'tax_output_summary', 'tax_amount',     '税额',       'amount', 'amount',   0, 1, 6,  '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250366, 'OUTPUT_SUM', 'tax_output_summary', 'total_amount',   '价税合计',   'amount', 'amount',   0, 1, 7,  '金额信息');

-- ------------------------------------------------------------
-- 6.6 INPUT_SUM 进项汇总（主表 tax_input_summary，7 字段）
-- ------------------------------------------------------------
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250367, 'INPUT_SUM', 'tax_input_summary', 'period_code',    '期间',       'text',   'text',     1, 0, 1,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (250368, 'INPUT_SUM', 'tax_input_summary', 'org_id',         '组织',       'ref',    'ref',      0, 0, 'MD_ORG',      2,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (250369, 'INPUT_SUM', 'tax_input_summary', 'supplier_id',    '供应商',     'ref',    'ref',      0, 0, 'MD_SUPPLIER', 3,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250370, 'INPUT_SUM', 'tax_input_summary', 'invoice_count',  '发票数量',   'number', 'number',   0, 0, 4,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250371, 'INPUT_SUM', 'tax_input_summary', 'no_tax_amount',  '不含税金额', 'amount', 'amount',   0, 1, 5,  '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250372, 'INPUT_SUM', 'tax_input_summary', 'tax_amount',     '税额',       'amount', 'amount',   0, 1, 6,  '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250373, 'INPUT_SUM', 'tax_input_summary', 'deduct_amount',  '抵扣额',     'amount', 'amount',   0, 0, 7,  '金额信息');

-- ------------------------------------------------------------
-- 6.7 VAT_CALC 增值税计算（主表 tax_vat_calc，8 字段）
-- ------------------------------------------------------------
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250374, 'VAT_CALC', 'tax_vat_calc', 'period_code',       '期间',       'text',   'text',     1, 0, 1,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (250375, 'VAT_CALC', 'tax_vat_calc', 'org_id',            '组织',       'ref',    'ref',      0, 0, 'MD_ORG',      2,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250376, 'VAT_CALC', 'tax_vat_calc', 'output_tax',        '销项税额',   'amount', 'amount',   0, 1, 3,  '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250377, 'VAT_CALC', 'tax_vat_calc', 'input_tax',         '进项税额',   'amount', 'amount',   0, 1, 4,  '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250378, 'VAT_CALC', 'tax_vat_calc', 'input_transferred',  '进项转出',   'amount', 'amount',   0, 0, 5,  '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250379, 'VAT_CALC', 'tax_vat_calc', 'deduct_tax',        '抵扣税额',   'amount', 'amount',   0, 0, 6,  '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250380, 'VAT_CALC', 'tax_vat_calc', 'payable_tax',       '应纳税额',   'amount', 'amount',   0, 1, 7,  '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (250381, 'VAT_CALC', 'tax_vat_calc', 'tax_burden_rate',   '税负率',     'number', 'number',   0, 0, 8,  '金额信息');


-- ============================================================
-- 文件末尾说明
-- ============================================================
-- ID 范围汇总：
--   meta_business_object  210001-210007   (7 行税务业务对象)
--   meta_state_machine    210100-210101   (2 行，code=bo_code，state_field=pact_state)
--   meta_state_node       210200-210209   (10 行，每状态机 5 节点，复制 STD_5STATE)
--   meta_state_transition 210300-210333   (34 行，每状态机 17 流转，t12-t15 含 post_action)
--   meta_form_entity      210500-210508   (9 行：7 主 + 2 子)
--   meta_form_field       250300-250381   (82 行关键字段)
-- 依赖关系：
--   1. schema-h2.sql 提供元数据表结构与税务业务表结构。
--   2. data-h2-seed.sql 提供标准状态机 STD_5STATE（machine_id=100）及测试主数据。
--   3. data-h2-master-seed.sql 提供主数据 bo_code（MD_ORG/MD_SUPPLIER/MD_CUSTOMER/
--      MD_EMPLOYEE 等），本文件 meta_form_field.ref_bo_code 引用这些主数据 bo_code。
--   4. 表列特征：tax_accrual 有 is_closed（支持 close 操作）；
--      tax_declaration 无 is_closed/is_cancel（close/cancel 操作不可用）。
-- 加载顺序建议：schema-h2.sql → data-h2-seed.sql → data-h2-master-seed.sql →
--              data-h2-scm-seed.sql → ... → data-h2-fin-seed.sql → 本文件。
-- ============================================================
