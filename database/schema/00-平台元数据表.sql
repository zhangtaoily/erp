-- =====================================================================
-- 00-平台元数据表（BOS 动态领域建模底座）
-- 说明：业务对象建模、表单元数据、字段元数据、状态机、下推规则、
--       按钮、查询方案、打印模板（类Excel单元格）、变更日志、操作日志、
--       编码规则（段定义）、插件机制（金蝶BOS三基类）、实体服务规则、
--       反写规则、权限体系、组织架构、附件、导入导出、API日志。
-- 命名约定：表前缀 meta_/sys_/biz_/data_/field_/user_
--           主键统一为 id bigint（雪花ID，非自增），全表沿用此约定。
-- 字段约定：create_by/create_time/update_by/update_time 为公共审计字段。
-- 版本：v2.0  2026-07-04  对齐 BOS 原型（三基类插件/段式编码/类Excel打印）
-- 版本：v2.1  2026-07-04  Java类插件改为反射自描述模型（base_class/class_base/class_name/class_file 反射自动识别；
--                         meta_plugin_param 新增 default_value 列，参数结构由注解自动发现，仅 param_value 用户填写）
-- 版本：v2.2  2026-07-04  插件参数零配置：移除 meta_plugin_param.param_value 列（不再有管理员填写项）；
--                         @FormParam.key 直接=单据字段编码（运行时读取 bill_data[key] 注入），
--                         @BehaviorParam.defaultValue=运行时值（系统注入），管理员无需配置任何参数
-- =====================================================================

-- ---------------------------------------------------------------------
-- 一、业务对象与实体建模（BOS 元数据核心）
-- ---------------------------------------------------------------------

-- meta_business_object：业务对象定义（BOS 建模入口，所有单据/基础资料的注册锚点）
CREATE TABLE `meta_business_object` (
  `id` bigint NOT NULL COMMENT '主键（雪花ID）',
  `bo_code` varchar(50) NOT NULL COMMENT '业务对象编码（全局唯一，如 SAL_ORDER）',
  `bo_name` varchar(100) NOT NULL COMMENT '业务对象名称（如 销售订单）',
  `bo_type` varchar(20) NOT NULL COMMENT '类型：bill单据/master基础资料/report报表',
  `main_table` varchar(100) NOT NULL COMMENT '主表物理表名（如 sal_order）',
  `main_key` varchar(50) NOT NULL DEFAULT 'id' COMMENT '主键字段名',
  `pk_strategy` varchar(20) NOT NULL DEFAULT 'snowflake' COMMENT '主键策略：auto自增/snowflake雪花/uuid',
  `is_stateful` tinyint NOT NULL DEFAULT 1 COMMENT '是否支持状态机（0否 1是）',
  `is_pushable` tinyint NOT NULL DEFAULT 1 COMMENT '是否支持下推（0否 1是）',
  `is_printable` tinyint NOT NULL DEFAULT 1 COMMENT '是否支持打印（0否 1是）',
  `org_type` varchar(20) DEFAULT NULL COMMENT '适用组织类型（group/company/factory/workshop/business）',
  `status` tinyint NOT NULL DEFAULT 1 COMMENT '状态：0停用 1启用',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `create_by` varchar(200) DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  `update_by` varchar(200) DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_bo_code` (`bo_code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='BOS 业务对象定义（动态领域建模入口）';

-- meta_form_entity：实体层级（主表/子表/孙表三级嵌套）
CREATE TABLE `meta_form_entity` (
  `id` bigint NOT NULL,
  `bo_code` varchar(50) NOT NULL COMMENT '所属业务对象编码',
  `entity_code` varchar(50) NOT NULL COMMENT '实体编码（如 sal_order / sal_order_goods / sal_order_goods_assign）',
  `entity_name` varchar(100) NOT NULL COMMENT '实体名称（如 单据头 / 明细 / 指定用料）',
  `entity_type` varchar(20) NOT NULL COMMENT '实体类型：main主表/sub子表/grandchild孙表',
  `entity_level` int NOT NULL DEFAULT 0 COMMENT '层级（0主 1子 2孙）',
  `table_name` varchar(100) NOT NULL COMMENT '物理表名',
  `parent_entity_code` varchar(50) DEFAULT NULL COMMENT '父实体编码（子表填主表编码，孙表填子表编码）',
  `link_field` varchar(100) DEFAULT NULL COMMENT '关联父表的外键字段（如 order_id）',
  `sort_index` int DEFAULT 0 COMMENT '页签排序',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_bo_entity` (`bo_code`,`entity_code`) USING BTREE,
  KEY `idx_bo_code` (`bo_code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='实体层级（主/子/孙三级嵌套）';

-- meta_form_field：字段元数据（驱动表单渲染、校验、计算）
CREATE TABLE `meta_form_field` (
  `id` bigint NOT NULL,
  `bo_code` varchar(50) NOT NULL COMMENT '所属业务对象编码',
  `entity_code` varchar(50) NOT NULL COMMENT '所属实体编码',
  `field_code` varchar(100) NOT NULL COMMENT '字段编码（即物理列名）',
  `field_name` varchar(200) NOT NULL COMMENT '字段显示名',
  `field_type` varchar(50) NOT NULL COMMENT '字段数据类型：text/number/date/datetime/enum/ref/bool/amount/qty/attachment',
  `ctrl_type` varchar(50) NOT NULL COMMENT '控件类型：text/textarea/number/date/datetime/select/ref/amount/qty/checkbox/attachment/subtable/grandchild',
  `data_type` varchar(50) DEFAULT NULL COMMENT '数据库类型（varchar/decimal/datetime/int）',
  `data_length` int DEFAULT NULL COMMENT '长度',
  `data_precision` int DEFAULT NULL COMMENT '精度（总位数）',
  `data_scale` int DEFAULT NULL COMMENT '小数位',
  `is_required` tinyint DEFAULT 0 COMMENT '是否必填（0否 1是）',
  `is_readonly` tinyint DEFAULT 0 COMMENT '是否只读（0否 1是）',
  `is_hidden` tinyint DEFAULT 0 COMMENT '是否隐藏（0否 1是）',
  `is_system` tinyint DEFAULT 0 COMMENT '是否系统字段（不可删，如 id/pact_state/create_by）',
  `default_value` varchar(500) DEFAULT NULL COMMENT '默认值（可为基础数据值 TODAY/CNY/1 或表达式）',
  `validate_rule` varchar(500) DEFAULT NULL COMMENT '校验规则表达式',
  `ref_bo_code` varchar(50) DEFAULT NULL COMMENT '引用基础资料的业务对象编码（field_type=ref 时填写）',
  `enum_code` varchar(50) DEFAULT NULL COMMENT '枚举编码（field_type=enum 时关联 meta_enum）',
  `formula` varchar(1000) DEFAULT NULL COMMENT '计算公式（如 qty*price，由实体服务规则calc类型执行）',
  `summary_to` varchar(100) DEFAULT NULL COMMENT '汇总到主表字段（如 amount 汇总到 total_amount）',
  `group_name` varchar(100) DEFAULT NULL COMMENT '字段分组（如 基本信息/汇总/系统/其他）',
  `col_width` int DEFAULT NULL COMMENT '列表列宽',
  `sort_index` int DEFAULT 0 COMMENT '排序',
  `remark` varchar(500) DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_bo_entity` (`bo_code`,`entity_code`) USING BTREE,
  KEY `idx_field_code` (`field_code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='字段元数据（驱动动态表单渲染）';

-- meta_enum / meta_enum_item：枚举定义
CREATE TABLE `meta_enum` (
  `id` bigint NOT NULL,
  `enum_code` varchar(100) NOT NULL COMMENT '枚举编码（唯一，如 PACT_STATE）',
  `enum_name` varchar(200) DEFAULT NULL COMMENT '枚举名称',
  `remark` varchar(500) DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_enum_code` (`enum_code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='枚举定义';

CREATE TABLE `meta_enum_item` (
  `id` bigint NOT NULL,
  `enum_code` varchar(100) NOT NULL COMMENT '枚举编码',
  `item_value` int DEFAULT NULL COMMENT '枚举值',
  `item_name` varchar(200) DEFAULT NULL COMMENT '枚举名',
  `item_color` varchar(20) DEFAULT NULL COMMENT '色系（如 info/primary/warning/success/danger）',
  `sort_index` int DEFAULT 0,
  `is_default` tinyint DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_enum_code` (`enum_code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='枚举项';

-- meta_form_layout：表单布局元数据（页签/分组/字段位置）
CREATE TABLE `meta_form_layout` (
  `id` bigint NOT NULL,
  `bo_code` varchar(50) NOT NULL COMMENT '业务对象编码',
  `layout_code` varchar(100) DEFAULT NULL COMMENT '布局编码',
  `layout_name` varchar(200) DEFAULT NULL COMMENT '布局名称',
  `layout_json` mediumtext COMMENT '布局JSON（页签/分组/字段位置/列宽）',
  `is_default` tinyint DEFAULT 0 COMMENT '是否默认布局',
  `create_by` varchar(200) DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_bo_code` (`bo_code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='表单布局元数据';

-- ---------------------------------------------------------------------
-- 二、状态机（5状态标准模型 + is_closed/is_cancel 辅助标记）
-- ---------------------------------------------------------------------

-- meta_state_machine：状态机定义
CREATE TABLE `meta_state_machine` (
  `id` bigint NOT NULL,
  `code` varchar(100) NOT NULL COMMENT '状态机编码（唯一）',
  `name` varchar(200) DEFAULT NULL COMMENT '状态机名称',
  `state_field` varchar(100) DEFAULT 'pact_state' COMMENT '状态字段名',
  `remark` varchar(500) DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_state_machine_code` (`code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='状态机定义';

-- meta_state_node：状态节点
-- 状态码约定：0暂存 1已创建 2已提交 3已审核 4已驳回（自定义状态码可 >=5）
-- 关闭/取消不占用状态码，改用 is_closed/is_cancel 字段记录（与 pact_state 正交）
CREATE TABLE `meta_state_node` (
  `id` bigint NOT NULL,
  `machine_id` bigint NOT NULL COMMENT '状态机ID',
  `state_value` int NOT NULL COMMENT '状态值（0暂存 1已创建 2已提交 3已审核 4已驳回；自定义状态码可 >=5）',
  `state_name` varchar(100) DEFAULT NULL COMMENT '状态名',
  `state_color` varchar(20) DEFAULT NULL COMMENT '状态色 hex（如 #909399；按 state_value 动态映射，自定义状态码可着色）',
  `is_initial` tinyint DEFAULT 0 COMMENT '是否初始状态（暂存为初始态）',
  `is_final` tinyint DEFAULT 0 COMMENT '是否终态',
  `is_editable` tinyint DEFAULT 0 COMMENT '该状态下单据是否可编辑',
  `is_deletable` tinyint DEFAULT 0 COMMENT '该状态下单据是否可删除',
  `pos_x` int DEFAULT NULL COMMENT '画布 X 坐标（节点拖拽位置持久化，GAP-D03-004 / RISK-D03-003）',
  `pos_y` int DEFAULT NULL COMMENT '画布 Y 坐标（节点拖拽位置持久化，GAP-D03-004 / RISK-D03-003）',
  `sort_index` int DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_machine_id` (`machine_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='状态节点（0暂存1已创建2已提交3已审核4已驳回；自定义状态码可扩展；关闭/取消用 is_closed/is_cancel）';

-- meta_state_transition：状态流转（from→to + 触发按钮 + 前置校验 + 后置动作 + 工作流）
-- 标准流转17条：保存(0→1)/暂存(0→0)/提交(1→2)/审核(2→3)/驳回(2→4)/重新提交(4→2)
--               撤销反提交(2→1)/撤销反审核(3→1)/删除(0/1/4→-1)
--               关闭(3→3,is_closed=1)/反关闭(3→3,is_closed=0)
--               取消(3→3,is_cancel=1)/反取消(3→3,is_cancel=0)
--               变更(3→3,生成变更单)/下推(3→3,pre_check校验可下推量)
CREATE TABLE `meta_state_transition` (
  `id` bigint NOT NULL,
  `machine_id` bigint NOT NULL COMMENT '状态机ID',
  `from_state` int DEFAULT NULL COMMENT '源状态（0暂存1已创建2已提交3已审核4已驳回）',
  `to_state` int DEFAULT NULL COMMENT '目标状态',
  `action_name` varchar(100) DEFAULT NULL COMMENT '操作名称（如 保存/提交/审核/驳回/撤销/关闭/取消/变更/下推）',
  `button_code` varchar(100) DEFAULT NULL COMMENT '触发按钮编码（save/submit/audit/revoke/reject/resubmit/delete/close/cancel/change/push）',
  `pre_check` varchar(1000) DEFAULT NULL COMMENT '前置校验表达式（如校验下游单据是否存在、可下推量）',
  `post_action` varchar(1000) DEFAULT NULL COMMENT '后置动作（如立账/生成凭证/更新库存/is_closed=1）',
  `need_wf` tinyint DEFAULT 0 COMMENT '是否触发外部工作流（提交/变更需推送审批流）',
  `wf_push_api` varchar(500) DEFAULT NULL COMMENT '工作流推送 API 地址（need_wf=1 时配置，如 /api/wf/start，GAP-D03-008 / PRD 02.1.3）',
  `wf_callback_url` varchar(500) DEFAULT NULL COMMENT '工作流回调 URL（外部系统回调 ERP 的接口路径，如 /api/wf/callback，GAP-D03-008）',
  `wf_callback_display` varchar(500) DEFAULT NULL COMMENT '回调展示字段说明（如 wf_request_id / pact_state 回写规则，GAP-D03-008）',
  `require_reason` tinyint DEFAULT 0 COMMENT '是否要求填写原因（驳回/重新提交/删除/变更需填原因）',
  `sort_index` int DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_machine_id` (`machine_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='状态流转定义（含驳回/关闭/取消/变更/下推流转）';

-- ---------------------------------------------------------------------
-- 三、按钮与下推转换
-- ---------------------------------------------------------------------

-- meta_button：按钮定义（15个标准按钮 + 自定义按钮）
-- 标准按钮：add/copy/draft/save/submit/audit/revoke/reject/delete/close/cancel/change/push/trace/print
CREATE TABLE `meta_button` (
  `id` bigint NOT NULL,
  `button_code` varchar(100) NOT NULL COMMENT '按钮编码（唯一）',
  `button_name` varchar(200) DEFAULT NULL COMMENT '按钮名称',
  `button_type` varchar(50) DEFAULT NULL COMMENT '按钮类型：standard标准 custom自定义',
  `icon` varchar(200) DEFAULT NULL COMMENT '图标',
  `location` varchar(50) DEFAULT NULL COMMENT '位置：form表单/list列表/both均显示',
  `exec_order` int DEFAULT 0 COMMENT '排序',
  `remark` varchar(500) DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_button_code` (`button_code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='按钮定义（标准+自定义）';

-- meta_form_button：表单-按钮绑定 + 可用性矩阵 + 二次确认 + 插件
-- 可用性4档：enabled可用/disabled禁用/hidden隐藏/readonly只读 × 5状态(0/1/2/3/4)
CREATE TABLE `meta_form_button` (
  `id` bigint NOT NULL,
  `bo_code` varchar(50) NOT NULL COMMENT '业务对象编码',
  `button_code` varchar(100) NOT NULL COMMENT '按钮编码',
  `availability_json` varchar(500) DEFAULT NULL COMMENT '可用性矩阵JSON（5状态对应的enabled/disabled/hidden/readonly）',
  `plugin_event` varchar(100) DEFAULT NULL COMMENT '点击触发的插件事件（如 BarItemClick）',
  `confirm_msg` varchar(500) DEFAULT NULL COMMENT '二次确认提示',
  `sort_index` int DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_bo_button` (`bo_code`,`button_code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='表单按钮绑定（含可用性矩阵）';

-- meta_push_rule：下推转换规则（源单→目标单）
CREATE TABLE `meta_push_rule` (
  `id` bigint NOT NULL,
  `rule_code` varchar(100) NOT NULL COMMENT '规则编码（唯一）',
  `rule_name` varchar(200) DEFAULT NULL COMMENT '规则名称',
  `src_bo_code` varchar(50) NOT NULL COMMENT '源业务对象编码',
  `tgt_bo_code` varchar(50) NOT NULL COMMENT '目标业务对象编码',
  `field_mapping_json` mediumtext COMMENT '字段映射JSON（src_field/target_field/is_main主表或子表/transform_expr）',
  `vp_check_expr` varchar(1000) DEFAULT NULL COMMENT '可下推量校验表达式（如 F.qty - F.out_qty > 0）',
  `filter_expr` varchar(1000) DEFAULT NULL COMMENT '过滤条件表达式（如 F.pact_state == 3 AND F.is_closed == 0）',
  `qty_field` varchar(100) DEFAULT NULL COMMENT '可下推数量字段',
  `pushed_field` varchar(100) DEFAULT NULL COMMENT '已下推量回写字段',
  `allow_merge` tinyint DEFAULT 0 COMMENT '是否允许合并下推（多源单→一目标单）',
  `allow_split` tinyint DEFAULT 0 COMMENT '是否允许拆分下推（一源单行→多目标单）',
  `is_enable` tinyint DEFAULT 1,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_push_rule_code` (`rule_code`) USING BTREE,
  KEY `idx_src_tgt` (`src_bo_code`,`tgt_bo_code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='下推转换规则';

-- biz_bill_link：单据上下游关联（联查依据，下推时自动写入）
CREATE TABLE `biz_bill_link` (
  `id` bigint NOT NULL,
  `src_bo_code` varchar(50) DEFAULT NULL COMMENT '源单业务对象编码',
  `src_bill_id` bigint DEFAULT NULL COMMENT '源单ID',
  `src_line_id` bigint DEFAULT NULL COMMENT '源单行ID',
  `tgt_bo_code` varchar(50) DEFAULT NULL COMMENT '目标单业务对象编码',
  `tgt_bill_id` bigint DEFAULT NULL COMMENT '目标单ID',
  `tgt_line_id` bigint DEFAULT NULL COMMENT '目标单行ID',
  `link_qty` decimal(19,6) DEFAULT NULL COMMENT '关联数量',
  `push_rule_code` varchar(100) DEFAULT NULL COMMENT '转换规则编码',
  `create_by` varchar(200) DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_src` (`src_bo_code`,`src_bill_id`,`src_line_id`) USING BTREE,
  KEY `idx_tgt` (`tgt_bo_code`,`tgt_bill_id`,`tgt_line_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='单据上下游关联（联查追溯依据）';

-- ---------------------------------------------------------------------
-- 四、变更日志与操作日志
-- ---------------------------------------------------------------------

-- biz_change_log：字段级变更日志（变更单留痕）
CREATE TABLE `biz_change_log` (
  `id` bigint NOT NULL,
  `bo_code` varchar(50) DEFAULT NULL COMMENT '业务对象编码',
  `bill_id` bigint DEFAULT NULL COMMENT '单据ID',
  `entity_code` varchar(50) DEFAULT NULL COMMENT '实体编码',
  `line_id` bigint DEFAULT NULL COMMENT '行ID',
  `field_code` varchar(100) DEFAULT NULL COMMENT '字段编码',
  `field_name` varchar(200) DEFAULT NULL COMMENT '字段名',
  `old_value` mediumtext COMMENT '旧值',
  `new_value` mediumtext COMMENT '新值',
  `change_code` varchar(200) DEFAULT NULL COMMENT '变更单号',
  `change_reason` varchar(2000) DEFAULT NULL COMMENT '变更原因',
  `change_by` varchar(200) DEFAULT NULL COMMENT '变更人',
  `change_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_bill` (`bo_code`,`bill_id`) USING BTREE,
  KEY `idx_change_code` (`change_code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='字段级变更日志';

-- biz_op_log：业务操作日志（状态变更全记录）
CREATE TABLE `biz_op_log` (
  `id` bigint NOT NULL,
  `bo_code` varchar(50) DEFAULT NULL COMMENT '业务对象编码',
  `bill_id` bigint DEFAULT NULL COMMENT '单据ID',
  `bill_code` varchar(200) DEFAULT NULL COMMENT '单据编号',
  `op_type` varchar(50) DEFAULT NULL COMMENT '操作类型（save/submit/audit/revoke/reject/delete/close/cancel/change/push/print）',
  `from_state` int DEFAULT NULL COMMENT '操作前状态',
  `to_state` int DEFAULT NULL COMMENT '操作后状态',
  `op_remark` varchar(2000) DEFAULT NULL COMMENT '操作说明/原因',
  `op_by` varchar(200) DEFAULT NULL COMMENT '操作人',
  `op_time` datetime DEFAULT NULL,
  `ip` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_bill` (`bo_code`,`bill_id`) USING BTREE,
  KEY `idx_op_by` (`op_by`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='业务操作日志';

-- ---------------------------------------------------------------------
-- 五、编码规则（段定义模型：prefix/date/serial/fixed/variable）
-- ---------------------------------------------------------------------

-- meta_code_rule：编码规则定义（段式编排，与业务对象 bo_code 关联）
CREATE TABLE `meta_code_rule` (
  `id` bigint NOT NULL,
  `rule_code` varchar(50) NOT NULL COMMENT '规则编码（唯一）',
  `rule_name` varchar(100) NOT NULL COMMENT '规则名称',
  `bo_code` varchar(50) NOT NULL COMMENT '业务对象编码',
  `org_id` bigint DEFAULT NULL COMMENT '适用组织（空=全组织通用）',
  `segments_json` text NOT NULL COMMENT '段定义JSON（数组，每段含 type/value/format/digits/var_code/sort）',
  `reset_type` varchar(20) NOT NULL DEFAULT 'year' COMMENT '流水重置类型：none不重置/year按年/month按月/org_year按组织+年',
  `is_manual` tinyint NOT NULL DEFAULT 0 COMMENT '是否允许手动录入（0否 1是）',
  `status` tinyint NOT NULL DEFAULT 1 COMMENT '状态：0停用 1启用',
  `remark` varchar(500) DEFAULT NULL,
  `create_by` varchar(200) DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  `update_by` varchar(200) DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_code_rule_code` (`rule_code`) USING BTREE,
  KEY `idx_bo_code` (`bo_code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='编码规则定义（段式编排）';

-- meta_code_serial：编码流水记录（配合 meta_code_rule，并发安全行锁）
CREATE TABLE `meta_code_serial` (
  `id` bigint NOT NULL,
  `rule_code` varchar(50) NOT NULL COMMENT '规则编码',
  `org_id` bigint DEFAULT NULL COMMENT '组织ID（按组织+年重置时使用）',
  `period` varchar(20) NOT NULL COMMENT '周期标识（如 2026 / 202607 / 2026_001）',
  `current_serial` bigint NOT NULL DEFAULT 0 COMMENT '当前流水值',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_rule_org_period` (`rule_code`,`org_id`,`period`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='编码流水记录（并发安全）';

-- ---------------------------------------------------------------------
-- 六、插件机制（金蝶BOS三基类：BillPlugin/ListPlugin/OperationServicePlugin）
-- ---------------------------------------------------------------------

-- meta_form_plugin：插件绑定（金蝶BOS风格，3基类 + 3插件类型 + 上下文传递）
-- 基类：BillPlugin(表单插件,13事件) / ListPlugin(列表插件,5事件) / OperationServicePlugin(操作服务插件,6流水线事件)
-- 插件类型：script脚本 / api外部API / class Java类上传
-- 事务边界：整个操作（含插件与主流程），插件异常默认阻断并回滚
-- 自描述模型：plugin_type=class 时，base_class/class_base/class_name/class_file 由系统上传时反射 superclass 链
--           自动识别回填（非用户填写）；参数结构由 @FormParam/@BehaviorParam 注解声明、反射扫描自动发现
CREATE TABLE `meta_form_plugin` (
  `id` bigint NOT NULL,
  `plugin_code` varchar(50) NOT NULL COMMENT '插件编码（唯一，如 SO_AFTER_AUDIT）',
  `plugin_name` varchar(200) NOT NULL COMMENT '插件名称',
  `bo_code` varchar(50) NOT NULL COMMENT '所属业务对象编码',
  `base_class` varchar(50) NOT NULL DEFAULT 'BillPlugin' COMMENT '系统基类：BillPlugin表单/ListPlugin列表/OperationServicePlugin操作服务（class类型由系统反射自动识别回填，非用户填写）',
  `event_name` varchar(50) NOT NULL COMMENT '绑定事件（按基类决定可选事件集）',
  `field_code` varchar(100) DEFAULT NULL COMMENT '字段级事件触发字段（如 DataChanged 事件的 mat_id/qty）',
  `plugin_type` varchar(20) NOT NULL DEFAULT 'script' COMMENT '插件类型：script脚本/api外部API/class Java类',
  `exec_order` int NOT NULL DEFAULT 10 COMMENT '执行顺序（升序，前置返回false或抛异常阻断后续）',
  `status` tinyint NOT NULL DEFAULT 1 COMMENT '状态：0停用 1启用',
  `remark` varchar(500) DEFAULT NULL,
  -- 脚本插件
  `script_content` mediumtext COMMENT '脚本内容（plugin_type=script，ANTLR4表达式引擎）',
  -- API 插件
  `api_url` varchar(500) DEFAULT NULL COMMENT 'API地址（plugin_type=api）',
  `api_method` varchar(10) DEFAULT 'POST' COMMENT 'HTTP方法（GET/POST/PUT/DELETE）',
  `api_headers` varchar(1000) DEFAULT NULL COMMENT 'API请求头JSON',
  `api_timeout` int DEFAULT 10 COMMENT 'API超时秒数',
  -- Java 类插件（自描述模型：以下四项由系统上传时反射自动识别回填，非用户填写）
  `class_name` varchar(300) DEFAULT NULL COMMENT '实现类全限定名（系统反射自动识别，如 com.eerp.plugin.sal.SalOrderCreditValidator）',
  `class_file` varchar(500) DEFAULT NULL COMMENT '上传的 class/jar 文件路径（系统自动存储）',
  `class_base` varchar(300) DEFAULT NULL COMMENT '继承的系统基类全限定名（系统反射 superclass 链自动识别，如 com.eerp.plugin.base.AbstractOperationServicePlugIn）',
  `create_by` varchar(200) DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  `update_by` varchar(200) DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_plugin_code` (`plugin_code`) USING BTREE,
  KEY `idx_bo_base` (`bo_code`,`base_class`) USING BTREE,
  KEY `idx_event` (`event_name`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='插件绑定（金蝶BOS三基类，script/api/class三种类型；class类型采用反射自描述模型）';

-- meta_plugin_param：Java类插件传入参数（表单参数 form + 行为参数 behavior）
-- 自描述模型（参数零配置）：param_key/param_label/param_type/default_value 全部由系统反射扫描
--           @FormParam/@BehaviorParam 注解自动生成，无管理员配置项；运行时系统按 param_type 自动注入：
--           form 类型读取 bill_data[param_key]（param_key=单据字段编码），behavior 类型注入 default_value
-- 通过基类 PluginContext 传递给插件实现类
CREATE TABLE `meta_plugin_param` (
  `id` bigint NOT NULL,
  `plugin_code` varchar(50) NOT NULL COMMENT '插件编码',
  `param_key` varchar(100) NOT NULL COMMENT '参数键（注解自动发现）：form类型=单据字段编码（如 cust_credit，运行时读取 bill_data[param_key]）；behavior类型=参数名（如 over_action）',
  `param_label` varchar(200) DEFAULT NULL COMMENT '参数标签（注解自动发现，来自注解 label 属性，如 信用额度字段）',
  `param_type` varchar(20) NOT NULL DEFAULT 'form' COMMENT '参数类型（注解自动发现）：form表单参数(@FormParam,运行时取单据字段值) / behavior行为参数(@BehaviorParam,运行时取default_value)',
  `default_value` varchar(500) DEFAULT NULL COMMENT '运行时值（注解自动发现，来自 @BehaviorParam.defaultValue，如 block）；form类型为空（值由bill_data运行时决定）',
  `sort_index` int DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_plugin_code` (`plugin_code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='Java类插件传入参数（自描述模型：参数零配置，全部由注解自动发现，运行时系统自动注入）';

-- meta_plugin_validator：操作服务插件校验器（OnAddValidators 阶段挂载）
-- 仅 OperationServicePlugin 基类在 OnAddValidators 事件下使用
CREATE TABLE `meta_plugin_validator` (
  `id` bigint NOT NULL,
  `plugin_code` varchar(50) NOT NULL COMMENT '所属插件编码',
  `validator_code` varchar(50) NOT NULL COMMENT '校验器编码（如 CREDIT_CHECK）',
  `validator_name` varchar(200) DEFAULT NULL COMMENT '校验器名称',
  `validator_class` varchar(300) DEFAULT NULL COMMENT '校验器实现类（Java类插件）',
  `validate_expr` varchar(1000) DEFAULT NULL COMMENT '校验表达式（脚本插件，如 cust_credit >= total_amount）',
  `error_msg` varchar(500) DEFAULT NULL COMMENT '校验失败提示信息',
  `is_enabled` tinyint NOT NULL DEFAULT 1 COMMENT '是否启用',
  `sort_index` int DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_plugin_code` (`plugin_code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='操作服务插件校验器（OnAddValidators阶段）';

-- biz_plugin_log：插件执行日志（执行时间/入参/出参/异常）
CREATE TABLE `biz_plugin_log` (
  `id` bigint NOT NULL,
  `plugin_code` varchar(50) DEFAULT NULL COMMENT '插件编码',
  `bo_code` varchar(50) DEFAULT NULL COMMENT '业务对象编码',
  `event_name` varchar(50) DEFAULT NULL COMMENT '触发事件',
  `bill_id` bigint DEFAULT NULL COMMENT '单据ID',
  `exec_order` int DEFAULT NULL COMMENT '执行顺序',
  `input_params` mediumtext COMMENT '入参JSON（PluginContext序列化）',
  `output_result` mediumtext COMMENT '出参JSON（PluginResult序列化）',
  `exec_time_ms` int DEFAULT NULL COMMENT '执行耗时(毫秒)',
  `is_success` tinyint DEFAULT 1 COMMENT '是否成功',
  `error_msg` mediumtext COMMENT '异常信息',
  `exec_by` varchar(200) DEFAULT NULL COMMENT '执行人',
  `exec_time` datetime DEFAULT NULL COMMENT '执行时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_plugin` (`plugin_code`) USING BTREE,
  KEY `idx_bill` (`bo_code`,`bill_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='插件执行日志';

-- ---------------------------------------------------------------------
-- 七、实体服务规则（BOS 声明式规则引擎，ANTLR4 表达式）
-- ---------------------------------------------------------------------

-- meta_entity_rule：实体服务规则定义（validate/calc/linkage/available 四类）
CREATE TABLE `meta_entity_rule` (
  `id` bigint NOT NULL,
  `rule_code` varchar(50) NOT NULL COMMENT '规则编码（唯一）',
  `rule_name` varchar(100) NOT NULL COMMENT '规则名称',
  `bo_code` varchar(50) NOT NULL COMMENT '业务对象编码',
  `entity_code` varchar(50) NOT NULL COMMENT '实体编码（主表/子表）',
  `rule_type` varchar(20) NOT NULL COMMENT '规则类型：validate校验/calc计算/linkage联动/available可用量',
  `trigger_event` varchar(50) NOT NULL COMMENT '触发事件：OnBeforeSave/OnAfterSave/OnBeforeSubmit/OnBeforeAudit/OnFieldValueChange',
  `trigger_field` varchar(50) DEFAULT NULL COMMENT '触发字段（linkage类型必填，如 mat_id）',
  `priority` int NOT NULL DEFAULT 100 COMMENT '优先级（升序执行，先于脚本插件）',
  `is_enabled` tinyint NOT NULL DEFAULT 1 COMMENT '启用状态：0停用 1启用',
  `remark` varchar(500) DEFAULT NULL,
  `create_by` varchar(200) DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  `update_by` varchar(200) DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_entity_rule_code` (`rule_code`) USING BTREE,
  KEY `idx_bo_entity` (`bo_code`,`entity_code`) USING BTREE,
  KEY `idx_trigger` (`trigger_event`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='实体服务规则定义（声明式规则引擎）';

-- meta_entity_rule_item：实体服务规则条目（多条件多动作）
CREATE TABLE `meta_entity_rule_item` (
  `id` bigint NOT NULL,
  `rule_code` varchar(50) NOT NULL COMMENT '规则编码',
  `item_seq` int NOT NULL COMMENT '条目序号',
  `condition_expr` text COMMENT '条件表达式（calc/available可空）',
  `action_expr` text NOT NULL COMMENT '动作表达式（赋值/校验/联动，ANTLR4解析）',
  `error_msg` varchar(500) DEFAULT NULL COMMENT '校验失败提示信息',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_rule_code` (`rule_code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='实体服务规则条目';

-- ---------------------------------------------------------------------
-- 八、反写规则（下游单据审核/撤销回写上游执行量）
-- ---------------------------------------------------------------------

-- meta_writeback_rule：反写规则定义（add累加/subtract扣减/cover覆盖）
CREATE TABLE `meta_writeback_rule` (
  `id` bigint NOT NULL,
  `rule_code` varchar(50) NOT NULL COMMENT '规则编码（唯一）',
  `rule_name` varchar(100) NOT NULL COMMENT '规则名称',
  `src_bill_type` varchar(50) NOT NULL COMMENT '下游源单类型（如 sal_outstock）',
  `target_bill_type` varchar(50) NOT NULL COMMENT '上游目标单类型（如 sal_order）',
  `trigger_op` varchar(200) NOT NULL COMMENT '触发操作（逗号分隔多选：save/delete/cancel/audit/revoke）',
  `src_link_field` varchar(100) NOT NULL COMMENT '源单关联字段（下游单据行字段，如 src_order_goods_id）',
  `target_link_field` varchar(100) NOT NULL COMMENT '目标单关联字段（上游单据行字段，如 id）',
  `writeback_mode` varchar(20) NOT NULL COMMENT '反写模式：add累加/subtract扣减/cover覆盖/aggregate聚合重算',
  `src_table` varchar(100) DEFAULT NULL COMMENT '下游子表名（aggregate模式用，如 sal_contract_goods）',
  `target_table` varchar(100) DEFAULT NULL COMMENT '上游子表名（aggregate模式用，如 sal_int_cont_goods）',
  `status_filter` varchar(200) DEFAULT NULL COMMENT '下游记录状态过滤（aggregate模式用，如 pact_state NOT IN (0,3)）',
  `src_main_table` varchar(100) DEFAULT NULL COMMENT '下游主表名（aggregate模式JOIN用，如 sal_cont，pact_state在主表时需配置）',
  `src_main_fk` varchar(100) DEFAULT NULL COMMENT '下游子表→主表外键（如 sal_cont_id）',
  `target_main_fk` varchar(100) DEFAULT NULL COMMENT '上游子表→主表外键（如 sal_int_cont_id，配置后自动汇总到主表）',
  `over_control` varchar(20) NOT NULL DEFAULT 'block' COMMENT '超限控制：block阻断/warn预警放行/allow允许',
  `over_expr` text COMMENT '超限校验表达式（如 target.out_qty + src.qty <= target.order_qty）',
  `condition_expr` text COMMENT '反写条件（满足才反写）',
  `cascade` tinyint NOT NULL DEFAULT 0 COMMENT '是否级联反写上级：0否 1是',
  `is_enabled` tinyint NOT NULL DEFAULT 1 COMMENT '启用状态：0停用 1启用',
  `remark` varchar(500) DEFAULT NULL,
  `create_by` varchar(200) DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  `update_by` varchar(200) DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_wb_rule_code` (`rule_code`) USING BTREE,
  KEY `idx_src_target` (`src_bill_type`,`target_bill_type`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='反写规则定义（下游反写上游执行量）';

-- meta_writeback_field：反写字段映射
CREATE TABLE `meta_writeback_field` (
  `id` bigint NOT NULL,
  `rule_code` varchar(50) NOT NULL COMMENT '规则编码',
  `item_seq` int NOT NULL COMMENT '序号',
  `src_field` varchar(50) NOT NULL COMMENT '下游字段（如 qty）',
  `target_field` varchar(50) NOT NULL COMMENT '上游字段（如 out_qty）',
  `base_field` varchar(50) DEFAULT NULL COMMENT '基准字段（aggregate模式用，上游的基准字段如 order_qty）',
  `writeback_expr` varchar(200) NOT NULL COMMENT '反写表达式（如 target_field = target_field + src_field）',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_wb_rule_code` (`rule_code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='反写字段映射';

-- ---------------------------------------------------------------------
-- 九、列表查询配置
-- ---------------------------------------------------------------------

-- meta_list_column：列表列定义（管理员配置，含冻结/合计/平均）
CREATE TABLE `meta_list_column` (
  `id` bigint NOT NULL,
  `bo_code` varchar(50) NOT NULL COMMENT '业务对象编码',
  `field_code` varchar(100) NOT NULL COMMENT '字段编码',
  `field_name` varchar(200) DEFAULT NULL COMMENT '列名',
  `entity_code` varchar(50) DEFAULT NULL COMMENT '所属实体',
  `ctrl_type` varchar(50) DEFAULT NULL COMMENT '控件类型（用于格式化：amount/qty/date/enum）',
  `is_show` tinyint DEFAULT 1 COMMENT '是否显示',
  `is_fixed` varchar(10) DEFAULT 'none' COMMENT '冻结列：none不冻结/left左冻结/right右冻结',
  `is_sum` tinyint DEFAULT 0 COMMENT '是否列尾合计',
  `is_avg` tinyint DEFAULT 0 COMMENT '是否列尾平均',
  `col_width` int DEFAULT NULL COMMENT '列宽',
  `sort_index` int DEFAULT 0,
  `is_enable` tinyint DEFAULT 1,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_bo_code` (`bo_code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='列表列定义';

-- meta_query_field：查询字段配置（普通/高级，14种运算符）
CREATE TABLE `meta_query_field` (
  `id` bigint NOT NULL,
  `bo_code` varchar(50) NOT NULL COMMENT '业务对象编码',
  `field_code` varchar(100) NOT NULL COMMENT '字段编码',
  `field_name` varchar(200) DEFAULT NULL COMMENT '字段名',
  `is_common` tinyint DEFAULT 0 COMMENT '是否普通查询字段（列表顶部常用筛选区）',
  `is_advanced` tinyint DEFAULT 0 COMMENT '是否高级查询字段（弹窗查询构造器）',
  `operators` varchar(500) DEFAULT NULL COMMENT '支持的运算符（逗号分隔：eq/ne/gt/ge/lt/le/like/not_like/begin_with/end_with/is_null/is_not_null/in/between）',
  `default_op` varchar(50) DEFAULT 'eq' COMMENT '默认运算符',
  `sort_index` int DEFAULT 0,
  `is_enable` tinyint DEFAULT 1,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_bo_code` (`bo_code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='查询字段配置（14种运算符）';

-- user_list_setting：用户列设置（私有）
CREATE TABLE `user_list_setting` (
  `id` bigint NOT NULL,
  `user_id` bigint DEFAULT NULL COMMENT '用户ID',
  `bo_code` varchar(50) DEFAULT NULL COMMENT '业务对象编码',
  `columns_json` mediumtext COMMENT '列设置JSON（字段/顺序/宽度/冻结/合计）',
  `page_size` int DEFAULT 20 COMMENT '每页条数',
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_user_bo` (`user_id`,`bo_code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='用户列表设置（私有）';

-- user_query_scheme：用户查询方案（私有+公共）
CREATE TABLE `user_query_scheme` (
  `id` bigint NOT NULL,
  `user_id` bigint DEFAULT NULL COMMENT '用户ID（公共方案为0）',
  `bo_code` varchar(50) DEFAULT NULL COMMENT '业务对象编码',
  `scheme_name` varchar(200) DEFAULT NULL COMMENT '方案名称',
  `condition_json` mediumtext COMMENT '查询条件JSON（含AND/OR分组、运算符、值）',
  `columns_json` mediumtext COMMENT '列设置JSON',
  `order_by` varchar(500) DEFAULT NULL COMMENT '排序',
  `page_size` int DEFAULT 20,
  `is_default` tinyint DEFAULT 0 COMMENT '是否默认',
  `is_favorite` tinyint DEFAULT 0 COMMENT '是否收藏',
  `is_public` tinyint DEFAULT 0 COMMENT '是否公共方案',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_user_bo` (`user_id`,`bo_code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='用户查询方案（私有+公共）';

-- ---------------------------------------------------------------------
-- 十、打印模板（FineReport 风格类 Excel 单元格设计器）
-- ---------------------------------------------------------------------

-- meta_print_template：打印模板（类Excel单元格画布 + 行带区 + 合并 + 扩展）
-- 设计要素：单元格(cells)、合并(merges)、行带区(row_bands: title/header/detail/summary)
-- 字段绑定：cell_type=field + expand(none/vertical/horizontal) + data_setting(list/group/sum/avg/max/min/count)
-- 公式：cell_type=formula，如 =sum(D3) =count() =avg()
-- 纸张设置：paper_type/paper_width/paper_height/orientation/margin_json（GAP-D10-001/009 / RISK-D10-004）
CREATE TABLE `meta_print_template` (
  `id` bigint NOT NULL,
  `template_code` varchar(100) NOT NULL COMMENT '模板编码（唯一）',
  `template_name` varchar(200) DEFAULT NULL COMMENT '模板名称',
  `bo_code` varchar(50) NOT NULL COMMENT '业务对象编码',
  `template_type` varchar(50) DEFAULT 'single' COMMENT '类型：single单据/batch套打',
  `lang` varchar(20) DEFAULT 'zh' COMMENT '语言（zh/en）',
  `paper_size` varchar(50) DEFAULT 'A4' COMMENT '纸张大小（兼容旧版，与 paper_type 同义）',
  `paper_type` varchar(20) DEFAULT 'A4' COMMENT '纸张类型：A4/A5/letter/custom（GAP-D10-001）',
  `paper_width` int DEFAULT NULL COMMENT '自定义纸张宽度（mm，paper_type=custom 时填写）',
  `paper_height` int DEFAULT NULL COMMENT '自定义纸张高度（mm，paper_type=custom 时填写）',
  `orientation` varchar(20) DEFAULT 'portrait' COMMENT '方向：portrait纵向/landscape横向（GAP-D10-001）',
  `margin_json` varchar(500) DEFAULT NULL COMMENT '页边距JSON：{top,bottom,left,right,header,footer}（单位mm，GAP-D10-001）',
  `row_count` int DEFAULT 12 COMMENT '画布行数',
  `col_count` int DEFAULT 8 COMMENT '画布列数',
  `cells_json` longtext COMMENT '单元格定义JSON（Record<r_c, PrintCell>，含content/cell_type/field_code/expand/data_setting/style）',
  `merges_json` text COMMENT '合并信息JSON（Record<r_c, {rowspan, colspan}>）',
  `row_bands_json` text COMMENT '行带区JSON（数组：title标题/header表头/detail明细/summary汇总）',
  `template_json` longtext COMMENT '模板完整JSON（兼容旧版，含上述全部信息）',
  `is_default` tinyint DEFAULT 0,
  `create_by` varchar(200) DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  `update_by` varchar(200) DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_print_template_code` (`template_code`) USING BTREE,
  KEY `idx_bo_code` (`bo_code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='打印模板（FineReport风格类Excel单元格设计器）';

-- ---------------------------------------------------------------------
-- 十一、权限体系（用户/角色/按钮权限/字段权限/数据权限）
-- 注：sys_org / sys_dept 定义见 01-基础资料表.sql
-- ---------------------------------------------------------------------

-- sys_user：系统用户
CREATE TABLE `sys_user` (
  `id` bigint NOT NULL,
  `username` varchar(100) NOT NULL COMMENT '登录账号（唯一）',
  `password` varchar(200) DEFAULT NULL COMMENT '密码（加密）',
  `real_name` varchar(100) DEFAULT NULL COMMENT '姓名',
  `emp_id` bigint DEFAULT NULL COMMENT '关联员工ID',
  `org_id` bigint DEFAULT NULL COMMENT '主组织',
  `dept_id` bigint DEFAULT NULL COMMENT '主部门',
  `email` varchar(200) DEFAULT NULL,
  `phone` varchar(50) DEFAULT NULL,
  `status` int DEFAULT 1 COMMENT '状态（1启用 0停用）',
  `last_login_time` datetime DEFAULT NULL,
  `pwd_update_time` datetime DEFAULT NULL,
  `fail_count` int DEFAULT 0 COMMENT '登录失败次数',
  `create_by` varchar(200) DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  `update_by` varchar(200) DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_username` (`username`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='系统用户';

-- sys_role：角色（支持继承）
CREATE TABLE `sys_role` (
  `id` bigint NOT NULL,
  `role_code` varchar(100) NOT NULL COMMENT '角色编码（唯一）',
  `role_name` varchar(200) DEFAULT NULL COMMENT '角色名称',
  `parent_id` bigint DEFAULT NULL COMMENT '上级角色（继承）',
  `remark` varchar(500) DEFAULT NULL,
  `status` int DEFAULT 1,
  `create_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_role_code` (`role_code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='角色';

-- sys_user_role：用户-角色关联
CREATE TABLE `sys_user_role` (
  `id` bigint NOT NULL,
  `user_id` bigint DEFAULT NULL,
  `role_id` bigint DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_user_role` (`user_id`,`role_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='用户角色关联';

-- sys_user_org：用户-组织归属（多组织，GAP-D11-001 / RISK-D11-002）
-- 一个用户可归属多个组织，标记主组织（is_main=1），支持跨组织业务
CREATE TABLE `sys_user_org` (
  `id` bigint NOT NULL,
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `org_id` bigint NOT NULL COMMENT '组织ID',
  `is_main` tinyint DEFAULT 0 COMMENT '是否主组织（0否 1是，一个用户仅一个主组织）',
  `eff_date` date DEFAULT NULL COMMENT '生效日期',
  `exp_date` date DEFAULT NULL COMMENT '失效日期',
  `create_by` varchar(200) DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  `update_by` varchar(200) DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_user_org` (`user_id`,`org_id`) USING BTREE,
  KEY `idx_user_id` (`user_id`) USING BTREE,
  KEY `idx_org_id` (`org_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='用户多组织归属（一个用户可归属多个组织，标记主组织）';

-- sys_role_button：角色-按钮授权（4档控制级别）
CREATE TABLE `sys_role_button` (
  `id` bigint NOT NULL,
  `role_id` bigint DEFAULT NULL COMMENT '角色ID',
  `bo_code` varchar(50) DEFAULT NULL COMMENT '业务对象编码',
  `button_code` varchar(100) DEFAULT NULL COMMENT '按钮编码',
  `control_level` varchar(20) DEFAULT 'enabled' COMMENT '控制级别：enabled可用/disabled禁用/hidden隐藏/readonly只读',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_role_bo_button` (`role_id`,`bo_code`,`button_code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='角色按钮授权（4档控制）';

-- field_permission：字段权限（列级，visible/hidden/mask）
CREATE TABLE `field_permission` (
  `id` bigint NOT NULL,
  `role_id` bigint DEFAULT NULL COMMENT '角色ID',
  `bo_code` varchar(50) DEFAULT NULL COMMENT '业务对象编码',
  `field_code` varchar(100) DEFAULT NULL COMMENT '字段编码',
  `permission` varchar(20) DEFAULT 'visible' COMMENT '权限：visible可见/hidden隐藏/mask脱敏',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_role_bo_field` (`role_id`,`bo_code`,`field_code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='字段权限（列级）';

-- data_permission_rule：数据权限规则（行级，5种数据范围）
CREATE TABLE `data_permission_rule` (
  `id` bigint NOT NULL,
  `role_id` bigint DEFAULT NULL COMMENT '角色ID',
  `bo_code` varchar(50) DEFAULT NULL COMMENT '业务对象编码',
  `dimension` varchar(50) DEFAULT NULL COMMENT '权限维度：org组织/dept部门/saler业务员/customer客户/supplier供应商/warehouse仓库/workshop车间',
  `scope_type` varchar(50) DEFAULT NULL COMMENT '范围：self本人/dept本部门/dept_sub本部门及下级/org本组织/all全部/custom自定义',
  `field_code` varchar(100) DEFAULT NULL COMMENT '过滤字段（如 saler_id）',
  `is_enable` tinyint DEFAULT 1,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_role_bo` (`role_id`,`bo_code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='数据权限规则（行级）';

-- data_permission_scope：数据权限范围授权（custom 自定义具体记录）
CREATE TABLE `data_permission_scope` (
  `id` bigint NOT NULL,
  `rule_id` bigint DEFAULT NULL COMMENT '规则ID',
  `ref_id` bigint DEFAULT NULL COMMENT '授权记录ID（客户/供应商/仓库ID）',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_rule_id` (`rule_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='数据权限范围授权';

-- ---------------------------------------------------------------------
-- 十二、工作流对接 + 附件 + 导入导出 + API日志
-- ---------------------------------------------------------------------

-- wf_instance：外部工作流对接（审批流由独立工作流系统承担）
CREATE TABLE `wf_instance` (
  `id` bigint NOT NULL COMMENT '主键',
  `instance_id` bigint NOT NULL COMMENT '本地实例ID',
  `request_id` varchar(100) DEFAULT NULL COMMENT '外部工作流实例ID（由工作流系统返回）',
  `bill_type` varchar(50) DEFAULT NULL COMMENT '单据类型（bo_code）',
  `bill_id` bigint DEFAULT NULL COMMENT '单据ID',
  `status` varchar(20) DEFAULT NULL COMMENT '审批状态：approving审批中/approved通过/rejected驳回',
  `submit_by` varchar(200) DEFAULT NULL COMMENT '提交人',
  `submit_time` datetime DEFAULT NULL,
  `callback_time` datetime DEFAULT NULL COMMENT '工作流回调时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_request_id` (`request_id`) USING BTREE,
  KEY `idx_bill` (`bill_type`,`bill_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='外部工作流对接（审批流由独立系统承担）';

-- sys_attachment：附件管理
CREATE TABLE `sys_attachment` (
  `id` bigint NOT NULL,
  `bill_type` varchar(50) NOT NULL COMMENT '单据类型（bo_code）',
  `bill_id` bigint NOT NULL COMMENT '单据ID',
  `file_name` varchar(255) NOT NULL COMMENT '文件名',
  `file_path` varchar(500) NOT NULL COMMENT '存储路径',
  `file_size` bigint DEFAULT NULL COMMENT '文件大小(字节)',
  `file_type` varchar(20) DEFAULT NULL COMMENT '文件类型',
  `storage_type` varchar(10) NOT NULL DEFAULT 'local' COMMENT '存储类型：local本地/oss对象存储',
  `version` int NOT NULL DEFAULT 1 COMMENT '版本号',
  `upload_by` varchar(200) DEFAULT NULL COMMENT '上传人',
  `upload_time` datetime DEFAULT NULL,
  `is_deleted` tinyint NOT NULL DEFAULT 0 COMMENT '是否删除',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_bill` (`bill_type`,`bill_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='附件管理';

-- sys_import_task：数据导入任务（异步导入 + 模板配置）
CREATE TABLE `sys_import_task` (
  `id` bigint NOT NULL,
  `task_code` varchar(100) DEFAULT NULL COMMENT '任务编码',
  `bo_code` varchar(50) NOT NULL COMMENT '业务对象编码',
  `template_name` varchar(200) DEFAULT NULL COMMENT '导入模板名称',
  `file_name` varchar(255) DEFAULT NULL COMMENT '导入文件名',
  `file_path` varchar(500) DEFAULT NULL COMMENT '文件路径',
  `total_count` int DEFAULT 0 COMMENT '总行数',
  `success_count` int DEFAULT 0 COMMENT '成功行数',
  `fail_count` int DEFAULT 0 COMMENT '失败行数',
  `status` varchar(20) DEFAULT 'pending' COMMENT '状态：pending等待/validating校验中/importing导入中/done完成/failed失败',
  `error_log` longtext COMMENT '错误明细日志（行号+错误信息）',
  `import_by` varchar(200) DEFAULT NULL COMMENT '导入人',
  `import_time` datetime DEFAULT NULL,
  `finish_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_bo_code` (`bo_code`) USING BTREE,
  KEY `idx_import_by` (`import_by`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='数据导入任务（异步）';

-- meta_import_template：导入模板配置（PRD 07.3.7，GAP-D12-012 / RISK-D12-006）
-- 字段映射 + 校验规则 + 行为配置，模板驱动批量导入
CREATE TABLE `meta_import_template` (
  `id` bigint NOT NULL,
  `template_code` varchar(100) NOT NULL COMMENT '模板编码（唯一）',
  `template_name` varchar(200) NOT NULL COMMENT '模板名称',
  `bo_code` varchar(50) NOT NULL COMMENT '业务对象编码',
  `field_mappings_json` longtext COMMENT '字段映射JSON（ImportTemplateField[]：field_code/field_name/is_required/data_type/validate_rule/default_value/sort_index）',
  `unique_fields` varchar(500) DEFAULT NULL COMMENT '唯一性校验字段（逗号分隔）',
  `required_fields` varchar(500) DEFAULT NULL COMMENT '必填字段（逗号分隔）',
  `allow_update` tinyint DEFAULT 0 COMMENT '允许更新已存在记录（0否 1是）',
  `update_key` varchar(100) DEFAULT NULL COMMENT '更新匹配键字段',
  `fail_fast` tinyint DEFAULT 1 COMMENT '出错即终止（1终止 0跳过继续）',
  `template_file` varchar(500) DEFAULT NULL COMMENT '模板文件路径',
  `status` tinyint DEFAULT 1 COMMENT '状态：0停用 1启用',
  `remark` varchar(500) DEFAULT NULL,
  `create_by` varchar(200) DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  `update_by` varchar(200) DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_import_template_code` (`template_code`) USING BTREE,
  KEY `idx_bo_code` (`bo_code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='导入模板配置（字段映射 + 校验规则 + 行为配置）';

-- sys_api_log：外部接口调用日志（插件API调用、工作流推送、第三方集成）
CREATE TABLE `sys_api_log` (
  `id` bigint NOT NULL,
  `category` varchar(32) DEFAULT NULL COMMENT '接口分类：wf工作流/mes制造执行/qms质量管理/report报表/tax税务/bank银行/other其他',
  `api_type` varchar(50) DEFAULT NULL COMMENT '接口类型（兼容保留）：plugin插件调用/wf工作流推送/third_party第三方集成',
  `source_code` varchar(100) DEFAULT NULL COMMENT '来源编码（插件编码/工作流编码）',
  `bo_code` varchar(50) DEFAULT NULL COMMENT '业务对象编码',
  `bill_id` bigint DEFAULT NULL COMMENT '单据ID',
  `api_url` varchar(500) DEFAULT NULL COMMENT '请求URL',
  `api_method` varchar(10) DEFAULT NULL COMMENT 'HTTP方法',
  `request_body` longtext COMMENT '请求体',
  `response_body` longtext COMMENT '响应体',
  `status_code` int DEFAULT NULL COMMENT 'HTTP状态码',
  `duration_ms` int DEFAULT NULL COMMENT '耗时(毫秒)',
  `is_success` tinyint DEFAULT 1 COMMENT '是否成功',
  `error_msg` varchar(2000) DEFAULT NULL COMMENT '错误信息',
  `call_by` varchar(200) DEFAULT NULL COMMENT '调用人',
  `call_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_api_type` (`api_type`) USING BTREE,
  KEY `idx_category` (`category`) USING BTREE,
  KEY `idx_bo_bill` (`bo_code`,`bill_id`) USING BTREE,
  KEY `idx_call_time` (`call_time`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='外部接口调用日志';
