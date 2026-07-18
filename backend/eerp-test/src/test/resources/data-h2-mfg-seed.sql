-- ============================================================
-- EERP H2 MFG (生产制造) 元数据种子
-- ============================================================
-- 用途：集成测试 H2 内存数据库生产制造模块元数据种子（Phase 2e-2g）。
--       为 8 个生产制造业务单据 bo_code 注册业务对象、独立状态机
--       （5 节点 / 17 流转，复制 STD_5STATE 模型）、表单实体层级
--       （主/子/孙）与关键字段元数据，驱动 GenericBillService →
--       GenericOperationService 的 6 阶段流水线，无需具体 Entity/Mapper。
-- 加载：spring.sql.init.data-locations 追加本文件，或测试用 @Sql 注解加载。
-- 幂等：全部使用 MERGE INTO ... KEY(id) VALUES (...)，可重复执行。
-- ID 约定（与 data-h2-master-seed.sql / data-h2-scm-seed.sql / data-h2-sal-seed.sql 不冲突）：
--   meta_business_object  190001-190008   (8 行)
--   meta_state_machine    190100-190107   (8 行，每 bo_code 一台，code=bo_code)
--   meta_state_node       190200-190239   (8×5=40 行)
--   meta_state_transition 190300-190435   (8×17=136 行)
--   meta_form_entity      190500-190516   (8 主 + 8 子 + 1 孙 = 17 行)
--   meta_form_field       230300-230457   (158 行)
-- 生产单据约定：bo_type='business', is_stateful=1, is_pushable=1,
--             is_printable=1, pk_strategy='snowflake', main_key='id', status=1
-- 状态机复制：每 bo_code 复制 STD_5STATE（machine_id=100）的 5 节点
--             （id=101-105）与 17 流转（id=200-216），替换 machine_id。
--             t12-t15 含 post_action（is_closed/is_cancel 标记）。
-- 兼容：H2 MODE=MySQL；时间戳使用 CURRENT_TIMESTAMP；布尔值统一用 1/0。
-- 依赖：schema-h2.sql（元数据表结构）；data-h2-seed.sql（STD_5STATE 及主数据）；
--       data-h2-master-seed.sql（30 个主数据 bo_code，外键 ref_bo_code 引用）；
--       data-h2-sal-seed.sql（SAL_ORDER 销售订单，MFG_ORDER.sal_order_id 引用）。
-- ============================================================


-- ============================================================
-- 1. 业务对象定义（meta_business_object）—— 8 个生产制造业务 BO
-- ============================================================

MERGE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
KEY(id) VALUES (190001, 'MFG_BOM',       'BOM配方',   'business', 'mfg_bom',       'id', 'snowflake', 1, 1, 1, NULL, 1, 'BOM与配方管理业务单据', 'system', CURRENT_TIMESTAMP);
MERGE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
KEY(id) VALUES (190002, 'MFG_ROUTE',     '工艺路线',  'business', 'mfg_route',     'id', 'snowflake', 1, 1, 1, NULL, 1, '工艺路线管理业务单据', 'system', CURRENT_TIMESTAMP);
MERGE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
KEY(id) VALUES (190003, 'MFG_NOTICE',    '生产通知单', 'business', 'mfg_notice',    'id', 'snowflake', 1, 1, 1, NULL, 1, '生产通知单业务单据',   'system', CURRENT_TIMESTAMP);
MERGE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
KEY(id) VALUES (190004, 'MFG_ORDER',     '生产订单',   'business', 'mfg_order',     'id', 'snowflake', 1, 1, 1, NULL, 1, '生产订单业务单据',     'system', CURRENT_TIMESTAMP);
MERGE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
KEY(id) VALUES (190005, 'MFG_PICK',      '领料单',     'business', 'mfg_pick',      'id', 'snowflake', 1, 1, 1, NULL, 1, '生产领料单业务单据',   'system', CURRENT_TIMESTAMP);
MERGE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
KEY(id) VALUES (190006, 'MFG_IN_STOCK',  '生产入库',   'business', 'mfg_in_stock',  'id', 'snowflake', 1, 1, 1, NULL, 1, '生产入库业务单据',     'system', CURRENT_TIMESTAMP);
MERGE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
KEY(id) VALUES (190007, 'MFG_MRP_PLAN',  'MRP计划',    'business', 'mfg_mrp_plan',  'id', 'snowflake', 1, 1, 1, NULL, 1, 'MRP物料需求计划业务单据', 'system', CURRENT_TIMESTAMP);
MERGE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
KEY(id) VALUES (190008, 'MFG_OUTSOURCE', '外协订单',   'business', 'mfg_outsource', 'id', 'snowflake', 1, 1, 1, NULL, 1, '外协加工订单业务单据', 'system', CURRENT_TIMESTAMP);


-- ============================================================
-- 2. 状态机定义（meta_state_machine）—— 8 行，code=bo_code
--    StateMachineCache.load(boCode) 通过 code=bo_code 查询
-- ============================================================

MERGE INTO meta_state_machine (id, code, name, state_field, remark)
KEY(id) VALUES (190100, 'MFG_BOM',       'BOM配方状态机',   'pact_state', '复制 STD_5STATE：0暂存/1已创建/2已提交/3已审核/4已驳回；is_closed/is_cancel 辅助标记');
MERGE INTO meta_state_machine (id, code, name, state_field, remark)
KEY(id) VALUES (190101, 'MFG_ROUTE',     '工艺路线状态机',  'pact_state', '复制 STD_5STATE：0暂存/1已创建/2已提交/3已审核/4已驳回；is_closed/is_cancel 辅助标记');
MERGE INTO meta_state_machine (id, code, name, state_field, remark)
KEY(id) VALUES (190102, 'MFG_NOTICE',    '生产通知单状态机', 'pact_state', '复制 STD_5STATE：0暂存/1已创建/2已提交/3已审核/4已驳回；is_closed/is_cancel 辅助标记');
MERGE INTO meta_state_machine (id, code, name, state_field, remark)
KEY(id) VALUES (190103, 'MFG_ORDER',     '生产订单状态机',   'pact_state', '复制 STD_5STATE：0暂存/1已创建/2已提交/3已审核/4已驳回；is_closed/is_cancel 辅助标记');
MERGE INTO meta_state_machine (id, code, name, state_field, remark)
KEY(id) VALUES (190104, 'MFG_PICK',      '领料单状态机',     'pact_state', '复制 STD_5STATE：0暂存/1已创建/2已提交/3已审核/4已驳回；is_closed/is_cancel 辅助标记');
MERGE INTO meta_state_machine (id, code, name, state_field, remark)
KEY(id) VALUES (190105, 'MFG_IN_STOCK',  '生产入库状态机',   'pact_state', '复制 STD_5STATE：0暂存/1已创建/2已提交/3已审核/4已驳回；is_closed/is_cancel 辅助标记');
MERGE INTO meta_state_machine (id, code, name, state_field, remark)
KEY(id) VALUES (190106, 'MFG_MRP_PLAN',  'MRP计划状态机',    'pact_state', '复制 STD_5STATE：0暂存/1已创建/2已提交/3已审核/4已驳回；is_closed/is_cancel 辅助标记');
MERGE INTO meta_state_machine (id, code, name, state_field, remark)
KEY(id) VALUES (190107, 'MFG_OUTSOURCE', '外协订单状态机',   'pact_state', '复制 STD_5STATE：0暂存/1已创建/2已提交/3已审核/4已驳回；is_closed/is_cancel 辅助标记');


-- ============================================================
-- 3. 状态节点（meta_state_node）—— 8×5=40 行
--    复制 STD_5STATE 节点（machine_id=100 的 id=101-105），替换 machine_id
--    0暂存(初始) 1已创建 2已提交 3已审核 4已驳回
-- ============================================================

-- 3.1 MFG_BOM (machine_id=190100) —— id=190200-190204
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (190200, 190100, 0, '暂存',   '#909399', 1, 0, 1, 1, 0);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (190201, 190100, 1, '已创建', '#409EFF', 0, 0, 1, 1, 1);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (190202, 190100, 2, '已提交', '#E6A23C', 0, 0, 0, 0, 2);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (190203, 190100, 3, '已审核', '#67C23A', 0, 0, 0, 0, 3);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (190204, 190100, 4, '已驳回', '#F56C6C', 0, 0, 1, 1, 4);

-- 3.2 MFG_ROUTE (machine_id=190101) —— id=190205-190209
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (190205, 190101, 0, '暂存',   '#909399', 1, 0, 1, 1, 0);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (190206, 190101, 1, '已创建', '#409EFF', 0, 0, 1, 1, 1);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (190207, 190101, 2, '已提交', '#E6A23C', 0, 0, 0, 0, 2);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (190208, 190101, 3, '已审核', '#67C23A', 0, 0, 0, 0, 3);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (190209, 190101, 4, '已驳回', '#F56C6C', 0, 0, 1, 1, 4);

-- 3.3 MFG_NOTICE (machine_id=190102) —— id=190210-190214
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (190210, 190102, 0, '暂存',   '#909399', 1, 0, 1, 1, 0);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (190211, 190102, 1, '已创建', '#409EFF', 0, 0, 1, 1, 1);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (190212, 190102, 2, '已提交', '#E6A23C', 0, 0, 0, 0, 2);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (190213, 190102, 3, '已审核', '#67C23A', 0, 0, 0, 0, 3);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (190214, 190102, 4, '已驳回', '#F56C6C', 0, 0, 1, 1, 4);

-- 3.4 MFG_ORDER (machine_id=190103) —— id=190215-190219
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (190215, 190103, 0, '暂存',   '#909399', 1, 0, 1, 1, 0);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (190216, 190103, 1, '已创建', '#409EFF', 0, 0, 1, 1, 1);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (190217, 190103, 2, '已提交', '#E6A23C', 0, 0, 0, 0, 2);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (190218, 190103, 3, '已审核', '#67C23A', 0, 0, 0, 0, 3);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (190219, 190103, 4, '已驳回', '#F56C6C', 0, 0, 1, 1, 4);

-- 3.5 MFG_PICK (machine_id=190104) —— id=190220-190224
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (190220, 190104, 0, '暂存',   '#909399', 1, 0, 1, 1, 0);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (190221, 190104, 1, '已创建', '#409EFF', 0, 0, 1, 1, 1);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (190222, 190104, 2, '已提交', '#E6A23C', 0, 0, 0, 0, 2);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (190223, 190104, 3, '已审核', '#67C23A', 0, 0, 0, 0, 3);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (190224, 190104, 4, '已驳回', '#F56C6C', 0, 0, 1, 1, 4);

-- 3.6 MFG_IN_STOCK (machine_id=190105) —— id=190225-190229
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (190225, 190105, 0, '暂存',   '#909399', 1, 0, 1, 1, 0);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (190226, 190105, 1, '已创建', '#409EFF', 0, 0, 1, 1, 1);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (190227, 190105, 2, '已提交', '#E6A23C', 0, 0, 0, 0, 2);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (190228, 190105, 3, '已审核', '#67C23A', 0, 0, 0, 0, 3);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (190229, 190105, 4, '已驳回', '#F56C6C', 0, 0, 1, 1, 4);

-- 3.7 MFG_MRP_PLAN (machine_id=190106) —— id=190230-190234
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (190230, 190106, 0, '暂存',   '#909399', 1, 0, 1, 1, 0);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (190231, 190106, 1, '已创建', '#409EFF', 0, 0, 1, 1, 1);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (190232, 190106, 2, '已提交', '#E6A23C', 0, 0, 0, 0, 2);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (190233, 190106, 3, '已审核', '#67C23A', 0, 0, 0, 0, 3);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (190234, 190106, 4, '已驳回', '#F56C6C', 0, 0, 1, 1, 4);

-- 3.8 MFG_OUTSOURCE (machine_id=190107) —— id=190235-190239
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (190235, 190107, 0, '暂存',   '#909399', 1, 0, 1, 1, 0);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (190236, 190107, 1, '已创建', '#409EFF', 0, 0, 1, 1, 1);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (190237, 190107, 2, '已提交', '#E6A23C', 0, 0, 0, 0, 2);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (190238, 190107, 3, '已审核', '#67C23A', 0, 0, 0, 0, 3);
MERGE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) KEY(id) VALUES (190239, 190107, 4, '已驳回', '#F56C6C', 0, 0, 1, 1, 4);


-- ============================================================
-- 4. 状态流转（meta_state_transition）—— 8×17=136 行
--    复制 STD_5STATE 流转（machine_id=100 的 id=200-216），替换 machine_id
--    t1-t11 + t16-t17 无 post_action；t12-t15 含 post_action
--    删除 to_state=-1（物理删除）；关闭/取消/变更/下推 to_state=3（保持原状态）
-- ============================================================

-- 4.1 MFG_BOM (machine_id=190100) —— id=190300-190316
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190300, 190100, 0,  1, '保存',     'save',     0, 0, 1);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190301, 190100, 0,  0, '暂存',     'draft',    0, 0, 2);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190302, 190100, 1,  2, '提交',     'submit',   1, 0, 3);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190303, 190100, 2,  3, '审核',     'audit',    0, 0, 4);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190304, 190100, 2,  4, '驳回',     'reject',   0, 1, 5);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190305, 190100, 4,  2, '重新提交', 'resubmit', 1, 0, 6);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190306, 190100, 2,  1, '撤销',     'revoke',   0, 0, 7);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190307, 190100, 3,  1, '撤销',     'revoke',   0, 0, 8);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190308, 190100, 0, -1, '删除',     'delete',   0, 0, 9);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190309, 190100, 1, -1, '删除',     'delete',   0, 0, 10);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190310, 190100, 4, -1, '删除',     'delete',   0, 0, 11);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (190311, 190100, 3, 3, '关闭',   'close',  'is_closed=1', 0, 0, 12);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (190312, 190100, 3, 3, '反关闭', 'close',  'is_closed=0', 0, 0, 13);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (190313, 190100, 3, 3, '取消',   'cancel', 'is_cancel=1', 0, 1, 14);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (190314, 190100, 3, 3, '反取消', 'cancel', 'is_cancel=0', 0, 0, 15);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190315, 190100, 3,  3, '变更',     'change',   1, 1, 16);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190316, 190100, 3,  3, '下推',     'push',     0, 0, 17);

-- 4.2 MFG_ROUTE (machine_id=190101) —— id=190317-190333
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190317, 190101, 0,  1, '保存',     'save',     0, 0, 1);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190318, 190101, 0,  0, '暂存',     'draft',    0, 0, 2);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190319, 190101, 1,  2, '提交',     'submit',   1, 0, 3);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190320, 190101, 2,  3, '审核',     'audit',    0, 0, 4);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190321, 190101, 2,  4, '驳回',     'reject',   0, 1, 5);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190322, 190101, 4,  2, '重新提交', 'resubmit', 1, 0, 6);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190323, 190101, 2,  1, '撤销',     'revoke',   0, 0, 7);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190324, 190101, 3,  1, '撤销',     'revoke',   0, 0, 8);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190325, 190101, 0, -1, '删除',     'delete',   0, 0, 9);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190326, 190101, 1, -1, '删除',     'delete',   0, 0, 10);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190327, 190101, 4, -1, '删除',     'delete',   0, 0, 11);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (190328, 190101, 3, 3, '关闭',   'close',  'is_closed=1', 0, 0, 12);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (190329, 190101, 3, 3, '反关闭', 'close',  'is_closed=0', 0, 0, 13);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (190330, 190101, 3, 3, '取消',   'cancel', 'is_cancel=1', 0, 1, 14);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (190331, 190101, 3, 3, '反取消', 'cancel', 'is_cancel=0', 0, 0, 15);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190332, 190101, 3,  3, '变更',     'change',   1, 1, 16);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190333, 190101, 3,  3, '下推',     'push',     0, 0, 17);

-- 4.3 MFG_NOTICE (machine_id=190102) —— id=190334-190350
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190334, 190102, 0,  1, '保存',     'save',     0, 0, 1);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190335, 190102, 0,  0, '暂存',     'draft',    0, 0, 2);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190336, 190102, 1,  2, '提交',     'submit',   1, 0, 3);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190337, 190102, 2,  3, '审核',     'audit',    0, 0, 4);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190338, 190102, 2,  4, '驳回',     'reject',   0, 1, 5);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190339, 190102, 4,  2, '重新提交', 'resubmit', 1, 0, 6);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190340, 190102, 2,  1, '撤销',     'revoke',   0, 0, 7);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190341, 190102, 3,  1, '撤销',     'revoke',   0, 0, 8);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190342, 190102, 0, -1, '删除',     'delete',   0, 0, 9);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190343, 190102, 1, -1, '删除',     'delete',   0, 0, 10);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190344, 190102, 4, -1, '删除',     'delete',   0, 0, 11);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (190345, 190102, 3, 3, '关闭',   'close',  'is_closed=1', 0, 0, 12);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (190346, 190102, 3, 3, '反关闭', 'close',  'is_closed=0', 0, 0, 13);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (190347, 190102, 3, 3, '取消',   'cancel', 'is_cancel=1', 0, 1, 14);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (190348, 190102, 3, 3, '反取消', 'cancel', 'is_cancel=0', 0, 0, 15);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190349, 190102, 3,  3, '变更',     'change',   1, 1, 16);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190350, 190102, 3,  3, '下推',     'push',     0, 0, 17);

-- 4.4 MFG_ORDER (machine_id=190103) —— id=190351-190367
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190351, 190103, 0,  1, '保存',     'save',     0, 0, 1);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190352, 190103, 0,  0, '暂存',     'draft',    0, 0, 2);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190353, 190103, 1,  2, '提交',     'submit',   1, 0, 3);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190354, 190103, 2,  3, '审核',     'audit',    0, 0, 4);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190355, 190103, 2,  4, '驳回',     'reject',   0, 1, 5);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190356, 190103, 4,  2, '重新提交', 'resubmit', 1, 0, 6);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190357, 190103, 2,  1, '撤销',     'revoke',   0, 0, 7);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190358, 190103, 3,  1, '撤销',     'revoke',   0, 0, 8);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190359, 190103, 0, -1, '删除',     'delete',   0, 0, 9);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190360, 190103, 1, -1, '删除',     'delete',   0, 0, 10);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190361, 190103, 4, -1, '删除',     'delete',   0, 0, 11);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (190362, 190103, 3, 3, '关闭',   'close',  'is_closed=1', 0, 0, 12);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (190363, 190103, 3, 3, '反关闭', 'close',  'is_closed=0', 0, 0, 13);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (190364, 190103, 3, 3, '取消',   'cancel', 'is_cancel=1', 0, 1, 14);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (190365, 190103, 3, 3, '反取消', 'cancel', 'is_cancel=0', 0, 0, 15);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190366, 190103, 3,  3, '变更',     'change',   1, 1, 16);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190367, 190103, 3,  3, '下推',     'push',     0, 0, 17);

-- 4.5 MFG_PICK (machine_id=190104) —— id=190368-190384
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190368, 190104, 0,  1, '保存',     'save',     0, 0, 1);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190369, 190104, 0,  0, '暂存',     'draft',    0, 0, 2);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190370, 190104, 1,  2, '提交',     'submit',   1, 0, 3);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190371, 190104, 2,  3, '审核',     'audit',    0, 0, 4);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190372, 190104, 2,  4, '驳回',     'reject',   0, 1, 5);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190373, 190104, 4,  2, '重新提交', 'resubmit', 1, 0, 6);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190374, 190104, 2,  1, '撤销',     'revoke',   0, 0, 7);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190375, 190104, 3,  1, '撤销',     'revoke',   0, 0, 8);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190376, 190104, 0, -1, '删除',     'delete',   0, 0, 9);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190377, 190104, 1, -1, '删除',     'delete',   0, 0, 10);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190378, 190104, 4, -1, '删除',     'delete',   0, 0, 11);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (190379, 190104, 3, 3, '关闭',   'close',  'is_closed=1', 0, 0, 12);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (190380, 190104, 3, 3, '反关闭', 'close',  'is_closed=0', 0, 0, 13);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (190381, 190104, 3, 3, '取消',   'cancel', 'is_cancel=1', 0, 1, 14);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (190382, 190104, 3, 3, '反取消', 'cancel', 'is_cancel=0', 0, 0, 15);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190383, 190104, 3,  3, '变更',     'change',   1, 1, 16);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190384, 190104, 3,  3, '下推',     'push',     0, 0, 17);

-- 4.6 MFG_IN_STOCK (machine_id=190105) —— id=190385-190401
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190385, 190105, 0,  1, '保存',     'save',     0, 0, 1);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190386, 190105, 0,  0, '暂存',     'draft',    0, 0, 2);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190387, 190105, 1,  2, '提交',     'submit',   1, 0, 3);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190388, 190105, 2,  3, '审核',     'audit',    0, 0, 4);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190389, 190105, 2,  4, '驳回',     'reject',   0, 1, 5);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190390, 190105, 4,  2, '重新提交', 'resubmit', 1, 0, 6);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190391, 190105, 2,  1, '撤销',     'revoke',   0, 0, 7);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190392, 190105, 3,  1, '撤销',     'revoke',   0, 0, 8);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190393, 190105, 0, -1, '删除',     'delete',   0, 0, 9);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190394, 190105, 1, -1, '删除',     'delete',   0, 0, 10);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190395, 190105, 4, -1, '删除',     'delete',   0, 0, 11);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (190396, 190105, 3, 3, '关闭',   'close',  'is_closed=1', 0, 0, 12);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (190397, 190105, 3, 3, '反关闭', 'close',  'is_closed=0', 0, 0, 13);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (190398, 190105, 3, 3, '取消',   'cancel', 'is_cancel=1', 0, 1, 14);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (190399, 190105, 3, 3, '反取消', 'cancel', 'is_cancel=0', 0, 0, 15);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190400, 190105, 3,  3, '变更',     'change',   1, 1, 16);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190401, 190105, 3,  3, '下推',     'push',     0, 0, 17);

-- 4.7 MFG_MRP_PLAN (machine_id=190106) —— id=190402-190418
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190402, 190106, 0,  1, '保存',     'save',     0, 0, 1);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190403, 190106, 0,  0, '暂存',     'draft',    0, 0, 2);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190404, 190106, 1,  2, '提交',     'submit',   1, 0, 3);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190405, 190106, 2,  3, '审核',     'audit',    0, 0, 4);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190406, 190106, 2,  4, '驳回',     'reject',   0, 1, 5);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190407, 190106, 4,  2, '重新提交', 'resubmit', 1, 0, 6);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190408, 190106, 2,  1, '撤销',     'revoke',   0, 0, 7);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190409, 190106, 3,  1, '撤销',     'revoke',   0, 0, 8);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190410, 190106, 0, -1, '删除',     'delete',   0, 0, 9);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190411, 190106, 1, -1, '删除',     'delete',   0, 0, 10);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190412, 190106, 4, -1, '删除',     'delete',   0, 0, 11);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (190413, 190106, 3, 3, '关闭',   'close',  'is_closed=1', 0, 0, 12);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (190414, 190106, 3, 3, '反关闭', 'close',  'is_closed=0', 0, 0, 13);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (190415, 190106, 3, 3, '取消',   'cancel', 'is_cancel=1', 0, 1, 14);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (190416, 190106, 3, 3, '反取消', 'cancel', 'is_cancel=0', 0, 0, 15);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190417, 190106, 3,  3, '变更',     'change',   1, 1, 16);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190418, 190106, 3,  3, '下推',     'push',     0, 0, 17);

-- 4.8 MFG_OUTSOURCE (machine_id=190107) —— id=190419-190435
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190419, 190107, 0,  1, '保存',     'save',     0, 0, 1);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190420, 190107, 0,  0, '暂存',     'draft',    0, 0, 2);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190421, 190107, 1,  2, '提交',     'submit',   1, 0, 3);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190422, 190107, 2,  3, '审核',     'audit',    0, 0, 4);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190423, 190107, 2,  4, '驳回',     'reject',   0, 1, 5);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190424, 190107, 4,  2, '重新提交', 'resubmit', 1, 0, 6);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190425, 190107, 2,  1, '撤销',     'revoke',   0, 0, 7);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190426, 190107, 3,  1, '撤销',     'revoke',   0, 0, 8);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190427, 190107, 0, -1, '删除',     'delete',   0, 0, 9);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190428, 190107, 1, -1, '删除',     'delete',   0, 0, 10);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190429, 190107, 4, -1, '删除',     'delete',   0, 0, 11);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (190430, 190107, 3, 3, '关闭',   'close',  'is_closed=1', 0, 0, 12);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (190431, 190107, 3, 3, '反关闭', 'close',  'is_closed=0', 0, 0, 13);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (190432, 190107, 3, 3, '取消',   'cancel', 'is_cancel=1', 0, 1, 14);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) KEY(id) VALUES (190433, 190107, 3, 3, '反取消', 'cancel', 'is_cancel=0', 0, 0, 15);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190434, 190107, 3,  3, '变更',     'change',   1, 1, 16);
MERGE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) KEY(id) VALUES (190435, 190107, 3,  3, '下推',     'push',     0, 0, 17);


-- ============================================================
-- 5. 表单实体层级（meta_form_entity）—— 8 主 + 8 子 + 1 孙 = 17 行
--    主表 entity_code=main_table；子表 entity_code 视业务命名；
--    孙表 entity_code='sub'（parent_entity_code='material', entity_level=2，仅 MFG_BOM）
-- ============================================================

-- 5.1 主实体（entity_type='main', entity_level=0）—— 8 行
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (190500, 'MFG_BOM',       'mfg_bom',       'BOM配方',   'main', 0, 'mfg_bom',       NULL, NULL, 1);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (190503, 'MFG_ROUTE',     'mfg_route',     '工艺路线',  'main', 0, 'mfg_route',     NULL, NULL, 1);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (190505, 'MFG_NOTICE',    'mfg_notice',    '生产通知单', 'main', 0, 'mfg_notice',    NULL, NULL, 1);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (190507, 'MFG_ORDER',     'mfg_order',     '生产订单',   'main', 0, 'mfg_order',     NULL, NULL, 1);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (190509, 'MFG_PICK',      'mfg_pick',     '领料单',     'main', 0, 'mfg_pick',      NULL, NULL, 1);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (190511, 'MFG_IN_STOCK',  'mfg_in_stock',  '生产入库',   'main', 0, 'mfg_in_stock',  NULL, NULL, 1);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (190513, 'MFG_MRP_PLAN',  'mfg_mrp_plan',  'MRP计划',    'main', 0, 'mfg_mrp_plan',  NULL, NULL, 1);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (190515, 'MFG_OUTSOURCE', 'mfg_outsource', '外协订单',   'main', 0, 'mfg_outsource', NULL, NULL, 1);

-- 5.2 子实体（entity_type='sub', entity_level=1）—— 8 行
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (190501, 'MFG_BOM',       'material',  'BOM原料明细',   'sub', 1, 'mfg_bom_material',       'mfg_bom',       'bom_id',      2);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (190504, 'MFG_ROUTE',     'operation', '工艺工序明细',  'sub', 1, 'mfg_route_operation',    'mfg_route',     'route_id',    2);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (190506, 'MFG_NOTICE',    'goods',     '通知单明细',    'sub', 1, 'mfg_notice_goods',       'mfg_notice',    'notice_id',   2);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (190508, 'MFG_ORDER',     'material',  '投料明细',      'sub', 1, 'mfg_order_material',     'mfg_order',     'order_id',    2);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (190510, 'MFG_PICK',      'goods',     '领料明细',      'sub', 1, 'mfg_pick_goods',         'mfg_pick',      'pick_id',     2);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (190512, 'MFG_IN_STOCK',  'goods',     '入库明细',      'sub', 1, 'mfg_in_stock_goods',     'mfg_in_stock',  'in_stock_id', 2);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (190514, 'MFG_MRP_PLAN',  'detail',    'MRP计划明细',   'sub', 1, 'mfg_mrp_plan_detail',    'mfg_mrp_plan',  'plan_id',     2);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (190516, 'MFG_OUTSOURCE', 'goods',     '外协明细',      'sub', 1, 'mfg_outsource_goods',    'mfg_outsource', 'out_id',      2);

-- 5.3 孙实体（entity_type='sub', entity_level=2）—— 1 行，MFG_BOM 替代料/染化料
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (190502, 'MFG_BOM', 'sub', 'BOM替代料明细', 'sub', 2, 'mfg_bom_material_sub', 'material', 'bom_material_id', 3);


-- ============================================================
-- 6. 表单字段元数据（meta_form_field）—— 158 行
--    仅注册关键字段（编码/日期/状态 + 组织/人员/供应商/仓库外键 + 金额 + 备注 + 审计字段）
--    字段类型：text/number/date/datetime/enum/ref/qty/amount
--    控件类型：text/textarea/number/date/datetime/select/ref/qty/amount
--    ref 字段附带 ref_bo_code；ID 区间 230300-230457
--    is_closed/is_cancel 不注册为 form_field，由 post_action 处理（遵循 SCM 模式）
-- ============================================================

-- ------------------------------------------------------------
-- 6.1 MFG_BOM BOM配方
-- ------------------------------------------------------------
-- 主表 mfg_bom（12 字段）
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230300, 'MFG_BOM', 'mfg_bom', 'code',         '单据编码', 'text',   'text',     1, 0, 1,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (230301, 'MFG_BOM', 'mfg_bom', 'mat_id',       '成品物料', 'ref',    'ref',      1, 0, 'MD_MATERIAL', 2,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230302, 'MFG_BOM', 'mfg_bom', 'bom_type',     'BOM类型',  'enum',   'select',   0, 0, 3,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230303, 'MFG_BOM', 'mfg_bom', 'version_no',   '版本号',   'number', 'number',   0, 1, 4,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230304, 'MFG_BOM', 'mfg_bom', 'valid_start',  '生效日期', 'date',   'date',     0, 0, 5,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230305, 'MFG_BOM', 'mfg_bom', 'valid_end',    '失效日期', 'date',   'date',     0, 0, 6,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (230306, 'MFG_BOM', 'mfg_bom', 'route_id',     '工艺路线', 'ref',    'ref',      0, 0, 'MFG_ROUTE',    7,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230307, 'MFG_BOM', 'mfg_bom', 'base_qty',     '基础数量', 'qty',    'qty',      0, 0, 8,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230308, 'MFG_BOM', 'mfg_bom', 'std_cost',     '标准成本', 'amount', 'amount',   0, 1, 9,  '金额信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230309, 'MFG_BOM', 'mfg_bom', 'pact_state',    '单据状态', 'enum',   'select',   0, 1, 10, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230310, 'MFG_BOM', 'mfg_bom', 'remark',        '备注',     'text',   'textarea', 0, 0, 11, '其他');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (230311, 'MFG_BOM', 'mfg_bom', 'auditor',       '审核人',   'ref',    'ref',      0, 1, 'MD_EMPLOYEE', 12, '审计信息');
-- 子表 mfg_bom_material / material（9 字段）
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230312, 'MFG_BOM', 'material', 'sort_index', '行号',     'number', 'number',   0, 0, 1,  '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (230313, 'MFG_BOM', 'material', 'bom_id',     'BOM',      'ref',    'ref',      1, 1, 'MFG_BOM',      2,  '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (230314, 'MFG_BOM', 'material', 'mat_id',     '物料',     'ref',    'ref',      1, 0, 'MD_MATERIAL',  3,  '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230315, 'MFG_BOM', 'material', 'mat_type',   '物料类型', 'enum',   'select',   0, 0, 4,  '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230316, 'MFG_BOM', 'material', 'ratio',      '配比',     'number', 'number',   0, 0, 5,  '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230317, 'MFG_BOM', 'material', 'unit_qty',   '单位用量', 'qty',    'qty',      0, 0, 6,  '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230318, 'MFG_BOM', 'material', 'loss_rate',  '损耗率',   'number', 'number',   0, 0, 7,  '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230319, 'MFG_BOM', 'material', 'is_dm',      '是否缸差', 'enum',   'select',   0, 0, 8,  '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230320, 'MFG_BOM', 'material', 'remark',     '备注',     'text',   'textarea', 0, 0, 9,  '明细信息');
-- 孙表 mfg_bom_material_sub / sub（6 字段，entity_level=2，parent_entity_code='material'）
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230321, 'MFG_BOM', 'sub', 'sort_index',       '行号',       'number', 'number',   0, 0, 1,  '替代料信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230322, 'MFG_BOM', 'sub', 'bom_material_id',  'BOM明细',    'number', 'number',   1, 1, 2,  '替代料信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (230323, 'MFG_BOM', 'sub', 'mat_id',           '替代物料',   'ref',    'ref',      1, 0, 'MD_MATERIAL',    3,  '替代料信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230324, 'MFG_BOM', 'sub', 'sub_ratio',        '替代比例',   'number', 'number',   0, 0, 4,  '替代料信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230325, 'MFG_BOM', 'sub', 'priority',         '优先级',     'number', 'number',   0, 0, 5,  '替代料信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (230326, 'MFG_BOM', 'sub', 'color_id',         '颜色',       'ref',    'ref',      0, 0, 'MD_COLOR_SERIES',6,  '替代料信息');

-- ------------------------------------------------------------
-- 6.2 MFG_ROUTE 工艺路线
-- ------------------------------------------------------------
-- 主表 mfg_route（5 字段）
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230327, 'MFG_ROUTE', 'mfg_route', 'code',       '单据编码', 'text',   'text',     1, 0, 1,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (230328, 'MFG_ROUTE', 'mfg_route', 'mat_id',     '成品物料', 'ref',    'ref',      1, 0, 'MD_MATERIAL', 2,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230329, 'MFG_ROUTE', 'mfg_route', 'name',       '工艺名称', 'text',   'text',     0, 0, 3,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230330, 'MFG_ROUTE', 'mfg_route', 'pact_state', '单据状态', 'enum',   'select',   0, 1, 4,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230331, 'MFG_ROUTE', 'mfg_route', 'remark',     '备注',     'text',   'textarea', 0, 0, 5,  '其他');
-- 子表 mfg_route_operation / operation（9 字段）
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230332, 'MFG_ROUTE', 'operation', 'sort_index',        '行号',       'number', 'number',   0, 0, 1,  '工序信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (230333, 'MFG_ROUTE', 'operation', 'route_id',           '工艺路线',   'ref',    'ref',      1, 1, 'MFG_ROUTE',   2,  '工序信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230334, 'MFG_ROUTE', 'operation', 'operation_name',     '工序名称',   'text',   'text',     1, 0, 3,  '工序信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230335, 'MFG_ROUTE', 'operation', 'std_labor_hours',   '标准工时',   'number', 'number',   0, 0, 4,  '工序信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230336, 'MFG_ROUTE', 'operation', 'std_machine_hours', '标准机时',   'number', 'number',   0, 0, 5,  '工序信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230337, 'MFG_ROUTE', 'operation', 'machine_type',      '机型',       'text',   'text',     0, 0, 6,  '工序信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230338, 'MFG_ROUTE', 'operation', 'piece_rate',        '计件单价',   'amount', 'amount',   0, 0, 7,  '工序信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230339, 'MFG_ROUTE', 'operation', 'is_outsource',      '是否外协',   'enum',   'select',   0, 0, 8,  '工序信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230340, 'MFG_ROUTE', 'operation', 'remark',             '备注',       'text',   'textarea', 0, 0, 9,  '工序信息');

-- ------------------------------------------------------------
-- 6.3 MFG_NOTICE 生产通知单
-- ------------------------------------------------------------
-- 主表 mfg_notice（12 字段）
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230341, 'MFG_NOTICE', 'mfg_notice', 'code',        '单据编码', 'text',   'text',     1, 0, 1,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230342, 'MFG_NOTICE', 'mfg_notice', 'pact_date',   '通知日期', 'date',   'date',     1, 0, 2,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230343, 'MFG_NOTICE', 'mfg_notice', 'pact_state',  '单据状态', 'enum',   'select',   0, 1, 3,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (230344, 'MFG_NOTICE', 'mfg_notice', 'sal_org_id',  '销售组织', 'ref',    'ref',      0, 0, 'MD_ORG',      4,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (230345, 'MFG_NOTICE', 'mfg_notice', 'prd_org_id',  '生产组织', 'ref',    'ref',      0, 0, 'MD_ORG',      5,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (230346, 'MFG_NOTICE', 'mfg_notice', 'cust_id',     '客户',     'ref',    'ref',      0, 0, 'MD_CUSTOMER', 6,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (230347, 'MFG_NOTICE', 'mfg_notice', 'dept_id',     '部门',     'ref',    'ref',      0, 0, 'MD_DEPT',     7,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (230348, 'MFG_NOTICE', 'mfg_notice', 'saler_id',    '业务员',   'ref',    'ref',      0, 0, 'MD_SALER',    8,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (230349, 'MFG_NOTICE', 'mfg_notice', 'mat_id',      '成品物料', 'ref',    'ref',      1, 0, 'MD_MATERIAL', 9,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (230350, 'MFG_NOTICE', 'mfg_notice', 'route_id',    '工艺路线', 'ref',    'ref',      0, 0, 'MFG_ROUTE',   10, '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230351, 'MFG_NOTICE', 'mfg_notice', 'remark',      '备注',     'text',   'textarea', 0, 0, 11, '其他');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (230352, 'MFG_NOTICE', 'mfg_notice', 'auditor',     '审核人',   'ref',    'ref',      0, 1, 'MD_EMPLOYEE', 12, '审计信息');
-- 子表 mfg_notice_goods / goods（9 字段）
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230353, 'MFG_NOTICE', 'goods', 'sort_index', '行号',   'number', 'number',   0, 0, 1,  '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (230354, 'MFG_NOTICE', 'goods', 'notice_id',  '通知单', 'ref',    'ref',      1, 1, 'MFG_NOTICE',   2,  '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (230355, 'MFG_NOTICE', 'goods', 'mat_id',     '物料',   'ref',    'ref',      1, 0, 'MD_MATERIAL',  3,  '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230356, 'MFG_NOTICE', 'goods', 'qty',        '数量',   'qty',    'qty',      1, 0, 4,  '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (230357, 'MFG_NOTICE', 'goods', 'unit',       '单位',   'ref',    'ref',      0, 0, 'MD_UNIT',      5,  '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230358, 'MFG_NOTICE', 'goods', 'price',      '单价',   'amount', 'amount',   0, 0, 6,  '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230359, 'MFG_NOTICE', 'goods', 'amount',     '金额',   'amount', 'amount',   0, 1, 7,  '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230360, 'MFG_NOTICE', 'goods', 'color',      '颜色',   'text',   'text',     0, 0, 8,  '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230361, 'MFG_NOTICE', 'goods', 'remark',     '备注',   'text',   'textarea', 0, 0, 9,  '明细信息');

-- ------------------------------------------------------------
-- 6.4 MFG_ORDER 生产订单
-- ------------------------------------------------------------
-- 主表 mfg_order（14 字段）
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230362, 'MFG_ORDER', 'mfg_order', 'code',         '单据编码', 'text',   'text',     1, 0, 1,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230363, 'MFG_ORDER', 'mfg_order', 'order_date',   '订单日期', 'date',   'date',     1, 0, 2,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230364, 'MFG_ORDER', 'mfg_order', 'pact_state',   '单据状态', 'enum',   'select',   0, 1, 3,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (230365, 'MFG_ORDER', 'mfg_order', 'org_id',       '生产组织', 'ref',    'ref',      1, 0, 'MD_ORG',       4,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (230366, 'MFG_ORDER', 'mfg_order', 'workshop_id',  '生产车间', 'ref',    'ref',      0, 0, 'MD_DEPT',      5,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (230367, 'MFG_ORDER', 'mfg_order', 'mat_id',       '成品物料', 'ref',    'ref',      1, 0, 'MD_MATERIAL',  6,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230368, 'MFG_ORDER', 'mfg_order', 'plan_qty',     '计划数量', 'qty',    'qty',      1, 0, 7,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (230369, 'MFG_ORDER', 'mfg_order', 'unit',         '单位',     'ref',    'ref',      0, 0, 'MD_UNIT',      8,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230370, 'MFG_ORDER', 'mfg_order', 'plan_start',   '计划开始', 'date',   'date',     0, 0, 9,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230371, 'MFG_ORDER', 'mfg_order', 'plan_end',     '计划结束', 'date',   'date',     0, 0, 10, '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (230372, 'MFG_ORDER', 'mfg_order', 'bom_id',       'BOM',      'ref',    'ref',      0, 0, 'MFG_BOM',      11, '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (230373, 'MFG_ORDER', 'mfg_order', 'route_id',     '工艺路线', 'ref',    'ref',      0, 0, 'MFG_ROUTE',    12, '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230374, 'MFG_ORDER', 'mfg_order', 'remark',        '备注',     'text',   'textarea', 0, 0, 13, '其他');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (230375, 'MFG_ORDER', 'mfg_order', 'auditor',       '审核人',   'ref',    'ref',      0, 1, 'MD_EMPLOYEE', 14, '审计信息');
-- 子表 mfg_order_material / material（8 字段）
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230376, 'MFG_ORDER', 'material', 'sort_index',  '行号',     'number', 'number',   0, 0, 1,  '投料明细');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (230377, 'MFG_ORDER', 'material', 'order_id',    '生产订单', 'ref',    'ref',      1, 1, 'MFG_ORDER',    2,  '投料明细');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (230378, 'MFG_ORDER', 'material', 'mat_id',      '物料',     'ref',    'ref',      1, 0, 'MD_MATERIAL',  3,  '投料明细');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230379, 'MFG_ORDER', 'material', 'batch_no',    '批次号',   'text',   'text',     0, 0, 4,  '投料明细');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230380, 'MFG_ORDER', 'material', 'std_qty',     '标准用量', 'qty',    'qty',      0, 1, 5,  '投料明细');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230381, 'MFG_ORDER', 'material', 'actual_qty',  '实际用量', 'qty',    'qty',      0, 1, 6,  '投料明细');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230382, 'MFG_ORDER', 'material', 'loss_rate',   '损耗率',   'number', 'number',   0, 0, 7,  '投料明细');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230383, 'MFG_ORDER', 'material', 'remark',      '备注',     'text',   'textarea', 0, 0, 8,  '投料明细');

-- ------------------------------------------------------------
-- 6.5 MFG_PICK 领料单
-- ------------------------------------------------------------
-- 主表 mfg_pick（12 字段）
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230384, 'MFG_PICK', 'mfg_pick', 'code',         '单据编码', 'text',   'text',     1, 0, 1,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230385, 'MFG_PICK', 'mfg_pick', 'pick_date',    '领料日期', 'date',   'date',     1, 0, 2,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230386, 'MFG_PICK', 'mfg_pick', 'pact_state',   '单据状态', 'enum',   'select',   0, 1, 3,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (230387, 'MFG_PICK', 'mfg_pick', 'org_id',       '生产组织', 'ref',    'ref',      1, 0, 'MD_ORG',       4,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (230388, 'MFG_PICK', 'mfg_pick', 'workshop_id',  '生产车间', 'ref',    'ref',      0, 0, 'MD_DEPT',      5,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (230389, 'MFG_PICK', 'mfg_pick', 'warehouse_id', '仓库',     'ref',    'ref',      1, 0, 'MD_WAREHOUSE', 6,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (230390, 'MFG_PICK', 'mfg_pick', 'mfg_order_id', '生产订单', 'ref',    'ref',      0, 0, 'MFG_ORDER',    7,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230391, 'MFG_PICK', 'mfg_pick', 'pick_type',    '领料类型', 'enum',   'select',   0, 0, 8,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230392, 'MFG_PICK', 'mfg_pick', 'total_qty',    '总数量',   'qty',    'qty',      0, 1, 9,  '金额信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230393, 'MFG_PICK', 'mfg_pick', 'total_cost',   '总成本',   'amount', 'amount',   0, 1, 10, '金额信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230394, 'MFG_PICK', 'mfg_pick', 'remark',       '备注',     'text',   'textarea', 0, 0, 11, '其他');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (230395, 'MFG_PICK', 'mfg_pick', 'auditor',      '审核人',   'ref',    'ref',      0, 1, 'MD_EMPLOYEE', 12, '审计信息');
-- 子表 mfg_pick_goods / goods（9 字段）
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230396, 'MFG_PICK', 'goods', 'sort_index',   '行号',   'number', 'number',   0, 0, 1,  '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (230397, 'MFG_PICK', 'goods', 'pick_id',      '领料单', 'ref',    'ref',      1, 1, 'MFG_PICK',     2,  '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (230398, 'MFG_PICK', 'goods', 'mat_id',       '物料',   'ref',    'ref',      1, 0, 'MD_MATERIAL',  3,  '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230399, 'MFG_PICK', 'goods', 'batch_no',     '批次号', 'text',   'text',     0, 0, 4,  '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230400, 'MFG_PICK', 'goods', 'qty',          '数量',   'qty',    'qty',      1, 0, 5,  '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (230401, 'MFG_PICK', 'goods', 'unit',         '单位',   'ref',    'ref',      0, 0, 'MD_UNIT',      6,  '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230402, 'MFG_PICK', 'goods', 'cost_price',   '成本单价', 'amount', 'amount',   0, 0, 7,  '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230403, 'MFG_PICK', 'goods', 'cost_amount',  '成本金额', 'amount', 'amount',   0, 1, 8,  '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230404, 'MFG_PICK', 'goods', 'remark',       '备注',   'text',   'textarea', 0, 0, 9,  '明细信息');

-- ------------------------------------------------------------
-- 6.6 MFG_IN_STOCK 生产入库
-- ------------------------------------------------------------
-- 主表 mfg_in_stock（11 字段）
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230405, 'MFG_IN_STOCK', 'mfg_in_stock', 'code',         '单据编码', 'text',   'text',     1, 0, 1,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230406, 'MFG_IN_STOCK', 'mfg_in_stock', 'in_date',      '入库日期', 'date',   'date',     1, 0, 2,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230407, 'MFG_IN_STOCK', 'mfg_in_stock', 'pact_state',   '单据状态', 'enum',   'select',   0, 1, 3,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (230408, 'MFG_IN_STOCK', 'mfg_in_stock', 'org_id',       '生产组织', 'ref',    'ref',      1, 0, 'MD_ORG',       4,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (230409, 'MFG_IN_STOCK', 'mfg_in_stock', 'warehouse_id', '仓库',     'ref',    'ref',      1, 0, 'MD_WAREHOUSE', 5,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (230410, 'MFG_IN_STOCK', 'mfg_in_stock', 'mfg_order_id', '生产订单', 'ref',    'ref',      0, 0, 'MFG_ORDER',    6,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230411, 'MFG_IN_STOCK', 'mfg_in_stock', 'in_type',      '入库类型', 'enum',   'select',   0, 0, 7,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230412, 'MFG_IN_STOCK', 'mfg_in_stock', 'total_qty',    '总数量',   'qty',    'qty',      0, 1, 8,  '金额信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230413, 'MFG_IN_STOCK', 'mfg_in_stock', 'total_cost',   '总成本',   'amount', 'amount',   0, 1, 9,  '金额信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230414, 'MFG_IN_STOCK', 'mfg_in_stock', 'remark',       '备注',     'text',   'textarea', 0, 0, 10, '其他');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (230415, 'MFG_IN_STOCK', 'mfg_in_stock', 'auditor',      '审核人',   'ref',    'ref',      0, 1, 'MD_EMPLOYEE', 11, '审计信息');
-- 子表 mfg_in_stock_goods / goods（9 字段）
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230416, 'MFG_IN_STOCK', 'goods', 'sort_index',   '行号',   'number', 'number',   0, 0, 1,  '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (230417, 'MFG_IN_STOCK', 'goods', 'in_stock_id',  '入库单', 'ref',    'ref',      1, 1, 'MFG_IN_STOCK', 2,  '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (230418, 'MFG_IN_STOCK', 'goods', 'mat_id',       '物料',   'ref',    'ref',      1, 0, 'MD_MATERIAL',  3,  '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230419, 'MFG_IN_STOCK', 'goods', 'batch_no',     '批次号', 'text',   'text',     0, 0, 4,  '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230420, 'MFG_IN_STOCK', 'goods', 'qty',          '数量',   'qty',    'qty',      1, 0, 5,  '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (230421, 'MFG_IN_STOCK', 'goods', 'unit',         '单位',   'ref',    'ref',      0, 0, 'MD_UNIT',      6,  '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230422, 'MFG_IN_STOCK', 'goods', 'cost_price',   '成本单价', 'amount', 'amount',   0, 0, 7,  '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230423, 'MFG_IN_STOCK', 'goods', 'cost_amount',  '成本金额', 'amount', 'amount',   0, 1, 8,  '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230424, 'MFG_IN_STOCK', 'goods', 'remark',       '备注',   'text',   'textarea', 0, 0, 9,  '明细信息');

-- ------------------------------------------------------------
-- 6.7 MFG_MRP_PLAN MRP计划
-- ------------------------------------------------------------
-- 主表 mfg_mrp_plan（5 字段）
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230425, 'MFG_MRP_PLAN', 'mfg_mrp_plan', 'code',       '单据编码', 'text',   'text',     1, 0, 1,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230426, 'MFG_MRP_PLAN', 'mfg_mrp_plan', 'plan_date',  '计划日期', 'date',   'date',     1, 0, 2,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230427, 'MFG_MRP_PLAN', 'mfg_mrp_plan', 'plan_type',  '计划类型', 'enum',   'select',   0, 0, 3,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (230428, 'MFG_MRP_PLAN', 'mfg_mrp_plan', 'org_id',     '组织',     'ref',    'ref',      0, 0, 'MD_ORG',       4,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230429, 'MFG_MRP_PLAN', 'mfg_mrp_plan', 'pact_state', '单据状态', 'enum',   'select',   0, 1, 5,  '基本信息');
-- 子表 mfg_mrp_plan_detail / detail（9 字段）
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230430, 'MFG_MRP_PLAN', 'detail', 'sort_index',  '行号',       'number', 'number',   0, 0, 1,  '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (230431, 'MFG_MRP_PLAN', 'detail', 'plan_id',     'MRP计划',    'ref',    'ref',      1, 1, 'MFG_MRP_PLAN', 2,  '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (230432, 'MFG_MRP_PLAN', 'detail', 'mat_id',      '物料',       'ref',    'ref',      1, 0, 'MD_MATERIAL',  3,  '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230433, 'MFG_MRP_PLAN', 'detail', 'gross_req',   '毛需求',     'qty',    'qty',      0, 0, 4,  '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230434, 'MFG_MRP_PLAN', 'detail', 'stock_avail', '可用库存',   'qty',    'qty',      0, 0, 5,  '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230435, 'MFG_MRP_PLAN', 'detail', 'net_req',     '净需求',     'qty',    'qty',      0, 1, 6,  '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230436, 'MFG_MRP_PLAN', 'detail', 'sugg_type',   '建议类型',   'enum',   'select',   0, 0, 7,  '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230437, 'MFG_MRP_PLAN', 'detail', 'sugg_qty',    '建议数量',   'qty',    'qty',      0, 0, 8,  '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230438, 'MFG_MRP_PLAN', 'detail', 'sugg_date',   '建议日期',   'date',   'date',     0, 0, 9,  '明细信息');

-- ------------------------------------------------------------
-- 6.8 MFG_OUTSOURCE 外协订单
-- ------------------------------------------------------------
-- 主表 mfg_outsource（10 字段）
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230439, 'MFG_OUTSOURCE', 'mfg_outsource', 'code',        '单据编码', 'text',   'text',     1, 0, 1,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230440, 'MFG_OUTSOURCE', 'mfg_outsource', 'out_date',    '外协日期', 'date',   'date',     1, 0, 2,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (230441, 'MFG_OUTSOURCE', 'mfg_outsource', 'order_id',    '生产订单', 'ref',    'ref',      0, 0, 'MFG_ORDER',    3,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (230442, 'MFG_OUTSOURCE', 'mfg_outsource', 'supplier_id', '供应商',   'ref',    'ref',      1, 0, 'MD_SUPPLIER',  4,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230443, 'MFG_OUTSOURCE', 'mfg_outsource', 'operation',   '工序',     'text',   'text',     0, 0, 5,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (230444, 'MFG_OUTSOURCE', 'mfg_outsource', 'issue_wh',    '发料仓库', 'ref',    'ref',      0, 0, 'MD_WAREHOUSE', 6,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (230445, 'MFG_OUTSOURCE', 'mfg_outsource', 'recv_wh',     '收货仓库', 'ref',    'ref',      0, 0, 'MD_WAREHOUSE', 7,  '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230446, 'MFG_OUTSOURCE', 'mfg_outsource', 'process_fee', '加工费',   'amount', 'amount',   0, 1, 8,  '金额信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (230447, 'MFG_OUTSOURCE', 'mfg_outsource', 'curr_id',     '币别',     'ref',    'ref',      0, 0, 'MD_CURRENCY',  9,  '金额信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230448, 'MFG_OUTSOURCE', 'mfg_outsource', 'pact_state',  '单据状态', 'enum',   'select',   0, 1, 10, '基本信息');
-- 子表 mfg_outsource_goods / goods（9 字段）
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230449, 'MFG_OUTSOURCE', 'goods', 'sort_index',      '行号',       'number', 'number',   0, 0, 1,  '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (230450, 'MFG_OUTSOURCE', 'goods', 'out_id',          '外协订单',   'ref',    'ref',      1, 1, 'MFG_OUTSOURCE',2,  '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (230451, 'MFG_OUTSOURCE', 'goods', 'mat_id',          '物料',       'ref',    'ref',      1, 0, 'MD_MATERIAL',  3,  '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230452, 'MFG_OUTSOURCE', 'goods', 'batch_no',        '批次号',     'text',   'text',     0, 0, 4,  '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230453, 'MFG_OUTSOURCE', 'goods', 'plan_issue_qty',  '计划发料量', 'qty',    'qty',      0, 0, 5,  '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230454, 'MFG_OUTSOURCE', 'goods', 'issued_qty',      '已发料量',   'qty',    'qty',      0, 1, 6,  '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230455, 'MFG_OUTSOURCE', 'goods', 'received_qty',    '已收货量',   'qty',    'qty',      0, 1, 7,  '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230456, 'MFG_OUTSOURCE', 'goods', 'fee_price',       '加工单价',   'amount', 'amount',   0, 0, 8,  '明细信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (230457, 'MFG_OUTSOURCE', 'goods', 'fee_amount',      '加工金额',   'amount', 'amount',   0, 1, 9,  '明细信息');


-- ============================================================
-- 文件末尾说明
-- ============================================================
-- ID 范围汇总：
--   meta_business_object  190001-190008   (8 行生产制造业务对象)
--   meta_state_machine    190100-190107   (8 行，code=bo_code，state_field=pact_state)
--   meta_state_node       190200-190239   (40 行，每状态机 5 节点，复制 STD_5STATE)
--   meta_state_transition 190300-190435   (136 行，每状态机 17 流转，t12-t15 含 post_action)
--   meta_form_entity      190500-190516   (17 行：8 主 + 8 子 + 1 孙)
--   meta_form_field       230300-230457   (158 行关键字段)
-- 字段总数：12+9+6 + 5+9 + 12+9 + 14+8 + 12+9 + 11+9 + 5+9 + 10+9 = 158
-- ref_bo_code 引用：
--   外部主数据：MD_ORG/MD_DEPT/MD_EMPLOYEE/MD_SUPPLIER/MD_MATERIAL/MD_CURRENCY/
--              MD_WAREHOUSE/MD_UNIT/MD_SALER/MD_CUSTOMER/MD_COLOR_SERIES
--   内部业务对象：MFG_BOM/MFG_ROUTE/MFG_ORDER/MFG_NOTICE/MFG_PICK/MFG_IN_STOCK/
--                MFG_MRP_PLAN/MFG_OUTSOURCE（用于单据间引用，如 bom_id/route_id/mfg_order_id 等）
--   workshop_id → MD_DEPT（无 MD_WORKSHOP，借用部门主数据）
-- is_closed/is_cancel 不注册为 form_field，由 post_action 处理（遵循 SCM 模式）。
-- ============================================================
