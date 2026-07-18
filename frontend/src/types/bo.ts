// BOS 平台核心类型定义 - 依据 PRD 01-平台基座 8 个模块 + 表结构 00-平台元数据表.sql

// ============ 通用 ============
export interface ApiResponse<T = any> {
  code: number
  message: string
  data: T
}

export interface PageResult<T = any> {
  list: T[]
  total: number
  pageNum: number
  pageSize: number
}

// ============ 业务对象（PRD 05）============
export interface BusinessObject {
  id: string
  bo_code: string          // 业务对象编码（全局唯一，保存后不可改）
  bo_name: string          // 业务对象名称
  bo_type: BoType          // 类型：单据/基础资料/报表
  main_table: string       // 主表名
  main_entity_id: string   // 主实体ID
  is_stateful: boolean     // 是否启用状态机
  is_pushable: boolean     // 是否支持下推
  is_printable: boolean    // 是否启用打印
  org_type: string         // 适用组织类型
  pk_strategy: PkStrategy  // 主键策略
  status: 0 | 1            // 0停用 1启用
  remark?: string
  create_by?: string
  create_time?: string
}

// ============ 实体与字段（PRD 05.2 / 01.1）============
export interface FormEntity {
  id: string
  bo_code: string
  entity_code: string      // 实体编码（表名）
  entity_name: string      // 实体名称
  entity_type: EntityType  // main主表/sub子表/grandchild孙表
  entity_level: number     // 实体层级（0主/1子/2孙，与 SQL meta_form_entity.entity_level 对齐）
  parent_entity_code?: string  // 父实体编码（子表/孙表必填）
  link_field?: string      // 关联父实体的外键字段
  sort_index: number
  fields: FormField[]
}

export interface FormField {
  id: string
  entity_code: string
  field_code: string       // 字段编码（即数据库列名）
  field_name: string       // 字段名称
  field_type: FieldType    // 数据类型
  ctrl_type: ControlType   // 控件类型（与 SQL meta_form_field.ctrl_type 对齐）
  data_length?: number     // 长度（与 SQL meta_form_field.data_length 对齐）
  data_precision?: number  // 精度（总位数，与 SQL meta_form_field.data_precision 对齐）
  data_scale?: number      // 小数位（与 SQL meta_form_field.data_scale 对齐）
  is_required: boolean
  is_system: boolean       // 系统预置字段不可删
  is_hidden: boolean       // 是否隐藏
  default_value?: string
  ref_bo_code?: string     // 基础资料引用的目标业务对象
  enum_code?: string       // 枚举编码
  sort_index: number
  group_name?: string      // 字段分组
  validate_rule?: string   // 校验规则表达式
  formula?: string         // 计算公式（如 qty*price，由实体服务规则 calc 类型执行，与 SQL meta_form_field.formula 对齐）
  summary_to?: string      // 汇总到主表字段（如 amount 汇总到 total_amount，与 SQL meta_form_field.summary_to 对齐）
  placeholder?: string
}

// ============ 状态机（PRD 02）============
export interface StateNode {
  id: string
  bo_code: string
  state_code: number       // 0暂存 1已创建 2已提交 3已审核 4已驳回（自定义状态码可 >=5）
  state_name: string
  color?: string           // 状态色 hex（与 SQL meta_state_node.state_color 对齐，按 state_value 动态映射，GAP-D03-005 / RISK-D03-002）
  is_initial: boolean
  is_final: boolean
  pos_x?: number           // 节点画布 X 坐标（GAP-D03-004 / RISK-D03-003）
  pos_y?: number           // 节点画布 Y 坐标（GAP-D03-004 / RISK-D03-003）
  sort_index: number
}

export interface StateTransition {
  id: string
  bo_code: string
  from_state: number
  to_state: number
  action_name: string      // 操作名（保存/提交/审核/驳回/撤销）
  pre_check?: string       // 前置校验表达式
  post_action?: string     // 后置动作
  need_wf: boolean         // 是否触发外部工作流
  // 外部工作流对接配置（GAP-D03-008 / PRD 02.1.3）
  wf_push_api?: string     // 工作流推送 API 地址（need_wf=true 时配置，如 /api/wf/start）
  wf_callback_url?: string // 工作流回调展示 URL（外部系统回调 ERP 的接口路径，如 /api/wf/callback）
  wf_callback_display?: string // 回调展示字段（如 wf_request_id / pact_state 回写规则说明）
}

// ============ 按钮（PRD 02.7 / 04.4）============
export interface ButtonDef {
  id: string
  bo_code: string
  button_code: string      // save/submit/audit/reject/revoke/delete/close/cancel/change/push/print/copy...
  button_name: string
  icon?: string
  position: 'form' | 'list' | 'both'
  sort_index: number
  is_custom: boolean       // 是否自定义按钮
  need_confirm: boolean    // 是否二次确认
  bind_plugin?: string     // 绑定的插件 code（OnCustomButtonClick）
  // 可用性矩阵：Record<state_code, ButtonAvailability>（按状态码索引，防越界，RISK-D03-001）
  // 序列化为 JSON 时键为 state_code 字符串；原型内存中保留为数组以兼容 0-4 标准状态
  availability: ButtonAvailability[]
}

export type ButtonAvailability = 'enabled' | 'disabled' | 'hidden' | 'readonly'

// ============ 下推规则（PRD 02.3）============
export interface PushRule {
  id: string
  rule_code: string
  rule_name: string
  src_bo_code: string      // 源业务对象
  target_bo_code: string   // 目标业务对象
  field_mappings: PushFieldMapping[]
  vp_check_expr?: string   // 可下推量校验表达式
  filter_expr?: string     // 过滤条件
  qty_field?: string       // 可下推数量字段（如 qty，GAP-D04-001 / PRD 02.3.3）
  pushed_field?: string    // 已下推量回写字段（如 out_qty，GAP-D04-001 / PRD 02.3.3）
  allow_merge: boolean     // 允许合并下推
  allow_split: boolean     // 允许拆分下推
  status: 0 | 1            // 0停用 1启用
}

export interface PushFieldMapping {
  src_field: string
  target_field: string
  is_main: boolean         // 主表映射 or 子表映射
  transform_expr?: string  // 转换表达式
}

// ============ 编码规则（PRD 06.1）============
export interface CodeRule {
  id: string
  rule_code: string
  rule_name: string
  bo_code: string
  org_id?: string
  segments: CodeSegment[]  // 段定义
  reset_type: ResetType    // 流水重置类型
  is_manual: boolean       // 是否允许手动录入
  status: 0 | 1            // 0停用 1启用
}

export interface CodeSegment {
  id: string
  rule_id: string
  type: SegmentType        // prefix/date/serial/fixed/variable（与 PRD 6.1.6 / SQL meta_code_rule.segments_json 对齐）
  value?: string           // prefix/fixed 的值
  format?: string          // date 段格式 yyyyMMdd/yyyyMM/yyyy
  digits?: number          // serial 流水位数
  var_code?: string        // variable 变量编码
  sort: number             // 段顺序
}

// ============ 插件（PRD 01.4 / 06.2，参考金蝶BOS插件机制）============
// 系统三大插件基类（参考金蝶 AbstractBillPlugIn / AbstractListPlugIn / AbstractOperationServicePlugIn）
export type PluginBaseClass = 'BillPlugin' | 'ListPlugin' | 'OperationServicePlugin'

// 插件运行上下文（参考金蝶 this.View / this.View.Model / this.Context / this.Option）
// 系统基类在 execute(Ctx) 时将以下信息注入 PluginContext，子类通过 ctx 访问
export interface PluginContext {
  bo_code: string                          // 业务对象编码（this.BusinessInfo）
  bo_name: string
  operation: string                        // 当前操作 save/submit/audit...
  // —— this.Context：当前用户与组织
  user_id: string
  user_name: string
  org_id: string
  org_name: string
  // —— this.View.Model：单据数据包（主表+子表+孙表）
  bill_id: string
  bill_code: string
  bill_data: Record<string, any>
  // —— this.Option：表单参数（单据字段值）+ 行为参数（控制执行逻辑）
  form_params: Record<string, any>
  behavior_params: Record<string, any>
}

// 插件执行结果
export interface PluginResult {
  success: boolean
  blocked: boolean        // 是否阻断后续插件与主操作
  message?: string
  data?: any
}

// 传入插件类的参数（自描述模型 + 参数零配置：全部由系统反射扫描 @FormParam / @BehaviorParam 注解自动发现，
// 运行时系统自动注入——form 类型读取 bill_data[param_key]，behavior 类型注入 default_value，管理员无需配置）
export interface ClassPluginParam {
  param_key: string                       // 参数键（注解自动发现）：form 类型=单据字段编码（运行时读取 bill_data[param_key]）；behavior 类型=参数名
  param_label: string                     // 参数标签（注解自动发现，来自注解 label 属性）
  param_type: 'form' | 'behavior'         // 参数类型（注解自动发现）：form=@FormParam(运行时取单据字段值), behavior=@BehaviorParam(运行时取 default_value)
  default_value?: string                  // 运行时值（注解自动发现，来自 @BehaviorParam.defaultValue，如 block）；form 类型为空
}

// Java 类插件反射元数据（上传 .class/.jar 后系统反射自动识别，对应 PRD 06 6.2.4.1 自描述模型）
export interface ClassPluginMeta {
  base_class: PluginBaseClass             // 系统基类（反射 superclass 链识别）
  class_base: string                      // 基类全限定名（反射识别）
  class_name: string                      // 实现类全限定名（反射识别）
  class_params: ClassPluginParam[]        // 参数结构（反射扫描注解自动发现，参数零配置，运行时系统自动注入）
  // RISK-D05-001 / PRD 06.2.4.1：签名校验结果（true=已签名/受信任，false=未签名/不可信）
  // 未签名 .class/.jar 上传时系统弹窗警告，管理员确认后可继续上传但运行时按沙箱执行
  signature_valid?: boolean
  // RISK-D05-002 / PRD 06.2.4.1：反射扫描后字段存在性校验提示
  // @FormParam.key 引用的字段不在当前 BO 字段清单时产生告警（不阻断上传，仅提示管理员核对）
  warnings?: string[]
}

// 校验器（参考金蝶 onAddValidators，操作服务插件可挂自定义校验器）
export interface PluginValidator {
  validator_code: string
  validator_name: string
  validator_class?: string  // 校验器实现类（继承 AbstractValidator），可选
  validate_expr?: string    // 校验表达式（脚本型校验器）
  error_msg?: string        // 校验失败提示
  is_enabled: boolean
}

export interface FormPlugin {
  id: string
  bo_code: string
  plugin_code: string
  plugin_name: string
  // 插件类型：脚本(ANTLR表达式) / API(HTTP) / Java类(继承系统基类)
  plugin_type: 'script' | 'api' | 'class'
  // 系统基类（参考金蝶三大基类，决定可绑定事件与运行时上下文）
  base_class: PluginBaseClass
  // 绑定事件（按基类过滤：表单插件用 BillPluginEvent，操作服务插件用 OperationPipelineEvent）
  event_name: string
  field_code?: string        // 字段级事件触发字段（如 DataChanged 的触发字段）

  script_content?: string    // 脚本内容
  api_url?: string           // API 地址
  api_method?: 'GET' | 'POST' | 'PUT'

  // Java class 插件（自描述模型：以下四项由系统上传 .class/.jar 时反射自动识别回填，非用户填写）
  class_name?: string        // 实现类全限定名（系统反射自动识别）
  class_file?: string        // 上传的 .class / .jar 文件路径（系统自动存储）
  class_base?: string        // 基类全限定名（系统反射 superclass 链自动识别）

  // 传入参数（注入 PluginContext.form_params / behavior_params）
  class_params?: ClassPluginParam[]

  // 校验器（操作服务插件 OnAddValidators 阶段挂载）
  validators?: PluginValidator[]

  exec_order: number
  status: 0 | 1              // 0停用 1启用
}

// ============ 实体服务规则（PRD 08.1）============
export interface EntityRule {
  id: string
  rule_code: string
  rule_name: string
  bo_code: string
  entity_code: string
  rule_type: RuleType      // validate/calc/linkage/available
  trigger_event: TriggerEvent
  trigger_field?: string   // 触发字段（字段级事件）
  priority: number
  is_enabled: boolean
  remark?: string
  items: EntityRuleItem[]
}

export interface EntityRuleItem {
  id: string
  rule_id: string
  item_seq: number
  condition_expr: string   // 条件表达式
  action_expr: string      // 动作表达式
  error_msg?: string       // 校验失败提示
}

// ============ 反写规则（PRD 08.2）============
export interface WritebackRule {
  id: string
  rule_code: string
  rule_name: string
  src_bill_type: string    // 下游单据（触发反写）
  target_bill_type: string // 上游单据（被反写）
  trigger_op: 'audit' | 'cancel'
  writeback_mode: WritebackMode  // add/subtract/cover
  over_control: OverControl      // block/warn/allow
  cascade: boolean                // 是否级联反写
  src_link_field: string         // 源单关联字段（下游单据行字段，如 src_order_goods_id）
  target_link_field: string      // 目标单关联字段（上游单据行字段，如 id）
  fields: WritebackField[]
  over_expr?: string             // 超限校验表达式
  condition_expr?: string        // 反写条件
  is_enabled: boolean
}

export interface WritebackField {
  id: string
  rule_id: string
  src_field: string       // 下游单据字段
  target_field: string    // 上游单据字段
  writeback_expr: string  // 反写表达式
}

// ============ 列表与查询（PRD 03）============
export interface ListColumn {
  id: string
  bo_code: string
  field_code: string
  field_name: string
  ctrl_type: ControlType  // 控件类型（与 SQL meta_list_column.ctrl_type 对齐）
  is_show: boolean        // 默认是否展示
  is_fixed: 'none' | 'left' | 'right'
  column_width: number
  sort_index: number
  is_sum: boolean         // 是否合计
  is_avg: boolean
}

export interface QueryField {
  id: string
  bo_code: string
  field_code: string
  field_name: string
  ctrl_type: ControlType  // 控件类型（与 SQL meta_list_column.ctrl_type 对齐）
  is_common: boolean      // 普通查询字段
  is_advanced: boolean    // 高级查询字段
  operators: string[]     // 支持的运算符
  sort_index: number
}

export interface QueryScheme {
  id: string
  scheme_name: string
  bo_code: string
  user_id: string
  is_public: boolean      // 公共/私有
  is_default: boolean
  is_favorite: boolean
  conditions: QueryCondition[]
  columns: string[]       // 展示字段编码
  order_by?: string
  page_size: number
}

export interface QueryCondition {
  field_code: string
  operator: string
  value: any
  logic: 'AND' | 'OR'     // 与上一条件的逻辑
  group?: number           // 括号分组（旧扁平模式）
  // === D09 多级嵌套：条件树（GAP-D09-001）===
  // 当 group_type 为 'group' 时，children 表示子条件/子分组（递归嵌套，支持多级括号）
  group_type?: 'condition' | 'group'
  children?: QueryCondition[]
  // 嵌套层级的逻辑运算符（group 节点与上层节点的逻辑：AND/OR）
  group_logic?: 'AND' | 'OR'
}

// 用户列表设置（GAP-D09-002 / RISK-D09-003：列设置持久化）
export interface UserListSetting {
  id?: string
  user_id: string
  bo_code: string
  columns_json: string  // JSON 字符串：列编码 + 列宽 + 冻结 + 合计 + 排序
  page_size?: number
  update_time?: string
}

// ============ 权限（PRD 04）============
export interface Org {
  id: string
  org_code: string
  org_name: string
  org_type: OrgType
  parent_id?: string
  status: 0 | 1            // 0停用 1启用
  sort_index: number
}

export interface SysUser {
  id: string
  user_code: string
  user_name: string
  org_id: string          // 主组织
  dept_id?: string
  position?: string
  status: 0 | 1            // 0停用 1启用
  role_ids: string[]
  phone?: string
  email?: string
}

export interface Role {
  id: string
  role_code: string
  role_name: string
  parent_role_id?: string  // 角色继承
  remark?: string
  status: 0 | 1            // 0停用 1启用
}

export interface RoleButton {
  role_id: string
  bo_code: string
  button_code: string
  perm: ButtonAvailability  // hidden/readonly/disabled/enabled
}

export interface DataPermissionRule {
  id: string
  role_id: string
  bo_code: string
  dimension: 'org' | 'dept' | 'salesman' | 'customer' | 'supplier' | 'warehouse' | 'workshop'
  scope: DataScope          // self/dept/dept_sub/org/all
  field_code?: string       // 过滤字段编码（如 saler_id，与 SQL data_permission_rule.field_code 对齐，RISK-D11-005）
}

export interface FieldPermission {
  role_id: string
  bo_code: string
  field_code: string
  perm: FieldPerm           // visible/hidden/mask
}

// ============ 集成（PRD 07）============
export interface Attachment {
  id: string
  bill_type: string
  bill_id: string
  file_name: string
  file_size: number
  file_type: string
  file_url: string
  version: number
  upload_by: string
  upload_time: string
  is_deleted: boolean
}

export interface ImportTask {
  id: string
  template_code: string
  file_name: string
  status: 'pending' | 'validating' | 'importing' | 'done' | 'failed'
  total_rows: number
  success_rows: number
  fail_rows: number
  error_log?: string
  create_by: string
  create_time: string
}

export interface ApiLog {
  id: string
  category: string         // wf/mes/qms/report/tax/bank/other
  endpoint: string
  method: string
  request_body?: string
  response_body?: string
  duration: number
  status: 'success' | 'fail'
  error_msg?: string
  create_time: string
}

// ============ 单据运行时（PRD 02.4 / 02.5）============
export interface BillLink {
  id: string
  src_bill_type: string
  src_bill_id: string
  src_bill_code: string
  src_line_id?: string
  target_bill_type: string
  target_bill_id: string
  target_bill_code: string
  target_line_id?: string
  link_type: 'push' | 'manual'  // 下推/手工关联
  qty: number                     // 关联数量
}

export interface ChangeLog {
  id: string
  bill_type: string
  bill_id: string
  change_code: string            // 变更单号
  field_code: string
  field_name: string
  old_value: string
  new_value: string
  change_by: string
  change_time: string
  change_reason: string
  change_state: 0 | 1            // 0待审 1已审
}

// ============ 枚举类型 ============
export type BoType = 'bill' | 'master' | 'report'
export type EntityType = 'main' | 'sub' | 'grandchild'
export type FieldType = 'text' | 'number' | 'date' | 'datetime' | 'enum' | 'ref' | 'bool' | 'amount' | 'qty' | 'attachment'
export type ControlType =
  | 'text' | 'textarea' | 'number' | 'date' | 'datetime'
  | 'select' | 'ref' | 'amount' | 'qty' | 'checkbox' | 'attachment'
export type PkStrategy = 'auto' | 'snowflake' | 'uuid'
export type PluginEvent =
  | 'OnLoad' | 'OnFieldValueChanged' | 'OnBeforeSave' | 'OnAfterSave'
  | 'OnBeforeSubmit' | 'OnAfterSubmit' | 'OnBeforeAudit' | 'OnAfterAudit'
  | 'OnBeforePush' | 'OnAfterPush' | 'OnBeforeDelete' | 'OnAfterDelete'
  | 'OnFieldValueChange' | 'OnBeforeValidate' | 'OnCustomButtonClick'
export type RuleType = 'validate' | 'calc' | 'linkage' | 'available'
export type TriggerEvent =
  | 'OnBeforeSave' | 'OnAfterSave' | 'OnBeforeSubmit' | 'OnBeforeAudit' | 'OnFieldValueChange'
export type WritebackMode = 'add' | 'subtract' | 'cover'
export type OverControl = 'block' | 'warn' | 'allow'
export type SegmentType = 'prefix' | 'date' | 'serial' | 'fixed' | 'variable'
export type ResetType = 'none' | 'year' | 'month' | 'org_year'
export type OrgType = 'group' | 'company' | 'factory' | 'workshop' | 'business'
export type DataScope = 'self' | 'dept' | 'dept_sub' | 'org' | 'all'
export type FieldPerm = 'visible' | 'hidden' | 'mask'

// ============ D11 权限体系扩展 ============
// 部门（PRD 04.2，sys_dept 独立管理页面 GAP-D11-004）
export interface SysDept {
  id: string
  dept_code: string
  dept_name: string
  org_id: string
  parent_id?: string
  sort_index: number
  status: 0 | 1
  remark?: string
}

// 用户多组织归属（PRD 04.1.4，sys_user_org GAP-D11-001 / RISK-D11-002）
export interface SysUserOrg {
  id?: string
  user_id: string
  org_id: string
  is_main: 0 | 1   // 1 主组织 / 0 兼任组织
  eff_date?: string  // 生效日期
  exp_date?: string  // 失效日期
  create_by?: string
  create_time?: string
  update_by?: string
  update_time?: string
}

// 登录安全策略（PRD 04.6 GAP-D11-006 / RISK-D11-004）
export interface SecurityPolicy {
  id?: string
  // 密码策略
  pwd_min_length: number          // 最小长度
  pwd_complexity: 'low' | 'mid' | 'high'  // 复杂度：low 字母+数字 / mid 大小写+数字 / high 大小写+数字+特殊符号
  pwd_expire_days: number         // 密码有效期（天，0 永久）
  pwd_history_count: number       // 历史密码不可重复次数
  // 失败锁定
  fail_lock_threshold: number     // 失败 N 次锁定
  fail_lock_minutes: number       // 锁定时长（分钟）
  captcha_threshold: number       // 失败 N 次后强制验证码
  // 会话
  session_timeout_minutes: number // 会话超时
  // 审计
  audit_login: 0 | 1              // 是否审计登录
  audit_operation: 0 | 1          // 是否审计关键操作
  remark?: string
  update_time?: string
}

// 登录审计日志（PRD 04.6）
export interface LoginAuditLog {
  id: string
  user_code: string
  user_name?: string
  login_type: 'login' | 'logout' | 'fail' | 'lock' | 'unlock'
  ip: string
  client: string
  result: 'success' | 'fail'
  error_msg?: string
  create_time: string
}

// ============ D12 集成与附件扩展 ============
// 工作流实例（PRD 07.4，GAP-D12-007 / RISK-D12-002）
export interface WfInstance {
  id: string
  instance_id: string             // 本地实例ID
  request_id?: string             // 外部工作流实例ID
  bill_type: string               // 单据类型（bo_code）
  bill_id: string
  bill_code?: string
  status: 'approving' | 'approved' | 'rejected' | 'canceled'
  submit_by?: string
  submit_time?: string
  callback_time?: string
  current_node?: string           // 当前审批节点
  approver?: string               // 当前审批人
  remark?: string
}

// 附件存储配置（PRD 07.1.3，GAP-D12-003/006 / RISK-D12-003）
export interface StorageConfig {
  id?: string
  storage_type: 'local' | 'oss' | 'minio' | 's3'
  // OSS 配置
  endpoint?: string
  access_key?: string
  secret_key?: string
  bucket?: string
  region?: string
  // 文件限制
  allowed_types: string           // 允许的文件类型（逗号分隔，如 pdf,docx,xlsx,jpg,png）
  max_file_size: number           // 单文件大小上限（MB）
  max_total_size?: number         // 单业务对象附件总上限（MB）
  // 路径
  base_path?: string
  status: 0 | 1
  remark?: string
  update_time?: string
}

// API 鉴权配置（PRD 07.5，GAP-D12-008/009/010 / RISK-D12-005）
export interface ApiAuthConfig {
  id?: string
  auth_type: 'oauth2' | 'api_key' | 'jwt' | 'basic'
  client_id?: string              // OAuth2 client_id
  client_secret?: string          // OAuth2 client_secret
  token_url?: string              // OAuth2 token endpoint
  scope?: string                  // OAuth2 scope
  api_key?: string                // API Key
  api_key_header?: string         // API Key 头部名称（默认 X-API-Key）
  jwt_secret?: string             // JWT 签名密钥
  jwt_expire_minutes?: number     // JWT 过期时间
  // 幂等键（GAP-D12-009）
  idempotent_enabled: 0 | 1       // 是否启用幂等键
  idempotent_header?: string      // 幂等键头部名称（默认 X-Idempotency-Key）
  idempotent_ttl_seconds?: number // 幂等键 TTL（秒）
  // Swagger（GAP-D12-010）
  swagger_enabled: 0 | 1
  swagger_url?: string
  remark?: string
  status: 0 | 1
  update_time?: string
}

// 幂等键记录
export interface IdempotentRecord {
  id: string
  idempotent_key: string
  api_url: string
  method: string
  request_body?: string
  response_body?: string
  status_code: number
  create_time: string
  expire_time: string
}

// 导入模板配置（PRD 07.3.7，meta_import_template GAP-D12-012 / RISK-D12-006）
export interface ImportTemplate {
  id?: string
  template_code: string           // 模板编码（唯一）
  template_name: string
  bo_code: string                 // 业务对象编码
  // 字段映射（导入列 → 字段编码）
  field_mappings: ImportTemplateField[]
  // 校验规则
  unique_fields?: string          // 唯一性校验字段（逗号分隔）
  required_fields?: string        // 必填字段（逗号分隔）
  // 行为
  allow_update: 0 | 1             // 允许更新已存在记录
  update_key?: string             // 更新匹配键字段
  fail_fast: 0 | 1                // 出错即终止（1 终止 / 0 跳过继续）
  // 模板文件
  template_file?: string
  status: 0 | 1
  remark?: string
  create_by?: string
  create_time?: string
  update_by?: string
  update_time?: string
}

export interface ImportTemplateField {
  field_code: string              // 字段编码（与 meta_form_field.field_code 对齐）
  field_name: string              // 字段名称（导入列标题）
  is_required: 0 | 1              // 是否必填
  data_type: string               // 数据类型
  validate_rule?: string          // 校验规则
  default_value?: string          // 默认值
  sort_index: number
}

// ============ D10 打印模板扩展（GAP-D10-001/009 / RISK-D10-004）============
export interface PrintPaperSettings {
  paper_type: 'A4' | 'A5' | 'letter' | 'custom'
  paper_width?: number            // 自定义宽度（mm）
  paper_height?: number           // 自定义高度（mm）
  orientation: 'portrait' | 'landscape'   // 纵向 / 横向
  margin_json: {
    top: number
    bottom: number
    left: number
    right: number
    header: number
    footer: number
  }
}

// 套打配置（GAP-D10-002）
export interface PrintBatchConfig {
  batch_enabled: 0 | 1
  copies: number                  // 每单据打印份数
  collate: 0 | 1                  // 1=逐份(1,2,3,1,2,3) / 0=逐单(1,1,2,2,3,3)
  print_by?: string               // 打印人
  print_time?: string             // 打印时间
  printer?: string                // 打印机名
}

// 列设置项（GAP-D09-002 / RISK-D09-003：含列宽/冻结/合计）
export interface ColumnSettingItem {
  field_code: string
  is_show: boolean
  column_width?: number
  is_fixed?: 'none' | 'left' | 'right'
  is_sum?: boolean
  is_avg?: boolean
  sort_index?: number
}
