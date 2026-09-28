-- =====================================================================
-- V1.0.2__seed_dict.sql
-- 通用数据字典种子数据：字典定义 + 字典枚举项
-- 对应表：sys_dict / sys_dict_item（定义于 10-系统管理表.sql）
-- 已确认 10-系统管理表.sql 中存在 sys_dict 与 sys_dict_item 两张表
-- =====================================================================

-- ---------------------------------------------------------------------
-- 一、数据字典定义（sys_dict）
-- 主键为 dict_code；table_name/field_name 描述字典归属字段
-- ---------------------------------------------------------------------
INSERT INTO `sys_dict` (`dict_code`, `dict_name`, `table_name`, `field_name`, `field_type`, `field_length`, `field_comment`, `is_enum`, `status`) VALUES
('Y_N',        '是否',     NULL,      'is_flag',    'varchar', 2,   '是否标识（Y是 / N否）',              1, 1),
('BILL_STATE', '单据状态', NULL,      'pact_state', 'int',     11,  '单据状态（0暂存/1已创建/2已提交/3已审核/4已驳回）', 1, 1),
('ORG_TYPE',   '组织类型', 'sys_org', 'org_type',   'varchar', 50,  '组织类型（group集团/company公司/factory工厂/workshop车间/business事业部）', 1, 1);

-- ---------------------------------------------------------------------
-- 二、字典枚举项（sys_dict_item）
-- id 为自增主键，此处不指定；item_value 为字符串类型
-- ---------------------------------------------------------------------

-- 是否（Y_N）
INSERT INTO `sys_dict_item` (`dict_code`, `item_value`, `item_name`, `sort_order`, `is_default`) VALUES
('Y_N', 'Y', '是', 1, 1),
('Y_N', 'N', '否', 2, 0);

-- 单据状态（BILL_STATE）
INSERT INTO `sys_dict_item` (`dict_code`, `item_value`, `item_name`, `sort_order`, `is_default`) VALUES
('BILL_STATE', '0', '暂存',   1, 1),
('BILL_STATE', '1', '已创建', 2, 0),
('BILL_STATE', '2', '已提交', 3, 0),
('BILL_STATE', '3', '已审核', 4, 0),
('BILL_STATE', '4', '已驳回', 5, 0);

-- 组织类型（ORG_TYPE）
INSERT INTO `sys_dict_item` (`dict_code`, `item_value`, `item_name`, `sort_order`, `is_default`) VALUES
('ORG_TYPE', 'group',     '集团',     1, 1),
('ORG_TYPE', 'company',   '公司',     2, 0),
('ORG_TYPE', 'factory',   '工厂',     3, 0),
('ORG_TYPE', 'workshop',  '车间',     4, 0),
('ORG_TYPE', 'business',  '事业部',   5, 0);
