-- ============================================================
-- EERP H2 Master Data Metadata Seed
-- ============================================================
-- 用途：集成测试 H2 内存数据库主数据元数据种子。
--       注册 30 个主数据业务对象（meta_business_object）及其表单
--       实体（meta_form_entity）与关键字段元数据（meta_form_field）。
-- 加载：spring.sql.init.data-locations 追加本文件，或测试用 @Sql 注解加载。
-- 幂等：全部使用 MERGE INTO ... KEY(id) VALUES (...)，可重复执行。
-- ID 约定：
--   meta_business_object  100001-100030  (30 行)
--   meta_form_entity      150001-150035  (30 MAIN + 5 SUB = 35 行)
--   meta_form_field       200001-200200  (200 行)
-- 主数据约定：bo_type='master', is_stateful=0, is_pushable=0,
--             is_printable=0, pk_strategy='snowflake', main_key='id', status=1
-- 兼容：H2 MODE=MySQL；时间戳使用 CURRENT_TIMESTAMP；布尔值统一用 1/0。
-- 依赖：sys_dict/sys_dict_item 表结构见 schema-h2-master-ext.sql
--       （注意：schema-h2.sql 中已有不同结构的 sys_dict，详见文件末尾说明）
-- ============================================================


-- ============================================================
-- 1. 业务对象定义（meta_business_object）—— 30 个主数据 BO
-- ============================================================

MERGE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
KEY(id) VALUES (100001, 'MD_ORG',                '组织',         'master', 'sys_org',                'id', 'snowflake', 0, 0, 0, NULL, 1, '组织架构',         'system', CURRENT_TIMESTAMP);
MERGE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
KEY(id) VALUES (100002, 'MD_DEPT',                '部门',         'master', 'sys_dept',               'id', 'snowflake', 0, 0, 0, NULL, 1, '部门管理',         'system', CURRENT_TIMESTAMP);
MERGE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
KEY(id) VALUES (100003, 'MD_EMPLOYEE',            '员工',         'master', 'sys_employee',           'id', 'snowflake', 0, 0, 0, NULL, 1, '员工档案',         'system', CURRENT_TIMESTAMP);
MERGE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
KEY(id) VALUES (100004, 'MD_SALER',               '业务员',       'master', 'sys_saler',              'id', 'snowflake', 0, 0, 0, NULL, 1, '业务员档案',       'system', CURRENT_TIMESTAMP);
MERGE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
KEY(id) VALUES (100005, 'MD_MERCHANDISER',        '跟单员',       'master', 'sys_merchandiser',        'id', 'snowflake', 0, 0, 0, NULL, 1, '跟单员档案',       'system', CURRENT_TIMESTAMP);
MERGE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
KEY(id) VALUES (100006, 'MD_CUSTOMER',            '客户',         'master', 'md_customer',            'id', 'snowflake', 0, 0, 0, NULL, 1, '客户档案',         'system', CURRENT_TIMESTAMP);
MERGE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
KEY(id) VALUES (100007, 'MD_SUPPLIER',            '供应商',       'master', 'md_supplier',            'id', 'snowflake', 0, 0, 0, NULL, 1, '供应商档案',       'system', CURRENT_TIMESTAMP);
MERGE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
KEY(id) VALUES (100008, 'MD_MATERIAL',            '物料',         'master', 'md_material',            'id', 'snowflake', 0, 0, 0, NULL, 1, '物料档案',         'system', CURRENT_TIMESTAMP);
MERGE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
KEY(id) VALUES (100009, 'MD_MATERIAL_GROUP',      '物料分组',     'master', 'md_material_group',      'id', 'snowflake', 0, 0, 0, NULL, 1, '物料分组',         'system', CURRENT_TIMESTAMP);
MERGE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
KEY(id) VALUES (100010, 'MD_RAW_MATERIAL',        '原料',         'master', 'md_raw_material',        'id', 'snowflake', 0, 0, 0, NULL, 1, '原料档案',         'system', CURRENT_TIMESTAMP);
MERGE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
KEY(id) VALUES (100011, 'MD_RAW_MATERIAL_GROUP',  '原料分组',     'master', 'md_raw_material_group',   'id', 'snowflake', 0, 0, 0, NULL, 1, '原料分组',         'system', CURRENT_TIMESTAMP);
MERGE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
KEY(id) VALUES (100012, 'MD_CURRENCY',            '币别',         'master', 'md_currency',            'id', 'snowflake', 0, 0, 0, NULL, 1, '币别档案',         'system', CURRENT_TIMESTAMP);
MERGE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
KEY(id) VALUES (100013, 'MD_EXCHANGE_RATE',      '汇率',         'master', 'md_exchange_rate',        'id', 'snowflake', 0, 0, 0, NULL, 1, '汇率档案',         'system', CURRENT_TIMESTAMP);
MERGE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
KEY(id) VALUES (100014, 'MD_WAREHOUSE',           '仓库',         'master', 'md_warehouse',            'id', 'snowflake', 0, 0, 0, NULL, 1, '仓库档案',         'system', CURRENT_TIMESTAMP);
MERGE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
KEY(id) VALUES (100015, 'MD_BIN',                 '仓位',         'master', 'md_position',             'id', 'snowflake', 0, 0, 0, NULL, 1, '仓位档案',         'system', CURRENT_TIMESTAMP);
MERGE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
KEY(id) VALUES (100016, 'MD_UNIT',                '计量单位',     'master', 'md_unit',                 'id', 'snowflake', 0, 0, 0, NULL, 1, '计量单位档案',     'system', CURRENT_TIMESTAMP);
MERGE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
KEY(id) VALUES (100017, 'MD_BRAND',               '品牌',         'master', 'md_brand',                'id', 'snowflake', 0, 0, 0, NULL, 1, '品牌档案',         'system', CURRENT_TIMESTAMP);
MERGE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
KEY(id) VALUES (100018, 'MD_COLOR_SERIES',        '色系',         'master', 'md_color_series',         'id', 'snowflake', 0, 0, 0, NULL, 1, '色系档案',         'system', CURRENT_TIMESTAMP);
MERGE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
KEY(id) VALUES (100019, 'MD_COMP_COLOR',          '公司色号',     'master', 'md_comp_color',           'id', 'snowflake', 0, 0, 0, NULL, 1, '公司色号档案',     'system', CURRENT_TIMESTAMP);
MERGE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
KEY(id) VALUES (100020, 'MD_PRINT_COLOR',         '打版色号',     'master', 'md_print_color',           'id', 'snowflake', 0, 0, 0, NULL, 1, '打版色号档案',     'system', CURRENT_TIMESTAMP);
MERGE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
KEY(id) VALUES (100021, 'MD_HL_CARD',             '集锦卡',       'master', 'md_hl_card',              'id', 'snowflake', 0, 0, 0, NULL, 1, '集锦卡档案',       'system', CURRENT_TIMESTAMP);
MERGE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
KEY(id) VALUES (100022, 'MD_TRADE_TYPE',          '贸易类型',     'master', 'md_trade_type',           'id', 'snowflake', 0, 0, 0, NULL, 1, '贸易类型档案',     'system', CURRENT_TIMESTAMP);
MERGE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
KEY(id) VALUES (100023, 'MD_PORT',                '港口',         'master', 'md_harbour',              'id', 'snowflake', 0, 0, 0, NULL, 1, '港口档案',         'system', CURRENT_TIMESTAMP);
MERGE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
KEY(id) VALUES (100024, 'MD_SEAL',                '印章',         'master', 'md_seal',                 'id', 'snowflake', 0, 0, 0, NULL, 1, '印章档案',         'system', CURRENT_TIMESTAMP);
MERGE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
KEY(id) VALUES (100025, 'MD_BOX_LABEL_TPL',      '箱贴模板',     'master', 'md_box_label_tpl',        'id', 'snowflake', 0, 0, 0, NULL, 1, '箱贴打印模板',     'system', CURRENT_TIMESTAMP);
MERGE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
KEY(id) VALUES (100026, 'MD_QUALITY_STD',         '质量标准',     'master', 'md_quality_std',          'id', 'snowflake', 0, 0, 0, NULL, 1, '质量标准档案',     'system', CURRENT_TIMESTAMP);
MERGE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
KEY(id) VALUES (100027, 'MD_SETTLE_TYPE',         '结算方式',     'master', 'md_firp_type',            'id', 'snowflake', 0, 0, 0, NULL, 1, '结算方式档案',     'system', CURRENT_TIMESTAMP);
MERGE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
KEY(id) VALUES (100028, 'MD_SPIN_FEE',            '特殊纺工费',   'master', 'md_spin_fee',             'id', 'snowflake', 0, 0, 0, NULL, 1, '特殊纺工费档案',   'system', CURRENT_TIMESTAMP);
MERGE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
KEY(id) VALUES (100029, 'MD_CREDIT',              '信用管理',     'master', 'md_credit',               'id', 'snowflake', 0, 0, 0, NULL, 1, '信用管理档案',     'system', CURRENT_TIMESTAMP);
MERGE INTO meta_business_object (id, bo_code, bo_name, bo_type, main_table, main_key, pk_strategy, is_stateful, is_pushable, is_printable, org_type, status, remark, create_by, create_time)
KEY(id) VALUES (100030, 'SYS_DICT',               '数据字典',     'master', 'sys_dict',                'id', 'snowflake', 0, 0, 0, NULL, 1, '系统数据字典',     'system', CURRENT_TIMESTAMP);


-- ============================================================
-- 2. 表单实体定义（meta_form_entity）—— 30 MAIN + 5 SUB = 35 行
--    约定：MAIN 实体 entity_code = main_table（与表名一致）
--          SUB 实体 entity_code 按业务命名（detail/material/raw_material/item）
-- ============================================================

-- 2.1 主实体（entity_type='main', entity_level=0）—— 30 行
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (150001, 'MD_ORG',                'sys_org',                '组织',         'main', 0, 'sys_org',                NULL, NULL, 1);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (150002, 'MD_DEPT',               'sys_dept',               '部门',         'main', 0, 'sys_dept',               NULL, NULL, 1);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (150003, 'MD_EMPLOYEE',           'sys_employee',           '员工',         'main', 0, 'sys_employee',           NULL, NULL, 1);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (150004, 'MD_SALER',              'sys_saler',              '业务员',       'main', 0, 'sys_saler',              NULL, NULL, 1);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (150005, 'MD_MERCHANDISER',       'sys_merchandiser',       '跟单员',       'main', 0, 'sys_merchandiser',       NULL, NULL, 1);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (150006, 'MD_CUSTOMER',           'md_customer',            '客户',         'main', 0, 'md_customer',            NULL, NULL, 1);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (150007, 'MD_SUPPLIER',           'md_supplier',            '供应商',       'main', 0, 'md_supplier',            NULL, NULL, 1);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (150008, 'MD_MATERIAL',           'md_material',            '物料',         'main', 0, 'md_material',            NULL, NULL, 1);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (150009, 'MD_MATERIAL_GROUP',     'md_material_group',      '物料分组',     'main', 0, 'md_material_group',      NULL, NULL, 1);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (150010, 'MD_RAW_MATERIAL',       'md_raw_material',        '原料',         'main', 0, 'md_raw_material',        NULL, NULL, 1);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (150011, 'MD_RAW_MATERIAL_GROUP', 'md_raw_material_group',  '原料分组',     'main', 0, 'md_raw_material_group',  NULL, NULL, 1);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (150012, 'MD_CURRENCY',           'md_currency',            '币别',         'main', 0, 'md_currency',            NULL, NULL, 1);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (150013, 'MD_EXCHANGE_RATE',      'md_exchange_rate',       '汇率',         'main', 0, 'md_exchange_rate',       NULL, NULL, 1);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (150014, 'MD_WAREHOUSE',          'md_warehouse',           '仓库',         'main', 0, 'md_warehouse',           NULL, NULL, 1);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (150015, 'MD_BIN',                'md_position',            '仓位',         'main', 0, 'md_position',            NULL, NULL, 1);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (150016, 'MD_UNIT',               'md_unit',                '计量单位',     'main', 0, 'md_unit',                NULL, NULL, 1);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (150017, 'MD_BRAND',              'md_brand',               '品牌',         'main', 0, 'md_brand',               NULL, NULL, 1);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (150018, 'MD_COLOR_SERIES',       'md_color_series',        '色系',         'main', 0, 'md_color_series',         NULL, NULL, 1);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (150019, 'MD_COMP_COLOR',         'md_comp_color',          '公司色号',     'main', 0, 'md_comp_color',          NULL, NULL, 1);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (150020, 'MD_PRINT_COLOR',        'md_print_color',         '打版色号',     'main', 0, 'md_print_color',          NULL, NULL, 1);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (150021, 'MD_HL_CARD',            'md_hl_card',             '集锦卡',       'main', 0, 'md_hl_card',             NULL, NULL, 1);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (150022, 'MD_TRADE_TYPE',         'md_trade_type',          '贸易类型',     'main', 0, 'md_trade_type',          NULL, NULL, 1);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (150023, 'MD_PORT',               'md_harbour',             '港口',         'main', 0, 'md_harbour',             NULL, NULL, 1);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (150024, 'MD_SEAL',               'md_seal',                '印章',         'main', 0, 'md_seal',                NULL, NULL, 1);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (150025, 'MD_BOX_LABEL_TPL',      'md_box_label_tpl',       '箱贴模板',     'main', 0, 'md_box_label_tpl',       NULL, NULL, 1);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (150026, 'MD_QUALITY_STD',        'md_quality_std',         '质量标准',     'main', 0, 'md_quality_std',         NULL, NULL, 1);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (150027, 'MD_SETTLE_TYPE',       'md_firp_type',           '结算方式',     'main', 0, 'md_firp_type',           NULL, NULL, 1);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (150028, 'MD_SPIN_FEE',           'md_spin_fee',            '特殊纺工费',   'main', 0, 'md_spin_fee',            NULL, NULL, 1);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (150029, 'MD_CREDIT',             'md_credit',              '信用管理',     'main', 0, 'md_credit',              NULL, NULL, 1);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (150030, 'SYS_DICT',              'sys_dict',               '数据字典',     'main', 0, 'sys_dict',               NULL, NULL, 1);

-- 2.2 子实体（entity_type='sub', entity_level=1）—— 5 行
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (150031, 'MD_RAW_MATERIAL', 'detail',       '原料成分',   'sub', 1, 'md_raw_material_detail',  'md_raw_material', 'raw_mat_id',   2);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (150032, 'MD_SPIN_FEE',    'material',     '关联物料',   'sub', 1, 'md_spin_fee_material',    'md_spin_fee',    'spin_fee_id',  2);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (150033, 'MD_SPIN_FEE',    'raw_material', '关联原料',   'sub', 1, 'md_spin_fee_raw_material','md_spin_fee',    'spin_fee_id',  3);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (150034, 'MD_CREDIT',      'detail',       '客户明细',   'sub', 1, 'md_credit_detail',        'md_credit',      'credit_id',    2);
MERGE INTO meta_form_entity (id, bo_code, entity_code, entity_name, entity_type, entity_level, table_name, parent_entity_code, link_field, sort_index)
KEY(id) VALUES (150035, 'SYS_DICT',       'item',         '字典项',     'sub', 1, 'sys_dict_item',           'sys_dict',       'dict_id',      2);


-- ============================================================
-- 3. 表单字段元数据（meta_form_field）—— 200 行
--    仅注册关键字段（编码/名称/状态 + 业务核心字段），驱动表单渲染。
--    字段类型：text/number/date/datetime/enum/ref/bool/amount/qty
--    控件类型：text/textarea/number/date/datetime/select/ref/amount/qty/checkbox
--    ref 字段附带 ref_bo_code；ID 区间 200001-200200
-- ============================================================

-- ------------------------------------------------------------
-- 3.1 MD_ORG 组织（sys_org）—— 8 字段
-- ------------------------------------------------------------
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200001, 'MD_ORG', 'sys_org', 'code',          '组织编码', 'text', 'text',     1, 0, 1, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200002, 'MD_ORG', 'sys_org', 'name',          '组织名称', 'text', 'text',     1, 0, 2, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200003, 'MD_ORG', 'sys_org', 'org_type',      '组织类型', 'enum', 'select',   0, 0, 3, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200004, 'MD_ORG', 'sys_org', 'parent_id',     '上级组织', 'ref',  'ref',      0, 0, 'MD_ORG', 4, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200005, 'MD_ORG', 'sys_org', 'status',         '状态',     'bool', 'checkbox', 0, 0, 5, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200006, 'MD_ORG', 'sys_org', 'is_accounting', '是否核算', 'bool', 'checkbox', 0, 0, 6, '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200007, 'MD_ORG', 'sys_org', 'is_business',   '是否业务', 'bool', 'checkbox', 0, 0, 7, '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200008, 'MD_ORG', 'sys_org', 'sort_index',    '排序',     'number','number',   0, 0, 8, '业务信息');

-- ------------------------------------------------------------
-- 3.2 MD_DEPT 部门（sys_dept）—— 8 字段
-- ------------------------------------------------------------
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200009, 'MD_DEPT', 'sys_dept', 'code',       '部门编码', 'text', 'text',     1, 0, 1, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200010, 'MD_DEPT', 'sys_dept', 'name',       '部门名称', 'text', 'text',     1, 0, 2, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200011, 'MD_DEPT', 'sys_dept', 'org_id',     '所属组织', 'ref',  'ref',      0, 0, 'MD_ORG', 3, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200012, 'MD_DEPT', 'sys_dept', 'parent_id',  '上级部门', 'ref',  'ref',      0, 0, 'MD_DEPT', 4, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200013, 'MD_DEPT', 'sys_dept', 'dept_type',  '部门类型', 'enum', 'select',   0, 0, 5, '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200014, 'MD_DEPT', 'sys_dept', 'manager_id', '负责人',   'ref',  'ref',      0, 0, 'MD_EMPLOYEE', 6, '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200015, 'MD_DEPT', 'sys_dept', 'status',     '状态',     'bool', 'checkbox', 0, 0, 7, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200016, 'MD_DEPT', 'sys_dept', 'sort_index', '排序',     'number','number',   0, 0, 8, '业务信息');

-- ------------------------------------------------------------
-- 3.3 MD_EMPLOYEE 员工（sys_employee）—— 10 字段
-- ------------------------------------------------------------
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200017, 'MD_EMPLOYEE', 'sys_employee', 'code',        '员工编码', 'text', 'text',     1, 0, 1, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200018, 'MD_EMPLOYEE', 'sys_employee', 'name',        '员工姓名', 'text', 'text',     1, 0, 2, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200019, 'MD_EMPLOYEE', 'sys_employee', 'org_id',      '所属组织', 'ref',  'ref',      0, 0, 'MD_ORG', 3, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200020, 'MD_EMPLOYEE', 'sys_employee', 'dept_id',     '所属部门', 'ref',  'ref',      0, 0, 'MD_DEPT', 4, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200021, 'MD_EMPLOYEE', 'sys_employee', 'position',    '职位',     'text', 'text',     0, 0, 5, '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200022, 'MD_EMPLOYEE', 'sys_employee', 'gender',      '性别',     'enum', 'select',   0, 0, 6, '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200023, 'MD_EMPLOYEE', 'sys_employee', 'entry_date',  '入职日期', 'date', 'date',     0, 0, 7, '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200024, 'MD_EMPLOYEE', 'sys_employee', 'mobile',      '手机号',   'text', 'text',     0, 0, 8, '联系信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200025, 'MD_EMPLOYEE', 'sys_employee', 'status',      '状态',     'bool', 'checkbox', 0, 0, 9, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200026, 'MD_EMPLOYEE', 'sys_employee', 'active',      '是否在职', 'bool', 'checkbox', 0, 0, 10,'业务信息');

-- ------------------------------------------------------------
-- 3.4 MD_SALER 业务员（sys_saler）—— 6 字段
-- ------------------------------------------------------------
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200027, 'MD_SALER', 'sys_saler', 'code',            '业务员编码', 'text', 'text',     1, 0, 1, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200028, 'MD_SALER', 'sys_saler', 'staff_id',        '关联员工',   'ref',  'ref',      0, 0, 'MD_EMPLOYEE', 2, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200029, 'MD_SALER', 'sys_saler', 'dept_id',         '所属部门',   'ref',  'ref',      0, 0, 'MD_DEPT', 3, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200030, 'MD_SALER', 'sys_saler', 'is_cal_biz_fee',  '是否计算业务费', 'bool', 'checkbox', 0, 0, 4, '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200031, 'MD_SALER', 'sys_saler', 'enabled',         '是否启用',   'bool', 'checkbox', 0, 0, 5, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200032, 'MD_SALER', 'sys_saler', 'remark',          '备注',       'text', 'textarea', 0, 0, 6, '其他');

-- ------------------------------------------------------------
-- 3.5 MD_MERCHANDISER 跟单员（sys_merchandiser）—— 4 字段
-- ------------------------------------------------------------
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200033, 'MD_MERCHANDISER', 'sys_merchandiser', 'code',     '跟单员编码', 'text', 'text',     1, 0, 1, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200034, 'MD_MERCHANDISER', 'sys_merchandiser', 'staff_id', '关联员工',   'ref',  'ref',      0, 0, 'MD_EMPLOYEE', 2, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200035, 'MD_MERCHANDISER', 'sys_merchandiser', 'enabled',  '是否启用',   'bool', 'checkbox', 0, 0, 3, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200036, 'MD_MERCHANDISER', 'sys_merchandiser', 'remark',   '备注',       'text', 'textarea', 0, 0, 4, '其他');

-- ------------------------------------------------------------
-- 3.6 MD_CUSTOMER 客户（md_customer）—— 10 字段
-- ------------------------------------------------------------
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200037, 'MD_CUSTOMER', 'md_customer', 'code',         '客户编码', 'text', 'text',     1, 0, 1, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200038, 'MD_CUSTOMER', 'md_customer', 'name',         '客户名称', 'text', 'text',     1, 0, 2, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200039, 'MD_CUSTOMER', 'md_customer', 'short_name',   '简称',     'text', 'text',     0, 0, 3, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200040, 'MD_CUSTOMER', 'md_customer', 'cust_type',    '客户类型', 'enum', 'select',   0, 0, 4, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200041, 'MD_CUSTOMER', 'md_customer', 'saler_id',     '业务员',   'ref',  'ref',      0, 0, 'MD_SALER', 5, '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200042, 'MD_CUSTOMER', 'md_customer', 'credit_limit', '信用额度', 'amount','amount',   0, 0, 6, '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200043, 'MD_CUSTOMER', 'md_customer', 'contact',      '联系人',   'text', 'text',     0, 0, 7, '联系信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200044, 'MD_CUSTOMER', 'md_customer', 'phone',        '电话',     'text', 'text',     0, 0, 8, '联系信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200045, 'MD_CUSTOMER', 'md_customer', 'status',       '状态',     'bool', 'checkbox', 0, 0, 9, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200046, 'MD_CUSTOMER', 'md_customer', 'allow_sale',   '允许销售', 'bool', 'checkbox', 0, 0, 10,'业务信息');

-- ------------------------------------------------------------
-- 3.7 MD_SUPPLIER 供应商（md_supplier）—— 8 字段
-- ------------------------------------------------------------
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200047, 'MD_SUPPLIER', 'md_supplier', 'code',        '供应商编码', 'text', 'text',     1, 0, 1, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200048, 'MD_SUPPLIER', 'md_supplier', 'name',        '供应商名称', 'text', 'text',     1, 0, 2, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200049, 'MD_SUPPLIER', 'md_supplier', 'short_name',  '简称',       'text', 'text',     0, 0, 3, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200050, 'MD_SUPPLIER', 'md_supplier', 'sup_type',    '供应商类型', 'enum', 'select',   0, 0, 4, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200051, 'MD_SUPPLIER', 'md_supplier', 'purchaser_id', '采购员',     'ref',  'ref',      0, 0, 'MD_EMPLOYEE', 5, '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200052, 'MD_SUPPLIER', 'md_supplier', 'contact',     '联系人',     'text', 'text',     0, 0, 6, '联系信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200053, 'MD_SUPPLIER', 'md_supplier', 'phone',       '电话',       'text', 'text',     0, 0, 7, '联系信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200054, 'MD_SUPPLIER', 'md_supplier', 'status',      '状态',       'bool', 'checkbox', 0, 0, 8, '基本信息');

-- ------------------------------------------------------------
-- 3.8 MD_MATERIAL 物料（md_material）—— 10 字段
-- ------------------------------------------------------------
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200055, 'MD_MATERIAL', 'md_material', 'code',          '物料编码', 'text', 'text',     1, 0, 1, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200056, 'MD_MATERIAL', 'md_material', 'name',          '物料名称', 'text', 'text',     1, 0, 2, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200057, 'MD_MATERIAL', 'md_material', 'mat_type',      '物料类型', 'enum', 'select',   0, 0, 3, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200058, 'MD_MATERIAL', 'md_material', 'spec',          '规格型号', 'text', 'text',     0, 0, 4, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200059, 'MD_MATERIAL', 'md_material', 'yarn_count',    '纱支',     'number','number',   0, 0, 5, '纱线属性');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200060, 'MD_MATERIAL', 'md_material', 'unit_id',       '计量单位', 'ref',  'ref',      0, 0, 'MD_UNIT', 6, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200061, 'MD_MATERIAL', 'md_material', 'color',         '颜色',     'text', 'text',     0, 0, 7, '纱线属性');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200062, 'MD_MATERIAL', 'md_material', 'status',        '状态',     'bool', 'checkbox', 0, 0, 8, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200063, 'MD_MATERIAL', 'md_material', 'purchase_flag', '可采购',   'bool', 'checkbox', 0, 0, 9, '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200064, 'MD_MATERIAL', 'md_material', 'sale_flag',     '可销售',   'bool', 'checkbox', 0, 0, 10,'业务信息');

-- ------------------------------------------------------------
-- 3.9 MD_MATERIAL_GROUP 物料分组（md_material_group，树形）—— 6 字段
-- ------------------------------------------------------------
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200065, 'MD_MATERIAL_GROUP', 'md_material_group', 'code',      '分组编码', 'text', 'text',     1, 0, 1, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200066, 'MD_MATERIAL_GROUP', 'md_material_group', 'parent_id', '上级分组', 'ref',  'ref',      0, 0, 'MD_MATERIAL_GROUP', 2, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200067, 'MD_MATERIAL_GROUP', 'md_material_group', 'cn_name',   '中文名称', 'text', 'text',     1, 0, 3, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200068, 'MD_MATERIAL_GROUP', 'md_material_group', 'en_name',   '英文名称', 'text', 'text',     0, 0, 4, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200069, 'MD_MATERIAL_GROUP', 'md_material_group', 'enabled',   '是否启用', 'bool', 'checkbox', 0, 0, 5, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200070, 'MD_MATERIAL_GROUP', 'md_material_group', 'remark',    '备注',     'text', 'textarea', 0, 0, 6, '其他');

-- ------------------------------------------------------------
-- 3.10 MD_RAW_MATERIAL 原料（md_raw_material）—— 8 字段（主）+ 6 字段（子）
-- ------------------------------------------------------------
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200071, 'MD_RAW_MATERIAL', 'md_raw_material', 'code',       '原料编码', 'text', 'text',     1, 0, 1, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200072, 'MD_RAW_MATERIAL', 'md_raw_material', 'name',       '原料名称', 'text', 'text',     1, 0, 2, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200073, 'MD_RAW_MATERIAL', 'md_raw_material', 'cn_name',    '中文名称', 'text', 'text',     0, 0, 3, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200074, 'MD_RAW_MATERIAL', 'md_raw_material', 'fineness',   '细度',     'text', 'text',     0, 0, 4, '纱线属性');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200075, 'MD_RAW_MATERIAL', 'md_raw_material', 's_fee',      '纺工费',   'amount','amount',   0, 0, 5, '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200076, 'MD_RAW_MATERIAL', 'md_raw_material', 'group_id',   '所属分组', 'ref',  'ref',      0, 0, 'MD_RAW_MATERIAL_GROUP', 6, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200077, 'MD_RAW_MATERIAL', 'md_raw_material', 'enabled',    '是否启用', 'bool', 'checkbox', 0, 0, 7, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200078, 'MD_RAW_MATERIAL', 'md_raw_material', 'spin_type',  '纺纱类型', 'enum', 'select',   0, 0, 8, '纱线属性');
-- 子表 md_raw_material_detail（entity_code='detail'）
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200079, 'MD_RAW_MATERIAL', 'detail', 'mat_id',       '关联物料', 'ref',   'ref',    0, 0, 'MD_MATERIAL', 1, '成分明细');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200080, 'MD_RAW_MATERIAL', 'detail', 'ratio',        '比例',     'number','number', 0, 0, 2, '成分明细');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200081, 'MD_RAW_MATERIAL', 'detail', 'fiber_code',   '纤维编码', 'text',  'text',   0, 0, 3, '成分明细');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200082, 'MD_RAW_MATERIAL', 'detail', 'fiber_name',   '纤维名称', 'text',  'text',   0, 0, 4, '成分明细');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200083, 'MD_RAW_MATERIAL', 'detail', 'fiber_ratio',  '纤维比例', 'number','number', 0, 0, 5, '成分明细');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200084, 'MD_RAW_MATERIAL', 'detail', 'sort_index',   '排序',     'number','number', 0, 0, 6, '成分明细');

-- ------------------------------------------------------------
-- 3.11 MD_RAW_MATERIAL_GROUP 原料分组（md_raw_material_group，树形）—— 6 字段
-- ------------------------------------------------------------
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200085, 'MD_RAW_MATERIAL_GROUP', 'md_raw_material_group', 'code',      '分组编码', 'text', 'text',     1, 0, 1, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200086, 'MD_RAW_MATERIAL_GROUP', 'md_raw_material_group', 'parent_id', '上级分组', 'ref',  'ref',      0, 0, 'MD_RAW_MATERIAL_GROUP', 2, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200087, 'MD_RAW_MATERIAL_GROUP', 'md_raw_material_group', 'cn_name',   '中文名称', 'text', 'text',     1, 0, 3, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200088, 'MD_RAW_MATERIAL_GROUP', 'md_raw_material_group', 'en_name',   '英文名称', 'text', 'text',     0, 0, 4, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200089, 'MD_RAW_MATERIAL_GROUP', 'md_raw_material_group', 'enabled',   '是否启用', 'bool', 'checkbox', 0, 0, 5, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200090, 'MD_RAW_MATERIAL_GROUP', 'md_raw_material_group', 'remark',    '备注',     'text', 'textarea', 0, 0, 6, '其他');

-- ------------------------------------------------------------
-- 3.12 MD_CURRENCY 币别（md_currency）—— 6 字段
-- ------------------------------------------------------------
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200091, 'MD_CURRENCY', 'md_currency', 'code',            '币别编码', 'text', 'text',     1, 0, 1, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200092, 'MD_CURRENCY', 'md_currency', 'name',            '币别名称', 'text', 'text',     1, 0, 2, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200093, 'MD_CURRENCY', 'md_currency', 'symbol',          '货币符号', 'text', 'text',     0, 0, 3, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200094, 'MD_CURRENCY', 'md_currency', 'is_base',         '是否本位币', 'bool', 'checkbox', 0, 0, 4, '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200095, 'MD_CURRENCY', 'md_currency', 'decimal_digits',  '小数位数', 'number','number',   0, 0, 5, '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200096, 'MD_CURRENCY', 'md_currency', 'status',          '状态',     'bool', 'checkbox', 0, 0, 6, '基本信息');

-- ------------------------------------------------------------
-- 3.13 MD_EXCHANGE_RATE 汇率（md_exchange_rate）—— 4 字段（无 code/name/status）
-- ------------------------------------------------------------
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200097, 'MD_EXCHANGE_RATE', 'md_exchange_rate', 'curr_id',    '币别',     'ref',   'ref',    1, 0, 'MD_CURRENCY', 1, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200098, 'MD_EXCHANGE_RATE', 'md_exchange_rate', 'rate_type', '汇率类型', 'enum',  'select', 0, 0, 2, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200099, 'MD_EXCHANGE_RATE', 'md_exchange_rate', 'rate',      '汇率',     'number','number', 1, 0, 3, '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200100, 'MD_EXCHANGE_RATE', 'md_exchange_rate', 'valid_date','生效日期', 'date',  'date',   1, 0, 4, '业务信息');

-- ------------------------------------------------------------
-- 3.14 MD_WAREHOUSE 仓库（md_warehouse）—— 7 字段
-- ------------------------------------------------------------
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200101, 'MD_WAREHOUSE', 'md_warehouse', 'code',       '仓库编码', 'text', 'text',     1, 0, 1, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200102, 'MD_WAREHOUSE', 'md_warehouse', 'name',       '仓库名称', 'text', 'text',     1, 0, 2, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200103, 'MD_WAREHOUSE', 'md_warehouse', 'org_id',     '所属组织', 'ref',  'ref',      0, 0, 'MD_ORG', 3, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200104, 'MD_WAREHOUSE', 'md_warehouse', 'wh_type',    '仓库类型', 'enum', 'select',   0, 0, 4, '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200105, 'MD_WAREHOUSE', 'md_warehouse', 'manager_id', '仓管员',   'ref',  'ref',      0, 0, 'MD_EMPLOYEE', 5, '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200106, 'MD_WAREHOUSE', 'md_warehouse', 'address',    '地址',     'text', 'text',     0, 0, 6, '其他');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200107, 'MD_WAREHOUSE', 'md_warehouse', 'status',     '状态',     'bool', 'checkbox', 0, 0, 7, '基本信息');

-- ------------------------------------------------------------
-- 3.15 MD_BIN 仓位（md_position）—— 4 字段
-- ------------------------------------------------------------
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200108, 'MD_BIN', 'md_position', 'warehouse_id', '所属仓库', 'ref',  'ref',      1, 0, 'MD_WAREHOUSE', 1, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200109, 'MD_BIN', 'md_position', 'code',         '仓位编码', 'text', 'text',     1, 0, 2, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200110, 'MD_BIN', 'md_position', 'name',         '仓位名称', 'text', 'text',     1, 0, 3, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200111, 'MD_BIN', 'md_position', 'status',        '状态',     'bool', 'checkbox', 0, 0, 4, '基本信息');

-- ------------------------------------------------------------
-- 3.16 MD_UNIT 计量单位（md_unit）—— 5 字段
-- ------------------------------------------------------------
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200112, 'MD_UNIT', 'md_unit', 'code',       '单位编码', 'text', 'text',     1, 0, 1, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200113, 'MD_UNIT', 'md_unit', 'name',       '单位名称', 'text', 'text',     1, 0, 2, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200114, 'MD_UNIT', 'md_unit', 'unit_type',  '单位类型', 'enum', 'select',   0, 0, 3, '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200115, 'MD_UNIT', 'md_unit', 'is_base',    '是否基本单位', 'bool', 'checkbox', 0, 0, 4, '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200116, 'MD_UNIT', 'md_unit', 'status',     '状态',     'bool', 'checkbox', 0, 0, 5, '基本信息');

-- ------------------------------------------------------------
-- 3.17 MD_BRAND 品牌（md_brand）—— 3 字段
-- ------------------------------------------------------------
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200117, 'MD_BRAND', 'md_brand', 'code',   '品牌编码', 'text', 'text',     1, 0, 1, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200118, 'MD_BRAND', 'md_brand', 'name',   '品牌名称', 'text', 'text',     1, 0, 2, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200119, 'MD_BRAND', 'md_brand', 'status', '状态',     'bool', 'checkbox', 0, 0, 3, '基本信息');

-- ------------------------------------------------------------
-- 3.18 MD_COLOR_SERIES 色系（md_color_series）—— 4 字段
-- ------------------------------------------------------------
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200120, 'MD_COLOR_SERIES', 'md_color_series', 'code',    '色系编码', 'text', 'text',     1, 0, 1, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200121, 'MD_COLOR_SERIES', 'md_color_series', 'cn_name', '中文名称', 'text', 'text',     1, 0, 2, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200122, 'MD_COLOR_SERIES', 'md_color_series', 'enabled', '是否启用', 'bool', 'checkbox', 0, 0, 3, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200123, 'MD_COLOR_SERIES', 'md_color_series', 'remark',  '备注',     'text', 'textarea', 0, 0, 4, '其他');

-- ------------------------------------------------------------
-- 3.19 MD_COMP_COLOR 公司色号（md_comp_color）—— 6 字段
-- ------------------------------------------------------------
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200124, 'MD_COMP_COLOR', 'md_comp_color', 'code',          '色号编码', 'text', 'text',     1, 0, 1, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200125, 'MD_COMP_COLOR', 'md_comp_color', 'color_sys_id',  '所属色系', 'ref',  'ref',      0, 0, 'MD_COLOR_SERIES', 2, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200126, 'MD_COMP_COLOR', 'md_comp_color', 'cn_name',       '中文名称', 'text', 'text',     1, 0, 3, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200127, 'MD_COMP_COLOR', 'md_comp_color', 'color_name',    '颜色名称', 'text', 'text',     0, 0, 4, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200128, 'MD_COMP_COLOR', 'md_comp_color', 'enabled',       '是否启用', 'bool', 'checkbox', 0, 0, 5, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200129, 'MD_COMP_COLOR', 'md_comp_color', 'is_ab_yarn',    '是否AB纱', 'bool', 'checkbox', 0, 0, 6, '业务信息');

-- ------------------------------------------------------------
-- 3.20 MD_PRINT_COLOR 打版色号（md_print_color）—— 6 字段
-- ------------------------------------------------------------
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200130, 'MD_PRINT_COLOR', 'md_print_color', 'code',           '色号编码',   'text', 'text',     1, 0, 1, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200131, 'MD_PRINT_COLOR', 'md_print_color', 'cn_name',        '中文名称',   'text', 'text',     1, 0, 2, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200132, 'MD_PRINT_COLOR', 'md_print_color', 'comp_color_id',  '关联公司色号', 'ref',  'ref',      0, 0, 'MD_COMP_COLOR', 3, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200133, 'MD_PRINT_COLOR', 'md_print_color', 'color_sys_id',   '所属色系',   'ref',  'ref',      0, 0, 'MD_COLOR_SERIES', 4, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200134, 'MD_PRINT_COLOR', 'md_print_color', 'color_name',     '颜色名称',   'text', 'text',     0, 0, 5, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200135, 'MD_PRINT_COLOR', 'md_print_color', 'enabled',        '是否启用',   'bool', 'checkbox', 0, 0, 6, '基本信息');

-- ------------------------------------------------------------
-- 3.21 MD_HL_CARD 集锦卡（md_hl_card）—— 10 字段
-- ------------------------------------------------------------
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200136, 'MD_HL_CARD', 'md_hl_card', 'code',       '集锦卡编码', 'text', 'text',     1, 0, 1, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200137, 'MD_HL_CARD', 'md_hl_card', 'name',       '集锦卡名称', 'text', 'text',     1, 0, 2, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200138, 'MD_HL_CARD', 'md_hl_card', 'mat_id',     '关联物料',   'ref',  'ref',      0, 0, 'MD_MATERIAL', 3, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200139, 'MD_HL_CARD', 'md_hl_card', 'yarn_count', '纱支',       'number','number',   0, 0, 4, '纱线属性');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200140, 'MD_HL_CARD', 'md_hl_card', 'strand',     '股数',       'number','number',   0, 0, 5, '纱线属性');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200141, 'MD_HL_CARD', 'md_hl_card', 'twist',      '捻度',       'text', 'text',     0, 0, 6, '纱线属性');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200142, 'MD_HL_CARD', 'md_hl_card', 'fineness',   '细度',       'text', 'text',     0, 0, 7, '纱线属性');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200143, 'MD_HL_CARD', 'md_hl_card', 'color_id',   '颜色',       'ref',  'ref',      0, 0, 'MD_COMP_COLOR', 8, '纱线属性');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200144, 'MD_HL_CARD', 'md_hl_card', 'sp_price',   '加工单价',   'amount','amount',   0, 0, 9, '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200145, 'MD_HL_CARD', 'md_hl_card', 'status',     '状态',       'bool', 'checkbox', 0, 0, 10,'基本信息');

-- ------------------------------------------------------------
-- 3.22 MD_TRADE_TYPE 贸易类型（md_trade_type）—— 5 字段
-- ------------------------------------------------------------
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200146, 'MD_TRADE_TYPE', 'md_trade_type', 'code',       '贸易类型编码', 'text', 'text',     1, 0, 1, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200147, 'MD_TRADE_TYPE', 'md_trade_type', 'name',       '中文名称',     'text', 'text',     1, 0, 2, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200148, 'MD_TRADE_TYPE', 'md_trade_type', 'name_en',    '英文名称',     'text', 'text',     0, 0, 3, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200149, 'MD_TRADE_TYPE', 'md_trade_type', 'trade_kind', '贸易种类',     'enum', 'select',   0, 0, 4, '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200150, 'MD_TRADE_TYPE', 'md_trade_type', 'status',     '状态',         'bool', 'checkbox', 0, 0, 5, '基本信息');

-- ------------------------------------------------------------
-- 3.23 MD_PORT 港口（md_harbour）—— 5 字段
-- ------------------------------------------------------------
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200151, 'MD_PORT', 'md_harbour', 'code',    '港口编码', 'text', 'text',     1, 0, 1, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200152, 'MD_PORT', 'md_harbour', 'name_cn', '中文名称', 'text', 'text',     1, 0, 2, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200153, 'MD_PORT', 'md_harbour', 'name_en', '英文名称', 'text', 'text',     0, 0, 3, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200154, 'MD_PORT', 'md_harbour', 'country', '国家',     'text', 'text',     0, 0, 4, '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200155, 'MD_PORT', 'md_harbour', 'status',  '状态',     'bool', 'checkbox', 0, 0, 5, '基本信息');

-- ------------------------------------------------------------
-- 3.24 MD_SEAL 印章（md_seal）—— 4 字段（表无 status 字段）
-- ------------------------------------------------------------
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200156, 'MD_SEAL', 'md_seal', 'code',        '印章编码', 'text', 'text',     1, 0, 1, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200157, 'MD_SEAL', 'md_seal', 'stamp_name',  '印章名称', 'text', 'text',     1, 0, 2, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200158, 'MD_SEAL', 'md_seal', 'company_id',  '所属公司', 'ref',  'ref',      0, 0, 'MD_ORG', 3, '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200159, 'MD_SEAL', 'md_seal', 'stamp_admin', '印章管理员', 'ref',  'ref',      0, 0, 'MD_EMPLOYEE', 4, '业务信息');

-- ------------------------------------------------------------
-- 3.25 MD_BOX_LABEL_TPL 箱贴模板（md_box_label_tpl）—— 6 字段
-- ------------------------------------------------------------
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200160, 'MD_BOX_LABEL_TPL', 'md_box_label_tpl', 'code',        '模板编码', 'text', 'text',     1, 0, 1, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200161, 'MD_BOX_LABEL_TPL', 'md_box_label_tpl', 'cn_name',     '中文名称', 'text', 'text',     1, 0, 2, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200162, 'MD_BOX_LABEL_TPL', 'md_box_label_tpl', 'en_name',     '英文名称', 'text', 'text',     0, 0, 3, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200163, 'MD_BOX_LABEL_TPL', 'md_box_label_tpl', 'org_id',      '所属组织', 'ref',  'ref',      0, 0, 'MD_ORG', 4, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200164, 'MD_BOX_LABEL_TPL', 'md_box_label_tpl', 'is_en_print', '是否英文打印', 'bool', 'checkbox', 0, 0, 5, '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200165, 'MD_BOX_LABEL_TPL', 'md_box_label_tpl', 'enabled',     '是否启用', 'bool', 'checkbox', 0, 0, 6, '基本信息');

-- ------------------------------------------------------------
-- 3.26 MD_QUALITY_STD 质量标准（md_quality_std）—— 4 字段
-- ------------------------------------------------------------
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200166, 'MD_QUALITY_STD', 'md_quality_std', 'code',     '质量标准编码', 'text', 'text',     1, 0, 1, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200167, 'MD_QUALITY_STD', 'md_quality_std', 'name',     '质量标准名称', 'text', 'text',     1, 0, 2, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200168, 'MD_QUALITY_STD', 'md_quality_std', 'std_desc', '标准说明',     'text', 'textarea', 0, 0, 3, '其他');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200169, 'MD_QUALITY_STD', 'md_quality_std', 'status',   '状态',         'bool', 'checkbox', 0, 0, 4, '基本信息');

-- ------------------------------------------------------------
-- 3.27 MD_SETTLE_TYPE 结算方式（md_firp_type）—— 4 字段
-- ------------------------------------------------------------
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200170, 'MD_SETTLE_TYPE', 'md_firp_type', 'code',      '结算方式编码', 'text', 'text',     1, 0, 1, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200171, 'MD_SETTLE_TYPE', 'md_firp_type', 'name',      '结算方式名称', 'text', 'text',     1, 0, 2, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200172, 'MD_SETTLE_TYPE', 'md_firp_type', 'firp_kind', '结算种类',     'enum', 'select',   0, 0, 3, '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200173, 'MD_SETTLE_TYPE', 'md_firp_type', 'status',    '状态',         'bool', 'checkbox', 0, 0, 4, '基本信息');

-- ------------------------------------------------------------
-- 3.28 MD_SPIN_FEE 特殊纺工费（md_spin_fee）—— 2 字段（主）+ 2 字段（子1）+ 3 字段（子2）
-- ------------------------------------------------------------
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200174, 'MD_SPIN_FEE', 'md_spin_fee', 'code',   '纺工费编码', 'text', 'text',     1, 0, 1, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200175, 'MD_SPIN_FEE', 'md_spin_fee', 'remark', '备注',       'text', 'textarea', 0, 0, 2, '其他');
-- 子表 md_spin_fee_material（entity_code='material'）
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200176, 'MD_SPIN_FEE', 'material', 'mat_id',     '关联物料', 'ref',   'ref',    1, 0, 'MD_MATERIAL', 1, '关联物料');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200177, 'MD_SPIN_FEE', 'material', 'sort_index', '排序',     'number','number', 0, 0, 2, '关联物料');
-- 子表 md_spin_fee_raw_material（entity_code='raw_material'）
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200178, 'MD_SPIN_FEE', 'raw_material', 'raw_mat_id', '关联原料', 'ref',   'ref',    1, 0, 'MD_RAW_MATERIAL', 1, '关联原料');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200179, 'MD_SPIN_FEE', 'raw_material', 's_fee',      '纺工费',   'amount','amount', 0, 0, 2, '关联原料');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200180, 'MD_SPIN_FEE', 'raw_material', 'sort_index', '排序',     'number','number', 0, 0, 3, '关联原料');

-- ------------------------------------------------------------
-- 3.29 MD_CREDIT 信用管理（md_credit）—— 5 字段（主）+ 7 字段（子）
-- ------------------------------------------------------------
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200181, 'MD_CREDIT', 'md_credit', 'code',             '信用编码', 'text', 'text',     1, 0, 1, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200182, 'MD_CREDIT', 'md_credit', 'org_id',           '所属组织', 'ref',  'ref',      0, 0, 'MD_ORG', 2, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200183, 'MD_CREDIT', 'md_credit', 'is_group_credit',  '是否集团信用', 'bool', 'checkbox', 0, 0, 3, '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200184, 'MD_CREDIT', 'md_credit', 'cust_type',        '客户类型', 'enum', 'select',   0, 0, 4, '业务信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200185, 'MD_CREDIT', 'md_credit', 'remark',           '备注',     'text', 'textarea', 0, 0, 5, '其他');
-- 子表 md_credit_detail（entity_code='detail'）
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200186, 'MD_CREDIT', 'detail', 'cust_id',        '客户',     'ref',   'ref',    1, 0, 'MD_CUSTOMER', 1, '客户明细');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, ref_bo_code, sort_index, group_name) KEY(id) VALUES (200187, 'MD_CREDIT', 'detail', 'curr_id',        '币别',     'ref',   'ref',    0, 0, 'MD_CURRENCY', 2, '客户明细');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200188, 'MD_CREDIT', 'detail', 'amount',         '信用额度', 'amount','amount', 0, 0, 3, '客户明细');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200189, 'MD_CREDIT', 'detail', 'amount_status',  '额度状态', 'enum',  'select', 0, 0, 4, '客户明细');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200190, 'MD_CREDIT', 'detail', 'valid_time',     '生效日期', 'date',  'date',   0, 0, 5, '客户明细');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200191, 'MD_CREDIT', 'detail', 'credit_status',  '信用状态', 'enum',  'select', 0, 0, 6, '客户明细');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200192, 'MD_CREDIT', 'detail', 'sort_index',     '排序',     'number','number', 0, 0, 7, '客户明细');

-- ------------------------------------------------------------
-- 3.30 SYS_DICT 数据字典（sys_dict）—— 4 字段（主）+ 4 字段（子）
-- 注：sys_dict/sys_dict_item 表结构见 schema-h2-master-ext.sql
-- ============================================================
-- 重要说明（sys_dict 表结构冲突）：
--   schema-h2.sql 第 5648 行已定义 sys_dict/sys_dict_item，但结构不同：
--     - sys_dict      主键为 dict_code(varchar)，无 id/create_by/create_time 列
--     - sys_dict_item 关联字段为 dict_code，列为 item_value/sort_order/is_default
--   本文件按 schema-h2-master-ext.sql 的新结构（id 主键、dict_id 关联）注册元数据。
--   若 schema-h2.sql 先加载，schema-h2-master-ext.sql 的 CREATE TABLE IF NOT EXISTS
--   将是空操作，SYS_DICT 字段元数据与实际表列不匹配。
--   解决方案（任选其一）：
--     1) 更新 schema-h2.sql 中 sys_dict/sys_dict_item 为新结构；
--     2) 将 schema-h2-master-ext.sql 改为 DROP TABLE IF EXISTS + CREATE TABLE；
--     3) 将本节 SYS_DICT 字段改为对齐 schema-h2.sql 既有列。
-- ============================================================
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200193, 'SYS_DICT', 'sys_dict', 'dict_code', '字典编码', 'text', 'text',     1, 0, 1, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200194, 'SYS_DICT', 'sys_dict', 'dict_name', '字典名称', 'text', 'text',     1, 0, 2, '基本信息');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200195, 'SYS_DICT', 'sys_dict', 'remark',    '备注',     'text', 'textarea', 0, 0, 3, '其他');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200196, 'SYS_DICT', 'sys_dict', 'status',    '状态',     'bool', 'checkbox', 0, 0, 4, '基本信息');
-- 子表 sys_dict_item（entity_code='item'）
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200197, 'SYS_DICT', 'item', 'item_code',  '字典项编码', 'text', 'text',     1, 0, 1, '字典项');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200198, 'SYS_DICT', 'item', 'item_name',  '字典项名称', 'text', 'text',     1, 0, 2, '字典项');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200199, 'SYS_DICT', 'item', 'sort_index', '排序',       'number','number',   0, 0, 3, '字典项');
MERGE INTO meta_form_field (id, bo_code, entity_code, field_code, field_name, field_type, ctrl_type, is_required, is_system, sort_index, group_name) KEY(id) VALUES (200200, 'SYS_DICT', 'item', 'enabled',    '是否启用',   'bool', 'checkbox', 0, 0, 4, '字典项');


-- ============================================================
-- 文件统计
--   meta_business_object : 30 行 (ID 100001-100030)
--   meta_form_entity     : 35 行 (ID 150001-150035，30 MAIN + 5 SUB)
--   meta_form_field      : 200 行 (ID 200001-200200)
--   合计                 : 265 条 MERGE 语句
-- ============================================================
