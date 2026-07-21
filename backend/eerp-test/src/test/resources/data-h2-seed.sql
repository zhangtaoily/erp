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


-- ============================================================
-- 3. 系统菜单（sys_menu）—— 前端侧边栏从此表动态加载
--    8 个一级目录 + 对应子菜单，与原 config/menu.ts 保持一致
-- ============================================================

-- 3.1 一级目录（menu_type='directory', parent_id=0）
INSERT INTO sys_menu (id, menu_code, menu_name, parent_id, menu_type, path, icon, sort_index, visible, status, remark) VALUES
  (3001, 'BOS_MODEL',     '业务对象建模', 0, 'directory', NULL, 'DataBoard',   1, 1, 1, 'BOS 建模相关'),
  (3002, 'BOS_FORM',      '表单与渲染',   0, 'directory', NULL, 'Document',    2, 1, 1, '表单设计/插件'),
  (3003, 'BOS_STATE',     '状态与操作',   0, 'directory', NULL, 'Switch',      3, 1, 1, '状态机/下推/按钮/打印'),
  (3004, 'BOS_LIST',      '列表与查询',   0, 'directory', NULL, 'Search',      4, 1, 1, '列表字段/查询方案'),
  (3005, 'BOS_RULE',      '编码与规则',   0, 'directory', NULL, 'SetUp',       5, 1, 1, '编码规则/实体规则/反写规则'),
  (3006, 'SYS_PERM',      '权限管理',     0, 'directory', NULL, 'Lock',        6, 1, 1, '用户/角色/部门/权限'),
  (3007, 'SYS_INTEGRATION','集成与附件',  0, 'directory', NULL, 'Connection',  7, 1, 1, '导入/导出/API日志/工作流'),
  (3008, 'BILL_RUNTIME',  '单据运行时',   0, 'directory', NULL, 'Files',       8, 1, 1, '单据列表与详情');

-- 3.2 业务对象建模子菜单
INSERT INTO sys_menu (id, menu_code, menu_name, parent_id, menu_type, path, icon, sort_index, visible, status) VALUES
  (3101, 'BOS_BUSINESS_OBJECT', '业务对象管理',  3001, 'menu', '/bos/business-object', NULL, 1, 1, 1),
  (3102, 'BOS_ENTITY_MODEL',    '实体与字段建模', 3001, 'menu', '/bos/entity-model',    NULL, 2, 1, 1),
  (3103, 'BOS_OBJECT_RELATION', '对象关系配置',   3001, 'menu', '/bos/object-relation', NULL, 3, 1, 1);

-- 3.3 表单与渲染子菜单
INSERT INTO sys_menu (id, menu_code, menu_name, parent_id, menu_type, path, icon, sort_index, visible, status) VALUES
  (3201, 'BOS_FORM_DESIGNER', '表单设计器',     3002, 'menu', '/bos/form-designer', NULL, 1, 1, 1),
  (3202, 'BOS_FORM_PLUGIN',   '表单插件配置',   3002, 'menu', '/bos/form-plugin',   NULL, 2, 1, 1);

-- 3.4 状态与操作子菜单
INSERT INTO sys_menu (id, menu_code, menu_name, parent_id, menu_type, path, icon, sort_index, visible, status) VALUES
  (3301, 'BOS_STATE_MACHINE',  '状态机配置',     3003, 'menu', '/bos/state-machine',  NULL, 1, 1, 1),
  (3302, 'BOS_PUSH_RULE',      '下推转换规则',   3003, 'menu', '/bos/push-rule',      NULL, 2, 1, 1),
  (3303, 'BOS_BUTTON_CONFIG',  '自定义按钮配置', 3003, 'menu', '/bos/button-config',  NULL, 3, 1, 1),
  (3304, 'BOS_PRINT_DESIGNER', '打印模板设计器', 3003, 'menu', '/bos/print-designer', NULL, 4, 1, 1);

-- 3.5 列表与查询子菜单
INSERT INTO sys_menu (id, menu_code, menu_name, parent_id, menu_type, path, icon, sort_index, visible, status) VALUES
  (3401, 'BOS_LIST_CONFIG',    '列表字段配置',   3004, 'menu', '/bos/list-config',    NULL, 1, 1, 1),
  (3402, 'BOS_QUERY_SCHEME',   '查询方案管理',   3004, 'menu', '/bos/query-scheme',   NULL, 2, 1, 1);

-- 3.6 编码与规则子菜单
INSERT INTO sys_menu (id, menu_code, menu_name, parent_id, menu_type, path, icon, sort_index, visible, status) VALUES
  (3501, 'BOS_CODE_RULE',      '编码规则配置',   3005, 'menu', '/bos/code-rule',      NULL, 1, 1, 1),
  (3502, 'BOS_ENTITY_RULE',    '实体服务规则',   3005, 'menu', '/bos/entity-rule',    NULL, 2, 1, 1),
  (3503, 'BOS_WRITEBACK_RULE', '反写规则配置',   3005, 'menu', '/bos/writeback-rule', NULL, 3, 1, 1);

-- 3.7 权限管理子菜单
INSERT INTO sys_menu (id, menu_code, menu_name, parent_id, menu_type, path, icon, sort_index, visible, status, remark) VALUES
  (3601, 'SYS_ORG',             '组织架构',         3006, 'menu', '/sys/org',             NULL, 1, 1, 1, NULL),
  (3602, 'SYS_USER',            '用户管理',         3006, 'menu', '/sys/user',            NULL, 2, 1, 1, NULL),
  (3603, 'SYS_ROLE',            '角色管理',         3006, 'menu', '/sys/role',            NULL, 3, 1, 1, NULL),
  (3604, 'SYS_DEPT',            '部门管理',         3006, 'menu', '/sys/dept',            NULL, 4, 1, 1, NULL),
  (3605, 'SYS_DATA_PERMISSION', '数据权限（行级）', 3006, 'menu', '/sys/data-permission', NULL, 5, 1, 1, NULL),
  (3606, 'SYS_FIELD_PERMISSION','字段权限（列级）', 3006, 'menu', '/sys/field-permission',NULL, 6, 1, 1, NULL),
  (3607, 'SYS_SECURITY',        '登录安全策略',     3006, 'menu', '/sys/security',        NULL, 7, 1, 1, NULL),
  (3608, 'SYS_MENU',            '菜单管理',         3006, 'menu', '/sys/menu',            NULL, 8, 1, 1, '系统菜单 CRUD');

-- 3.8 集成与附件子菜单
INSERT INTO sys_menu (id, menu_code, menu_name, parent_id, menu_type, path, icon, sort_index, visible, status) VALUES
  (3701, 'SYS_IMPORT_TASK',     '导入任务管理', 3007, 'menu', '/sys/import-task',     NULL, 1, 1, 1),
  (3702, 'SYS_IMPORT_TEMPLATE', '导入模板配置', 3007, 'menu', '/sys/import-template', NULL, 2, 1, 1),
  (3703, 'SYS_API_LOG',         'API 接口日志', 3007, 'menu', '/sys/api-log',         NULL, 3, 1, 1),
  (3704, 'SYS_WF_INSTANCE',     '工作流实例',   3007, 'menu', '/sys/wf-instance',     NULL, 4, 1, 1),
  (3705, 'SYS_STORAGE',         '附件存储配置', 3007, 'menu', '/sys/storage',         NULL, 5, 1, 1),
  (3706, 'SYS_API_AUTH',        'API 鉴权配置', 3007, 'menu', '/sys/api-auth',        NULL, 6, 1, 1);

-- 3.9 单据运行时子菜单
INSERT INTO sys_menu (id, menu_code, menu_name, parent_id, menu_type, path, icon, sort_index, visible, status) VALUES
  (3801, 'BILL_SAL_ORDER', '销售订单列表', 3008, 'menu', '/bill/sal_order', NULL, 1, 1, 1);

-- ============================================================
-- 3.10 业务模块一级目录（9 个业务模块）
--     采购管理 / 销售管理 / 供应链 / 财务会计 / 生产制造 /
--     税务管理 / 库存管理 / 基础数据 / 消息与通知
-- ============================================================
INSERT INTO sys_menu (id, menu_code, menu_name, parent_id, menu_type, path, icon, sort_index, visible, status, remark) VALUES
  (3009, 'MOD_PUR',     '采购管理',   0, 'directory', NULL, 'ShoppingCart', 11, 1, 1, '采购业务单据'),
  (3010, 'MOD_SAL',     '销售管理',   0, 'directory', NULL, 'Sell',         12, 1, 1, '销售业务单据'),
  (3011, 'MOD_SCM',     '供应链',     0, 'directory', NULL, 'Connection',   13, 1, 1, '供应链管理'),
  (3012, 'MOD_FIN',     '财务会计',   0, 'directory', NULL, 'Money',        14, 1, 1, '财务会计'),
  (3013, 'MOD_MFG',     '生产制造',   0, 'directory', NULL, 'Tools',        15, 1, 1, '生产制造'),
  (3014, 'MOD_TAX',     '税务管理',   0, 'directory', NULL, 'Tickets',      16, 1, 1, '税务管理'),
  (3015, 'MOD_INV',     '库存管理',   0, 'directory', NULL, 'Box',          17, 1, 1, '库存管理'),
  (3016, 'MOD_MASTER',  '基础数据',   0, 'directory', NULL, 'Files',        18, 1, 1, '基础主数据'),
  (3017, 'MOD_SYSMSG',  '消息与通知', 0, 'directory', NULL, 'Bell',         19, 1, 1, '系统消息与通知');

-- 3.11 采购管理子菜单（7 项 PUR_*）
INSERT INTO sys_menu (id, menu_code, menu_name, parent_id, menu_type, path, icon, sort_index, visible, status) VALUES
  (3901, 'PUR_APPLY',          '采购申请', 3009, 'menu', '/bill/pur_apply',          NULL, 1, 1, 1),
  (3902, 'PUR_CONT',           '采购合同', 3009, 'menu', '/bill/pur_cont',           NULL, 2, 1, 1),
  (3903, 'PUR_ORDER',          '采购订单', 3009, 'menu', '/bill/pur_order',          NULL, 3, 1, 1),
  (3904, 'PUR_RECEIVE_NOTICE', '收料通知', 3009, 'menu', '/bill/pur_receive_notice', NULL, 4, 1, 1),
  (3905, 'PUR_IN_STOCK',       '采购入库', 3009, 'menu', '/bill/pur_in_stock',       NULL, 5, 1, 1),
  (3906, 'PUR_RETURN',         '采购退料', 3009, 'menu', '/bill/pur_return',         NULL, 6, 1, 1),
  (3907, 'PUR_INVOICE',        '采购发票', 3009, 'menu', '/bill/pur_invoice',        NULL, 7, 1, 1);

-- 3.12 销售管理子菜单（11 项 SAL_* / PP_*）
INSERT INTO sys_menu (id, menu_code, menu_name, parent_id, menu_type, path, icon, sort_index, visible, status) VALUES
  (4001, 'SAL_INT_CONT',       '意向合同',   3010, 'menu', '/bill/sal_int_cont',       NULL, 1,  1, 1),
  (4002, 'SAL_QUOTE',          '销售报价',   3010, 'menu', '/bill/sal_quote',          NULL, 2,  1, 1),
  (4003, 'SAL_CONTRACT',       '销售合同',   3010, 'menu', '/bill/sal_contract',       NULL, 3,  1, 1),
  (4004, 'SAL_ORDER',          '销售订单',   3010, 'menu', '/bill/sal_order',          NULL, 4,  1, 1),
  (4005, 'SAL_DELIVERY_NOTICE','发货通知',   3010, 'menu', '/bill/sal_delivery_notice',NULL, 5,  1, 1),
  (4006, 'SAL_OUT_STOCK',      '销售出库',   3010, 'menu', '/bill/sal_out_stock',      NULL, 6,  1, 1),
  (4007, 'SAL_RETURN',         '销售退货',   3010, 'menu', '/bill/sal_return',         NULL, 7,  1, 1),
  (4008, 'SAL_RETURN_NOTICE',  '退货通知',   3010, 'menu', '/bill/sal_return_notice',  NULL, 8,  1, 1),
  (4009, 'SAL_INVOICE',        '销售发票',   3010, 'menu', '/bill/sal_invoice',        NULL, 9,  1, 1),
  (4010, 'PP_NOTICE',          '打样通知',   3010, 'menu', '/bill/pp_notice',          NULL, 10, 1, 1),
  (4011, 'PP_RECORD',          '打样记录',   3010, 'menu', '/bill/pp_record',          NULL, 11, 1, 1);

-- 3.13 供应链子菜单（暂无对应 BO，预留目录）
-- 无子菜单，后续按需补充物流/供应商评估等

-- 3.14 财务会计子菜单（14 项 FIN_*）
INSERT INTO sys_menu (id, menu_code, menu_name, parent_id, menu_type, path, icon, sort_index, visible, status) VALUES
  (4201, 'FIN_EST_AP',        '暂估应付',   3012, 'menu', '/bill/fin_est_ap',        NULL, 1,  1, 1),
  (4202, 'FIN_AR',            '应收单',     3012, 'menu', '/bill/fin_ar',            NULL, 2,  1, 1),
  (4203, 'FIN_AP',            '应付单',     3012, 'menu', '/bill/fin_ap',            NULL, 3,  1, 1),
  (4204, 'FIN_RECEIPT',       '收款单',     3012, 'menu', '/bill/fin_receipt',       NULL, 4,  1, 1),
  (4205, 'FIN_PAYMENT',       '付款单',     3012, 'menu', '/bill/fin_payment',       NULL, 5,  1, 1),
  (4206, 'FIN_WRITEOFF',      '核销单',     3012, 'menu', '/bill/fin_writeoff',      NULL, 6,  1, 1),
  (4207, 'FIN_CUST_RECEIPT',  '客户回款',   3012, 'menu', '/bill/fin_cust_receipt',  NULL, 7,  1, 1),
  (4208, 'FIN_ACCOUNT',       '会计科目',   3012, 'menu', '/bill/fin_account',       NULL, 8,  1, 1),
  (4209, 'FIN_PERIOD',        '会计期间',   3012, 'menu', '/bill/fin_period',        NULL, 9,  1, 1),
  (4210, 'FIN_VOUCHER_TPL',   '凭证模板',   3012, 'menu', '/bill/fin_voucher_tpl',   NULL, 10, 1, 1),
  (4211, 'FIN_VOUCHER',       '凭证',       3012, 'menu', '/bill/fin_voucher',       NULL, 11, 1, 1),
  (4212, 'FIN_COST_COLLECT',  '成本归集',   3012, 'menu', '/bill/fin_cost_collect',  NULL, 12, 1, 1),
  (4213, 'FIN_COST_POOL',     '制造费用池', 3012, 'menu', '/bill/fin_cost_pool',     NULL, 13, 1, 1),
  (4214, 'FIN_COST_VARIANCE', '成本差异',   3012, 'menu', '/bill/fin_cost_variance', NULL, 14, 1, 1);

-- 3.15 生产制造子菜单（8 项 MFG_*）
INSERT INTO sys_menu (id, menu_code, menu_name, parent_id, menu_type, path, icon, sort_index, visible, status) VALUES
  (4301, 'MFG_BOM',       'BOM配方',    3013, 'menu', '/bill/mfg_bom',       NULL, 1, 1, 1),
  (4302, 'MFG_ROUTE',     '工艺路线',   3013, 'menu', '/bill/mfg_route',     NULL, 2, 1, 1),
  (4303, 'MFG_NOTICE',    '生产通知单', 3013, 'menu', '/bill/mfg_notice',    NULL, 3, 1, 1),
  (4304, 'MFG_ORDER',     '生产订单',   3013, 'menu', '/bill/mfg_order',     NULL, 4, 1, 1),
  (4305, 'MFG_PICK',      '领料单',     3013, 'menu', '/bill/mfg_pick',      NULL, 5, 1, 1),
  (4306, 'MFG_IN_STOCK',  '生产入库',   3013, 'menu', '/bill/mfg_in_stock',  NULL, 6, 1, 1),
  (4307, 'MFG_MRP_PLAN',  'MRP计划',    3013, 'menu', '/bill/mfg_mrp_plan',  NULL, 7, 1, 1),
  (4308, 'MFG_OUTSOURCE', '外协订单',   3013, 'menu', '/bill/mfg_outsource', NULL, 8, 1, 1);

-- 3.16 税务管理子菜单（3 项 TAX_*）
INSERT INTO sys_menu (id, menu_code, menu_name, parent_id, menu_type, path, icon, sort_index, visible, status) VALUES
  (4401, 'TAX_RATE',    '税率配置', 3014, 'menu', '/bill/tax_rate',    NULL, 1, 1, 1),
  (4402, 'TAX_PROVIDE', '税务计提', 3014, 'menu', '/bill/tax_provide', NULL, 2, 1, 1),
  (4403, 'TAX_DECLARE', '纳税申报', 3014, 'menu', '/bill/tax_declare', NULL, 3, 1, 1);

-- 3.17 库存管理子菜单（9 项 INV_*）
INSERT INTO sys_menu (id, menu_code, menu_name, parent_id, menu_type, path, icon, sort_index, visible, status) VALUES
  (4501, 'INV_STOCK',      '即时库存',   3015, 'menu', '/bill/inv_stock',      NULL, 1, 1, 1),
  (4502, 'INV_BATCH',      '批次台账',   3015, 'menu', '/bill/inv_batch',      NULL, 2, 1, 1),
  (4503, 'INV_STOCKTAKE',  '盘点单',     3015, 'menu', '/bill/inv_stocktake',  NULL, 3, 1, 1),
  (4504, 'INV_TRANSFER',   '调拨单',     3015, 'menu', '/bill/inv_transfer',   NULL, 4, 1, 1),
  (4505, 'INV_FORM_CONV',  '形态转换',   3015, 'menu', '/bill/inv_form_conv',  NULL, 5, 1, 1),
  (4506, 'INV_OTHER_IN',   '其他入库',   3015, 'menu', '/bill/inv_other_in',   NULL, 6, 1, 1),
  (4507, 'INV_OTHER_OUT',  '其他出库',   3015, 'menu', '/bill/inv_other_out',  NULL, 7, 1, 1),
  (4508, 'INV_LOCK',       '锁库单',     3015, 'menu', '/bill/inv_lock',       NULL, 8, 1, 1),
  (4509, 'INV_LOCK_APPLY', '锁库申请',   3015, 'menu', '/bill/inv_lock_apply', NULL, 9, 1, 1);

-- 3.18 基础数据子菜单（29 项 MD_*）
INSERT INTO sys_menu (id, menu_code, menu_name, parent_id, menu_type, path, icon, sort_index, visible, status) VALUES
  (4601, 'MD_ORG',                 '组织',         3016, 'menu', '/master/md_org',                 NULL, 1,  1, 1),
  (4602, 'MD_DEPT',                '部门',         3016, 'menu', '/master/md_dept',                NULL, 2,  1, 1),
  (4603, 'MD_EMPLOYEE',            '员工',         3016, 'menu', '/master/md_employee',            NULL, 3,  1, 1),
  (4604, 'MD_SALER',               '业务员',       3016, 'menu', '/master/md_saler',               NULL, 4,  1, 1),
  (4605, 'MD_MERCHANDISER',        '跟单员',       3016, 'menu', '/master/md_merchandiser',        NULL, 5,  1, 1),
  (4606, 'MD_CUSTOMER',            '客户',         3016, 'menu', '/master/md_customer',            NULL, 6,  1, 1),
  (4607, 'MD_SUPPLIER',            '供应商',       3016, 'menu', '/master/md_supplier',            NULL, 7,  1, 1),
  (4608, 'MD_MATERIAL',            '物料',         3016, 'menu', '/master/md_material',            NULL, 8,  1, 1),
  (4609, 'MD_MATERIAL_GROUP',      '物料分组',     3016, 'menu', '/master/md_material_group',      NULL, 9,  1, 1),
  (4610, 'MD_RAW_MATERIAL',        '原料',         3016, 'menu', '/master/md_raw_material',        NULL, 10, 1, 1),
  (4611, 'MD_RAW_MATERIAL_GROUP',  '原料分组',     3016, 'menu', '/master/md_raw_material_group',  NULL, 11, 1, 1),
  (4612, 'MD_CURRENCY',            '币别',         3016, 'menu', '/master/md_currency',            NULL, 12, 1, 1),
  (4613, 'MD_EXCHANGE_RATE',       '汇率',         3016, 'menu', '/master/md_exchange_rate',       NULL, 13, 1, 1),
  (4614, 'MD_WAREHOUSE',           '仓库',         3016, 'menu', '/master/md_warehouse',           NULL, 14, 1, 1),
  (4615, 'MD_BIN',                 '仓位',         3016, 'menu', '/master/md_bin',                 NULL, 15, 1, 1),
  (4616, 'MD_UNIT',                '计量单位',     3016, 'menu', '/master/md_unit',                NULL, 16, 1, 1),
  (4617, 'MD_BRAND',               '品牌',         3016, 'menu', '/master/md_brand',               NULL, 17, 1, 1),
  (4618, 'MD_COLOR_SERIES',        '色系',         3016, 'menu', '/master/md_color_series',        NULL, 18, 1, 1),
  (4619, 'MD_COMP_COLOR',          '公司色号',     3016, 'menu', '/master/md_comp_color',          NULL, 19, 1, 1),
  (4620, 'MD_PRINT_COLOR',         '打版色号',     3016, 'menu', '/master/md_print_color',         NULL, 20, 1, 1),
  (4621, 'MD_HL_CARD',             '集锦卡',       3016, 'menu', '/master/md_hl_card',             NULL, 21, 1, 1),
  (4622, 'MD_TRADE_TYPE',          '贸易类型',     3016, 'menu', '/master/md_trade_type',          NULL, 22, 1, 1),
  (4623, 'MD_PORT',                '港口',         3016, 'menu', '/master/md_port',                NULL, 23, 1, 1),
  (4624, 'MD_SEAL',                '印章',         3016, 'menu', '/master/md_seal',                NULL, 24, 1, 1),
  (4625, 'MD_BOX_LABEL_TPL',       '箱贴模板',     3016, 'menu', '/master/md_box_label_tpl',       NULL, 25, 1, 1),
  (4626, 'MD_QUALITY_STD',         '质量标准',     3016, 'menu', '/master/md_quality_std',         NULL, 26, 1, 1),
  (4627, 'MD_SETTLE_TYPE',         '结算方式',     3016, 'menu', '/master/md_settle_type',         NULL, 27, 1, 1),
  (4628, 'MD_SPIN_FEE',            '特殊纺工费',   3016, 'menu', '/master/md_spin_fee',            NULL, 28, 1, 1),
  (4629, 'MD_CREDIT',              '信用管理',     3016, 'menu', '/master/md_credit',              NULL, 29, 1, 1);

-- 3.19 消息与通知子菜单（7 项 SYSMSG BO；SYS_IMPORT_TASK 已在集成与附件模块）
INSERT INTO sys_menu (id, menu_code, menu_name, parent_id, menu_type, path, icon, sort_index, visible, status) VALUES
  (4701, 'SYS_PARAM',      '系统参数',   3017, 'menu', '/master/sys_param',      NULL, 1, 1, 1),
  (4702, 'SYS_NOTICE',     '公告',       3017, 'menu', '/master/sys_notice',     NULL, 2, 1, 1),
  (4703, 'SYS_BACKUP',     '数据备份',   3017, 'menu', '/master/sys_backup',     NULL, 3, 1, 1),
  (4705, 'ALERT_RULE',     '预警规则',   3017, 'menu', '/master/alert_rule',     NULL, 4, 1, 1),
  (4706, 'ALERT_RECORD',   '预警记录',   3017, 'menu', '/master/alert_record',   NULL, 5, 1, 1),
  (4707, 'INBOX_MSG',      '站内信',     3017, 'menu', '/master/inbox_msg',      NULL, 6, 1, 1),
  (4708, 'EMAIL_LOG',      '邮件日志',   3017, 'menu', '/master/email_log',      NULL, 7, 1, 1);
