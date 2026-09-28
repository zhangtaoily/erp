-- =====================================================================
-- 10-系统管理表（系统参数、公告、备份、任务调度、数据字典、导入任务）
-- 命名约定：表前缀 sys_
-- 说明：系统级配置、运维管理、数据字典与定时任务调度。
-- =====================================================================

-- ---------------------------------------------------------------------
-- 一、系统参数
-- ---------------------------------------------------------------------

-- sys_param：系统参数
CREATE TABLE `sys_param` (
  `param_code` varchar(100) NOT NULL COMMENT '参数编码',
  `param_name` varchar(200) NOT NULL COMMENT '参数名称',
  `param_value` varchar(1000) DEFAULT NULL COMMENT '参数值',
  `param_type` varchar(20) DEFAULT NULL COMMENT '参数类型（string/number/bool/date/json）',
  `param_group` varchar(50) DEFAULT NULL COMMENT '参数分组',
  `default_value` varchar(1000) DEFAULT NULL COMMENT '默认值',
  `is_system` tinyint NOT NULL DEFAULT 0 COMMENT '是否系统内置（1内置不可删 0用户自定义）',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `update_by` bigint DEFAULT NULL COMMENT '修改人',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
  PRIMARY KEY (`param_code`) USING BTREE,
  KEY `sys_param_group_IDX` (`param_group`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='系统参数';

-- ---------------------------------------------------------------------
-- 二、公告管理
-- ---------------------------------------------------------------------

-- sys_notice：公告
CREATE TABLE `sys_notice` (
  `notice_id` bigint NOT NULL AUTO_INCREMENT COMMENT '公告ID',
  `title` varchar(200) NOT NULL COMMENT '标题',
  `content` mediumtext COMMENT '内容',
  `notice_type` varchar(20) DEFAULT NULL COMMENT '公告类型（system系统/business业务/urgent紧急）',
  `publish_by` bigint DEFAULT NULL COMMENT '发布人',
  `publish_time` datetime DEFAULT NULL COMMENT '发布时间',
  `expire_time` datetime DEFAULT NULL COMMENT '过期时间',
  `is_top` tinyint NOT NULL DEFAULT 0 COMMENT '是否置顶',
  `is_read_required` tinyint NOT NULL DEFAULT 0 COMMENT '是否必读',
  `status` tinyint NOT NULL DEFAULT 0 COMMENT '状态：0草稿 1已发布 2已撤回',
  PRIMARY KEY (`notice_id`) USING BTREE,
  KEY `sys_notice_status_IDX` (`status`,`publish_time`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='系统公告';

-- sys_notice_read：公告阅读记录
CREATE TABLE `sys_notice_read` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `notice_id` bigint NOT NULL COMMENT '公告ID',
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `read_time` datetime DEFAULT NULL COMMENT '阅读时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `sys_notice_read_UK` (`notice_id`,`user_id`) USING BTREE,
  KEY `sys_notice_read_user_id_IDX` (`user_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='公告阅读记录';

-- ---------------------------------------------------------------------
-- 三、数据备份
-- ---------------------------------------------------------------------

-- sys_backup：数据备份
CREATE TABLE `sys_backup` (
  `backup_id` bigint NOT NULL AUTO_INCREMENT COMMENT '备份ID',
  `backup_type` varchar(20) NOT NULL COMMENT '备份类型（full全量/incremental增量/manual手动）',
  `backup_time` datetime DEFAULT NULL COMMENT '备份时间',
  `file_path` varchar(500) DEFAULT NULL COMMENT '备份文件路径',
  `file_size` bigint DEFAULT NULL COMMENT '文件大小(字节)',
  `status` varchar(20) DEFAULT NULL COMMENT '状态（running备份中/success成功/failed失败）',
  `operator` varchar(200) DEFAULT NULL COMMENT '操作人',
  PRIMARY KEY (`backup_id`) USING BTREE,
  KEY `sys_backup_type_time_IDX` (`backup_type`,`backup_time`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='数据备份记录';

-- ---------------------------------------------------------------------
-- 四、任务调度
-- ---------------------------------------------------------------------

-- sys_schedule：定时任务
CREATE TABLE `sys_schedule` (
  `schedule_code` varchar(100) NOT NULL COMMENT '任务编码',
  `schedule_name` varchar(200) DEFAULT NULL COMMENT '任务名称',
  `cron` varchar(100) DEFAULT NULL COMMENT 'cron 表达式',
  `target_type` varchar(20) DEFAULT NULL COMMENT '目标类型（bean/http/method）',
  `target` varchar(500) DEFAULT NULL COMMENT '调用目标（bean名/URL/方法路径）',
  `params` varchar(1000) DEFAULT NULL COMMENT '参数（JSON）',
  `is_enabled` tinyint NOT NULL DEFAULT 1 COMMENT '是否启用',
  `last_run_time` datetime DEFAULT NULL COMMENT '上次执行时间',
  `last_run_status` varchar(20) DEFAULT NULL COMMENT '上次执行状态（success/failed/running）',
  `next_run_time` datetime DEFAULT NULL COMMENT '下次执行时间',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  PRIMARY KEY (`schedule_code`) USING BTREE,
  KEY `sys_schedule_enabled_IDX` (`is_enabled`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='定时任务';

-- sys_schedule_log：任务执行日志
CREATE TABLE `sys_schedule_log` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `schedule_code` varchar(100) NOT NULL COMMENT '任务编码',
  `run_time` datetime DEFAULT NULL COMMENT '执行时间',
  `run_status` varchar(20) DEFAULT NULL COMMENT '执行状态（success/failed/running）',
  `duration` int DEFAULT NULL COMMENT '耗时(毫秒)',
  `error_msg` varchar(2000) DEFAULT NULL COMMENT '错误信息',
  `log` mediumtext COMMENT '详细日志',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `sys_schedule_log_code_time_IDX` (`schedule_code`,`run_time`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='任务执行日志';

-- ---------------------------------------------------------------------
-- 五、数据字典
-- ---------------------------------------------------------------------

-- sys_dict：数据字典
CREATE TABLE `sys_dict` (
  `dict_code` varchar(100) NOT NULL COMMENT '字典编码',
  `dict_name` varchar(200) DEFAULT NULL COMMENT '字典名称',
  `table_name` varchar(100) DEFAULT NULL COMMENT '物理表名（字段所属表）',
  `field_name` varchar(100) DEFAULT NULL COMMENT '字段名',
  `field_type` varchar(50) DEFAULT NULL COMMENT '字段类型',
  `field_length` int DEFAULT NULL COMMENT '字段长度',
  `field_comment` varchar(200) DEFAULT NULL COMMENT '字段说明',
  `is_enum` tinyint NOT NULL DEFAULT 1 COMMENT '是否枚举（1枚举 0仅字典说明）',
  `status` tinyint NOT NULL DEFAULT 1 COMMENT '状态：0停用 1启用',
  PRIMARY KEY (`dict_code`) USING BTREE,
  KEY `sys_dict_table_field_IDX` (`table_name`,`field_name`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='数据字典';

-- sys_dict_item：字典枚举项
CREATE TABLE `sys_dict_item` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `dict_code` varchar(100) NOT NULL COMMENT '字典编码',
  `item_value` varchar(100) DEFAULT NULL COMMENT '枚举值',
  `item_name` varchar(200) DEFAULT NULL COMMENT '枚举名',
  `sort_order` int DEFAULT '0' COMMENT '排序',
  `is_default` tinyint NOT NULL DEFAULT 0 COMMENT '是否默认',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `sys_dict_item_dict_code_IDX` (`dict_code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='字典枚举项';
