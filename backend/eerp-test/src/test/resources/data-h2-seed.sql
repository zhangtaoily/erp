-- ============================================================
-- EERP H2 Test Seed Data
-- ============================================================
-- 用途：集成测试 H2 内存数据库种子数据（application-test.yml 中
--       spring.sql.init.data-locations 指向本文件）
-- 来源：1) 平台元数据 —— 转换自 表结构/V1.1.0__seed_operation.sql
--           （15 标准按钮 + 1 状态机 + 5 状态节点 + 17 条状态流转）
--       2) 测试主数据 —— 组织/部门/员工/用户/客户/供应商/物料/币别/仓库/单位
-- 兼容：H2 MODE=MySQL；tinyint 已转换为 SMALLINT，布尔值统一用 1/0
--       （不使用 TRUE/FALSE）；标识符不带反引号；使用普通 INSERT
--       （H2 内存库每次测试重建，无需 MERGE/IGNORE 幂等处理）
-- ============================================================


-- ============================================================
-- 1. 平台元数据种子（标准按钮 + 状态机 + 状态节点 + 17 条状态流转）
--    转换自 V1.1.0__seed_operation.sql（INSERT IGNORE → INSERT）
-- ============================================================

-- ------------------------------------------------------------
-- 1.1 15 个标准按钮（meta_button）
--     位置：form 表单 / list 列表 / both 均显示
-- ------------------------------------------------------------
INSERT INTO meta_button (id, button_code, button_name, button_type, icon, location, exec_order, remark) VALUES
  (1,  'add',    '新增',   'standard', 'plus',         'list', 1,  '新增单据'),
  (2,  'copy',   '复制',   'standard', 'copy',         'list', 2,  '复制现有单据生成新单'),
  (3,  'draft',  '暂存',   'standard', 'document',     'form', 3,  '保存为暂存状态（pact_state=0）'),
  (4,  'save',   '保存',   'standard', 'check',        'form', 4,  '保存单据（0→1）'),
  (5,  'submit', '提交',   'standard', 'promotion',    'form', 5,  '提交审核（1→2，触发工作流）'),
  (6,  'audit',  '审核',   'standard', 'circle-check', 'form', 6,  '审核通过（2→3）'),
  (7,  'revoke', '撤销',   'standard', 'refresh-left', 'form', 7,  '反提交（2→1）或反审核（3→1）'),
  (8,  'reject', '驳回',   'standard', 'close',        'form', 8,  '驳回（2→4，需填原因）'),
  (9,  'delete', '删除',   'standard', 'delete',       'both', 9,  '删除单据（0/1/4→-1）'),
  (10, 'close',  '关闭',   'standard', 'lock',         'form', 10, '关闭单据（is_closed=1）'),
  (11, 'cancel', '取消',   'standard', 'circle-close', 'form', 11, '取消单据（is_cancel=1，需填原因）'),
  (12, 'change', '变更',   'standard', 'edit',         'form', 12, '变更已审核单据（生成变更单，需填原因）'),
  (13, 'push',   '下推',   'standard', 'bottom-right', 'form', 13, '下推生成目标单据'),
  (14, 'trace',  '联查',   'standard', 'view',         'form', 14, '单据上下游追溯'),
  (15, 'print',  '打印',   'standard', 'printer',      'form', 15, '打印单据');

-- ------------------------------------------------------------
-- 1.2 标准状态机定义（meta_state_machine）
--     编码 STD_5STATE，状态字段 pact_state
-- ------------------------------------------------------------
INSERT INTO meta_state_machine (id, code, name, state_field, remark) VALUES
  (100, 'STD_5STATE', '标准5状态机', 'pact_state', '0暂存/1已创建/2已提交/3已审核/4已驳回；关闭/取消用 is_closed/is_cancel 字段');

-- ------------------------------------------------------------
-- 1.3 5 个标准状态节点（meta_state_node）
--     0暂存（初始态）1已创建 2已提交 3已审核 4已驳回
-- ------------------------------------------------------------
INSERT INTO meta_state_node (id, machine_id, state_value, state_name, state_color, is_initial, is_final, is_editable, is_deletable, sort_index) VALUES
  (101, 100, 0, '暂存',   '#909399', 1, 0, 1, 1, 0),
  (102, 100, 1, '已创建', '#409EFF', 0, 0, 1, 1, 1),
  (103, 100, 2, '已提交', '#E6A23C', 0, 0, 0, 0, 2),
  (104, 100, 3, '已审核', '#67C23A', 0, 0, 0, 0, 3),
  (105, 100, 4, '已驳回', '#F56C6C', 0, 0, 1, 1, 4);

-- ------------------------------------------------------------
-- 1.4 17 条标准状态流转（meta_state_transition）
--     t1-t17 对齐设计文档 02 §5.1.3
--     关闭/取消 to_state=3（保持原状态），通过 post_action 设置 is_closed/is_cancel
--     删除 to_state=-1（特殊标记，由 OperationService 物理删除）
--     下推/变更 to_state=3（保持原状态）
--     注：pre_check 在源文件中均为 NULL，此处省略该列；post_action 仅 t12-t15 有值，分两段插入以避免显式 NULL
-- ------------------------------------------------------------
-- t1-t11 + t16-t17（无 post_action）
INSERT INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, need_wf, require_reason, sort_index) VALUES
  (200, 100, 0,  1, '保存',     'save',     0, 0, 1),
  (201, 100, 0,  0, '暂存',     'draft',    0, 0, 2),
  (202, 100, 1,  2, '提交',     'submit',   1, 0, 3),
  (203, 100, 2,  3, '审核',     'audit',    0, 0, 4),
  (204, 100, 2,  4, '驳回',     'reject',   0, 1, 5),
  (205, 100, 4,  2, '重新提交', 'resubmit', 1, 0, 6),
  (206, 100, 2,  1, '撤销',     'revoke',   0, 0, 7),
  (207, 100, 3,  1, '撤销',     'revoke',   0, 0, 8),
  (208, 100, 0, -1, '删除',     'delete',   0, 0, 9),
  (209, 100, 1, -1, '删除',     'delete',   0, 0, 10),
  (210, 100, 4, -1, '删除',     'delete',   0, 0, 11),
  (215, 100, 3,  3, '变更',     'change',   1, 1, 16),
  (216, 100, 3,  3, '下推',     'push',     0, 0, 17);

-- t12-t15（含 post_action：is_closed / is_cancel 标记）
INSERT INTO meta_state_transition (id, machine_id, from_state, to_state, action_name, button_code, post_action, need_wf, require_reason, sort_index) VALUES
  (211, 100, 3, 3, '关闭',   'close',  'is_closed=1', 0, 0, 12),
  (212, 100, 3, 3, '反关闭', 'close',  'is_closed=0', 0, 0, 13),
  (213, 100, 3, 3, '取消',   'cancel', 'is_cancel=1', 0, 1, 14),
  (214, 100, 3, 3, '反取消', 'cancel', 'is_cancel=0', 0, 0, 15);


-- ============================================================
-- 2. 测试主数据种子（集成测试最小数据集）
--    列名以 01-基础资料表.sql / 00-平台元数据表.sql 实际定义为准
--    审计字段（create_by/create_time/update_by/update_time）使用 'system' / CURRENT_TIMESTAMP
-- ============================================================

-- ------------------------------------------------------------
-- 2.1 组织（sys_org）
-- ------------------------------------------------------------
INSERT INTO sys_org (id, code, name, is_accounting, is_business, status, create_by, create_time, update_by, update_time) VALUES
  (1, 'TEST_ORG', '测试组织', 1, 1, 1, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP);

-- ------------------------------------------------------------
-- 2.2 部门（sys_dept）
-- ------------------------------------------------------------
INSERT INTO sys_dept (id, code, name, org_id, status) VALUES
  (1, 'TEST_DEPT',  '测试部门', 1, 1),
  (2, 'SALES_DEPT', '销售部',   1, 1);

-- ------------------------------------------------------------
-- 2.3 员工（sys_employee）
-- ------------------------------------------------------------
INSERT INTO sys_employee (id, code, name, org_id, dept_id, status, create_by, create_time, update_by, update_time) VALUES
  (1, 'EMP001', '管理员', 1, 1, 1, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP),
  (2, 'EMP002', '测试员', 1, 2, 1, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP);

-- ------------------------------------------------------------
-- 2.4 用户（sys_user）
-- ------------------------------------------------------------
INSERT INTO sys_user (id, username, password, real_name, emp_id, status, create_by, create_time, update_by, update_time) VALUES
  (1, 'admin', '$2a$10$test', '管理员', 1, 1, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP);

-- ------------------------------------------------------------
-- 2.5 客户（md_customer）
-- ------------------------------------------------------------
INSERT INTO md_customer (id, code, name, status, create_by, create_time, update_by, update_time) VALUES
  (1, 'CUST001', '测试客户',  1, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP),
  (2, 'CUST002', '测试客户2', 1, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP);

-- ------------------------------------------------------------
-- 2.6 供应商（md_supplier）
-- ------------------------------------------------------------
INSERT INTO md_supplier (id, code, name, status, create_by, create_time, update_by, update_time) VALUES
  (1, 'SUP001', '测试供应商',  1, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP),
  (2, 'SUP002', '测试供应商2', 1, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP);

-- ------------------------------------------------------------
-- 2.7 物料（md_material）
-- ------------------------------------------------------------
INSERT INTO md_material (id, code, name, mat_type, status, create_by, create_time, update_by, update_time) VALUES
  (1, 'MAT001', '测试物料-纱线', 'YARN',     1, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP),
  (2, 'MAT002', '测试物料-染料', 'DYE',      1, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP),
  (3, 'MAT003', '测试物料-成品', 'FINISHED', 1, 'system', CURRENT_TIMESTAMP, 'system', CURRENT_TIMESTAMP);

-- ------------------------------------------------------------
-- 2.8 币别（md_currency）
-- ------------------------------------------------------------
INSERT INTO md_currency (id, code, name, symbol, status) VALUES
  (1, 'CNY', '人民币', '¥', 1),
  (2, 'USD', '美元',   '$', 1);

-- ------------------------------------------------------------
-- 2.9 仓库（md_warehouse）
-- ------------------------------------------------------------
INSERT INTO md_warehouse (id, code, name, status) VALUES
  (1, 'WH001', '原料仓', 1),
  (2, 'WH002', '成品仓', 1);

-- ------------------------------------------------------------
-- 2.10 计量单位（md_unit）
-- ------------------------------------------------------------
INSERT INTO md_unit (id, code, name, unit_type, status) VALUES
  (1, 'KG',  '千克', 'WEIGHT', 1),
  (2, 'M',   '米',   'LENGTH', 1),
  (3, 'PCS', '个',   'COUNT',  1);
