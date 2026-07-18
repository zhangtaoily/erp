-- ============================================================
-- EERP H2 SYSMSG (系统管理 + 消息与通知) 元数据种子
-- ============================================================
-- 用途：集成测试 H2 内存数据库系统管理与消息通知模块元数据种子（Phase 4）。
--       为 8 个 bo_code 注册业务对象、表单实体层级（主/子）与关键字段
--       元数据，驱动 GenericBillService → GenericOperationService 的 6 阶段
--       流水线，无需具体 Entity/Mapper。
-- 加载：spring.sql.init.data-locations 追加本文件，或测试用 @Sql 注解加载。
-- 幂等：全部使用 MERGE INTO ... KEY(id) VALUES (...)，可重复执行。
-- ID 约定（与 data-h2-master-seed.sql / data-h2-scm-seed.sql 等不冲突）：
--   meta_business_object  220001-220008   (8 行)
--   meta_state_machine    无               (全部主数据，无状态机)
--   meta_state_node       无
--   meta_state_transition 无
--   meta_form_entity      220500-220508   (8 主 + 1 子 = 9 行)
--   meta_form_field       260300-260386   (87 行)
-- 主数据约定：bo_type='master', is_stateful=0, is_pushable=0,
--             is_printable=0, pk_strategy='snowflake', status=1
-- 判定依据：8 张表均无 pact_state 字段 → 全部为主数据（无状态机）。
--           sys_notice 有子表 sys_notice_read（link_field=notice_id）。
-- 兼容：H2 MODE=MySQL；时间戳使用 CURRENT_TIMESTAMP；布尔值统一用 1/0。
-- 依赖：schema-h2.sql（元数据表结构 + 系统管理物理表）；
--       data-h2-seed.sql（STD_5STATE 及测试主数据）；
--       data-h2-master-seed.sql（30 个主数据 bo_code）。
-- ============================================================


-- ============================================================
-- 1. 业务对象定义（meta_business_object）—— 8 个系统管理/消息 BO
--    全部为主数据：bo_type='master', is_stateful=0
-- ============================================================

MERGE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
KEY(id) VALUES (220001, 'SYS_PARAM',      '系统参数', 'master', 'sys_param',      'param_code', 'snowflake', 0, 0, 0, NULL, 1, '系统参数配置',     'system', CURRENT_TIMESTAMP);
MERGE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
KEY(id) VALUES (220002, 'SYS_NOTICE',     '公告',     'master', 'sys_notice',     'notice_id',  'snowflake', 0, 0, 0, NULL, 1, '公告管理',         'system', CURRENT_TIMESTAMP);
MERGE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
KEY(id) VALUES (220003, 'SYS_BACKUP',     '数据备份', 'master', 'sys_backup',     'backup_id',  'snowflake', 0, 0, 0, NULL, 1, '数据备份记录',     'system', CURRENT_TIMESTAMP);
MERGE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
KEY(id) VALUES (220004, 'SYS_IMPORT_TASK','导入任务', 'master', 'sys_import_task','id',         'snowflake', 0, 0, 0, NULL, 1, '批量导入任务',     'system', CURRENT_TIMESTAMP);
MERGE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
KEY(id) VALUES (220005, 'ALERT_RULE',     '预警规则', 'master', 'sys_alert_rule', 'rule_code',  'snowflake', 0, 0, 0, NULL, 1, '预警规则配置',     'system', CURRENT_TIMESTAMP);
MERGE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
KEY(id) VALUES (220006, 'ALERT_RECORD',   '预警记录', 'master', 'sys_alert_log',  'alert_id',   'snowflake', 0, 0, 0, NULL, 1, '预警触发记录',     'system', CURRENT_TIMESTAMP);
MERGE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
KEY(id) VALUES (220007, 'INBOX_MSG',      '站内信',   'master', 'sys_message',    'message_id', 'snowflake', 0, 0, 0, NULL, 1, '站内消息',         'system', CURRENT_TIMESTAMP);
MERGE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
KEY(id) VALUES (220008, 'EMAIL_LOG',      '邮件日志', 'master', 'sys_mail_log',   'mail_id',    'snowflake', 0, 0, 0, NULL, 1, '邮件发送日志',     'system', CURRENT_TIMESTAMP);


-- ============================================================
-- 2. 状态机定义（meta_state_machine）—— 无
--    8 张表均无 pact_state 字段，全部为主数据，不注册状态机。
-- ============================================================


-- ============================================================
-- 3. 表单实体层级（meta_form_entity）—— 8 主 + 1 子 = 9 行
--    主实体 entity_code = main_table；子实体 entity_code 按业务命名
-- ============================================================

-- 3.1 主实体（entity_type='main', entity_level=0）—— 8 行
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (220500, 'SYS_PARAM',      'sys_param',       '系统参数', 'main', 0, 'sys_param',       NULL, NULL, 1);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (220501, 'SYS_NOTICE',     'sys_notice',      '公告',     'main', 0, 'sys_notice',      NULL, NULL, 1);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (220503, 'SYS_BACKUP',     'sys_backup',      '数据备份', 'main', 0, 'sys_backup',      NULL, NULL, 1);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (220504, 'SYS_IMPORT_TASK','sys_import_task', '导入任务', 'main', 0, 'sys_import_task', NULL, NULL, 1);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (220505, 'ALERT_RULE',     'sys_alert_rule',  '预警规则', 'main', 0, 'sys_alert_rule',  NULL, NULL, 1);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (220506, 'ALERT_RECORD',   'sys_alert_log',   '预警记录', 'main', 0, 'sys_alert_log',   NULL, NULL, 1);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (220507, 'INBOX_MSG',      'sys_message',     '站内信',   'main', 0, 'sys_message',     NULL, NULL, 1);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (220508, 'EMAIL_LOG',      'sys_mail_log',    '邮件日志', 'main', 0, 'sys_mail_log',    NULL, NULL, 1);

-- 3.2 子实体（entity_type='sub', entity_level=1）—— 1 行，SYS_NOTICE 阅读记录
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (220502, 'SYS_NOTICE', 'read', '公告阅读记录', 'sub', 1, 'sys_notice_read', 'sys_notice', 'notice_id', 2);


-- ============================================================
-- 4. 表单字段元数据（meta_form_field）—— 87 行
--    仅注册关键字段（主键/编码/状态 + 业务字段 + 审计字段）
--    字段类型：text/number/date/datetime/enum/bool
--    控件类型：text/textarea/number/date/datetime/select/checkbox
--    ID 区间 260300-260386
-- ============================================================

-- ------------------------------------------------------------
-- 4.1 SYS_PARAM 系统参数（sys_param，10 字段）
-- ------------------------------------------------------------
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260300, 'SYS_PARAM', 'sys_param', 'param_code',    '参数编码', 'text',     'text',     1, 1, 1,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260301, 'SYS_PARAM', 'sys_param', 'param_name',    '参数名称', 'text',     'text',     1, 0, 2,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260302, 'SYS_PARAM', 'sys_param', 'param_value',   '参数值',   'text',     'textarea', 0, 0, 3,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260303, 'SYS_PARAM', 'sys_param', 'param_type',    '参数类型', 'text',     'text',     0, 0, 4,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260304, 'SYS_PARAM', 'sys_param', 'param_group',   '参数分组', 'text',     'text',     0, 0, 5,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260305, 'SYS_PARAM', 'sys_param', 'default_value',  '默认值',   'text',     'textarea', 0, 0, 6,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260306, 'SYS_PARAM', 'sys_param', 'is_system',     '是否系统', 'bool',     'checkbox', 0, 1, 7,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260307, 'SYS_PARAM', 'sys_param', 'remark',        '备注',     'text',     'textarea', 0, 0, 8,  '其他');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260308, 'SYS_PARAM', 'sys_param', 'update_by',     '修改人',   'number',   'number',   0, 1, 9,  '审计信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260309, 'SYS_PARAM', 'sys_param', 'update_time',   '修改时间', 'datetime', 'datetime', 0, 1, 10, '审计信息');

-- ------------------------------------------------------------
-- 4.2 SYS_NOTICE 公告（sys_notice，10 字段）
-- ------------------------------------------------------------
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260310, 'SYS_NOTICE', 'sys_notice', 'notice_id',        '公告ID',   'number',   'number',   1, 1, 1,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260311, 'SYS_NOTICE', 'sys_notice', 'title',            '标题',     'text',     'text',     1, 0, 2,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260312, 'SYS_NOTICE', 'sys_notice', 'content',          '内容',     'text',     'textarea', 0, 0, 3,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260313, 'SYS_NOTICE', 'sys_notice', 'notice_type',      '公告类型', 'text',     'select',   0, 0, 4,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260314, 'SYS_NOTICE', 'sys_notice', 'publish_by',       '发布人',   'number',   'number',   0, 0, 5,  '发布信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260315, 'SYS_NOTICE', 'sys_notice', 'publish_time',     '发布时间', 'datetime', 'datetime', 0, 0, 6,  '发布信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260316, 'SYS_NOTICE', 'sys_notice', 'expire_time',      '过期时间', 'datetime', 'datetime', 0, 0, 7,  '发布信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260317, 'SYS_NOTICE', 'sys_notice', 'is_top',           '是否置顶', 'bool',     'checkbox', 0, 0, 8,  '发布信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260318, 'SYS_NOTICE', 'sys_notice', 'is_read_required', '需已读',   'bool',     'checkbox', 0, 0, 9,  '发布信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260319, 'SYS_NOTICE', 'sys_notice', 'status',           '状态',     'number',   'select',   0, 1, 10, '基本信息');

-- ------------------------------------------------------------
-- 4.3 SYS_NOTICE 子表 公告阅读记录（sys_notice_read，3 字段）
-- ------------------------------------------------------------
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260320, 'SYS_NOTICE', 'read', 'notice_id',  '公告ID', 'number',   'number',   1, 1, 1, '阅读信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260321, 'SYS_NOTICE', 'read', 'user_id',    '用户ID', 'number',   'number',   1, 0, 2, '阅读信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260322, 'SYS_NOTICE', 'read', 'read_time',  '阅读时间', 'datetime', 'datetime', 0, 0, 3, '阅读信息');

-- ------------------------------------------------------------
-- 4.4 SYS_BACKUP 数据备份（sys_backup，7 字段）
-- ------------------------------------------------------------
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260323, 'SYS_BACKUP', 'sys_backup', 'backup_id',    '备份ID',   'number',   'number',   1, 1, 1,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260324, 'SYS_BACKUP', 'sys_backup', 'backup_type',  '备份类型', 'text',     'select',   1, 0, 2,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260325, 'SYS_BACKUP', 'sys_backup', 'backup_time',  '备份时间', 'datetime', 'datetime', 0, 0, 3,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260326, 'SYS_BACKUP', 'sys_backup', 'file_path',    '文件路径', 'text',     'text',     0, 0, 4,  '文件信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260327, 'SYS_BACKUP', 'sys_backup', 'file_size',    '文件大小', 'number',   'number',   0, 0, 5,  '文件信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260328, 'SYS_BACKUP', 'sys_backup', 'status',       '状态',     'text',     'select',   0, 0, 6,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260329, 'SYS_BACKUP', 'sys_backup', 'operator',     '操作人',   'text',     'text',     0, 0, 7,  '审计信息');

-- ------------------------------------------------------------
-- 4.5 SYS_IMPORT_TASK 导入任务（sys_import_task，13 字段）
-- ------------------------------------------------------------
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260330, 'SYS_IMPORT_TASK', 'sys_import_task', 'task_code',     '任务编码', 'text',     'text',     0, 0, 1,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260331, 'SYS_IMPORT_TASK', 'sys_import_task', 'bo_code',       '业务对象', 'text',     'text',     1, 0, 2,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260332, 'SYS_IMPORT_TASK', 'sys_import_task', 'template_name', '模板名称', 'text',     'text',     0, 0, 3,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260333, 'SYS_IMPORT_TASK', 'sys_import_task', 'file_name',     '文件名',   'text',     'text',     0, 0, 4,  '文件信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260334, 'SYS_IMPORT_TASK', 'sys_import_task', 'file_path',     '文件路径', 'text',     'text',     0, 0, 5,  '文件信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260335, 'SYS_IMPORT_TASK', 'sys_import_task', 'total_count',   '总数',     'number',   'number',   0, 0, 6,  '进度信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260336, 'SYS_IMPORT_TASK', 'sys_import_task', 'success_count', '成功数',   'number',   'number',   0, 0, 7,  '进度信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260337, 'SYS_IMPORT_TASK', 'sys_import_task', 'fail_count',    '失败数',   'number',   'number',   0, 0, 8,  '进度信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260338, 'SYS_IMPORT_TASK', 'sys_import_task', 'status',        '状态',     'text',     'select',   0, 0, 9,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260339, 'SYS_IMPORT_TASK', 'sys_import_task', 'error_log',     '错误日志', 'text',     'textarea', 0, 0, 10, '文件信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260340, 'SYS_IMPORT_TASK', 'sys_import_task', 'import_by',     '导入人',   'text',     'text',     0, 0, 11, '审计信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260341, 'SYS_IMPORT_TASK', 'sys_import_task', 'import_time',   '导入时间', 'datetime', 'datetime', 0, 0, 12, '审计信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260342, 'SYS_IMPORT_TASK', 'sys_import_task', 'finish_time',   '完成时间', 'datetime', 'datetime', 0, 0, 13, '审计信息');

-- ------------------------------------------------------------
-- 4.6 ALERT_RULE 预警规则（sys_alert_rule，10 字段）
-- ------------------------------------------------------------
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260343, 'ALERT_RULE', 'sys_alert_rule', 'rule_code',      '规则编码', 'text',     'text',     1, 1, 1,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260344, 'ALERT_RULE', 'sys_alert_rule', 'rule_name',      '规则名称', 'text',     'text',     1, 0, 2,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260345, 'ALERT_RULE', 'sys_alert_rule', 'alert_type',     '预警类型', 'text',     'select',   0, 0, 3,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260346, 'ALERT_RULE', 'sys_alert_rule', 'target_object',  '目标对象', 'text',     'text',     0, 0, 4,  '监控配置');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260347, 'ALERT_RULE', 'sys_alert_rule', 'condition_expr', '条件表达式', 'text',   'textarea', 0, 0, 5,  '监控配置');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260348, 'ALERT_RULE', 'sys_alert_rule', 'check_cron',     '检查周期', 'text',     'text',     0, 0, 6,  '监控配置');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260349, 'ALERT_RULE', 'sys_alert_rule', 'notify_target',  '通知目标', 'text',     'text',     0, 0, 7,  '通知配置');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260350, 'ALERT_RULE', 'sys_alert_rule', 'notify_channel', '通知渠道', 'text',     'text',     0, 0, 8,  '通知配置');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260351, 'ALERT_RULE', 'sys_alert_rule', 'is_enabled',     '是否启用', 'bool',     'checkbox', 0, 0, 9,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260352, 'ALERT_RULE', 'sys_alert_rule', 'remark',         '备注',     'text',     'textarea', 0, 0, 10, '其他');

-- ------------------------------------------------------------
-- 4.7 ALERT_RECORD 预警记录（sys_alert_log，14 字段）
-- ------------------------------------------------------------
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260353, 'ALERT_RECORD', 'sys_alert_log', 'alert_id',       '预警ID',   'number',   'number',   1, 1, 1,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260354, 'ALERT_RECORD', 'sys_alert_log', 'rule_code',      '规则编码', 'text',     'text',     0, 0, 2,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260355, 'ALERT_RECORD', 'sys_alert_log', 'alert_type',     '预警类型', 'text',     'select',   0, 0, 3,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260356, 'ALERT_RECORD', 'sys_alert_log', 'target_id',      '目标ID',   'number',   'number',   0, 0, 4,  '目标信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260357, 'ALERT_RECORD', 'sys_alert_log', 'target_desc',    '目标描述', 'text',     'text',     0, 0, 5,  '目标信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260358, 'ALERT_RECORD', 'sys_alert_log', 'alert_content',  '预警内容', 'text',     'textarea', 0, 0, 6,  '预警信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260359, 'ALERT_RECORD', 'sys_alert_log', 'alert_time',     '预警时间', 'datetime', 'datetime', 0, 0, 7,  '预警信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260360, 'ALERT_RECORD', 'sys_alert_log', 'alert_level',    '预警级别', 'text',     'select',   0, 0, 8,  '预警信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260361, 'ALERT_RECORD', 'sys_alert_log', 'is_read',        '是否已读', 'bool',     'checkbox', 0, 0, 9,  '处理信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260362, 'ALERT_RECORD', 'sys_alert_log', 'is_handled',     '是否已处理', 'bool',   'checkbox', 0, 0, 10, '处理信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260363, 'ALERT_RECORD', 'sys_alert_log', 'handle_by',      '处理人',   'number',   'number',   0, 0, 11, '处理信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260364, 'ALERT_RECORD', 'sys_alert_log', 'handle_time',    '处理时间', 'datetime', 'datetime', 0, 0, 12, '处理信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260365, 'ALERT_RECORD', 'sys_alert_log', 'handle_remark',  '处理备注', 'text',     'textarea', 0, 0, 13, '处理信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260366, 'ALERT_RECORD', 'sys_alert_log', 'status',         '状态',     'text',     'select',   0, 0, 14, '基本信息');

-- ------------------------------------------------------------
-- 4.8 INBOX_MSG 站内信（sys_message，11 字段）
-- ------------------------------------------------------------
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260367, 'INBOX_MSG', 'sys_message', 'message_id',     '消息ID',   'number',   'number',   1, 1, 1,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260368, 'INBOX_MSG', 'sys_message', 'user_id',        '用户ID',   'number',   'number',   1, 0, 2,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260369, 'INBOX_MSG', 'sys_message', 'message_type',   '消息类型', 'text',     'select',   0, 0, 3,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260370, 'INBOX_MSG', 'sys_message', 'title',          '标题',     'text',     'text',     1, 0, 4,  '内容信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260371, 'INBOX_MSG', 'sys_message', 'content',        '内容',     'text',     'textarea', 0, 0, 5,  '内容信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260372, 'INBOX_MSG', 'sys_message', 'ref_bill_type',  '关联单据类型', 'text',   'text',     0, 0, 6,  '关联信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260373, 'INBOX_MSG', 'sys_message', 'ref_bill_id',    '关联单据ID', 'number',   'number',   0, 0, 7,  '关联信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260374, 'INBOX_MSG', 'sys_message', 'is_read',        '是否已读', 'bool',     'checkbox', 0, 0, 8,  '阅读信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260375, 'INBOX_MSG', 'sys_message', 'read_time',      '阅读时间', 'datetime', 'datetime', 0, 0, 9,  '阅读信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260376, 'INBOX_MSG', 'sys_message', 'create_time',    '创建时间', 'datetime', 'datetime', 0, 1, 10, '审计信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260377, 'INBOX_MSG', 'sys_message', 'expire_time',    '过期时间', 'datetime', 'datetime', 0, 0, 11, '审计信息');

-- ------------------------------------------------------------
-- 4.9 EMAIL_LOG 邮件日志（sys_mail_log，9 字段）
-- ------------------------------------------------------------
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260378, 'EMAIL_LOG', 'sys_mail_log', 'mail_id',        '邮件ID',   'number',   'number',   1, 1, 1,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260379, 'EMAIL_LOG', 'sys_mail_log', 'to_email',       '收件人',   'text',     'text',     1, 0, 2,  '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260380, 'EMAIL_LOG', 'sys_mail_log', 'subject',        '主题',     'text',     'text',     0, 0, 3,  '内容信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260381, 'EMAIL_LOG', 'sys_mail_log', 'content',        '内容',     'text',     'textarea', 0, 0, 4,  '内容信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260382, 'EMAIL_LOG', 'sys_mail_log', 'ref_bill_type',  '关联单据类型', 'text',   'text',     0, 0, 5,  '关联信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260383, 'EMAIL_LOG', 'sys_mail_log', 'ref_bill_id',    '关联单据ID', 'number',   'number',   0, 0, 6,  '关联信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260384, 'EMAIL_LOG', 'sys_mail_log', 'send_time',      '发送时间', 'datetime', 'datetime', 0, 0, 7,  '发送信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260385, 'EMAIL_LOG', 'sys_mail_log', 'send_status',    '发送状态', 'text',     'select',   0, 0, 8,  '发送信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (260386, 'EMAIL_LOG', 'sys_mail_log', 'error_msg',      '错误信息', 'text',     'textarea', 0, 0, 9,  '发送信息');


-- ============================================================
-- 文件末尾说明
-- ============================================================
-- ID 范围汇总：
--   meta_business_object  220001-220008   (8 行系统管理/消息 BO)
--   meta_state_machine    无              (全部主数据，无状态机)
--   meta_state_node       无
--   meta_state_transition 无
--   meta_form_entity      220500-220508   (9 行：8 主 + 1 子)
--   meta_form_field       260300-260386   (87 行关键字段)
-- 依赖关系：
--   1. schema-h2.sql 提供元数据表结构与系统管理物理表
--      （sys_param/sys_notice/sys_notice_read/sys_backup/sys_import_task/
--       sys_alert_rule/sys_alert_log/sys_message/sys_mail_log）。
--   2. data-h2-seed.sql 提供标准状态机 STD_5STATE 及测试主数据。
--   3. data-h2-master-seed.sql 提供 30 个主数据 bo_code。
-- 判定依据：8 张表均无 pact_state 字段 → 全部为主数据（bo_type='master',
--           is_stateful=0），不注册状态机。
-- 物理表主键差异（main_key）：
--   sys_param: param_code（varchar）  sys_notice: notice_id（bigint）
--   sys_backup: backup_id（bigint）   sys_import_task: id（bigint）
--   sys_alert_rule: rule_code（varchar） sys_alert_log: alert_id（bigint）
--   sys_message: message_id（bigint） sys_mail_log: mail_id（bigint）
-- 注意：BillDataAccessor 固化以 `id` 列为主键，仅 sys_import_task 可通过
--       BillController 端到端 CRUD；其余 7 表主键非 id，CRUD 测试通过
--       jdbcTemplate 直验物理表与元数据对齐。
-- 加载顺序建议：schema-h2.sql → data-h2-seed.sql → data-h2-master-seed.sql
--               → ... → 本文件。
-- ============================================================
