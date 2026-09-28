-- =====================================================================
-- 01-基础资料表（主数据 MDM）
-- 说明：组织、部门、员工、客户、供应商、物料、币别、汇率、仓库、仓位、
--       计量单位、品牌、色号、集锦卡、质量标准、贸易类型、结算方式、港口。
-- 命名约定：表前缀 sys_/md_
-- =====================================================================

-- ---------------------------------------------------------------------
-- 一、组织架构
-- ---------------------------------------------------------------------

-- sys_org：组织
CREATE TABLE `sys_org` (
  `id` bigint NOT NULL,
  `code` varchar(100) DEFAULT NULL COMMENT '组织编码',
  `name` varchar(200) DEFAULT NULL COMMENT '组织名称',
  `org_type` varchar(50) DEFAULT NULL COMMENT '组织类型（group集团/company公司/factory工厂/workshop车间/business事业部）',
  `parent_id` bigint DEFAULT NULL COMMENT '上级组织ID',
  `is_accounting` int DEFAULT '0' COMMENT '是否核算组织',
  `is_business` int DEFAULT '0' COMMENT '是否业务组织',
  `base_curr_id` bigint DEFAULT NULL COMMENT '本位币',
  `tax_no` varchar(100) DEFAULT NULL COMMENT '税号',
  `address` varchar(500) DEFAULT NULL COMMENT '地址',
  `status` int DEFAULT '1' COMMENT '状态（1启用 0停用）',
  `sort_index` int DEFAULT '0',
  `logo` varchar(255) DEFAULT NULL COMMENT '组织Logo',
  `create_by` varchar(200) DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  `update_by` varchar(200) DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `sys_org_code_UK` (`code`) USING BTREE,
  KEY `sys_org_parent_id_IDX` (`parent_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='组织';

-- sys_dept：部门
CREATE TABLE `sys_dept` (
  `id` bigint NOT NULL,
  `code` varchar(100) DEFAULT NULL COMMENT '部门编码',
  `name` varchar(200) DEFAULT NULL COMMENT '部门名称',
  `org_id` bigint DEFAULT NULL COMMENT '所属组织',
  `parent_id` bigint DEFAULT NULL COMMENT '上级部门',
  `dept_type` varchar(50) DEFAULT NULL COMMENT '部门类型（sale销售/pur采购/mfg生产/fin财务/admin行政）',
  `manager_id` bigint DEFAULT NULL COMMENT '负责人ID',
  `status` int DEFAULT '1',
  `sort_index` int DEFAULT '0',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `sys_dept_code_UK` (`code`) USING BTREE,
  KEY `sys_dept_org_id_IDX` (`org_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='部门';

-- sys_employee：员工
CREATE TABLE `sys_employee` (
  `id` bigint NOT NULL,
  `code` varchar(100) DEFAULT NULL COMMENT '工号',
  `name` varchar(100) DEFAULT NULL COMMENT '姓名',
  `org_id` bigint DEFAULT NULL COMMENT '所属组织',
  `dept_id` bigint DEFAULT NULL COMMENT '部门',
  `position` varchar(100) DEFAULT NULL COMMENT '岗位',
  `gender` int DEFAULT NULL COMMENT '性别',
  `entry_date` date DEFAULT NULL COMMENT '入职日期',
  `is_saler` int DEFAULT '0' COMMENT '是否业务员',
  `is_purchaser` int DEFAULT '0' COMMENT '是否采购员',
  `user_id` bigint DEFAULT NULL COMMENT '关联系统用户ID',
  `mobile` varchar(100) DEFAULT NULL COMMENT '电话',
  `email` varchar(100) DEFAULT NULL COMMENT '邮箱',
  `manager_id` bigint DEFAULT NULL COMMENT '直属主管',
  `birthday` date DEFAULT NULL COMMENT '生日',
  `departure_date` date DEFAULT NULL COMMENT '离职时间',
  `employee_rank` int DEFAULT NULL COMMENT '员工等级',
  `active` int DEFAULT '1' COMMENT '是否在职',
  `remark` mediumtext COMMENT '备注',
  `status` int DEFAULT '1',
  `create_by` varchar(200) DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  `update_by` varchar(200) DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `sys_employee_code_UK` (`code`) USING BTREE,
  KEY `sys_employee_dept_id_IDX` (`dept_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='员工';

-- ---------------------------------------------------------------------
-- 二、客商
-- ---------------------------------------------------------------------

-- md_customer：客户
CREATE TABLE `md_customer` (
  `id` bigint NOT NULL,
  `code` varchar(100) DEFAULT NULL COMMENT '客户编码',
  `name` varchar(200) DEFAULT NULL COMMENT '客户名称',
  `name_en` varchar(200) DEFAULT NULL COMMENT '英文名',
  `short_name` varchar(200) DEFAULT NULL COMMENT '简称',
  `cust_type` varchar(50) DEFAULT NULL COMMENT '客户类型（domestic内贸/foreign外贸）',
  `trade_type` varchar(200) DEFAULT NULL COMMENT '贸易类型',
  `curr_id` bigint DEFAULT NULL COMMENT '默认结算币别',
  `sal_org_id` bigint DEFAULT NULL COMMENT '默认销售组织',
  `saler_id` bigint DEFAULT NULL COMMENT '默认业务员',
  `credit_limit` decimal(19,6) DEFAULT NULL COMMENT '信用额度',
  `credit_period` int DEFAULT NULL COMMENT '信用期(天)',
  `tax_rate` decimal(16,8) DEFAULT NULL COMMENT '默认税率',
  `tax_no` varchar(100) DEFAULT NULL COMMENT '税号',
  `firp_type` varchar(200) DEFAULT NULL COMMENT '默认结算方式',
  `rec_type` varchar(200) DEFAULT NULL COMMENT '默认收款方式',
  `contact` varchar(100) DEFAULT NULL COMMENT '联系人',
  `phone` varchar(100) DEFAULT NULL COMMENT '电话',
  `fax` varchar(100) DEFAULT NULL COMMENT '传真',
  `email` varchar(200) DEFAULT NULL COMMENT '邮箱',
  `address` varchar(500) DEFAULT NULL COMMENT '地址',
  `address_en` varchar(500) DEFAULT NULL COMMENT '英文地址',
  `harbour_end` varchar(200) DEFAULT NULL COMMENT '默认目的港',
  `bank_name` varchar(200) DEFAULT NULL COMMENT '开户行',
  `bank_account` varchar(100) DEFAULT NULL COMMENT '银行账号',
  `credit_balance` decimal(18,4) DEFAULT NULL COMMENT '信用余额',
  `is_credit_check` tinyint NOT NULL DEFAULT 0 COMMENT '是否启用信用控制',
  `credit_expiry` date DEFAULT NULL COMMENT '额度有效期',
  `credit_level` varchar(50) DEFAULT NULL COMMENT '信用等级',
  `credit_status` varchar(50) DEFAULT NULL COMMENT '信用状态（normal正常/overdue逾期/exceeded超额）',
  `ar_period` varchar(50) DEFAULT NULL COMMENT '应收账期',
  `overdue_days` int DEFAULT NULL COMMENT '逾期天数',
  `group_cust_id` bigint DEFAULT NULL COMMENT '对应集团客户',
  `cust_gp_id` bigint DEFAULT NULL COMMENT '客户分组',
  `is_gp_cust` int DEFAULT '0' COMMENT '是否集团客户',
  `legal_person` varchar(200) DEFAULT NULL COMMENT '法人代表',
  `reg_capital` decimal(19,6) DEFAULT NULL COMMENT '注册资本',
  `comp_nature` varchar(200) DEFAULT NULL COMMENT '公司性质',
  `comp_size` varchar(200) DEFAULT NULL COMMENT '公司规模',
  `comp_date` date DEFAULT NULL COMMENT '创立日期',
  `industry` varchar(200) DEFAULT NULL COMMENT '行业',
  `country` varchar(200) DEFAULT NULL COMMENT '国家',
  `province` varchar(200) DEFAULT NULL COMMENT '省份',
  `region` varchar(200) DEFAULT NULL COMMENT '地区',
  `post_code` varchar(200) DEFAULT NULL COMMENT '邮政编码',
  `inv_title` varchar(200) DEFAULT NULL COMMENT '发票抬头',
  `inv_type` varchar(200) DEFAULT NULL COMMENT '发票类别',
  `prod_inv_name` varchar(200) DEFAULT NULL COMMENT '产品开票名称',
  `attm` varchar(255) DEFAULT NULL COMMENT '附件地址',
  `allow_sale` int DEFAULT '1' COMMENT '允许销售',
  `allow_trust` int DEFAULT '0' COMMENT '允许受托',
  `allow_purchase` int DEFAULT '1' COMMENT '允许采购',
  `allow_outsource` int DEFAULT '0' COMMENT '允许委外',
  `remark` mediumtext COMMENT '备注',
  `status` int DEFAULT '1',
  `create_by` varchar(200) DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  `update_by` varchar(200) DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `md_customer_code_UK` (`code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='客户';

-- md_supplier：供应商
CREATE TABLE `md_supplier` (
  `id` bigint NOT NULL,
  `code` varchar(100) DEFAULT NULL COMMENT '供应商编码',
  `name` varchar(200) DEFAULT NULL COMMENT '名称',
  `name_en` varchar(200) DEFAULT NULL COMMENT '英文名',
  `short_name` varchar(200) DEFAULT NULL COMMENT '简称',
  `sup_type` varchar(50) DEFAULT NULL COMMENT '类型（raw原毛/dye染化料/pack包装/machine设备）',
  `curr_id` bigint DEFAULT NULL COMMENT '默认币别',
  `pur_org_id` bigint DEFAULT NULL COMMENT '默认采购组织',
  `purchaser_id` bigint DEFAULT NULL COMMENT '默认采购员',
  `tax_rate` decimal(16,8) DEFAULT NULL COMMENT '默认税率',
  `tax_no` varchar(100) DEFAULT NULL COMMENT '税号',
  `firp_type` varchar(200) DEFAULT NULL COMMENT '默认结算方式',
  `pay_type` varchar(200) DEFAULT NULL COMMENT '默认付款方式',
  `is_agri` int DEFAULT '0' COMMENT '是否农产品收购（免税特殊处理）',
  `credit_level` varchar(50) DEFAULT NULL COMMENT '信誉评级',
  `contact` varchar(100) DEFAULT NULL,
  `phone` varchar(100) DEFAULT NULL,
  `fax` varchar(100) DEFAULT NULL,
  `email` varchar(200) DEFAULT NULL,
  `address` varchar(500) DEFAULT NULL,
  `bank_name` varchar(200) DEFAULT NULL,
  `bank_account` varchar(100) DEFAULT NULL,
  `on_time_rate` decimal(5,2) DEFAULT NULL COMMENT '交货准时率(%)',
  `pass_rate` decimal(5,2) DEFAULT NULL COMMENT '合格率(%)',
  `eval_score` decimal(5,2) DEFAULT NULL COMMENT '综合评分',
  `eval_level` varchar(2) DEFAULT NULL COMMENT '评估等级A/B/C/D',
  `eval_date` date DEFAULT NULL COMMENT '评估日期',
  `status` int DEFAULT '1',
  `create_by` varchar(200) DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  `update_by` varchar(200) DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `md_supplier_code_UK` (`code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='供应商';

-- ---------------------------------------------------------------------
-- 三、物料（核心主数据，含纱线行业属性）
-- ---------------------------------------------------------------------

-- md_material：物料
CREATE TABLE `md_material` (
  `id` bigint NOT NULL,
  `code` varchar(100) DEFAULT NULL COMMENT '物料编码',
  `name` varchar(200) DEFAULT NULL COMMENT '物料名称',
  `name_en` varchar(200) DEFAULT NULL COMMENT '英文名',
  `spec` varchar(200) DEFAULT NULL COMMENT '规格',
  `mat_type` varchar(50) DEFAULT NULL COMMENT '物料类型（raw_wool原毛/dye染化料/pack包装/semi_yarn半成品纱/fin_yarn成品纱）',
  `yarn_count` decimal(16,8) DEFAULT NULL COMMENT '支数（纱线）',
  `strand` decimal(16,8) DEFAULT NULL COMMENT '股数（纱线）',
  `yarn_type` varchar(50) DEFAULT NULL COMMENT '纱线类型（cone筒子纱/hank绞纱）',
  `twist` varchar(100) DEFAULT NULL COMMENT '捻度',
  `fineness` varchar(200) DEFAULT NULL COMMENT '细度',
  `color` varchar(100) DEFAULT NULL COMMENT '颜色',
  `unit_id` bigint DEFAULT NULL COMMENT '基本单位',
  `weight_type` varchar(200) DEFAULT NULL COMMENT '计重方式',
  `ct_weight` decimal(16,8) DEFAULT NULL COMMENT '筒重/绞重',
  `batch_flag` int DEFAULT '0' COMMENT '是否批次管理',
  `vat_flag` int DEFAULT '0' COMMENT '是否缸号管理',
  `shelf_life` int DEFAULT NULL COMMENT '保质期(天，染化料)',
  `tax_rate` decimal(16,8) DEFAULT NULL COMMENT '默认税率',
  `std_cost` decimal(19,6) DEFAULT NULL COMMENT '标准成本',
  `purchase_flag` int DEFAULT '0' COMMENT '可采购',
  `sale_flag` int DEFAULT '0' COMMENT '可销售',
  `produce_flag` int DEFAULT '0' COMMENT '可生产',
  `barcode` varchar(100) DEFAULT NULL COMMENT '物料条码',
  `dye_method` varchar(200) DEFAULT NULL COMMENT '染色方式',
  `prd_type` varchar(200) DEFAULT NULL COMMENT '生产类型',
  `yarn_proc` varchar(200) DEFAULT NULL COMMENT '纺纱工艺',
  `twist_direction` varchar(50) DEFAULT NULL COMMENT '捻向（S捻/Z捻）',
  `raw_material_detail` mediumtext COMMENT '原料明细',
  `customs_no` varchar(200) DEFAULT NULL COMMENT '报关编号',
  `customs_name` varchar(200) DEFAULT NULL COMMENT '报关货名',
  `ra_fee` decimal(19,6) DEFAULT NULL COMMENT '倒筒加价费',
  `pa_rate` decimal(16,8) DEFAULT NULL COMMENT '实磅加价比例',
  `s_fee` decimal(19,6) DEFAULT NULL COMMENT '纺工费',
  `sale_rate` decimal(16,8) DEFAULT NULL COMMENT '销售折率',
  `stock_type` varchar(200) DEFAULT NULL COMMENT '存货类别',
  `mat_gp_id` bigint DEFAULT NULL COMMENT '物料分组',
  `mat_prop` varchar(200) DEFAULT NULL COMMENT '物料属性',
  `prd_rate` decimal(16,8) DEFAULT NULL COMMENT '生产折率',
  `is_newyarn` int DEFAULT '0' COMMENT '是否新型纱线',
  `mat_index` varchar(100) DEFAULT NULL COMMENT '物料序号',
  `is_inventory` int DEFAULT '1' COMMENT '允许库存',
  `is_sub_contract` int DEFAULT '0' COMMENT '允许委外',
  `is_check` int DEFAULT '0' COMMENT '入库免检',
  `is_main_prd` int DEFAULT '0' COMMENT '可为主产品',
  `remark` mediumtext COMMENT '备注',
  `status` int DEFAULT '1',
  `create_by` varchar(200) DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  `update_by` varchar(200) DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `md_material_code_UK` (`code`) USING BTREE,
  KEY `md_material_mat_type_IDX` (`mat_type`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='物料';

-- ---------------------------------------------------------------------
-- 四、币别与汇率
-- ---------------------------------------------------------------------

-- md_currency：币别
CREATE TABLE `md_currency` (
  `id` bigint NOT NULL,
  `code` varchar(50) DEFAULT NULL COMMENT '币别编码（CNY/USD/EUR）',
  `name` varchar(100) DEFAULT NULL COMMENT '币别名称',
  `symbol` varchar(20) DEFAULT NULL COMMENT '符号',
  `is_base` int DEFAULT '0' COMMENT '是否本位币',
  `decimal_digits` int DEFAULT '2' COMMENT '小数位',
  `status` int DEFAULT '1',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `md_currency_code_UK` (`code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='币别';

-- md_exchange_rate：汇率
CREATE TABLE `md_exchange_rate` (
  `id` bigint NOT NULL,
  `curr_id` bigint DEFAULT NULL COMMENT '币别ID',
  `rate_type` varchar(50) DEFAULT NULL COMMENT '汇率类型（buy买入/sell卖出/mid中间）',
  `rate` decimal(16,8) DEFAULT NULL COMMENT '汇率',
  `valid_date` date DEFAULT NULL COMMENT '生效日期',
  `create_by` varchar(200) DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `md_exchange_rate_curr_date_IDX` (`curr_id`,`valid_date`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='汇率';

-- ---------------------------------------------------------------------
-- 五、仓库与仓位
-- ---------------------------------------------------------------------

-- md_warehouse：仓库
CREATE TABLE `md_warehouse` (
  `id` bigint NOT NULL,
  `code` varchar(100) DEFAULT NULL COMMENT '仓库编码',
  `name` varchar(200) DEFAULT NULL COMMENT '仓库名称',
  `org_id` bigint DEFAULT NULL COMMENT '所属组织',
  `wh_type` varchar(50) DEFAULT NULL COMMENT '仓库类型（raw原料/fin成品/dye染化料/pack包装）',
  `batch_flag` int DEFAULT '0' COMMENT '是否批次管理',
  `manager_id` bigint DEFAULT NULL COMMENT '负责人',
  `address` varchar(500) DEFAULT NULL,
  `status` int DEFAULT '1',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `md_warehouse_code_UK` (`code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='仓库';

-- md_position：仓位
CREATE TABLE `md_position` (
  `id` bigint NOT NULL,
  `warehouse_id` bigint DEFAULT NULL COMMENT '仓库ID',
  `code` varchar(100) DEFAULT NULL COMMENT '仓位编码',
  `name` varchar(200) DEFAULT NULL COMMENT '仓位名称',
  `status` int DEFAULT '1',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `md_position_warehouse_id_IDX` (`warehouse_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='仓位';

-- ---------------------------------------------------------------------
-- 六、计量单位
-- ---------------------------------------------------------------------

-- md_unit：计量单位
CREATE TABLE `md_unit` (
  `id` bigint NOT NULL,
  `code` varchar(50) DEFAULT NULL COMMENT '单位编码（kg/lb/box/cone/hank）',
  `name` varchar(100) DEFAULT NULL COMMENT '单位名称（公斤/磅/箱/筒/绞）',
  `unit_type` varchar(50) DEFAULT NULL COMMENT '单位类型（weight重量/count数量）',
  `is_base` int DEFAULT '0' COMMENT '是否基本单位',
  `status` int DEFAULT '1',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `md_unit_code_UK` (`code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='计量单位';

-- md_unit_conv：物料单位换算
CREATE TABLE `md_unit_conv` (
  `id` bigint NOT NULL,
  `mat_id` bigint DEFAULT NULL COMMENT '物料ID',
  `from_unit_id` bigint DEFAULT NULL COMMENT '源单位',
  `to_unit_id` bigint DEFAULT NULL COMMENT '目标单位',
  `rate` decimal(16,8) DEFAULT NULL COMMENT '换算率',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `md_unit_conv_mat_id_IDX` (`mat_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='物料单位换算';

-- ---------------------------------------------------------------------
-- 七、品牌、色号、集锦卡、质量标准
-- ---------------------------------------------------------------------

-- md_brand：品牌
CREATE TABLE `md_brand` (
  `id` bigint NOT NULL,
  `code` varchar(100) DEFAULT NULL,
  `name` varchar(200) DEFAULT NULL,
  `status` int DEFAULT '1',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `md_brand_code_UK` (`code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='品牌';

-- md_color：色号
CREATE TABLE `md_color` (
  `id` bigint NOT NULL,
  `code` varchar(100) DEFAULT NULL COMMENT '色号编码',
  `name` varchar(200) DEFAULT NULL COMMENT '色号名称',
  `color_type` varchar(50) DEFAULT NULL COMMENT '类型（company公司色号/print打版色号）',
  `color_value` varchar(50) DEFAULT NULL COMMENT '色值',
  `color_sys_id` bigint DEFAULT NULL COMMENT '色系',
  `remark` mediumtext COMMENT '备注',
  `status` int DEFAULT '1',
  `create_by` varchar(200) DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  `update_by` varchar(200) DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `md_color_code_UK` (`code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='色号';

-- md_hl_card：集锦卡（纱线工艺集合卡，记录纱线规格工艺标准）
CREATE TABLE `md_hl_card` (
  `id` bigint NOT NULL,
  `code` varchar(100) DEFAULT NULL COMMENT '集锦卡编码',
  `name` varchar(200) DEFAULT NULL COMMENT '名称',
  `mat_id` bigint DEFAULT NULL COMMENT '物料',
  `yarn_count` decimal(16,8) DEFAULT NULL COMMENT '支数',
  `strand` decimal(16,8) DEFAULT NULL COMMENT '股数',
  `twist` varchar(100) DEFAULT NULL COMMENT '捻度',
  `fineness` varchar(200) DEFAULT NULL COMMENT '细度',
  `color_id` bigint DEFAULT NULL COMMENT '色号',
  `craft_desc` mediumtext COMMENT '工艺描述',
  `cn_name` varchar(200) DEFAULT NULL COMMENT '打印中文名',
  `en_name` varchar(200) DEFAULT NULL COMMENT '打印英文名',
  `sp_req` varchar(200) DEFAULT NULL COMMENT '特殊工艺要求',
  `sp_price` decimal(19,6) DEFAULT NULL COMMENT '特殊工艺费',
  `remark` mediumtext COMMENT '备注',
  `status` int DEFAULT '1',
  `create_by` varchar(200) DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  `update_by` varchar(200) DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `md_hl_card_code_UK` (`code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='集锦卡';

-- md_quality_std：质量标准
CREATE TABLE `md_quality_std` (
  `id` bigint NOT NULL,
  `code` varchar(100) DEFAULT NULL,
  `name` varchar(200) DEFAULT NULL,
  `std_desc` mediumtext COMMENT '标准描述',
  `status` int DEFAULT '1',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `md_quality_std_code_UK` (`code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='质量标准';

-- ---------------------------------------------------------------------
-- 八、贸易类型、结算方式、港口
-- ---------------------------------------------------------------------

-- md_trade_type：贸易类型/方式
CREATE TABLE `md_trade_type` (
  `id` bigint NOT NULL,
  `code` varchar(100) DEFAULT NULL,
  `name` varchar(200) DEFAULT NULL,
  `name_en` varchar(200) DEFAULT NULL,
  `trade_kind` varchar(50) DEFAULT NULL COMMENT '贸易种类（type类型/mode方式）',
  `status` int DEFAULT '1',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `md_trade_type_code_UK` (`code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='贸易类型方式';

-- md_firp_type：结算/收款方式
CREATE TABLE `md_firp_type` (
  `id` bigint NOT NULL,
  `code` varchar(100) DEFAULT NULL,
  `name` varchar(200) DEFAULT NULL,
  `firp_kind` varchar(50) DEFAULT NULL COMMENT '种类（settle结算/receipt收款/payment付款）',
  `status` int DEFAULT '1',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `md_firp_type_code_UK` (`code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='结算收款方式';

-- md_harbour：港口
CREATE TABLE `md_harbour` (
  `id` bigint NOT NULL,
  `code` varchar(100) DEFAULT NULL,
  `name_cn` varchar(200) DEFAULT NULL COMMENT '中文名',
  `name_en` varchar(200) DEFAULT NULL COMMENT '英文名',
  `country` varchar(100) DEFAULT NULL,
  `status` int DEFAULT '1',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `md_harbour_code_UK` (`code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='港口';

-- ---------------------------------------------------------------------
-- 九、物料分组、原料、原料分组
-- ---------------------------------------------------------------------

-- md_material_group：物料分组
CREATE TABLE `md_material_group` (
  `id` bigint NOT NULL,
  `code` varchar(200) DEFAULT NULL COMMENT '编码',
  `parent_id` bigint DEFAULT '0' COMMENT '上级关联',
  `enabled` int DEFAULT NULL COMMENT '是否启用',
  `cn_name` varchar(200) DEFAULT NULL COMMENT '名称',
  `en_name` varchar(200) DEFAULT NULL COMMENT '英文名称',
  `create_by` varchar(200) DEFAULT '' COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(200) DEFAULT '' COMMENT '修改人',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `auditor` varchar(200) DEFAULT NULL COMMENT '审核人',
  `audit_time` datetime DEFAULT NULL COMMENT '审核时间',
  `remark` mediumtext COMMENT '备注',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `md_material_group_code_IDX` (`code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='物料分组';

-- md_raw_material：原料档案
CREATE TABLE `md_raw_material` (
  `id` bigint NOT NULL,
  `code` varchar(200) DEFAULT NULL COMMENT '原料编码',
  `name` varchar(200) DEFAULT NULL COMMENT '原料名称',
  `cn_name` varchar(200) DEFAULT NULL COMMENT '打印中文名',
  `en_name` varchar(200) DEFAULT NULL COMMENT '打印英文名',
  `fineness` varchar(200) DEFAULT NULL COMMENT '细度',
  `s_fee` decimal(19,6) DEFAULT NULL COMMENT '加价纺工费',
  `damp` decimal(16,8) DEFAULT NULL COMMENT '公定回潮',
  `prd_name` varchar(200) DEFAULT NULL COMMENT '生产简称',
  `cm_rate` decimal(16,8) DEFAULT NULL COMMENT '羊绒比例%',
  `loss_rate` decimal(16,8) DEFAULT NULL COMMENT '标准损耗率%',
  `wool_rate` decimal(16,8) DEFAULT NULL COMMENT '羊毛比例%',
  `bulk_rate` decimal(16,8) DEFAULT NULL COMMENT '膨松系数',
  `product_type` varchar(200) DEFAULT NULL COMMENT '产品类别',
  `description` varchar(200) DEFAULT NULL COMMENT '描述',
  `recomb_rate` decimal(16,8) DEFAULT NULL COMMENT '复精梳折率(%)',
  `customs_name` varchar(200) DEFAULT NULL COMMENT '报关名称',
  `group_id` bigint DEFAULT NULL COMMENT '原料明细分组',
  `enabled` int DEFAULT NULL COMMENT '是否启用',
  `spin_type` varchar(200) DEFAULT NULL COMMENT '纺纱分类',
  `recomb_type` varchar(200) DEFAULT NULL COMMENT '复精梳分类',
  `prd_area` varchar(255) DEFAULT NULL COMMENT '产地',
  `remark` mediumtext COMMENT '备注',
  `create_by` varchar(200) DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(200) DEFAULT NULL COMMENT '修改人',
  `update_time` datetime DEFAULT NULL COMMENT '修改日期',
  `auditor` varchar(200) DEFAULT NULL COMMENT '审核人',
  `audit_time` datetime DEFAULT NULL COMMENT '审核时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `md_raw_material_code_IDX` (`code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='原料档案';

-- md_raw_material_detail：原料成分
CREATE TABLE `md_raw_material_detail` (
  `id` bigint NOT NULL,
  `sort_index` int DEFAULT NULL COMMENT '排序字段',
  `raw_mat_id` bigint DEFAULT NULL COMMENT '关联原料id',
  `mat_id` bigint DEFAULT NULL COMMENT '物料id',
  `ratio` decimal(16,4) DEFAULT NULL COMMENT '比例',
  `prd_addr_code` varchar(200) DEFAULT NULL COMMENT '产地代码',
  `prd_addr_name` varchar(200) DEFAULT NULL COMMENT '产地名称',
  `auth_type` varchar(200) DEFAULT NULL COMMENT '认证类型',
  `fineness` varchar(200) DEFAULT NULL COMMENT '细度',
  `cn_comp` varchar(200) DEFAULT NULL COMMENT '中文成分',
  `en_comp` varchar(200) DEFAULT NULL COMMENT '英文成分',
  `yarn_num` decimal(16,2) DEFAULT NULL COMMENT '支数',
  `line_num` decimal(16,0) DEFAULT NULL COMMENT '股数',
  `fiber_code` varchar(100) DEFAULT NULL COMMENT '纤维编码',
  `fiber_name` varchar(200) DEFAULT NULL COMMENT '纤维名称',
  `fiber_ratio` decimal(16,4) DEFAULT NULL COMMENT '纤维比例',
  `prd_area` varchar(255) DEFAULT NULL COMMENT '产地',
  `remark` mediumtext COMMENT '备注',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='原料成分';

-- md_raw_material_group：原料明细分组
CREATE TABLE `md_raw_material_group` (
  `id` bigint NOT NULL,
  `code` varchar(200) DEFAULT NULL COMMENT '编码',
  `parent_id` bigint DEFAULT '0' COMMENT '上级关联',
  `enabled` int DEFAULT NULL COMMENT '是否启用',
  `cn_name` varchar(200) DEFAULT NULL COMMENT '名称',
  `en_name` varchar(200) DEFAULT NULL COMMENT '英文名称',
  `create_by` varchar(200) DEFAULT '' COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(200) DEFAULT '' COMMENT '修改人',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `auditor` varchar(200) DEFAULT NULL COMMENT '审核人',
  `audit_time` datetime DEFAULT NULL COMMENT '审核时间',
  `remark` mediumtext COMMENT '备注',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='原料明细分组';

-- ---------------------------------------------------------------------
-- 十、公司色号、打版色号、色系
-- ---------------------------------------------------------------------

-- md_comp_color：公司色号
CREATE TABLE `md_comp_color` (
  `id` bigint NOT NULL,
  `code` varchar(200) DEFAULT NULL COMMENT '公司色号编码',
  `color_sys_id` bigint DEFAULT NULL COMMENT '色系',
  `cn_name` varchar(200) DEFAULT NULL COMMENT '色号名称',
  `is_ab_yarn` int DEFAULT NULL COMMENT '是否AB色',
  `color_name` varchar(200) DEFAULT NULL COMMENT '颜色名称',
  `enabled` int DEFAULT NULL COMMENT '是否启用',
  `create_by` varchar(200) DEFAULT '' COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(200) DEFAULT '' COMMENT '修改人',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `auditor` varchar(200) DEFAULT NULL COMMENT '审核人',
  `audit_time` datetime DEFAULT NULL COMMENT '审核时间',
  `remark` mediumtext COMMENT '备注',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `md_comp_color_code_IDX` (`code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='公司色号';

-- md_print_color：打版色号
CREATE TABLE `md_print_color` (
  `id` bigint NOT NULL,
  `code` varchar(255) DEFAULT NULL COMMENT '打版色号编码',
  `cn_name` varchar(200) DEFAULT NULL COMMENT '打版色号名称',
  `enabled` int DEFAULT NULL COMMENT '是否启用',
  `comp_color_id` bigint DEFAULT NULL COMMENT '公司色号',
  `color_sys_id` bigint DEFAULT NULL COMMENT '色系',
  `color_name` varchar(200) DEFAULT NULL COMMENT '颜色名称',
  `dye_method_id` varchar(200) DEFAULT NULL COMMENT '染色方式',
  `create_by` varchar(200) DEFAULT '' COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(200) DEFAULT '' COMMENT '修改人',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `auditor` varchar(200) DEFAULT NULL COMMENT '审核人',
  `audit_time` datetime DEFAULT NULL COMMENT '审核时间',
  `remark` mediumtext COMMENT '备注',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `md_print_color_code_IDX` (`code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='打版色号';

-- md_color_series：色系
CREATE TABLE `md_color_series` (
  `id` bigint NOT NULL,
  `code` varchar(200) DEFAULT NULL COMMENT '色系编号',
  `enabled` int DEFAULT NULL COMMENT '是否启用',
  `cn_name` varchar(200) DEFAULT NULL COMMENT '色系名称',
  `create_by` varchar(200) DEFAULT '' COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(200) DEFAULT '' COMMENT '修改人',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `auditor` varchar(200) DEFAULT NULL COMMENT '审核人',
  `audit_time` datetime DEFAULT NULL COMMENT '审核时间',
  `remark` mediumtext COMMENT '备注',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `md_color_series_code_IDX` (`code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='色系';

-- ---------------------------------------------------------------------
-- 十一、业务员、跟单员
-- ---------------------------------------------------------------------

-- sys_saler：业务员
CREATE TABLE `sys_saler` (
  `id` bigint NOT NULL,
  `code` varchar(200) DEFAULT NULL COMMENT '编号',
  `staff_id` bigint DEFAULT NULL COMMENT '员工',
  `dept_id` bigint DEFAULT NULL COMMENT '部门',
  `is_cal_biz_fee` tinyint DEFAULT NULL COMMENT '是否计算业务费',
  `enabled` int DEFAULT NULL COMMENT '是否启用',
  `create_by` varchar(200) DEFAULT '' COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(200) DEFAULT '' COMMENT '修改人',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `auditor` varchar(200) DEFAULT NULL COMMENT '审核人',
  `audit_time` datetime DEFAULT NULL COMMENT '审核时间',
  `remark` mediumtext COMMENT '备注',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `sys_saler_staff_id_IDX` (`staff_id`) USING BTREE,
  KEY `sys_saler_code_IDX` (`code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='业务员';

-- sys_merchandiser：跟单员
CREATE TABLE `sys_merchandiser` (
  `id` bigint NOT NULL,
  `code` varchar(200) DEFAULT NULL COMMENT '跟单编号',
  `staff_id` bigint DEFAULT NULL COMMENT '员工',
  `enabled` int DEFAULT NULL COMMENT '是否启用',
  `create_by` varchar(200) DEFAULT '' COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(200) DEFAULT '' COMMENT '修改人',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `auditor` varchar(200) DEFAULT NULL COMMENT '审核人',
  `audit_time` datetime DEFAULT NULL COMMENT '审核时间',
  `remark` mediumtext COMMENT '备注',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='跟单员';

-- ---------------------------------------------------------------------
-- 十二、印章、箱贴打印模板
-- ---------------------------------------------------------------------

-- md_seal：印章
CREATE TABLE `md_seal` (
  `id` bigint NOT NULL,
  `code` varchar(255) DEFAULT NULL COMMENT '印章编码',
  `stamp_name` varchar(100) DEFAULT NULL COMMENT '印章名称',
  `company_id` bigint DEFAULT NULL COMMENT '所属公司',
  `stamp_admin` bigint DEFAULT NULL COMMENT '印章管理员',
  `create_by` varchar(255) DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(255) DEFAULT NULL COMMENT '修改人',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='印章';

-- md_box_label_tpl：箱贴打印模板
CREATE TABLE `md_box_label_tpl` (
  `id` bigint NOT NULL,
  `code` varchar(255) DEFAULT NULL COMMENT '模板编码',
  `cn_name` varchar(255) DEFAULT NULL COMMENT '中文名称',
  `en_name` varchar(255) DEFAULT NULL COMMENT '英文名称',
  `org_id` bigint DEFAULT NULL COMMENT '销售组织',
  `is_en_print` int DEFAULT '0' COMMENT '是否英文打印',
  `enabled` int DEFAULT NULL COMMENT '是否启用',
  `remark` mediumtext COMMENT '备注',
  `create_by` varchar(255) NOT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(255) DEFAULT NULL COMMENT '修改人',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `auditor` varchar(255) DEFAULT NULL COMMENT '审核人',
  `audit_time` datetime DEFAULT NULL COMMENT '审核时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='箱贴打印模板';

-- ---------------------------------------------------------------------
-- 十三、特殊纺工费
-- ---------------------------------------------------------------------

-- md_spin_fee：特殊纺工费
CREATE TABLE `md_spin_fee` (
  `id` bigint NOT NULL,
  `code` varchar(200) DEFAULT NULL COMMENT '单据编号',
  `remark` mediumtext COMMENT '备注',
  `create_by` varchar(200) DEFAULT '' COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(200) DEFAULT '' COMMENT '修改人',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `auditor` varchar(200) DEFAULT NULL COMMENT '审核人',
  `audit_time` datetime DEFAULT NULL COMMENT '审核时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='特殊纺工费';

-- md_spin_fee_material：特殊纺工费关联物料
CREATE TABLE `md_spin_fee_material` (
  `id` bigint NOT NULL,
  `sort_index` int DEFAULT NULL COMMENT '排序字段',
  `spin_fee_id` bigint DEFAULT NULL COMMENT '特殊纺工费id',
  `mat_id` bigint DEFAULT NULL COMMENT '物料id',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='特殊纺工费关联物料';

-- md_spin_fee_raw_material：特殊纺工费关联原料
CREATE TABLE `md_spin_fee_raw_material` (
  `id` bigint NOT NULL,
  `sort_index` int DEFAULT NULL COMMENT '排序字段',
  `spin_fee_id` bigint DEFAULT NULL COMMENT '特殊纺工费id',
  `raw_mat_id` bigint DEFAULT NULL COMMENT '原料明细id',
  `s_fee` decimal(19,6) DEFAULT NULL COMMENT '纺工费',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='特殊纺工费关联原料';

-- ---------------------------------------------------------------------
-- 十四、信用管理
-- ---------------------------------------------------------------------

-- md_credit：信用管理
CREATE TABLE `md_credit` (
  `id` bigint NOT NULL,
  `code` varchar(255) DEFAULT NULL COMMENT '单据编号',
  `org_id` bigint DEFAULT NULL COMMENT '组织id',
  `is_group_credit` int DEFAULT NULL COMMENT '是否集团身份授信（0单组织授信 1集团身份授信）',
  `cust_type` int DEFAULT NULL COMMENT '授信对象（0单公司 1集团）',
  `remark` mediumtext COMMENT '备注',
  `create_by` varchar(255) DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(255) DEFAULT NULL COMMENT '修改人',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `auditor` varchar(255) DEFAULT NULL COMMENT '审核人',
  `audit_time` datetime DEFAULT NULL COMMENT '审核时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `md_credit_code_IDX` (`code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='信用管理';

-- md_credit_detail：信用管理客户明细
CREATE TABLE `md_credit_detail` (
  `id` bigint NOT NULL,
  `sort_index` int DEFAULT NULL COMMENT '排序字段',
  `credit_id` bigint DEFAULT NULL COMMENT '关联表头id',
  `cust_id` bigint DEFAULT NULL COMMENT '客户id',
  `curr_id` bigint DEFAULT NULL COMMENT '币别id',
  `amount` decimal(19,6) DEFAULT NULL COMMENT '额度',
  `amount_status` varchar(255) DEFAULT NULL COMMENT '额度状态（0正常 1超额）',
  `valid_time` date DEFAULT NULL COMMENT '额度有效期',
  `credit_status` varchar(255) DEFAULT NULL COMMENT '有效状态（0有效 1失效）',
  `overdue_days` int DEFAULT NULL COMMENT '逾期天数',
  `remark` mediumtext COMMENT '备注',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `md_credit_detail_cust_id_IDX` (`cust_id`) USING BTREE,
  KEY `md_credit_detail_credit_id_IDX` (`credit_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='信用管理客户明细';
