-- =====================================================================
-- 10-消息与预警表（业务预警规则、预警记录、站内信、邮件日志）
-- 命名约定：表前缀 sys_
-- 说明：业务预警规则定义与触发记录、站内消息、邮件发送日志。
-- =====================================================================

-- ---------------------------------------------------------------------
-- 一、预警规则与记录
-- ---------------------------------------------------------------------

-- sys_alert_rule：预警规则
CREATE TABLE `sys_alert_rule` (
  `rule_code` varchar(100) NOT NULL COMMENT '规则编码',
  `rule_name` varchar(200) DEFAULT NULL COMMENT '规则名称',
  `alert_type` varchar(50) DEFAULT NULL COMMENT '预警类型（stock库存/credit信用/expire到期/overdue逾期/threshold阈值）',
  `target_object` varchar(100) DEFAULT NULL COMMENT '目标业务对象（bo_code，如 sal_order/md_customer）',
  `condition_expr` varchar(1000) DEFAULT NULL COMMENT '预警条件表达式（如 stock_qty < safe_qty）',
  `check_cron` varchar(100) DEFAULT NULL COMMENT '检查周期 cron 表达式',
  `notify_target` varchar(200) DEFAULT NULL COMMENT '通知对象（role角色/user用户/dept部门，逗号分隔）',
  `notify_channel` varchar(100) DEFAULT NULL COMMENT '通知渠道（message站内信/mail邮件/sms短信，逗号分隔）',
  `is_enabled` tinyint NOT NULL DEFAULT 1 COMMENT '是否启用',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  PRIMARY KEY (`rule_code`) USING BTREE,
  KEY `sys_alert_rule_type_IDX` (`alert_type`,`is_enabled`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='预警规则';

-- sys_alert_log：预警记录
CREATE TABLE `sys_alert_log` (
  `alert_id` bigint NOT NULL AUTO_INCREMENT COMMENT '预警ID',
  `rule_code` varchar(100) DEFAULT NULL COMMENT '规则编码',
  `alert_type` varchar(50) DEFAULT NULL COMMENT '预警类型',
  `target_id` bigint DEFAULT NULL COMMENT '目标对象ID（单据/客商ID等）',
  `target_desc` varchar(500) DEFAULT NULL COMMENT '目标描述（如客户名称+单据号）',
  `alert_content` varchar(2000) DEFAULT NULL COMMENT '预警内容',
  `alert_time` datetime DEFAULT NULL COMMENT '预警时间',
  `alert_level` varchar(20) DEFAULT NULL COMMENT '预警级别（info提示/warn警告/urgent紧急）',
  `is_read` tinyint NOT NULL DEFAULT 0 COMMENT '是否已读',
  `is_handled` tinyint NOT NULL DEFAULT 0 COMMENT '是否已处理',
  `handle_by` bigint DEFAULT NULL COMMENT '处理人',
  `handle_time` datetime DEFAULT NULL COMMENT '处理时间',
  `handle_remark` varchar(1000) DEFAULT NULL COMMENT '处理说明',
  `status` varchar(20) DEFAULT NULL COMMENT '状态（pending待处理/handled已处理/ignored已忽略）',
  PRIMARY KEY (`alert_id`) USING BTREE,
  KEY `sys_alert_log_rule_IDX` (`rule_code`,`alert_time`) USING BTREE,
  KEY `sys_alert_log_status_IDX` (`status`,`is_read`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='预警记录';

-- ---------------------------------------------------------------------
-- 二、站内信
-- ---------------------------------------------------------------------

-- sys_message：站内信
CREATE TABLE `sys_message` (
  `message_id` bigint NOT NULL AUTO_INCREMENT COMMENT '消息ID',
  `user_id` bigint NOT NULL COMMENT '接收用户ID',
  `message_type` varchar(20) DEFAULT NULL COMMENT '消息类型（system系统/business业务/alert预警/todo待办）',
  `title` varchar(200) DEFAULT NULL COMMENT '标题',
  `content` varchar(2000) DEFAULT NULL COMMENT '内容',
  `ref_bill_type` varchar(50) DEFAULT NULL COMMENT '关联单据类型',
  `ref_bill_id` bigint DEFAULT NULL COMMENT '关联单据ID',
  `is_read` tinyint NOT NULL DEFAULT 0 COMMENT '是否已读',
  `read_time` datetime DEFAULT NULL COMMENT '阅读时间',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `expire_time` datetime DEFAULT NULL COMMENT '过期时间',
  PRIMARY KEY (`message_id`) USING BTREE,
  KEY `sys_message_user_read_IDX` (`user_id`,`is_read`) USING BTREE,
  KEY `sys_message_bill_IDX` (`ref_bill_type`,`ref_bill_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='站内信';

-- ---------------------------------------------------------------------
-- 三、邮件日志
-- ---------------------------------------------------------------------

-- sys_mail_log：邮件日志
CREATE TABLE `sys_mail_log` (
  `mail_id` bigint NOT NULL AUTO_INCREMENT COMMENT '邮件ID',
  `to_email` varchar(500) NOT NULL COMMENT '收件邮箱（多个逗号分隔）',
  `subject` varchar(500) DEFAULT NULL COMMENT '主题',
  `content` mediumtext COMMENT '邮件内容',
  `ref_bill_type` varchar(50) DEFAULT NULL COMMENT '关联单据类型',
  `ref_bill_id` bigint DEFAULT NULL COMMENT '关联单据ID',
  `send_time` datetime DEFAULT NULL COMMENT '发送时间',
  `send_status` varchar(20) DEFAULT NULL COMMENT '发送状态（success成功/failed失败/pending待发）',
  `error_msg` varchar(2000) DEFAULT NULL COMMENT '错误信息',
  PRIMARY KEY (`mail_id`) USING BTREE,
  KEY `sys_mail_log_status_IDX` (`send_status`,`send_time`) USING BTREE,
  KEY `sys_mail_log_bill_IDX` (`ref_bill_type`,`ref_bill_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='邮件发送日志';
