-- ============================================================
-- EERP H2 SCM (采购管理) 元数据种子
-- ============================================================
-- 用途：集成测试 H2 内存数据库采购管理模块元数据种子（Phase 2a）。
--       为 7 个采购业务单据 bo_code 注册业务对象、独立状态机
--       （5 节点 / 17 流转，复制 STD_5STATE 模型）、表单实体层级
--       （主/子/孙）与关键字段元数据，驱动 GenericBillService →
--       GenericOperationService 的 6 阶段流水线，无需具体 Entity/Mapper。
-- 加载：spring.sql.init.data-locations 追加本文件，或测试用 @Sql 注解加载。
-- 幂等：全部使用 MERGE INTO ... KEY(id) VALUES (...)，可重复执行。
-- ID 约定（与 data-h2-master-seed.sql 不冲突）：
--   meta_business_object  160001-160007   (7 行)
--   meta_state_machine    160100-160106   (7 行，每 bo_code 一台，code=bo_code)
--   meta_state_node       160200-160234   (7×5=35 行)
--   meta_state_transition 160300-160418   (7×17=119 行)
--   meta_form_entity      160500-160514   (7 主 + 7 子 + 1 孙 = 15 行)
--   meta_form_field       200300-200447   (148 行)
-- 采购单据约定：bo_type='business', is_stateful=1, is_pushable=1,
--             is_printable=1, pk_strategy='snowflake', main_key='id', status=1
-- 状态机复制：每 bo_code 复制 STD_5STATE（machine_id=100）的 5 节点
--             （id=101-105）与 17 流转（id=200-216），替换 machine_id。
--             t12-t15 含 post_action（is_closed/is_cancel 标记）。
-- 兼容：H2 MODE=MySQL；时间戳使用 CURRENT_TIMESTAMP；布尔值统一用 1/0。
-- 依赖：schema-h2.sql（元数据表结构）；data-h2-seed.sql（STD_5STATE 及主数据）；
--       data-h2-master-seed.sql（30 个主数据 bo_code，外键 ref_bo_code 引用）。
-- ============================================================


-- ============================================================
-- 1. 业务对象定义（meta_business_object）—— 7 个采购业务 BO
-- ============================================================

MERGE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
KEY(id) VALUES (160001, 'PUR_APPLY',          '采购申请', 'business', 'pur_apply',          'id', 'snowflake', 1, 1, 1, NULL, 1, '采购申请业务单据', 'system', CURRENT_TIMESTAMP);
MERGE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
KEY(id) VALUES (160002, 'PUR_CONT',           '采购合同', 'business', 'pur_cont',           'id', 'snowflake', 1, 1, 1, NULL, 1, '采购合同业务单据', 'system', CURRENT_TIMESTAMP);
MERGE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
KEY(id) VALUES (160003, 'PUR_ORDER',          '采购订单', 'business', 'pur_order',          'id', 'snowflake', 1, 1, 1, NULL, 1, '采购订单业务单据', 'system', CURRENT_TIMESTAMP);
MERGE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
KEY(id) VALUES (160004, 'PUR_RECEIVE_NOTICE', '收料通知', 'business', 'pur_receive_notice', 'id', 'snowflake', 1, 1, 1, NULL, 1, '收料通知业务单据', 'system', CURRENT_TIMESTAMP);
MERGE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
KEY(id) VALUES (160005, 'PUR_IN_STOCK',       '采购入库', 'business', 'pur_in_stock',       'id', 'snowflake', 1, 1, 1, NULL, 1, '采购入库业务单据', 'system', CURRENT_TIMESTAMP);
MERGE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
KEY(id) VALUES (160006, 'PUR_RETURN',         '采购退料', 'business', 'pur_return',         'id', 'snowflake', 1, 1, 1, NULL, 1, '采购退料业务单据', 'system', CURRENT_TIMESTAMP);
MERGE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
KEY(id) VALUES (160007, 'PUR_INVOICE',        '采购发票', 'business', 'pur_invoice',        'id', 'snowflake', 1, 1, 1, NULL, 1, '采购发票业务单据', 'system', CURRENT_TIMESTAMP);


-- ============================================================
-- 2. 状态机定义（meta_state_machine）—— 7 行，code=bo_code
--    StateMachineCache.load(boCode) 通过 code=bo_code 查询
-- ============================================================

MERGE INTO meta_state_machine (id, code, name, state_field, remark)
KEY(id) VALUES (160100, 'PUR_APPLY',          '采购申请状态机', 'pact_state', '复制 STD_5STATE：0暂存/1已创建/2已提交/3已审核/4已驳回；is_closed/is_cancel 辅助标记');
MERGE INTO meta_state_machine (id, code, name, state_field, remark)
KEY(id) VALUES (160101, 'PUR_CONT',           '采购合同状态机', 'pact_state', '复制 STD_5STATE：0暂存/1已创建/2已提交/3已审核/4已驳回；is_closed/is_cancel 辅助标记');
MERGE INTO meta_state_machine (id, code, name, state_field, remark)
KEY(id) VALUES (160102, 'PUR_ORDER',          '采购订单状态机', 'pact_state', '复制 STD_5STATE：0暂存/1已创建/2已提交/3已审核/4已驳回；is_closed/is_cancel 辅助标记');
MERGE INTO meta_state_machine (id, code, name, state_field, remark)
KEY(id) VALUES (160103, 'PUR_RECEIVE_NOTICE', '收料通知状态机', 'pact_state', '复制 STD_5STATE：0暂存/1已创建/2已提交/3已审核/4已驳回；is_closed/is_cancel 辅助标记');
MERGE INTO meta_state_machine (id, code, name, state_field, remark)
KEY(id) VALUES (160104, 'PUR_IN_STOCK',       '采购入库状态机', 'pact_state', '复制 STD_5STATE：0暂存/1已创建/2已提交/3已审核/4已驳回；is_closed/is_cancel 辅助标记');
MERGE INTO meta_state_machine (id, code, name, state_field, remark)
KEY(id) VALUES (160105, 'PUR_RETURN',         '采购退料状态机', 'pact_state', '复制 STD_5STATE：0暂存/1已创建/2已提交/3已审核/4已驳回；is_closed/is_cancel 辅助标记');
MERGE INTO meta_state_machine (id, code, name, state_field, remark)
KEY(id) VALUES (160106, 'PUR_INVOICE',        '采购发票状态机', 'pact_state', '复制 STD_5STATE：0暂存/1已创建/2已提交/3已审核/4已驳回；is_closed/is_cancel 辅助标记');


-- ============================================================
-- 3. 状态节点（meta_state_node）—— 7×5=35 行
--    复制 STD_5STATE 节点（machine_id=100 的 id=101-105），替换 machine_id
--    0暂存(初始) 1已创建 2已提交 3已审核 4已驳回
-- ============================================================

-- 3.1 PUR_APPLY (machine_id=160100) —— id=160200-160204
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (160200, 160100, 0, '暂存',   '#909399', 1, 0, 1, 1, 0);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (160201, 160100, 1, '已创建', '#409EFF', 0, 0, 1, 1, 1);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (160202, 160100, 2, '已提交', '#E6A23C', 0, 0, 0, 0, 2);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (160203, 160100, 3, '已审核', '#67C23A', 0, 0, 0, 0, 3);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (160204, 160100, 4, '已驳回', '#F56C6C', 0, 0, 1, 1, 4);

-- 3.2 PUR_CONT (machine_id=160101) —— id=160205-160209
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (160205, 160101, 0, '暂存',   '#909399', 1, 0, 1, 1, 0);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (160206, 160101, 1, '已创建', '#409EFF', 0, 0, 1, 1, 1);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (160207, 160101, 2, '已提交', '#E6A23C', 0, 0, 0, 0, 2);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (160208, 160101, 3, '已审核', '#67C23A', 0, 0, 0, 0, 3);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (160209, 160101, 4, '已驳回', '#F56C6C', 0, 0, 1, 1, 4);

-- 3.3 PUR_ORDER (machine_id=160102) —— id=160210-160214
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (160210, 160102, 0, '暂存',   '#909399', 1, 0, 1, 1, 0);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (160211, 160102, 1, '已创建', '#409EFF', 0, 0, 1, 1, 1);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (160212, 160102, 2, '已提交', '#E6A23C', 0, 0, 0, 0, 2);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (160213, 160102, 3, '已审核', '#67C23A', 0, 0, 0, 0, 3);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (160214, 160102, 4, '已驳回', '#F56C6C', 0, 0, 1, 1, 4);

-- 3.4 PUR_RECEIVE_NOTICE (machine_id=160103) —— id=160215-160219
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (160215, 160103, 0, '暂存',   '#909399', 1, 0, 1, 1, 0);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (160216, 160103, 1, '已创建', '#409EFF', 0, 0, 1, 1, 1);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (160217, 160103, 2, '已提交', '#E6A23C', 0, 0, 0, 0, 2);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (160218, 160103, 3, '已审核', '#67C23A', 0, 0, 0, 0, 3);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (160219, 160103, 4, '已驳回', '#F56C6C', 0, 0, 1, 1, 4);

-- 3.5 PUR_IN_STOCK (machine_id=160104) —— id=160220-160224
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (160220, 160104, 0, '暂存',   '#909399', 1, 0, 1, 1, 0);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (160221, 160104, 1, '已创建', '#409EFF', 0, 0, 1, 1, 1);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (160222, 160104, 2, '已提交', '#E6A23C', 0, 0, 0, 0, 2);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (160223, 160104, 3, '已审核', '#67C23A', 0, 0, 0, 0, 3);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (160224, 160104, 4, '已驳回', '#F56C6C', 0, 0, 1, 1, 4);

-- 3.6 PUR_RETURN (machine_id=160105) —— id=160225-160229
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (160225, 160105, 0, '暂存',   '#909399', 1, 0, 1, 1, 0);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (160226, 160105, 1, '已创建', '#409EFF', 0, 0, 1, 1, 1);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (160227, 160105, 2, '已提交', '#E6A23C', 0, 0, 0, 0, 2);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (160228, 160105, 3, '已审核', '#67C23A', 0, 0, 0, 0, 3);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (160229, 160105, 4, '已驳回', '#F56C6C', 0, 0, 1, 1, 4);

-- 3.7 PUR_INVOICE (machine_id=160106) —— id=160230-160234
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (160230, 160106, 0, '暂存',   '#909399', 1, 0, 1, 1, 0);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (160231, 160106, 1, '已创建', '#409EFF', 0, 0, 1, 1, 1);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (160232, 160106, 2, '已提交', '#E6A23C', 0, 0, 0, 0, 2);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (160233, 160106, 3, '已审核', '#67C23A', 0, 0, 0, 0, 3);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (160234, 160106, 4, '已驳回', '#F56C6C', 0, 0, 1, 1, 4);


-- ============================================================
-- 4. 状态流转（meta_state_transition）—— 7×17=119 行
--    复制 STD_5STATE 流转（machine_id=100 的 id=200-216），替换 machine_id
--    t1-t11 + t16-t17 无 post_action；t12-t15 含 post_action
--    删除 to_state=-1（物理删除）；关闭/取消/变更/下推 to_state=3（保持原状态）
-- ============================================================

-- 4.1 PUR_APPLY (machine_id=160100) —— id=160300-160316
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160300, 160100, 0,  1, '保存',     'save',     0, 0, 1);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160301, 160100, 0,  0, '暂存',     'draft',    0, 0, 2);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160302, 160100, 1,  2, '提交',     'submit',   1, 0, 3);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160303, 160100, 2,  3, '审核',     'audit',    0, 0, 4);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160304, 160100, 2,  4, '驳回',     'reject',   0, 1, 5);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160305, 160100, 4,  2, '重新提交', 'resubmit', 1, 0, 6);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160306, 160100, 2,  1, '撤销',     'revoke',   0, 0, 7);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160307, 160100, 3,  1, '撤销',     'revoke',   0, 0, 8);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160308, 160100, 0, -1, '删除',     'delete',   0, 0, 9);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160309, 160100, 1, -1, '删除',     'delete',   0, 0, 10);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160310, 160100, 4, -1, '删除',     'delete',   0, 0, 11);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (160311, 160100, 3, 3, '关闭',   'close',  'is_closed=1', 0, 0, 12);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (160312, 160100, 3, 3, '反关闭', 'close',  'is_closed=0', 0, 0, 13);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (160313, 160100, 3, 3, '取消',   'cancel', 'is_cancel=1', 0, 1, 14);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (160314, 160100, 3, 3, '反取消', 'cancel', 'is_cancel=0', 0, 0, 15);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160315, 160100, 3,  3, '变更',     'change',   1, 1, 16);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160316, 160100, 3,  3, '下推',     'push',     0, 0, 17);

-- 4.2 PUR_CONT (machine_id=160101) —— id=160317-160333
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160317, 160101, 0,  1, '保存',     'save',     0, 0, 1);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160318, 160101, 0,  0, '暂存',     'draft',    0, 0, 2);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160319, 160101, 1,  2, '提交',     'submit',   1, 0, 3);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160320, 160101, 2,  3, '审核',     'audit',    0, 0, 4);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160321, 160101, 2,  4, '驳回',     'reject',   0, 1, 5);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160322, 160101, 4,  2, '重新提交', 'resubmit', 1, 0, 6);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160323, 160101, 2,  1, '撤销',     'revoke',   0, 0, 7);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160324, 160101, 3,  1, '撤销',     'revoke',   0, 0, 8);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160325, 160101, 0, -1, '删除',     'delete',   0, 0, 9);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160326, 160101, 1, -1, '删除',     'delete',   0, 0, 10);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160327, 160101, 4, -1, '删除',     'delete',   0, 0, 11);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (160328, 160101, 3, 3, '关闭',   'close',  'is_closed=1', 0, 0, 12);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (160329, 160101, 3, 3, '反关闭', 'close',  'is_closed=0', 0, 0, 13);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (160330, 160101, 3, 3, '取消',   'cancel', 'is_cancel=1', 0, 1, 14);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (160331, 160101, 3, 3, '反取消', 'cancel', 'is_cancel=0', 0, 0, 15);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160332, 160101, 3,  3, '变更',     'change',   1, 1, 16);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160333, 160101, 3,  3, '下推',     'push',     0, 0, 17);

-- 4.3 PUR_ORDER (machine_id=160102) —— id=160334-160350
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160334, 160102, 0,  1, '保存',     'save',     0, 0, 1);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160335, 160102, 0,  0, '暂存',     'draft',    0, 0, 2);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160336, 160102, 1,  2, '提交',     'submit',   1, 0, 3);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160337, 160102, 2,  3, '审核',     'audit',    0, 0, 4);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160338, 160102, 2,  4, '驳回',     'reject',   0, 1, 5);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160339, 160102, 4,  2, '重新提交', 'resubmit', 1, 0, 6);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160340, 160102, 2,  1, '撤销',     'revoke',   0, 0, 7);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160341, 160102, 3,  1, '撤销',     'revoke',   0, 0, 8);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160342, 160102, 0, -1, '删除',     'delete',   0, 0, 9);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160343, 160102, 1, -1, '删除',     'delete',   0, 0, 10);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160344, 160102, 4, -1, '删除',     'delete',   0, 0, 11);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (160345, 160102, 3, 3, '关闭',   'close',  'is_closed=1', 0, 0, 12);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (160346, 160102, 3, 3, '反关闭', 'close',  'is_closed=0', 0, 0, 13);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (160347, 160102, 3, 3, '取消',   'cancel', 'is_cancel=1', 0, 1, 14);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (160348, 160102, 3, 3, '反取消', 'cancel', 'is_cancel=0', 0, 0, 15);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160349, 160102, 3,  3, '变更',     'change',   1, 1, 16);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160350, 160102, 3,  3, '下推',     'push',     0, 0, 17);

-- 4.4 PUR_RECEIVE_NOTICE (machine_id=160103) —— id=160351-160367
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160351, 160103, 0,  1, '保存',     'save',     0, 0, 1);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160352, 160103, 0,  0, '暂存',     'draft',    0, 0, 2);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160353, 160103, 1,  2, '提交',     'submit',   1, 0, 3);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160354, 160103, 2,  3, '审核',     'audit',    0, 0, 4);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160355, 160103, 2,  4, '驳回',     'reject',   0, 1, 5);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160356, 160103, 4,  2, '重新提交', 'resubmit', 1, 0, 6);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160357, 160103, 2,  1, '撤销',     'revoke',   0, 0, 7);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160358, 160103, 3,  1, '撤销',     'revoke',   0, 0, 8);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160359, 160103, 0, -1, '删除',     'delete',   0, 0, 9);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160360, 160103, 1, -1, '删除',     'delete',   0, 0, 10);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160361, 160103, 4, -1, '删除',     'delete',   0, 0, 11);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (160362, 160103, 3, 3, '关闭',   'close',  'is_closed=1', 0, 0, 12);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (160363, 160103, 3, 3, '反关闭', 'close',  'is_closed=0', 0, 0, 13);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (160364, 160103, 3, 3, '取消',   'cancel', 'is_cancel=1', 0, 1, 14);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (160365, 160103, 3, 3, '反取消', 'cancel', 'is_cancel=0', 0, 0, 15);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160366, 160103, 3,  3, '变更',     'change',   1, 1, 16);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160367, 160103, 3,  3, '下推',     'push',     0, 0, 17);

-- 4.5 PUR_IN_STOCK (machine_id=160104) —— id=160368-160384
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160368, 160104, 0,  1, '保存',     'save',     0, 0, 1);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160369, 160104, 0,  0, '暂存',     'draft',    0, 0, 2);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160370, 160104, 1,  2, '提交',     'submit',   1, 0, 3);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160371, 160104, 2,  3, '审核',     'audit',    0, 0, 4);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160372, 160104, 2,  4, '驳回',     'reject',   0, 1, 5);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160373, 160104, 4,  2, '重新提交', 'resubmit', 1, 0, 6);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160374, 160104, 2,  1, '撤销',     'revoke',   0, 0, 7);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160375, 160104, 3,  1, '撤销',     'revoke',   0, 0, 8);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160376, 160104, 0, -1, '删除',     'delete',   0, 0, 9);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160377, 160104, 1, -1, '删除',     'delete',   0, 0, 10);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160378, 160104, 4, -1, '删除',     'delete',   0, 0, 11);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (160379, 160104, 3, 3, '关闭',   'close',  'is_closed=1', 0, 0, 12);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (160380, 160104, 3, 3, '反关闭', 'close',  'is_closed=0', 0, 0, 13);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (160381, 160104, 3, 3, '取消',   'cancel', 'is_cancel=1', 0, 1, 14);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (160382, 160104, 3, 3, '反取消', 'cancel', 'is_cancel=0', 0, 0, 15);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160383, 160104, 3,  3, '变更',     'change',   1, 1, 16);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160384, 160104, 3,  3, '下推',     'push',     0, 0, 17);

-- 4.6 PUR_RETURN (machine_id=160105) —— id=160385-160401
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160385, 160105, 0,  1, '保存',     'save',     0, 0, 1);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160386, 160105, 0,  0, '暂存',     'draft',    0, 0, 2);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160387, 160105, 1,  2, '提交',     'submit',   1, 0, 3);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160388, 160105, 2,  3, '审核',     'audit',    0, 0, 4);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160389, 160105, 2,  4, '驳回',     'reject',   0, 1, 5);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160390, 160105, 4,  2, '重新提交', 'resubmit', 1, 0, 6);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160391, 160105, 2,  1, '撤销',     'revoke',   0, 0, 7);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160392, 160105, 3,  1, '撤销',     'revoke',   0, 0, 8);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160393, 160105, 0, -1, '删除',     'delete',   0, 0, 9);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160394, 160105, 1, -1, '删除',     'delete',   0, 0, 10);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160395, 160105, 4, -1, '删除',     'delete',   0, 0, 11);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (160396, 160105, 3, 3, '关闭',   'close',  'is_closed=1', 0, 0, 12);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (160397, 160105, 3, 3, '反关闭', 'close',  'is_closed=0', 0, 0, 13);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (160398, 160105, 3, 3, '取消',   'cancel', 'is_cancel=1', 0, 1, 14);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (160399, 160105, 3, 3, '反取消', 'cancel', 'is_cancel=0', 0, 0, 15);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160400, 160105, 3,  3, '变更',     'change',   1, 1, 16);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160401, 160105, 3,  3, '下推',     'push',     0, 0, 17);

-- 4.7 PUR_INVOICE (machine_id=160106) —— id=160402-160418
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160402, 160106, 0,  1, '保存',     'save',     0, 0, 1);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160403, 160106, 0,  0, '暂存',     'draft',    0, 0, 2);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160404, 160106, 1,  2, '提交',     'submit',   1, 0, 3);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160405, 160106, 2,  3, '审核',     'audit',    0, 0, 4);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160406, 160106, 2,  4, '驳回',     'reject',   0, 1, 5);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160407, 160106, 4,  2, '重新提交', 'resubmit', 1, 0, 6);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160408, 160106, 2,  1, '撤销',     'revoke',   0, 0, 7);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160409, 160106, 3,  1, '撤销',     'revoke',   0, 0, 8);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160410, 160106, 0, -1, '删除',     'delete',   0, 0, 9);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160411, 160106, 1, -1, '删除',     'delete',   0, 0, 10);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160412, 160106, 4, -1, '删除',     'delete',   0, 0, 11);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (160413, 160106, 3, 3, '关闭',   'close',  'is_closed=1', 0, 0, 12);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (160414, 160106, 3, 3, '反关闭', 'close',  'is_closed=0', 0, 0, 13);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (160415, 160106, 3, 3, '取消',   'cancel', 'is_cancel=1', 0, 1, 14);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (160416, 160106, 3, 3, '反取消', 'cancel', 'is_cancel=0', 0, 0, 15);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160417, 160106, 3,  3, '变更',     'change',   1, 1, 16);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (160418, 160106, 3,  3, '下推',     'push',     0, 0, 17);


-- ============================================================
-- 5. 表单实体层级（meta_form_entity）—— 7 主 + 7 子 + 1 孙 = 15 行
--    主表 entity_code=main_table；子表 entity_code='goods'；
--    孙表 entity_code='assign'（parent_entity_code='goods', entity_level=2）
-- ============================================================

-- 5.1 主实体（entity_type='main', entity_level=0）—— 7 行
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (160500, 'PUR_APPLY',          'pur_apply',          '采购申请', 'main', 0, 'pur_apply',          NULL,        NULL,         1);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (160502, 'PUR_CONT',           'pur_cont',           '采购合同', 'main', 0, 'pur_cont',           NULL,        NULL,         1);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (160505, 'PUR_ORDER',          'pur_order',          '采购订单', 'main', 0, 'pur_order',          NULL,        NULL,         1);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (160507, 'PUR_RECEIVE_NOTICE', 'pur_receive_notice', '收料通知', 'main', 0, 'pur_receive_notice', NULL,        NULL,         1);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (160509, 'PUR_IN_STOCK',       'pur_in_stock',       '采购入库', 'main', 0, 'pur_in_stock',       NULL,        NULL,         1);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (160511, 'PUR_RETURN',         'pur_return',         '采购退料', 'main', 0, 'pur_return',         NULL,        NULL,         1);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (160513, 'PUR_INVOICE',        'pur_invoice',        '采购发票', 'main', 0, 'pur_invoice',        NULL,        NULL,         1);

-- 5.2 子实体（entity_type='sub', entity_level=1）—— 7 行，entity_code='goods'
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (160501, 'PUR_APPLY',          'goods', '采购申请明细', 'sub', 1, 'pur_apply_goods',          'pur_apply',          'apply_id',     2);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (160503, 'PUR_CONT',           'goods', '采购合同明细', 'sub', 1, 'pur_cont_goods',           'pur_cont',           'cont_id',      2);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (160506, 'PUR_ORDER',          'goods', '采购订单明细', 'sub', 1, 'pur_order_goods',          'pur_order',          'order_id',     2);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (160508, 'PUR_RECEIVE_NOTICE', 'goods', '收料通知明细', 'sub', 1, 'pur_receive_notice_goods', 'pur_receive_notice', 'notice_id',    2);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (160510, 'PUR_IN_STOCK',       'goods', '采购入库明细', 'sub', 1, 'pur_in_stock_goods',       'pur_in_stock',       'in_stock_id',  2);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (160512, 'PUR_RETURN',         'goods', '采购退料明细', 'sub', 1, 'pur_return_goods',         'pur_return',         'return_id',    2);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (160514, 'PUR_INVOICE',        'goods', '采购发票明细', 'sub', 1, 'pur_invoice_goods',        'pur_invoice',        'invoice_id',   2);

-- 5.3 孙实体（entity_type='sub', entity_level=2）—— 1 行，PUR_CONT 配额分配
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (160504, 'PUR_CONT', 'assign', '合同明细配额', 'sub', 2, 'pur_cont_goods_assign', 'goods', 'cont_goods_id', 3);


-- ============================================================
-- 6. 表单字段元数据（meta_form_field）—— 148 行
--    仅注册关键字段（编码/日期/状态 + 组织/人员/供应商/仓库外键 + 金额 + 备注 + 审计字段）
--    字段类型：text/number/date/datetime/enum/ref/qty/amount
--    控件类型：text/textarea/number/date/datetime/select/ref/qty/amount
--    ref 字段附带 ref_bo_code；ID 区间 200300-200447
-- ============================================================

-- ------------------------------------------------------------
-- 6.1 PUR_APPLY 采购申请
-- ------------------------------------------------------------
-- 主表 pur_apply（12 字段）
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200300, 'PUR_APPLY', 'pur_apply', 'code',          '单据编码', 'text',   'text',     1, 0, 1,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200301, 'PUR_APPLY', 'pur_apply', 'apply_date',    '申请日期', 'date',   'date',     1, 0, 2,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200302, 'PUR_APPLY', 'pur_apply', 'pact_state',    '单据状态', 'enum',   'select',   0, 1, 3,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200303, 'PUR_APPLY', 'pur_apply', 'pur_org_id',    '采购组织', 'ref',    'ref',      1, 0, 'MD_ORG',      4,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200304, 'PUR_APPLY', 'pur_apply', 'dept_id',       '申请部门', 'ref',    'ref',      0, 0, 'MD_DEPT',     5,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200305, 'PUR_APPLY', 'pur_apply', 'applicant_id',  '申请人',   'ref',    'ref',      1, 0, 'MD_EMPLOYEE', 6,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200306, 'PUR_APPLY', 'pur_apply', 'req_date',      '需求日期', 'date',   'date',     0, 0, 7,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200307, 'PUR_APPLY', 'pur_apply', 'supplier_id',   '供应商',   'ref',    'ref',      1, 0, 'MD_SUPPLIER', 8,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200308, 'PUR_APPLY', 'pur_apply', 'total_qty',     '总数量',   'qty',    'qty',      0, 1, 9,  '金额信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200309, 'PUR_APPLY', 'pur_apply', 'total_amount',  '总金额',   'amount', 'amount',   0, 1, 10, '金额信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200310, 'PUR_APPLY', 'pur_apply', 'remark',        '备注',     'text',   'textarea', 0, 0, 11, '其他');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200311, 'PUR_APPLY', 'pur_apply', 'auditor',       '审核人',   'ref',    'ref',      0, 1, 'MD_EMPLOYEE', 12, '审计信息');
-- 子表 pur_apply_goods / goods（8 字段）
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200312, 'PUR_APPLY', 'goods', 'sort_index', '行号',   'number', 'number',   0, 0, 1, '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200313, 'PUR_APPLY', 'goods', 'apply_id',   '申请单', 'ref',    'ref',      1, 1, 'PUR_APPLY',    2, '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200314, 'PUR_APPLY', 'goods', 'mat_id',     '物料',   'ref',    'ref',      1, 0, 'MD_MATERIAL',  3, '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200315, 'PUR_APPLY', 'goods', 'qty',        '数量',   'qty',    'qty',      1, 0, 4, '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200316, 'PUR_APPLY', 'goods', 'unit',       '单位',   'ref',    'ref',      0, 0, 'MD_UNIT',      5, '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200317, 'PUR_APPLY', 'goods', 'price',      '单价',   'amount', 'amount',   0, 0, 6, '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200318, 'PUR_APPLY', 'goods', 'amount',     '金额',   'amount', 'amount',   0, 1, 7, '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200319, 'PUR_APPLY', 'goods', 'remark',     '备注',   'text',   'textarea', 0, 0, 8, '明细信息');

-- ------------------------------------------------------------
-- 6.2 PUR_CONT 采购合同
-- ------------------------------------------------------------
-- 主表 pur_cont（12 字段）
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200320, 'PUR_CONT', 'pur_cont', 'code',          '单据编码', 'text',   'text',     1, 0, 1,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200321, 'PUR_CONT', 'pur_cont', 'pact_date',     '合同日期', 'date',   'date',     1, 0, 2,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200322, 'PUR_CONT', 'pur_cont', 'pact_state',    '单据状态', 'enum',   'select',   0, 1, 3,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200323, 'PUR_CONT', 'pur_cont', 'supplier_id',   '供应商',   'ref',    'ref',      1, 0, 'MD_SUPPLIER', 4,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200324, 'PUR_CONT', 'pur_cont', 'pur_org_id',    '采购组织', 'ref',    'ref',      1, 0, 'MD_ORG',      5,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200325, 'PUR_CONT', 'pur_cont', 'pur_dept_id',   '采购部门', 'ref',    'ref',      0, 0, 'MD_DEPT',     6,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200326, 'PUR_CONT', 'pur_cont', 'purchaser_id',  '采购员',   'ref',    'ref',      0, 0, 'MD_EMPLOYEE', 7,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200327, 'PUR_CONT', 'pur_cont', 'curr_id',       '币别',     'ref',    'ref',      0, 0, 'MD_CURRENCY', 8,  '金额信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200328, 'PUR_CONT', 'pur_cont', 'total_qty',     '总数量',   'qty',    'qty',      0, 1, 9,  '金额信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200329, 'PUR_CONT', 'pur_cont', 'total_amount',  '总金额',   'amount', 'amount',   0, 1, 10, '金额信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200330, 'PUR_CONT', 'pur_cont', 'remark',        '备注',     'text',   'textarea', 0, 0, 11, '其他');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200331, 'PUR_CONT', 'pur_cont', 'auditor',       '审核人',   'ref',    'ref',      0, 1, 'MD_EMPLOYEE', 12, '审计信息');
-- 子表 pur_cont_goods / goods（9 字段）
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200332, 'PUR_CONT', 'goods', 'sort_index',   '行号',     'number', 'number',   0, 0, 1, '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200333, 'PUR_CONT', 'goods', 'cont_id',      '合同',     'ref',    'ref',      1, 1, 'PUR_CONT',     2, '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200334, 'PUR_CONT', 'goods', 'mat_id',       '物料',     'ref',    'ref',      1, 0, 'MD_MATERIAL',  3, '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200335, 'PUR_CONT', 'goods', 'qty',          '数量',     'qty',    'qty',      1, 0, 4, '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200336, 'PUR_CONT', 'goods', 'unit',         '单位',     'ref',    'ref',      0, 0, 'MD_UNIT',      5, '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200337, 'PUR_CONT', 'goods', 'price',        '单价',     'amount', 'amount',   0, 0, 6, '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200338, 'PUR_CONT', 'goods', 'amount',       '金额',     'amount', 'amount',   0, 1, 7, '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200339, 'PUR_CONT', 'goods', 'require_date', '需求日期', 'date',   'date',     0, 0, 8, '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200340, 'PUR_CONT', 'goods', 'tax_rate',     '税率',     'number', 'number',   0, 0, 9, '明细信息');
-- 孙表 pur_cont_goods_assign / assign（6 字段）
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200341, 'PUR_CONT', 'assign', 'sort_index',    '行号',       'number', 'number',   0, 0, 1, '配额信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200342, 'PUR_CONT', 'assign', 'cont_goods_id', '合同明细',   'number', 'number',   1, 1, 2, '配额信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200343, 'PUR_CONT', 'assign', 'mat_id',        '物料',       'ref',    'ref',      1, 0, 'MD_MATERIAL', 3, '配额信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200344, 'PUR_CONT', 'assign', 'qty',           '数量',       'qty',    'qty',      1, 0, 4, '配额信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200345, 'PUR_CONT', 'assign', 'price',         '单价',       'amount', 'amount',   0, 0, 5, '配额信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200346, 'PUR_CONT', 'assign', 'remark',        '备注',       'text',   'textarea', 0, 0, 6, '配额信息');

-- ------------------------------------------------------------
-- 6.3 PUR_ORDER 采购订单
-- ------------------------------------------------------------
-- 主表 pur_order（13 字段）
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200347, 'PUR_ORDER', 'pur_order', 'code',          '单据编码', 'text',   'text',     1, 0, 1,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200348, 'PUR_ORDER', 'pur_order', 'order_date',    '订单日期', 'date',   'date',     1, 0, 2,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200349, 'PUR_ORDER', 'pur_order', 'pact_state',    '单据状态', 'enum',   'select',   0, 1, 3,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200350, 'PUR_ORDER', 'pur_order', 'supplier_id',   '供应商',   'ref',    'ref',      1, 0, 'MD_SUPPLIER', 4,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200351, 'PUR_ORDER', 'pur_order', 'pur_org_id',    '采购组织', 'ref',    'ref',      1, 0, 'MD_ORG',      5,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200352, 'PUR_ORDER', 'pur_order', 'pur_dept_id',   '采购部门', 'ref',    'ref',      0, 0, 'MD_DEPT',     6,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200353, 'PUR_ORDER', 'pur_order', 'purchaser_id',  '采购员',   'ref',    'ref',      0, 0, 'MD_EMPLOYEE', 7,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200354, 'PUR_ORDER', 'pur_order', 'curr_id',       '币别',     'ref',    'ref',      0, 0, 'MD_CURRENCY', 8,  '金额信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200355, 'PUR_ORDER', 'pur_order', 'total_qty',     '总数量',   'qty',    'qty',      0, 1, 9,  '金额信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200356, 'PUR_ORDER', 'pur_order', 'total_amount',  '总金额',   'amount', 'amount',   0, 1, 10, '金额信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200357, 'PUR_ORDER', 'pur_order', 'received_qty',  '已收数量', 'qty',    'qty',      0, 1, 11, '金额信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200358, 'PUR_ORDER', 'pur_order', 'pur_cont_id',   '采购合同', 'ref',    'ref',      0, 0, 'PUR_CONT',    12, '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200359, 'PUR_ORDER', 'pur_order', 'remark',        '备注',     'text',   'textarea', 0, 0, 13, '其他');
-- 子表 pur_order_goods / goods（8 字段）
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200360, 'PUR_ORDER', 'goods', 'sort_index', '行号',   'number', 'number',   0, 0, 1, '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200361, 'PUR_ORDER', 'goods', 'order_id',   '订单',   'ref',    'ref',      1, 1, 'PUR_ORDER',    2, '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200362, 'PUR_ORDER', 'goods', 'mat_id',     '物料',   'ref',    'ref',      1, 0, 'MD_MATERIAL',  3, '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200363, 'PUR_ORDER', 'goods', 'qty',        '数量',   'qty',    'qty',      1, 0, 4, '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200364, 'PUR_ORDER', 'goods', 'unit',       '单位',   'ref',    'ref',      0, 0, 'MD_UNIT',      5, '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200365, 'PUR_ORDER', 'goods', 'price',      '单价',   'amount', 'amount',   0, 0, 6, '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200366, 'PUR_ORDER', 'goods', 'amount',     '金额',   'amount', 'amount',   0, 1, 7, '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200367, 'PUR_ORDER', 'goods', 'remark',     '备注',   'text',   'textarea', 0, 0, 8, '明细信息');

-- ------------------------------------------------------------
-- 6.4 PUR_RECEIVE_NOTICE 收料通知
-- ------------------------------------------------------------
-- 主表 pur_receive_notice（11 字段）
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200368, 'PUR_RECEIVE_NOTICE', 'pur_receive_notice', 'code',           '单据编码', 'text',   'text',     1, 0, 1,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200369, 'PUR_RECEIVE_NOTICE', 'pur_receive_notice', 'notice_date',    '通知日期', 'date',   'date',     1, 0, 2,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200370, 'PUR_RECEIVE_NOTICE', 'pur_receive_notice', 'pact_state',     '单据状态', 'enum',   'select',   0, 1, 3,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200371, 'PUR_RECEIVE_NOTICE', 'pur_receive_notice', 'supplier_id',    '供应商',   'ref',    'ref',      1, 0, 'MD_SUPPLIER',    4,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200372, 'PUR_RECEIVE_NOTICE', 'pur_receive_notice', 'pur_org_id',     '采购组织', 'ref',    'ref',      1, 0, 'MD_ORG',         5,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200373, 'PUR_RECEIVE_NOTICE', 'pur_receive_notice', 'pur_order_id',   '采购订单', 'ref',    'ref',      0, 0, 'PUR_ORDER',      6,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200374, 'PUR_RECEIVE_NOTICE', 'pur_receive_notice', 'plan_date',      '计划交货日期', 'date', 'date',   0, 0, 7,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200375, 'PUR_RECEIVE_NOTICE', 'pur_receive_notice', 'transport_type', '运输方式', 'enum',   'select',   0, 0, 8,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200376, 'PUR_RECEIVE_NOTICE', 'pur_receive_notice', 'tracking_no',    '物流单号', 'text',   'text',     0, 0, 9,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200377, 'PUR_RECEIVE_NOTICE', 'pur_receive_notice', 'total_qty',      '总数量',   'qty',    'qty',      0, 1, 10, '金额信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200378, 'PUR_RECEIVE_NOTICE', 'pur_receive_notice', 'remark',         '备注',     'text',   'textarea', 0, 0, 11, '其他');
-- 子表 pur_receive_notice_goods / goods（7 字段）
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200379, 'PUR_RECEIVE_NOTICE', 'goods', 'sort_index', '行号',   'number', 'number',   0, 0, 1, '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200380, 'PUR_RECEIVE_NOTICE', 'goods', 'notice_id',  '收料通知', 'ref',  'ref',      1, 1, 'PUR_RECEIVE_NOTICE', 2, '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200381, 'PUR_RECEIVE_NOTICE', 'goods', 'mat_id',     '物料',     'ref',  'ref',      1, 0, 'MD_MATERIAL',        3, '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200382, 'PUR_RECEIVE_NOTICE', 'goods', 'lot_no',     '批号',     'text', 'text',     0, 0, 4, '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200383, 'PUR_RECEIVE_NOTICE', 'goods', 'qty',        '数量',     'qty',  'qty',      1, 0, 5, '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200384, 'PUR_RECEIVE_NOTICE', 'goods', 'unit',       '单位',     'ref',  'ref',      0, 0, 'MD_UNIT',            6, '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200385, 'PUR_RECEIVE_NOTICE', 'goods', 'remark',     '备注',     'text', 'textarea', 0, 0, 7, '明细信息');

-- ------------------------------------------------------------
-- 6.5 PUR_IN_STOCK 采购入库
-- ------------------------------------------------------------
-- 主表 pur_in_stock（12 字段）
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200386, 'PUR_IN_STOCK', 'pur_in_stock', 'code',            '单据编码', 'text',   'text',     1, 0, 1,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200387, 'PUR_IN_STOCK', 'pur_in_stock', 'in_date',         '入库日期', 'date',   'date',     1, 0, 2,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200388, 'PUR_IN_STOCK', 'pur_in_stock', 'pact_state',      '单据状态', 'enum',   'select',   0, 1, 3,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200389, 'PUR_IN_STOCK', 'pur_in_stock', 'supplier_id',     '供应商',   'ref',    'ref',      1, 0, 'MD_SUPPLIER', 4,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200390, 'PUR_IN_STOCK', 'pur_in_stock', 'pur_org_id',      '采购组织', 'ref',    'ref',      1, 0, 'MD_ORG',      5,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200391, 'PUR_IN_STOCK', 'pur_in_stock', 'warehouse_id',    '仓库',     'ref',    'ref',      1, 0, 'MD_WAREHOUSE',6,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200392, 'PUR_IN_STOCK', 'pur_in_stock', 'in_type',         '入库类型', 'enum',   'select',   0, 0, 7,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200393, 'PUR_IN_STOCK', 'pur_in_stock', 'curr_id',         '币别',     'ref',    'ref',      0, 0, 'MD_CURRENCY', 8,  '金额信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200394, 'PUR_IN_STOCK', 'pur_in_stock', 'pur_order_id',    '采购订单', 'ref',    'ref',      0, 0, 'PUR_ORDER',   9,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200395, 'PUR_IN_STOCK', 'pur_in_stock', 'total_qty',       '总数量',   'qty',    'qty',      0, 1, 10, '金额信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200396, 'PUR_IN_STOCK', 'pur_in_stock', 'total_amount',    '总金额',   'amount', 'amount',   0, 1, 11, '金额信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200397, 'PUR_IN_STOCK', 'pur_in_stock', 'remark',          '备注',     'text',   'textarea', 0, 0, 12, '其他');
-- 子表 pur_in_stock_goods / goods（9 字段）
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200398, 'PUR_IN_STOCK', 'goods', 'sort_index',  '行号',   'number', 'number',   0, 0, 1, '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200399, 'PUR_IN_STOCK', 'goods', 'in_stock_id', '入库单', 'ref',    'ref',      1, 1, 'PUR_IN_STOCK', 2, '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200400, 'PUR_IN_STOCK', 'goods', 'mat_id',      '物料',   'ref',    'ref',      1, 0, 'MD_MATERIAL',  3, '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200401, 'PUR_IN_STOCK', 'goods', 'lot_no',      '批号',   'text',   'text',     0, 0, 4, '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200402, 'PUR_IN_STOCK', 'goods', 'qty',         '数量',   'qty',    'qty',      1, 0, 5, '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200403, 'PUR_IN_STOCK', 'goods', 'unit',        '单位',   'ref',    'ref',      0, 0, 'MD_UNIT',      6, '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200404, 'PUR_IN_STOCK', 'goods', 'price',       '单价',   'amount', 'amount',   0, 0, 7, '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200405, 'PUR_IN_STOCK', 'goods', 'amount',      '金额',   'amount', 'amount',   0, 1, 8, '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200406, 'PUR_IN_STOCK', 'goods', 'tax_rate',    '税率',   'number', 'number',   0, 0, 9, '明细信息');

-- ------------------------------------------------------------
-- 6.6 PUR_RETURN 采购退料
-- ------------------------------------------------------------
-- 主表 pur_return（11 字段）
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200407, 'PUR_RETURN', 'pur_return', 'code',          '单据编码', 'text',   'text',     1, 0, 1,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200408, 'PUR_RETURN', 'pur_return', 'return_date',   '退料日期', 'date',   'date',     1, 0, 2,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200409, 'PUR_RETURN', 'pur_return', 'pact_state',    '单据状态', 'enum',   'select',   0, 1, 3,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200410, 'PUR_RETURN', 'pur_return', 'supplier_id',   '供应商',   'ref',    'ref',      1, 0, 'MD_SUPPLIER', 4,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200411, 'PUR_RETURN', 'pur_return', 'pur_org_id',    '采购组织', 'ref',    'ref',      1, 0, 'MD_ORG',      5,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200412, 'PUR_RETURN', 'pur_return', 'warehouse_id',  '仓库',     'ref',    'ref',      1, 0, 'MD_WAREHOUSE',6,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200413, 'PUR_RETURN', 'pur_return', 'in_stock_id',   '入库单',   'ref',    'ref',      0, 0, 'PUR_IN_STOCK',7,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200414, 'PUR_RETURN', 'pur_return', 'return_reason', '退料原因', 'text',   'textarea', 0, 0, 8,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200415, 'PUR_RETURN', 'pur_return', 'total_qty',     '总数量',   'qty',    'qty',      0, 1, 9,  '金额信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200416, 'PUR_RETURN', 'pur_return', 'total_amount',  '总金额',   'amount', 'amount',   0, 1, 10, '金额信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200417, 'PUR_RETURN', 'pur_return', 'remark',        '备注',     'text',   'textarea', 0, 0, 11, '其他');
-- 子表 pur_return_goods / goods（8 字段）
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200418, 'PUR_RETURN', 'goods', 'sort_index', '行号',   'number', 'number',   0, 0, 1, '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200419, 'PUR_RETURN', 'goods', 'return_id',  '退料单', 'ref',    'ref',      1, 1, 'PUR_RETURN',   2, '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200420, 'PUR_RETURN', 'goods', 'mat_id',     '物料',   'ref',    'ref',      1, 0, 'MD_MATERIAL',  3, '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200421, 'PUR_RETURN', 'goods', 'lot_no',     '批号',   'text',   'text',     0, 0, 4, '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200422, 'PUR_RETURN', 'goods', 'qty',        '数量',   'qty',    'qty',      1, 0, 5, '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200423, 'PUR_RETURN', 'goods', 'unit',       '单位',   'ref',    'ref',      0, 0, 'MD_UNIT',      6, '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200424, 'PUR_RETURN', 'goods', 'price',      '单价',   'amount', 'amount',   0, 0, 7, '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200425, 'PUR_RETURN', 'goods', 'amount',     '金额',   'amount', 'amount',   0, 1, 8, '明细信息');

-- ------------------------------------------------------------
-- 6.7 PUR_INVOICE 采购发票
-- ------------------------------------------------------------
-- 主表 pur_invoice（13 字段）
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200426, 'PUR_INVOICE', 'pur_invoice', 'code',           '单据编码',   'text',   'text',     1, 0, 1,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200427, 'PUR_INVOICE', 'pur_invoice', 'invoice_code',  '发票代码',   'text',   'text',     1, 0, 2,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200428, 'PUR_INVOICE', 'pur_invoice', 'invoice_no',    '发票号码',   'text',   'text',     1, 0, 3,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200429, 'PUR_INVOICE', 'pur_invoice', 'invoice_date',  '开票日期',   'date',   'date',     1, 0, 4,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200430, 'PUR_INVOICE', 'pur_invoice', 'pact_state',    '单据状态',   'enum',   'select',   0, 1, 5,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200431, 'PUR_INVOICE', 'pur_invoice', 'supplier_id',   '供应商',     'ref',    'ref',      1, 0, 'MD_SUPPLIER', 6,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200432, 'PUR_INVOICE', 'pur_invoice', 'pur_org_id',    '采购组织',   'ref',    'ref',      1, 0, 'MD_ORG',      7,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200433, 'PUR_INVOICE', 'pur_invoice', 'invoice_type',  '发票类型',   'enum',   'select',   0, 0, 8,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200434, 'PUR_INVOICE', 'pur_invoice', 'no_tax_amount', '不含税金额', 'amount', 'amount',   0, 1, 9,  '金额信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200435, 'PUR_INVOICE', 'pur_invoice', 'tax_amount',    '税额',       'amount', 'amount',   0, 1, 10, '金额信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200436, 'PUR_INVOICE', 'pur_invoice', 'total_amount',  '价税合计',   'amount', 'amount',   0, 1, 11, '金额信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200437, 'PUR_INVOICE', 'pur_invoice', 'ap_id',         '应付单',     'number', 'number',   0, 0, 12, '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200438, 'PUR_INVOICE', 'pur_invoice', 'remark',        '备注',       'text',   'textarea', 0, 0, 13, '其他');
-- 子表 pur_invoice_goods / goods（9 字段）
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200439, 'PUR_INVOICE', 'goods', 'sort_index',     '行号',       'number', 'number',   0, 0, 1, '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200440, 'PUR_INVOICE', 'goods', 'invoice_id',     '采购发票',   'ref',    'ref',      1, 1, 'PUR_INVOICE',  2, '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200441, 'PUR_INVOICE', 'goods', 'mat_id',         '物料',       'ref',    'ref',      1, 0, 'MD_MATERIAL',  3, '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200442, 'PUR_INVOICE', 'goods', 'qty',            '数量',       'qty',    'qty',      1, 0, 4, '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200443, 'PUR_INVOICE', 'goods', 'unit',           '单位',       'ref',    'ref',      0, 0, 'MD_UNIT',      5, '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200444, 'PUR_INVOICE', 'goods', 'price',          '单价',       'amount', 'amount',   0, 0, 6, '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200445, 'PUR_INVOICE', 'goods', 'no_tax_amount',  '不含税金额', 'amount', 'amount',   0, 1, 7, '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200446, 'PUR_INVOICE', 'goods', 'tax_rate',       '税率',       'number', 'number',   0, 0, 8, '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200447, 'PUR_INVOICE', 'goods', 'tax_amount',     '税额',       'amount', 'amount',   0, 1, 9, '明细信息');


-- ============================================================
-- 文件末尾说明
-- ============================================================
-- ID 范围汇总：
--   meta_business_object  160001-160007   (7 行采购业务对象)
--   meta_state_machine    160100-160106   (7 行，code=bo_code，state_field=pact_state)
--   meta_state_node       160200-160234   (35 行，每状态机 5 节点，复制 STD_5STATE)
--   meta_state_transition 160300-160418   (119 行，每状态机 17 流转，t12-t15 含 post_action)
--   meta_form_entity      160500-160514   (15 行：7 主 + 7 子 + 1 孙)
--   meta_form_field       200300-200447   (148 行关键字段)
-- 依赖关系：
--   1. schema-h2.sql 提供元数据表结构（meta_business_object/meta_state_machine/
--      meta_state_node/meta_state_transition/meta_form_entity/meta_form_field）。
--   2. data-h2-seed.sql 提供标准状态机 STD_5STATE（machine_id=100）及测试主数据
--      （组织/部门/员工/供应商/物料/币别/仓库/单位等）。
--   3. data-h2-master-seed.sql 提供 30 个主数据 bo_code（MD_ORG/MD_DEPT/MD_EMPLOYEE/
--      MD_SUPPLIER/MD_MATERIAL/MD_CURRENCY/MD_WAREHOUSE/MD_UNIT 等），本文件
--      meta_form_field.ref_bo_code 引用这些主数据 bo_code。
--   4. 采购单据间互引：PUR_ORDER.pur_cont_id→PUR_CONT；PUR_RECEIVE_NOTICE.pur_order_id
--      →PUR_ORDER；PUR_IN_STOCK.pur_order_id→PUR_ORDER；PUR_RETURN.in_stock_id→PUR_IN_STOCK。
--   5. PUR_CONT 孙表 assign.cont_goods_id 为 bigint 外键（指向子表 goods 行，
--      非业务对象，故 field_type='number' 不带 ref_bo_code）。
--   6. PUR_INVOICE.ap_id 指向应付单（AP 模块未在本文件注册，field_type='number'）。
-- 加载顺序建议：schema-h2.sql → data-h2-seed.sql → data-h2-master-seed.sql → 本文件。
-- ============================================================
