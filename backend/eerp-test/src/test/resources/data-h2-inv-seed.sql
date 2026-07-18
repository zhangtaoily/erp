-- ============================================================
-- EERP H2 INV (库存管理) 元数据种子
-- ============================================================
-- 用途：集成测试 H2 内存数据库库存管理模块元数据种子（Phase 2c）。
--       为 9 个库存业务单据 bo_code 注册业务对象、独立状态机
--       （5 节点 / 17 流转，复制 STD_5STATE 模型）、表单实体层级
--       （主/子）与关键字段元数据，驱动 GenericBillService →
--       GenericOperationService 的 6 阶段流水线，无需具体 Entity/Mapper。
-- 加载：spring.sql.init.data-locations 追加本文件。
-- 幂等：全部使用 REPLACE INTO ... VALUES (...)，可重复执行。
-- ID 约定（与 data-h2-master-seed / scm-seed / sal-seed 不冲突）：
--   meta_business_object  180001-180009   (9 行)
--   meta_state_machine    180100-180106   (7 行，仅 7 个有状态机的 bo_code；code=bo_code)
--   meta_state_node       180200-180234   (7×5=35 行)
--   meta_state_transition 180300-180418   (7×17=119 行)
--   meta_form_entity      180500-180515   (9 主 + 7 子 = 16 行)
--   meta_form_field       220300-220425   (126 行)
-- 特殊约定：
--   1. INV_STOCK / INV_BATCH 为即时查询型台账，is_stateful=0，
--      不注册状态机（无 meta_state_machine/node/transition），
--      is_pushable=0, is_printable=0，保存即落库，不走状态流转。
--   2. INV_OTHER_IN / INV_OTHER_OUT 共享物理表 inv_other_stock 与
--      inv_other_stock_goods，但为两个独立 bo_code：
--      - INV_OTHER_IN  主实体 entity_code='inv_other_in'，stock_direction='in'
--      - INV_OTHER_OUT 主实体 entity_code='inv_other_out'，stock_direction='out'
--      两者 table_name 均为 inv_other_stock；子表 link_field='bill_id'
--      （schema 实际列名，非 stock_id）。
--   3. 子表 link_field 严格对齐 schema-h2.sql 实际列名：
--      inv_stocktake_goods.stocktake_id / inv_transfer_goods.transfer_id /
--      inv_form_conv_goods.conv_id / inv_other_stock_goods.bill_id /
--      inv_lock_goods.lock_id / inv_lock_apply_goods.lock_apply_id。
-- 有状态机的单据约定：bo_type='business', is_stateful=1, is_pushable=1,
--      is_printable=1, pk_strategy='snowflake', main_key='id', status=1
-- 状态机复制：每 bo_code 复制 STD_5STATE（machine_id=100）的 5 节点
--      （id=101-105）与 17 流转（id=200-216），替换 machine_id。
--      t12-t15 含 post_action（is_closed/is_cancel 标记）。
-- 兼容：H2 MODE=MySQL；时间戳使用 CURRENT_TIMESTAMP；布尔值统一用 1/0。
-- 依赖：schema-h2.sql（元数据表结构 + inv_ 业务表）；data-h2-seed.sql（STD_5STATE
--       及主数据）；data-h2-master-seed.sql（30 个主数据 bo_code）；
--       data-h2-scm-seed.sql / data-h2-sal-seed.sql（前置模块）。
-- ============================================================


-- ============================================================
-- 1. 业务对象定义（meta_business_object）—— 9 个库存业务 BO
-- ============================================================

-- 1.1 无状态机台账（is_stateful=0）—— 2 行
REPLACE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
VALUES (180001, 'INV_STOCK',   '即时库存', 'business', 'inv_stock', 'id', 'snowflake', 0, 0, 0, NULL, 1, '即时库存台账（无状态机）', 'system', CURRENT_TIMESTAMP);
REPLACE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
VALUES (180002, 'INV_BATCH',   '批次台账', 'business', 'inv_batch', 'id', 'snowflake', 0, 0, 0, NULL, 1, '批次台账（无状态机）', 'system', CURRENT_TIMESTAMP);

-- 1.2 有状态机业务单据（is_stateful=1）—— 7 行
REPLACE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
VALUES (180003, 'INV_STOCKTAKE',  '盘点单',   'business', 'inv_stocktake', 'id', 'snowflake', 1, 1, 1, NULL, 1, '盘点单业务单据', 'system', CURRENT_TIMESTAMP);
REPLACE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
VALUES (180004, 'INV_TRANSFER',   '调拨单',   'business', 'inv_transfer',   'id', 'snowflake', 1, 1, 1, NULL, 1, '调拨单业务单据', 'system', CURRENT_TIMESTAMP);
REPLACE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
VALUES (180005, 'INV_FORM_CONV',  '形态转换', 'business', 'inv_form_conv',  'id', 'snowflake', 1, 1, 1, NULL, 1, '形态转换业务单据', 'system', CURRENT_TIMESTAMP);
REPLACE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
VALUES (180006, 'INV_OTHER_IN',   '其他入库', 'business', 'inv_other_stock','id', 'snowflake', 1, 1, 1, NULL, 1, '其他入库业务单据（共享 inv_other_stock 表）', 'system', CURRENT_TIMESTAMP);
REPLACE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
VALUES (180007, 'INV_OTHER_OUT',  '其他出库', 'business', 'inv_other_stock','id', 'snowflake', 1, 1, 1, NULL, 1, '其他出库业务单据（共享 inv_other_stock 表）', 'system', CURRENT_TIMESTAMP);
REPLACE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
VALUES (180008, 'INV_LOCK',       '锁库单',   'business', 'inv_lock',       'id', 'snowflake', 1, 1, 1, NULL, 1, '锁库单业务单据', 'system', CURRENT_TIMESTAMP);
REPLACE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
VALUES (180009, 'INV_LOCK_APPLY', '锁库申请', 'business', 'inv_lock_apply', 'id', 'snowflake', 1, 1, 1, NULL, 1, '锁库申请单业务单据', 'system', CURRENT_TIMESTAMP);


-- ============================================================
-- 2. 状态机定义（meta_state_machine）—— 7 行，code=bo_code
--    StateMachineCache.load(boCode) 通过 code=bo_code 查询
--    INV_STOCK / INV_BATCH 不注册（is_stateful=0）
-- ============================================================

REPLACE INTO meta_state_machine (id, code, name, state_field, remark)
VALUES (180100, 'INV_STOCKTAKE',  '盘点单状态机',   'pact_state', '复制 STD_5STATE：0暂存/1已创建/2已提交/3已审核/4已驳回；is_closed/is_cancel 辅助标记');
REPLACE INTO meta_state_machine (id, code, name, state_field, remark)
VALUES (180101, 'INV_TRANSFER',   '调拨单状态机',   'pact_state', '复制 STD_5STATE：0暂存/1已创建/2已提交/3已审核/4已驳回；is_closed/is_cancel 辅助标记');
REPLACE INTO meta_state_machine (id, code, name, state_field, remark)
VALUES (180102, 'INV_FORM_CONV',  '形态转换状态机', 'pact_state', '复制 STD_5STATE：0暂存/1已创建/2已提交/3已审核/4已驳回；is_closed/is_cancel 辅助标记');
REPLACE INTO meta_state_machine (id, code, name, state_field, remark)
VALUES (180103, 'INV_OTHER_IN',   '其他入库状态机', 'pact_state', '复制 STD_5STATE：0暂存/1已创建/2已提交/3已审核/4已驳回；is_closed/is_cancel 辅助标记');
REPLACE INTO meta_state_machine (id, code, name, state_field, remark)
VALUES (180104, 'INV_OTHER_OUT',  '其他出库状态机', 'pact_state', '复制 STD_5STATE：0暂存/1已创建/2已提交/3已审核/4已驳回；is_closed/is_cancel 辅助标记');
REPLACE INTO meta_state_machine (id, code, name, state_field, remark)
VALUES (180105, 'INV_LOCK',       '锁库单状态机',   'pact_state', '复制 STD_5STATE：0暂存/1已创建/2已提交/3已审核/4已驳回；is_closed/is_cancel 辅助标记');
REPLACE INTO meta_state_machine (id, code, name, state_field, remark)
VALUES (180106, 'INV_LOCK_APPLY', '锁库申请状态机', 'pact_state', '复制 STD_5STATE：0暂存/1已创建/2已提交/3已审核/4已驳回；is_closed/is_cancel 辅助标记');


-- ============================================================
-- 3. 状态节点（meta_state_node）—— 7×5=35 行
--    复制 STD_5STATE 节点（machine_id=100 的 id=101-105），替换 machine_id
--    0暂存(初始) 1已创建 2已提交 3已审核 4已驳回
-- ============================================================

-- 3.1 INV_STOCKTAKE (machine_id=180100) —— id=180200-180204
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (180200, 180100, 0, '暂存',   '#909399', 1, 0, 1, 1, 0);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (180201, 180100, 1, '已创建', '#409EFF', 0, 0, 1, 1, 1);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (180202, 180100, 2, '已提交', '#E6A23C', 0, 0, 0, 0, 2);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (180203, 180100, 3, '已审核', '#67C23A', 0, 0, 0, 0, 3);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (180204, 180100, 4, '已驳回', '#F56C6C', 0, 0, 1, 1, 4);

-- 3.2 INV_TRANSFER (machine_id=180101) —— id=180205-180209
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (180205, 180101, 0, '暂存',   '#909399', 1, 0, 1, 1, 0);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (180206, 180101, 1, '已创建', '#409EFF', 0, 0, 1, 1, 1);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (180207, 180101, 2, '已提交', '#E6A23C', 0, 0, 0, 0, 2);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (180208, 180101, 3, '已审核', '#67C23A', 0, 0, 0, 0, 3);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (180209, 180101, 4, '已驳回', '#F56C6C', 0, 0, 1, 1, 4);

-- 3.3 INV_FORM_CONV (machine_id=180102) —— id=180210-180214
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (180210, 180102, 0, '暂存',   '#909399', 1, 0, 1, 1, 0);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (180211, 180102, 1, '已创建', '#409EFF', 0, 0, 1, 1, 1);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (180212, 180102, 2, '已提交', '#E6A23C', 0, 0, 0, 0, 2);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (180213, 180102, 3, '已审核', '#67C23A', 0, 0, 0, 0, 3);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (180214, 180102, 4, '已驳回', '#F56C6C', 0, 0, 1, 1, 4);

-- 3.4 INV_OTHER_IN (machine_id=180103) —— id=180215-180219
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (180215, 180103, 0, '暂存',   '#909399', 1, 0, 1, 1, 0);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (180216, 180103, 1, '已创建', '#409EFF', 0, 0, 1, 1, 1);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (180217, 180103, 2, '已提交', '#E6A23C', 0, 0, 0, 0, 2);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (180218, 180103, 3, '已审核', '#67C23A', 0, 0, 0, 0, 3);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (180219, 180103, 4, '已驳回', '#F56C6C', 0, 0, 1, 1, 4);

-- 3.5 INV_OTHER_OUT (machine_id=180104) —— id=180220-180224
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (180220, 180104, 0, '暂存',   '#909399', 1, 0, 1, 1, 0);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (180221, 180104, 1, '已创建', '#409EFF', 0, 0, 1, 1, 1);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (180222, 180104, 2, '已提交', '#E6A23C', 0, 0, 0, 0, 2);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (180223, 180104, 3, '已审核', '#67C23A', 0, 0, 0, 0, 3);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (180224, 180104, 4, '已驳回', '#F56C6C', 0, 0, 1, 1, 4);

-- 3.6 INV_LOCK (machine_id=180105) —— id=180225-180229
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (180225, 180105, 0, '暂存',   '#909399', 1, 0, 1, 1, 0);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (180226, 180105, 1, '已创建', '#409EFF', 0, 0, 1, 1, 1);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (180227, 180105, 2, '已提交', '#E6A23C', 0, 0, 0, 0, 2);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (180228, 180105, 3, '已审核', '#67C23A', 0, 0, 0, 0, 3);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (180229, 180105, 4, '已驳回', '#F56C6C', 0, 0, 1, 1, 4);

-- 3.7 INV_LOCK_APPLY (machine_id=180106) —— id=180230-180234
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (180230, 180106, 0, '暂存',   '#909399', 1, 0, 1, 1, 0);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (180231, 180106, 1, '已创建', '#409EFF', 0, 0, 1, 1, 1);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (180232, 180106, 2, '已提交', '#E6A23C', 0, 0, 0, 0, 2);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (180233, 180106, 3, '已审核', '#67C23A', 0, 0, 0, 0, 3);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (180234, 180106, 4, '已驳回', '#F56C6C', 0, 0, 1, 1, 4);


-- ============================================================
-- 4. 状态流转（meta_state_transition）—— 7×17=119 行
--    复制 STD_5STATE 流转（machine_id=100 的 id=200-216），替换 machine_id
--    t1-t11 + t16-t17 无 post_action；t12-t15 含 post_action
--    删除 to_state=-1（物理删除）；关闭/取消/变更/下推 to_state=3（保持原状态）
-- ============================================================

-- 4.1 INV_STOCKTAKE (machine_id=180100) —— id=180300-180316
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180300, 180100, 0,  1, '保存',     'save',     0, 0, 1);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180301, 180100, 0,  0, '暂存',     'draft',    0, 0, 2);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180302, 180100, 1,  2, '提交',     'submit',   1, 0, 3);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180303, 180100, 2,  3, '审核',     'audit',    0, 0, 4);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180304, 180100, 2,  4, '驳回',     'reject',   0, 1, 5);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180305, 180100, 4,  2, '重新提交', 'resubmit', 1, 0, 6);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180306, 180100, 2,  1, '撤销',     'revoke',   0, 0, 7);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180307, 180100, 3,  1, '撤销',     'revoke',   0, 0, 8);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180308, 180100, 0, -1, '删除',     'delete',   0, 0, 9);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180309, 180100, 1, -1, '删除',     'delete',   0, 0, 10);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180310, 180100, 4, -1, '删除',     'delete',   0, 0, 11);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (180311, 180100, 3, 3, '关闭',   'close',  'is_closed=1', 0, 0, 12);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (180312, 180100, 3, 3, '反关闭', 'close',  'is_closed=0', 0, 0, 13);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (180313, 180100, 3, 3, '取消',   'cancel', 'is_cancel=1', 0, 1, 14);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (180314, 180100, 3, 3, '反取消', 'cancel', 'is_cancel=0', 0, 0, 15);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180315, 180100, 3,  3, '变更',     'change',   1, 1, 16);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180316, 180100, 3,  3, '下推',     'push',     0, 0, 17);

-- 4.2 INV_TRANSFER (machine_id=180101) —— id=180317-180333
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180317, 180101, 0,  1, '保存',     'save',     0, 0, 1);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180318, 180101, 0,  0, '暂存',     'draft',    0, 0, 2);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180319, 180101, 1,  2, '提交',     'submit',   1, 0, 3);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180320, 180101, 2,  3, '审核',     'audit',    0, 0, 4);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180321, 180101, 2,  4, '驳回',     'reject',   0, 1, 5);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180322, 180101, 4,  2, '重新提交', 'resubmit', 1, 0, 6);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180323, 180101, 2,  1, '撤销',     'revoke',   0, 0, 7);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180324, 180101, 3,  1, '撤销',     'revoke',   0, 0, 8);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180325, 180101, 0, -1, '删除',     'delete',   0, 0, 9);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180326, 180101, 1, -1, '删除',     'delete',   0, 0, 10);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180327, 180101, 4, -1, '删除',     'delete',   0, 0, 11);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (180328, 180101, 3, 3, '关闭',   'close',  'is_closed=1', 0, 0, 12);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (180329, 180101, 3, 3, '反关闭', 'close',  'is_closed=0', 0, 0, 13);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (180330, 180101, 3, 3, '取消',   'cancel', 'is_cancel=1', 0, 1, 14);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (180331, 180101, 3, 3, '反取消', 'cancel', 'is_cancel=0', 0, 0, 15);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180332, 180101, 3,  3, '变更',     'change',   1, 1, 16);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180333, 180101, 3,  3, '下推',     'push',     0, 0, 17);

-- 4.3 INV_FORM_CONV (machine_id=180102) —— id=180334-180350
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180334, 180102, 0,  1, '保存',     'save',     0, 0, 1);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180335, 180102, 0,  0, '暂存',     'draft',    0, 0, 2);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180336, 180102, 1,  2, '提交',     'submit',   1, 0, 3);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180337, 180102, 2,  3, '审核',     'audit',    0, 0, 4);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180338, 180102, 2,  4, '驳回',     'reject',   0, 1, 5);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180339, 180102, 4,  2, '重新提交', 'resubmit', 1, 0, 6);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180340, 180102, 2,  1, '撤销',     'revoke',   0, 0, 7);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180341, 180102, 3,  1, '撤销',     'revoke',   0, 0, 8);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180342, 180102, 0, -1, '删除',     'delete',   0, 0, 9);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180343, 180102, 1, -1, '删除',     'delete',   0, 0, 10);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180344, 180102, 4, -1, '删除',     'delete',   0, 0, 11);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (180345, 180102, 3, 3, '关闭',   'close',  'is_closed=1', 0, 0, 12);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (180346, 180102, 3, 3, '反关闭', 'close',  'is_closed=0', 0, 0, 13);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (180347, 180102, 3, 3, '取消',   'cancel', 'is_cancel=1', 0, 1, 14);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (180348, 180102, 3, 3, '反取消', 'cancel', 'is_cancel=0', 0, 0, 15);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180349, 180102, 3,  3, '变更',     'change',   1, 1, 16);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180350, 180102, 3,  3, '下推',     'push',     0, 0, 17);

-- 4.4 INV_OTHER_IN (machine_id=180103) —— id=180351-180367
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180351, 180103, 0,  1, '保存',     'save',     0, 0, 1);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180352, 180103, 0,  0, '暂存',     'draft',    0, 0, 2);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180353, 180103, 1,  2, '提交',     'submit',   1, 0, 3);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180354, 180103, 2,  3, '审核',     'audit',    0, 0, 4);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180355, 180103, 2,  4, '驳回',     'reject',   0, 1, 5);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180356, 180103, 4,  2, '重新提交', 'resubmit', 1, 0, 6);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180357, 180103, 2,  1, '撤销',     'revoke',   0, 0, 7);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180358, 180103, 3,  1, '撤销',     'revoke',   0, 0, 8);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180359, 180103, 0, -1, '删除',     'delete',   0, 0, 9);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180360, 180103, 1, -1, '删除',     'delete',   0, 0, 10);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180361, 180103, 4, -1, '删除',     'delete',   0, 0, 11);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (180362, 180103, 3, 3, '关闭',   'close',  'is_closed=1', 0, 0, 12);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (180363, 180103, 3, 3, '反关闭', 'close',  'is_closed=0', 0, 0, 13);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (180364, 180103, 3, 3, '取消',   'cancel', 'is_cancel=1', 0, 1, 14);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (180365, 180103, 3, 3, '反取消', 'cancel', 'is_cancel=0', 0, 0, 15);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180366, 180103, 3,  3, '变更',     'change',   1, 1, 16);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180367, 180103, 3,  3, '下推',     'push',     0, 0, 17);

-- 4.5 INV_OTHER_OUT (machine_id=180104) —— id=180368-180384
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180368, 180104, 0,  1, '保存',     'save',     0, 0, 1);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180369, 180104, 0,  0, '暂存',     'draft',    0, 0, 2);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180370, 180104, 1,  2, '提交',     'submit',   1, 0, 3);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180371, 180104, 2,  3, '审核',     'audit',    0, 0, 4);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180372, 180104, 2,  4, '驳回',     'reject',   0, 1, 5);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180373, 180104, 4,  2, '重新提交', 'resubmit', 1, 0, 6);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180374, 180104, 2,  1, '撤销',     'revoke',   0, 0, 7);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180375, 180104, 3,  1, '撤销',     'revoke',   0, 0, 8);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180376, 180104, 0, -1, '删除',     'delete',   0, 0, 9);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180377, 180104, 1, -1, '删除',     'delete',   0, 0, 10);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180378, 180104, 4, -1, '删除',     'delete',   0, 0, 11);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (180379, 180104, 3, 3, '关闭',   'close',  'is_closed=1', 0, 0, 12);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (180380, 180104, 3, 3, '反关闭', 'close',  'is_closed=0', 0, 0, 13);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (180381, 180104, 3, 3, '取消',   'cancel', 'is_cancel=1', 0, 1, 14);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (180382, 180104, 3, 3, '反取消', 'cancel', 'is_cancel=0', 0, 0, 15);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180383, 180104, 3,  3, '变更',     'change',   1, 1, 16);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180384, 180104, 3,  3, '下推',     'push',     0, 0, 17);

-- 4.6 INV_LOCK (machine_id=180105) —— id=180385-180401
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180385, 180105, 0,  1, '保存',     'save',     0, 0, 1);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180386, 180105, 0,  0, '暂存',     'draft',    0, 0, 2);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180387, 180105, 1,  2, '提交',     'submit',   1, 0, 3);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180388, 180105, 2,  3, '审核',     'audit',    0, 0, 4);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180389, 180105, 2,  4, '驳回',     'reject',   0, 1, 5);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180390, 180105, 4,  2, '重新提交', 'resubmit', 1, 0, 6);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180391, 180105, 2,  1, '撤销',     'revoke',   0, 0, 7);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180392, 180105, 3,  1, '撤销',     'revoke',   0, 0, 8);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180393, 180105, 0, -1, '删除',     'delete',   0, 0, 9);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180394, 180105, 1, -1, '删除',     'delete',   0, 0, 10);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180395, 180105, 4, -1, '删除',     'delete',   0, 0, 11);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (180396, 180105, 3, 3, '关闭',   'close',  'is_closed=1', 0, 0, 12);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (180397, 180105, 3, 3, '反关闭', 'close',  'is_closed=0', 0, 0, 13);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (180398, 180105, 3, 3, '取消',   'cancel', 'is_cancel=1', 0, 1, 14);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (180399, 180105, 3, 3, '反取消', 'cancel', 'is_cancel=0', 0, 0, 15);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180400, 180105, 3,  3, '变更',     'change',   1, 1, 16);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180401, 180105, 3,  3, '下推',     'push',     0, 0, 17);

-- 4.7 INV_LOCK_APPLY (machine_id=180106) —— id=180402-180418
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180402, 180106, 0,  1, '保存',     'save',     0, 0, 1);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180403, 180106, 0,  0, '暂存',     'draft',    0, 0, 2);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180404, 180106, 1,  2, '提交',     'submit',   1, 0, 3);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180405, 180106, 2,  3, '审核',     'audit',    0, 0, 4);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180406, 180106, 2,  4, '驳回',     'reject',   0, 1, 5);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180407, 180106, 4,  2, '重新提交', 'resubmit', 1, 0, 6);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180408, 180106, 2,  1, '撤销',     'revoke',   0, 0, 7);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180409, 180106, 3,  1, '撤销',     'revoke',   0, 0, 8);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180410, 180106, 0, -1, '删除',     'delete',   0, 0, 9);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180411, 180106, 1, -1, '删除',     'delete',   0, 0, 10);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180412, 180106, 4, -1, '删除',     'delete',   0, 0, 11);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (180413, 180106, 3, 3, '关闭',   'close',  'is_closed=1', 0, 0, 12);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (180414, 180106, 3, 3, '反关闭', 'close',  'is_closed=0', 0, 0, 13);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (180415, 180106, 3, 3, '取消',   'cancel', 'is_cancel=1', 0, 1, 14);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (180416, 180106, 3, 3, '反取消', 'cancel', 'is_cancel=0', 0, 0, 15);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180417, 180106, 3,  3, '变更',     'change',   1, 1, 16);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (180418, 180106, 3,  3, '下推',     'push',     0, 0, 17);


-- ============================================================
-- 5. 表单实体层级（meta_form_entity）—— 9 主 + 7 子 = 16 行
--    主表 entity_type='main', entity_level=0；
--    子表 entity_type='sub', entity_level=1, entity_code='goods'
--    特殊：INV_OTHER_IN/INV_OTHER_OUT 共享 inv_other_stock 表，
--          entity_code 分别为 inv_other_in / inv_other_out；
--          子表 link_field='bill_id'（schema 实际列名）
-- ============================================================

-- 5.1 主实体（entity_type='main', entity_level=0）—— 9 行
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (180500, 'INV_STOCK',      'inv_stock',      '即时库存',   'main', 0, 'inv_stock',      NULL, NULL, 1);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (180501, 'INV_BATCH',      'inv_batch',      '批次台账',   'main', 0, 'inv_batch',      NULL, NULL, 1);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (180502, 'INV_STOCKTAKE',  'inv_stocktake',  '盘点单',     'main', 0, 'inv_stocktake',  NULL, NULL, 1);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (180504, 'INV_TRANSFER',   'inv_transfer',   '调拨单',     'main', 0, 'inv_transfer',   NULL, NULL, 1);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (180506, 'INV_FORM_CONV',  'inv_form_conv',  '形态转换',   'main', 0, 'inv_form_conv',  NULL, NULL, 1);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (180508, 'INV_OTHER_IN',   'inv_other_in',   '其他入库',   'main', 0, 'inv_other_stock', NULL, NULL, 1);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (180510, 'INV_OTHER_OUT',  'inv_other_out',  '其他出库',   'main', 0, 'inv_other_stock', NULL, NULL, 1);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (180512, 'INV_LOCK',       'inv_lock',       '锁库单',     'main', 0, 'inv_lock',       NULL, NULL, 1);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (180514, 'INV_LOCK_APPLY', 'inv_lock_apply', '锁库申请',   'main', 0, 'inv_lock_apply', NULL, NULL, 1);

-- 5.2 子实体（entity_type='sub', entity_level=1, entity_code='goods'）—— 7 行
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (180503, 'INV_STOCKTAKE',  'goods', '盘点明细', 'sub', 1, 'inv_stocktake_goods',  'inv_stocktake',  'stocktake_id', 2);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (180505, 'INV_TRANSFER',   'goods', '调拨明细', 'sub', 1, 'inv_transfer_goods',   'inv_transfer',   'transfer_id',  2);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (180507, 'INV_FORM_CONV',  'goods', '转换明细', 'sub', 1, 'inv_form_conv_goods',  'inv_form_conv',  'conv_id',      2);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (180509, 'INV_OTHER_IN',   'goods', '入库明细', 'sub', 1, 'inv_other_stock_goods', 'inv_other_in',  'bill_id',      2);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (180511, 'INV_OTHER_OUT',  'goods', '出库明细', 'sub', 1, 'inv_other_stock_goods', 'inv_other_out', 'bill_id',      2);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (180513, 'INV_LOCK',       'goods', '锁库明细', 'sub', 1, 'inv_lock_goods',        'inv_lock',      'lock_id',      2);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (180515, 'INV_LOCK_APPLY', 'goods', '锁库申请明细', 'sub', 1, 'inv_lock_apply_goods', 'inv_lock_apply', 'lock_apply_id', 2);


-- ============================================================
-- 6. 表单字段元数据（meta_form_field）—— 126 行
--    仅注册关键字段（编码/日期/状态 + 组织/仓库/物料外键 + 数量 + 备注）
--    字段类型：text/number/date/enum/ref/qty/amount
--    ref 字段附带 ref_bo_code；ID 区间 220300-220425
--    注意：field_code 必须与 schema-h2.sql 实际列名一致（allowedColumns 过滤）
-- ============================================================

-- ------------------------------------------------------------
-- 6.1 INV_STOCK 即时库存（主表 inv_stock，无状态机，12 字段）
-- ------------------------------------------------------------
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (220300, 'INV_STOCK', 'inv_stock', 'org_id',         '组织',     'ref',    'ref',      0, 0, 'MD_ORG',       1,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (220301, 'INV_STOCK', 'inv_stock', 'warehouse_id',   '仓库',     'ref',    'ref',      1, 0, 'MD_WAREHOUSE', 2,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220302, 'INV_STOCK', 'inv_stock', 'position_id',    '库位',     'number', 'number',   0, 0, 3,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (220303, 'INV_STOCK', 'inv_stock', 'mat_id',         '物料',     'ref',    'ref',      1, 0, 'MD_MATERIAL',  4,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220304, 'INV_STOCK', 'inv_stock', 'batch_no',       '批号',     'text',   'text',     0, 0, 5,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220305, 'INV_STOCK', 'inv_stock', 'vat_no',         '缸号',     'text',   'text',     0, 0, 6,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220306, 'INV_STOCK', 'inv_stock', 'unit',           '单位',     'text',   'text',     0, 0, 7,  '数量信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220307, 'INV_STOCK', 'inv_stock', 'qty',            '库存数量', 'qty',    'qty',      1, 0, 8,  '数量信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220308, 'INV_STOCK', 'inv_stock', 'lock_qty',       '锁定数量', 'qty',    'qty',      0, 1, 9,  '数量信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220309, 'INV_STOCK', 'inv_stock', 'available_qty',  '可用数量', 'qty',    'qty',      0, 1, 10, '数量信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220310, 'INV_STOCK', 'inv_stock', 'cost_price',     '成本单价', 'amount', 'amount',   0, 0, 11, '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220311, 'INV_STOCK', 'inv_stock', 'cost_amount',    '成本金额', 'amount', 'amount',   0, 1, 12, '金额信息');

-- ------------------------------------------------------------
-- 6.2 INV_BATCH 批次台账（主表 inv_batch，无状态机，9 字段）
-- ------------------------------------------------------------
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (220312, 'INV_BATCH', 'inv_batch', 'mat_id',       '物料',     'ref',    'ref',      1, 0, 'MD_MATERIAL', 1, '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220313, 'INV_BATCH', 'inv_batch', 'batch_no',     '批号',     'text',   'text',     1, 0, 2, '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220314, 'INV_BATCH', 'inv_batch', 'vat_no',       '缸号',     'text',   'text',     0, 0, 3, '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220315, 'INV_BATCH', 'inv_batch', 'in_date',      '入库日期', 'date',   'date',     0, 0, 4, '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220316, 'INV_BATCH', 'inv_batch', 'produce_date', '生产日期', 'date',   'date',     0, 0, 5, '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (220317, 'INV_BATCH', 'inv_batch', 'supplier_id',  '供应商',   'ref',    'ref',      0, 0, 'MD_SUPPLIER', 6, '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220318, 'INV_BATCH', 'inv_batch', 'qty',          '数量',     'qty',    'qty',      1, 0, 7, '数量信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220319, 'INV_BATCH', 'inv_batch', 'status',       '状态',     'text',   'select',   0, 0, 8, '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220320, 'INV_BATCH', 'inv_batch', 'remark',       '备注',     'text',   'textarea', 0, 0, 9, '其他');

-- ------------------------------------------------------------
-- 6.3 INV_STOCKTAKE 盘点单
-- ------------------------------------------------------------
-- 主表 inv_stocktake（8 字段）
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220321, 'INV_STOCKTAKE', 'inv_stocktake', 'code',           '单据编码', 'text',   'text',     1, 0, 1,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220322, 'INV_STOCKTAKE', 'inv_stocktake', 'stocktake_date', '盘点日期', 'date',   'date',     1, 0, 2,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220323, 'INV_STOCKTAKE', 'inv_stocktake', 'pact_state',     '单据状态', 'enum',   'select',   0, 1, 3,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (220324, 'INV_STOCKTAKE', 'inv_stocktake', 'org_id',         '组织',     'ref',    'ref',      0, 0, 'MD_ORG',       4,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (220325, 'INV_STOCKTAKE', 'inv_stocktake', 'warehouse_id',   '仓库',     'ref',    'ref',      1, 0, 'MD_WAREHOUSE', 5,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220326, 'INV_STOCKTAKE', 'inv_stocktake', 'stocktake_type', '盘点类型', 'text',   'select',   0, 0, 6,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220327, 'INV_STOCKTAKE', 'inv_stocktake', 'total_qty',      '总数量',   'qty',    'qty',      0, 1, 7,  '数量信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220328, 'INV_STOCKTAKE', 'inv_stocktake', 'remark',         '备注',     'text',   'textarea', 0, 0, 8,  '其他');
-- 子表 inv_stocktake_goods / goods（7 字段）
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220329, 'INV_STOCKTAKE', 'goods', 'sort_index',    '行号',     'number', 'number',   0, 0, 1, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (220330, 'INV_STOCKTAKE', 'goods', 'stocktake_id',  '盘点单',   'ref',    'ref',      1, 1, 'INV_STOCKTAKE', 2, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (220331, 'INV_STOCKTAKE', 'goods', 'mat_id',        '物料',     'ref',    'ref',      1, 0, 'MD_MATERIAL',  3, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220332, 'INV_STOCKTAKE', 'goods', 'batch_no',      '批号',     'text',   'text',     0, 0, 4, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220333, 'INV_STOCKTAKE', 'goods', 'book_qty',      '账面数量', 'qty',    'qty',      0, 0, 5, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220334, 'INV_STOCKTAKE', 'goods', 'actual_qty',    '实盘数量', 'qty',    'qty',      0, 0, 6, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220335, 'INV_STOCKTAKE', 'goods', 'diff_qty',      '差异数量', 'qty',    'qty',      0, 1, 7, '明细信息');

-- ------------------------------------------------------------
-- 6.4 INV_TRANSFER 调拨单
-- ------------------------------------------------------------
-- 主表 inv_transfer（9 字段）
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220336, 'INV_TRANSFER', 'inv_transfer', 'code',              '单据编码', 'text',   'text',     1, 0, 1,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220337, 'INV_TRANSFER', 'inv_transfer', 'transfer_date',     '调拨日期', 'date',   'date',     1, 0, 2,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220338, 'INV_TRANSFER', 'inv_transfer', 'pact_state',        '单据状态', 'enum',   'select',   0, 1, 3,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (220339, 'INV_TRANSFER', 'inv_transfer', 'from_org_id',       '调出组织', 'ref',    'ref',      0, 0, 'MD_ORG',       4,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (220340, 'INV_TRANSFER', 'inv_transfer', 'from_warehouse_id', '调出仓库', 'ref',    'ref',      1, 0, 'MD_WAREHOUSE', 5,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (220341, 'INV_TRANSFER', 'inv_transfer', 'to_warehouse_id',   '调入仓库', 'ref',    'ref',      1, 0, 'MD_WAREHOUSE', 6,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220342, 'INV_TRANSFER', 'inv_transfer', 'transfer_type',     '调拨类型', 'text',   'select',   0, 0, 7,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220343, 'INV_TRANSFER', 'inv_transfer', 'total_qty',         '总数量',   'qty',    'qty',      0, 1, 8,  '数量信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220344, 'INV_TRANSFER', 'inv_transfer', 'remark',            '备注',     'text',   'textarea', 0, 0, 9,  '其他');
-- 子表 inv_transfer_goods / goods（6 字段）
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220345, 'INV_TRANSFER', 'goods', 'sort_index',  '行号',   'number', 'number',   0, 0, 1, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (220346, 'INV_TRANSFER', 'goods', 'transfer_id', '调拨单', 'ref',    'ref',      1, 1, 'INV_TRANSFER', 2, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (220347, 'INV_TRANSFER', 'goods', 'mat_id',      '物料',   'ref',    'ref',      1, 0, 'MD_MATERIAL',  3, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220348, 'INV_TRANSFER', 'goods', 'batch_no',    '批号',   'text',   'text',     0, 0, 4, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220349, 'INV_TRANSFER', 'goods', 'qty',         '数量',   'qty',    'qty',      1, 0, 5, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220350, 'INV_TRANSFER', 'goods', 'unit',        '单位',   'text',   'text',     0, 0, 6, '明细信息');

-- ------------------------------------------------------------
-- 6.5 INV_FORM_CONV 形态转换
-- ------------------------------------------------------------
-- 主表 inv_form_conv（8 字段）
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220351, 'INV_FORM_CONV', 'inv_form_conv', 'code',        '单据编码', 'text',   'text',     1, 0, 1,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220352, 'INV_FORM_CONV', 'inv_form_conv', 'conv_date',   '转换日期', 'date',   'date',     1, 0, 2,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220353, 'INV_FORM_CONV', 'inv_form_conv', 'pact_state',  '单据状态', 'enum',   'select',   0, 1, 3,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (220354, 'INV_FORM_CONV', 'inv_form_conv', 'org_id',      '组织',     'ref',    'ref',      0, 0, 'MD_ORG',       4,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (220355, 'INV_FORM_CONV', 'inv_form_conv', 'warehouse_id','仓库',     'ref',    'ref',      1, 0, 'MD_WAREHOUSE', 5,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220356, 'INV_FORM_CONV', 'inv_form_conv', 'conv_type',   '转换类型', 'text',   'select',   0, 0, 6,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220357, 'INV_FORM_CONV', 'inv_form_conv', 'total_qty',   '总数量',   'qty',    'qty',      0, 1, 7,  '数量信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220358, 'INV_FORM_CONV', 'inv_form_conv', 'remark',      '备注',     'text',   'textarea', 0, 0, 8,  '其他');
-- 子表 inv_form_conv_goods / goods（7 字段）
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220359, 'INV_FORM_CONV', 'goods', 'sort_index',   '行号',       'number', 'number',   0, 0, 1, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (220360, 'INV_FORM_CONV', 'goods', 'conv_id',      '形态转换',   'ref',    'ref',      1, 1, 'INV_FORM_CONV', 2, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (220361, 'INV_FORM_CONV', 'goods', 'src_mat_id',   '源物料',     'ref',    'ref',      1, 0, 'MD_MATERIAL',  3, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220362, 'INV_FORM_CONV', 'goods', 'src_batch_no', '源批号',     'text',   'text',     0, 0, 4, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220363, 'INV_FORM_CONV', 'goods', 'src_qty',      '源数量',     'qty',    'qty',      1, 0, 5, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (220364, 'INV_FORM_CONV', 'goods', 'tgt_mat_id',   '目标物料',   'ref',    'ref',      0, 0, 'MD_MATERIAL',  6, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220365, 'INV_FORM_CONV', 'goods', 'tgt_qty',      '目标数量',   'qty',    'qty',      0, 1, 7, '明细信息');

-- ------------------------------------------------------------
-- 6.6 INV_OTHER_IN 其他入库（主表 inv_other_stock，entity_code=inv_other_in）
-- ------------------------------------------------------------
-- 主表 inv_other_stock / inv_other_in（8 字段）
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220366, 'INV_OTHER_IN', 'inv_other_in', 'code',           '单据编码', 'text',   'text',     1, 0, 1,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220367, 'INV_OTHER_IN', 'inv_other_in', 'bill_date',      '单据日期', 'date',   'date',     1, 0, 2,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220368, 'INV_OTHER_IN', 'inv_other_in', 'pact_state',     '单据状态', 'enum',   'select',   0, 1, 3,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (220369, 'INV_OTHER_IN', 'inv_other_in', 'org_id',         '组织',     'ref',    'ref',      0, 0, 'MD_ORG',       4,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (220370, 'INV_OTHER_IN', 'inv_other_in', 'warehouse_id',   '仓库',     'ref',    'ref',      1, 0, 'MD_WAREHOUSE', 5,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220371, 'INV_OTHER_IN', 'inv_other_in', 'stock_direction', '出入方向', 'text',   'select',   0, 1, 6,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220372, 'INV_OTHER_IN', 'inv_other_in', 'total_qty',      '总数量',   'qty',    'qty',      0, 1, 7,  '数量信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220373, 'INV_OTHER_IN', 'inv_other_in', 'remark',         '备注',     'text',   'textarea', 0, 0, 8,  '其他');
-- 子表 inv_other_stock_goods / goods（7 字段，link_field=bill_id）
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220374, 'INV_OTHER_IN', 'goods', 'sort_index', '行号',     'number', 'number',   0, 0, 1, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (220375, 'INV_OTHER_IN', 'goods', 'bill_id',    '出入库单', 'ref',    'ref',      1, 1, 'INV_OTHER_IN', 2, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (220376, 'INV_OTHER_IN', 'goods', 'mat_id',     '物料',     'ref',    'ref',      1, 0, 'MD_MATERIAL',  3, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220377, 'INV_OTHER_IN', 'goods', 'batch_no',   '批号',     'text',   'text',     0, 0, 4, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220378, 'INV_OTHER_IN', 'goods', 'qty',        '数量',     'qty',    'qty',      1, 0, 5, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220379, 'INV_OTHER_IN', 'goods', 'unit',       '单位',     'text',   'text',     0, 0, 6, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220380, 'INV_OTHER_IN', 'goods', 'cost_price', '成本单价', 'amount', 'amount',   0, 0, 7, '明细信息');

-- ------------------------------------------------------------
-- 6.7 INV_OTHER_OUT 其他出库（主表 inv_other_stock，entity_code=inv_other_out）
-- ------------------------------------------------------------
-- 主表 inv_other_stock / inv_other_out（8 字段）
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220381, 'INV_OTHER_OUT', 'inv_other_out', 'code',           '单据编码', 'text',   'text',     1, 0, 1,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220382, 'INV_OTHER_OUT', 'inv_other_out', 'bill_date',      '单据日期', 'date',   'date',     1, 0, 2,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220383, 'INV_OTHER_OUT', 'inv_other_out', 'pact_state',     '单据状态', 'enum',   'select',   0, 1, 3,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (220384, 'INV_OTHER_OUT', 'inv_other_out', 'org_id',         '组织',     'ref',    'ref',      0, 0, 'MD_ORG',       4,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (220385, 'INV_OTHER_OUT', 'inv_other_out', 'warehouse_id',   '仓库',     'ref',    'ref',      1, 0, 'MD_WAREHOUSE', 5,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220386, 'INV_OTHER_OUT', 'inv_other_out', 'stock_direction', '出入方向', 'text',   'select',   0, 1, 6,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220387, 'INV_OTHER_OUT', 'inv_other_out', 'total_qty',      '总数量',   'qty',    'qty',      0, 1, 7,  '数量信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220388, 'INV_OTHER_OUT', 'inv_other_out', 'remark',         '备注',     'text',   'textarea', 0, 0, 8,  '其他');
-- 子表 inv_other_stock_goods / goods（7 字段，link_field=bill_id）
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220389, 'INV_OTHER_OUT', 'goods', 'sort_index', '行号',     'number', 'number',   0, 0, 1, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (220390, 'INV_OTHER_OUT', 'goods', 'bill_id',    '出入库单', 'ref',    'ref',      1, 1, 'INV_OTHER_OUT', 2, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (220391, 'INV_OTHER_OUT', 'goods', 'mat_id',     '物料',     'ref',    'ref',      1, 0, 'MD_MATERIAL',  3, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220392, 'INV_OTHER_OUT', 'goods', 'batch_no',   '批号',     'text',   'text',     0, 0, 4, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220393, 'INV_OTHER_OUT', 'goods', 'qty',        '数量',     'qty',    'qty',      1, 0, 5, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220394, 'INV_OTHER_OUT', 'goods', 'unit',       '单位',     'text',   'text',     0, 0, 6, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220395, 'INV_OTHER_OUT', 'goods', 'cost_price', '成本单价', 'amount', 'amount',   0, 0, 7, '明细信息');

-- ------------------------------------------------------------
-- 6.8 INV_LOCK 锁库单
-- ------------------------------------------------------------
-- 主表 inv_lock（9 字段）
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220396, 'INV_LOCK', 'inv_lock', 'code',           '单据编码', 'text',   'text',     1, 0, 1,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220397, 'INV_LOCK', 'inv_lock', 'pact_date',      '单据日期', 'date',   'date',     1, 0, 2,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220398, 'INV_LOCK', 'inv_lock', 'pact_state',     '单据状态', 'enum',   'select',   0, 1, 3,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (220399, 'INV_LOCK', 'inv_lock', 'org_id',         '组织',     'ref',    'ref',      0, 0, 'MD_ORG',       4,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (220400, 'INV_LOCK', 'inv_lock', 'warehouse_id',   '仓库',     'ref',    'ref',      1, 0, 'MD_WAREHOUSE', 5,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (220401, 'INV_LOCK', 'inv_lock', 'cust_id',        '客户',     'ref',    'ref',      0, 0, 'MD_CUSTOMER',  6,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (220402, 'INV_LOCK', 'inv_lock', 'mat_id',         '物料',     'ref',    'ref',      0, 0, 'MD_MATERIAL',  7,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220403, 'INV_LOCK', 'inv_lock', 'total_lock_qty', '总锁定数', 'qty',    'qty',      0, 1, 8,  '数量信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220404, 'INV_LOCK', 'inv_lock', 'remark',         '备注',     'text',   'textarea', 0, 0, 9,  '其他');
-- 子表 inv_lock_goods / goods（6 字段，link_field=lock_id）
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220405, 'INV_LOCK', 'goods', 'sort_index', '行号',     'number', 'number',   0, 0, 1, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (220406, 'INV_LOCK', 'goods', 'lock_id',    '锁库单',   'ref',    'ref',      1, 1, 'INV_LOCK',     2, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (220407, 'INV_LOCK', 'goods', 'mat_id',     '物料',     'ref',    'ref',      1, 0, 'MD_MATERIAL',  3, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220408, 'INV_LOCK', 'goods', 'lot_no',     '批号',     'text',   'text',     0, 0, 4, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220409, 'INV_LOCK', 'goods', 'lock_qty',   '锁定数量', 'qty',    'qty',      1, 0, 5, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220410, 'INV_LOCK', 'goods', 'unit',       '单位',     'text',   'text',     0, 0, 6, '明细信息');

-- ------------------------------------------------------------
-- 6.9 INV_LOCK_APPLY 锁库申请单
-- ------------------------------------------------------------
-- 主表 inv_lock_apply（9 字段）
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220411, 'INV_LOCK_APPLY', 'inv_lock_apply', 'code',       '单据编码', 'text',   'text',     1, 0, 1,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220412, 'INV_LOCK_APPLY', 'inv_lock_apply', 'pact_date',  '单据日期', 'date',   'date',     1, 0, 2,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220413, 'INV_LOCK_APPLY', 'inv_lock_apply', 'pact_state', '单据状态', 'enum',   'select',   0, 1, 3,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (220414, 'INV_LOCK_APPLY', 'inv_lock_apply', 'org_id',     '组织',     'ref',    'ref',      0, 0, 'MD_ORG',       4,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (220415, 'INV_LOCK_APPLY', 'inv_lock_apply', 'saler_id',   '销售员',   'ref',    'ref',      0, 0, 'MD_EMPLOYEE',  5,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (220416, 'INV_LOCK_APPLY', 'inv_lock_apply', 'dept_id',    '部门',     'ref',    'ref',      0, 0, 'MD_DEPT',      6,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (220417, 'INV_LOCK_APPLY', 'inv_lock_apply', 'cust_id',    '客户',     'ref',    'ref',      0, 0, 'MD_CUSTOMER',  7,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220418, 'INV_LOCK_APPLY', 'inv_lock_apply', 'pact_type',  '协议类型', 'text',   'select',   0, 0, 8,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220419, 'INV_LOCK_APPLY', 'inv_lock_apply', 'remark',     '备注',     'text',   'textarea', 0, 0, 9,  '其他');
-- 子表 inv_lock_apply_goods / goods（6 字段，link_field=lock_apply_id）
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220420, 'INV_LOCK_APPLY', 'goods', 'sort_index',     '行号',     'number', 'number',   0, 0, 1, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (220421, 'INV_LOCK_APPLY', 'goods', 'lock_apply_id',  '锁库申请', 'ref',    'ref',      1, 1, 'INV_LOCK_APPLY', 2, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (220422, 'INV_LOCK_APPLY', 'goods', 'mat_id',         '物料',     'ref',    'ref',      1, 0, 'MD_MATERIAL',  3, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220423, 'INV_LOCK_APPLY', 'goods', 'qty',            '数量',     'qty',    'qty',      1, 0, 4, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220424, 'INV_LOCK_APPLY', 'goods', 'lock_qty',       '锁定数量', 'qty',    'qty',      0, 0, 5, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (220425, 'INV_LOCK_APPLY', 'goods', 'unit',           '单位',     'text',   'text',     0, 0, 6, '明细信息');


-- ============================================================
-- 文件末尾说明
-- ============================================================
-- ID 范围汇总：
--   meta_business_object  180001-180009   (9 行：2 无状态机 + 7 有状态机)
--   meta_state_machine    180100-180106   (7 行，code=bo_code，state_field=pact_state)
--   meta_state_node       180200-180234   (35 行，每状态机 5 节点，复制 STD_5STATE)
--   meta_state_transition 180300-180418   (119 行，每状态机 17 流转，t12-t15 含 post_action)
--   meta_form_entity      180500-180515   (16 行：9 主 + 7 子)
--   meta_form_field       220300-220425   (126 行关键字段)
-- 依赖关系：
--   1. schema-h2.sql 提供元数据表结构 + inv_ 业务表（inv_stock/inv_batch/
--      inv_stocktake(_goods)/inv_transfer(_goods)/inv_form_conv(_goods)/
--      inv_other_stock(_goods)/inv_lock(_goods)/inv_lock_apply(_goods)）。
--   2. data-h2-seed.sql 提供 STD_5STATE（machine_id=100）及测试主数据。
--   3. data-h2-master-seed.sql 提供 30 个主数据 bo_code（MD_ORG/MD_WAREHOUSE/
--      MD_MATERIAL/MD_SUPPLIER/MD_DEPT/MD_EMPLOYEE/MD_CUSTOMER 等）。
--   4. INV_OTHER_IN/INV_OTHER_OUT 共享 inv_other_stock/inv_other_stock_goods，
--      通过 entity_code（inv_other_in/inv_other_out）区分，子表 link_field=bill_id。
--   5. INV_STOCK/INV_BATCH 为台账（is_stateful=0），无状态机，save 即落库。
-- 加载顺序：schema-h2.sql → data-h2-seed.sql → data-h2-master-seed.sql
--          → data-h2-scm-seed.sql → data-h2-sal-seed.sql → 本文件。
-- ============================================================
