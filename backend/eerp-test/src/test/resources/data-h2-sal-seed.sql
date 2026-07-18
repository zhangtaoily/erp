-- ============================================================
-- EERP H2 SAL (销售管理) 元数据种子
-- ============================================================
-- 用途：集成测试 H2 内存数据库销售管理模块元数据种子（Phase 2b）。
--       为 11 个销售/打样业务单据 bo_code 注册业务对象、独立状态机
--       （5 节点 / 17 流转，复制 STD_5STATE 模型）、表单实体层级
--       （主/子/孙）与关键字段元数据，驱动 GenericBillService →
--       GenericOperationService 的 6 阶段流水线，无需具体 Entity/Mapper。
-- 加载：spring.sql.init.data-locations 追加本文件。
-- 幂等：全部使用 REPLACE INTO ... VALUES (...)，可重复执行。
-- ID 约定（与 data-h2-master-seed.sql / data-h2-scm-seed.sql 不冲突）：
--   meta_business_object  170001-170011   (11 行)
--   meta_state_machine    170100-170110   (11 行，每 bo_code 一台，code=bo_code)
--   meta_state_node       170200-170254   (11×5=55 行)
--   meta_state_transition 170300-170486   (11×17=187 行)
--   meta_form_entity      170500-170524   (11 主 + 11 子 + 3 孙 = 25 行)
--   meta_form_field       210300-210545   (246 行)
-- 销售单据约定：bo_type='business', is_stateful=1, is_pushable=1,
--             is_printable=1, pk_strategy='snowflake', main_key='id', status=1
-- 状态机复制：每 bo_code 复制 STD_5STATE（machine_id=100）的 5 节点
--             （id=101-105）与 17 流转（id=200-216），替换 machine_id。
--             t12-t15 含 post_action（is_closed/is_cancel 标记）。
-- 表名/列名以 schema-h2.sql 实际定义为准：
--   SAL_CONTRACT 主表为 sal_cont（非 sal_contract）；
--   SAL_RETURN_NOTICE 主表为 sal_ret_notice；
--   SAL_INT_CONT 子表 link_field=int_cont_id，孙表 link_field=int_cont_goods_id；
--   SAL_RETURN_NOTICE 子表 link_field=ret_notice_id；
--   SAL_ORDER 孙表 craft（sal_order_goods_craft）link_field=order_goods_id。
-- 兼容：H2 MODE=MySQL；时间戳使用 CURRENT_TIMESTAMP；布尔值统一用 1/0。
-- 依赖：schema-h2.sql；data-h2-seed.sql（STD_5STATE 及测试主数据）；
--       data-h2-master-seed.sql（主数据 bo_code，ref_bo_code 引用）；
--       data-h2-scm-seed.sql（采购模块，不冲突）。
-- ============================================================


-- ============================================================
-- 1. 业务对象定义（meta_business_object）—— 11 个销售/打样业务 BO
-- ============================================================

REPLACE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
VALUES (170001, 'SAL_INT_CONT',        '意向合同', 'business', 'sal_int_cont',        'id', 'snowflake', 1, 1, 1, NULL, 1, '意向合同业务单据', 'system', CURRENT_TIMESTAMP);
REPLACE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
VALUES (170002, 'SAL_QUOTE',           '销售报价', 'business', 'sal_quote',            'id', 'snowflake', 1, 1, 1, NULL, 1, '销售报价业务单据', 'system', CURRENT_TIMESTAMP);
REPLACE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
VALUES (170003, 'SAL_CONTRACT',        '销售合同', 'business', 'sal_cont',             'id', 'snowflake', 1, 1, 1, NULL, 1, '销售合同业务单据', 'system', CURRENT_TIMESTAMP);
REPLACE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
VALUES (170004, 'SAL_ORDER',           '销售订单', 'business', 'sal_order',            'id', 'snowflake', 1, 1, 1, NULL, 1, '销售订单业务单据', 'system', CURRENT_TIMESTAMP);
REPLACE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
VALUES (170005, 'SAL_DELIVERY_NOTICE', '发货通知', 'business', 'sal_delivery_notice',  'id', 'snowflake', 1, 1, 1, NULL, 1, '发货通知业务单据', 'system', CURRENT_TIMESTAMP);
REPLACE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
VALUES (170006, 'SAL_OUT_STOCK',       '销售出库', 'business', 'sal_out_stock',        'id', 'snowflake', 1, 1, 1, NULL, 1, '销售出库业务单据', 'system', CURRENT_TIMESTAMP);
REPLACE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
VALUES (170007, 'SAL_RETURN',          '销售退货', 'business', 'sal_return',           'id', 'snowflake', 1, 1, 1, NULL, 1, '销售退货业务单据', 'system', CURRENT_TIMESTAMP);
REPLACE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
VALUES (170008, 'SAL_RETURN_NOTICE',   '退货通知', 'business', 'sal_ret_notice',       'id', 'snowflake', 1, 1, 1, NULL, 1, '退货通知业务单据', 'system', CURRENT_TIMESTAMP);
REPLACE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
VALUES (170009, 'SAL_INVOICE',         '销售发票', 'business', 'sal_invoice',          'id', 'snowflake', 1, 1, 1, NULL, 1, '销售发票业务单据', 'system', CURRENT_TIMESTAMP);
REPLACE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
VALUES (170010, 'PP_NOTICE',           '打样通知', 'business', 'pp_notice',            'id', 'snowflake', 1, 1, 1, NULL, 1, '打样通知业务单据', 'system', CURRENT_TIMESTAMP);
REPLACE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
VALUES (170011, 'PP_RECORD',           '打样记录', 'business', 'pp_record',            'id', 'snowflake', 1, 1, 1, NULL, 1, '打样记录业务单据', 'system', CURRENT_TIMESTAMP);


-- ============================================================
-- 2. 状态机定义（meta_state_machine）—— 11 行，code=bo_code
-- ============================================================

REPLACE INTO meta_state_machine (id, code, name, state_field, remark)
VALUES (170100, 'SAL_INT_CONT',        '意向合同状态机', 'pact_state', '复制 STD_5STATE：0暂存/1已创建/2已提交/3已审核/4已驳回；is_closed/is_cancel 辅助标记');
REPLACE INTO meta_state_machine (id, code, name, state_field, remark)
VALUES (170101, 'SAL_QUOTE',           '销售报价状态机', 'pact_state', '复制 STD_5STATE：0暂存/1已创建/2已提交/3已审核/4已驳回；is_closed/is_cancel 辅助标记');
REPLACE INTO meta_state_machine (id, code, name, state_field, remark)
VALUES (170102, 'SAL_CONTRACT',        '销售合同状态机', 'pact_state', '复制 STD_5STATE：0暂存/1已创建/2已提交/3已审核/4已驳回；is_closed/is_cancel 辅助标记');
REPLACE INTO meta_state_machine (id, code, name, state_field, remark)
VALUES (170103, 'SAL_ORDER',           '销售订单状态机', 'pact_state', '复制 STD_5STATE：0暂存/1已创建/2已提交/3已审核/4已驳回；is_closed/is_cancel 辅助标记');
REPLACE INTO meta_state_machine (id, code, name, state_field, remark)
VALUES (170104, 'SAL_DELIVERY_NOTICE', '发货通知状态机', 'pact_state', '复制 STD_5STATE：0暂存/1已创建/2已提交/3已审核/4已驳回；is_closed/is_cancel 辅助标记');
REPLACE INTO meta_state_machine (id, code, name, state_field, remark)
VALUES (170105, 'SAL_OUT_STOCK',       '销售出库状态机', 'pact_state', '复制 STD_5STATE：0暂存/1已创建/2已提交/3已审核/4已驳回；is_closed/is_cancel 辅助标记');
REPLACE INTO meta_state_machine (id, code, name, state_field, remark)
VALUES (170106, 'SAL_RETURN',          '销售退货状态机', 'pact_state', '复制 STD_5STATE：0暂存/1已创建/2已提交/3已审核/4已驳回；is_closed/is_cancel 辅助标记');
REPLACE INTO meta_state_machine (id, code, name, state_field, remark)
VALUES (170107, 'SAL_RETURN_NOTICE',   '退货通知状态机', 'pact_state', '复制 STD_5STATE：0暂存/1已创建/2已提交/3已审核/4已驳回；is_closed/is_cancel 辅助标记');
REPLACE INTO meta_state_machine (id, code, name, state_field, remark)
VALUES (170108, 'SAL_INVOICE',         '销售发票状态机', 'pact_state', '复制 STD_5STATE：0暂存/1已创建/2已提交/3已审核/4已驳回；is_closed/is_cancel 辅助标记');
REPLACE INTO meta_state_machine (id, code, name, state_field, remark)
VALUES (170109, 'PP_NOTICE',           '打样通知状态机', 'pact_state', '复制 STD_5STATE：0暂存/1已创建/2已提交/3已审核/4已驳回；is_closed/is_cancel 辅助标记');
REPLACE INTO meta_state_machine (id, code, name, state_field, remark)
VALUES (170110, 'PP_RECORD',           '打样记录状态机', 'pact_state', '复制 STD_5STATE：0暂存/1已创建/2已提交/3已审核/4已驳回；is_closed/is_cancel 辅助标记');


-- ============================================================
-- 3. 状态节点（meta_state_node）—— 11×5=55 行
--    复制 STD_5STATE 节点（machine_id=100 的 id=101-105），替换 machine_id
-- ============================================================

-- 3.1 SAL_INT_CONT (machine_id=170100) —— id=170200-170204
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (170200, 170100, 0, '暂存',   '#909399', 1, 0, 1, 1, 0);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (170201, 170100, 1, '已创建', '#409EFF', 0, 0, 1, 1, 1);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (170202, 170100, 2, '已提交', '#E6A23C', 0, 0, 0, 0, 2);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (170203, 170100, 3, '已审核', '#67C23A', 0, 0, 0, 0, 3);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (170204, 170100, 4, '已驳回', '#F56C6C', 0, 0, 1, 1, 4);

-- 3.2 SAL_QUOTE (machine_id=170101) —— id=170205-170209
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (170205, 170101, 0, '暂存',   '#909399', 1, 0, 1, 1, 0);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (170206, 170101, 1, '已创建', '#409EFF', 0, 0, 1, 1, 1);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (170207, 170101, 2, '已提交', '#E6A23C', 0, 0, 0, 0, 2);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (170208, 170101, 3, '已审核', '#67C23A', 0, 0, 0, 0, 3);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (170209, 170101, 4, '已驳回', '#F56C6C', 0, 0, 1, 1, 4);

-- 3.3 SAL_CONTRACT (machine_id=170102) —— id=170210-170214
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (170210, 170102, 0, '暂存',   '#909399', 1, 0, 1, 1, 0);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (170211, 170102, 1, '已创建', '#409EFF', 0, 0, 1, 1, 1);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (170212, 170102, 2, '已提交', '#E6A23C', 0, 0, 0, 0, 2);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (170213, 170102, 3, '已审核', '#67C23A', 0, 0, 0, 0, 3);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (170214, 170102, 4, '已驳回', '#F56C6C', 0, 0, 1, 1, 4);

-- 3.4 SAL_ORDER (machine_id=170103) —— id=170215-170219
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (170215, 170103, 0, '暂存',   '#909399', 1, 0, 1, 1, 0);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (170216, 170103, 1, '已创建', '#409EFF', 0, 0, 1, 1, 1);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (170217, 170103, 2, '已提交', '#E6A23C', 0, 0, 0, 0, 2);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (170218, 170103, 3, '已审核', '#67C23A', 0, 0, 0, 0, 3);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (170219, 170103, 4, '已驳回', '#F56C6C', 0, 0, 1, 1, 4);

-- 3.5 SAL_DELIVERY_NOTICE (machine_id=170104) —— id=170220-170224
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (170220, 170104, 0, '暂存',   '#909399', 1, 0, 1, 1, 0);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (170221, 170104, 1, '已创建', '#409EFF', 0, 0, 1, 1, 1);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (170222, 170104, 2, '已提交', '#E6A23C', 0, 0, 0, 0, 2);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (170223, 170104, 3, '已审核', '#67C23A', 0, 0, 0, 0, 3);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (170224, 170104, 4, '已驳回', '#F56C6C', 0, 0, 1, 1, 4);

-- 3.6 SAL_OUT_STOCK (machine_id=170105) —— id=170225-170229
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (170225, 170105, 0, '暂存',   '#909399', 1, 0, 1, 1, 0);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (170226, 170105, 1, '已创建', '#409EFF', 0, 0, 1, 1, 1);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (170227, 170105, 2, '已提交', '#E6A23C', 0, 0, 0, 0, 2);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (170228, 170105, 3, '已审核', '#67C23A', 0, 0, 0, 0, 3);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (170229, 170105, 4, '已驳回', '#F56C6C', 0, 0, 1, 1, 4);

-- 3.7 SAL_RETURN (machine_id=170106) —— id=170230-170234
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (170230, 170106, 0, '暂存',   '#909399', 1, 0, 1, 1, 0);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (170231, 170106, 1, '已创建', '#409EFF', 0, 0, 1, 1, 1);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (170232, 170106, 2, '已提交', '#E6A23C', 0, 0, 0, 0, 2);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (170233, 170106, 3, '已审核', '#67C23A', 0, 0, 0, 0, 3);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (170234, 170106, 4, '已驳回', '#F56C6C', 0, 0, 1, 1, 4);

-- 3.8 SAL_RETURN_NOTICE (machine_id=170107) —— id=170235-170239
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (170235, 170107, 0, '暂存',   '#909399', 1, 0, 1, 1, 0);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (170236, 170107, 1, '已创建', '#409EFF', 0, 0, 1, 1, 1);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (170237, 170107, 2, '已提交', '#E6A23C', 0, 0, 0, 0, 2);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (170238, 170107, 3, '已审核', '#67C23A', 0, 0, 0, 0, 3);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (170239, 170107, 4, '已驳回', '#F56C6C', 0, 0, 1, 1, 4);

-- 3.9 SAL_INVOICE (machine_id=170108) —— id=170240-170244
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (170240, 170108, 0, '暂存',   '#909399', 1, 0, 1, 1, 0);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (170241, 170108, 1, '已创建', '#409EFF', 0, 0, 1, 1, 1);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (170242, 170108, 2, '已提交', '#E6A23C', 0, 0, 0, 0, 2);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (170243, 170108, 3, '已审核', '#67C23A', 0, 0, 0, 0, 3);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (170244, 170108, 4, '已驳回', '#F56C6C', 0, 0, 1, 1, 4);

-- 3.10 PP_NOTICE (machine_id=170109) —— id=170245-170249
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (170245, 170109, 0, '暂存',   '#909399', 1, 0, 1, 1, 0);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (170246, 170109, 1, '已创建', '#409EFF', 0, 0, 1, 1, 1);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (170247, 170109, 2, '已提交', '#E6A23C', 0, 0, 0, 0, 2);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (170248, 170109, 3, '已审核', '#67C23A', 0, 0, 0, 0, 3);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (170249, 170109, 4, '已驳回', '#F56C6C', 0, 0, 1, 1, 4);

-- 3.11 PP_RECORD (machine_id=170110) —— id=170250-170254
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (170250, 170110, 0, '暂存',   '#909399', 1, 0, 1, 1, 0);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (170251, 170110, 1, '已创建', '#409EFF', 0, 0, 1, 1, 1);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (170252, 170110, 2, '已提交', '#E6A23C', 0, 0, 0, 0, 2);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (170253, 170110, 3, '已审核', '#67C23A', 0, 0, 0, 0, 3);
REPLACE INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES (170254, 170110, 4, '已驳回', '#F56C6C', 0, 0, 1, 1, 4);


-- ============================================================
-- 4. 状态流转（meta_state_transition）—— 11×17=187 行
--    复制 STD_5STATE 流转，替换 machine_id
-- ============================================================

-- 4.1 SAL_INT_CONT (machine_id=170100) —— id=170300-170316
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170300, 170100, 0,  1, '保存',     'save',     0, 0, 1);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170301, 170100, 0,  0, '暂存',     'draft',    0, 0, 2);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170302, 170100, 1,  2, '提交',     'submit',   1, 0, 3);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170303, 170100, 2,  3, '审核',     'audit',    0, 0, 4);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170304, 170100, 2,  4, '驳回',     'reject',   0, 1, 5);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170305, 170100, 4,  2, '重新提交', 'resubmit', 1, 0, 6);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170306, 170100, 2,  1, '撤销',     'revoke',   0, 0, 7);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170307, 170100, 3,  1, '撤销',     'revoke',   0, 0, 8);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170308, 170100, 0, -1, '删除',     'delete',   0, 0, 9);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170309, 170100, 1, -1, '删除',     'delete',   0, 0, 10);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170310, 170100, 4, -1, '删除',     'delete',   0, 0, 11);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (170311, 170100, 3, 3, '关闭',   'close',  'is_closed=1', 0, 0, 12);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (170312, 170100, 3, 3, '反关闭', 'close',  'is_closed=0', 0, 0, 13);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (170313, 170100, 3, 3, '取消',   'cancel', 'is_cancel=1', 0, 1, 14);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (170314, 170100, 3, 3, '反取消', 'cancel', 'is_cancel=0', 0, 0, 15);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170315, 170100, 3,  3, '变更',     'change',   1, 1, 16);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170316, 170100, 3,  3, '下推',     'push',     0, 0, 17);

-- 4.2 SAL_QUOTE (machine_id=170101) —— id=170317-170333
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170317, 170101, 0,  1, '保存',     'save',     0, 0, 1);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170318, 170101, 0,  0, '暂存',     'draft',    0, 0, 2);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170319, 170101, 1,  2, '提交',     'submit',   1, 0, 3);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170320, 170101, 2,  3, '审核',     'audit',    0, 0, 4);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170321, 170101, 2,  4, '驳回',     'reject',   0, 1, 5);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170322, 170101, 4,  2, '重新提交', 'resubmit', 1, 0, 6);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170323, 170101, 2,  1, '撤销',     'revoke',   0, 0, 7);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170324, 170101, 3,  1, '撤销',     'revoke',   0, 0, 8);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170325, 170101, 0, -1, '删除',     'delete',   0, 0, 9);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170326, 170101, 1, -1, '删除',     'delete',   0, 0, 10);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170327, 170101, 4, -1, '删除',     'delete',   0, 0, 11);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (170328, 170101, 3, 3, '关闭',   'close',  'is_closed=1', 0, 0, 12);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (170329, 170101, 3, 3, '反关闭', 'close',  'is_closed=0', 0, 0, 13);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (170330, 170101, 3, 3, '取消',   'cancel', 'is_cancel=1', 0, 1, 14);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (170331, 170101, 3, 3, '反取消', 'cancel', 'is_cancel=0', 0, 0, 15);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170332, 170101, 3,  3, '变更',     'change',   1, 1, 16);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170333, 170101, 3,  3, '下推',     'push',     0, 0, 17);

-- 4.3 SAL_CONTRACT (machine_id=170102) —— id=170334-170350
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170334, 170102, 0,  1, '保存',     'save',     0, 0, 1);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170335, 170102, 0,  0, '暂存',     'draft',    0, 0, 2);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170336, 170102, 1,  2, '提交',     'submit',   1, 0, 3);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170337, 170102, 2,  3, '审核',     'audit',    0, 0, 4);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170338, 170102, 2,  4, '驳回',     'reject',   0, 1, 5);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170339, 170102, 4,  2, '重新提交', 'resubmit', 1, 0, 6);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170340, 170102, 2,  1, '撤销',     'revoke',   0, 0, 7);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170341, 170102, 3,  1, '撤销',     'revoke',   0, 0, 8);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170342, 170102, 0, -1, '删除',     'delete',   0, 0, 9);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170343, 170102, 1, -1, '删除',     'delete',   0, 0, 10);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170344, 170102, 4, -1, '删除',     'delete',   0, 0, 11);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (170345, 170102, 3, 3, '关闭',   'close',  'is_closed=1', 0, 0, 12);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (170346, 170102, 3, 3, '反关闭', 'close',  'is_closed=0', 0, 0, 13);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (170347, 170102, 3, 3, '取消',   'cancel', 'is_cancel=1', 0, 1, 14);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (170348, 170102, 3, 3, '反取消', 'cancel', 'is_cancel=0', 0, 0, 15);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170349, 170102, 3,  3, '变更',     'change',   1, 1, 16);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170350, 170102, 3,  3, '下推',     'push',     0, 0, 17);

-- 4.4 SAL_ORDER (machine_id=170103) —— id=170351-170367
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170351, 170103, 0,  1, '保存',     'save',     0, 0, 1);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170352, 170103, 0,  0, '暂存',     'draft',    0, 0, 2);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170353, 170103, 1,  2, '提交',     'submit',   1, 0, 3);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170354, 170103, 2,  3, '审核',     'audit',    0, 0, 4);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170355, 170103, 2,  4, '驳回',     'reject',   0, 1, 5);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170356, 170103, 4,  2, '重新提交', 'resubmit', 1, 0, 6);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170357, 170103, 2,  1, '撤销',     'revoke',   0, 0, 7);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170358, 170103, 3,  1, '撤销',     'revoke',   0, 0, 8);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170359, 170103, 0, -1, '删除',     'delete',   0, 0, 9);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170360, 170103, 1, -1, '删除',     'delete',   0, 0, 10);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170361, 170103, 4, -1, '删除',     'delete',   0, 0, 11);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (170362, 170103, 3, 3, '关闭',   'close',  'is_closed=1', 0, 0, 12);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (170363, 170103, 3, 3, '反关闭', 'close',  'is_closed=0', 0, 0, 13);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (170364, 170103, 3, 3, '取消',   'cancel', 'is_cancel=1', 0, 1, 14);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (170365, 170103, 3, 3, '反取消', 'cancel', 'is_cancel=0', 0, 0, 15);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170366, 170103, 3,  3, '变更',     'change',   1, 1, 16);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170367, 170103, 3,  3, '下推',     'push',     0, 0, 17);

-- 4.5 SAL_DELIVERY_NOTICE (machine_id=170104) —— id=170368-170384
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170368, 170104, 0,  1, '保存',     'save',     0, 0, 1);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170369, 170104, 0,  0, '暂存',     'draft',    0, 0, 2);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170370, 170104, 1,  2, '提交',     'submit',   1, 0, 3);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170371, 170104, 2,  3, '审核',     'audit',    0, 0, 4);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170372, 170104, 2,  4, '驳回',     'reject',   0, 1, 5);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170373, 170104, 4,  2, '重新提交', 'resubmit', 1, 0, 6);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170374, 170104, 2,  1, '撤销',     'revoke',   0, 0, 7);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170375, 170104, 3,  1, '撤销',     'revoke',   0, 0, 8);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170376, 170104, 0, -1, '删除',     'delete',   0, 0, 9);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170377, 170104, 1, -1, '删除',     'delete',   0, 0, 10);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170378, 170104, 4, -1, '删除',     'delete',   0, 0, 11);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (170379, 170104, 3, 3, '关闭',   'close',  'is_closed=1', 0, 0, 12);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (170380, 170104, 3, 3, '反关闭', 'close',  'is_closed=0', 0, 0, 13);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (170381, 170104, 3, 3, '取消',   'cancel', 'is_cancel=1', 0, 1, 14);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (170382, 170104, 3, 3, '反取消', 'cancel', 'is_cancel=0', 0, 0, 15);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170383, 170104, 3,  3, '变更',     'change',   1, 1, 16);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170384, 170104, 3,  3, '下推',     'push',     0, 0, 17);

-- 4.6 SAL_OUT_STOCK (machine_id=170105) —— id=170385-170401
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170385, 170105, 0,  1, '保存',     'save',     0, 0, 1);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170386, 170105, 0,  0, '暂存',     'draft',    0, 0, 2);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170387, 170105, 1,  2, '提交',     'submit',   1, 0, 3);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170388, 170105, 2,  3, '审核',     'audit',    0, 0, 4);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170389, 170105, 2,  4, '驳回',     'reject',   0, 1, 5);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170390, 170105, 4,  2, '重新提交', 'resubmit', 1, 0, 6);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170391, 170105, 2,  1, '撤销',     'revoke',   0, 0, 7);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170392, 170105, 3,  1, '撤销',     'revoke',   0, 0, 8);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170393, 170105, 0, -1, '删除',     'delete',   0, 0, 9);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170394, 170105, 1, -1, '删除',     'delete',   0, 0, 10);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170395, 170105, 4, -1, '删除',     'delete',   0, 0, 11);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (170396, 170105, 3, 3, '关闭',   'close',  'is_closed=1', 0, 0, 12);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (170397, 170105, 3, 3, '反关闭', 'close',  'is_closed=0', 0, 0, 13);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (170398, 170105, 3, 3, '取消',   'cancel', 'is_cancel=1', 0, 1, 14);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (170399, 170105, 3, 3, '反取消', 'cancel', 'is_cancel=0', 0, 0, 15);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170400, 170105, 3,  3, '变更',     'change',   1, 1, 16);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170401, 170105, 3,  3, '下推',     'push',     0, 0, 17);

-- 4.7 SAL_RETURN (machine_id=170106) —— id=170402-170418
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170402, 170106, 0,  1, '保存',     'save',     0, 0, 1);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170403, 170106, 0,  0, '暂存',     'draft',    0, 0, 2);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170404, 170106, 1,  2, '提交',     'submit',   1, 0, 3);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170405, 170106, 2,  3, '审核',     'audit',    0, 0, 4);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170406, 170106, 2,  4, '驳回',     'reject',   0, 1, 5);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170407, 170106, 4,  2, '重新提交', 'resubmit', 1, 0, 6);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170408, 170106, 2,  1, '撤销',     'revoke',   0, 0, 7);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170409, 170106, 3,  1, '撤销',     'revoke',   0, 0, 8);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170410, 170106, 0, -1, '删除',     'delete',   0, 0, 9);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170411, 170106, 1, -1, '删除',     'delete',   0, 0, 10);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170412, 170106, 4, -1, '删除',     'delete',   0, 0, 11);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (170413, 170106, 3, 3, '关闭',   'close',  'is_closed=1', 0, 0, 12);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (170414, 170106, 3, 3, '反关闭', 'close',  'is_closed=0', 0, 0, 13);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (170415, 170106, 3, 3, '取消',   'cancel', 'is_cancel=1', 0, 1, 14);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (170416, 170106, 3, 3, '反取消', 'cancel', 'is_cancel=0', 0, 0, 15);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170417, 170106, 3,  3, '变更',     'change',   1, 1, 16);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170418, 170106, 3,  3, '下推',     'push',     0, 0, 17);

-- 4.8 SAL_RETURN_NOTICE (machine_id=170107) —— id=170419-170435
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170419, 170107, 0,  1, '保存',     'save',     0, 0, 1);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170420, 170107, 0,  0, '暂存',     'draft',    0, 0, 2);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170421, 170107, 1,  2, '提交',     'submit',   1, 0, 3);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170422, 170107, 2,  3, '审核',     'audit',    0, 0, 4);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170423, 170107, 2,  4, '驳回',     'reject',   0, 1, 5);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170424, 170107, 4,  2, '重新提交', 'resubmit', 1, 0, 6);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170425, 170107, 2,  1, '撤销',     'revoke',   0, 0, 7);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170426, 170107, 3,  1, '撤销',     'revoke',   0, 0, 8);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170427, 170107, 0, -1, '删除',     'delete',   0, 0, 9);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170428, 170107, 1, -1, '删除',     'delete',   0, 0, 10);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170429, 170107, 4, -1, '删除',     'delete',   0, 0, 11);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (170430, 170107, 3, 3, '关闭',   'close',  'is_closed=1', 0, 0, 12);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (170431, 170107, 3, 3, '反关闭', 'close',  'is_closed=0', 0, 0, 13);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (170432, 170107, 3, 3, '取消',   'cancel', 'is_cancel=1', 0, 1, 14);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (170433, 170107, 3, 3, '反取消', 'cancel', 'is_cancel=0', 0, 0, 15);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170434, 170107, 3,  3, '变更',     'change',   1, 1, 16);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170435, 170107, 3,  3, '下推',     'push',     0, 0, 17);

-- 4.9 SAL_INVOICE (machine_id=170108) —— id=170436-170452
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170436, 170108, 0,  1, '保存',     'save',     0, 0, 1);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170437, 170108, 0,  0, '暂存',     'draft',    0, 0, 2);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170438, 170108, 1,  2, '提交',     'submit',   1, 0, 3);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170439, 170108, 2,  3, '审核',     'audit',    0, 0, 4);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170440, 170108, 2,  4, '驳回',     'reject',   0, 1, 5);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170441, 170108, 4,  2, '重新提交', 'resubmit', 1, 0, 6);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170442, 170108, 2,  1, '撤销',     'revoke',   0, 0, 7);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170443, 170108, 3,  1, '撤销',     'revoke',   0, 0, 8);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170444, 170108, 0, -1, '删除',     'delete',   0, 0, 9);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170445, 170108, 1, -1, '删除',     'delete',   0, 0, 10);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170446, 170108, 4, -1, '删除',     'delete',   0, 0, 11);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (170447, 170108, 3, 3, '关闭',   'close',  'is_closed=1', 0, 0, 12);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (170448, 170108, 3, 3, '反关闭', 'close',  'is_closed=0', 0, 0, 13);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (170449, 170108, 3, 3, '取消',   'cancel', 'is_cancel=1', 0, 1, 14);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (170450, 170108, 3, 3, '反取消', 'cancel', 'is_cancel=0', 0, 0, 15);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170451, 170108, 3,  3, '变更',     'change',   1, 1, 16);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170452, 170108, 3,  3, '下推',     'push',     0, 0, 17);

-- 4.10 PP_NOTICE (machine_id=170109) —— id=170453-170469
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170453, 170109, 0,  1, '保存',     'save',     0, 0, 1);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170454, 170109, 0,  0, '暂存',     'draft',    0, 0, 2);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170455, 170109, 1,  2, '提交',     'submit',   1, 0, 3);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170456, 170109, 2,  3, '审核',     'audit',    0, 0, 4);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170457, 170109, 2,  4, '驳回',     'reject',   0, 1, 5);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170458, 170109, 4,  2, '重新提交', 'resubmit', 1, 0, 6);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170459, 170109, 2,  1, '撤销',     'revoke',   0, 0, 7);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170460, 170109, 3,  1, '撤销',     'revoke',   0, 0, 8);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170461, 170109, 0, -1, '删除',     'delete',   0, 0, 9);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170462, 170109, 1, -1, '删除',     'delete',   0, 0, 10);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170463, 170109, 4, -1, '删除',     'delete',   0, 0, 11);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (170464, 170109, 3, 3, '关闭',   'close',  'is_closed=1', 0, 0, 12);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (170465, 170109, 3, 3, '反关闭', 'close',  'is_closed=0', 0, 0, 13);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (170466, 170109, 3, 3, '取消',   'cancel', 'is_cancel=1', 0, 1, 14);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (170467, 170109, 3, 3, '反取消', 'cancel', 'is_cancel=0', 0, 0, 15);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170468, 170109, 3,  3, '变更',     'change',   1, 1, 16);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170469, 170109, 3,  3, '下推',     'push',     0, 0, 17);

-- 4.11 PP_RECORD (machine_id=170110) —— id=170470-170486
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170470, 170110, 0,  1, '保存',     'save',     0, 0, 1);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170471, 170110, 0,  0, '暂存',     'draft',    0, 0, 2);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170472, 170110, 1,  2, '提交',     'submit',   1, 0, 3);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170473, 170110, 2,  3, '审核',     'audit',    0, 0, 4);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170474, 170110, 2,  4, '驳回',     'reject',   0, 1, 5);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170475, 170110, 4,  2, '重新提交', 'resubmit', 1, 0, 6);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170476, 170110, 2,  1, '撤销',     'revoke',   0, 0, 7);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170477, 170110, 3,  1, '撤销',     'revoke',   0, 0, 8);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170478, 170110, 0, -1, '删除',     'delete',   0, 0, 9);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170479, 170110, 1, -1, '删除',     'delete',   0, 0, 10);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170480, 170110, 4, -1, '删除',     'delete',   0, 0, 11);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (170481, 170110, 3, 3, '关闭',   'close',  'is_closed=1', 0, 0, 12);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (170482, 170110, 3, 3, '反关闭', 'close',  'is_closed=0', 0, 0, 13);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (170483, 170110, 3, 3, '取消',   'cancel', 'is_cancel=1', 0, 1, 14);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES (170484, 170110, 3, 3, '反取消', 'cancel', 'is_cancel=0', 0, 0, 15);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170485, 170110, 3,  3, '变更',     'change',   1, 1, 16);
REPLACE INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES (170486, 170110, 3,  3, '下推',     'push',     0, 0, 17);


-- ============================================================
-- 5. 表单实体层级（meta_form_entity）—— 11 主 + 11 子 + 3 孙 = 25 行
-- ============================================================

-- 5.1 主实体（entity_type='main', entity_level=0）—— 11 行
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (170500, 'SAL_INT_CONT',        'sal_int_cont',        '意向合同', 'main', 0, 'sal_int_cont',        NULL, NULL, 1);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (170503, 'SAL_QUOTE',           'sal_quote',           '销售报价', 'main', 0, 'sal_quote',           NULL, NULL, 1);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (170505, 'SAL_CONTRACT',        'sal_cont',            '销售合同', 'main', 0, 'sal_cont',            NULL, NULL, 1);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (170508, 'SAL_ORDER',           'sal_order',           '销售订单', 'main', 0, 'sal_order',           NULL, NULL, 1);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (170511, 'SAL_DELIVERY_NOTICE', 'sal_delivery_notice', '发货通知', 'main', 0, 'sal_delivery_notice', NULL, NULL, 1);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (170513, 'SAL_OUT_STOCK',       'sal_out_stock',       '销售出库', 'main', 0, 'sal_out_stock',       NULL, NULL, 1);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (170515, 'SAL_RETURN',          'sal_return',          '销售退货', 'main', 0, 'sal_return',          NULL, NULL, 1);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (170517, 'SAL_RETURN_NOTICE',   'sal_ret_notice',      '退货通知', 'main', 0, 'sal_ret_notice',      NULL, NULL, 1);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (170519, 'SAL_INVOICE',         'sal_invoice',         '销售发票', 'main', 0, 'sal_invoice',         NULL, NULL, 1);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (170521, 'PP_NOTICE',           'pp_notice',           '打样通知', 'main', 0, 'pp_notice',           NULL, NULL, 1);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (170523, 'PP_RECORD',           'pp_record',           '打样记录', 'main', 0, 'pp_record',           NULL, NULL, 1);

-- 5.2 子实体（entity_type='sub', entity_level=1）—— 11 行
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (170501, 'SAL_INT_CONT',        'goods',  '意向合同明细', 'sub', 1, 'sal_int_cont_goods',        'sal_int_cont',        'int_cont_id',   2);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (170504, 'SAL_QUOTE',           'goods',  '销售报价明细', 'sub', 1, 'sal_quote_goods',           'sal_quote',           'quote_id',      2);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (170506, 'SAL_CONTRACT',        'goods',  '销售合同明细', 'sub', 1, 'sal_cont_goods',            'sal_cont',            'cont_id',       2);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (170509, 'SAL_ORDER',           'goods',  '销售订单明细', 'sub', 1, 'sal_order_goods',           'sal_order',           'order_id',      2);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (170512, 'SAL_DELIVERY_NOTICE', 'goods',  '发货通知明细', 'sub', 1, 'sal_delivery_notice_goods', 'sal_delivery_notice', 'notice_id',     2);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (170514, 'SAL_OUT_STOCK',       'goods',  '销售出库明细', 'sub', 1, 'sal_out_stock_goods',       'sal_out_stock',       'out_stock_id',  2);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (170516, 'SAL_RETURN',          'goods',  '销售退货明细', 'sub', 1, 'sal_return_goods',          'sal_return',          'return_id',     2);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (170518, 'SAL_RETURN_NOTICE',   'goods',  '退货通知明细', 'sub', 1, 'sal_ret_notice_goods',      'sal_ret_notice',      'ret_notice_id', 2);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (170520, 'SAL_INVOICE',         'goods',  '销售发票明细', 'sub', 1, 'sal_invoice_goods',         'sal_invoice',         'invoice_id',    2);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (170522, 'PP_NOTICE',           'detail', '打样通知明细', 'sub', 1, 'pp_notice_detail',          'pp_notice',           'notice_id',     2);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (170524, 'PP_RECORD',           'detail', '打样记录明细', 'sub', 1, 'pp_record_detail',          'pp_record',           'record_id',     2);

-- 5.3 孙实体（entity_type='grandchild', entity_level=2）—— 3 行
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (170502, 'SAL_INT_CONT', 'assign', '意向合同指定用料', 'grandchild', 2, 'sal_int_cont_goods_assign', 'goods', 'int_cont_goods_id', 3);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (170507, 'SAL_CONTRACT', 'assign', '销售合同指定用料', 'grandchild', 2, 'sal_cont_goods_assign', 'goods', 'cont_goods_id', 3);
REPLACE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
VALUES (170510, 'SAL_ORDER', 'craft', '销售订单特殊工艺', 'grandchild', 2, 'sal_order_goods_craft', 'goods', 'order_goods_id', 3);


-- ============================================================
-- 6. 表单字段元数据（meta_form_field）—— 246 行
--    仅注册关键字段（编码/日期/状态 + 客户/组织/业务员/仓库外键 +
--    金额/数量 + is_closed/is_cancel + 备注 + 审计字段 + 明细关键字段）
--    字段类型：text/number/date/enum/ref/qty/amount/bool
--    ID 区间 210300-210545
-- ============================================================

-- ------------------------------------------------------------
-- 6.1 SAL_INT_CONT 意向合同
-- ------------------------------------------------------------
-- 主表 sal_int_cont（14 字段）
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210300, 'SAL_INT_CONT', 'sal_int_cont', 'code',          '单据编码', 'text',   'text',     1, 0, 1,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210301, 'SAL_INT_CONT', 'sal_int_cont', 'pact_date',     '合同日期', 'date',   'date',     1, 0, 2,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210302, 'SAL_INT_CONT', 'sal_int_cont', 'pact_state',    '单据状态', 'enum',   'select',   0, 1, 3,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210303, 'SAL_INT_CONT', 'sal_int_cont', 'sal_org_id',    '销售组织', 'ref',    'ref',      1, 0, 'MD_ORG',      4,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210304, 'SAL_INT_CONT', 'sal_int_cont', 'cust_id',       '客户',     'ref',    'ref',      1, 0, 'MD_CUSTOMER', 5,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210305, 'SAL_INT_CONT', 'sal_int_cont', 'dept_id',       '部门',     'ref',    'ref',      0, 0, 'MD_DEPT',     6,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210306, 'SAL_INT_CONT', 'sal_int_cont', 'saler_id',      '业务员',   'ref',    'ref',      0, 0, 'MD_SALER',    7,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210307, 'SAL_INT_CONT', 'sal_int_cont', 'curr_id',       '币别',     'ref',    'ref',      0, 0, 'MD_CURRENCY', 8,  '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210308, 'SAL_INT_CONT', 'sal_int_cont', 'total_qty',     '总数量',   'qty',    'qty',      0, 1, 9,  '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210309, 'SAL_INT_CONT', 'sal_int_cont', 'total_amount',  '总金额',   'amount', 'amount',   0, 1, 10, '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210310, 'SAL_INT_CONT', 'sal_int_cont', 'is_closed',     '是否关闭', 'bool',   'checkbox', 0, 1, 11, '状态信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210311, 'SAL_INT_CONT', 'sal_int_cont', 'is_cancel',     '是否取消', 'bool',   'checkbox', 0, 1, 12, '状态信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210312, 'SAL_INT_CONT', 'sal_int_cont', 'remark',        '备注',     'text',   'textarea', 0, 0, 13, '其他');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210313, 'SAL_INT_CONT', 'sal_int_cont', 'auditor',       '审核人',   'ref',    'ref',      0, 1, 'MD_EMPLOYEE', 14, '审计信息');
-- 子表 sal_int_cont_goods / goods（8 字段）
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210314, 'SAL_INT_CONT', 'goods', 'sort_index',   '行号',       'number', 'number',   0, 0, 1, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210315, 'SAL_INT_CONT', 'goods', 'int_cont_id',  '意向合同',   'ref',    'ref',      1, 1, 'SAL_INT_CONT', 2, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210316, 'SAL_INT_CONT', 'goods', 'mat_id',       '物料',       'ref',    'ref',      1, 0, 'MD_MATERIAL',  3, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210317, 'SAL_INT_CONT', 'goods', 'qty',          '数量',       'qty',    'qty',      1, 0, 4, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210318, 'SAL_INT_CONT', 'goods', 'unit',         '单位',       'ref',    'ref',      0, 0, 'MD_UNIT',      5, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210319, 'SAL_INT_CONT', 'goods', 'price',        '单价',       'amount', 'amount',   0, 0, 6, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210320, 'SAL_INT_CONT', 'goods', 'amount',       '金额',       'amount', 'amount',   0, 1, 7, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210321, 'SAL_INT_CONT', 'goods', 'remark',       '备注',       'text',   'textarea', 0, 0, 8, '明细信息');
-- 孙表 sal_int_cont_goods_assign / assign（6 字段）
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210322, 'SAL_INT_CONT', 'assign', 'sort_index',       '行号',     'number', 'number',   0, 0, 1, '配额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210323, 'SAL_INT_CONT', 'assign', 'int_cont_goods_id','合同明细', 'number', 'number',   1, 1, 2, '配额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210324, 'SAL_INT_CONT', 'assign', 'mat_id',           '物料',     'ref',    'ref',      1, 0, 'MD_MATERIAL', 3, '配额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210325, 'SAL_INT_CONT', 'assign', 'qty',              '数量',     'qty',    'qty',      1, 0, 4, '配额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210326, 'SAL_INT_CONT', 'assign', 'price',            '单价',     'amount', 'amount',   0, 0, 5, '配额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210327, 'SAL_INT_CONT', 'assign', 'remark',           '备注',     'text',   'textarea', 0, 0, 6, '配额信息');

-- ------------------------------------------------------------
-- 6.2 SAL_QUOTE 销售报价
-- ------------------------------------------------------------
-- 主表 sal_quote（14 字段）
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210328, 'SAL_QUOTE', 'sal_quote', 'code',          '单据编码', 'text',   'text',     1, 0, 1,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210329, 'SAL_QUOTE', 'sal_quote', 'quote_date',    '报价日期', 'date',   'date',     1, 0, 2,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210330, 'SAL_QUOTE', 'sal_quote', 'pact_state',    '单据状态', 'enum',   'select',   0, 1, 3,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210331, 'SAL_QUOTE', 'sal_quote', 'cust_id',       '客户',     'ref',    'ref',      1, 0, 'MD_CUSTOMER', 4,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210332, 'SAL_QUOTE', 'sal_quote', 'sal_org_id',    '销售组织', 'ref',    'ref',      1, 0, 'MD_ORG',      5,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210333, 'SAL_QUOTE', 'sal_quote', 'dept_id',       '部门',     'ref',    'ref',      0, 0, 'MD_DEPT',     6,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210334, 'SAL_QUOTE', 'sal_quote', 'saler_id',      '业务员',   'ref',    'ref',      0, 0, 'MD_SALER',    7,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210335, 'SAL_QUOTE', 'sal_quote', 'curr_id',       '币别',     'ref',    'ref',      0, 0, 'MD_CURRENCY', 8,  '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210336, 'SAL_QUOTE', 'sal_quote', 'total_qty',     '总数量',   'qty',    'qty',      0, 1, 9,  '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210337, 'SAL_QUOTE', 'sal_quote', 'total_amount',  '总金额',   'amount', 'amount',   0, 1, 10, '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210338, 'SAL_QUOTE', 'sal_quote', 'is_closed',     '是否关闭', 'bool',   'checkbox', 0, 1, 11, '状态信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210339, 'SAL_QUOTE', 'sal_quote', 'is_cancel',     '是否取消', 'bool',   'checkbox', 0, 1, 12, '状态信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210340, 'SAL_QUOTE', 'sal_quote', 'remark',        '备注',     'text',   'textarea', 0, 0, 13, '其他');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210341, 'SAL_QUOTE', 'sal_quote', 'auditor',       '审核人',   'ref',    'ref',      0, 1, 'MD_EMPLOYEE', 14, '审计信息');
-- 子表 sal_quote_goods / goods（8 字段）
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210342, 'SAL_QUOTE', 'goods', 'sort_index', '行号',   'number', 'number',   0, 0, 1, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210343, 'SAL_QUOTE', 'goods', 'quote_id',   '报价单', 'ref',    'ref',      1, 1, 'SAL_QUOTE',    2, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210344, 'SAL_QUOTE', 'goods', 'mat_id',     '物料',   'ref',    'ref',      1, 0, 'MD_MATERIAL',  3, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210345, 'SAL_QUOTE', 'goods', 'qty',        '数量',   'qty',    'qty',      1, 0, 4, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210346, 'SAL_QUOTE', 'goods', 'unit',       '单位',   'ref',    'ref',      0, 0, 'MD_UNIT',      5, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210347, 'SAL_QUOTE', 'goods', 'price',      '单价',   'amount', 'amount',   0, 0, 6, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210348, 'SAL_QUOTE', 'goods', 'amount',     '金额',   'amount', 'amount',   0, 1, 7, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210349, 'SAL_QUOTE', 'goods', 'remark',     '备注',   'text',   'textarea', 0, 0, 8, '明细信息');

-- ------------------------------------------------------------
-- 6.3 SAL_CONTRACT 销售合同
-- ------------------------------------------------------------
-- 主表 sal_cont（14 字段）
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210350, 'SAL_CONTRACT', 'sal_cont', 'code',          '单据编码', 'text',   'text',     1, 0, 1,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210351, 'SAL_CONTRACT', 'sal_cont', 'pact_date',     '合同日期', 'date',   'date',     1, 0, 2,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210352, 'SAL_CONTRACT', 'sal_cont', 'pact_state',    '单据状态', 'enum',   'select',   0, 1, 3,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210353, 'SAL_CONTRACT', 'sal_cont', 'sal_org_id',    '销售组织', 'ref',    'ref',      1, 0, 'MD_ORG',      4,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210354, 'SAL_CONTRACT', 'sal_cont', 'cust_id',       '客户',     'ref',    'ref',      1, 0, 'MD_CUSTOMER', 5,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210355, 'SAL_CONTRACT', 'sal_cont', 'dept_id',       '部门',     'ref',    'ref',      0, 0, 'MD_DEPT',     6,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210356, 'SAL_CONTRACT', 'sal_cont', 'saler_id',      '业务员',   'ref',    'ref',      0, 0, 'MD_SALER',    7,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210357, 'SAL_CONTRACT', 'sal_cont', 'curr_id',       '币别',     'ref',    'ref',      0, 0, 'MD_CURRENCY', 8,  '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210358, 'SAL_CONTRACT', 'sal_cont', 'total_qty',     '总数量',   'qty',    'qty',      0, 1, 9,  '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210359, 'SAL_CONTRACT', 'sal_cont', 'total_amount',  '总金额',   'amount', 'amount',   0, 1, 10, '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210360, 'SAL_CONTRACT', 'sal_cont', 'is_closed',     '是否关闭', 'bool',   'checkbox', 0, 1, 11, '状态信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210361, 'SAL_CONTRACT', 'sal_cont', 'is_cancel',     '是否取消', 'bool',   'checkbox', 0, 1, 12, '状态信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210362, 'SAL_CONTRACT', 'sal_cont', 'remark',        '备注',     'text',   'textarea', 0, 0, 13, '其他');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210363, 'SAL_CONTRACT', 'sal_cont', 'auditor',       '审核人',   'ref',    'ref',      0, 1, 'MD_EMPLOYEE', 14, '审计信息');
-- 子表 sal_cont_goods / goods（8 字段）
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210364, 'SAL_CONTRACT', 'goods', 'sort_index', '行号',   'number', 'number',   0, 0, 1, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210365, 'SAL_CONTRACT', 'goods', 'cont_id',    '合同',   'ref',    'ref',      1, 1, 'SAL_CONTRACT', 2, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210366, 'SAL_CONTRACT', 'goods', 'mat_id',     '物料',   'ref',    'ref',      1, 0, 'MD_MATERIAL',  3, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210367, 'SAL_CONTRACT', 'goods', 'qty',        '数量',   'qty',    'qty',      1, 0, 4, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210368, 'SAL_CONTRACT', 'goods', 'unit',       '单位',   'ref',    'ref',      0, 0, 'MD_UNIT',      5, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210369, 'SAL_CONTRACT', 'goods', 'price',      '单价',   'amount', 'amount',   0, 0, 6, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210370, 'SAL_CONTRACT', 'goods', 'amount',     '金额',   'amount', 'amount',   0, 1, 7, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210371, 'SAL_CONTRACT', 'goods', 'remark',     '备注',   'text',   'textarea', 0, 0, 8, '明细信息');
-- 孙表 sal_cont_goods_assign / assign（6 字段）
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210372, 'SAL_CONTRACT', 'assign', 'sort_index',    '行号',     'number', 'number',   0, 0, 1, '配额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210373, 'SAL_CONTRACT', 'assign', 'cont_goods_id', '合同明细', 'number', 'number',   1, 1, 2, '配额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210374, 'SAL_CONTRACT', 'assign', 'mat_id',        '物料',     'ref',    'ref',      1, 0, 'MD_MATERIAL', 3, '配额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210375, 'SAL_CONTRACT', 'assign', 'qty',           '数量',     'qty',    'qty',      1, 0, 4, '配额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210376, 'SAL_CONTRACT', 'assign', 'price',         '单价',     'amount', 'amount',   0, 0, 5, '配额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210377, 'SAL_CONTRACT', 'assign', 'remark',        '备注',     'text',   'textarea', 0, 0, 6, '配额信息');

-- ------------------------------------------------------------
-- 6.4 SAL_ORDER 销售订单
-- ------------------------------------------------------------
-- 主表 sal_order（14 字段）
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210378, 'SAL_ORDER', 'sal_order', 'code',          '单据编码', 'text',   'text',     1, 0, 1,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210379, 'SAL_ORDER', 'sal_order', 'order_date',    '订单日期', 'date',   'date',     1, 0, 2,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210380, 'SAL_ORDER', 'sal_order', 'pact_state',    '单据状态', 'enum',   'select',   0, 1, 3,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210381, 'SAL_ORDER', 'sal_order', 'cust_id',       '客户',     'ref',    'ref',      1, 0, 'MD_CUSTOMER', 4,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210382, 'SAL_ORDER', 'sal_order', 'sal_org_id',    '销售组织', 'ref',    'ref',      1, 0, 'MD_ORG',      5,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210383, 'SAL_ORDER', 'sal_order', 'dept_id',       '部门',     'ref',    'ref',      0, 0, 'MD_DEPT',     6,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210384, 'SAL_ORDER', 'sal_order', 'saler_id',      '业务员',   'ref',    'ref',      0, 0, 'MD_SALER',    7,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210385, 'SAL_ORDER', 'sal_order', 'curr_id',       '币别',     'ref',    'ref',      0, 0, 'MD_CURRENCY', 8,  '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210386, 'SAL_ORDER', 'sal_order', 'total_qty',     '总数量',   'qty',    'qty',      0, 1, 9,  '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210387, 'SAL_ORDER', 'sal_order', 'total_amount',  '总金额',   'amount', 'amount',   0, 1, 10, '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210388, 'SAL_ORDER', 'sal_order', 'is_closed',     '是否关闭', 'bool',   'checkbox', 0, 1, 11, '状态信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210389, 'SAL_ORDER', 'sal_order', 'is_cancel',     '是否取消', 'bool',   'checkbox', 0, 1, 12, '状态信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210390, 'SAL_ORDER', 'sal_order', 'remark',        '备注',     'text',   'textarea', 0, 0, 13, '其他');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210391, 'SAL_ORDER', 'sal_order', 'auditor',       '审核人',   'ref',    'ref',      0, 1, 'MD_EMPLOYEE', 14, '审计信息');
-- 子表 sal_order_goods / goods（8 字段）
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210392, 'SAL_ORDER', 'goods', 'sort_index',   '行号',       'number', 'number',   0, 0, 1, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210393, 'SAL_ORDER', 'goods', 'order_id',     '销售订单',   'ref',    'ref',      1, 1, 'SAL_ORDER',   2, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210394, 'SAL_ORDER', 'goods', 'mat_id',       '物料',       'ref',    'ref',      1, 0, 'MD_MATERIAL', 3, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210395, 'SAL_ORDER', 'goods', 'qty',          '数量',       'qty',    'qty',      1, 0, 4, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210396, 'SAL_ORDER', 'goods', 'unit',         '单位',       'ref',    'ref',      0, 0, 'MD_UNIT',     5, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210397, 'SAL_ORDER', 'goods', 'price',        '单价',       'amount', 'amount',   0, 0, 6, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210398, 'SAL_ORDER', 'goods', 'amount',       '金额',       'amount', 'amount',   0, 1, 7, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210399, 'SAL_ORDER', 'goods', 'remark',       '备注',       'text',   'textarea', 0, 0, 8, '明细信息');
-- 孙表 sal_order_goods_craft / craft（5 字段）
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210400, 'SAL_ORDER', 'craft', 'sort_index',     '行号',       'number', 'number',   0, 0, 1, '工艺信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210401, 'SAL_ORDER', 'craft', 'order_goods_id', '订单明细',   'number', 'number',   1, 1, 2, '工艺信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210402, 'SAL_ORDER', 'craft', 'sp_req',         '特殊要求',   'text',   'text',     0, 0, 3, '工艺信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210403, 'SAL_ORDER', 'craft', 'sp_price',       '特殊费用',   'amount', 'amount',   0, 0, 4, '工艺信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210404, 'SAL_ORDER', 'craft', 'remark',         '备注',       'text',   'textarea', 0, 0, 5, '工艺信息');

-- ------------------------------------------------------------
-- 6.5 SAL_DELIVERY_NOTICE 发货通知
-- ------------------------------------------------------------
-- 主表 sal_delivery_notice（14 字段）
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210405, 'SAL_DELIVERY_NOTICE', 'sal_delivery_notice', 'code',            '单据编码', 'text',   'text',     1, 0, 1,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210406, 'SAL_DELIVERY_NOTICE', 'sal_delivery_notice', 'notice_date',     '通知日期', 'date',   'date',     1, 0, 2,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210407, 'SAL_DELIVERY_NOTICE', 'sal_delivery_notice', 'pact_state',      '单据状态', 'enum',   'select',   0, 1, 3,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210408, 'SAL_DELIVERY_NOTICE', 'sal_delivery_notice', 'cust_id',         '客户',     'ref',    'ref',      1, 0, 'MD_CUSTOMER', 4,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210409, 'SAL_DELIVERY_NOTICE', 'sal_delivery_notice', 'sal_org_id',      '销售组织', 'ref',    'ref',      1, 0, 'MD_ORG',      5,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210410, 'SAL_DELIVERY_NOTICE', 'sal_delivery_notice', 'sal_order_id',    '销售订单', 'ref',    'ref',      0, 0, 'SAL_ORDER',   6,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210411, 'SAL_DELIVERY_NOTICE', 'sal_delivery_notice', 'plan_date',       '计划日期', 'date',   'date',     0, 0, 7,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210412, 'SAL_DELIVERY_NOTICE', 'sal_delivery_notice', 'delivery_method', '发货方式', 'text',   'text',     0, 0, 8,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210413, 'SAL_DELIVERY_NOTICE', 'sal_delivery_notice', 'tracking_no',     '物流单号', 'text',   'text',     0, 0, 9,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210414, 'SAL_DELIVERY_NOTICE', 'sal_delivery_notice', 'total_qty',       '总数量',   'qty',    'qty',      0, 1, 10, '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210415, 'SAL_DELIVERY_NOTICE', 'sal_delivery_notice', 'is_closed',       '是否关闭', 'bool',   'checkbox', 0, 1, 11, '状态信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210416, 'SAL_DELIVERY_NOTICE', 'sal_delivery_notice', 'is_cancel',       '是否取消', 'bool',   'checkbox', 0, 1, 12, '状态信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210417, 'SAL_DELIVERY_NOTICE', 'sal_delivery_notice', 'remark',          '备注',     'text',   'textarea', 0, 0, 13, '其他');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210418, 'SAL_DELIVERY_NOTICE', 'sal_delivery_notice', 'auditor',         '审核人',   'ref',    'ref',      0, 1, 'MD_EMPLOYEE', 14, '审计信息');
-- 子表 sal_delivery_notice_goods / goods（8 字段）
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210419, 'SAL_DELIVERY_NOTICE', 'goods', 'sort_index',  '行号',       'number', 'number',   0, 0, 1, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210420, 'SAL_DELIVERY_NOTICE', 'goods', 'notice_id',   '发货通知',   'ref',    'ref',      1, 1, 'SAL_DELIVERY_NOTICE', 2, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210421, 'SAL_DELIVERY_NOTICE', 'goods', 'mat_id',      '物料',       'ref',    'ref',      1, 0, 'MD_MATERIAL', 3, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210422, 'SAL_DELIVERY_NOTICE', 'goods', 'qty',         '数量',       'qty',    'qty',      1, 0, 4, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210423, 'SAL_DELIVERY_NOTICE', 'goods', 'unit',        '单位',       'ref',    'ref',      0, 0, 'MD_UNIT',     5, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210424, 'SAL_DELIVERY_NOTICE', 'goods', 'price',       '单价',       'amount', 'amount',   0, 0, 6, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210425, 'SAL_DELIVERY_NOTICE', 'goods', 'amount',      '金额',       'amount', 'amount',   0, 1, 7, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210426, 'SAL_DELIVERY_NOTICE', 'goods', 'remark',      '备注',       'text',   'textarea', 0, 0, 8, '明细信息');

-- ------------------------------------------------------------
-- 6.6 SAL_OUT_STOCK 销售出库
-- ------------------------------------------------------------
-- 主表 sal_out_stock（14 字段）
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210427, 'SAL_OUT_STOCK', 'sal_out_stock', 'code',          '单据编码', 'text',   'text',     1, 0, 1,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210428, 'SAL_OUT_STOCK', 'sal_out_stock', 'out_date',      '出库日期', 'date',   'date',     1, 0, 2,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210429, 'SAL_OUT_STOCK', 'sal_out_stock', 'pact_state',    '单据状态', 'enum',   'select',   0, 1, 3,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210430, 'SAL_OUT_STOCK', 'sal_out_stock', 'cust_id',       '客户',     'ref',    'ref',      1, 0, 'MD_CUSTOMER', 4,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210431, 'SAL_OUT_STOCK', 'sal_out_stock', 'sal_org_id',    '销售组织', 'ref',    'ref',      1, 0, 'MD_ORG',      5,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210432, 'SAL_OUT_STOCK', 'sal_out_stock', 'warehouse_id',  '仓库',     'ref',    'ref',      0, 0, 'MD_WAREHOUSE',6,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210433, 'SAL_OUT_STOCK', 'sal_out_stock', 'curr_id',       '币别',     'ref',    'ref',      0, 0, 'MD_CURRENCY', 7,  '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210434, 'SAL_OUT_STOCK', 'sal_out_stock', 'sal_order_id',  '销售订单', 'ref',    'ref',      0, 0, 'SAL_ORDER',   8,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210435, 'SAL_OUT_STOCK', 'sal_out_stock', 'total_qty',     '总数量',   'qty',    'qty',      0, 1, 9,  '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210436, 'SAL_OUT_STOCK', 'sal_out_stock', 'total_amount',  '总金额',   'amount', 'amount',   0, 1, 10, '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210437, 'SAL_OUT_STOCK', 'sal_out_stock', 'is_closed',     '是否关闭', 'bool',   'checkbox', 0, 1, 11, '状态信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210438, 'SAL_OUT_STOCK', 'sal_out_stock', 'is_cancel',     '是否取消', 'bool',   'checkbox', 0, 1, 12, '状态信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210439, 'SAL_OUT_STOCK', 'sal_out_stock', 'remark',        '备注',     'text',   'textarea', 0, 0, 13, '其他');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210440, 'SAL_OUT_STOCK', 'sal_out_stock', 'auditor',       '审核人',   'ref',    'ref',      0, 1, 'MD_EMPLOYEE', 14, '审计信息');
-- 子表 sal_out_stock_goods / goods（8 字段）
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210441, 'SAL_OUT_STOCK', 'goods', 'sort_index',   '行号',       'number', 'number',   0, 0, 1, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210442, 'SAL_OUT_STOCK', 'goods', 'out_stock_id', '销售出库',   'ref',    'ref',      1, 1, 'SAL_OUT_STOCK', 2, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210443, 'SAL_OUT_STOCK', 'goods', 'mat_id',       '物料',       'ref',    'ref',      1, 0, 'MD_MATERIAL', 3, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210444, 'SAL_OUT_STOCK', 'goods', 'qty',          '数量',       'qty',    'qty',      1, 0, 4, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210445, 'SAL_OUT_STOCK', 'goods', 'unit',         '单位',       'ref',    'ref',      0, 0, 'MD_UNIT',     5, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210446, 'SAL_OUT_STOCK', 'goods', 'price',        '单价',       'amount', 'amount',   0, 0, 6, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210447, 'SAL_OUT_STOCK', 'goods', 'amount',       '金额',       'amount', 'amount',   0, 1, 7, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210448, 'SAL_OUT_STOCK', 'goods', 'remark',       '备注',       'text',   'textarea', 0, 0, 8, '明细信息');

-- ------------------------------------------------------------
-- 6.7 SAL_RETURN 销售退货
-- ------------------------------------------------------------
-- 主表 sal_return（14 字段）
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210449, 'SAL_RETURN', 'sal_return', 'code',          '单据编码', 'text',   'text',     1, 0, 1,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210450, 'SAL_RETURN', 'sal_return', 'return_date',   '退货日期', 'date',   'date',     1, 0, 2,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210451, 'SAL_RETURN', 'sal_return', 'pact_state',    '单据状态', 'enum',   'select',   0, 1, 3,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210452, 'SAL_RETURN', 'sal_return', 'cust_id',       '客户',     'ref',    'ref',      1, 0, 'MD_CUSTOMER', 4,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210453, 'SAL_RETURN', 'sal_return', 'sal_org_id',    '销售组织', 'ref',    'ref',      1, 0, 'MD_ORG',      5,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210454, 'SAL_RETURN', 'sal_return', 'warehouse_id',  '仓库',     'ref',    'ref',      0, 0, 'MD_WAREHOUSE',6,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210455, 'SAL_RETURN', 'sal_return', 'dept_id',       '部门',     'ref',    'ref',      0, 0, 'MD_DEPT',     7,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210456, 'SAL_RETURN', 'sal_return', 'curr_id',       '币别',     'ref',    'ref',      0, 0, 'MD_CURRENCY', 8,  '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210457, 'SAL_RETURN', 'sal_return', 'total_qty',     '总数量',   'qty',    'qty',      0, 1, 9,  '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210458, 'SAL_RETURN', 'sal_return', 'total_amount',  '总金额',   'amount', 'amount',   0, 1, 10, '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210459, 'SAL_RETURN', 'sal_return', 'is_closed',     '是否关闭', 'bool',   'checkbox', 0, 1, 11, '状态信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210460, 'SAL_RETURN', 'sal_return', 'is_cancel',     '是否取消', 'bool',   'checkbox', 0, 1, 12, '状态信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210461, 'SAL_RETURN', 'sal_return', 'remark',        '备注',     'text',   'textarea', 0, 0, 13, '其他');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210462, 'SAL_RETURN', 'sal_return', 'auditor',       '审核人',   'ref',    'ref',      0, 1, 'MD_EMPLOYEE', 14, '审计信息');
-- 子表 sal_return_goods / goods（8 字段）
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210463, 'SAL_RETURN', 'goods', 'sort_index',   '行号',       'number', 'number',   0, 0, 1, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210464, 'SAL_RETURN', 'goods', 'return_id',    '销售退货',   'ref',    'ref',      1, 1, 'SAL_RETURN',  2, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210465, 'SAL_RETURN', 'goods', 'mat_id',       '物料',       'ref',    'ref',      1, 0, 'MD_MATERIAL', 3, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210466, 'SAL_RETURN', 'goods', 'qty',          '数量',       'qty',    'qty',      1, 0, 4, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210467, 'SAL_RETURN', 'goods', 'unit',         '单位',       'ref',    'ref',      0, 0, 'MD_UNIT',     5, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210468, 'SAL_RETURN', 'goods', 'price',        '单价',       'amount', 'amount',   0, 0, 6, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210469, 'SAL_RETURN', 'goods', 'amount',       '金额',       'amount', 'amount',   0, 1, 7, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210470, 'SAL_RETURN', 'goods', 'remark',       '备注',       'text',   'textarea', 0, 0, 8, '明细信息');

-- ------------------------------------------------------------
-- 6.8 SAL_RETURN_NOTICE 退货通知（主表 sal_ret_notice，无 is_closed/is_cancel，使用 close_state）
-- ------------------------------------------------------------
-- 主表 sal_ret_notice（14 字段）
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210471, 'SAL_RETURN_NOTICE', 'sal_ret_notice', 'code',         '单据编码', 'text',   'text',     1, 0, 1,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210472, 'SAL_RETURN_NOTICE', 'sal_ret_notice', 'pact_date',    '单据日期', 'date',   'date',     1, 0, 2,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210473, 'SAL_RETURN_NOTICE', 'sal_ret_notice', 'pact_state',   '单据状态', 'enum',   'select',   0, 1, 3,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210474, 'SAL_RETURN_NOTICE', 'sal_ret_notice', 'cust_id',      '客户',     'ref',    'ref',      1, 0, 'MD_CUSTOMER', 4,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210475, 'SAL_RETURN_NOTICE', 'sal_ret_notice', 'prd_org_id',   '生产组织', 'ref',    'ref',      0, 0, 'MD_ORG',      5,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210476, 'SAL_RETURN_NOTICE', 'sal_ret_notice', 'dept_id',      '部门',     'ref',    'ref',      0, 0, 'MD_DEPT',     6,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210477, 'SAL_RETURN_NOTICE', 'sal_ret_notice', 'saler_id',     '业务员',   'ref',    'ref',      0, 0, 'MD_SALER',    7,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210478, 'SAL_RETURN_NOTICE', 'sal_ret_notice', 'curr_id',      '币别',     'ref',    'ref',      0, 0, 'MD_CURRENCY', 8,  '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210479, 'SAL_RETURN_NOTICE', 'sal_ret_notice', 'agent',        '代理人',   'text',   'text',     0, 0, 9,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210480, 'SAL_RETURN_NOTICE', 'sal_ret_notice', 'inv_type',     '发票类型', 'text',   'text',     0, 0, 10, '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210481, 'SAL_RETURN_NOTICE', 'sal_ret_notice', 'dev_addr',     '交货地点', 'text',   'text',     0, 0, 11, '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210482, 'SAL_RETURN_NOTICE', 'sal_ret_notice', 're_reason',    '退货原因', 'text',   'textarea', 0, 0, 12, '其他');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210483, 'SAL_RETURN_NOTICE', 'sal_ret_notice', 'remark',       '备注',     'text',   'textarea', 0, 0, 13, '其他');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210484, 'SAL_RETURN_NOTICE', 'sal_ret_notice', 'auditor',      '审核人',   'ref',    'ref',      0, 1, 'MD_EMPLOYEE', 14, '审计信息');
-- 子表 sal_ret_notice_goods / goods（8 字段，link_field=ret_notice_id）
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210485, 'SAL_RETURN_NOTICE', 'goods', 'sort_index',    '行号',       'number', 'number',   0, 0, 1, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210486, 'SAL_RETURN_NOTICE', 'goods', 'ret_notice_id', '退货通知',   'ref',    'ref',      1, 1, 'SAL_RETURN_NOTICE', 2, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210487, 'SAL_RETURN_NOTICE', 'goods', 'mat_id',        '物料',       'ref',    'ref',      1, 0, 'MD_MATERIAL', 3, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210488, 'SAL_RETURN_NOTICE', 'goods', 'qty',           '数量',       'qty',    'qty',      1, 0, 4, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210489, 'SAL_RETURN_NOTICE', 'goods', 'unit',          '单位',       'ref',    'ref',      0, 0, 'MD_UNIT',     5, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210490, 'SAL_RETURN_NOTICE', 'goods', 'price',         '单价',       'amount', 'amount',   0, 0, 6, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210491, 'SAL_RETURN_NOTICE', 'goods', 'amount',        '金额',       'amount', 'amount',   0, 1, 7, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210492, 'SAL_RETURN_NOTICE', 'goods', 'remark',        '备注',       'text',   'textarea', 0, 0, 8, '明细信息');

-- ------------------------------------------------------------
-- 6.9 SAL_INVOICE 销售发票
-- ------------------------------------------------------------
-- 主表 sal_invoice（13 字段）
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210493, 'SAL_INVOICE', 'sal_invoice', 'code',          '单据编码', 'text',   'text',     1, 0, 1,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210494, 'SAL_INVOICE', 'sal_invoice', 'invoice_date',  '发票日期', 'date',   'date',     1, 0, 2,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210495, 'SAL_INVOICE', 'sal_invoice', 'pact_state',    '单据状态', 'enum',   'select',   0, 1, 3,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210496, 'SAL_INVOICE', 'sal_invoice', 'cust_id',       '客户',     'ref',    'ref',      1, 0, 'MD_CUSTOMER', 4,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210497, 'SAL_INVOICE', 'sal_invoice', 'sal_org_id',    '销售组织', 'ref',    'ref',      1, 0, 'MD_ORG',      5,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210498, 'SAL_INVOICE', 'sal_invoice', 'invoice_type',  '发票类型', 'text',   'text',     0, 0, 6,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210499, 'SAL_INVOICE', 'sal_invoice', 'no_tax_amount', '不含税金额','amount', 'amount',   0, 1, 7,  '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210500, 'SAL_INVOICE', 'sal_invoice', 'tax_amount',    '税额',     'amount', 'amount',   0, 1, 8,  '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210501, 'SAL_INVOICE', 'sal_invoice', 'total_amount',  '总金额',   'amount', 'amount',   0, 1, 9,  '金额信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210502, 'SAL_INVOICE', 'sal_invoice', 'is_closed',     '是否关闭', 'bool',   'checkbox', 0, 1, 10, '状态信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210503, 'SAL_INVOICE', 'sal_invoice', 'is_cancel',     '是否取消', 'bool',   'checkbox', 0, 1, 11, '状态信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210504, 'SAL_INVOICE', 'sal_invoice', 'remark',        '备注',     'text',   'textarea', 0, 0, 12, '其他');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210505, 'SAL_INVOICE', 'sal_invoice', 'auditor',       '审核人',   'ref',    'ref',      0, 1, 'MD_EMPLOYEE', 13, '审计信息');
-- 子表 sal_invoice_goods / goods（8 字段，link_field=invoice_id）
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210506, 'SAL_INVOICE', 'goods', 'sort_index',    '行号',       'number', 'number',   0, 0, 1, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210507, 'SAL_INVOICE', 'goods', 'invoice_id',    '销售发票',   'ref',    'ref',      1, 1, 'SAL_INVOICE', 2, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210508, 'SAL_INVOICE', 'goods', 'mat_id',        '物料',       'ref',    'ref',      1, 0, 'MD_MATERIAL', 3, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210509, 'SAL_INVOICE', 'goods', 'qty',           '数量',       'qty',    'qty',      1, 0, 4, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210510, 'SAL_INVOICE', 'goods', 'unit',          '单位',       'ref',    'ref',      0, 0, 'MD_UNIT',     5, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210511, 'SAL_INVOICE', 'goods', 'price',         '单价',       'amount', 'amount',   0, 0, 6, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210512, 'SAL_INVOICE', 'goods', 'total_amount',  '金额',       'amount', 'amount',   0, 1, 7, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210513, 'SAL_INVOICE', 'goods', 'remark',        '备注',       'text',   'textarea', 0, 0, 8, '明细信息');

-- ------------------------------------------------------------
-- 6.10 PP_NOTICE 打样通知
-- ------------------------------------------------------------
-- 主表 pp_notice（13 字段）
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210514, 'PP_NOTICE', 'pp_notice', 'code',       '单据编码', 'text',   'text',     1, 0, 1,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210515, 'PP_NOTICE', 'pp_notice', 'pact_date',  '单据日期', 'date',   'date',     1, 0, 2,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210516, 'PP_NOTICE', 'pp_notice', 'pact_state', '单据状态', 'enum',   'select',   0, 1, 3,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210517, 'PP_NOTICE', 'pp_notice', 'sal_org_id', '销售组织', 'ref',    'ref',      1, 0, 'MD_ORG',      4,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210518, 'PP_NOTICE', 'pp_notice', 'dept_id',    '部门',     'ref',    'ref',      0, 0, 'MD_DEPT',     5,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210519, 'PP_NOTICE', 'pp_notice', 'saler_id',   '业务员',   'ref',    'ref',      0, 0, 'MD_SALER',    6,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210520, 'PP_NOTICE', 'pp_notice', 'cust_id',    '客户',     'ref',    'ref',      1, 0, 'MD_CUSTOMER', 7,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210521, 'PP_NOTICE', 'pp_notice', 'mat_id',     '物料',     'ref',    'ref',      0, 0, 'MD_MATERIAL', 8,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210522, 'PP_NOTICE', 'pp_notice', 'pro_qty',    '打样数量', 'qty',    'qty',      0, 0, 9,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210523, 'PP_NOTICE', 'pp_notice', 'is_closed',  '是否关闭', 'bool',   'checkbox', 0, 1, 10, '状态信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210524, 'PP_NOTICE', 'pp_notice', 'is_cancel',  '是否取消', 'bool',   'checkbox', 0, 1, 11, '状态信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210525, 'PP_NOTICE', 'pp_notice', 'remark',     '备注',     'text',   'textarea', 0, 0, 12, '其他');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210526, 'PP_NOTICE', 'pp_notice', 'auditor',    '审核人',   'ref',    'ref',      0, 1, 'MD_EMPLOYEE', 13, '审计信息');
-- 子表 pp_notice_detail / detail（4 字段，link_field=notice_id）
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210527, 'PP_NOTICE', 'detail', 'sort_index',    '行号',       'number', 'number',   0, 0, 1, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210528, 'PP_NOTICE', 'detail', 'notice_id',     '打样通知',   'ref',    'ref',      1, 1, 'PP_NOTICE',   2, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210529, 'PP_NOTICE', 'detail', 'sample_color',  '样品颜色',   'text',   'text',     0, 0, 3, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210530, 'PP_NOTICE', 'detail', 'remark',        '备注',       'text',   'textarea', 0, 0, 4, '明细信息');

-- ------------------------------------------------------------
-- 6.11 PP_RECORD 打样记录
-- ------------------------------------------------------------
-- 主表 pp_record（10 字段）
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210531, 'PP_RECORD', 'pp_record', 'code',       '单据编码', 'text',   'text',     1, 0, 1,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210532, 'PP_RECORD', 'pp_record', 'pact_date',  '单据日期', 'date',   'date',     1, 0, 2,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210533, 'PP_RECORD', 'pp_record', 'pact_state', '单据状态', 'enum',   'select',   0, 1, 3,  '基本信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210534, 'PP_RECORD', 'pp_record', 'sal_org_id', '销售组织', 'ref',    'ref',      1, 0, 'MD_ORG',      4,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210535, 'PP_RECORD', 'pp_record', 'saler_id',   '业务员',   'ref',    'ref',      0, 0, 'MD_SALER',    5,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210536, 'PP_RECORD', 'pp_record', 'cust_id',    '客户',     'ref',    'ref',      1, 0, 'MD_CUSTOMER', 6,  '业务信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210537, 'PP_RECORD', 'pp_record', 'is_closed',  '是否关闭', 'bool',   'checkbox', 0, 1, 7,  '状态信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210538, 'PP_RECORD', 'pp_record', 'is_cancel',  '是否取消', 'bool',   'checkbox', 0, 1, 8,  '状态信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210539, 'PP_RECORD', 'pp_record', 'remark',     '备注',     'text',   'textarea', 0, 0, 9,  '其他');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210540, 'PP_RECORD', 'pp_record', 'auditor',    '审核人',   'ref',    'ref',      0, 1, 'MD_EMPLOYEE', 10, '审计信息');
-- 子表 pp_record_detail / detail（5 字段，link_field=record_id）
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210541, 'PP_RECORD', 'detail', 'sort_index',      '行号',       'number', 'number',   0, 0, 1, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) VALUES (210542, 'PP_RECORD', 'detail', 'record_id',       '打样记录',   'ref',    'ref',      1, 1, 'PP_RECORD',   2, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210543, 'PP_RECORD', 'detail', 'sample_color_no', '样品色号',   'text',   'text',     0, 0, 3, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210544, 'PP_RECORD', 'detail', 'is_confirm',      '是否确认',   'bool',   'checkbox', 0, 0, 4, '明细信息');
REPLACE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) VALUES (210545, 'PP_RECORD', 'detail', 'remark',          '备注',       'text',   'textarea', 0, 0, 5, '明细信息');