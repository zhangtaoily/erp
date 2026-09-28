-- =====================================================================
-- V1.0.1__seed_meta.sql
-- 平台元数据种子数据：业务对象、表单实体、字段元数据、状态机、按钮
-- 对应表：meta_business_object / meta_form_entity / meta_form_field /
--        meta_state_machine / meta_state_node / meta_state_transition /
--        meta_button / meta_form_button
-- 字段严格对齐 00-平台元数据表.sql
-- 状态码约定：0暂存 1已创建 2已提交 3已审核 4已驳回
-- =====================================================================

-- ---------------------------------------------------------------------
-- 一、业务对象（meta_business_object）
-- ---------------------------------------------------------------------
INSERT INTO `meta_business_object` (`id`, `bo_code`, `bo_name`, `bo_type`, `main_table`, `main_key`, `pk_strategy`, `is_stateful`, `is_pushable`, `is_printable`, `org_type`, `status`, `remark`, `create_by`, `create_time`)
VALUES (1, 'SAL_ORDER', '销售订单', 'NORMAL', 'sal_order', 'id', 'snowflake', 1, 1, 1, 'group', 1, '销售订单业务对象（示例）', 'admin', '2026-07-15 00:00:00');

-- ---------------------------------------------------------------------
-- 二、表单实体（meta_form_entity）
-- 主实体：订单头
-- ---------------------------------------------------------------------
INSERT INTO `meta_form_entity` (`id`, `bo_code`, `entity_code`, `entity_name`, `entity_type`, `entity_level`, `table_name`, `parent_entity_code`, `link_field`, `sort_index`)
VALUES (1, 'SAL_ORDER', 'main', '订单头', 'MAIN', 0, 'sal_order', NULL, NULL, 1);

-- ---------------------------------------------------------------------
-- 三、字段元数据（meta_form_field）
-- field_code 即物理列名；data_type 为数据库类型；ref 类型字段填 ref_bo_code
-- ---------------------------------------------------------------------
INSERT INTO `meta_form_field` (`id`, `bo_code`, `entity_code`, `field_code`, `field_name`, `field_type`, `ctrl_type`, `data_type`, `is_required`, `is_system`, `ref_bo_code`, `sort_index`, `group_name`) VALUES
(1,  'SAL_ORDER', 'main', 'code',         '编码',     'text',     'text',     'varchar',    1, 1, NULL,           1,  '基本信息'),
(2,  'SAL_ORDER', 'main', 'pact_date',    '日期',     'date',     'date',     'date',       1, 0, NULL,           2,  '基本信息'),
(3,  'SAL_ORDER', 'main', 'pact_state',   '状态',     'enum',     'select',   'int',        1, 1, NULL,           3,  '基本信息'),
(4,  'SAL_ORDER', 'main', 'cust_id',      '客户',     'ref',      'ref',      'bigint',     1, 0, 'MD_CUSTOMER',  4,  '基本信息'),
(5,  'SAL_ORDER', 'main', 'saler_id',     '业务员',   'ref',      'ref',      'bigint',     0, 0, 'SYS_SALER',    5,  '基本信息'),
(6,  'SAL_ORDER', 'main', 'total_qty',    '总数量',   'qty',      'number',   'decimal',    0, 0, NULL,           6,  '汇总'),
(7,  'SAL_ORDER', 'main', 'total_amount', '总金额',   'amount',   'number',   'decimal',    0, 0, NULL,           7,  '汇总'),
(8,  'SAL_ORDER', 'main', 'remark',       '备注',     'text',     'textarea', 'mediumtext', 0, 0, NULL,           8,  '其他'),
(9,  'SAL_ORDER', 'main', 'auditor',      '审核人',   'text',     'text',     'varchar',    0, 1, NULL,           9,  '系统'),
(10, 'SAL_ORDER', 'main', 'audit_time',   '审核时间', 'datetime', 'datetime', 'datetime',   0, 1, NULL,           10, '系统');

-- ---------------------------------------------------------------------
-- 四、状态机定义（meta_state_machine）
-- 注：表结构无 bo_code 列，状态机通过 machine_id 与节点/流转关联
-- ---------------------------------------------------------------------
INSERT INTO `meta_state_machine` (`id`, `code`, `name`, `state_field`, `remark`)
VALUES (1, 'STD_5_STATE', '标准五态状态机', 'pact_state', '标准五态状态机：0暂存 1已创建 2已提交 3已审核 4已驳回');

-- ---------------------------------------------------------------------
-- 五、状态节点（meta_state_node）
-- ---------------------------------------------------------------------
INSERT INTO `meta_state_node` (`id`, `machine_id`, `state_value`, `state_name`, `state_color`, `is_initial`, `is_final`, `is_editable`, `is_deletable`, `sort_index`) VALUES
(1, 1, 0, '暂存',   '#909399', 1, 0, 1, 1, 1),
(2, 1, 1, '已创建', '#409EFF', 0, 0, 1, 1, 2),
(3, 1, 2, '已提交', '#E6A23C', 0, 0, 0, 0, 3),
(4, 1, 3, '已审核', '#67C23A', 0, 1, 0, 0, 4),
(5, 1, 4, '已驳回', '#F56C6C', 0, 0, 1, 0, 5);

-- ---------------------------------------------------------------------
-- 六、状态流转（meta_state_transition）
-- from_state/to_state 为 NULL 表示任意状态/不改变状态
-- ---------------------------------------------------------------------
INSERT INTO `meta_state_transition` (`id`, `machine_id`, `from_state`, `to_state`, `action_name`, `button_code`, `pre_check`, `post_action`, `need_wf`, `require_reason`, `sort_index`) VALUES
-- 保存 / 暂存
(1,  1, 0,    1,    '保存',   'save',   NULL, NULL, 0, 0, 1),
(2,  1, 0,    0,    '暂存',   'save',   NULL, NULL, 0, 0, 2),
(3,  1, 1,    1,    '保存',   'save',   NULL, NULL, 0, 0, 3),
-- 提交
(4,  1, 1,    2,    '提交',   'submit', NULL, NULL, 1, 0, 4),
-- 审核
(5,  1, 2,    3,    '审核',   'audit',  NULL, NULL, 0, 0, 5),
-- 驳回
(6,  1, 2,    4,    '驳回',   'reject', NULL, NULL, 0, 1, 6),
-- 撤销（反审核 / 反驳回）
(7,  1, 3,    1,    '反审核', 'revoke', NULL, NULL, 0, 0, 7),
(8,  1, 4,    1,    '反驳回', 'revoke', NULL, NULL, 0, 0, 8),
-- 删除
(9,  1, 0,    NULL, '删除',   'delete', NULL, NULL, 0, 1, 9),
(10, 1, 1,    NULL, '删除',   'delete', NULL, NULL, 0, 1, 10),
-- 关闭
(11, 1, 3,    3,    '关闭',   'close',  NULL, 'is_closed=1', 0, 0, 11),
-- 取消
(12, 1, 1,    NULL, '取消',   'cancel', NULL, 'is_cancel=1', 0, 0, 12),
(13, 1, 2,    NULL, '取消',   'cancel', NULL, 'is_cancel=1', 0, 0, 13),
(14, 1, 3,    3,    '取消',   'cancel', NULL, 'is_cancel=1', 0, 0, 14),
-- 变更
(15, 1, 3,    3,    '变更',   'change', NULL, 'generate_change_bill', 1, 1, 15),
-- 下推
(16, 1, 1,    1,    '下推',   'push',   'check_pushable_qty', NULL, 0, 0, 16),
(17, 1, 2,    2,    '下推',   'push',   'check_pushable_qty', NULL, 0, 0, 17),
(18, 1, 3,    3,    '下推',   'push',   'check_pushable_qty', NULL, 0, 0, 18),
-- 复制 / 打印 / 联查（无状态变化，任意状态可用）
(19, 1, NULL, NULL, '复制',   'copy',   NULL, NULL, 0, 0, 19),
(20, 1, NULL, NULL, '打印',   'print',  NULL, NULL, 0, 0, 20),
(21, 1, NULL, NULL, '联查',   'link',   NULL, NULL, 0, 0, 21);

-- ---------------------------------------------------------------------
-- 七、按钮定义（meta_button）
-- 15 个标准按钮
-- ---------------------------------------------------------------------
INSERT INTO `meta_button` (`id`, `button_code`, `button_name`, `button_type`, `location`, `exec_order`) VALUES
(1,  'add',     '新增', 'standard', 'list', 1),
(2,  'copy',    '复制', 'standard', 'form', 2),
(3,  'save',    '保存', 'standard', 'form', 3),
(4,  'submit',  '提交', 'standard', 'form', 4),
(5,  'audit',   '审核', 'standard', 'form', 5),
(6,  'reject',  '驳回', 'standard', 'form', 6),
(7,  'revoke',  '撤销', 'standard', 'form', 7),
(8,  'delete',  '删除', 'standard', 'both', 8),
(9,  'close',   '关闭', 'standard', 'form', 9),
(10, 'cancel',  '取消', 'standard', 'form', 10),
(11, 'change',  '变更', 'standard', 'form', 11),
(12, 'push',    '下推', 'standard', 'form', 12),
(13, 'link',    '联查', 'standard', 'both', 13),
(14, 'print',   '打印', 'standard', 'both', 14),
(15, 'export',  '导出', 'standard', 'list', 15);

-- ---------------------------------------------------------------------
-- 八、表单-按钮绑定（meta_form_button）
-- availability_json 存可用状态 JSON 数组，如 "[0,1]" 表示在暂存/已创建可用
-- ---------------------------------------------------------------------
INSERT INTO `meta_form_button` (`id`, `bo_code`, `button_code`, `availability_json`, `confirm_msg`, `sort_index`) VALUES
(1,  'SAL_ORDER', 'add',     '[0,1,2,3,4]', NULL,             1),
(2,  'SAL_ORDER', 'copy',    '[1,2,3,4]',   NULL,             2),
(3,  'SAL_ORDER', 'save',    '[0,1]',       NULL,             3),
(4,  'SAL_ORDER', 'submit',  '[1]',         NULL,             4),
(5,  'SAL_ORDER', 'audit',   '[2]',         NULL,             5),
(6,  'SAL_ORDER', 'reject',  '[2]',         '确认驳回该单据？', 6),
(7,  'SAL_ORDER', 'revoke',  '[3,4]',       '确认撤销该单据？', 7),
(8,  'SAL_ORDER', 'delete',  '[0,1]',       '确认删除该单据？', 8),
(9,  'SAL_ORDER', 'close',   '[3]',         '确认关闭该单据？', 9),
(10, 'SAL_ORDER', 'cancel',  '[1,2,3]',     '确认取消该单据？', 10),
(11, 'SAL_ORDER', 'change',  '[3]',         '确认发起变更？',   11),
(12, 'SAL_ORDER', 'push',    '[1,2,3]',     NULL,             12),
(13, 'SAL_ORDER', 'link',    '[0,1,2,3,4]', NULL,             13),
(14, 'SAL_ORDER', 'print',   '[0,1,2,3,4]', NULL,             14),
(15, 'SAL_ORDER', 'export',  '[0,1,2,3,4]', NULL,             15);
