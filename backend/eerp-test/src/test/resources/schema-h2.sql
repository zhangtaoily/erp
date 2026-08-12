-- ============================================================
-- EERP H2 Test Schema (auto-converted from MySQL DDL)
-- H2 MODE=MySQL; Snowflake ID (ASSIGN_ID), no AUTO_INCREMENT
-- ============================================================

-- ============================================================
-- 00-平台元数据表
-- ============================================================

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
CREATE TABLE meta_business_object (
  id bigint NOT NULL,
  bo_code varchar(50) NOT NULL,
  bo_name varchar(100) NOT NULL,
  bo_type varchar(20) NOT NULL,
  main_table varchar(100) NOT NULL,
  main_key varchar(50) NOT NULL DEFAULT 'id',
  pk_strategy varchar(20) NOT NULL DEFAULT 'snowflake',
  is_stateful SMALLINT NOT NULL DEFAULT 1,
  is_pushable SMALLINT NOT NULL DEFAULT 1,
  is_printable SMALLINT NOT NULL DEFAULT 1,
  org_type varchar(20) DEFAULT NULL,
  status SMALLINT NOT NULL DEFAULT 1,
  remark varchar(500) DEFAULT NULL,
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE (bo_code)
);

-- meta_form_entity：实体层级（主表/子表/孙表三级嵌套）
CREATE TABLE meta_form_entity (
  id bigint NOT NULL,
  bo_code varchar(50) NOT NULL,
  entity_code varchar(50) NOT NULL,
  entity_name varchar(100) NOT NULL,
  entity_type varchar(20) NOT NULL,
  entity_level int NOT NULL DEFAULT 0,
  table_name varchar(100) NOT NULL,
  parent_entity_code varchar(50) DEFAULT NULL,
  link_field varchar(100) DEFAULT NULL,
  sort_index int DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE (bo_code,entity_code)
);

-- meta_form_field：字段元数据（驱动表单渲染、校验、计算）
CREATE TABLE meta_form_field (
  id bigint NOT NULL,
  bo_code varchar(50) NOT NULL,
  entity_code varchar(50) NOT NULL,
  field_code varchar(100) NOT NULL,
  field_name varchar(200) NOT NULL,
  field_type varchar(50) NOT NULL,
  ctrl_type varchar(50) NOT NULL,
  data_type varchar(50) DEFAULT NULL,
  data_length int DEFAULT NULL,
  data_precision int DEFAULT NULL,
  data_scale int DEFAULT NULL,
  is_required SMALLINT DEFAULT 0,
  is_readonly SMALLINT DEFAULT 0,
  is_hidden SMALLINT DEFAULT 0,
  is_system SMALLINT DEFAULT 0,
  default_value varchar(500) DEFAULT NULL,
  validate_rule varchar(500) DEFAULT NULL,
  ref_bo_code varchar(50) DEFAULT NULL,
  enum_code varchar(50) DEFAULT NULL,
  formula varchar(1000) DEFAULT NULL,
  summary_to varchar(100) DEFAULT NULL,
  group_name varchar(100) DEFAULT NULL,
  col_width int DEFAULT NULL,
  sort_index int DEFAULT 0,
  remark varchar(500) DEFAULT NULL,
  PRIMARY KEY (id)
);

-- meta_enum / meta_enum_item：枚举定义
CREATE TABLE meta_enum (
  id bigint NOT NULL,
  enum_code varchar(100) NOT NULL,
  enum_name varchar(200) DEFAULT NULL,
  remark varchar(500) DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE (enum_code)
);

CREATE TABLE meta_enum_item (
  id bigint NOT NULL,
  enum_code varchar(100) NOT NULL,
  item_value int DEFAULT NULL,
  item_name varchar(200) DEFAULT NULL,
  item_color varchar(20) DEFAULT NULL,
  sort_index int DEFAULT 0,
  is_default SMALLINT DEFAULT 0,
  PRIMARY KEY (id)
);

-- meta_form_layout：表单布局元数据（页签/分组/字段位置）
CREATE TABLE meta_form_layout (
  id bigint NOT NULL,
  bo_code varchar(50) NOT NULL,
  layout_code varchar(100) DEFAULT NULL,
  layout_name varchar(200) DEFAULT NULL,
  layout_json CLOB,
  is_default SMALLINT DEFAULT 0,
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id)
);

-- ---------------------------------------------------------------------
-- 二、状态机（5状态标准模型 + is_closed/is_cancel 辅助标记）
-- ---------------------------------------------------------------------

-- meta_state_machine：状态机定义
CREATE TABLE meta_state_machine (
  id bigint NOT NULL,
  code varchar(100) NOT NULL,
  name varchar(200) DEFAULT NULL,
  state_field varchar(100) DEFAULT 'pact_state',
  remark varchar(500) DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE (code)
);

-- meta_state_node：状态节点
-- 状态码约定：0暂存 1已创建 2已提交 3已审核 4已驳回（自定义状态码可 >=5）
-- 关闭/取消不占用状态码，改用 is_closed/is_cancel 字段记录（与 pact_state 正交）
CREATE TABLE meta_state_node (
  id bigint NOT NULL,
  machine_id bigint NOT NULL,
  state_value int NOT NULL,
  state_name varchar(100) DEFAULT NULL,
  state_color varchar(20) DEFAULT NULL,
  is_initial SMALLINT DEFAULT 0,
  is_final SMALLINT DEFAULT 0,
  is_editable SMALLINT DEFAULT 0,
  is_deletable SMALLINT DEFAULT 0,
  pos_x int DEFAULT NULL,
  pos_y int DEFAULT NULL,
  sort_index int DEFAULT 0,
  PRIMARY KEY (id)
);

-- meta_state_transition：状态流转（from→to + 触发按钮 + 前置校验 + 后置动作 + 工作流）
-- 标准流转17条：保存(0→1)/暂存(0→0)/提交(1→2)/审核(2→3)/驳回(2→4)/重新提交(4→2)
--               撤销反提交(2→1)/撤销反审核(3→1)/删除(0/1/4→-1)
--               关闭(3→3,is_closed=1)/反关闭(3→3,is_closed=0)
--               取消(3→3,is_cancel=1)/反取消(3→3,is_cancel=0)
--               变更(3→3,生成变更单)/下推(3→3,pre_check校验可下推量)
CREATE TABLE meta_state_transition (
  id bigint NOT NULL,
  machine_id bigint NOT NULL,
  from_state int DEFAULT NULL,
  to_state int DEFAULT NULL,
  action_name varchar(100) DEFAULT NULL,
  button_code varchar(100) DEFAULT NULL,
  pre_check varchar(1000) DEFAULT NULL,
  post_action varchar(1000) DEFAULT NULL,
  need_wf SMALLINT DEFAULT 0,
  wf_push_api varchar(500) DEFAULT NULL,
  wf_callback_url varchar(500) DEFAULT NULL,
  wf_callback_display varchar(500) DEFAULT NULL,
  require_reason SMALLINT DEFAULT 0,
  sort_index int DEFAULT 0,
  PRIMARY KEY (id)
);

-- ---------------------------------------------------------------------
-- 三、按钮与下推转换
-- ---------------------------------------------------------------------

-- meta_button：按钮定义（15个标准按钮 + 自定义按钮）
-- 标准按钮：add/copy/draft/save/submit/audit/revoke/reject/delete/close/cancel/change/push/trace/print
CREATE TABLE meta_button (
  id bigint NOT NULL,
  button_code varchar(100) NOT NULL,
  button_name varchar(200) DEFAULT NULL,
  button_type varchar(50) DEFAULT NULL,
  icon varchar(200) DEFAULT NULL,
  location varchar(50) DEFAULT NULL,
  exec_order int DEFAULT 0,
  remark varchar(500) DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE (button_code)
);

-- meta_form_button：表单-按钮绑定 + 可用性矩阵 + 二次确认 + 插件
-- 可用性4档：enabled可用/disabled禁用/hidden隐藏/readonly只读 × 5状态(0/1/2/3/4)
CREATE TABLE meta_form_button (
  id bigint NOT NULL,
  bo_code varchar(50) NOT NULL,
  button_code varchar(100) NOT NULL,
  availability_json varchar(500) DEFAULT NULL,
  plugin_event varchar(100) DEFAULT NULL,
  confirm_msg varchar(500) DEFAULT NULL,
  sort_index int DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE (bo_code,button_code)
);

-- meta_push_rule：下推转换规则（源单→目标单）
CREATE TABLE meta_push_rule (
  id bigint NOT NULL,
  rule_code varchar(100) NOT NULL,
  rule_name varchar(200) DEFAULT NULL,
  src_bo_code varchar(50) NOT NULL,
  tgt_bo_code varchar(50) NOT NULL,
  field_mapping_json CLOB,
  vp_check_expr varchar(1000) DEFAULT NULL,
  filter_expr varchar(1000) DEFAULT NULL,
  qty_field varchar(100) DEFAULT NULL,
  pushed_field varchar(100) DEFAULT NULL,
  allow_merge SMALLINT DEFAULT 0,
  allow_split SMALLINT DEFAULT 0,
  is_enable SMALLINT DEFAULT 1,
  PRIMARY KEY (id),
  UNIQUE (rule_code)
);

-- biz_bill_link：单据上下游关联（联查依据，下推时自动写入）
CREATE TABLE biz_bill_link (
  id bigint NOT NULL,
  src_bo_code varchar(50) DEFAULT NULL,
  src_bill_id bigint DEFAULT NULL,
  src_line_id bigint DEFAULT NULL,
  tgt_bo_code varchar(50) DEFAULT NULL,
  tgt_bill_id bigint DEFAULT NULL,
  tgt_line_id bigint DEFAULT NULL,
  link_qty decimal(19,6) DEFAULT NULL,
  push_rule_code varchar(100) DEFAULT NULL,
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id)
);

-- ---------------------------------------------------------------------
-- 四、变更日志与操作日志
-- ---------------------------------------------------------------------

-- biz_change_log：字段级变更日志（变更单留痕）
CREATE TABLE biz_change_log (
  id bigint NOT NULL,
  bo_code varchar(50) DEFAULT NULL,
  bill_id bigint DEFAULT NULL,
  entity_code varchar(50) DEFAULT NULL,
  line_id bigint DEFAULT NULL,
  field_code varchar(100) DEFAULT NULL,
  field_name varchar(200) DEFAULT NULL,
  old_value CLOB,
  new_value CLOB,
  change_code varchar(200) DEFAULT NULL,
  change_reason varchar(2000) DEFAULT NULL,
  change_by varchar(200) DEFAULT NULL,
  change_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id)
);

-- biz_op_log：业务操作日志（状态变更全记录）
CREATE TABLE biz_op_log (
  id bigint NOT NULL,
  bo_code varchar(50) DEFAULT NULL,
  bill_id bigint DEFAULT NULL,
  bill_code varchar(200) DEFAULT NULL,
  op_type varchar(50) DEFAULT NULL,
  from_state int DEFAULT NULL,
  to_state int DEFAULT NULL,
  op_remark varchar(2000) DEFAULT NULL,
  op_by varchar(200) DEFAULT NULL,
  op_time TIMESTAMP DEFAULT NULL,
  ip varchar(100) DEFAULT NULL,
  PRIMARY KEY (id)
);

-- ---------------------------------------------------------------------
-- 五、编码规则（段定义模型：prefix/date/serial/fixed/variable）
-- ---------------------------------------------------------------------

-- meta_code_rule：编码规则定义（段式编排，与业务对象 bo_code 关联）
CREATE TABLE meta_code_rule (
  id bigint NOT NULL,
  rule_code varchar(50) NOT NULL,
  rule_name varchar(100) NOT NULL,
  bo_code varchar(50) NOT NULL,
  org_id bigint DEFAULT NULL,
  segments_json CLOB NOT NULL,
  reset_type varchar(20) NOT NULL DEFAULT 'year',
  is_manual SMALLINT NOT NULL DEFAULT 0,
  status SMALLINT NOT NULL DEFAULT 1,
  remark varchar(500) DEFAULT NULL,
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE (rule_code)
);

-- meta_code_serial：编码流水记录（配合 meta_code_rule，并发安全行锁）
CREATE TABLE meta_code_serial (
  id bigint NOT NULL,
  rule_code varchar(50) NOT NULL,
  org_id bigint DEFAULT NULL,
  period varchar(20) NOT NULL,
  current_serial bigint NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE (rule_code,org_id,period)
);

-- ---------------------------------------------------------------------
-- 六、插件机制（金蝶BOS三基类：BillPlugin/ListPlugin/OperationServicePlugin）
-- ---------------------------------------------------------------------

-- meta_form_plugin：插件绑定（金蝶BOS风格，3基类 + 3插件类型 + 上下文传递）
-- 基类：BillPlugin(表单插件,13事件) / ListPlugin(列表插件,5事件) / OperationServicePlugin(操作服务插件,6流水线事件)
-- 插件类型：script脚本 / api外部API / class Java类上传
-- 事务边界：整个操作（含插件与主流程），插件异常默认阻断并回滚
-- 自描述模型：plugin_type=class 时，base_class/class_base/class_name/class_file 由系统上传时反射 superclass 链
--           自动识别回填（非用户填写）；参数结构由 @FormParam/@BehaviorParam 注解声明、反射扫描自动发现
CREATE TABLE meta_form_plugin (
  id bigint NOT NULL,
  plugin_code varchar(50) NOT NULL,
  plugin_name varchar(200) NOT NULL,
  bo_code varchar(50) NOT NULL,
  base_class varchar(50) NOT NULL DEFAULT 'BillPlugin',
  event_name varchar(50) NOT NULL,
  field_code varchar(100) DEFAULT NULL,
  plugin_type varchar(20) NOT NULL DEFAULT 'script',
  exec_order int NOT NULL DEFAULT 10,
  status SMALLINT NOT NULL DEFAULT 1,
  remark varchar(500) DEFAULT NULL,
  -- 脚本插件
  script_content CLOB,
  -- API 插件
  api_url varchar(500) DEFAULT NULL,
  api_method varchar(10) DEFAULT 'POST',
  api_headers varchar(1000) DEFAULT NULL,
  api_timeout int DEFAULT 10,
  -- Java 类插件（自描述模型：以下四项由系统上传时反射自动识别回填，非用户填写）
  class_name varchar(300) DEFAULT NULL,
  class_file varchar(500) DEFAULT NULL,
  class_base varchar(300) DEFAULT NULL,
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE (plugin_code)
);

-- meta_plugin_param：Java类插件传入参数（表单参数 form + 行为参数 behavior）
-- 自描述模型（参数零配置）：param_key/param_label/param_type/default_value 全部由系统反射扫描
--           @FormParam/@BehaviorParam 注解自动生成，无管理员配置项；运行时系统按 param_type 自动注入：
--           form 类型读取 bill_data[param_key]（param_key=单据字段编码），behavior 类型注入 default_value
-- 通过基类 PluginContext 传递给插件实现类
CREATE TABLE meta_plugin_param (
  id bigint NOT NULL,
  plugin_code varchar(50) NOT NULL,
  param_key varchar(100) NOT NULL,
  param_label varchar(200) DEFAULT NULL,
  param_type varchar(20) NOT NULL DEFAULT 'form',
  default_value varchar(500) DEFAULT NULL,
  sort_index int DEFAULT 0,
  PRIMARY KEY (id)
);

-- meta_plugin_validator：操作服务插件校验器（OnAddValidators 阶段挂载）
-- 仅 OperationServicePlugin 基类在 OnAddValidators 事件下使用
CREATE TABLE meta_plugin_validator (
  id bigint NOT NULL,
  plugin_code varchar(50) NOT NULL,
  validator_code varchar(50) NOT NULL,
  validator_name varchar(200) DEFAULT NULL,
  validator_class varchar(300) DEFAULT NULL,
  validate_expr varchar(1000) DEFAULT NULL,
  error_msg varchar(500) DEFAULT NULL,
  is_enabled SMALLINT NOT NULL DEFAULT 1,
  sort_index int DEFAULT 0,
  PRIMARY KEY (id)
);

-- biz_plugin_log：插件执行日志（执行时间/入参/出参/异常）
CREATE TABLE biz_plugin_log (
  id bigint NOT NULL,
  plugin_code varchar(50) DEFAULT NULL,
  bo_code varchar(50) DEFAULT NULL,
  event_name varchar(50) DEFAULT NULL,
  bill_id bigint DEFAULT NULL,
  exec_order int DEFAULT NULL,
  input_params CLOB,
  output_result CLOB,
  exec_time_ms int DEFAULT NULL,
  is_success SMALLINT DEFAULT 1,
  error_msg CLOB,
  exec_by varchar(200) DEFAULT NULL,
  exec_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id)
);

-- ---------------------------------------------------------------------
-- 七、实体服务规则（BOS 声明式规则引擎，ANTLR4 表达式）
-- ---------------------------------------------------------------------

-- meta_entity_rule：实体服务规则定义（validate/calc/linkage/available 四类）
CREATE TABLE meta_entity_rule (
  id bigint NOT NULL,
  rule_code varchar(50) NOT NULL,
  rule_name varchar(100) NOT NULL,
  bo_code varchar(50) NOT NULL,
  entity_code varchar(50) NOT NULL,
  rule_type varchar(20) NOT NULL,
  trigger_event varchar(50) NOT NULL,
  trigger_field varchar(50) DEFAULT NULL,
  priority int NOT NULL DEFAULT 100,
  is_enabled SMALLINT NOT NULL DEFAULT 1,
  remark varchar(500) DEFAULT NULL,
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE (rule_code)
);

-- meta_entity_rule_item：实体服务规则条目（多条件多动作）
CREATE TABLE meta_entity_rule_item (
  id bigint NOT NULL,
  rule_code varchar(50) NOT NULL,
  item_seq int NOT NULL,
  condition_expr CLOB,
  action_expr CLOB NOT NULL,
  error_msg varchar(500) DEFAULT NULL,
  PRIMARY KEY (id)
);

-- ---------------------------------------------------------------------
-- 八、反写规则（下游单据审核/撤销回写上游执行量）
-- ---------------------------------------------------------------------

-- meta_writeback_rule：反写规则定义（add累加/subtract扣减/cover覆盖）
CREATE TABLE meta_writeback_rule (
  id bigint NOT NULL,
  rule_code varchar(50) NOT NULL,
  rule_name varchar(100) NOT NULL,
  src_bill_type varchar(50) NOT NULL,
  target_bill_type varchar(50) NOT NULL,
  trigger_op varchar(200) NOT NULL,
  src_link_field varchar(100) NOT NULL,
  target_link_field varchar(100) NOT NULL,
  writeback_mode varchar(20) NOT NULL,
  src_table varchar(100) DEFAULT NULL,
  target_table varchar(100) DEFAULT NULL,
  status_filter varchar(200) DEFAULT NULL,
  src_main_table varchar(100) DEFAULT NULL,
  src_main_fk varchar(100) DEFAULT NULL,
  target_main_fk varchar(100) DEFAULT NULL,
  over_control varchar(20) NOT NULL DEFAULT 'block',
  over_expr CLOB,
  condition_expr CLOB,
  cascade SMALLINT NOT NULL DEFAULT 0,
  is_enabled SMALLINT NOT NULL DEFAULT 1,
  remark varchar(500) DEFAULT NULL,
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE (rule_code)
);

-- meta_writeback_field：反写字段映射
CREATE TABLE meta_writeback_field (
  id bigint NOT NULL,
  rule_code varchar(50) NOT NULL,
  item_seq int NOT NULL,
  src_field varchar(50) NOT NULL,
  target_field varchar(50) NOT NULL,
  base_field varchar(50) DEFAULT NULL,
  writeback_expr varchar(200) NOT NULL,
  PRIMARY KEY (id)
);

-- ---------------------------------------------------------------------
-- 九、列表查询配置
-- ---------------------------------------------------------------------

-- meta_list_column：列表列定义（管理员配置，含冻结/合计/平均）
CREATE TABLE meta_list_column (
  id bigint NOT NULL,
  bo_code varchar(50) NOT NULL,
  field_code varchar(100) NOT NULL,
  field_name varchar(200) DEFAULT NULL,
  entity_code varchar(50) DEFAULT NULL,
  ctrl_type varchar(50) DEFAULT NULL,
  is_show SMALLINT DEFAULT 1,
  is_fixed varchar(10) DEFAULT 'none',
  is_sum SMALLINT DEFAULT 0,
  is_avg SMALLINT DEFAULT 0,
  col_width int DEFAULT NULL,
  sort_index int DEFAULT 0,
  is_enable SMALLINT DEFAULT 1,
  PRIMARY KEY (id)
);

-- meta_query_field：查询字段配置（普通/高级，14种运算符）
CREATE TABLE meta_query_field (
  id bigint NOT NULL,
  bo_code varchar(50) NOT NULL,
  field_code varchar(100) NOT NULL,
  field_name varchar(200) DEFAULT NULL,
  entity_code varchar(50) DEFAULT NULL,
  is_common SMALLINT DEFAULT 0,
  is_advanced SMALLINT DEFAULT 0,
  operators varchar(500) DEFAULT NULL,
  default_op varchar(50) DEFAULT 'eq',
  sort_index int DEFAULT 0,
  is_enable SMALLINT DEFAULT 1,
  PRIMARY KEY (id)
);

-- user_list_setting：用户列设置（私有）
CREATE TABLE user_list_setting (
  id bigint NOT NULL,
  user_id bigint DEFAULT NULL,
  bo_code varchar(50) DEFAULT NULL,
  columns_json CLOB,
  page_size int DEFAULT 20,
  update_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE (user_id,bo_code)
);

-- user_query_scheme：用户查询方案（私有+公共）
CREATE TABLE user_query_scheme (
  id bigint NOT NULL,
  user_id bigint DEFAULT NULL,
  bo_code varchar(50) DEFAULT NULL,
  scheme_name varchar(200) DEFAULT NULL,
  condition_json CLOB,
  columns_json CLOB,
  order_by varchar(500) DEFAULT NULL,
  page_size int DEFAULT 20,
  is_default SMALLINT DEFAULT 0,
  is_favorite SMALLINT DEFAULT 0,
  is_public SMALLINT DEFAULT 0,
  create_time TIMESTAMP DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id)
);

-- ---------------------------------------------------------------------
-- 十、打印模板（FineReport 风格类 Excel 单元格设计器）
-- ---------------------------------------------------------------------

-- meta_print_template：打印模板（类Excel单元格画布 + 行带区 + 合并 + 扩展）
-- 设计要素：单元格(cells)、合并(merges)、行带区(row_bands: title/header/detail/summary)
-- 字段绑定：cell_type=field + expand(none/vertical/horizontal) + data_setting(list/group/sum/avg/max/min/count)
-- 公式：cell_type=formula，如 =sum(D3) =count() =avg()
-- 纸张设置：paper_type/paper_width/paper_height/orientation/margin_json（GAP-D10-001/009 / RISK-D10-004）
CREATE TABLE meta_print_template (
  id bigint NOT NULL,
  template_code varchar(100) NOT NULL,
  template_name varchar(200) DEFAULT NULL,
  bo_code varchar(50) NOT NULL,
  template_type varchar(50) DEFAULT 'single',
  lang varchar(20) DEFAULT 'zh',
  paper_size varchar(50) DEFAULT 'A4',
  paper_type varchar(20) DEFAULT 'A4',
  paper_width int DEFAULT NULL,
  paper_height int DEFAULT NULL,
  orientation varchar(20) DEFAULT 'portrait',
  margin_json varchar(500) DEFAULT NULL,
  row_count int DEFAULT 12,
  col_count int DEFAULT 8,
  cells_json CLOB,
  merges_json CLOB,
  row_bands_json CLOB,
  template_json CLOB,
  is_default SMALLINT DEFAULT 0,
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE (template_code)
);

-- ---------------------------------------------------------------------
-- 十一、权限体系（用户/角色/按钮权限/字段权限/数据权限）
-- 注：sys_org / sys_dept 定义见 01-基础资料表.sql
-- ---------------------------------------------------------------------

-- sys_user：系统用户
CREATE TABLE sys_user (
  id bigint NOT NULL,
  username varchar(100) NOT NULL,
  password varchar(200) DEFAULT NULL,
  real_name varchar(100) DEFAULT NULL,
  emp_id bigint DEFAULT NULL,
  org_id bigint DEFAULT NULL,
  dept_id bigint DEFAULT NULL,
  email varchar(200) DEFAULT NULL,
  phone varchar(50) DEFAULT NULL,
  status int DEFAULT 1,
  last_login_time TIMESTAMP DEFAULT NULL,
  pwd_update_time TIMESTAMP DEFAULT NULL,
  fail_count int DEFAULT 0,
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE (username)
);

-- sys_role：角色（支持继承）
CREATE TABLE sys_role (
  id bigint NOT NULL,
  role_code varchar(100) NOT NULL,
  role_name varchar(200) DEFAULT NULL,
  parent_id bigint DEFAULT NULL,
  remark varchar(500) DEFAULT NULL,
  status int DEFAULT 1,
  create_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE (role_code)
);

-- sys_user_role：用户-角色关联
CREATE TABLE sys_user_role (
  id bigint NOT NULL,
  user_id bigint DEFAULT NULL,
  role_id bigint DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE (user_id,role_id)
);

-- sys_user_org：用户-组织归属（多组织，GAP-D11-001 / RISK-D11-002）
-- 一个用户可归属多个组织，标记主组织（is_main=1），支持跨组织业务
CREATE TABLE sys_user_org (
  id bigint NOT NULL,
  user_id bigint NOT NULL,
  org_id bigint NOT NULL,
  is_main SMALLINT DEFAULT 0,
  eff_date date DEFAULT NULL,
  exp_date date DEFAULT NULL,
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE (user_id,org_id)
);

-- sys_role_button：角色-按钮授权（4档控制级别）
CREATE TABLE sys_role_button (
  id bigint NOT NULL,
  role_id bigint DEFAULT NULL,
  bo_code varchar(50) DEFAULT NULL,
  button_code varchar(100) DEFAULT NULL,
  control_level varchar(20) DEFAULT 'enabled',
  PRIMARY KEY (id),
  UNIQUE (role_id,bo_code,button_code)
);

-- sys_menu：系统菜单（多级树形，前端侧边栏从此表动态加载）
CREATE TABLE sys_menu (
  id bigint NOT NULL,
  menu_code varchar(50) NOT NULL,
  menu_name varchar(100) NOT NULL,
  parent_id bigint NOT NULL DEFAULT 0,
  menu_type varchar(20) NOT NULL DEFAULT 'menu',
  path varchar(200) DEFAULT NULL,
  icon varchar(50) DEFAULT NULL,
  sort_index int NOT NULL DEFAULT 99,
  visible SMALLINT NOT NULL DEFAULT 1,
  status SMALLINT NOT NULL DEFAULT 1,
  remark varchar(500) DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE (menu_code)
);

-- field_permission：字段权限（列级，visible/hidden/mask）
CREATE TABLE field_permission (
  id bigint NOT NULL,
  role_id bigint DEFAULT NULL,
  bo_code varchar(50) DEFAULT NULL,
  field_code varchar(100) DEFAULT NULL,
  permission varchar(20) DEFAULT 'visible',
  PRIMARY KEY (id),
  UNIQUE (role_id,bo_code,field_code)
);

-- data_permission_rule：数据权限规则（行级，5种数据范围）
CREATE TABLE data_permission_rule (
  id bigint NOT NULL,
  role_id bigint DEFAULT NULL,
  bo_code varchar(50) DEFAULT NULL,
  dimension varchar(50) DEFAULT NULL,
  scope_type varchar(50) DEFAULT NULL,
  field_code varchar(100) DEFAULT NULL,
  is_enable SMALLINT DEFAULT 1,
  PRIMARY KEY (id)
);

-- data_permission_scope：数据权限范围授权（custom 自定义具体记录）
CREATE TABLE data_permission_scope (
  id bigint NOT NULL,
  rule_id bigint DEFAULT NULL,
  ref_id bigint DEFAULT NULL,
  PRIMARY KEY (id)
);

-- ---------------------------------------------------------------------
-- 十二、工作流对接 + 附件 + 导入导出 + API日志
-- ---------------------------------------------------------------------

-- wf_instance：外部工作流对接（审批流由独立工作流系统承担）
CREATE TABLE wf_instance (
  id bigint NOT NULL,
  instance_id bigint NOT NULL,
  request_id varchar(100) DEFAULT NULL,
  bill_type varchar(50) DEFAULT NULL,
  bill_id bigint DEFAULT NULL,
  status varchar(20) DEFAULT NULL,
  submit_by varchar(200) DEFAULT NULL,
  submit_time TIMESTAMP DEFAULT NULL,
  callback_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE (request_id)
);

-- sys_attachment：附件管理
CREATE TABLE sys_attachment (
  id bigint NOT NULL,
  bill_type varchar(50) NOT NULL,
  bill_id bigint NOT NULL,
  file_name varchar(255) NOT NULL,
  file_path varchar(500) NOT NULL,
  file_size bigint DEFAULT NULL,
  file_type varchar(20) DEFAULT NULL,
  storage_type varchar(10) NOT NULL DEFAULT 'local',
  version int NOT NULL DEFAULT 1,
  upload_by varchar(200) DEFAULT NULL,
  upload_time TIMESTAMP DEFAULT NULL,
  is_deleted SMALLINT NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);

-- sys_import_task：数据导入任务（异步导入 + 模板配置）
CREATE TABLE sys_import_task (
  id bigint NOT NULL,
  task_code varchar(100) DEFAULT NULL,
  bo_code varchar(50) NOT NULL,
  template_name varchar(200) DEFAULT NULL,
  file_name varchar(255) DEFAULT NULL,
  file_path varchar(500) DEFAULT NULL,
  total_count int DEFAULT 0,
  success_count int DEFAULT 0,
  fail_count int DEFAULT 0,
  status varchar(20) DEFAULT 'pending',
  error_log CLOB,
  import_by varchar(200) DEFAULT NULL,
  import_time TIMESTAMP DEFAULT NULL,
  finish_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id)
);

-- meta_import_template：导入模板配置（PRD 07.3.7，GAP-D12-012 / RISK-D12-006）
-- 字段映射 + 校验规则 + 行为配置，模板驱动批量导入
CREATE TABLE meta_import_template (
  id bigint NOT NULL,
  template_code varchar(100) NOT NULL,
  template_name varchar(200) NOT NULL,
  bo_code varchar(50) NOT NULL,
  field_mappings_json CLOB,
  unique_fields varchar(500) DEFAULT NULL,
  required_fields varchar(500) DEFAULT NULL,
  allow_update SMALLINT DEFAULT 0,
  update_key varchar(100) DEFAULT NULL,
  fail_fast SMALLINT DEFAULT 1,
  template_file varchar(500) DEFAULT NULL,
  status SMALLINT DEFAULT 1,
  remark varchar(500) DEFAULT NULL,
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE (template_code)
);

-- sys_api_log：外部接口调用日志（插件API调用、工作流推送、第三方集成）
CREATE TABLE sys_api_log (
  id bigint NOT NULL,
  category varchar(32) DEFAULT NULL,
  api_type varchar(50) DEFAULT NULL,
  source_code varchar(100) DEFAULT NULL,
  bo_code varchar(50) DEFAULT NULL,
  bill_id bigint DEFAULT NULL,
  api_url varchar(500) DEFAULT NULL,
  api_method varchar(10) DEFAULT NULL,
  request_body CLOB,
  response_body CLOB,
  status_code int DEFAULT NULL,
  duration_ms int DEFAULT NULL,
  is_success SMALLINT DEFAULT 1,
  error_msg varchar(2000) DEFAULT NULL,
  call_by varchar(200) DEFAULT NULL,
  call_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id)
);


-- ============================================================
-- 00b-biz-writeback-log
-- ============================================================

-- ======================================================================
-- 00b-biz-writeback-log.sql
-- 模块：A4 规则与反写引擎
-- 用途：1) 补建 biz_writeback_log 反写失败补偿日志表（对齐设计文档 08 §5.5）
--       2) 扩展 meta_writeback_rule 增加 exec_mode 字段（对齐设计文档 08 §5.6）
-- 说明：本文件为 00-平台元数据表.sql 的增量补充，独立执行不影响既有结构。
-- ======================================================================

-- ---------------------------------------------------------------------
-- 一、biz_writeback_log：反写失败补偿日志（ASYNC 反写失败 / 同步重试中）
--    对齐设计文档 08 §5.5 / §3.6 AbstractWritebackCompensationService
--    状态流转：PENDING（初次记录）→ SUCCESS（重试成功）/ FAILED（重试中或超过 max_retry 终态）
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS biz_writeback_log (
  id bigint NOT NULL,
  rule_id bigint NOT NULL,
  rule_code varchar(50) NOT NULL,
  src_bill_id bigint NOT NULL,
  src_bo_code varchar(50) NOT NULL,
  target_bo_code varchar(50) DEFAULT NULL,
  target_bill_id bigint DEFAULT NULL,
  status varchar(20) NOT NULL DEFAULT 'PENDING',
  retry_count int NOT NULL DEFAULT 0,
  max_retry int NOT NULL DEFAULT 5,
  error_msg CLOB,
  next_retry_time TIMESTAMP DEFAULT NULL,
  created_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id)
);

-- ---------------------------------------------------------------------
-- 二、meta_writeback_rule 扩展 exec_mode 字段
--    对齐设计文档 08 §5.6 / §3.7 异步反写设计
--    取值：SYNC（同步，事务内执行，失败回滚）/ ASYNC（异步，事务后执行，失败记 biz_writeback_log）
-- ---------------------------------------------------------------------
ALTER TABLE meta_writeback_rule
  ADD COLUMN exec_mode varchar(10) NOT NULL DEFAULT 'SYNC' AFTER over_control;


-- ============================================================
-- 00c-平台元数据扩展补全
-- ============================================================

-- ======================================================================
-- 00c-平台元数据扩展补全.sql
-- 模块：B2 数据库 schema 补充
-- 用途：1) 补全 meta_print_template.is_enable 启用状态字段（对齐设计文档 02 §3.8）
--       2) 补全 meta_print_template 缺失的审计字段索引（如有必要）
-- 说明：本文件为 00-平台元数据表.sql 的增量补充，独立执行不影响既有结构。
--       meta_print_template 表已含 create_by/create_time/update_by/update_time 字段，
--       仅缺 is_enable 启用状态字段。
-- ======================================================================

-- ---------------------------------------------------------------------
-- 一、meta_print_template 补全 is_enable 字段
--    对齐设计文档 02 §3.8 AbstractPrintTemplateService.listByBoCode/getDefault
--    取值：0 停用 / 1 启用（默认 1）
--    MetaPrintTemplateService.listByBoCode 按 is_enable=1 过滤
--    MetaPrintTemplateService.getDefault   按 is_default=1 + is_enable=1 过滤
-- ---------------------------------------------------------------------
ALTER TABLE meta_print_template
  ADD COLUMN is_enable SMALLINT NOT NULL DEFAULT 1 AFTER is_default;


-- ============================================================
-- 01-基础资料表
-- ============================================================

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
CREATE TABLE sys_org (
  id bigint NOT NULL,
  code varchar(100) DEFAULT NULL,
  name varchar(200) DEFAULT NULL,
  org_type varchar(50) DEFAULT NULL,
  parent_id bigint DEFAULT NULL,
  is_accounting int DEFAULT '0',
  is_business int DEFAULT '0',
  base_curr_id bigint DEFAULT NULL,
  tax_no varchar(100) DEFAULT NULL,
  address varchar(500) DEFAULT NULL,
  status int DEFAULT '1',
  sort_index int DEFAULT '0',
  logo varchar(255) DEFAULT NULL,
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE (code)
);

-- sys_dept：部门
CREATE TABLE sys_dept (
  id bigint NOT NULL,
  code varchar(100) DEFAULT NULL,
  name varchar(200) DEFAULT NULL,
  org_id bigint DEFAULT NULL,
  parent_id bigint DEFAULT NULL,
  dept_type varchar(50) DEFAULT NULL,
  manager_id bigint DEFAULT NULL,
  status int DEFAULT '1',
  sort_index int DEFAULT '0',
  PRIMARY KEY (id),
  UNIQUE (code)
);

-- sys_employee：员工
CREATE TABLE sys_employee (
  id bigint NOT NULL,
  code varchar(100) DEFAULT NULL,
  name varchar(100) DEFAULT NULL,
  org_id bigint DEFAULT NULL,
  dept_id bigint DEFAULT NULL,
  position varchar(100) DEFAULT NULL,
  gender int DEFAULT NULL,
  entry_date date DEFAULT NULL,
  is_saler int DEFAULT '0',
  is_purchaser int DEFAULT '0',
  user_id bigint DEFAULT NULL,
  mobile varchar(100) DEFAULT NULL,
  email varchar(100) DEFAULT NULL,
  manager_id bigint DEFAULT NULL,
  birthday date DEFAULT NULL,
  departure_date date DEFAULT NULL,
  employee_rank int DEFAULT NULL,
  active int DEFAULT '1',
  remark CLOB,
  status int DEFAULT '1',
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE (code)
);

-- ---------------------------------------------------------------------
-- 二、客商
-- ---------------------------------------------------------------------

-- md_customer：客户
CREATE TABLE md_customer (
  id bigint NOT NULL,
  code varchar(100) DEFAULT NULL,
  name varchar(200) DEFAULT NULL,
  name_en varchar(200) DEFAULT NULL,
  short_name varchar(200) DEFAULT NULL,
  cust_type varchar(50) DEFAULT NULL,
  trade_type varchar(200) DEFAULT NULL,
  curr_id bigint DEFAULT NULL,
  sal_org_id bigint DEFAULT NULL,
  saler_id bigint DEFAULT NULL,
  credit_limit decimal(19,6) DEFAULT NULL,
  credit_period int DEFAULT NULL,
  tax_rate decimal(16,8) DEFAULT NULL,
  tax_no varchar(100) DEFAULT NULL,
  firp_type varchar(200) DEFAULT NULL,
  rec_type varchar(200) DEFAULT NULL,
  contact varchar(100) DEFAULT NULL,
  phone varchar(100) DEFAULT NULL,
  fax varchar(100) DEFAULT NULL,
  email varchar(200) DEFAULT NULL,
  address varchar(500) DEFAULT NULL,
  address_en varchar(500) DEFAULT NULL,
  harbour_end varchar(200) DEFAULT NULL,
  bank_name varchar(200) DEFAULT NULL,
  bank_account varchar(100) DEFAULT NULL,
  credit_balance decimal(18,4) DEFAULT NULL,
  is_credit_check SMALLINT NOT NULL DEFAULT 0,
  credit_expiry date DEFAULT NULL,
  credit_level varchar(50) DEFAULT NULL,
  credit_status varchar(50) DEFAULT NULL,
  ar_period varchar(50) DEFAULT NULL,
  overdue_days int DEFAULT NULL,
  group_cust_id bigint DEFAULT NULL,
  cust_gp_id bigint DEFAULT NULL,
  is_gp_cust int DEFAULT '0',
  legal_person varchar(200) DEFAULT NULL,
  reg_capital decimal(19,6) DEFAULT NULL,
  comp_nature varchar(200) DEFAULT NULL,
  comp_size varchar(200) DEFAULT NULL,
  comp_date date DEFAULT NULL,
  industry varchar(200) DEFAULT NULL,
  country varchar(200) DEFAULT NULL,
  province varchar(200) DEFAULT NULL,
  region varchar(200) DEFAULT NULL,
  post_code varchar(200) DEFAULT NULL,
  inv_title varchar(200) DEFAULT NULL,
  inv_type varchar(200) DEFAULT NULL,
  prod_inv_name varchar(200) DEFAULT NULL,
  attm varchar(255) DEFAULT NULL,
  allow_sale int DEFAULT '1',
  allow_trust int DEFAULT '0',
  allow_purchase int DEFAULT '1',
  allow_outsource int DEFAULT '0',
  remark CLOB,
  status int DEFAULT '1',
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE (code)
);

-- md_supplier：供应商
CREATE TABLE md_supplier (
  id bigint NOT NULL,
  code varchar(100) DEFAULT NULL,
  name varchar(200) DEFAULT NULL,
  name_en varchar(200) DEFAULT NULL,
  short_name varchar(200) DEFAULT NULL,
  sup_type varchar(50) DEFAULT NULL,
  curr_id bigint DEFAULT NULL,
  pur_org_id bigint DEFAULT NULL,
  purchaser_id bigint DEFAULT NULL,
  tax_rate decimal(16,8) DEFAULT NULL,
  tax_no varchar(100) DEFAULT NULL,
  firp_type varchar(200) DEFAULT NULL,
  pay_type varchar(200) DEFAULT NULL,
  is_agri int DEFAULT '0',
  credit_level varchar(50) DEFAULT NULL,
  contact varchar(100) DEFAULT NULL,
  phone varchar(100) DEFAULT NULL,
  fax varchar(100) DEFAULT NULL,
  email varchar(200) DEFAULT NULL,
  address varchar(500) DEFAULT NULL,
  bank_name varchar(200) DEFAULT NULL,
  bank_account varchar(100) DEFAULT NULL,
  on_time_rate decimal(5,2) DEFAULT NULL,
  pass_rate decimal(5,2) DEFAULT NULL,
  eval_score decimal(5,2) DEFAULT NULL,
  eval_level varchar(2) DEFAULT NULL,
  eval_date date DEFAULT NULL,
  status int DEFAULT '1',
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE (code)
);

-- ---------------------------------------------------------------------
-- 三、物料（核心主数据，含纱线行业属性）
-- ---------------------------------------------------------------------

-- md_material：物料
CREATE TABLE md_material (
  id bigint NOT NULL,
  code varchar(100) DEFAULT NULL,
  name varchar(200) DEFAULT NULL,
  name_en varchar(200) DEFAULT NULL,
  spec varchar(200) DEFAULT NULL,
  mat_type varchar(50) DEFAULT NULL,
  yarn_count decimal(16,8) DEFAULT NULL,
  strand decimal(16,8) DEFAULT NULL,
  yarn_type varchar(50) DEFAULT NULL,
  twist varchar(100) DEFAULT NULL,
  fineness varchar(200) DEFAULT NULL,
  color varchar(100) DEFAULT NULL,
  unit_id bigint DEFAULT NULL,
  weight_type varchar(200) DEFAULT NULL,
  ct_weight decimal(16,8) DEFAULT NULL,
  batch_flag int DEFAULT '0',
  vat_flag int DEFAULT '0',
  shelf_life int DEFAULT NULL,
  tax_rate decimal(16,8) DEFAULT NULL,
  std_cost decimal(19,6) DEFAULT NULL,
  purchase_flag int DEFAULT '0',
  sale_flag int DEFAULT '0',
  produce_flag int DEFAULT '0',
  barcode varchar(100) DEFAULT NULL,
  dye_method varchar(200) DEFAULT NULL,
  prd_type varchar(200) DEFAULT NULL,
  yarn_proc varchar(200) DEFAULT NULL,
  twist_direction varchar(50) DEFAULT NULL,
  raw_material_detail CLOB,
  customs_no varchar(200) DEFAULT NULL,
  customs_name varchar(200) DEFAULT NULL,
  ra_fee decimal(19,6) DEFAULT NULL,
  pa_rate decimal(16,8) DEFAULT NULL,
  s_fee decimal(19,6) DEFAULT NULL,
  sale_rate decimal(16,8) DEFAULT NULL,
  stock_type varchar(200) DEFAULT NULL,
  mat_gp_id bigint DEFAULT NULL,
  mat_prop varchar(200) DEFAULT NULL,
  prd_rate decimal(16,8) DEFAULT NULL,
  is_newyarn int DEFAULT '0',
  mat_index varchar(100) DEFAULT NULL,
  is_inventory int DEFAULT '1',
  is_sub_contract int DEFAULT '0',
  is_check int DEFAULT '0',
  is_main_prd int DEFAULT '0',
  remark CLOB,
  status int DEFAULT '1',
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE (code)
);

-- ---------------------------------------------------------------------
-- 四、币别与汇率
-- ---------------------------------------------------------------------

-- md_currency：币别
CREATE TABLE md_currency (
  id bigint NOT NULL,
  code varchar(50) DEFAULT NULL,
  name varchar(100) DEFAULT NULL,
  symbol varchar(20) DEFAULT NULL,
  is_base int DEFAULT '0',
  decimal_digits int DEFAULT '2',
  status int DEFAULT '1',
  PRIMARY KEY (id),
  UNIQUE (code)
);

-- md_exchange_rate：汇率
CREATE TABLE md_exchange_rate (
  id bigint NOT NULL,
  curr_id bigint DEFAULT NULL,
  rate_type varchar(50) DEFAULT NULL,
  rate decimal(16,8) DEFAULT NULL,
  valid_date date DEFAULT NULL,
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id)
);

-- ---------------------------------------------------------------------
-- 五、仓库与仓位
-- ---------------------------------------------------------------------

-- md_warehouse：仓库
CREATE TABLE md_warehouse (
  id bigint NOT NULL,
  code varchar(100) DEFAULT NULL,
  name varchar(200) DEFAULT NULL,
  org_id bigint DEFAULT NULL,
  wh_type varchar(50) DEFAULT NULL,
  batch_flag int DEFAULT '0',
  manager_id bigint DEFAULT NULL,
  address varchar(500) DEFAULT NULL,
  status int DEFAULT '1',
  PRIMARY KEY (id),
  UNIQUE (code)
);

-- md_position：仓位
CREATE TABLE md_position (
  id bigint NOT NULL,
  warehouse_id bigint DEFAULT NULL,
  code varchar(100) DEFAULT NULL,
  name varchar(200) DEFAULT NULL,
  status int DEFAULT '1',
  PRIMARY KEY (id)
);

-- ---------------------------------------------------------------------
-- 六、计量单位
-- ---------------------------------------------------------------------

-- md_unit：计量单位
CREATE TABLE md_unit (
  id bigint NOT NULL,
  code varchar(50) DEFAULT NULL,
  name varchar(100) DEFAULT NULL,
  unit_type varchar(50) DEFAULT NULL,
  is_base int DEFAULT '0',
  status int DEFAULT '1',
  PRIMARY KEY (id),
  UNIQUE (code)
);

-- md_unit_conv：物料单位换算
CREATE TABLE md_unit_conv (
  id bigint NOT NULL,
  mat_id bigint DEFAULT NULL,
  from_unit_id bigint DEFAULT NULL,
  to_unit_id bigint DEFAULT NULL,
  rate decimal(16,8) DEFAULT NULL,
  PRIMARY KEY (id)
);

-- ---------------------------------------------------------------------
-- 七、品牌、色号、集锦卡、质量标准
-- ---------------------------------------------------------------------

-- md_brand：品牌
CREATE TABLE md_brand (
  id bigint NOT NULL,
  code varchar(100) DEFAULT NULL,
  name varchar(200) DEFAULT NULL,
  status int DEFAULT '1',
  PRIMARY KEY (id),
  UNIQUE (code)
);

-- md_color：色号
CREATE TABLE md_color (
  id bigint NOT NULL,
  code varchar(100) DEFAULT NULL,
  name varchar(200) DEFAULT NULL,
  color_type varchar(50) DEFAULT NULL,
  color_value varchar(50) DEFAULT NULL,
  color_sys_id bigint DEFAULT NULL,
  remark CLOB,
  status int DEFAULT '1',
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE (code)
);

-- md_hl_card：集锦卡（纱线工艺集合卡，记录纱线规格工艺标准）
CREATE TABLE md_hl_card (
  id bigint NOT NULL,
  code varchar(100) DEFAULT NULL,
  name varchar(200) DEFAULT NULL,
  mat_id bigint DEFAULT NULL,
  yarn_count decimal(16,8) DEFAULT NULL,
  strand decimal(16,8) DEFAULT NULL,
  twist varchar(100) DEFAULT NULL,
  fineness varchar(200) DEFAULT NULL,
  color_id bigint DEFAULT NULL,
  craft_desc CLOB,
  cn_name varchar(200) DEFAULT NULL,
  en_name varchar(200) DEFAULT NULL,
  sp_req varchar(200) DEFAULT NULL,
  sp_price decimal(19,6) DEFAULT NULL,
  remark CLOB,
  status int DEFAULT '1',
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE (code)
);

-- md_quality_std：质量标准
CREATE TABLE md_quality_std (
  id bigint NOT NULL,
  code varchar(100) DEFAULT NULL,
  name varchar(200) DEFAULT NULL,
  std_desc CLOB,
  status int DEFAULT '1',
  PRIMARY KEY (id),
  UNIQUE (code)
);

-- ---------------------------------------------------------------------
-- 八、贸易类型、结算方式、港口
-- ---------------------------------------------------------------------

-- md_trade_type：贸易类型/方式
CREATE TABLE md_trade_type (
  id bigint NOT NULL,
  code varchar(100) DEFAULT NULL,
  name varchar(200) DEFAULT NULL,
  name_en varchar(200) DEFAULT NULL,
  trade_kind varchar(50) DEFAULT NULL,
  status int DEFAULT '1',
  PRIMARY KEY (id),
  UNIQUE (code)
);

-- md_firp_type：结算/收款方式
CREATE TABLE md_firp_type (
  id bigint NOT NULL,
  code varchar(100) DEFAULT NULL,
  name varchar(200) DEFAULT NULL,
  firp_kind varchar(50) DEFAULT NULL,
  status int DEFAULT '1',
  PRIMARY KEY (id),
  UNIQUE (code)
);

-- md_harbour：港口
CREATE TABLE md_harbour (
  id bigint NOT NULL,
  code varchar(100) DEFAULT NULL,
  name_cn varchar(200) DEFAULT NULL,
  name_en varchar(200) DEFAULT NULL,
  country varchar(100) DEFAULT NULL,
  status int DEFAULT '1',
  PRIMARY KEY (id),
  UNIQUE (code)
);

-- ---------------------------------------------------------------------
-- 九、物料分组、原料、原料分组
-- ---------------------------------------------------------------------

-- md_material_group：物料分组
CREATE TABLE md_material_group (
  id bigint NOT NULL,
  code varchar(200) DEFAULT NULL,
  parent_id bigint DEFAULT '0',
  enabled int DEFAULT NULL,
  cn_name varchar(200) DEFAULT NULL,
  en_name varchar(200) DEFAULT NULL,
  create_by varchar(200) DEFAULT '',
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT '',
  update_time TIMESTAMP DEFAULT NULL,
  auditor varchar(200) DEFAULT NULL,
  audit_time TIMESTAMP DEFAULT NULL,
  remark CLOB,
  PRIMARY KEY (id)
);

-- md_raw_material：原料档案
CREATE TABLE md_raw_material (
  id bigint NOT NULL,
  code varchar(200) DEFAULT NULL,
  name varchar(200) DEFAULT NULL,
  cn_name varchar(200) DEFAULT NULL,
  en_name varchar(200) DEFAULT NULL,
  fineness varchar(200) DEFAULT NULL,
  s_fee decimal(19,6) DEFAULT NULL,
  damp decimal(16,8) DEFAULT NULL,
  prd_name varchar(200) DEFAULT NULL,
  cm_rate decimal(16,8) DEFAULT NULL,
  loss_rate decimal(16,8) DEFAULT NULL,
  wool_rate decimal(16,8) DEFAULT NULL,
  bulk_rate decimal(16,8) DEFAULT NULL,
  product_type varchar(200) DEFAULT NULL,
  description varchar(200) DEFAULT NULL,
  recomb_rate decimal(16,8) DEFAULT NULL,
  customs_name varchar(200) DEFAULT NULL,
  group_id bigint DEFAULT NULL,
  enabled int DEFAULT NULL,
  spin_type varchar(200) DEFAULT NULL,
  recomb_type varchar(200) DEFAULT NULL,
  prd_area varchar(255) DEFAULT NULL,
  remark CLOB,
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  auditor varchar(200) DEFAULT NULL,
  audit_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id)
);

-- md_raw_material_detail：原料成分
CREATE TABLE md_raw_material_detail (
  id bigint NOT NULL,
  sort_index int DEFAULT NULL,
  raw_mat_id bigint DEFAULT NULL,
  mat_id bigint DEFAULT NULL,
  ratio decimal(16,4) DEFAULT NULL,
  prd_addr_code varchar(200) DEFAULT NULL,
  prd_addr_name varchar(200) DEFAULT NULL,
  auth_type varchar(200) DEFAULT NULL,
  fineness varchar(200) DEFAULT NULL,
  cn_comp varchar(200) DEFAULT NULL,
  en_comp varchar(200) DEFAULT NULL,
  yarn_num decimal(16,2) DEFAULT NULL,
  line_num decimal(16,0) DEFAULT NULL,
  fiber_code varchar(100) DEFAULT NULL,
  fiber_name varchar(200) DEFAULT NULL,
  fiber_ratio decimal(16,4) DEFAULT NULL,
  prd_area varchar(255) DEFAULT NULL,
  remark CLOB,
  PRIMARY KEY (id)
);

-- md_raw_material_group：原料明细分组
CREATE TABLE md_raw_material_group (
  id bigint NOT NULL,
  code varchar(200) DEFAULT NULL,
  parent_id bigint DEFAULT '0',
  enabled int DEFAULT NULL,
  cn_name varchar(200) DEFAULT NULL,
  en_name varchar(200) DEFAULT NULL,
  create_by varchar(200) DEFAULT '',
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT '',
  update_time TIMESTAMP DEFAULT NULL,
  auditor varchar(200) DEFAULT NULL,
  audit_time TIMESTAMP DEFAULT NULL,
  remark CLOB,
  PRIMARY KEY (id)
);

-- ---------------------------------------------------------------------
-- 十、公司色号、打版色号、色系
-- ---------------------------------------------------------------------

-- md_comp_color：公司色号
CREATE TABLE md_comp_color (
  id bigint NOT NULL,
  code varchar(200) DEFAULT NULL,
  color_sys_id bigint DEFAULT NULL,
  cn_name varchar(200) DEFAULT NULL,
  is_ab_yarn int DEFAULT NULL,
  color_name varchar(200) DEFAULT NULL,
  enabled int DEFAULT NULL,
  create_by varchar(200) DEFAULT '',
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT '',
  update_time TIMESTAMP DEFAULT NULL,
  auditor varchar(200) DEFAULT NULL,
  audit_time TIMESTAMP DEFAULT NULL,
  remark CLOB,
  PRIMARY KEY (id)
);

-- md_print_color：打版色号
CREATE TABLE md_print_color (
  id bigint NOT NULL,
  code varchar(255) DEFAULT NULL,
  cn_name varchar(200) DEFAULT NULL,
  enabled int DEFAULT NULL,
  comp_color_id bigint DEFAULT NULL,
  color_sys_id bigint DEFAULT NULL,
  color_name varchar(200) DEFAULT NULL,
  dye_method_id varchar(200) DEFAULT NULL,
  create_by varchar(200) DEFAULT '',
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT '',
  update_time TIMESTAMP DEFAULT NULL,
  auditor varchar(200) DEFAULT NULL,
  audit_time TIMESTAMP DEFAULT NULL,
  remark CLOB,
  PRIMARY KEY (id)
);

-- md_color_series：色系
CREATE TABLE md_color_series (
  id bigint NOT NULL,
  code varchar(200) DEFAULT NULL,
  enabled int DEFAULT NULL,
  cn_name varchar(200) DEFAULT NULL,
  create_by varchar(200) DEFAULT '',
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT '',
  update_time TIMESTAMP DEFAULT NULL,
  auditor varchar(200) DEFAULT NULL,
  audit_time TIMESTAMP DEFAULT NULL,
  remark CLOB,
  PRIMARY KEY (id)
);

-- ---------------------------------------------------------------------
-- 十一、业务员、跟单员
-- ---------------------------------------------------------------------

-- sys_saler：业务员
CREATE TABLE sys_saler (
  id bigint NOT NULL,
  code varchar(200) DEFAULT NULL,
  staff_id bigint DEFAULT NULL,
  dept_id bigint DEFAULT NULL,
  is_cal_biz_fee SMALLINT DEFAULT NULL,
  enabled int DEFAULT NULL,
  create_by varchar(200) DEFAULT '',
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT '',
  update_time TIMESTAMP DEFAULT NULL,
  auditor varchar(200) DEFAULT NULL,
  audit_time TIMESTAMP DEFAULT NULL,
  remark CLOB,
  PRIMARY KEY (id)
);

-- sys_merchandiser：跟单员
CREATE TABLE sys_merchandiser (
  id bigint NOT NULL,
  code varchar(200) DEFAULT NULL,
  staff_id bigint DEFAULT NULL,
  enabled int DEFAULT NULL,
  create_by varchar(200) DEFAULT '',
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT '',
  update_time TIMESTAMP DEFAULT NULL,
  auditor varchar(200) DEFAULT NULL,
  audit_time TIMESTAMP DEFAULT NULL,
  remark CLOB,
  PRIMARY KEY (id)
);

-- ---------------------------------------------------------------------
-- 十二、印章、箱贴打印模板
-- ---------------------------------------------------------------------

-- md_seal：印章
CREATE TABLE md_seal (
  id bigint NOT NULL,
  code varchar(255) DEFAULT NULL,
  stamp_name varchar(100) DEFAULT NULL,
  company_id bigint DEFAULT NULL,
  stamp_admin bigint DEFAULT NULL,
  create_by varchar(255) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(255) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id)
);

-- md_box_label_tpl：箱贴打印模板
CREATE TABLE md_box_label_tpl (
  id bigint NOT NULL,
  code varchar(255) DEFAULT NULL,
  cn_name varchar(255) DEFAULT NULL,
  en_name varchar(255) DEFAULT NULL,
  org_id bigint DEFAULT NULL,
  is_en_print int DEFAULT '0',
  enabled int DEFAULT NULL,
  remark CLOB,
  create_by varchar(255) NOT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(255) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  auditor varchar(255) DEFAULT NULL,
  audit_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id)
);

-- ---------------------------------------------------------------------
-- 十三、特殊纺工费
-- ---------------------------------------------------------------------

-- md_spin_fee：特殊纺工费
CREATE TABLE md_spin_fee (
  id bigint NOT NULL,
  code varchar(200) DEFAULT NULL,
  remark CLOB,
  create_by varchar(200) DEFAULT '',
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT '',
  update_time TIMESTAMP DEFAULT NULL,
  auditor varchar(200) DEFAULT NULL,
  audit_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id)
);

-- md_spin_fee_material：特殊纺工费关联物料
CREATE TABLE md_spin_fee_material (
  id bigint NOT NULL,
  sort_index int DEFAULT NULL,
  spin_fee_id bigint DEFAULT NULL,
  mat_id bigint DEFAULT NULL,
  PRIMARY KEY (id)
);

-- md_spin_fee_raw_material：特殊纺工费关联原料
CREATE TABLE md_spin_fee_raw_material (
  id bigint NOT NULL,
  sort_index int DEFAULT NULL,
  spin_fee_id bigint DEFAULT NULL,
  raw_mat_id bigint DEFAULT NULL,
  s_fee decimal(19,6) DEFAULT NULL,
  PRIMARY KEY (id)
);

-- ---------------------------------------------------------------------
-- 十四、信用管理
-- ---------------------------------------------------------------------

-- md_credit：信用管理
CREATE TABLE md_credit (
  id bigint NOT NULL,
  code varchar(255) DEFAULT NULL,
  org_id bigint DEFAULT NULL,
  is_group_credit int DEFAULT NULL,
  cust_type int DEFAULT NULL,
  remark CLOB,
  create_by varchar(255) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(255) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  auditor varchar(255) DEFAULT NULL,
  audit_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id)
);

-- md_credit_detail：信用管理客户明细
CREATE TABLE md_credit_detail (
  id bigint NOT NULL,
  sort_index int DEFAULT NULL,
  credit_id bigint DEFAULT NULL,
  cust_id bigint DEFAULT NULL,
  curr_id bigint DEFAULT NULL,
  amount decimal(19,6) DEFAULT NULL,
  amount_status varchar(255) DEFAULT NULL,
  valid_time date DEFAULT NULL,
  credit_status varchar(255) DEFAULT NULL,
  overdue_days int DEFAULT NULL,
  remark CLOB,
  PRIMARY KEY (id)
);


-- ============================================================
-- 02-CRM销售表
-- ============================================================

-- =====================================================================
-- 02-CRM与销售业务表
-- 说明：意向合同、销售合同、销售报价、销售订单、发货通知、销售出库、
--       退货通知、销售退货、销售发票。
-- 销售链路：意向合同 → 销售合同 → 销售报价 → 销售订单 → 发货通知 → 销售出库 → 销售发票
--                                                         → 退货通知 → 销售退货
-- 命名约定：表前缀 sal_
-- 公共审计字段：create_by/create_time/update_by/update_time/auditor/audit_time
-- 状态字段：pact_state（0暂存 1已创建 2已提交 3已审核 4已驳回）
--           is_closed / is_cancel / change_state 辅助标记
--           wf_request_id / reject_by / reject_time / reject_reason 工作流驳回回写
-- =====================================================================

-- ---------------------------------------------------------------------
-- 一、意向合同
-- ---------------------------------------------------------------------

-- sal_int_cont：意向合同主表
CREATE TABLE sal_int_cont (
  id bigint NOT NULL,
  code varchar(200) DEFAULT NULL,
  pact_date date DEFAULT NULL,
  pact_state int DEFAULT '0',
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  auditor varchar(200) DEFAULT NULL,
  audit_time TIMESTAMP DEFAULT NULL,
  remark CLOB,
  valid_start date DEFAULT NULL,
  valid_end date DEFAULT NULL,
  valid_prd date DEFAULT NULL,
  sal_org_id bigint DEFAULT NULL,
  cust_id bigint DEFAULT NULL,
  dept_id bigint DEFAULT NULL,
  saler_id bigint DEFAULT NULL,
  curr_id bigint DEFAULT NULL,
  b_curr_rate decimal(16,8) DEFAULT NULL,
  cny_rate decimal(16,8) DEFAULT NULL,
  usd_rate decimal(16,8) DEFAULT NULL,
  trade_type varchar(200) DEFAULT NULL,
  trade_mode varchar(200) DEFAULT NULL,
  brand_id bigint DEFAULT NULL,
  firp_type varchar(200) DEFAULT NULL,
  rec_type varchar(200) DEFAULT NULL,
  total_qty decimal(19,6) DEFAULT NULL,
  total_amount decimal(19,6) DEFAULT NULL,
  cust_po varchar(200) DEFAULT NULL,
  fiar_days int DEFAULT NULL,
  agent varchar(200) DEFAULT NULL,
  int_cont_type varchar(200) DEFAULT NULL,
  is_cm int DEFAULT NULL,
  is_ml int DEFAULT NULL,
  dp_amount decimal(19,6) DEFAULT NULL,
  is_closed int DEFAULT '0',
  closed_by varchar(200) DEFAULT NULL,
  closed_time TIMESTAMP DEFAULT NULL,
  is_cancel int DEFAULT '0',
  cancel_by varchar(200) DEFAULT NULL,
  cancel_time TIMESTAMP DEFAULT NULL,
  signing_place varchar(255) DEFAULT NULL,
  signing_place_en varchar(255) DEFAULT NULL,
  spill_short_rate decimal(19,6) DEFAULT NULL,
  spill_short varchar(255) DEFAULT NULL,
  weight_type varchar(200) DEFAULT NULL,
  quality_standard_id bigint DEFAULT NULL,
  paper_cont varchar(255) DEFAULT NULL,
  su_type varchar(255) DEFAULT NULL,
  paper_cont_desc varchar(255) DEFAULT NULL,
  is_sp_raw_mat int DEFAULT NULL,
  pack_type varchar(100) DEFAULT NULL,
  payment_deadline_desc varchar(500) DEFAULT NULL,
  payment_deadline varchar(200) DEFAULT NULL,
  marking varchar(255) DEFAULT NULL,
  destination varchar(255) DEFAULT NULL,
  insure_per decimal(16,8) DEFAULT NULL,
  pur_co_method varchar(255) DEFAULT NULL,
  payment_method varchar(255) DEFAULT NULL,
  shipment_date varchar(255) DEFAULT NULL,
  delivery_method varchar(255) DEFAULT NULL,
  other_terms varchar(255) DEFAULT NULL,
  pur_co_date date DEFAULT NULL,
  pack_method varchar(255) DEFAULT NULL,
  signing_method varchar(255) DEFAULT NULL,
  payment_method_en varchar(255) DEFAULT NULL,
  tax_rate decimal(19,6) DEFAULT NULL,
  is_dm int DEFAULT '0',
  check_by varchar(255) DEFAULT NULL,
  check_time TIMESTAMP DEFAULT NULL,
  is_check int DEFAULT '0',
  is_paper_cont int DEFAULT '0',
  cancel_reason varchar(3000) DEFAULT NULL,
  yarn_use varchar(255) DEFAULT NULL,
  change_state int DEFAULT '0',
  change_code varchar(255) DEFAULT NULL,
  cc_cosign int DEFAULT '0',
  oa_stamp_id bigint DEFAULT NULL,
  seller_address tinytext,
  seller_fax tinytext,
  seller_email tinytext,
  buyer_tel tinytext,
  buyer_fax tinytext,
  buyer_email tinytext,
  cont_firp_type varchar(64) DEFAULT NULL,
  cont_firp_type_desc varchar(64) DEFAULT NULL,
  cont_trade_mode varchar(64) DEFAULT NULL,
  harbour_start_cn varchar(64) DEFAULT NULL,
  harbour_start_en varchar(64) DEFAULT NULL,
  harbour_end_cn varchar(64) DEFAULT NULL,
  harbour_end_en varchar(64) DEFAULT NULL,
  transport_type_cn varchar(64) DEFAULT NULL,
  transport_type_en varchar(64) DEFAULT NULL,
  cont_trade_mode_others tinytext,
  transport_type_other tinytext,
  insurance CLOB,
  qua_reg CLOB,
  dev_time date DEFAULT NULL,
  sp_req CLOB,
  pay_method_temp_en varchar(255) DEFAULT NULL,
  vp_qty decimal(19,6) DEFAULT NULL,
  wf_request_id bigint DEFAULT NULL,
  reject_by varchar(200) DEFAULT NULL,
  reject_time TIMESTAMP DEFAULT NULL,
  reject_reason varchar(3000) DEFAULT NULL,
  PRIMARY KEY (id)
);

-- sal_int_cont_goods：意向合同明细
CREATE TABLE sal_int_cont_goods (
  id bigint NOT NULL,
  sort_index int DEFAULT NULL,
  int_cont_id bigint DEFAULT NULL,
  hl_card_id bigint DEFAULT NULL,
  mat_id bigint DEFAULT NULL,
  line_num decimal(16,8) DEFAULT NULL,
  yarn_num decimal(16,8) DEFAULT NULL,
  print_color_id bigint DEFAULT NULL,
  comp_color_id bigint DEFAULT NULL,
  color varchar(50) DEFAULT NULL,
  raw_mat_id bigint DEFAULT NULL,
  fineness varchar(200) DEFAULT NULL,
  qty decimal(19,6) DEFAULT NULL,
  unit varchar(200) DEFAULT NULL,
  price decimal(19,6) DEFAULT NULL,
  amount decimal(19,6) DEFAULT NULL,
  remark CLOB,
  yarn_use varchar(200) DEFAULT NULL,
  weight_type varchar(200) DEFAULT NULL,
  pack_type varchar(200) DEFAULT NULL,
  ct_weight decimal(16,8) DEFAULT NULL,
  yarn_type varchar(200) DEFAULT NULL,
  ml_rate decimal(16,8) DEFAULT NULL,
  check_price decimal(19,6) DEFAULT NULL,
  s_fee decimal(19,6) DEFAULT NULL,
  tp_fee decimal(19,6) DEFAULT NULL,
  pa_fee decimal(19,6) DEFAULT NULL,
  pa_rate decimal(19,6) DEFAULT NULL,
  ra_fee decimal(19,6) DEFAULT NULL,
  c_fee decimal(19,6) DEFAULT NULL,
  other_fee decimal(19,6) DEFAULT NULL,
  cost_price decimal(19,6) DEFAULT NULL,
  over_price decimal(19,6) DEFAULT NULL,
  sp_req varchar(200) DEFAULT NULL,
  sp_price decimal(19,6) DEFAULT NULL,
  pack_req varchar(200) DEFAULT NULL,
  cf_req varchar(200) DEFAULT NULL,
  dye_req varchar(255) DEFAULT NULL,
  ps_req varchar(255) DEFAULT NULL,
  cont_qty decimal(19,6) DEFAULT NULL,
  vp_qty decimal(19,6) DEFAULT NULL,
  order_pro_qty decimal(19,6) DEFAULT NULL,
  self_pro_qty decimal(19,6) DEFAULT NULL,
  out_qty decimal(19,6) DEFAULT NULL,
  b_curr_rate decimal(16,8) DEFAULT NULL,
  cny_rate decimal(16,8) DEFAULT NULL,
  sal_rate decimal(16,8) DEFAULT NULL,
  is_closed int DEFAULT '0',
  closed_by varchar(200) DEFAULT NULL,
  closed_time TIMESTAMP DEFAULT NULL,
  is_cancel int DEFAULT '0',
  cancel_by varchar(200) DEFAULT NULL,
  cancel_time TIMESTAMP DEFAULT NULL,
  require_date date DEFAULT NULL,
  tax_rate decimal(16,8) DEFAULT NULL,
  is_dm int DEFAULT '0',
  dm_price decimal(16,8) DEFAULT NULL,
  PRIMARY KEY (id)
);

-- sal_int_cont_goods_assign：意向合同指定用料孙表
CREATE TABLE sal_int_cont_goods_assign (
  id bigint NOT NULL,
  sort_index int DEFAULT NULL,
  int_cont_goods_id bigint DEFAULT NULL,
  pur_apply_detail_id bigint DEFAULT NULL,
  mat_req_type varchar(200) DEFAULT NULL,
  mat_id bigint DEFAULT NULL,
  supplier_id bigint DEFAULT NULL,
  lot_no varchar(200) DEFAULT NULL,
  loss_rate decimal(16,8) DEFAULT NULL,
  ratio decimal(16,8) DEFAULT NULL,
  qty decimal(19,6) DEFAULT NULL,
  price decimal(19,6) DEFAULT NULL,
  remark CLOB,
  PRIMARY KEY (id)
);

-- sal_int_cont_goods_craft：意向合同特殊工艺孙表
CREATE TABLE sal_int_cont_goods_craft (
  id bigint NOT NULL,
  sort_index int DEFAULT NULL,
  int_cont_goods_id bigint DEFAULT NULL,
  sp_req varchar(200) DEFAULT NULL,
  sp_price decimal(19,6) DEFAULT NULL,
  remark CLOB,
  PRIMARY KEY (id)
);

-- ---------------------------------------------------------------------
-- 二、销售合同
-- ---------------------------------------------------------------------

-- sal_cont：销售合同主表
CREATE TABLE sal_cont (
  id bigint NOT NULL,
  code varchar(200) DEFAULT NULL,
  pact_date date DEFAULT NULL,
  pact_state int DEFAULT '0',
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  auditor varchar(200) DEFAULT NULL,
  audit_time TIMESTAMP DEFAULT NULL,
  remark CLOB,
  int_cont_id bigint DEFAULT NULL,
  cont_id bigint DEFAULT NULL,
  valid_start date DEFAULT NULL,
  valid_end date DEFAULT NULL,
  valid_out date DEFAULT NULL,
  valid_prd date DEFAULT NULL,
  sal_org_id bigint DEFAULT NULL,
  cust_id bigint DEFAULT NULL,
  dept_id bigint DEFAULT NULL,
  saler_id bigint DEFAULT NULL,
  curr_id bigint DEFAULT NULL,
  b_curr_rate decimal(16,8) DEFAULT NULL,
  cny_rate decimal(16,8) DEFAULT NULL,
  usd_rate decimal(16,8) DEFAULT NULL,
  trade_type varchar(200) DEFAULT NULL,
  trade_mode varchar(200) DEFAULT NULL,
  brand_id bigint DEFAULT NULL,
  firp_type varchar(200) DEFAULT NULL,
  rec_type varchar(200) DEFAULT NULL,
  total_qty decimal(19,6) DEFAULT NULL,
  total_amount decimal(19,6) DEFAULT NULL,
  cust_po varchar(200) DEFAULT NULL,
  fiar_days int DEFAULT NULL,
  agent varchar(200) DEFAULT NULL,
  int_cont_type varchar(200) DEFAULT NULL,
  cont_type varchar(200) DEFAULT NULL,
  is_cm int DEFAULT NULL,
  is_ml int DEFAULT NULL,
  int_cont_code varchar(30) DEFAULT NULL,
  cont_code varchar(30) DEFAULT NULL,
  dp_amount decimal(19,8) DEFAULT NULL,
  is_closed int DEFAULT '0',
  closed_by varchar(200) DEFAULT NULL,
  closed_time TIMESTAMP DEFAULT NULL,
  is_cancel int DEFAULT '0',
  cancel_by varchar(200) DEFAULT NULL,
  cancel_time TIMESTAMP DEFAULT NULL,
  signing_place varchar(255) DEFAULT NULL,
  signing_place_en varchar(255) DEFAULT NULL,
  spill_short_rate decimal(19,6) DEFAULT NULL,
  spill_short varchar(255) DEFAULT NULL,
  weight_type varchar(255) DEFAULT NULL,
  quality_standard_id bigint DEFAULT NULL,
  pack_req varchar(255) DEFAULT NULL,
  confirm_date date DEFAULT NULL,
  other_condition varchar(255) DEFAULT NULL,
  su_type varchar(255) DEFAULT NULL,
  pack_type varchar(100) DEFAULT NULL,
  payment_deadline_desc varchar(500) DEFAULT NULL,
  payment_deadline varchar(200) DEFAULT NULL,
  pack_method varchar(255) DEFAULT NULL,
  marking varchar(255) DEFAULT NULL,
  destination varchar(255) DEFAULT NULL,
  insure_per decimal(16,8) DEFAULT NULL,
  pur_co_method varchar(255) DEFAULT NULL,
  payment_method varchar(255) DEFAULT NULL,
  shipment_date varchar(255) DEFAULT NULL,
  delivery_method varchar(255) DEFAULT NULL,
  other_terms varchar(255) DEFAULT NULL,
  pur_co_date date DEFAULT NULL,
  signing_method varchar(255) DEFAULT NULL,
  payment_method_en varchar(255) DEFAULT NULL,
  tax_rate decimal(19,6) DEFAULT NULL,
  is_sa int DEFAULT '0',
  is_dm int DEFAULT '0',
  check_by varchar(255) DEFAULT NULL,
  check_time TIMESTAMP DEFAULT NULL,
  is_check int DEFAULT '0',
  is_paper_cont int DEFAULT '0',
  sub_cont_change_type varchar(255) DEFAULT NULL,
  cancel_reason varchar(3000) DEFAULT NULL,
  paper_cont_desc varchar(1000) DEFAULT NULL,
  int_cont_pact_date date DEFAULT NULL,
  yarn_use varchar(16) DEFAULT NULL,
  sp_req CLOB,
  cont_firp_type varchar(64) DEFAULT NULL,
  cont_firp_type_desc varchar(64) DEFAULT NULL,
  cont_trade_mode varchar(64) DEFAULT NULL,
  harbour_start_cn varchar(64) DEFAULT NULL,
  harbour_start_en varchar(64) DEFAULT NULL,
  harbour_end_cn varchar(64) DEFAULT NULL,
  harbour_end_en varchar(64) DEFAULT NULL,
  transport_type_cn varchar(64) DEFAULT NULL,
  transport_type_en varchar(64) DEFAULT NULL,
  cont_trade_mode_others CLOB,
  transport_type_other CLOB,
  insurance CLOB,
  qua_reg CLOB,
  dev_time CLOB,
  xa_tel CLOB,
  xa_fax CLOB,
  xa_mail CLOB,
  cu_tel CLOB,
  cu_fax CLOB,
  cu_mail varchar(100) DEFAULT NULL,
  change_state int DEFAULT '0',
  change_code varchar(255) DEFAULT NULL,
  cc_cosign int DEFAULT '0',
  oa_stamp_id bigint DEFAULT NULL,
  seller_address tinytext,
  seller_fax tinytext,
  seller_email tinytext,
  buyer_tel tinytext,
  buyer_fax tinytext,
  buyer_email tinytext,
  is_print_cust_po int DEFAULT NULL,
  pay_method_temp_en varchar(255) DEFAULT NULL,
  wf_request_id bigint DEFAULT NULL,
  reject_by varchar(200) DEFAULT NULL,
  reject_time TIMESTAMP DEFAULT NULL,
  reject_reason varchar(3000) DEFAULT NULL,
  PRIMARY KEY (id)
);

-- sal_cont_goods：销售合同明细
CREATE TABLE sal_cont_goods (
  id bigint NOT NULL,
  sort_index int DEFAULT NULL,
  cont_id bigint DEFAULT NULL,
  int_cont_goods_id bigint DEFAULT NULL,
  cont_goods_id bigint DEFAULT NULL,
  hl_card_id bigint DEFAULT NULL,
  mat_id bigint DEFAULT NULL,
  line_num decimal(16,8) DEFAULT NULL,
  yarn_num decimal(16,8) DEFAULT NULL,
  print_color_id bigint DEFAULT NULL,
  comp_color_id bigint DEFAULT NULL,
  color varchar(50) DEFAULT NULL,
  raw_mat_id bigint DEFAULT NULL,
  fineness varchar(200) DEFAULT NULL,
  qty decimal(19,6) DEFAULT NULL,
  unit varchar(200) DEFAULT NULL,
  price decimal(19,6) DEFAULT NULL,
  amount decimal(19,6) DEFAULT NULL,
  remark CLOB,
  yarn_use varchar(200) DEFAULT NULL,
  weight_type varchar(200) DEFAULT NULL,
  pack_type varchar(200) DEFAULT NULL,
  ct_weight decimal(16,8) DEFAULT NULL,
  yarn_type varchar(200) DEFAULT NULL,
  ml_rate decimal(16,8) DEFAULT NULL,
  check_price decimal(19,6) DEFAULT NULL,
  s_fee decimal(19,6) DEFAULT NULL,
  tp_fee decimal(19,6) DEFAULT NULL,
  pa_fee decimal(19,6) DEFAULT NULL,
  pa_rate decimal(16,8) DEFAULT NULL,
  ra_fee decimal(19,6) DEFAULT NULL,
  c_fee decimal(19,6) DEFAULT NULL,
  other_fee decimal(19,6) DEFAULT NULL,
  cost_price decimal(19,6) DEFAULT NULL,
  over_price decimal(19,6) DEFAULT NULL,
  sp_req varchar(200) DEFAULT NULL,
  sp_price decimal(16,8) DEFAULT NULL,
  pack_req varchar(200) DEFAULT NULL,
  cf_req varchar(200) DEFAULT NULL,
  dye_req varchar(255) DEFAULT NULL,
  ps_req varchar(255) DEFAULT NULL,
  c_qty decimal(19,6) DEFAULT NULL,
  dp_qty decimal(19,6) DEFAULT NULL,
  order_exclude_qty decimal(19,6) DEFAULT NULL,
  cp_rate decimal(19,6) DEFAULT NULL,
  sum_cp_rate decimal(19,6) DEFAULT NULL,
  out_qty decimal(19,6) DEFAULT NULL,
  notice_qty decimal(19,6) DEFAULT NULL,
  b_curr_rate decimal(16,8) DEFAULT NULL,
  cny_rate decimal(16,8) DEFAULT NULL,
  sal_rate decimal(16,8) DEFAULT NULL,
  is_closed int DEFAULT '0',
  closed_by varchar(200) DEFAULT NULL,
  closed_time TIMESTAMP DEFAULT NULL,
  is_cancel int DEFAULT '0',
  cancel_by varchar(200) DEFAULT NULL,
  cancel_time TIMESTAMP DEFAULT NULL,
  require_date date DEFAULT NULL,
  tax_rate decimal(16,8) DEFAULT NULL,
  order_sal_qty decimal(19,6) DEFAULT NULL,
  order_pro_qty decimal(19,6) DEFAULT NULL,
  is_dm int DEFAULT '0',
  dm_price decimal(16,8) DEFAULT NULL,
  need_co int DEFAULT NULL,
  PRIMARY KEY (id)
);

-- sal_cont_goods_assign：销售合同指定用料孙表
CREATE TABLE sal_cont_goods_assign (
  id bigint NOT NULL,
  sort_index int DEFAULT NULL,
  cont_goods_id bigint DEFAULT NULL,
  pur_apply_detail_id bigint DEFAULT NULL,
  mat_req_type varchar(200) DEFAULT NULL,
  mat_id bigint DEFAULT NULL,
  supplier_id bigint DEFAULT NULL,
  lot_no varchar(200) DEFAULT NULL,
  loss_rate decimal(16,8) DEFAULT NULL,
  ratio decimal(16,8) DEFAULT NULL,
  qty decimal(19,6) DEFAULT NULL,
  price decimal(19,6) DEFAULT NULL,
  remark CLOB,
  PRIMARY KEY (id)
);

-- sal_cont_goods_craft：销售合同特殊工艺孙表
CREATE TABLE sal_cont_goods_craft (
  id bigint NOT NULL,
  sort_index int DEFAULT NULL,
  cont_goods_id bigint DEFAULT NULL,
  sp_req varchar(200) DEFAULT NULL,
  sp_price decimal(19,6) DEFAULT NULL,
  remark CLOB,
  PRIMARY KEY (id)
);

-- ---------------------------------------------------------------------
-- 三、销售报价
-- ---------------------------------------------------------------------

-- sal_quote：销售报价主表
CREATE TABLE sal_quote (
  id bigint NOT NULL,
  code varchar(200) DEFAULT NULL,
  quote_date date DEFAULT NULL,
  pact_state int DEFAULT '0',
  cust_id bigint DEFAULT NULL,
  sal_org_id bigint DEFAULT NULL,
  dept_id bigint DEFAULT NULL,
  saler_id bigint DEFAULT NULL,
  curr_id bigint DEFAULT NULL,
  b_curr_rate decimal(16,8) DEFAULT NULL,
  cny_rate decimal(16,8) DEFAULT NULL,
  usd_rate decimal(16,8) DEFAULT NULL,
  valid_start date DEFAULT NULL,
  valid_end date DEFAULT NULL,
  total_qty decimal(19,6) DEFAULT NULL,
  total_amount decimal(19,6) DEFAULT NULL,
  int_cont_id bigint DEFAULT NULL,
  trade_type varchar(200) DEFAULT NULL,
  trade_mode varchar(200) DEFAULT NULL,
  brand_id bigint DEFAULT NULL,
  firp_type varchar(200) DEFAULT NULL,
  rec_type varchar(200) DEFAULT NULL,
  fiar_days int DEFAULT NULL,
  agent varchar(200) DEFAULT NULL,
  cust_po varchar(200) DEFAULT NULL,
  is_cm int DEFAULT NULL,
  is_ml int DEFAULT NULL,
  dp_amount decimal(19,6) DEFAULT NULL,
  pack_type varchar(100) DEFAULT NULL,
  weight_type varchar(200) DEFAULT NULL,
  su_type varchar(255) DEFAULT NULL,
  dev_time date DEFAULT NULL,
  out_qty decimal(19,6) DEFAULT NULL,
  vp_qty decimal(19,6) DEFAULT NULL,
  is_closed int DEFAULT '0',
  closed_by varchar(200) DEFAULT NULL,
  closed_time TIMESTAMP DEFAULT NULL,
  is_cancel int DEFAULT '0',
  cancel_by varchar(200) DEFAULT NULL,
  cancel_time TIMESTAMP DEFAULT NULL,
  cancel_reason varchar(3000) DEFAULT NULL,
  change_state int DEFAULT '0',
  change_code varchar(255) DEFAULT NULL,
  remark CLOB,
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  auditor varchar(200) DEFAULT NULL,
  audit_time TIMESTAMP DEFAULT NULL,
  wf_request_id bigint DEFAULT NULL,
  reject_by varchar(200) DEFAULT NULL,
  reject_time TIMESTAMP DEFAULT NULL,
  reject_reason varchar(3000) DEFAULT NULL,
  PRIMARY KEY (id)
);

-- sal_quote_goods：销售报价明细
CREATE TABLE sal_quote_goods (
  id bigint NOT NULL,
  sort_index int DEFAULT NULL,
  quote_id bigint DEFAULT NULL,
  mat_id bigint DEFAULT NULL,
  yarn_count decimal(16,8) DEFAULT NULL,
  strand decimal(16,8) DEFAULT NULL,
  color_id bigint DEFAULT NULL,
  qty decimal(19,6) DEFAULT NULL,
  unit varchar(200) DEFAULT NULL,
  price decimal(19,6) DEFAULT NULL,
  amount decimal(19,6) DEFAULT NULL,
  cost_price decimal(19,6) DEFAULT NULL,
  profit_rate decimal(16,8) DEFAULT NULL,
  s_fee decimal(19,6) DEFAULT NULL,
  sp_price decimal(19,6) DEFAULT NULL,
  tax_rate decimal(16,8) DEFAULT NULL,
  int_cont_goods_id bigint DEFAULT NULL,
  remark CLOB,
  hl_card_id bigint DEFAULT NULL,
  line_num decimal(16,8) DEFAULT NULL,
  yarn_num decimal(16,8) DEFAULT NULL,
  print_color_id bigint DEFAULT NULL,
  comp_color_id bigint DEFAULT NULL,
  color varchar(50) DEFAULT NULL,
  raw_mat_id bigint DEFAULT NULL,
  fineness varchar(200) DEFAULT NULL,
  yarn_use varchar(200) DEFAULT NULL,
  weight_type varchar(200) DEFAULT NULL,
  pack_type varchar(200) DEFAULT NULL,
  ct_weight decimal(16,8) DEFAULT NULL,
  yarn_type varchar(200) DEFAULT NULL,
  ml_rate decimal(16,8) DEFAULT NULL,
  check_price decimal(19,6) DEFAULT NULL,
  tp_fee decimal(19,6) DEFAULT NULL,
  pa_fee decimal(19,6) DEFAULT NULL,
  pa_rate decimal(19,6) DEFAULT NULL,
  ra_fee decimal(19,6) DEFAULT NULL,
  c_fee decimal(19,6) DEFAULT NULL,
  other_fee decimal(19,6) DEFAULT NULL,
  over_price decimal(19,6) DEFAULT NULL,
  sp_req varchar(200) DEFAULT NULL,
  pack_req varchar(200) DEFAULT NULL,
  cf_req varchar(200) DEFAULT NULL,
  dye_req varchar(255) DEFAULT NULL,
  ps_req varchar(255) DEFAULT NULL,
  cust_mat_no varchar(200) DEFAULT NULL,
  cust_color_no varchar(200) DEFAULT NULL,
  cust_color_name varchar(200) DEFAULT NULL,
  cust_lot_no varchar(200) DEFAULT NULL,
  b_curr_rate decimal(16,8) DEFAULT NULL,
  cny_rate decimal(16,8) DEFAULT NULL,
  sal_rate decimal(16,8) DEFAULT NULL,
  require_date date DEFAULT NULL,
  cont_goods_id bigint DEFAULT NULL,
  out_qty decimal(19,6) DEFAULT NULL,
  PRIMARY KEY (id)
);

-- ---------------------------------------------------------------------
-- 四、销售订单
-- ---------------------------------------------------------------------

-- sal_order：销售订单主表
CREATE TABLE sal_order (
  id bigint NOT NULL,
  code varchar(200) DEFAULT NULL,
  order_date date DEFAULT NULL,
  pact_state int DEFAULT '0',
  cust_id bigint DEFAULT NULL,
  sal_org_id bigint DEFAULT NULL,
  dept_id bigint DEFAULT NULL,
  saler_id bigint DEFAULT NULL,
  curr_id bigint DEFAULT NULL,
  b_curr_rate decimal(16,8) DEFAULT NULL,
  cny_rate decimal(16,8) DEFAULT NULL,
  usd_rate decimal(16,8) DEFAULT NULL,
  trade_type varchar(200) DEFAULT NULL,
  trade_mode varchar(200) DEFAULT NULL,
  firp_type varchar(200) DEFAULT NULL,
  rec_type varchar(200) DEFAULT NULL,
  fiar_days int DEFAULT NULL,
  dev_time date DEFAULT NULL,
  su_type varchar(255) DEFAULT NULL,
  cust_po varchar(200) DEFAULT NULL,
  total_qty decimal(19,6) DEFAULT NULL,
  total_amount decimal(19,6) DEFAULT NULL,
  out_qty decimal(19,6) DEFAULT NULL,
  vp_qty decimal(19,6) DEFAULT NULL,
  int_cont_id bigint DEFAULT NULL,
  is_closed int DEFAULT '0',
  closed_by varchar(200) DEFAULT NULL,
  closed_time TIMESTAMP DEFAULT NULL,
  is_cancel int DEFAULT '0',
  cancel_by varchar(200) DEFAULT NULL,
  cancel_time TIMESTAMP DEFAULT NULL,
  cancel_reason varchar(3000) DEFAULT NULL,
  change_state int DEFAULT '0',
  change_code varchar(255) DEFAULT NULL,
  remark CLOB,
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  auditor varchar(200) DEFAULT NULL,
  audit_time TIMESTAMP DEFAULT NULL,
  pact_date date DEFAULT NULL,
  close_state varchar(200) DEFAULT NULL,
  closer varchar(200) DEFAULT NULL,
  close_time date DEFAULT NULL,
  prd_org_id bigint DEFAULT NULL,
  brand_id bigint DEFAULT NULL,
  dev_method varchar(200) DEFAULT NULL,
  agent varchar(200) DEFAULT NULL,
  cont_type varchar(200) DEFAULT NULL,
  cont_id varchar(200) DEFAULT NULL,
  cont_code varchar(200) DEFAULT NULL,
  is_cm int DEFAULT '0',
  is_ml int DEFAULT '0',
  is_fast int DEFAULT NULL,
  is_dev_date int DEFAULT '0',
  is_proof int DEFAULT NULL,
  dp_amount decimal(19,6) DEFAULT NULL,
  is_et int DEFAULT NULL,
  auto_generate_prdnotice_status int DEFAULT NULL,
  pack_type varchar(100) DEFAULT NULL,
  weight_type varchar(100) DEFAULT NULL,
  is_tech_review int DEFAULT '0',
  is_plan_review int DEFAULT '0',
  normal_start date DEFAULT NULL,
  normal_end date DEFAULT NULL,
  fast_start date DEFAULT NULL,
  fast_end date DEFAULT NULL,
  print_start date DEFAULT NULL,
  print_end date DEFAULT NULL,
  fastreturn_start date DEFAULT NULL,
  fastreturn_end date DEFAULT NULL,
  confirm_date date DEFAULT NULL,
  confirm_days int DEFAULT NULL,
  plan_reviewer bigint DEFAULT NULL,
  plan_review_time TIMESTAMP DEFAULT NULL,
  fast_delivery_date varchar(500) DEFAULT NULL,
  is_gf int DEFAULT '0',
  is_nd int DEFAULT '0',
  dye_workshop varchar(255) DEFAULT NULL,
  rb_no varchar(255) DEFAULT NULL,
  sb_no varchar(255) DEFAULT NULL,
  fp_req varchar(1000) DEFAULT NULL,
  yarn_use varchar(255) DEFAULT NULL,
  tech_deny varchar(512) DEFAULT NULL,
  plan_deny varchar(512) DEFAULT NULL,
  tech_denyer bigint DEFAULT NULL,
  tech_deny_time TIMESTAMP DEFAULT NULL,
  plan_denyer bigint DEFAULT NULL,
  plan_deny_time TIMESTAMP DEFAULT NULL,
  is_rd int DEFAULT NULL,
  is_diff_prod int DEFAULT NULL,
  wf_request_id bigint DEFAULT NULL,
  reject_by varchar(200) DEFAULT NULL,
  reject_time TIMESTAMP DEFAULT NULL,
  reject_reason varchar(3000) DEFAULT NULL,
  PRIMARY KEY (id)
);

-- sal_order_goods：销售订单明细
CREATE TABLE sal_order_goods (
  id bigint NOT NULL,
  sort_index int DEFAULT NULL,
  order_id bigint DEFAULT NULL,
  mat_id bigint DEFAULT NULL,
  yarn_count decimal(16,8) DEFAULT NULL,
  strand decimal(16,8) DEFAULT NULL,
  color_id bigint DEFAULT NULL,
  batch_no varchar(200) DEFAULT NULL,
  qty decimal(19,6) DEFAULT NULL,
  unit varchar(200) DEFAULT NULL,
  price decimal(19,6) DEFAULT NULL,
  amount decimal(19,6) DEFAULT NULL,
  tax_rate decimal(16,8) DEFAULT NULL,
  su_type varchar(255) DEFAULT NULL,
  require_date date DEFAULT NULL,
  out_qty decimal(19,6) DEFAULT NULL,
  vp_qty decimal(19,6) DEFAULT NULL,
  mfg_order_id bigint DEFAULT NULL,
  int_cont_goods_id bigint DEFAULT NULL,
  is_closed int DEFAULT '0',
  is_cancel int DEFAULT '0',
  remark CLOB,
  cont_goods_id bigint DEFAULT NULL,
  hl_card_id bigint DEFAULT NULL,
  line_num decimal(16,8) DEFAULT NULL,
  yarn_num decimal(16,8) DEFAULT NULL,
  print_color_id bigint DEFAULT NULL,
  comp_color_id bigint DEFAULT NULL,
  color varchar(50) DEFAULT NULL,
  raw_mat_id bigint DEFAULT NULL,
  fineness varchar(200) DEFAULT NULL,
  yarn_use varchar(200) DEFAULT NULL,
  weight_type varchar(200) DEFAULT NULL,
  pack_type varchar(200) DEFAULT NULL,
  ct_weight decimal(16,8) DEFAULT NULL,
  yarn_type varchar(200) DEFAULT NULL,
  single_yarn_twist decimal(12,4) DEFAULT NULL,
  strands_twist decimal(12,4) DEFAULT NULL,
  ml_rate decimal(16,8) DEFAULT NULL,
  check_price decimal(19,6) DEFAULT NULL,
  s_fee decimal(19,6) DEFAULT NULL,
  tp_fee decimal(19,6) DEFAULT NULL,
  pa_fee decimal(19,6) DEFAULT NULL,
  pa_rate decimal(19,6) DEFAULT NULL,
  ra_fee decimal(19,6) DEFAULT NULL,
  c_fee decimal(19,6) DEFAULT NULL,
  other_fee decimal(19,6) DEFAULT NULL,
  cost_price decimal(19,6) DEFAULT NULL,
  over_price decimal(19,6) DEFAULT NULL,
  sp_req varchar(200) DEFAULT NULL,
  sp_price decimal(19,6) DEFAULT NULL,
  pack_req varchar(200) DEFAULT NULL,
  cf_req varchar(200) DEFAULT NULL,
  dye_req varchar(255) DEFAULT NULL,
  ps_req varchar(1000) DEFAULT NULL,
  is_newyarn int DEFAULT '0',
  spin_process varchar(200) DEFAULT NULL,
  sal_rate decimal(16,8) DEFAULT NULL,
  is_fast int DEFAULT NULL,
  is_proof int DEFAULT NULL,
  is_p_Fee int DEFAULT '0',
  p_fee_rate decimal(16,8) DEFAULT NULL,
  dev_date date DEFAULT NULL,
  cust_po varchar(200) DEFAULT NULL,
  exclude_qty decimal(19,6) DEFAULT '0.000000',
  notice_qty decimal(19,6) DEFAULT NULL,
  prd_qty decimal(19,6) DEFAULT NULL,
  oe_rate decimal(16,8) DEFAULT NULL,
  cust_mat_no varchar(200) DEFAULT NULL,
  cust_color_no varchar(200) DEFAULT NULL,
  cust_color_name varchar(200) DEFAULT NULL,
  cust_lot_no varchar(200) DEFAULT NULL,
  b_curr_rate decimal(16,8) DEFAULT NULL,
  cny_rate decimal(16,8) DEFAULT NULL,
  twist varchar(200) DEFAULT NULL,
  hs_qty decimal(19,6) DEFAULT NULL,
  hs_info varchar(100) DEFAULT NULL,
  closed_by varchar(200) DEFAULT NULL,
  closed_time TIMESTAMP DEFAULT NULL,
  cancel_by varchar(200) DEFAULT NULL,
  cancel_time TIMESTAMP DEFAULT NULL,
  is_et int DEFAULT NULL,
  is_hs_confirm int DEFAULT NULL,
  confirm_color varchar(200) DEFAULT NULL,
  is_dd_color int DEFAULT NULL,
  ms_qty decimal(20,6) DEFAULT NULL,
  is_single int DEFAULT NULL,
  is_wax int DEFAULT NULL,
  long_silk_color varchar(255) DEFAULT NULL,
  auto_generate_prdnotice_status int DEFAULT '1',
  yarn_sal_type varchar(255) DEFAULT NULL,
  tech_reviewer bigint DEFAULT NULL,
  tech_review_time TIMESTAMP DEFAULT NULL,
  is_tech_review int DEFAULT '0',
  tech_review_remark CLOB,
  tech_review_info_id bigint DEFAULT NULL,
  tech_review_info varchar(1000) DEFAULT NULL,
  spin_type varchar(255) DEFAULT NULL,
  label_print_req varchar(500) DEFAULT NULL,
  erp_cont_code varchar(500) DEFAULT NULL,
  fast_delivery_date CLOB,
  e_yarn_lot_no varchar(500) DEFAULT NULL,
  rb_no varchar(255) DEFAULT NULL,
  sb_no varchar(255) DEFAULT NULL,
  cont_code varchar(255) DEFAULT NULL,
  ingredient_detail_printout varchar(255) DEFAULT NULL,
  label_ingredients varchar(255) DEFAULT NULL,
  raw_mat_req varchar(500) DEFAULT NULL,
  is_plan_review int DEFAULT '0',
  normal_start date DEFAULT NULL,
  normal_end date DEFAULT NULL,
  fast_start date DEFAULT NULL,
  fast_end date DEFAULT NULL,
  print_start date DEFAULT NULL,
  print_end date DEFAULT NULL,
  fastreturn_start date DEFAULT NULL,
  fastreturn_end date DEFAULT NULL,
  confirm_date date DEFAULT NULL,
  confirm_days int DEFAULT NULL,
  plan_reviewer bigint DEFAULT NULL,
  plan_review_time TIMESTAMP DEFAULT NULL,
  single_yarn_twist_direction varchar(64) DEFAULT NULL,
  strands_twist_direction varchar(64) DEFAULT NULL,
  sample_start date DEFAULT NULL,
  sample_end date DEFAULT NULL,
  sec_tech_reviewer bigint DEFAULT NULL,
  sec_tech_review_time TIMESTAMP DEFAULT NULL,
  pu_price decimal(10,6) DEFAULT NULL,
  worsted_workshop_section varchar(56) DEFAULT NULL,
  hfp_date date DEFAULT NULL,
  other_spin_notes varchar(255) DEFAULT NULL,
  recombing_tech_req varchar(500) DEFAULT NULL,
  dyeing_tech_req varchar(500) DEFAULT NULL,
  is_following_combination bigint DEFAULT NULL,
  is_rd int DEFAULT NULL,
  need_co int DEFAULT NULL,
  PRIMARY KEY (id)
);

-- sal_order_goods_craft：销售订单特殊工艺孙表
CREATE TABLE sal_order_goods_craft (
  id bigint NOT NULL,
  sort_index int DEFAULT NULL,
  order_goods_id bigint DEFAULT NULL,
  sp_req varchar(200) DEFAULT NULL,
  sp_price decimal(19,6) DEFAULT NULL,
  remark CLOB,
  PRIMARY KEY (id)
);

-- sal_order_goods_assign：销售订单指定用料孙表
CREATE TABLE sal_order_goods_assign (
  id bigint NOT NULL,
  sort_index int DEFAULT NULL,
  order_goods_id bigint DEFAULT NULL,
  pur_apply_detail_id bigint DEFAULT NULL,
  mat_req_type varchar(200) DEFAULT NULL,
  mat_id bigint DEFAULT NULL,
  supplier_id bigint DEFAULT NULL,
  lot_no varchar(200) DEFAULT NULL,
  loss_rate decimal(16,8) DEFAULT NULL,
  ratio decimal(16,8) DEFAULT NULL,
  qty decimal(19,6) DEFAULT NULL,
  price decimal(19,6) DEFAULT NULL,
  remark CLOB,
  PRIMARY KEY (id)
);

-- sal_order_goods_pack：销售订单打印标签孙表
CREATE TABLE sal_order_goods_pack (
  id bigint NOT NULL,
  sort_index int DEFAULT NULL,
  order_goods_id bigint DEFAULT NULL,
  print_temp_id bigint DEFAULT NULL,
  color_no varchar(200) DEFAULT NULL,
  color_name varchar(200) DEFAULT NULL,
  cust_lot_no varchar(200) DEFAULT NULL,
  raw_mat_name varchar(200) DEFAULT NULL,
  product_name varchar(200) DEFAULT NULL,
  spec varchar(200) DEFAULT NULL,
  logo varchar(200) DEFAULT NULL,
  is_comp_color int DEFAULT NULL,
  remark CLOB,
  PRIMARY KEY (id)
);

-- ---------------------------------------------------------------------
-- 五、发货通知
-- ---------------------------------------------------------------------

-- sal_delivery_notice：发货通知主表
CREATE TABLE sal_delivery_notice (
  id bigint NOT NULL,
  code varchar(200) DEFAULT NULL,
  notice_date date DEFAULT NULL,
  pact_state int DEFAULT '0',
  cust_id bigint DEFAULT NULL,
  sal_org_id bigint DEFAULT NULL,
  sal_order_id bigint DEFAULT NULL,
  plan_date date DEFAULT NULL,
  delivery_method varchar(200) DEFAULT NULL,
  tracking_no varchar(200) DEFAULT NULL,
  pack_qty int DEFAULT NULL,
  total_qty decimal(19,6) DEFAULT NULL,
  is_closed int DEFAULT '0',
  is_cancel int DEFAULT '0',
  remark CLOB,
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  auditor varchar(200) DEFAULT NULL,
  audit_time TIMESTAMP DEFAULT NULL,
  pact_date date DEFAULT NULL,
  close_state varchar(200) DEFAULT NULL,
  closer varchar(200) DEFAULT NULL,
  close_time date DEFAULT NULL,
  dept_id bigint DEFAULT NULL,
  saler_id bigint DEFAULT NULL,
  curr_id bigint DEFAULT NULL,
  b_curr_rate decimal(16,8) DEFAULT NULL,
  cny_rate decimal(16,8) DEFAULT NULL,
  usd_rate decimal(16,8) DEFAULT NULL,
  trade_type varchar(200) DEFAULT NULL,
  trade_mode varchar(200) DEFAULT NULL,
  brand_id bigint DEFAULT NULL,
  firp_type varchar(200) DEFAULT NULL,
  rec_type varchar(200) DEFAULT NULL,
  dev_method varchar(200) DEFAULT NULL,
  fiar_days int DEFAULT NULL,
  agent varchar(200) DEFAULT NULL,
  inv_type varchar(200) DEFAULT NULL,
  trans_mode varchar(200) DEFAULT NULL,
  log_comp varchar(200) DEFAULT NULL,
  trans_no varchar(200) DEFAULT NULL,
  dev_addr varchar(200) DEFAULT NULL,
  dev_area varchar(200) DEFAULT NULL,
  credit_state varchar(200) DEFAULT NULL,
  credit_info varchar(255) DEFAULT NULL,
  order_code varchar(500) DEFAULT NULL,
  prd_org_id bigint DEFAULT NULL,
  closed_by varchar(200) DEFAULT NULL,
  closed_time TIMESTAMP DEFAULT NULL,
  cancel_by varchar(200) DEFAULT NULL,
  cancel_time TIMESTAMP DEFAULT NULL,
  cancel_reason varchar(3000) DEFAULT NULL,
  is_sa int DEFAULT NULL,
  total_amount decimal(19,6) DEFAULT NULL,
  is_outbound_price_print int DEFAULT NULL,
  credit_balance decimal(19,6) DEFAULT NULL,
  credit_limit decimal(19,8) DEFAULT NULL,
  is_out_stock int DEFAULT '0',
  yarn_use varchar(255) DEFAULT NULL,
  owed_amount decimal(18,8) DEFAULT NULL,
  days_overdue int DEFAULT NULL,
  debt_period_desc varchar(100) DEFAULT NULL,
  credit_desc varchar(100) DEFAULT NULL,
  wf_request_id bigint DEFAULT NULL,
  reject_by varchar(200) DEFAULT NULL,
  reject_time TIMESTAMP DEFAULT NULL,
  reject_reason varchar(3000) DEFAULT NULL,
  PRIMARY KEY (id)
);

-- sal_delivery_notice_goods：发货通知明细
CREATE TABLE sal_delivery_notice_goods (
  id bigint NOT NULL,
  sort_index int DEFAULT NULL,
  notice_id bigint DEFAULT NULL,
  mat_id bigint DEFAULT NULL,
  batch_no varchar(200) DEFAULT NULL,
  qty decimal(19,6) DEFAULT NULL,
  unit varchar(200) DEFAULT NULL,
  pack_spec varchar(200) DEFAULT NULL,
  sal_order_goods_id bigint DEFAULT NULL,
  remark CLOB,
  hl_card_id bigint DEFAULT NULL,
  line_num decimal(16,8) DEFAULT NULL,
  yarn_num decimal(16,8) DEFAULT NULL,
  print_color_id bigint DEFAULT NULL,
  comp_color_id bigint DEFAULT NULL,
  color varchar(50) DEFAULT NULL,
  raw_mat_id bigint DEFAULT NULL,
  fineness varchar(200) DEFAULT NULL,
  inv_id bigint DEFAULT NULL,
  lot_no varchar(300) DEFAULT NULL,
  dye_code varchar(200) DEFAULT NULL,
  price decimal(19,6) DEFAULT NULL,
  amount decimal(19,6) DEFAULT NULL,
  stock_id varchar(36) DEFAULT NULL,
  stock_name varchar(200) DEFAULT NULL,
  yarn_use varchar(200) DEFAULT NULL,
  weight_type varchar(200) DEFAULT NULL,
  pack_type varchar(200) DEFAULT NULL,
  yarn_type varchar(200) DEFAULT NULL,
  ml_rate decimal(16,8) DEFAULT NULL,
  check_price decimal(19,6) DEFAULT NULL,
  s_fee decimal(19,6) DEFAULT NULL,
  tp_fee decimal(19,6) DEFAULT NULL,
  pa_fee decimal(19,6) DEFAULT NULL,
  pa_rate decimal(19,6) DEFAULT NULL,
  ra_fee decimal(19,6) DEFAULT NULL,
  c_fee decimal(19,6) DEFAULT NULL,
  bus_fee decimal(19,6) DEFAULT NULL,
  sea_fee decimal(19,6) DEFAULT NULL,
  exp_fee decimal(19,6) DEFAULT NULL,
  air_fee decimal(19,6) DEFAULT NULL,
  other_fee decimal(19,6) DEFAULT NULL,
  cost_price decimal(19,6) DEFAULT NULL,
  add_cost_price decimal(19,6) DEFAULT NULL,
  total_cost_price decimal(19,6) DEFAULT NULL,
  over_price decimal(19,6) DEFAULT NULL,
  sp_req varchar(200) DEFAULT NULL,
  sp_price decimal(19,6) DEFAULT NULL,
  is_free int DEFAULT '0',
  cust_po varchar(255) DEFAULT NULL,
  lockstock_goods_id bigint DEFAULT NULL,
  out_qty decimal(19,6) DEFAULT NULL,
  b_curr_rate decimal(16,8) DEFAULT NULL,
  cny_rate decimal(16,8) DEFAULT NULL,
  dev_type varchar(255) DEFAULT NULL,
  amount_diff decimal(19,6) DEFAULT NULL,
  cust_mat_no varchar(255) DEFAULT NULL,
  cust_color_no varchar(255) DEFAULT NULL,
  cust_color_name varchar(200) DEFAULT NULL,
  cust_lot_no varchar(255) DEFAULT NULL,
  is_cb int DEFAULT '0',
  lockstock_goods_code varchar(255) DEFAULT NULL,
  stock_loc varchar(255) DEFAULT NULL,
  twist varchar(255) DEFAULT NULL,
  is_closed int DEFAULT '0',
  closed_by varchar(200) DEFAULT NULL,
  closed_time TIMESTAMP DEFAULT NULL,
  is_cancel int DEFAULT '0',
  cancel_by varchar(200) DEFAULT NULL,
  cancel_time TIMESTAMP DEFAULT NULL,
  order_price decimal(19,6) DEFAULT NULL,
  v_qty decimal(19,6) DEFAULT NULL,
  tax_rate decimal(16,8) DEFAULT NULL,
  stock_loc_name varchar(255) DEFAULT NULL,
  order_qty decimal(16,8) DEFAULT NULL,
  cont_code varchar(255) DEFAULT NULL,
  lockstock_id bigint DEFAULT NULL,
  po_saler varchar(255) DEFAULT NULL,
  po_cust varchar(255) DEFAULT NULL,
  raw_mat_cn_print varchar(255) DEFAULT NULL,
  raw_mat_en_print varchar(255) DEFAULT NULL,
  cont_other_fee decimal(19,6) DEFAULT NULL,
  c_dye_fee decimal(19,6) DEFAULT NULL,
  bulk_type_code varchar(100) DEFAULT NULL,
  PRIMARY KEY (id)
);

-- ---------------------------------------------------------------------
-- 六、销售出库（立应收 + 结转成本）
-- ---------------------------------------------------------------------

-- sal_out_stock：销售出库主表
CREATE TABLE sal_out_stock (
  id bigint NOT NULL,
  code varchar(200) DEFAULT NULL,
  out_date date DEFAULT NULL,
  pact_state int DEFAULT '0',
  cust_id bigint DEFAULT NULL,
  sal_org_id bigint DEFAULT NULL,
  warehouse_id bigint DEFAULT NULL,
  out_type varchar(50) DEFAULT NULL,
  curr_id bigint DEFAULT NULL,
  b_curr_rate decimal(16,8) DEFAULT NULL,
  cny_rate decimal(16,8) DEFAULT NULL,
  usd_rate decimal(16,8) DEFAULT NULL,
  sal_order_id bigint DEFAULT NULL,
  delivery_notice_id bigint DEFAULT NULL,
  total_qty decimal(19,6) DEFAULT NULL,
  total_amount decimal(19,6) DEFAULT NULL,
  no_tax_amount decimal(19,6) DEFAULT NULL,
  tax_amount decimal(19,6) DEFAULT NULL,
  cost_amount decimal(19,6) DEFAULT NULL,
  ar_id bigint DEFAULT NULL,
  voucher_id bigint DEFAULT NULL,
  is_closed int DEFAULT '0',
  is_cancel int DEFAULT '0',
  remark CLOB,
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  auditor varchar(200) DEFAULT NULL,
  audit_time TIMESTAMP DEFAULT NULL,
  pact_date date DEFAULT NULL,
  prd_org_id bigint DEFAULT NULL,
  end_cust_id bigint DEFAULT NULL,
  dept_id bigint DEFAULT NULL,
  saler_id bigint DEFAULT NULL,
  trade_type varchar(200) DEFAULT NULL,
  trade_mode varchar(200) DEFAULT NULL,
  brand_id bigint DEFAULT NULL,
  firp_type varchar(200) DEFAULT NULL,
  rec_type varchar(200) DEFAULT NULL,
  dev_method varchar(200) DEFAULT NULL,
  fiar_days int DEFAULT NULL,
  agent varchar(200) DEFAULT NULL,
  ware_name varchar(200) DEFAULT NULL,
  ware_code varchar(100) DEFAULT NULL,
  inv_type varchar(200) DEFAULT NULL,
  trans_mode varchar(200) DEFAULT NULL,
  trans_no varchar(200) DEFAULT NULL,
  notice_no varchar(200) DEFAULT NULL,
  inv_no varchar(200) DEFAULT NULL,
  dev_dept_id bigint DEFAULT NULL,
  notice_id bigint DEFAULT NULL,
  closed_by varchar(200) DEFAULT NULL,
  closed_time TIMESTAMP DEFAULT NULL,
  cancel_by varchar(200) DEFAULT NULL,
  cancel_time TIMESTAMP DEFAULT NULL,
  cancel_reason varchar(500) DEFAULT NULL,
  sync_status varchar(255) DEFAULT NULL,
  is_init int DEFAULT '0',
  is_hy_delivered int DEFAULT NULL,
  orig_total decimal(19,6) DEFAULT NULL,
  wf_request_id bigint DEFAULT NULL,
  reject_by varchar(200) DEFAULT NULL,
  reject_time TIMESTAMP DEFAULT NULL,
  reject_reason varchar(3000) DEFAULT NULL,
  PRIMARY KEY (id)
);

-- sal_out_stock_goods：销售出库明细
CREATE TABLE sal_out_stock_goods (
  id bigint NOT NULL,
  sort_index int DEFAULT NULL,
  out_stock_id bigint DEFAULT NULL,
  mat_id bigint DEFAULT NULL,
  batch_no varchar(200) DEFAULT NULL,
  qty decimal(19,6) DEFAULT NULL,
  unit varchar(200) DEFAULT NULL,
  price decimal(19,6) DEFAULT NULL,
  amount decimal(19,6) DEFAULT NULL,
  no_tax_amount decimal(19,6) DEFAULT NULL,
  tax_rate decimal(16,8) DEFAULT NULL,
  tax_amount decimal(19,6) DEFAULT NULL,
  cost_price decimal(19,6) DEFAULT NULL,
  cost_amount decimal(19,6) DEFAULT NULL,
  position_id bigint DEFAULT NULL,
  sal_order_goods_id bigint DEFAULT NULL,
  remark CLOB,
  notice_goods_id bigint DEFAULT NULL,
  hl_card_id bigint DEFAULT NULL,
  line_num decimal(16,8) DEFAULT NULL,
  yarn_num decimal(16,8) DEFAULT NULL,
  print_color_id bigint DEFAULT NULL,
  comp_color_id bigint DEFAULT NULL,
  color varchar(50) DEFAULT NULL,
  raw_mat_id bigint DEFAULT NULL,
  fineness varchar(200) DEFAULT NULL,
  inv_id bigint DEFAULT NULL,
  lot_no varchar(200) DEFAULT NULL,
  dye_code varchar(200) DEFAULT NULL,
  rec_qty decimal(19,6) DEFAULT NULL,
  act_qty decimal(19,6) DEFAULT NULL,
  is_free int DEFAULT '0',
  stock_name varchar(200) DEFAULT NULL,
  stock_loc varchar(200) DEFAULT NULL,
  check_price decimal(19,6) DEFAULT NULL,
  s_fee decimal(19,6) DEFAULT NULL,
  tp_fee decimal(19,6) DEFAULT NULL,
  pa_fee decimal(19,6) DEFAULT NULL,
  pa_rate decimal(19,6) DEFAULT NULL,
  ra_fee decimal(19,6) DEFAULT NULL,
  c_fee decimal(19,6) DEFAULT NULL,
  other_fee decimal(19,6) DEFAULT NULL,
  add_cost_price decimal(19,6) DEFAULT NULL,
  total_cost_price decimal(19,6) DEFAULT NULL,
  over_price decimal(19,6) DEFAULT NULL,
  sp_price decimal(19,6) DEFAULT NULL,
  weight_type varchar(200) DEFAULT NULL,
  yarn_use varchar(200) DEFAULT NULL,
  pack_type varchar(200) DEFAULT NULL,
  yarn_type varchar(200) DEFAULT NULL,
  lockstock_goods_id bigint DEFAULT NULL,
  re_out_qty decimal(19,6) DEFAULT NULL,
  rate decimal(16,8) DEFAULT NULL,
  ar_qty decimal(19,6) DEFAULT NULL,
  wait_ar_qty decimal(19,6) DEFAULT NULL,
  dye_type varchar(200) DEFAULT NULL,
  amount_diff decimal(19,6) DEFAULT NULL,
  dev_type varchar(255) DEFAULT NULL,
  b_curr_rate decimal(16,8) DEFAULT NULL,
  cny_rate decimal(16,8) DEFAULT NULL,
  stock_id varchar(100) DEFAULT NULL,
  is_closed int DEFAULT '0',
  closed_by varchar(200) DEFAULT NULL,
  closed_time TIMESTAMP DEFAULT NULL,
  is_cancel int DEFAULT '0',
  cancel_by varchar(200) DEFAULT NULL,
  cancel_time TIMESTAMP DEFAULT NULL,
  cust_color_no varchar(200) DEFAULT NULL,
  foreign_trade_fee decimal(16,8) DEFAULT NULL,
  box_qty decimal(16,8) DEFAULT NULL,
  pieces_qty decimal(16,8) DEFAULT NULL,
  cust_po varchar(200) DEFAULT NULL,
  cont_code varchar(255) DEFAULT NULL,
  total_cost_amount decimal(16,8) DEFAULT NULL,
  po_saler varchar(255) DEFAULT NULL,
  po_cust varchar(255) DEFAULT NULL,
  discount_amount decimal(18,8) DEFAULT NULL,
  total_amount_incl_tax_origin decimal(24,6) DEFAULT NULL,
  total_amount_incl_tax_local decimal(24,6) DEFAULT NULL,
  tax_exclusive_amount_original decimal(24,6) DEFAULT NULL,
  tax_exclusive_amount_local decimal(24,6) DEFAULT NULL,
  tax_amount_original decimal(24,6) DEFAULT NULL,
  tax_amount_local decimal(24,6) DEFAULT NULL,
  price_difference_local decimal(24,6) DEFAULT NULL,
  bulk_type_code varchar(100) DEFAULT NULL,
  net_weight decimal(19,6) DEFAULT NULL,
  gross_weight decimal(19,6) DEFAULT NULL,
  PRIMARY KEY (id)
);

-- ---------------------------------------------------------------------
-- 七、退货通知单
-- ---------------------------------------------------------------------

-- sal_ret_notice：退货通知主表
CREATE TABLE sal_ret_notice (
  id bigint NOT NULL,
  code varchar(200) DEFAULT NULL,
  pact_date date DEFAULT NULL,
  pact_state int DEFAULT '0',
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  auditor varchar(200) DEFAULT NULL,
  audit_time TIMESTAMP DEFAULT NULL,
  remark CLOB,
  close_state varchar(200) DEFAULT NULL,
  closer varchar(200) DEFAULT NULL,
  close_time date DEFAULT NULL,
  sal_org_id varchar(200) DEFAULT NULL,
  prd_org_id bigint DEFAULT NULL,
  cust_id bigint DEFAULT NULL,
  dept_id bigint DEFAULT NULL,
  saler_id bigint DEFAULT NULL,
  curr_id bigint DEFAULT NULL,
  b_curr_rate decimal(16,8) DEFAULT NULL,
  cny_rate decimal(16,8) DEFAULT NULL,
  usd_rate decimal(16,8) DEFAULT NULL,
  brand_id bigint DEFAULT NULL,
  agent varchar(200) DEFAULT NULL,
  inv_type varchar(200) DEFAULT NULL,
  dev_addr varchar(200) DEFAULT NULL,
  re_reason varchar(200) DEFAULT NULL,
  outstock_id bigint DEFAULT NULL,
  total_qty decimal(19,6) DEFAULT NULL,
  total_amount decimal(19,6) DEFAULT NULL,
  closed_by varchar(255) DEFAULT NULL,
  closed_time TIMESTAMP DEFAULT NULL,
  is_cancel int DEFAULT '0',
  cancel_by varchar(255) DEFAULT NULL,
  cancel_time TIMESTAMP DEFAULT NULL,
  is_closed int DEFAULT '0',
  is_hy_delivered int DEFAULT '0',
  cancel_reason varchar(3000) DEFAULT NULL,
  wf_request_id bigint DEFAULT NULL,
  reject_by varchar(200) DEFAULT NULL,
  reject_time TIMESTAMP DEFAULT NULL,
  reject_reason varchar(3000) DEFAULT NULL,
  PRIMARY KEY (id)
);

-- sal_ret_notice_goods：退货通知明细
CREATE TABLE sal_ret_notice_goods (
  id bigint NOT NULL,
  sort_index int DEFAULT NULL,
  ret_notice_id bigint DEFAULT NULL,
  outstock_goods_id bigint DEFAULT NULL,
  hl_card_id bigint DEFAULT NULL,
  mat_id bigint DEFAULT NULL,
  line_num decimal(16,8) DEFAULT NULL,
  yarn_num decimal(16,8) DEFAULT NULL,
  print_color_id bigint DEFAULT NULL,
  comp_color_id bigint DEFAULT NULL,
  color varchar(50) DEFAULT NULL,
  raw_mat_id bigint DEFAULT NULL,
  fineness varchar(200) DEFAULT NULL,
  inv_id bigint DEFAULT NULL,
  lot_no varchar(200) DEFAULT NULL,
  dye_code varchar(200) DEFAULT NULL,
  qty decimal(19,6) DEFAULT NULL,
  unit varchar(200) DEFAULT NULL,
  price decimal(19,6) DEFAULT NULL,
  amount decimal(19,6) DEFAULT NULL,
  is_free int DEFAULT NULL,
  remark CLOB,
  check_price decimal(19,6) DEFAULT NULL,
  s_fee decimal(19,6) DEFAULT NULL,
  tp_fee decimal(19,6) DEFAULT NULL,
  pa_fee decimal(19,6) DEFAULT NULL,
  pa_rate decimal(19,6) DEFAULT NULL,
  ra_fee decimal(19,6) DEFAULT NULL,
  c_fee decimal(19,6) DEFAULT NULL,
  other_fee decimal(19,6) DEFAULT NULL,
  cost_price decimal(19,6) DEFAULT NULL,
  add_cost_price decimal(19,6) DEFAULT NULL,
  total_cost_price decimal(19,6) DEFAULT NULL,
  over_price decimal(19,6) DEFAULT NULL,
  pack_type varchar(200) DEFAULT NULL,
  weight_type varchar(200) DEFAULT NULL,
  yarn_use varchar(200) DEFAULT NULL,
  spin_process varchar(200) DEFAULT NULL,
  sp_price decimal(19,6) DEFAULT NULL,
  re_out_qty decimal(19,6) DEFAULT NULL,
  order_goods_id bigint DEFAULT NULL,
  amount_diff decimal(19,6) DEFAULT NULL,
  dev_type varchar(255) DEFAULT NULL,
  b_curr_rate decimal(16,8) DEFAULT NULL,
  cny_rate decimal(16,8) DEFAULT NULL,
  return_type varchar(50) DEFAULT NULL,
  return_date date DEFAULT NULL,
  cc_restock_id bigint DEFAULT NULL,
  is_closed int DEFAULT NULL,
  closed_by varchar(200) DEFAULT NULL,
  closed_time TIMESTAMP DEFAULT NULL,
  is_cancel int DEFAULT NULL,
  cancel_by varchar(200) DEFAULT NULL,
  cancel_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id)
);

-- ---------------------------------------------------------------------
-- 八、销售退货
-- ---------------------------------------------------------------------

-- sal_return：销售退货主表
CREATE TABLE sal_return (
  id bigint NOT NULL,
  code varchar(200) DEFAULT NULL,
  return_date date DEFAULT NULL,
  pact_state int DEFAULT '0',
  cust_id bigint DEFAULT NULL,
  sal_org_id bigint DEFAULT NULL,
  warehouse_id bigint DEFAULT NULL,
  out_stock_id bigint DEFAULT NULL,
  return_reason varchar(2000) DEFAULT NULL,
  total_qty decimal(19,6) DEFAULT NULL,
  total_amount decimal(19,6) DEFAULT NULL,
  cost_amount decimal(19,6) DEFAULT NULL,
  is_closed int DEFAULT '0',
  is_cancel int DEFAULT '0',
  remark CLOB,
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  auditor varchar(200) DEFAULT NULL,
  audit_time TIMESTAMP DEFAULT NULL,
  pact_date date DEFAULT NULL,
  end_cust_id bigint DEFAULT NULL,
  dept_id bigint DEFAULT NULL,
  saler_id bigint DEFAULT NULL,
  curr_id bigint DEFAULT NULL,
  b_curr_rate decimal(16,8) DEFAULT NULL,
  cny_rate decimal(16,8) DEFAULT NULL,
  usd_rate decimal(16,8) DEFAULT NULL,
  brand_id bigint DEFAULT NULL,
  agent varchar(200) DEFAULT NULL,
  inv_type varchar(200) DEFAULT NULL,
  re_reason varchar(200) DEFAULT NULL,
  ware_name varchar(200) DEFAULT NULL,
  prd_org_id bigint DEFAULT NULL,
  trade_mode varchar(200) DEFAULT NULL,
  trade_type varchar(200) DEFAULT NULL,
  ret_notice_id bigint DEFAULT NULL,
  closed_by varchar(200) DEFAULT NULL,
  closed_time TIMESTAMP DEFAULT NULL,
  cancel_by varchar(200) DEFAULT NULL,
  cancel_time TIMESTAMP DEFAULT NULL,
  is_init int DEFAULT NULL,
  cancel_reason varchar(500) DEFAULT NULL,
  wf_request_id bigint DEFAULT NULL,
  reject_by varchar(200) DEFAULT NULL,
  reject_time TIMESTAMP DEFAULT NULL,
  reject_reason varchar(3000) DEFAULT NULL,
  PRIMARY KEY (id)
);

-- sal_return_goods：销售退货明细
CREATE TABLE sal_return_goods (
  id bigint NOT NULL,
  sort_index int DEFAULT NULL,
  return_id bigint DEFAULT NULL,
  mat_id bigint DEFAULT NULL,
  batch_no varchar(200) DEFAULT NULL,
  qty decimal(19,6) DEFAULT NULL,
  unit varchar(200) DEFAULT NULL,
  price decimal(19,6) DEFAULT NULL,
  amount decimal(19,6) DEFAULT NULL,
  cost_price decimal(19,6) DEFAULT NULL,
  cost_amount decimal(19,6) DEFAULT NULL,
  out_stock_goods_id bigint DEFAULT NULL,
  remark CLOB,
  ret_notice_goods_id bigint DEFAULT NULL,
  hl_card_id bigint DEFAULT NULL,
  line_num decimal(16,8) DEFAULT NULL,
  yarn_num decimal(16,8) DEFAULT NULL,
  print_color_id bigint DEFAULT NULL,
  comp_color_id bigint DEFAULT NULL,
  color varchar(50) DEFAULT NULL,
  raw_mat_id bigint DEFAULT NULL,
  fineness varchar(200) DEFAULT NULL,
  inv_id bigint DEFAULT NULL,
  lot_no varchar(200) DEFAULT NULL,
  dye_code varchar(200) DEFAULT NULL,
  act_qty decimal(19,6) DEFAULT NULL,
  stock_name varchar(200) DEFAULT NULL,
  stock_loc varchar(200) DEFAULT NULL,
  is_free int DEFAULT '0',
  check_price decimal(19,6) DEFAULT NULL,
  s_fee decimal(19,6) DEFAULT NULL,
  tp_fee decimal(19,6) DEFAULT NULL,
  pa_fee decimal(19,6) DEFAULT NULL,
  pa_rate decimal(19,6) DEFAULT NULL,
  ra_fee decimal(19,6) DEFAULT NULL,
  c_fee decimal(19,6) DEFAULT NULL,
  other_fee decimal(19,6) DEFAULT NULL,
  add_cost_price decimal(19,6) DEFAULT NULL,
  total_cost_price decimal(19,6) DEFAULT NULL,
  over_price decimal(19,6) DEFAULT NULL,
  sp_price decimal(19,6) DEFAULT NULL,
  pack_type varchar(200) DEFAULT NULL,
  weight_type varchar(200) DEFAULT NULL,
  yarn_use varchar(200) DEFAULT NULL,
  spin_process varchar(200) DEFAULT NULL,
  re_type varchar(200) DEFAULT NULL,
  order_goods_id bigint DEFAULT NULL,
  ar_qty decimal(19,6) DEFAULT NULL,
  wait_ar_qty decimal(19,6) DEFAULT NULL,
  re_qty varchar(100) DEFAULT NULL,
  amount_diff decimal(19,6) DEFAULT NULL,
  dev_type varchar(255) DEFAULT NULL,
  pact_rate decimal(19,6) DEFAULT NULL,
  b_curr_rate decimal(16,8) DEFAULT NULL,
  cny_rate decimal(16,8) DEFAULT NULL,
  cc_id bigint DEFAULT NULL,
  is_closed int DEFAULT '0',
  closed_by varchar(200) DEFAULT NULL,
  closed_time TIMESTAMP DEFAULT NULL,
  is_cancel int DEFAULT '0',
  cancel_by varchar(200) DEFAULT NULL,
  cancel_time TIMESTAMP DEFAULT NULL,
  rate decimal(16,8) DEFAULT NULL,
  foreign_trade_fee decimal(16,8) DEFAULT NULL,
  total_amount_incl_tax_origin decimal(24,6) DEFAULT NULL,
  total_amount_incl_tax_local decimal(24,6) DEFAULT NULL,
  tax_exclusive_amount_original decimal(24,6) DEFAULT NULL,
  tax_exclusive_amount_local decimal(24,6) DEFAULT NULL,
  tax_amount_original decimal(24,6) DEFAULT NULL,
  tax_amount_local decimal(24,6) DEFAULT NULL,
  price_difference_local decimal(24,6) DEFAULT NULL,
  po_saler varchar(255) DEFAULT NULL,
  po_cust varchar(255) DEFAULT NULL,
  brand_id bigint DEFAULT NULL,
  PRIMARY KEY (id)
);

-- ---------------------------------------------------------------------
-- 九、销售发票（销项）
-- ---------------------------------------------------------------------

-- sal_invoice：销售发票主表
CREATE TABLE sal_invoice (
  id bigint NOT NULL,
  code varchar(200) DEFAULT NULL,
  invoice_code varchar(100) DEFAULT NULL,
  invoice_no varchar(100) DEFAULT NULL,
  invoice_date date DEFAULT NULL,
  pact_state int DEFAULT '0',
  cust_id bigint DEFAULT NULL,
  sal_org_id bigint DEFAULT NULL,
  invoice_type varchar(50) DEFAULT NULL,
  no_tax_amount decimal(19,6) DEFAULT NULL,
  tax_amount decimal(19,6) DEFAULT NULL,
  total_amount decimal(19,6) DEFAULT NULL,
  issue_status varchar(50) DEFAULT NULL,
  red_invoice_id bigint DEFAULT NULL,
  is_closed int DEFAULT '0',
  is_cancel int DEFAULT '0',
  remark CLOB,
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  auditor varchar(200) DEFAULT NULL,
  audit_time TIMESTAMP DEFAULT NULL,
  pact_date date DEFAULT NULL,
  sync_time TIMESTAMP DEFAULT NULL,
  org_id bigint DEFAULT NULL,
  end_cust_id bigint DEFAULT NULL,
  dept_id bigint DEFAULT NULL,
  saler_id bigint DEFAULT NULL,
  inv_no varchar(200) DEFAULT NULL,
  inv_type_id varchar(200) DEFAULT NULL,
  curr_id bigint DEFAULT NULL,
  b_curr_rate decimal(16,6) DEFAULT NULL,
  cny_rate decimal(16,6) DEFAULT NULL,
  usd_rate decimal(16,6) DEFAULT NULL,
  amount decimal(19,6) DEFAULT NULL,
  erp_code varchar(200) DEFAULT NULL,
  f_red_blue int DEFAULT NULL,
  cancel_reason varchar(3000) DEFAULT NULL,
  closed_by varchar(200) DEFAULT NULL,
  closed_time TIMESTAMP DEFAULT NULL,
  cancel_by varchar(200) DEFAULT NULL,
  cancel_time TIMESTAMP DEFAULT NULL,
  wf_request_id bigint DEFAULT NULL,
  reject_by varchar(200) DEFAULT NULL,
  reject_time TIMESTAMP DEFAULT NULL,
  reject_reason varchar(3000) DEFAULT NULL,
  PRIMARY KEY (id)
);

-- sal_invoice_goods：销售发票明细
CREATE TABLE sal_invoice_goods (
  id bigint NOT NULL,
  sort_index int DEFAULT NULL,
  invoice_id bigint DEFAULT NULL,
  mat_id bigint DEFAULT NULL,
  qty decimal(19,6) DEFAULT NULL,
  unit varchar(200) DEFAULT NULL,
  price decimal(19,6) DEFAULT NULL,
  no_tax_amount decimal(19,6) DEFAULT NULL,
  tax_rate decimal(16,8) DEFAULT NULL,
  tax_amount decimal(19,6) DEFAULT NULL,
  total_amount decimal(19,6) DEFAULT NULL,
  out_stock_goods_id bigint DEFAULT NULL,
  sal_order_goods_id bigint DEFAULT NULL,
  ar_goods_id bigint DEFAULT NULL,
  line_num decimal(16,8) DEFAULT NULL,
  yarn_num decimal(16,8) DEFAULT NULL,
  print_color_id bigint DEFAULT NULL,
  comp_color_id bigint DEFAULT NULL,
  color varchar(200) DEFAULT NULL,
  raw_mat_id bigint DEFAULT NULL,
  fineness varchar(200) DEFAULT NULL,
  lot_no varchar(200) DEFAULT NULL,
  dye_code varchar(200) DEFAULT NULL,
  inv_name varchar(200) DEFAULT NULL,
  inv_spec varchar(200) DEFAULT NULL,
  remark CLOB,
  tax decimal(19,6) DEFAULT NULL,
  untax_amount decimal(19,6) DEFAULT NULL,
  total_amount_incl_tax_origin decimal(24,6) DEFAULT NULL,
  total_amount_incl_tax_local decimal(24,6) DEFAULT NULL,
  tax_exclusive_amount_original decimal(24,6) DEFAULT NULL,
  tax_exclusive_amount_local decimal(24,6) DEFAULT NULL,
  tax_amount_original decimal(24,6) DEFAULT NULL,
  tax_amount_local decimal(24,6) DEFAULT NULL,
  invrecord_detail_id bigint DEFAULT NULL,
  PRIMARY KEY (id)
);

-- ---------------------------------------------------------------------
-- 十、打样通知单（售前打样需求，pp_ 前缀）
-- ---------------------------------------------------------------------

-- pp_notice：打样通知单主表
CREATE TABLE pp_notice (
  id bigint NOT NULL,
  code varchar(200) DEFAULT NULL,
  pact_date date DEFAULT NULL,
  pact_state int DEFAULT '0',
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  auditor varchar(200) DEFAULT NULL,
  audit_time TIMESTAMP DEFAULT NULL,
  remark CLOB,
  sal_org_id bigint DEFAULT NULL,
  prd_org_id bigint DEFAULT NULL,
  dept_id bigint DEFAULT NULL,
  saler_id bigint DEFAULT NULL,
  brand_id bigint DEFAULT NULL,
  pp_cust varchar(200) DEFAULT NULL,
  cust_id bigint DEFAULT NULL,
  pro_qty decimal(19,6) DEFAULT NULL,
  mat_id bigint DEFAULT NULL,
  line_num decimal(16,8) DEFAULT NULL,
  yarn_num decimal(16,8) DEFAULT NULL,
  dye_type varchar(200) DEFAULT NULL,
  reply_date date DEFAULT NULL,
  raw_mat_id bigint DEFAULT NULL,
  hl_card_id bigint DEFAULT NULL,
  light1 varchar(200) DEFAULT NULL,
  light2 varchar(200) DEFAULT NULL,
  light3 varchar(200) DEFAULT NULL,
  color_fastness varchar(200) DEFAULT NULL,
  raw_lot_no varchar(200) DEFAULT NULL,
  sd_struct varchar(200) DEFAULT NULL,
  swatch_score varchar(200) DEFAULT NULL,
  swatch_size varchar(200) DEFAULT NULL,
  swatch varchar(200) DEFAULT NULL,
  sd_type varchar(200) DEFAULT NULL,
  swatch_pcs varchar(200) DEFAULT NULL,
  ep_req varchar(200) DEFAULT NULL,
  needle_req varchar(200) DEFAULT NULL,
  sd_req CLOB,
  is_en_print int DEFAULT '0',
  is_closed int DEFAULT '0',
  closed_by varchar(200) DEFAULT NULL,
  closed_time TIMESTAMP DEFAULT NULL,
  is_cancel int DEFAULT '0',
  cancel_by varchar(200) DEFAULT NULL,
  cancel_time TIMESTAMP DEFAULT NULL,
  cancel_reason varchar(3000) DEFAULT NULL,
  wf_request_id bigint DEFAULT NULL,
  reject_by varchar(200) DEFAULT NULL,
  reject_time TIMESTAMP DEFAULT NULL,
  reject_reason varchar(3000) DEFAULT NULL,
  PRIMARY KEY (id)
);

-- pp_notice_detail：打样通知单明细
CREATE TABLE pp_notice_detail (
  id bigint NOT NULL,
  notice_id bigint DEFAULT NULL,
  sort_index int DEFAULT NULL,
  sample_color varchar(200) DEFAULT NULL,
  print_color_id bigint DEFAULT NULL,
  color_name varchar(200) DEFAULT NULL,
  complete_date TIMESTAMP DEFAULT NULL,
  erp_entry_id varchar(200) DEFAULT NULL,
  remark CLOB,
  PRIMARY KEY (id)
);

-- ---------------------------------------------------------------------
-- 十一、打样记录（打样执行结果，pp_ 前缀）
-- ---------------------------------------------------------------------

-- pp_record：打样记录主表
CREATE TABLE pp_record (
  id bigint NOT NULL,
  code varchar(200) DEFAULT NULL,
  pact_date date DEFAULT NULL,
  pact_state int DEFAULT '0',
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  auditor varchar(200) DEFAULT NULL,
  audit_time TIMESTAMP DEFAULT NULL,
  remark CLOB,
  sal_org_id bigint DEFAULT NULL,
  prd_org_id bigint DEFAULT NULL,
  dept_id bigint DEFAULT NULL,
  saler_id bigint DEFAULT NULL,
  brand_id bigint DEFAULT NULL,
  cust_id bigint DEFAULT NULL,
  print_color_id bigint DEFAULT NULL,
  color_sys_id bigint DEFAULT NULL,
  color varchar(200) DEFAULT NULL,
  mat_id bigint DEFAULT NULL,
  line_num decimal(16,8) DEFAULT NULL,
  yarn_num decimal(16,8) DEFAULT NULL,
  dye_type varchar(200) DEFAULT NULL,
  confirm_date date DEFAULT NULL,
  send_date date DEFAULT NULL,
  raw_mat_id bigint DEFAULT NULL,
  hl_card_id bigint DEFAULT NULL,
  hue_qty decimal(19,6) DEFAULT NULL,
  pp_name varchar(200) DEFAULT NULL,
  is_dd_color int DEFAULT NULL,
  sd_type varchar(200) DEFAULT NULL,
  sd_spec varchar(200) DEFAULT NULL,
  liquor_ratio decimal(16,8) DEFAULT NULL,
  notice_id bigint DEFAULT NULL,
  is_closed int DEFAULT '0',
  closed_by varchar(200) DEFAULT NULL,
  closed_time TIMESTAMP DEFAULT NULL,
  is_cancel int DEFAULT '0',
  cancel_by varchar(200) DEFAULT NULL,
  cancel_time TIMESTAMP DEFAULT NULL,
  cancel_reason varchar(3000) DEFAULT NULL,
  wf_request_id bigint DEFAULT NULL,
  reject_by varchar(200) DEFAULT NULL,
  reject_time TIMESTAMP DEFAULT NULL,
  reject_reason varchar(3000) DEFAULT NULL,
  PRIMARY KEY (id)
);

-- pp_record_detail：打样记录明细
CREATE TABLE pp_record_detail (
  id bigint NOT NULL,
  record_id bigint DEFAULT NULL,
  sort_index int DEFAULT NULL,
  sample_color_no varchar(200) DEFAULT NULL,
  is_confirm int DEFAULT NULL,
  is_hue int DEFAULT NULL,
  notice_detail_id bigint DEFAULT NULL,
  remark CLOB,
  PRIMARY KEY (id)
);


-- ============================================================
-- 03-采购管理表
-- ============================================================

-- =====================================================================
-- 03-采购管理业务表
-- 说明：采购申请、采购合同、采购订单、收料通知、采购入库、采购退料、采购发票。
-- 采购链路：采购申请 → 采购合同 → 采购订单 → 收料通知 → 采购入库 → 采购退料
--                                                          → 采购发票（进项）
-- 命名约定：表前缀 pur_
-- 公共字段沿用销售表约定（pact_state/is_closed/is_cancel/change_state/审计字段）
-- =====================================================================

-- ---------------------------------------------------------------------
-- 一、采购申请
-- ---------------------------------------------------------------------

-- pur_apply：采购申请主表
CREATE TABLE pur_apply (
  id bigint NOT NULL,
  code varchar(200) DEFAULT NULL,
  apply_date date DEFAULT NULL,
  pact_state int DEFAULT '0',
  apply_type varchar(50) DEFAULT NULL,
  pur_org_id bigint DEFAULT NULL,
  sal_org_id bigint DEFAULT NULL,
  dept_id bigint DEFAULT NULL,
  applicant_id bigint DEFAULT NULL,
  saler_id bigint DEFAULT NULL,
  req_date date DEFAULT NULL,
  curr_id bigint DEFAULT NULL,
  supplier_id bigint DEFAULT NULL,
  raw_mat_id bigint DEFAULT NULL,
  total_qty decimal(19,6) DEFAULT NULL,
  total_amount decimal(19,6) DEFAULT NULL,
  pushed_qty decimal(19,6) DEFAULT NULL,
  is_closed int DEFAULT '0',
  closed_by varchar(200) DEFAULT NULL,
  closed_time TIMESTAMP DEFAULT NULL,
  is_cancel int DEFAULT '0',
  cancel_by varchar(200) DEFAULT NULL,
  cancel_time TIMESTAMP DEFAULT NULL,
  cancel_reason varchar(3000) DEFAULT NULL,
  change_state int DEFAULT '0',
  remark CLOB,
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  auditor varchar(200) DEFAULT NULL,
  audit_time TIMESTAMP DEFAULT NULL,
  wf_request_id bigint DEFAULT NULL,
  reject_by varchar(200) DEFAULT NULL,
  reject_time TIMESTAMP DEFAULT NULL,
  reject_reason varchar(3000) DEFAULT NULL,
  PRIMARY KEY (id)
);

-- pur_apply_goods：采购申请明细
CREATE TABLE pur_apply_goods (
  id bigint NOT NULL,
  sort_index int DEFAULT NULL,
  apply_id bigint DEFAULT NULL,
  hl_card_id bigint DEFAULT NULL,
  mat_id bigint DEFAULT NULL,
  line_num decimal(16,8) DEFAULT NULL,
  yarn_num decimal(16,8) DEFAULT NULL,
  raw_mat_id bigint DEFAULT NULL,
  fineness varchar(200) DEFAULT NULL,
  qty decimal(19,6) DEFAULT NULL,
  appr_qty decimal(19,6) DEFAULT NULL,
  used_qty decimal(19,6) DEFAULT NULL,
  remain_qty decimal(19,6) DEFAULT NULL,
  unit varchar(200) DEFAULT NULL,
  price decimal(19,6) DEFAULT NULL,
  amount decimal(19,6) DEFAULT NULL,
  comp_color_id bigint DEFAULT NULL,
  print_color_id bigint DEFAULT NULL,
  color varchar(200) DEFAULT NULL,
  yarn_use varchar(200) DEFAULT NULL,
  spin_process varchar(200) DEFAULT NULL,
  pack_type varchar(200) DEFAULT NULL,
  weight_type varchar(200) DEFAULT NULL,
  ml_rate decimal(16,8) DEFAULT NULL,
  mt_rate decimal(16,8) DEFAULT NULL,
  tec_type varchar(200) DEFAULT NULL,
  su_type varchar(200) DEFAULT NULL,
  sug_supplier_id bigint DEFAULT NULL,
  cust_id bigint DEFAULT NULL,
  saler_id bigint DEFAULT NULL,
  is_spec_mat int DEFAULT '0',
  lot_no varchar(200) DEFAULT NULL,
  mfg_order_id bigint DEFAULT NULL,
  sal_assign_id bigint DEFAULT NULL,
  pushed_qty decimal(19,6) DEFAULT NULL,
  vp_qty decimal(19,6) DEFAULT NULL,
  is_closed int DEFAULT '0',
  closed_by varchar(200) DEFAULT NULL,
  closed_time TIMESTAMP DEFAULT NULL,
  is_cancel int DEFAULT '0',
  cancel_by varchar(200) DEFAULT NULL,
  cancel_time TIMESTAMP DEFAULT NULL,
  remark CLOB,
  PRIMARY KEY (id)
);

-- ---------------------------------------------------------------------
-- 二、采购合同
-- ---------------------------------------------------------------------

-- pur_cont：采购合同主表
CREATE TABLE pur_cont (
  id bigint NOT NULL,
  code varchar(200) DEFAULT NULL,
  pact_date date DEFAULT NULL,
  pact_state int DEFAULT '0',
  supplier_id bigint DEFAULT NULL,
  pur_org_id bigint DEFAULT NULL,
  pur_dept_id bigint DEFAULT NULL,
  purchaser_id bigint DEFAULT NULL,
  curr_id bigint DEFAULT NULL,
  b_curr_rate decimal(16,8) DEFAULT NULL,
  cny_rate decimal(16,8) DEFAULT NULL,
  usd_rate decimal(16,8) DEFAULT NULL,
  trade_mode varchar(200) DEFAULT NULL,
  pay_method varchar(255) DEFAULT NULL,
  delivery_method varchar(255) DEFAULT NULL,
  shipment_date varchar(255) DEFAULT NULL,
  harbour_start varchar(200) DEFAULT NULL,
  harbour_end varchar(200) DEFAULT NULL,
  spill_short_rate decimal(19,6) DEFAULT NULL,
  quality_standard_id bigint DEFAULT NULL,
  total_qty decimal(19,6) DEFAULT NULL,
  total_amount decimal(19,6) DEFAULT NULL,
  is_dm int DEFAULT '0',
  is_closed int DEFAULT '0',
  is_cancel int DEFAULT '0',
  change_state int DEFAULT '0',
  remark CLOB,
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  auditor varchar(200) DEFAULT NULL,
  audit_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id)
);

-- pur_cont_goods：采购合同明细
CREATE TABLE pur_cont_goods (
  id bigint NOT NULL,
  sort_index int DEFAULT NULL,
  cont_id bigint DEFAULT NULL,
  mat_id bigint DEFAULT NULL,
  yarn_count decimal(16,8) DEFAULT NULL,
  strand decimal(16,8) DEFAULT NULL,
  qty decimal(19,6) DEFAULT NULL,
  unit varchar(200) DEFAULT NULL,
  price decimal(19,6) DEFAULT NULL,
  amount decimal(19,6) DEFAULT NULL,
  require_date date DEFAULT NULL,
  lot_no varchar(200) DEFAULT NULL,
  tax_rate decimal(16,8) DEFAULT NULL,
  remark CLOB,
  PRIMARY KEY (id)
);

-- pur_cont_goods_assign：采购合同指定用料孙表（对应销售意向合同指定用料）
CREATE TABLE pur_cont_goods_assign (
  id bigint NOT NULL,
  sort_index int DEFAULT NULL,
  cont_goods_id bigint DEFAULT NULL,
  sal_assign_id bigint DEFAULT NULL,
  pur_apply_detail_id bigint DEFAULT NULL,
  mat_id bigint DEFAULT NULL,
  supplier_id bigint DEFAULT NULL,
  lot_no varchar(200) DEFAULT NULL,
  ratio decimal(16,8) DEFAULT NULL,
  qty decimal(19,6) DEFAULT NULL,
  price decimal(19,6) DEFAULT NULL,
  remark CLOB,
  PRIMARY KEY (id)
);

-- ---------------------------------------------------------------------
-- 三、采购订单
-- ---------------------------------------------------------------------

-- pur_order：采购订单主表
CREATE TABLE pur_order (
  id bigint NOT NULL,
  code varchar(200) DEFAULT NULL,
  order_date date DEFAULT NULL,
  pact_state int DEFAULT '0',
  supplier_id bigint DEFAULT NULL,
  pur_org_id bigint DEFAULT NULL,
  pur_dept_id bigint DEFAULT NULL,
  purchaser_id bigint DEFAULT NULL,
  curr_id bigint DEFAULT NULL,
  b_curr_rate decimal(16,8) DEFAULT NULL,
  cny_rate decimal(16,8) DEFAULT NULL,
  usd_rate decimal(16,8) DEFAULT NULL,
  pay_method varchar(255) DEFAULT NULL,
  delivery_method varchar(255) DEFAULT NULL,
  delivery_place varchar(255) DEFAULT NULL,
  harbour_end varchar(200) DEFAULT NULL,
  spill_short_rate decimal(19,6) DEFAULT NULL,
  total_qty decimal(19,6) DEFAULT NULL,
  total_amount decimal(19,6) DEFAULT NULL,
  received_qty decimal(19,6) DEFAULT NULL,
  return_qty decimal(19,6) DEFAULT NULL,
  vp_qty decimal(19,6) DEFAULT NULL,
  pur_cont_id bigint DEFAULT NULL,
  pur_apply_id bigint DEFAULT NULL,
  is_closed int DEFAULT '0',
  is_cancel int DEFAULT '0',
  change_state int DEFAULT '0',
  remark CLOB,
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  auditor varchar(200) DEFAULT NULL,
  audit_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id)
);

-- pur_order_goods：采购订单明细
CREATE TABLE pur_order_goods (
  id bigint NOT NULL,
  sort_index int DEFAULT NULL,
  order_id bigint DEFAULT NULL,
  mat_id bigint DEFAULT NULL,
  yarn_count decimal(16,8) DEFAULT NULL,
  strand decimal(16,8) DEFAULT NULL,
  qty decimal(19,6) DEFAULT NULL,
  unit varchar(200) DEFAULT NULL,
  price decimal(19,6) DEFAULT NULL,
  amount decimal(19,6) DEFAULT NULL,
  tax_rate decimal(16,8) DEFAULT NULL,
  require_date date DEFAULT NULL,
  lot_no varchar(200) DEFAULT NULL,
  received_qty decimal(19,6) DEFAULT NULL,
  return_qty decimal(19,6) DEFAULT NULL,
  vp_qty decimal(19,6) DEFAULT NULL,
  pur_apply_goods_id bigint DEFAULT NULL,
  pur_cont_goods_id bigint DEFAULT NULL,
  remark CLOB,
  PRIMARY KEY (id)
);

-- ---------------------------------------------------------------------
-- 四、收料通知
-- ---------------------------------------------------------------------

-- pur_receive_notice：收料通知主表
CREATE TABLE pur_receive_notice (
  id bigint NOT NULL,
  code varchar(200) DEFAULT NULL,
  notice_date date DEFAULT NULL,
  pact_state int DEFAULT '0',
  supplier_id bigint DEFAULT NULL,
  pur_org_id bigint DEFAULT NULL,
  pur_order_id bigint DEFAULT NULL,
  plan_date date DEFAULT NULL,
  transport_type varchar(200) DEFAULT NULL,
  tracking_no varchar(200) DEFAULT NULL,
  total_qty decimal(19,6) DEFAULT NULL,
  is_closed int DEFAULT '0',
  is_cancel int DEFAULT '0',
  remark CLOB,
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  auditor varchar(200) DEFAULT NULL,
  audit_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id)
);

-- pur_receive_notice_goods：收料通知明细
CREATE TABLE pur_receive_notice_goods (
  id bigint NOT NULL,
  sort_index int DEFAULT NULL,
  notice_id bigint DEFAULT NULL,
  mat_id bigint DEFAULT NULL,
  lot_no varchar(200) DEFAULT NULL,
  qty decimal(19,6) DEFAULT NULL,
  unit varchar(200) DEFAULT NULL,
  pur_order_goods_id bigint DEFAULT NULL,
  remark CLOB,
  PRIMARY KEY (id)
);

-- ---------------------------------------------------------------------
-- 五、采购入库（暂估应付 + 库存增加）
-- ---------------------------------------------------------------------

-- pur_in_stock：采购入库主表
CREATE TABLE pur_in_stock (
  id bigint NOT NULL,
  code varchar(200) DEFAULT NULL,
  in_date date DEFAULT NULL,
  pact_state int DEFAULT '0',
  supplier_id bigint DEFAULT NULL,
  pur_org_id bigint DEFAULT NULL,
  warehouse_id bigint DEFAULT NULL,
  in_type varchar(50) DEFAULT NULL,
  curr_id bigint DEFAULT NULL,
  b_curr_rate decimal(16,8) DEFAULT NULL,
  cny_rate decimal(16,8) DEFAULT NULL,
  usd_rate decimal(16,8) DEFAULT NULL,
  pur_order_id bigint DEFAULT NULL,
  receive_notice_id bigint DEFAULT NULL,
  total_qty decimal(19,6) DEFAULT NULL,
  total_amount decimal(19,6) DEFAULT NULL,
  est_amount decimal(19,6) DEFAULT NULL,
  est_ap_id bigint DEFAULT NULL,
  voucher_id bigint DEFAULT NULL,
  qc_result varchar(20) DEFAULT NULL,
  qc_by bigint DEFAULT NULL,
  qc_time TIMESTAMP DEFAULT NULL,
  is_closed int DEFAULT '0',
  is_cancel int DEFAULT '0',
  remark CLOB,
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  auditor varchar(200) DEFAULT NULL,
  audit_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id)
);

-- pur_in_stock_goods：采购入库明细
CREATE TABLE pur_in_stock_goods (
  id bigint NOT NULL,
  sort_index int DEFAULT NULL,
  in_stock_id bigint DEFAULT NULL,
  mat_id bigint DEFAULT NULL,
  lot_no varchar(200) DEFAULT NULL,
  vat_no varchar(200) DEFAULT NULL,
  qty decimal(19,6) DEFAULT NULL,
  unit varchar(200) DEFAULT NULL,
  price decimal(19,6) DEFAULT NULL,
  amount decimal(19,6) DEFAULT NULL,
  est_price decimal(19,6) DEFAULT NULL,
  est_amount decimal(19,6) DEFAULT NULL,
  tax_rate decimal(16,8) DEFAULT NULL,
  position_id bigint DEFAULT NULL,
  qc_result varchar(50) DEFAULT NULL,
  pur_order_goods_id bigint DEFAULT NULL,
  remark CLOB,
  PRIMARY KEY (id)
);

-- ---------------------------------------------------------------------
-- 六、采购退料
-- ---------------------------------------------------------------------

-- pur_return：采购退料主表
CREATE TABLE pur_return (
  id bigint NOT NULL,
  code varchar(200) DEFAULT NULL,
  return_date date DEFAULT NULL,
  pact_state int DEFAULT '0',
  supplier_id bigint DEFAULT NULL,
  pur_org_id bigint DEFAULT NULL,
  warehouse_id bigint DEFAULT NULL,
  in_stock_id bigint DEFAULT NULL,
  return_reason varchar(2000) DEFAULT NULL,
  total_qty decimal(19,6) DEFAULT NULL,
  total_amount decimal(19,6) DEFAULT NULL,
  is_closed int DEFAULT '0',
  is_cancel int DEFAULT '0',
  remark CLOB,
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  auditor varchar(200) DEFAULT NULL,
  audit_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id)
);

-- pur_return_goods：采购退料明细
CREATE TABLE pur_return_goods (
  id bigint NOT NULL,
  sort_index int DEFAULT NULL,
  return_id bigint DEFAULT NULL,
  mat_id bigint DEFAULT NULL,
  lot_no varchar(200) DEFAULT NULL,
  vat_no varchar(200) DEFAULT NULL,
  qty decimal(19,6) DEFAULT NULL,
  unit varchar(200) DEFAULT NULL,
  price decimal(19,6) DEFAULT NULL,
  amount decimal(19,6) DEFAULT NULL,
  in_stock_goods_id bigint DEFAULT NULL,
  remark CLOB,
  PRIMARY KEY (id)
);

-- ---------------------------------------------------------------------
-- 七、采购发票（进项）
-- ---------------------------------------------------------------------

-- pur_invoice：采购发票主表
CREATE TABLE pur_invoice (
  id bigint NOT NULL,
  code varchar(200) DEFAULT NULL,
  invoice_code varchar(100) DEFAULT NULL,
  invoice_no varchar(100) DEFAULT NULL,
  invoice_date date DEFAULT NULL,
  pact_state int DEFAULT '0',
  supplier_id bigint DEFAULT NULL,
  pur_org_id bigint DEFAULT NULL,
  invoice_type varchar(50) DEFAULT NULL,
  no_tax_amount decimal(19,6) DEFAULT NULL,
  tax_amount decimal(19,6) DEFAULT NULL,
  total_amount decimal(19,6) DEFAULT NULL,
  certify_status varchar(50) DEFAULT NULL,
  certify_date date DEFAULT NULL,
  deduct_amount decimal(19,6) DEFAULT NULL,
  is_agri int DEFAULT '0',
  ap_id bigint DEFAULT NULL,
  voucher_id bigint DEFAULT NULL,
  is_closed int DEFAULT '0',
  is_cancel int DEFAULT '0',
  remark CLOB,
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  auditor varchar(200) DEFAULT NULL,
  audit_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id)
);

-- pur_invoice_goods：采购发票明细
CREATE TABLE pur_invoice_goods (
  id bigint NOT NULL,
  sort_index int DEFAULT NULL,
  invoice_id bigint DEFAULT NULL,
  mat_id bigint DEFAULT NULL,
  qty decimal(19,6) DEFAULT NULL,
  unit varchar(200) DEFAULT NULL,
  price decimal(19,6) DEFAULT NULL,
  no_tax_amount decimal(19,6) DEFAULT NULL,
  tax_rate decimal(16,8) DEFAULT NULL,
  tax_amount decimal(19,6) DEFAULT NULL,
  total_amount decimal(19,6) DEFAULT NULL,
  in_stock_goods_id bigint DEFAULT NULL,
  pur_order_goods_id bigint DEFAULT NULL,
  PRIMARY KEY (id)
);


-- ============================================================
-- 04-库存管理表
-- ============================================================

-- =====================================================================
-- 04-库存管理业务表
-- 说明：即时库存、批次管理、盘点、调拨、形态转换、其他出入库。
-- 命名约定：表前缀 inv_
-- 即时库存为汇总表，由各出入库单据审核更新。
-- =====================================================================

-- ---------------------------------------------------------------------
-- 一、即时库存（汇总表）
-- ---------------------------------------------------------------------

-- inv_stock：即时库存
CREATE TABLE inv_stock (
  id bigint NOT NULL,
  org_id bigint DEFAULT NULL,
  warehouse_id bigint DEFAULT NULL,
  position_id bigint DEFAULT NULL,
  mat_id bigint DEFAULT NULL,
  batch_no varchar(200) DEFAULT NULL,
  vat_no varchar(200) DEFAULT NULL,
  hl_card_id bigint DEFAULT NULL,
  comp_color_id bigint DEFAULT NULL,
  print_color_id bigint DEFAULT NULL,
  unit varchar(200) DEFAULT NULL,
  qty decimal(19,6) DEFAULT NULL,
  lock_qty decimal(19,6) DEFAULT '0',
  available_qty decimal(19,6) DEFAULT NULL,
  in_transit_qty decimal(19,6) DEFAULT '0',
  cost_price decimal(19,6) DEFAULT NULL,
  cost_amount decimal(19,6) DEFAULT NULL,
  in_stock_time TIMESTAMP DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE (org_id,warehouse_id,position_id,mat_id,batch_no,vat_no)
);

-- ---------------------------------------------------------------------
-- 二、批次管理
-- ---------------------------------------------------------------------

-- inv_batch：批次台账
CREATE TABLE inv_batch (
  id bigint NOT NULL,
  mat_id bigint DEFAULT NULL,
  batch_no varchar(200) DEFAULT NULL,
  vat_no varchar(200) DEFAULT NULL,
  in_date date DEFAULT NULL,
  produce_date date DEFAULT NULL,
  shelf_life int DEFAULT NULL,
  expire_date date DEFAULT NULL,
  supplier_id bigint DEFAULT NULL,
  src_bill_type varchar(100) DEFAULT NULL,
  src_bill_id bigint DEFAULT NULL,
  qty decimal(19,6) DEFAULT NULL,
  status varchar(50) DEFAULT NULL,
  remark CLOB,
  PRIMARY KEY (id)
);

-- ---------------------------------------------------------------------
-- 三、盘点
-- ---------------------------------------------------------------------

-- inv_stocktake：盘点主表
CREATE TABLE inv_stocktake (
  id bigint NOT NULL,
  code varchar(200) DEFAULT NULL,
  stocktake_date date DEFAULT NULL,
  pact_state int DEFAULT '0',
  org_id bigint DEFAULT NULL,
  warehouse_id bigint DEFAULT NULL,
  stocktake_type varchar(50) DEFAULT NULL,
  stocktake_by varchar(200) DEFAULT NULL,
  total_qty decimal(19,6) DEFAULT NULL,
  diff_amount decimal(19,6) DEFAULT NULL,
  voucher_id bigint DEFAULT NULL,
  is_closed int DEFAULT '0',
  is_cancel int DEFAULT '0',
  remark CLOB,
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  auditor varchar(200) DEFAULT NULL,
  audit_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id)
);

-- inv_stocktake_goods：盘点明细
CREATE TABLE inv_stocktake_goods (
  id bigint NOT NULL,
  sort_index int DEFAULT NULL,
  stocktake_id bigint DEFAULT NULL,
  mat_id bigint DEFAULT NULL,
  batch_no varchar(200) DEFAULT NULL,
  vat_no varchar(200) DEFAULT NULL,
  book_qty decimal(19,6) DEFAULT NULL,
  actual_qty decimal(19,6) DEFAULT NULL,
  diff_qty decimal(19,6) DEFAULT NULL,
  diff_reason varchar(500) DEFAULT NULL,
  cost_price decimal(19,6) DEFAULT NULL,
  diff_amount decimal(19,6) DEFAULT NULL,
  remark CLOB,
  PRIMARY KEY (id)
);

-- ---------------------------------------------------------------------
-- 四、调拨
-- ---------------------------------------------------------------------

-- inv_transfer：调拨主表
CREATE TABLE inv_transfer (
  id bigint NOT NULL,
  code varchar(200) DEFAULT NULL,
  transfer_date date DEFAULT NULL,
  pact_state int DEFAULT '0',
  from_org_id bigint DEFAULT NULL,
  from_warehouse_id bigint DEFAULT NULL,
  to_org_id bigint DEFAULT NULL,
  to_warehouse_id bigint DEFAULT NULL,
  transfer_type varchar(50) DEFAULT NULL,
  is_internal_trade int DEFAULT '0',
  total_qty decimal(19,6) DEFAULT NULL,
  total_amount decimal(19,6) DEFAULT NULL,
  voucher_id bigint DEFAULT NULL,
  is_closed int DEFAULT '0',
  is_cancel int DEFAULT '0',
  remark CLOB,
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  auditor varchar(200) DEFAULT NULL,
  audit_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id)
);

-- inv_transfer_goods：调拨明细
CREATE TABLE inv_transfer_goods (
  id bigint NOT NULL,
  sort_index int DEFAULT NULL,
  transfer_id bigint DEFAULT NULL,
  mat_id bigint DEFAULT NULL,
  batch_no varchar(200) DEFAULT NULL,
  vat_no varchar(200) DEFAULT NULL,
  qty decimal(19,6) DEFAULT NULL,
  unit varchar(200) DEFAULT NULL,
  cost_price decimal(19,6) DEFAULT NULL,
  cost_amount decimal(19,6) DEFAULT NULL,
  remark CLOB,
  PRIMARY KEY (id)
);

-- ---------------------------------------------------------------------
-- 五、形态转换（筒子纱↔绞纱、并纱、络筒）
-- ---------------------------------------------------------------------

-- inv_form_conv：形态转换主表
CREATE TABLE inv_form_conv (
  id bigint NOT NULL,
  code varchar(200) DEFAULT NULL,
  conv_date date DEFAULT NULL,
  pact_state int DEFAULT '0',
  org_id bigint DEFAULT NULL,
  warehouse_id bigint DEFAULT NULL,
  conv_type varchar(50) DEFAULT NULL,
  total_qty decimal(19,6) DEFAULT NULL,
  diff_amount decimal(19,6) DEFAULT NULL,
  voucher_id bigint DEFAULT NULL,
  is_closed int DEFAULT '0',
  is_cancel int DEFAULT '0',
  remark CLOB,
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  auditor varchar(200) DEFAULT NULL,
  audit_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id)
);

-- inv_form_conv_goods：形态转换明细（源→目标）
CREATE TABLE inv_form_conv_goods (
  id bigint NOT NULL,
  sort_index int DEFAULT NULL,
  conv_id bigint DEFAULT NULL,
  src_mat_id bigint DEFAULT NULL,
  src_batch_no varchar(200) DEFAULT NULL,
  src_qty decimal(19,6) DEFAULT NULL,
  tgt_mat_id bigint DEFAULT NULL,
  tgt_batch_no varchar(200) DEFAULT NULL,
  tgt_qty decimal(19,6) DEFAULT NULL,
  loss_rate decimal(16,8) DEFAULT NULL,
  diff_qty decimal(19,6) DEFAULT NULL,
  cost_price decimal(19,6) DEFAULT NULL,
  diff_amount decimal(19,6) DEFAULT NULL,
  remark CLOB,
  PRIMARY KEY (id)
);

-- ---------------------------------------------------------------------
-- 六、其他出入库
-- ---------------------------------------------------------------------

-- inv_other_stock：其他出入库主表
CREATE TABLE inv_other_stock (
  id bigint NOT NULL,
  code varchar(200) DEFAULT NULL,
  bill_date date DEFAULT NULL,
  pact_state int DEFAULT '0',
  org_id bigint DEFAULT NULL,
  warehouse_id bigint DEFAULT NULL,
  stock_direction varchar(50) DEFAULT NULL,
  biz_type varchar(50) DEFAULT NULL,
  total_qty decimal(19,6) DEFAULT NULL,
  total_amount decimal(19,6) DEFAULT NULL,
  cost_amount decimal(19,6) DEFAULT NULL,
  voucher_id bigint DEFAULT NULL,
  is_closed int DEFAULT '0',
  is_cancel int DEFAULT '0',
  remark CLOB,
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  auditor varchar(200) DEFAULT NULL,
  audit_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id)
);

-- inv_other_stock_goods：其他出入库明细
CREATE TABLE inv_other_stock_goods (
  id bigint NOT NULL,
  sort_index int DEFAULT NULL,
  bill_id bigint DEFAULT NULL,
  mat_id bigint DEFAULT NULL,
  batch_no varchar(200) DEFAULT NULL,
  vat_no varchar(200) DEFAULT NULL,
  qty decimal(19,6) DEFAULT NULL,
  unit varchar(200) DEFAULT NULL,
  cost_price decimal(19,6) DEFAULT NULL,
  cost_amount decimal(19,6) DEFAULT NULL,
  position_id bigint DEFAULT NULL,
  remark CLOB,
  PRIMARY KEY (id)
);

-- ---------------------------------------------------------------------
-- 七、锁库管理（锁库单 / 锁库申请单）
-- ---------------------------------------------------------------------

-- inv_lock：锁库单主表
CREATE TABLE inv_lock (
  id bigint NOT NULL,
  code varchar(200) DEFAULT NULL,
  pact_date date DEFAULT NULL,
  pact_state int DEFAULT '0',
  saler_id bigint DEFAULT NULL,
  dept_id bigint DEFAULT NULL,
  cust_id bigint DEFAULT NULL,
  sal_order_id bigint DEFAULT NULL,
  mat_id bigint DEFAULT NULL,
  warehouse_id bigint DEFAULT NULL,
  apply_code varchar(255) DEFAULT NULL,
  org_id bigint DEFAULT NULL,
  total_lock_qty decimal(19,6) DEFAULT NULL,
  total_unlock_qty decimal(19,6) DEFAULT NULL,
  is_closed int DEFAULT '0',
  is_cancel int DEFAULT '0',
  wf_request_id bigint DEFAULT NULL,
  reject_by varchar(200) DEFAULT NULL,
  reject_time TIMESTAMP DEFAULT NULL,
  reject_reason varchar(3000) DEFAULT NULL,
  remark CLOB,
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  auditor varchar(200) DEFAULT NULL,
  audit_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id)
);

-- inv_lock_goods：锁库单明细
CREATE TABLE inv_lock_goods (
  id bigint NOT NULL,
  sort_index int DEFAULT NULL,
  hl_card_id bigint DEFAULT NULL,
  lock_id bigint DEFAULT NULL,
  mat_id bigint DEFAULT NULL,
  line_num decimal(16,8) DEFAULT NULL,
  yarn_num decimal(16,8) DEFAULT NULL,
  raw_mat_id bigint DEFAULT NULL,
  fineness varchar(200) DEFAULT NULL,
  comp_color_id bigint DEFAULT NULL,
  print_color_id bigint DEFAULT NULL,
  color varchar(200) DEFAULT NULL,
  inv_id bigint DEFAULT NULL,
  lot_no varchar(200) DEFAULT NULL,
  dye_code varchar(200) DEFAULT NULL,
  stock_name varchar(200) DEFAULT NULL,
  position_id bigint DEFAULT NULL,
  unit varchar(200) DEFAULT NULL,
  out_qty decimal(19,6) DEFAULT NULL,
  lock_qty decimal(19,6) DEFAULT NULL,
  un_lock_qty decimal(19,6) DEFAULT NULL,
  valid_qty decimal(19,6) DEFAULT NULL,
  is_unlock int DEFAULT NULL,
  end_date date DEFAULT NULL,
  remark CLOB,
  stock_state varchar(255) DEFAULT NULL,
  lot_no_master_code varchar(255) DEFAULT NULL,
  stock_code varchar(255) DEFAULT NULL,
  org_code varchar(255) DEFAULT NULL,
  org_id bigint DEFAULT NULL,
  lock_apply_detail_id bigint DEFAULT NULL,
  mat_code varchar(255) DEFAULT NULL,
  raw_mat_code varchar(255) DEFAULT NULL,
  hl_card_code varchar(255) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  create_by varchar(100) DEFAULT NULL,
  update_by varchar(100) DEFAULT NULL,
  PRIMARY KEY (id)
);

-- inv_lock_apply：锁库申请单主表
CREATE TABLE inv_lock_apply (
  id bigint NOT NULL,
  code varchar(200) DEFAULT NULL,
  pact_date date DEFAULT NULL,
  pact_state int DEFAULT '0',
  saler_id bigint DEFAULT NULL,
  dept_id bigint DEFAULT NULL,
  cust_id bigint DEFAULT NULL,
  pact_type varchar(255) DEFAULT NULL,
  org_id bigint DEFAULT NULL,
  is_lock varchar(255) DEFAULT NULL,
  is_closed int DEFAULT NULL,
  closed_by varchar(200) DEFAULT NULL,
  closed_time TIMESTAMP DEFAULT NULL,
  is_cancel int DEFAULT NULL,
  cancel_by varchar(200) DEFAULT NULL,
  cancel_time TIMESTAMP DEFAULT NULL,
  is_renew_lock int DEFAULT '0',
  wf_request_id bigint DEFAULT NULL,
  reject_by varchar(200) DEFAULT NULL,
  reject_time TIMESTAMP DEFAULT NULL,
  reject_reason varchar(3000) DEFAULT NULL,
  remark CLOB,
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  auditor varchar(200) DEFAULT NULL,
  audit_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id)
);

-- inv_lock_apply_goods：锁库申请单明细
CREATE TABLE inv_lock_apply_goods (
  id bigint NOT NULL,
  sort_index int DEFAULT NULL,
  hl_card_id bigint DEFAULT NULL,
  lock_apply_id bigint DEFAULT NULL,
  mat_id bigint DEFAULT NULL,
  line_num decimal(16,8) DEFAULT NULL,
  yarn_num decimal(16,8) DEFAULT NULL,
  raw_mat_id bigint DEFAULT NULL,
  fineness varchar(200) DEFAULT NULL,
  qty decimal(19,6) DEFAULT NULL,
  comp_color_id bigint DEFAULT NULL,
  print_color_id bigint DEFAULT NULL,
  color varchar(200) DEFAULT NULL,
  inv_id bigint DEFAULT NULL,
  lot_no varchar(200) DEFAULT NULL,
  dye_code varchar(200) DEFAULT NULL,
  stock_id varchar(200) DEFAULT NULL,
  stock_name varchar(200) DEFAULT NULL,
  unit varchar(200) DEFAULT NULL,
  lock_qty decimal(19,6) DEFAULT NULL,
  end_date date DEFAULT NULL,
  stock_code varchar(200) DEFAULT NULL,
  stock_loc varchar(255) DEFAULT NULL,
  is_closed int DEFAULT NULL,
  closed_by varchar(200) DEFAULT NULL,
  closed_time TIMESTAMP DEFAULT NULL,
  is_cancel int DEFAULT NULL,
  cancel_by varchar(200) DEFAULT NULL,
  cancel_time TIMESTAMP DEFAULT NULL,
  is_renew_lock int DEFAULT '0',
  lock_apply_detail_id bigint DEFAULT NULL,
  lock_apply_code varchar(255) DEFAULT NULL,
  remark CLOB,
  PRIMARY KEY (id)
);


-- ============================================================
-- 05-生产制造表
-- ============================================================

-- =====================================================================
-- 05-生产制造业务表
-- 说明：BOM与配方、工艺路线、生产订单、领料单、生产入库、MRP、外协。
-- 命名约定：表前缀 mfg_
-- 生产订单采用主子两层：订单头-投料明细（工序汇报由独立工作流/采集系统承担）
-- 状态机：pact_state 0暂存1已创建2已提交3已审核4已驳回；is_closed/is_cancel 辅助
-- =====================================================================

-- ---------------------------------------------------------------------
-- 一、BOM与配方
-- ---------------------------------------------------------------------

-- mfg_bom：BOM/配方主表
CREATE TABLE mfg_bom (
  id bigint NOT NULL,
  code varchar(200) DEFAULT NULL,
  mat_id bigint DEFAULT NULL,
  bom_type varchar(50) DEFAULT NULL,
  version_no int DEFAULT '1',
  version_state varchar(50) DEFAULT NULL,
  valid_start date DEFAULT NULL,
  valid_end date DEFAULT NULL,
  route_id bigint DEFAULT NULL,
  base_qty decimal(19,6) DEFAULT NULL,
  std_cost decimal(19,6) DEFAULT NULL,
  pact_state int DEFAULT '0',
  remark CLOB,
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  auditor varchar(200) DEFAULT NULL,
  audit_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id)
);

-- mfg_bom_material：BOM原料明细（子表）
CREATE TABLE mfg_bom_material (
  id bigint NOT NULL,
  sort_index int DEFAULT NULL,
  bom_id bigint DEFAULT NULL,
  mat_id bigint DEFAULT NULL,
  mat_type varchar(50) DEFAULT NULL,
  ratio decimal(16,8) DEFAULT NULL,
  unit_qty decimal(19,6) DEFAULT NULL,
  loss_rate decimal(16,8) DEFAULT NULL,
  order_idx int DEFAULT NULL,
  is_dm int DEFAULT '0',
  sub_flag int DEFAULT '0',
  remark CLOB,
  PRIMARY KEY (id)
);

-- mfg_bom_material_sub：BOM替代料/染化料细分（孙表）
CREATE TABLE mfg_bom_material_sub (
  id bigint NOT NULL,
  sort_index int DEFAULT NULL,
  bom_material_id bigint DEFAULT NULL,
  mat_id bigint DEFAULT NULL,
  sub_ratio decimal(16,8) DEFAULT NULL,
  priority int DEFAULT NULL,
  color_id bigint DEFAULT NULL,
  remark CLOB,
  PRIMARY KEY (id)
);

-- ---------------------------------------------------------------------
-- 二、工艺路线
-- ---------------------------------------------------------------------

-- mfg_route：工艺路线主表
CREATE TABLE mfg_route (
  id bigint NOT NULL,
  code varchar(200) DEFAULT NULL,
  mat_id bigint DEFAULT NULL,
  name varchar(200) DEFAULT NULL,
  pact_state int DEFAULT '0',
  remark CLOB,
  PRIMARY KEY (id)
);

-- mfg_route_operation：工艺工序明细
CREATE TABLE mfg_route_operation (
  id bigint NOT NULL,
  sort_index int DEFAULT NULL,
  route_id bigint DEFAULT NULL,
  operation_name varchar(200) DEFAULT NULL,
  std_labor_hours decimal(16,8) DEFAULT NULL,
  std_machine_hours decimal(16,8) DEFAULT NULL,
  machine_type varchar(100) DEFAULT NULL,
  piece_rate decimal(19,6) DEFAULT NULL,
  is_outsource int DEFAULT '0',
  remark CLOB,
  PRIMARY KEY (id)
);

-- ---------------------------------------------------------------------
-- 三、生产订单（主子两层：订单头-投料明细）
-- ---------------------------------------------------------------------

-- mfg_order：生产订单主表
CREATE TABLE mfg_order (
  id bigint NOT NULL,
  code varchar(200) DEFAULT NULL,
  order_date date DEFAULT NULL,
  pact_state int DEFAULT '0',
  org_id bigint DEFAULT NULL,
  workshop_id bigint DEFAULT NULL,
  mat_id bigint DEFAULT NULL,
  plan_qty decimal(19,6) DEFAULT NULL,
  unit varchar(200) DEFAULT NULL,
  plan_start date DEFAULT NULL,
  plan_end date DEFAULT NULL,
  bom_id bigint DEFAULT NULL,
  bom_version int DEFAULT NULL,
  route_id bigint DEFAULT NULL,
  sal_order_id bigint DEFAULT NULL,
  sal_order_line_id bigint DEFAULT NULL,
  fin_qty decimal(19,6) DEFAULT NULL,
  picked_qty decimal(19,6) DEFAULT NULL,
  cost_amount decimal(19,6) DEFAULT NULL,
  is_closed int DEFAULT '0',
  closed_by varchar(200) DEFAULT NULL,
  closed_time TIMESTAMP DEFAULT NULL,
  is_cancel int DEFAULT '0',
  change_state int DEFAULT '0',
  change_code varchar(255) DEFAULT NULL,
  remark CLOB,
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  auditor varchar(200) DEFAULT NULL,
  audit_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id)
);

-- mfg_order_material：生产订单投料明细（子表，由BOM展开）
CREATE TABLE mfg_order_material (
  id bigint NOT NULL,
  sort_index int DEFAULT NULL,
  order_id bigint DEFAULT NULL,
  mat_id bigint DEFAULT NULL,
  batch_no varchar(200) DEFAULT NULL,
  std_qty decimal(19,6) DEFAULT NULL,
  actual_qty decimal(19,6) DEFAULT NULL,
  loss_rate decimal(16,8) DEFAULT NULL,
  is_dm int DEFAULT '0',
  sal_assign_id bigint DEFAULT NULL,
  vp_qty decimal(19,6) DEFAULT NULL,
  remark CLOB,
  PRIMARY KEY (id)
);

-- ---------------------------------------------------------------------
-- 四、领料单
-- ---------------------------------------------------------------------

-- mfg_pick：领料单主表
CREATE TABLE mfg_pick (
  id bigint NOT NULL,
  code varchar(200) DEFAULT NULL,
  pick_date date DEFAULT NULL,
  pact_state int DEFAULT '0',
  org_id bigint DEFAULT NULL,
  workshop_id bigint DEFAULT NULL,
  warehouse_id bigint DEFAULT NULL,
  mfg_order_id bigint DEFAULT NULL,
  pick_type varchar(50) DEFAULT NULL,
  total_qty decimal(19,6) DEFAULT NULL,
  total_cost decimal(19,6) DEFAULT NULL,
  voucher_id bigint DEFAULT NULL,
  is_closed int DEFAULT '0',
  is_cancel int DEFAULT '0',
  remark CLOB,
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  auditor varchar(200) DEFAULT NULL,
  audit_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id)
);

-- mfg_pick_goods：领料单明细
CREATE TABLE mfg_pick_goods (
  id bigint NOT NULL,
  sort_index int DEFAULT NULL,
  pick_id bigint DEFAULT NULL,
  mat_id bigint DEFAULT NULL,
  batch_no varchar(200) DEFAULT NULL,
  vat_no varchar(200) DEFAULT NULL,
  qty decimal(19,6) DEFAULT NULL,
  unit varchar(200) DEFAULT NULL,
  cost_price decimal(19,6) DEFAULT NULL,
  cost_amount decimal(19,6) DEFAULT NULL,
  position_id bigint DEFAULT NULL,
  order_material_id bigint DEFAULT NULL,
  remark CLOB,
  PRIMARY KEY (id)
);

-- ---------------------------------------------------------------------
-- 五、生产入库
-- ---------------------------------------------------------------------

-- mfg_in_stock：生产入库主表
CREATE TABLE mfg_in_stock (
  id bigint NOT NULL,
  code varchar(200) DEFAULT NULL,
  in_date date DEFAULT NULL,
  pact_state int DEFAULT '0',
  org_id bigint DEFAULT NULL,
  warehouse_id bigint DEFAULT NULL,
  mfg_order_id bigint DEFAULT NULL,
  mfg_report_id bigint DEFAULT NULL,
  in_type varchar(50) DEFAULT NULL,
  total_qty decimal(19,6) DEFAULT NULL,
  total_cost decimal(19,6) DEFAULT NULL,
  voucher_id bigint DEFAULT NULL,
  qc_result varchar(20) DEFAULT NULL,
  qc_by bigint DEFAULT NULL,
  qc_time TIMESTAMP DEFAULT NULL,
  is_closed int DEFAULT '0',
  is_cancel int DEFAULT '0',
  remark CLOB,
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  auditor varchar(200) DEFAULT NULL,
  audit_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id)
);

-- mfg_in_stock_goods：生产入库明细
CREATE TABLE mfg_in_stock_goods (
  id bigint NOT NULL,
  sort_index int DEFAULT NULL,
  in_stock_id bigint DEFAULT NULL,
  mat_id bigint DEFAULT NULL,
  batch_no varchar(200) DEFAULT NULL,
  vat_no varchar(200) DEFAULT NULL,
  qty decimal(19,6) DEFAULT NULL,
  unit varchar(200) DEFAULT NULL,
  cost_price decimal(19,6) DEFAULT NULL,
  cost_amount decimal(19,6) DEFAULT NULL,
  position_id bigint DEFAULT NULL,
  mes_report_line varchar(50) DEFAULT NULL,
  remark CLOB,
  PRIMARY KEY (id)
);

-- ---------------------------------------------------------------------
-- 六、MRP 物料需求计划
-- ---------------------------------------------------------------------

-- MRP 物料需求计划主表
CREATE TABLE mfg_mrp_plan (
  id bigint NOT NULL,
  code varchar(50) NOT NULL,
  plan_date date NOT NULL,
  plan_type varchar(20) NOT NULL,
  org_id bigint DEFAULT NULL,
  pact_state SMALLINT NOT NULL DEFAULT 0,
  is_closed SMALLINT NOT NULL DEFAULT 0,
  is_cancel SMALLINT NOT NULL DEFAULT 0,
  create_by bigint DEFAULT NULL,
  create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE (code)
);

-- MRP 计划明细
CREATE TABLE mfg_mrp_plan_detail (
  id bigint NOT NULL,
  plan_id bigint NOT NULL,
  mat_id bigint NOT NULL,
  gross_req decimal(18,4) DEFAULT NULL,
  stock_avail decimal(18,4) DEFAULT NULL,
  in_transit decimal(18,4) DEFAULT NULL,
  allocated decimal(18,4) DEFAULT NULL,
  net_req decimal(18,4) DEFAULT NULL,
  sugg_type varchar(10) DEFAULT NULL,
  sugg_qty decimal(18,4) DEFAULT NULL,
  sugg_date date DEFAULT NULL,
  src_bill_type varchar(20) DEFAULT NULL,
  src_bill_id bigint DEFAULT NULL,
  is_converted SMALLINT NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);

-- ---------------------------------------------------------------------
-- 七、外协订单
-- ---------------------------------------------------------------------

-- 外协订单主表
CREATE TABLE mfg_outsource (
  id bigint NOT NULL,
  code varchar(50) NOT NULL,
  out_date date NOT NULL,
  order_id bigint DEFAULT NULL,
  supplier_id bigint NOT NULL,
  operation varchar(50) DEFAULT NULL,
  issue_wh bigint DEFAULT NULL,
  recv_wh bigint DEFAULT NULL,
  process_fee decimal(18,4) DEFAULT NULL,
  curr_id bigint DEFAULT NULL,
  pact_state SMALLINT NOT NULL DEFAULT 0,
  is_closed SMALLINT NOT NULL DEFAULT 0,
  is_cancel SMALLINT NOT NULL DEFAULT 0,
  create_by bigint DEFAULT NULL,
  create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE (code)
);

-- 外协订单明细
CREATE TABLE mfg_outsource_goods (
  id bigint NOT NULL,
  out_id bigint NOT NULL,
  mat_id bigint NOT NULL,
  batch_no varchar(50) DEFAULT NULL,
  plan_issue_qty decimal(18,4) DEFAULT NULL,
  issued_qty decimal(18,4) DEFAULT NULL,
  received_qty decimal(18,4) DEFAULT NULL,
  fee_price decimal(18,4) DEFAULT NULL,
  fee_amount decimal(18,4) DEFAULT NULL,
  unit varchar(20) DEFAULT NULL,
  PRIMARY KEY (id)
);

-- ---------------------------------------------------------------------
-- 八、生产通知单（销售驱动的生产备货通知，审核后转生产订单）
-- ---------------------------------------------------------------------

-- mfg_notice：生产通知单主表
CREATE TABLE mfg_notice (
  id bigint NOT NULL,
  code varchar(200) DEFAULT NULL,
  pact_date date DEFAULT NULL,
  pact_state int DEFAULT '0',
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  auditor varchar(200) DEFAULT NULL,
  audit_time TIMESTAMP DEFAULT NULL,
  remark CLOB,
  close_state varchar(200) DEFAULT NULL,
  closer varchar(200) DEFAULT NULL,
  close_time date DEFAULT NULL,
  sal_org_id bigint DEFAULT NULL,
  prd_org_id bigint DEFAULT NULL,
  cust_id bigint DEFAULT NULL,
  dept_id bigint DEFAULT NULL,
  saler_id bigint DEFAULT NULL,
  mat_id bigint DEFAULT NULL,
  route_id bigint DEFAULT NULL,
  trade_type varchar(200) DEFAULT NULL,
  trade_mode varchar(200) DEFAULT NULL,
  brand_id bigint DEFAULT NULL,
  agent varchar(200) DEFAULT NULL,
  cont_type varchar(200) DEFAULT NULL,
  is_fast int DEFAULT NULL,
  is_proof int DEFAULT NULL,
  is_et int DEFAULT NULL,
  rd_name varchar(200) DEFAULT NULL,
  order_id varchar(255) DEFAULT NULL,
  order_code varchar(500) DEFAULT NULL,
  is_rd int DEFAULT '0',
  is_closed int DEFAULT '0',
  closed_by varchar(200) DEFAULT NULL,
  closed_time TIMESTAMP DEFAULT NULL,
  is_cancel int DEFAULT '0',
  cancel_by varchar(200) DEFAULT NULL,
  cancel_time TIMESTAMP DEFAULT NULL,
  wf_request_id bigint DEFAULT NULL,
  reject_by varchar(200) DEFAULT NULL,
  reject_time TIMESTAMP DEFAULT NULL,
  reject_reason varchar(3000) DEFAULT NULL,
  su_type varchar(100) DEFAULT NULL,
  weight_type varchar(100) DEFAULT NULL,
  pack_type varchar(100) DEFAULT NULL,
  is_init int DEFAULT NULL,
  is_tech_review int DEFAULT '0',
  is_plan_review int DEFAULT '0',
  normal_start date DEFAULT NULL,
  normal_end date DEFAULT NULL,
  fast_start date DEFAULT NULL,
  fast_end date DEFAULT NULL,
  print_start date DEFAULT NULL,
  print_end date DEFAULT NULL,
  fastreturn_start date DEFAULT NULL,
  fastreturn_end date DEFAULT NULL,
  confirm_date date DEFAULT NULL,
  confirm_days int DEFAULT NULL,
  plan_reviewer bigint DEFAULT NULL,
  plan_review_time TIMESTAMP DEFAULT NULL,
  cust_po varchar(255) DEFAULT NULL,
  fast_delivery_date varchar(500) DEFAULT NULL,
  is_sa int DEFAULT NULL,
  cancel_reason varchar(3000) DEFAULT NULL,
  fp_req varchar(1000) DEFAULT NULL,
  is_gf int DEFAULT '0',
  is_nd int DEFAULT '0',
  dye_workshop varchar(255) DEFAULT NULL,
  yarn_use varchar(255) DEFAULT NULL,
  tech_deny varchar(512) DEFAULT NULL,
  plan_deny varchar(512) DEFAULT NULL,
  tech_denyer bigint DEFAULT NULL,
  tech_deny_time TIMESTAMP DEFAULT NULL,
  plan_denyer bigint DEFAULT NULL,
  plan_deny_time TIMESTAMP DEFAULT NULL,
  change_state int DEFAULT '0',
  order_date date DEFAULT NULL,
  proof_type varchar(20) DEFAULT NULL,
  PRIMARY KEY (id)
);

-- mfg_notice_goods：生产通知单明细
CREATE TABLE mfg_notice_goods (
  id bigint NOT NULL,
  sort_index int DEFAULT NULL,
  notice_id bigint DEFAULT NULL,
  order_goods_id bigint DEFAULT NULL,
  int_cont_goods_id bigint DEFAULT NULL,
  hl_card_id bigint DEFAULT NULL,
  mat_id bigint DEFAULT NULL,
  line_num decimal(16,8) DEFAULT NULL,
  yarn_num decimal(16,8) DEFAULT NULL,
  print_color_id bigint DEFAULT NULL,
  comp_color_id bigint DEFAULT NULL,
  color varchar(50) DEFAULT NULL,
  raw_mat_id bigint DEFAULT NULL,
  fineness varchar(200) DEFAULT NULL,
  qty decimal(19,6) DEFAULT NULL,
  unit varchar(200) DEFAULT NULL,
  price decimal(19,6) DEFAULT NULL,
  amount decimal(19,6) DEFAULT NULL,
  remark CLOB,
  su_type varchar(255) DEFAULT NULL,
  su_yarn_type varchar(255) DEFAULT NULL,
  yarn_use varchar(200) DEFAULT NULL,
  weight_type varchar(200) DEFAULT NULL,
  pack_type varchar(200) DEFAULT NULL,
  ct_weight decimal(16,8) DEFAULT NULL,
  yarn_type varchar(200) DEFAULT NULL,
  single_yarn_twist decimal(12,4) DEFAULT NULL,
  strands_twist decimal(12,4) DEFAULT NULL,
  sp_req varchar(1000) DEFAULT NULL,
  sp_price decimal(19,6) DEFAULT NULL,
  pack_req varchar(1000) DEFAULT NULL,
  cf_req varchar(1000) DEFAULT NULL,
  dye_req varchar(1000) DEFAULT NULL,
  ps_req varchar(1000) DEFAULT NULL,
  spin_process varchar(200) DEFAULT NULL,
  is_fast int DEFAULT NULL,
  is_proof int DEFAULT NULL,
  dev_date date DEFAULT NULL,
  cust_po varchar(200) DEFAULT NULL,
  oe_rate decimal(16,8) DEFAULT NULL,
  cust_mat_no varchar(200) DEFAULT NULL,
  cust_color_no varchar(200) DEFAULT NULL,
  cust_color_name varchar(200) DEFAULT NULL,
  cust_lot_no varchar(200) DEFAULT NULL,
  confirm_color varchar(200) DEFAULT NULL,
  is_dd_color int DEFAULT NULL,
  ml_rate decimal(16,8) DEFAULT NULL,
  hs_qty decimal(19,6) DEFAULT NULL,
  ms_qty decimal(19,6) DEFAULT NULL,
  hs_info varchar(255) DEFAULT NULL,
  tec_type varchar(200) DEFAULT NULL,
  tp_req varchar(255) DEFAULT NULL,
  date_start date DEFAULT NULL,
  date_end date DEFAULT NULL,
  is_single int DEFAULT '0',
  is_wax int DEFAULT '0',
  is_bleach int DEFAULT '0',
  twist varchar(200) DEFAULT NULL,
  e_yarn_lot_no varchar(200) DEFAULT NULL,
  is_hs_confirm int DEFAULT NULL,
  is_et int DEFAULT NULL,
  is_closed int DEFAULT '0',
  closed_by varchar(200) DEFAULT NULL,
  closed_time TIMESTAMP DEFAULT NULL,
  is_cancel int DEFAULT '0',
  cancel_by varchar(200) DEFAULT NULL,
  cancel_time TIMESTAMP DEFAULT NULL,
  cont_goods_id bigint DEFAULT NULL,
  yarn_sal_type varchar(255) DEFAULT NULL,
  not_in_qty decimal(19,6) DEFAULT NULL,
  tech_reviewer bigint DEFAULT NULL,
  tech_review_time TIMESTAMP DEFAULT NULL,
  is_tech_review int DEFAULT '0',
  tech_review_remark CLOB,
  tech_review_info_id bigint DEFAULT NULL,
  tech_review_info varchar(1000) DEFAULT NULL,
  spin_type varchar(255) DEFAULT NULL,
  label_print_req varchar(500) DEFAULT NULL,
  check_price decimal(19,6) DEFAULT NULL,
  rb_no varchar(255) DEFAULT NULL,
  sb_no varchar(255) DEFAULT NULL,
  cont_code varchar(255) DEFAULT NULL,
  raw_mat_req varchar(500) DEFAULT NULL,
  is_plan_review int DEFAULT '0',
  normal_start date DEFAULT NULL,
  normal_end date DEFAULT NULL,
  fast_start date DEFAULT NULL,
  fast_end date DEFAULT NULL,
  print_start date DEFAULT NULL,
  print_end date DEFAULT NULL,
  fastreturn_start date DEFAULT NULL,
  fastreturn_end date DEFAULT NULL,
  confirm_date date DEFAULT NULL,
  confirm_days int DEFAULT NULL,
  plan_reviewer bigint DEFAULT NULL,
  plan_review_time TIMESTAMP DEFAULT NULL,
  single_yarn_twist_direction varchar(64) DEFAULT NULL,
  strands_twist_direction varchar(64) DEFAULT NULL,
  sample_start date DEFAULT NULL,
  sample_end date DEFAULT NULL,
  sec_tech_reviewer bigint DEFAULT NULL,
  sec_tech_review_time TIMESTAMP DEFAULT NULL,
  worsted_workshop_section varchar(56) DEFAULT NULL,
  hfp_date date DEFAULT NULL,
  other_spin_notes varchar(255) DEFAULT NULL,
  cost_price decimal(19,6) DEFAULT NULL,
  is_following_combination bigint DEFAULT NULL,
  recombing_tech_req varchar(500) DEFAULT NULL,
  dyeing_tech_req varchar(500) DEFAULT NULL,
  is_rd int DEFAULT NULL,
  cust_id bigint DEFAULT NULL,
  need_co int DEFAULT NULL,
  PRIMARY KEY (id)
);


-- ============================================================
-- 06-财务会计表
-- ============================================================

-- =====================================================================
-- 06-财务会计业务表
-- 说明：会计科目、会计期间、凭证模板、凭证、暂估应付、应收、应付、收款、
--       付款、核销、成本归集、制造费用池、成本差异。
-- 命名约定：表前缀 fin_
-- =====================================================================

-- ---------------------------------------------------------------------
-- 一、会计科目与期间
-- ---------------------------------------------------------------------

-- fin_account：会计科目
CREATE TABLE fin_account (
  id bigint NOT NULL,
  code varchar(100) DEFAULT NULL,
  name varchar(200) DEFAULT NULL,
  account_class varchar(50) DEFAULT NULL,
  dc_direction varchar(10) DEFAULT NULL,
  parent_id bigint DEFAULT NULL,
  is_leaf int DEFAULT '1',
  aux_flag int DEFAULT '0',
  aux_type varchar(200) DEFAULT NULL,
  status int DEFAULT '1',
  PRIMARY KEY (id),
  UNIQUE (code)
);

-- fin_period：会计期间
CREATE TABLE fin_period (
  id bigint NOT NULL,
  period_code varchar(20) DEFAULT NULL,
  year_no int DEFAULT NULL,
  month_no int DEFAULT NULL,
  start_date date DEFAULT NULL,
  end_date date DEFAULT NULL,
  status varchar(50) DEFAULT NULL,
  closed_by varchar(200) DEFAULT NULL,
  closed_time TIMESTAMP DEFAULT NULL,
  org_id bigint DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE (org_id,period_code)
);

-- ---------------------------------------------------------------------
-- 二、凭证模板与凭证
-- ---------------------------------------------------------------------

-- fin_voucher_tpl：凭证模板主表
CREATE TABLE fin_voucher_tpl (
  id bigint NOT NULL,
  code varchar(100) DEFAULT NULL,
  name varchar(200) DEFAULT NULL,
  src_bill_type varchar(100) DEFAULT NULL,
  org_id bigint DEFAULT NULL,
  cur_type varchar(50) DEFAULT NULL,
  status int DEFAULT '1',
  remark CLOB,
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id)
);

-- fin_voucher_tpl_entry：凭证模板分录
CREATE TABLE fin_voucher_tpl_entry (
  id bigint NOT NULL,
  sort_index int DEFAULT NULL,
  tpl_id bigint DEFAULT NULL,
  dc varchar(10) DEFAULT NULL,
  account_id bigint DEFAULT NULL,
  amount_source varchar(500) DEFAULT NULL,
  summary varchar(500) DEFAULT NULL,
  aux_source varchar(500) DEFAULT NULL,
  PRIMARY KEY (id)
);

-- fin_voucher：凭证主表
CREATE TABLE fin_voucher (
  id bigint NOT NULL,
  code varchar(200) DEFAULT NULL,
  voucher_date date DEFAULT NULL,
  period_code varchar(20) DEFAULT NULL,
  org_id bigint DEFAULT NULL,
  src_bill_type varchar(100) DEFAULT NULL,
  src_bill_id bigint DEFAULT NULL,
  attached_count int DEFAULT '0',
  total_debit decimal(19,6) DEFAULT NULL,
  total_credit decimal(19,6) DEFAULT NULL,
  status varchar(50) DEFAULT NULL,
  is_auto int DEFAULT '1',
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  auditor varchar(200) DEFAULT NULL,
  audit_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id)
);

-- fin_voucher_entry：凭证分录
CREATE TABLE fin_voucher_entry (
  id bigint NOT NULL,
  sort_index int DEFAULT NULL,
  voucher_id bigint DEFAULT NULL,
  dc varchar(10) DEFAULT NULL,
  account_id bigint DEFAULT NULL,
  amount decimal(19,6) DEFAULT NULL,
  summary varchar(500) DEFAULT NULL,
  cust_id bigint DEFAULT NULL,
  supplier_id bigint DEFAULT NULL,
  mat_id bigint DEFAULT NULL,
  dept_id bigint DEFAULT NULL,
  project_id bigint DEFAULT NULL,
  aux_org_id bigint DEFAULT NULL,
  PRIMARY KEY (id)
);

-- ---------------------------------------------------------------------
-- 三、应收应付与收付款
-- ---------------------------------------------------------------------

-- fin_est_ap：暂估应付
CREATE TABLE fin_est_ap (
  id bigint NOT NULL,
  code varchar(200) DEFAULT NULL,
  src_bill_type varchar(100) DEFAULT NULL,
  src_bill_id bigint DEFAULT NULL,
  supplier_id bigint DEFAULT NULL,
  org_id bigint DEFAULT NULL,
  curr_id bigint DEFAULT NULL,
  est_amount decimal(19,6) DEFAULT NULL,
  settle_amount decimal(19,6) DEFAULT '0',
  balance decimal(19,6) DEFAULT NULL,
  status varchar(50) DEFAULT NULL,
  voucher_id bigint DEFAULT NULL,
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id)
);

-- fin_ar：应收单
CREATE TABLE fin_ar (
  id bigint NOT NULL,
  code varchar(200) DEFAULT NULL,
  src_bill_type varchar(100) DEFAULT NULL,
  src_bill_id bigint DEFAULT NULL,
  cust_id bigint DEFAULT NULL,
  org_id bigint DEFAULT NULL,
  curr_id bigint DEFAULT NULL,
  b_curr_rate decimal(16,8) DEFAULT NULL,
  amount decimal(19,6) DEFAULT NULL,
  no_tax_amount decimal(19,6) DEFAULT NULL,
  tax_amount decimal(19,6) DEFAULT NULL,
  settled_amount decimal(19,6) DEFAULT '0',
  discount_amount decimal(19,6) DEFAULT '0',
  balance decimal(19,6) DEFAULT NULL,
  due_date date DEFAULT NULL,
  bill_date date DEFAULT NULL,
  status varchar(50) DEFAULT NULL,
  voucher_id bigint DEFAULT NULL,
  brand_id bigint DEFAULT NULL,
  end_cust_id bigint DEFAULT NULL,
  dept_id bigint DEFAULT NULL,
  saler_id bigint DEFAULT NULL,
  cny_rate decimal(16,8) DEFAULT NULL,
  usd_rate decimal(16,8) DEFAULT NULL,
  remark CLOB,
  is_init int DEFAULT '0',
  document_type int DEFAULT NULL,
  pact_state int DEFAULT '1',
  is_closed int DEFAULT '0',
  is_cancel int DEFAULT '0',
  wf_request_id bigint DEFAULT NULL,
  reject_by varchar(200) DEFAULT NULL,
  reject_time TIMESTAMP DEFAULT NULL,
  reject_reason varchar(3000) DEFAULT NULL,
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  auditor varchar(200) DEFAULT NULL,
  audit_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id)
);

-- fin_ap：应付单
CREATE TABLE fin_ap (
  id bigint NOT NULL,
  code varchar(200) DEFAULT NULL,
  src_bill_type varchar(100) DEFAULT NULL,
  src_bill_id bigint DEFAULT NULL,
  supplier_id bigint DEFAULT NULL,
  org_id bigint DEFAULT NULL,
  curr_id bigint DEFAULT NULL,
  b_curr_rate decimal(16,8) DEFAULT NULL,
  amount decimal(19,6) DEFAULT NULL,
  no_tax_amount decimal(19,6) DEFAULT NULL,
  tax_amount decimal(19,6) DEFAULT NULL,
  settled_amount decimal(19,6) DEFAULT '0',
  balance decimal(19,6) DEFAULT NULL,
  due_date date DEFAULT NULL,
  bill_date date DEFAULT NULL,
  status varchar(50) DEFAULT NULL,
  voucher_id bigint DEFAULT NULL,
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id)
);

-- fin_receipt：收款单主表
CREATE TABLE fin_receipt (
  id bigint NOT NULL,
  code varchar(200) DEFAULT NULL,
  receipt_date date DEFAULT NULL,
  pact_state int DEFAULT '0',
  cust_id bigint DEFAULT NULL,
  org_id bigint DEFAULT NULL,
  curr_id bigint DEFAULT NULL,
  b_curr_rate decimal(16,8) DEFAULT NULL,
  amount decimal(19,6) DEFAULT NULL,
  firp_type varchar(200) DEFAULT NULL,
  bank_account varchar(200) DEFAULT NULL,
  is_pre int DEFAULT '0',
  voucher_id bigint DEFAULT NULL,
  dept_id bigint DEFAULT NULL,
  saler_id bigint DEFAULT NULL,
  cny_rate decimal(16,8) DEFAULT NULL,
  usd_rate decimal(16,8) DEFAULT NULL,
  total_amount decimal(19,6) DEFAULT NULL,
  has_bill_amount decimal(19,6) DEFAULT '0',
  waitbill_amount decimal(19,6) DEFAULT NULL,
  custreturn_detail_id bigint DEFAULT NULL,
  payment_purp varchar(255) DEFAULT NULL,
  payment_type varchar(1) DEFAULT NULL,
  is_closed int DEFAULT '0',
  is_cancel int DEFAULT '0',
  wf_request_id bigint DEFAULT NULL,
  reject_by varchar(200) DEFAULT NULL,
  reject_time TIMESTAMP DEFAULT NULL,
  reject_reason varchar(3000) DEFAULT NULL,
  remark CLOB,
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  auditor varchar(200) DEFAULT NULL,
  audit_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id)
);

-- fin_receipt_detail：收款核销明细
CREATE TABLE fin_receipt_detail (
  id bigint NOT NULL,
  sort_index int DEFAULT NULL,
  receipt_id bigint DEFAULT NULL,
  ar_id bigint DEFAULT NULL,
  settle_amount decimal(19,6) DEFAULT NULL,
  discount_amount decimal(19,6) DEFAULT NULL,
  exchange_diff decimal(19,6) DEFAULT NULL,
  PRIMARY KEY (id)
);

-- fin_payment：付款单主表
CREATE TABLE fin_payment (
  id bigint NOT NULL,
  code varchar(200) DEFAULT NULL,
  payment_date date DEFAULT NULL,
  pact_state int DEFAULT '0',
  supplier_id bigint DEFAULT NULL,
  org_id bigint DEFAULT NULL,
  curr_id bigint DEFAULT NULL,
  b_curr_rate decimal(16,8) DEFAULT NULL,
  amount decimal(19,6) DEFAULT NULL,
  pay_type varchar(200) DEFAULT NULL,
  bank_account varchar(200) DEFAULT NULL,
  is_pre int DEFAULT '0',
  voucher_id bigint DEFAULT NULL,
  is_closed int DEFAULT '0',
  is_cancel int DEFAULT '0',
  remark CLOB,
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  auditor varchar(200) DEFAULT NULL,
  audit_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id)
);

-- fin_payment_detail：付款核销明细
CREATE TABLE fin_payment_detail (
  id bigint NOT NULL,
  sort_index int DEFAULT NULL,
  payment_id bigint DEFAULT NULL,
  ap_id bigint DEFAULT NULL,
  settle_amount decimal(19,6) DEFAULT NULL,
  exchange_diff decimal(19,6) DEFAULT NULL,
  PRIMARY KEY (id)
);

-- fin_writeoff：核销记录
CREATE TABLE fin_writeoff (
  id bigint NOT NULL,
  code varchar(200) DEFAULT NULL,
  writeoff_date date DEFAULT NULL,
  biz_type varchar(50) DEFAULT NULL,
  rec_bill_type varchar(100) DEFAULT NULL,
  rec_bill_id bigint DEFAULT NULL,
  ar_ap_id bigint DEFAULT NULL,
  settle_amount decimal(19,6) DEFAULT NULL,
  discount_amount decimal(19,6) DEFAULT NULL,
  exchange_diff decimal(19,6) DEFAULT NULL,
  status varchar(50) DEFAULT NULL,
  pact_state int DEFAULT '1',
  org_id bigint DEFAULT NULL,
  cust_id bigint DEFAULT NULL,
  saler_id bigint DEFAULT NULL,
  curr_id bigint DEFAULT NULL,
  local_curr_id bigint DEFAULT NULL,
  b_curr_rate decimal(16,8) DEFAULT NULL,
  cny_rate decimal(16,8) DEFAULT NULL,
  usd_rate decimal(16,8) DEFAULT NULL,
  cur_hx_amount decimal(19,6) DEFAULT NULL,
  hasbill_amount decimal(19,6) DEFAULT NULL,
  user_account_id bigint DEFAULT NULL,
  is_init int DEFAULT '0',
  document_type varchar(200) DEFAULT NULL,
  is_closed int DEFAULT '0',
  is_cancel int DEFAULT '0',
  wf_request_id bigint DEFAULT NULL,
  reject_by varchar(200) DEFAULT NULL,
  reject_time TIMESTAMP DEFAULT NULL,
  reject_reason varchar(3000) DEFAULT NULL,
  remark CLOB,
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  auditor varchar(200) DEFAULT NULL,
  audit_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id)
);

-- ---------------------------------------------------------------------
-- 四、成本核算
-- ---------------------------------------------------------------------

-- fin_cost_collect：成本归集（按生产订单+批次）
CREATE TABLE fin_cost_collect (
  id bigint NOT NULL,
  period_code varchar(20) DEFAULT NULL,
  mfg_order_id bigint DEFAULT NULL,
  batch_no varchar(200) DEFAULT NULL,
  mat_cost decimal(19,6) DEFAULT NULL,
  labor_cost decimal(19,6) DEFAULT NULL,
  mfg_cost decimal(19,6) DEFAULT NULL,
  total_cost decimal(19,6) DEFAULT NULL,
  wip_cost decimal(19,6) DEFAULT NULL,
  qty decimal(19,6) DEFAULT NULL,
  unit_cost decimal(19,6) DEFAULT NULL,
  std_cost decimal(19,6) DEFAULT NULL,
  variance decimal(19,6) DEFAULT NULL,
  status varchar(50) DEFAULT NULL,
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id)
);

-- fin_mfg_cost_pool：制造费用池
CREATE TABLE fin_mfg_cost_pool (
  id bigint NOT NULL,
  period_code varchar(20) DEFAULT NULL,
  workshop_id bigint DEFAULT NULL,
  cost_item varchar(50) DEFAULT NULL,
  amount decimal(19,6) DEFAULT NULL,
  alloc_base varchar(50) DEFAULT NULL,
  total_base decimal(19,6) DEFAULT NULL,
  alloc_rate decimal(16,8) DEFAULT NULL,
  voucher_id bigint DEFAULT NULL,
  PRIMARY KEY (id)
);

-- fin_cost_variance：成本差异明细
CREATE TABLE fin_cost_variance (
  id bigint NOT NULL,
  period_code varchar(20) DEFAULT NULL,
  mfg_order_id bigint DEFAULT NULL,
  variance_type varchar(50) DEFAULT NULL,
  std_value decimal(19,6) DEFAULT NULL,
  actual_value decimal(19,6) DEFAULT NULL,
  variance_amount decimal(19,6) DEFAULT NULL,
  alloc_to_stock decimal(19,6) DEFAULT NULL,
  alloc_to_cogs decimal(19,6) DEFAULT NULL,
  PRIMARY KEY (id)
);

-- ---------------------------------------------------------------------
-- 五、回款、调汇与银企直连
-- ---------------------------------------------------------------------

-- fin_cust_receipt：客户回款单主表
CREATE TABLE fin_cust_receipt (
  id bigint NOT NULL,
  code varchar(200) DEFAULT NULL,
  pact_date date DEFAULT NULL,
  pact_state int DEFAULT '0',
  sal_org_id bigint DEFAULT NULL,
  cust_id bigint DEFAULT NULL,
  curr_id bigint DEFAULT NULL,
  b_curr_rate decimal(16,8) DEFAULT NULL,
  cny_rate decimal(16,8) DEFAULT NULL,
  usd_rate decimal(16,8) DEFAULT NULL,
  rec_type varchar(200) DEFAULT NULL,
  rec_amount decimal(19,6) DEFAULT NULL,
  claim_amount decimal(19,6) DEFAULT NULL,
  unclaim_amount decimal(19,6) DEFAULT NULL,
  remark CLOB,
  is_closed int DEFAULT '0',
  closed_by varchar(200) DEFAULT NULL,
  closed_time TIMESTAMP DEFAULT NULL,
  is_cancel int DEFAULT '0',
  cancel_by varchar(200) DEFAULT NULL,
  cancel_time TIMESTAMP DEFAULT NULL,
  wf_request_id bigint DEFAULT NULL,
  reject_by varchar(200) DEFAULT NULL,
  reject_time TIMESTAMP DEFAULT NULL,
  reject_reason varchar(3000) DEFAULT NULL,
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  auditor varchar(200) DEFAULT NULL,
  audit_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id)
);

-- fin_cust_receipt_detail：客户回款单明细
CREATE TABLE fin_cust_receipt_detail (
  id bigint NOT NULL,
  cust_receipt_id bigint DEFAULT NULL,
  saler_id bigint DEFAULT NULL,
  dept_id bigint DEFAULT NULL,
  claim_date date DEFAULT NULL,
  claim_amount decimal(19,6) DEFAULT NULL,
  record_id bigint DEFAULT NULL,
  record_code varchar(200) DEFAULT NULL,
  payment_purp varchar(200) DEFAULT NULL,
  claim_state varchar(200) DEFAULT NULL,
  is_overtime int DEFAULT '0',
  is_closed int DEFAULT '0',
  closed_by varchar(200) DEFAULT NULL,
  closed_time TIMESTAMP DEFAULT NULL,
  is_cancel int DEFAULT '0',
  cancel_by varchar(200) DEFAULT NULL,
  cancel_time TIMESTAMP DEFAULT NULL,
  sort_index int DEFAULT NULL,
  remark CLOB,
  PRIMARY KEY (id)
);

-- fin_fx_adjust：调汇单主表
CREATE TABLE fin_fx_adjust (
  id bigint NOT NULL,
  code varchar(200) DEFAULT NULL,
  pact_date date DEFAULT NULL,
  pact_state int DEFAULT '0',
  org_id bigint DEFAULT NULL,
  curr_id bigint DEFAULT NULL,
  d_curr_id bigint DEFAULT NULL,
  parities_type varchar(200) DEFAULT NULL,
  orig_rate decimal(16,8) DEFAULT NULL,
  rate_adj decimal(16,8) DEFAULT NULL,
  rate_adj_year decimal(16,8) DEFAULT NULL,
  rate_adj_month decimal(16,8) DEFAULT NULL,
  total_exchange_diff decimal(19,6) DEFAULT NULL,
  remark CLOB,
  wf_request_id bigint DEFAULT NULL,
  reject_by varchar(200) DEFAULT NULL,
  reject_time TIMESTAMP DEFAULT NULL,
  reject_reason varchar(3000) DEFAULT NULL,
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  auditor varchar(200) DEFAULT NULL,
  audit_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id)
);

-- fin_fx_adjust_detail：调汇单明细
CREATE TABLE fin_fx_adjust_detail (
  id bigint NOT NULL,
  fx_adjust_id bigint DEFAULT NULL,
  sort_index int DEFAULT NULL,
  cust_id bigint DEFAULT NULL,
  saler_id bigint DEFAULT NULL,
  dept_id bigint DEFAULT NULL,
  curr_sum decimal(19,6) DEFAULT NULL,
  d_curr_sum decimal(19,6) DEFAULT NULL,
  d_currchange_sum decimal(19,6) DEFAULT NULL,
  rate_adj_sum decimal(19,6) DEFAULT NULL,
  exchange_diff decimal(19,6) DEFAULT NULL,
  cny_sum decimal(19,6) DEFAULT NULL,
  cust_code varchar(200) DEFAULT NULL,
  saler_code varchar(200) DEFAULT NULL,
  dept_code varchar(200) DEFAULT NULL,
  PRIMARY KEY (id)
);

-- fin_bank_pay：银企直连收付
CREATE TABLE fin_bank_pay (
  id bigint NOT NULL,
  code varchar(200) DEFAULT NULL,
  pact_date date DEFAULT NULL,
  pact_state int DEFAULT '0',
  payment int DEFAULT NULL,
  payment_status varchar(200) DEFAULT NULL,
  trans_date TIMESTAMP DEFAULT NULL,
  trans_time varchar(100) DEFAULT NULL,
  trans_amount decimal(19,6) DEFAULT NULL,
  curr_name varchar(200) DEFAULT NULL,
  ident_curr_id bigint DEFAULT NULL,
  trans_comp varchar(200) DEFAULT NULL,
  ident_cust_id bigint DEFAULT NULL,
  bank varchar(200) DEFAULT NULL,
  account_name varchar(200) DEFAULT NULL,
  account_no varchar(200) DEFAULT NULL,
  trans_serial_no varchar(200) DEFAULT NULL,
  trans_account_no varchar(200) DEFAULT NULL,
  trans_bank varchar(200) DEFAULT NULL,
  row_guid varchar(200) DEFAULT NULL,
  is_closed int DEFAULT '0',
  is_cancel int DEFAULT '0',
  wf_request_id bigint DEFAULT NULL,
  reject_by varchar(200) DEFAULT NULL,
  reject_time TIMESTAMP DEFAULT NULL,
  reject_reason varchar(3000) DEFAULT NULL,
  remark CLOB,
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  auditor varchar(200) DEFAULT NULL,
  audit_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id)
);


-- ============================================================
-- 07-税务管理表
-- ============================================================

-- =====================================================================
-- 07-税务管理业务表
-- 说明：销项发票（与sal_invoice复用，此处为税务视角补充）、进项发票（与pur_invoice复用）、
--       税率配置、税务计提、纳税申报。
-- 说明：销售/采购发票已在 02/03 文件定义，本文件聚焦税务专属配置与计提申报表。
-- 命名约定：表前缀 tax_
-- =====================================================================

-- ---------------------------------------------------------------------
-- 一、税率配置
-- ---------------------------------------------------------------------

-- tax_rate_config：税率配置
CREATE TABLE tax_rate_config (
  id bigint NOT NULL,
  org_id bigint DEFAULT NULL,
  mat_category varchar(100) DEFAULT NULL,
  tax_type varchar(50) DEFAULT NULL,
  tax_rate decimal(16,8) DEFAULT NULL,
  valid_start date DEFAULT NULL,
  valid_end date DEFAULT NULL,
  special_flag varchar(50) DEFAULT NULL,
  remark CLOB,
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id)
);

-- ---------------------------------------------------------------------
-- 二、税务计提
-- ---------------------------------------------------------------------

-- tax_accrual：税务计提主表
CREATE TABLE tax_accrual (
  id bigint NOT NULL,
  code varchar(200) DEFAULT NULL,
  period_code varchar(20) DEFAULT NULL,
  org_id bigint DEFAULT NULL,
  pact_state int DEFAULT '0',
  total_amount decimal(19,6) DEFAULT NULL,
  voucher_id bigint DEFAULT NULL,
  is_closed int DEFAULT '0',
  remark CLOB,
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  auditor varchar(200) DEFAULT NULL,
  audit_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id)
);

-- tax_accrual_detail：税务计提明细
CREATE TABLE tax_accrual_detail (
  id bigint NOT NULL,
  sort_index int DEFAULT NULL,
  accrual_id bigint DEFAULT NULL,
  tax_type varchar(50) DEFAULT NULL,
  base_amount decimal(19,6) DEFAULT NULL,
  tax_rate decimal(16,8) DEFAULT NULL,
  tax_amount decimal(19,6) DEFAULT NULL,
  deduct_amount decimal(19,6) DEFAULT NULL,
  payable_amount decimal(19,6) DEFAULT NULL,
  remark CLOB,
  PRIMARY KEY (id)
);

-- ---------------------------------------------------------------------
-- 三、纳税申报
-- ---------------------------------------------------------------------

-- tax_declaration：纳税申报主表
CREATE TABLE tax_declaration (
  id bigint NOT NULL,
  code varchar(200) DEFAULT NULL,
  period_code varchar(20) DEFAULT NULL,
  org_id bigint DEFAULT NULL,
  declaration_type varchar(50) DEFAULT NULL,
  declare_date date DEFAULT NULL,
  pact_state int DEFAULT '0',
  total_amount decimal(19,6) DEFAULT NULL,
  data_json CLOB,
  file_url varchar(500) DEFAULT NULL,
  submit_status varchar(50) DEFAULT NULL,
  remark CLOB,
  create_by varchar(200) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  update_by varchar(200) DEFAULT NULL,
  update_time TIMESTAMP DEFAULT NULL,
  auditor varchar(200) DEFAULT NULL,
  audit_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id)
);

-- tax_declaration_history：申报历史明细（留痕）
CREATE TABLE tax_declaration_history (
  id bigint NOT NULL,
  declaration_id bigint DEFAULT NULL,
  op_type varchar(50) DEFAULT NULL,
  op_amount decimal(19,6) DEFAULT NULL,
  op_by varchar(200) DEFAULT NULL,
  op_time TIMESTAMP DEFAULT NULL,
  op_remark CLOB,
  PRIMARY KEY (id)
);

-- ---------------------------------------------------------------------
-- 四、发票税务辅助表（认证台账）
-- ---------------------------------------------------------------------

-- tax_invoice_certify：发票认证台账（进项认证抵扣记录）
CREATE TABLE tax_invoice_certify (
  id bigint NOT NULL,
  invoice_type varchar(50) DEFAULT NULL,
  src_bill_type varchar(100) DEFAULT NULL,
  src_bill_id bigint DEFAULT NULL,
  invoice_code varchar(100) DEFAULT NULL,
  invoice_no varchar(100) DEFAULT NULL,
  invoice_date date DEFAULT NULL,
  supplier_id bigint DEFAULT NULL,
  tax_amount decimal(19,6) DEFAULT NULL,
  deduct_amount decimal(19,6) DEFAULT NULL,
  certify_status varchar(50) DEFAULT NULL,
  certify_date date DEFAULT NULL,
  certify_period varchar(20) DEFAULT NULL,
  is_agri int DEFAULT '0',
  remark CLOB,
  create_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id)
);

-- tax_output_summary：销项汇总（按期间汇总销项税）
CREATE TABLE tax_output_summary (
  id bigint NOT NULL,
  period_code varchar(20) DEFAULT NULL,
  org_id bigint DEFAULT NULL,
  cust_id bigint DEFAULT NULL,
  invoice_count int DEFAULT NULL,
  no_tax_amount decimal(19,6) DEFAULT NULL,
  tax_amount decimal(19,6) DEFAULT NULL,
  total_amount decimal(19,6) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id)
);

-- tax_input_summary：进项汇总（按期间汇总进项税）
CREATE TABLE tax_input_summary (
  id bigint NOT NULL,
  period_code varchar(20) DEFAULT NULL,
  org_id bigint DEFAULT NULL,
  supplier_id bigint DEFAULT NULL,
  invoice_count int DEFAULT NULL,
  no_tax_amount decimal(19,6) DEFAULT NULL,
  tax_amount decimal(19,6) DEFAULT NULL,
  deduct_amount decimal(19,6) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id)
);

-- tax_vat_calc：增值税计算（应纳税额 = 销项 - 进项）
CREATE TABLE tax_vat_calc (
  id bigint NOT NULL,
  period_code varchar(20) DEFAULT NULL,
  org_id bigint DEFAULT NULL,
  output_tax decimal(19,6) DEFAULT NULL,
  input_tax decimal(19,6) DEFAULT NULL,
  input_transferred decimal(19,6) DEFAULT NULL,
  deduct_tax decimal(19,6) DEFAULT NULL,
  payable_tax decimal(19,6) DEFAULT NULL,
  tax_burden_rate decimal(16,8) DEFAULT NULL,
  create_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE (period_code,org_id)
);


-- ============================================================
-- 10-消息预警表
-- ============================================================

-- =====================================================================
-- 10-消息与预警表（业务预警规则、预警记录、站内信、邮件日志）
-- 命名约定：表前缀 sys_
-- 说明：业务预警规则定义与触发记录、站内消息、邮件发送日志。
-- =====================================================================

-- ---------------------------------------------------------------------
-- 一、预警规则与记录
-- ---------------------------------------------------------------------

-- sys_alert_rule：预警规则
CREATE TABLE sys_alert_rule (
  rule_code varchar(100) NOT NULL,
  rule_name varchar(200) DEFAULT NULL,
  alert_type varchar(50) DEFAULT NULL,
  target_object varchar(100) DEFAULT NULL,
  condition_expr varchar(1000) DEFAULT NULL,
  check_cron varchar(100) DEFAULT NULL,
  notify_target varchar(200) DEFAULT NULL,
  notify_channel varchar(100) DEFAULT NULL,
  is_enabled SMALLINT NOT NULL DEFAULT 1,
  remark varchar(500) DEFAULT NULL,
  PRIMARY KEY (rule_code)
);

-- sys_alert_log：预警记录
CREATE TABLE sys_alert_log (
  alert_id bigint NOT NULL,
  rule_code varchar(100) DEFAULT NULL,
  alert_type varchar(50) DEFAULT NULL,
  target_id bigint DEFAULT NULL,
  target_desc varchar(500) DEFAULT NULL,
  alert_content varchar(2000) DEFAULT NULL,
  alert_time TIMESTAMP DEFAULT NULL,
  alert_level varchar(20) DEFAULT NULL,
  is_read SMALLINT NOT NULL DEFAULT 0,
  is_handled SMALLINT NOT NULL DEFAULT 0,
  handle_by bigint DEFAULT NULL,
  handle_time TIMESTAMP DEFAULT NULL,
  handle_remark varchar(1000) DEFAULT NULL,
  status varchar(20) DEFAULT NULL,
  PRIMARY KEY (alert_id)
);

-- ---------------------------------------------------------------------
-- 二、站内信
-- ---------------------------------------------------------------------

-- sys_message：站内信
CREATE TABLE sys_message (
  message_id bigint NOT NULL,
  user_id bigint NOT NULL,
  message_type varchar(20) DEFAULT NULL,
  title varchar(200) DEFAULT NULL,
  content varchar(2000) DEFAULT NULL,
  ref_bill_type varchar(50) DEFAULT NULL,
  ref_bill_id bigint DEFAULT NULL,
  is_read SMALLINT NOT NULL DEFAULT 0,
  read_time TIMESTAMP DEFAULT NULL,
  create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  expire_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (message_id)
);

-- ---------------------------------------------------------------------
-- 三、邮件日志
-- ---------------------------------------------------------------------

-- sys_mail_log：邮件日志
CREATE TABLE sys_mail_log (
  mail_id bigint NOT NULL,
  to_email varchar(500) NOT NULL,
  subject varchar(500) DEFAULT NULL,
  content CLOB,
  ref_bill_type varchar(50) DEFAULT NULL,
  ref_bill_id bigint DEFAULT NULL,
  send_time TIMESTAMP DEFAULT NULL,
  send_status varchar(20) DEFAULT NULL,
  error_msg varchar(2000) DEFAULT NULL,
  PRIMARY KEY (mail_id)
);


-- ============================================================
-- 10-系统管理表
-- ============================================================

-- =====================================================================
-- 10-系统管理表（系统参数、公告、备份、任务调度、数据字典、导入任务）
-- 命名约定：表前缀 sys_
-- 说明：系统级配置、运维管理、数据字典与定时任务调度。
-- =====================================================================

-- ---------------------------------------------------------------------
-- 一、系统参数
-- ---------------------------------------------------------------------

-- sys_param：系统参数
CREATE TABLE sys_param (
  param_code varchar(100) NOT NULL,
  param_name varchar(200) NOT NULL,
  param_value varchar(1000) DEFAULT NULL,
  param_type varchar(20) DEFAULT NULL,
  param_group varchar(50) DEFAULT NULL,
  default_value varchar(1000) DEFAULT NULL,
  is_system SMALLINT NOT NULL DEFAULT 0,
  remark varchar(500) DEFAULT NULL,
  update_by bigint DEFAULT NULL,
  update_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (param_code)
);

-- ---------------------------------------------------------------------
-- 二、公告管理
-- ---------------------------------------------------------------------

-- sys_notice：公告
CREATE TABLE sys_notice (
  notice_id bigint NOT NULL,
  title varchar(200) NOT NULL,
  content CLOB,
  notice_type varchar(20) DEFAULT NULL,
  publish_by bigint DEFAULT NULL,
  publish_time TIMESTAMP DEFAULT NULL,
  expire_time TIMESTAMP DEFAULT NULL,
  is_top SMALLINT NOT NULL DEFAULT 0,
  is_read_required SMALLINT NOT NULL DEFAULT 0,
  status SMALLINT NOT NULL DEFAULT 0,
  PRIMARY KEY (notice_id)
);

-- sys_notice_read：公告阅读记录
CREATE TABLE sys_notice_read (
  id bigint NOT NULL,
  notice_id bigint NOT NULL,
  user_id bigint NOT NULL,
  read_time TIMESTAMP DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE (notice_id,user_id)
);

-- ---------------------------------------------------------------------
-- 三、数据备份
-- ---------------------------------------------------------------------

-- sys_backup：数据备份
CREATE TABLE sys_backup (
  backup_id bigint NOT NULL,
  backup_type varchar(20) NOT NULL,
  backup_time TIMESTAMP DEFAULT NULL,
  file_path varchar(500) DEFAULT NULL,
  file_size bigint DEFAULT NULL,
  status varchar(20) DEFAULT NULL,
  operator varchar(200) DEFAULT NULL,
  PRIMARY KEY (backup_id)
);

-- ---------------------------------------------------------------------
-- 四、任务调度
-- ---------------------------------------------------------------------

-- sys_schedule：定时任务
CREATE TABLE sys_schedule (
  schedule_code varchar(100) NOT NULL,
  schedule_name varchar(200) DEFAULT NULL,
  cron varchar(100) DEFAULT NULL,
  target_type varchar(20) DEFAULT NULL,
  target varchar(500) DEFAULT NULL,
  params varchar(1000) DEFAULT NULL,
  is_enabled SMALLINT NOT NULL DEFAULT 1,
  last_run_time TIMESTAMP DEFAULT NULL,
  last_run_status varchar(20) DEFAULT NULL,
  next_run_time TIMESTAMP DEFAULT NULL,
  remark varchar(500) DEFAULT NULL,
  PRIMARY KEY (schedule_code)
);

-- sys_schedule_log：任务执行日志
CREATE TABLE sys_schedule_log (
  id bigint NOT NULL,
  schedule_code varchar(100) NOT NULL,
  run_time TIMESTAMP DEFAULT NULL,
  run_status varchar(20) DEFAULT NULL,
  duration int DEFAULT NULL,
  error_msg varchar(2000) DEFAULT NULL,
  log CLOB,
  PRIMARY KEY (id)
);

-- ---------------------------------------------------------------------
-- 五、数据字典
-- ---------------------------------------------------------------------

-- sys_dict：数据字典
CREATE TABLE sys_dict (
  dict_code varchar(100) NOT NULL,
  dict_name varchar(200) DEFAULT NULL,
  table_name varchar(100) DEFAULT NULL,
  field_name varchar(100) DEFAULT NULL,
  field_type varchar(50) DEFAULT NULL,
  field_length int DEFAULT NULL,
  field_comment varchar(200) DEFAULT NULL,
  is_enum SMALLINT NOT NULL DEFAULT 1,
  status SMALLINT NOT NULL DEFAULT 1,
  PRIMARY KEY (dict_code)
);

-- sys_dict_item：字典枚举项
CREATE TABLE sys_dict_item (
  id bigint NOT NULL,
  dict_code varchar(100) NOT NULL,
  item_value varchar(100) DEFAULT NULL,
  item_name varchar(200) DEFAULT NULL,
  sort_order int DEFAULT '0',
  is_default SMALLINT NOT NULL DEFAULT 0,
  PRIMARY KEY (id)
);

