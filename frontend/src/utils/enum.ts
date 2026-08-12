// BOS 平台枚举与常量 - 依据 PRD 01-平台基座

// 单据状态码（PRD 02.1 - prd-scope-refine spec）
export enum PactState {
  DRAFT = 0,       // 暂存
  CREATED = 1,     // 已创建
  SUBMITTED = 2,   // 已提交
  AUDITED = 3,     // 已审核
  REJECTED = 4     // 已驳回
}

export const PACT_STATE_MAP: Record<number, { label: string; type: 'info' | 'primary' | 'warning' | 'success' | 'danger' }> = {
  0: { label: '暂存', type: 'info' },
  1: { label: '已创建', type: 'primary' },
  2: { label: '已提交', type: 'warning' },
  3: { label: '已审核', type: 'success' },
  4: { label: '已驳回', type: 'danger' }
}

export const PACT_STATE_LIST = Object.entries(PACT_STATE_MAP).map(([k, v]) => ({
  value: Number(k),
  label: v.label,
  type: v.type
}))

// 控件类型（PRD 01.1.4）
export const CONTROL_TYPE_OPTIONS = [
  { value: 'text', label: '文本框' },
  { value: 'textarea', label: '多行文本' },
  { value: 'number', label: '数值' },
  { value: 'date', label: '日期' },
  { value: 'datetime', label: '日期时间' },
  { value: 'select', label: '下拉枚举' },
  { value: 'ref', label: '基础资料引用' },
  { value: 'amount', label: '币别金额' },
  { value: 'qty', label: '数量单位' },
  { value: 'checkbox', label: '复选框' },
  { value: 'attachment', label: '附件' }
]

// 容器控件（表单设计器 - 子表/孙表，对应实体而非字段）
export const CONTAINER_CONTROL_OPTIONS = [
  { value: 'subtable', label: '子表', desc: '订单明细等明细数据，以页签表格形式展示' },
  { value: 'grandchild', label: '孙表', desc: '子表行展开的次级明细，如指定用料' }
]

// 字段数据类型（与 SQL meta_form_field.field_type 对齐：text/number/date/datetime/enum/ref/bool/amount/qty/attachment）
export const FIELD_TYPE_OPTIONS = [
  { value: 'text', label: '文本' },
  { value: 'number', label: '数值' },
  { value: 'date', label: '日期' },
  { value: 'datetime', label: '日期时间' },
  { value: 'enum', label: '枚举' },
  { value: 'ref', label: '引用' },
  { value: 'bool', label: '布尔' },
  { value: 'amount', label: '金额' },
  { value: 'qty', label: '数量' },
  { value: 'attachment', label: '附件' }
]

// 字段类型 → 控件类型 映射（PRD 05.2.6）
export const FIELD_TYPE_CONTROL_MAP: Record<string, string> = {
  text: 'textarea',
  number: 'number',
  date: 'date',
  datetime: 'datetime',
  enum: 'select',
  ref: 'ref',
  bool: 'checkbox',
  amount: 'amount',
  qty: 'qty',
  attachment: 'attachment'
}

// 业务对象类型
export const BO_TYPE_OPTIONS = [
  { value: 'bill', label: '单据' },
  { value: 'master', label: '基础资料' },
  { value: 'report', label: '报表' }
]

// 实体类型
export const ENTITY_TYPE_OPTIONS = [
  { value: 'main', label: '主表' },
  { value: 'sub', label: '子表' },
  { value: 'grandchild', label: '孙表' }
]

// 组织类型（PRD 04.1.2）
export const ORG_TYPE_OPTIONS = [
  { value: 'group', label: '集团' },
  { value: 'company', label: '公司' },
  { value: 'factory', label: '工厂' },
  { value: 'workshop', label: '车间' },
  { value: 'business', label: '事业部' }
]

// 主键策略
export const PK_STRATEGY_OPTIONS = [
  { value: 'auto', label: '自增' },
  { value: 'snowflake', label: '雪花ID' },
  { value: 'uuid', label: 'UUID' }
]

// 规则类型（PRD 08.1.2）
export const RULE_TYPE_OPTIONS = [
  { value: 'validate', label: '校验' },
  { value: 'calc', label: '计算' },
  { value: 'linkage', label: '联动' },
  { value: 'available', label: '可用量校验' }
]

// 触发事件（PRD 08.1.5）
export const TRIGGER_EVENT_OPTIONS = [
  { value: 'OnBeforeSave', label: '保存前' },
  { value: 'OnAfterSave', label: '保存后' },
  { value: 'OnBeforeSubmit', label: '提交前' },
  { value: 'OnBeforeAudit', label: '审核前' },
  { value: 'OnFieldValueChange', label: '字段值变更' }
]

// 反写模式（PRD 08.2.5）
export const WRITEBACK_MODE_OPTIONS = [
  { value: 'add', label: '累加' },
  { value: 'subtract', label: '扣减' },
  { value: 'cover', label: '覆盖' },
  { value: 'aggregate', label: '聚合重算' }
]

// 超限控制（PRD 08.2.6）
export const OVER_CONTROL_OPTIONS = [
  { value: 'block', label: '阻断' },
  { value: 'warn', label: '预警放行' },
  { value: 'allow', label: '允许' }
]

// 反写触发操作（多选，逗号分隔存储）
export const TRIGGER_OP_OPTIONS = [
  { value: 'save', label: '保存' },
  { value: 'delete', label: '删除' },
  { value: 'cancel', label: '取消' },
  { value: 'audit', label: '审核' },
  { value: 'revoke', label: '撤销' }
]

// 段类型（PRD 06.1.6）
export const SEGMENT_TYPE_OPTIONS = [
  { value: 'prefix', label: '前缀' },
  { value: 'date', label: '日期' },
  { value: 'serial', label: '流水' },
  { value: 'fixed', label: '固定段' },
  { value: 'variable', label: '变量段' }
]

// 流水重置类型（PRD 06.1.3）
export const RESET_TYPE_OPTIONS = [
  { value: 'none', label: '不重置' },
  { value: 'year', label: '按年' },
  { value: 'month', label: '按月' },
  { value: 'org_year', label: '按组织+年' }
]

// 数据权限范围（PRD 04.2.2）
export const DATA_SCOPE_OPTIONS = [
  { value: 'self', label: '本人' },
  { value: 'dept', label: '本部门' },
  { value: 'dept_sub', label: '本部门及下级' },
  { value: 'org', label: '本组织' },
  { value: 'all', label: '全部' }
]

// 字段权限（PRD 04.3.1）
export const FIELD_PERM_OPTIONS = [
  { value: 'visible', label: '可见' },
  { value: 'hidden', label: '隐藏' },
  { value: 'mask', label: '脱敏' }
]

// 按钮可用性（PRD 04.4.3）
export const BUTTON_AVAIL_OPTIONS = [
  { value: 'enabled', label: '可用' },
  { value: 'disabled', label: '禁用' },
  { value: 'hidden', label: '隐藏' },
  { value: 'readonly', label: '只读' }
]

// 插件事件（PRD 06.2.2 表单级 + 字段级）
export const PLUGIN_EVENT_OPTIONS = [
  { value: 'OnLoad', label: '表单加载', group: '表单级' },
  { value: 'OnFieldValueChanged', label: '字段值变更', group: '表单级' },
  { value: 'OnBeforeSave', label: '保存前', group: '表单级' },
  { value: 'OnAfterSave', label: '保存后', group: '表单级' },
  { value: 'OnBeforeSubmit', label: '提交前', group: '表单级' },
  { value: 'OnAfterSubmit', label: '提交后', group: '表单级' },
  { value: 'OnBeforeAudit', label: '审核前', group: '表单级' },
  { value: 'OnAfterAudit', label: '审核后', group: '表单级' },
  { value: 'OnBeforePush', label: '下推前', group: '表单级' },
  { value: 'OnAfterPush', label: '下推后', group: '表单级' },
  { value: 'OnBeforeDelete', label: '删除前', group: '表单级' },
  { value: 'OnAfterDelete', label: '删除后', group: '表单级' },
  { value: 'OnFieldValueChange', label: '字段值变化', group: '字段级' },
  { value: 'OnBeforeValidate', label: '校验前', group: '字段级' },
  { value: 'OnCustomButtonClick', label: '自定义按钮点击', group: '表单级' }
]

// 插件系统基类（参考金蝶BOS三大基类）
export const PLUGIN_BASE_CLASS_OPTIONS = [
  {
    value: 'BillPlugin',
    label: '表单插件',
    base_class_name: 'com.eerp.plugin.base.AbstractBillPlugIn',
    desc: '继承 AbstractBillPlugIn，有 View/Model/Context，处理单据维护界面交互（字段变更、按钮、加载等）'
  },
  {
    value: 'ListPlugin',
    label: '列表插件',
    base_class_name: 'com.eerp.plugin.base.AbstractListPlugIn',
    desc: '继承 AbstractListPlugIn，处理单据列表界面交互（列表加载、行选择、批量操作等）'
  },
  {
    value: 'OperationServicePlugin',
    label: '操作服务插件',
    base_class_name: 'com.eerp.plugin.base.AbstractOperationServicePlugIn',
    desc: '继承 AbstractOperationServicePlugIn，绑定到单据操作（保存/提交/审核），按流水线事件干预操作执行，无 View'
  }
]

// 基类 → 全限定类名 映射
export const PLUGIN_BASE_CLASS_MAP: Record<string, string> = PLUGIN_BASE_CLASS_OPTIONS.reduce((m, o) => {
  m[o.value] = o.base_class_name
  return m
}, {} as Record<string, string>)

// 表单插件可绑定事件（BillPlugin）
export const BILL_PLUGIN_EVENTS = [
  { value: 'OnLoad', label: '表单加载(OnLoad)', desc: '表单界面加载完成' },
  { value: 'DataChanged', label: '字段值变更(DataChanged)', desc: '字段值改变时触发' },
  { value: 'BeforeSave', label: '保存前(BeforeSave)', desc: '保存操作前' },
  { value: 'AfterSave', label: '保存后(AfterSave)', desc: '保存操作后' },
  { value: 'BeforeSubmit', label: '提交前(BeforeSubmit)' },
  { value: 'AfterSubmit', label: '提交后(AfterSubmit)' },
  { value: 'BeforeAudit', label: '审核前(BeforeAudit)' },
  { value: 'AfterAudit', label: '审核后(AfterAudit)' },
  { value: 'BeforeDelete', label: '删除前(BeforeDelete)' },
  { value: 'AfterDelete', label: '删除后(AfterDelete)' },
  { value: 'BarItemClick', label: '按钮点击(BarItemClick)', desc: '自定义按钮点击' },
  { value: 'AfterCreateNewData', label: '新建后(AfterCreateNewData)', desc: '新建单据数据初始化后' },
  { value: 'AfterCopyData', label: '复制后(AfterCopyData)', desc: '复制单据数据后' }
]

// 列表插件可绑定事件（ListPlugin）
export const LIST_PLUGIN_EVENTS = [
  { value: 'OnLoad', label: '列表加载(OnLoad)' },
  { value: 'RowSelected', label: '行选择(RowSelected)' },
  { value: 'BeforeBatchOperate', label: '批量操作前(BeforeBatchOperate)' },
  { value: 'AfterBatchOperate', label: '批量操作后(AfterBatchOperate)' },
  { value: 'FilterRow', label: '过滤行(FilterRow)', desc: '列表行过滤' }
]

// 操作服务插件事件链（OperationServicePlugin 流水线，参考金蝶）
export const OPERATION_PIPELINE_EVENTS = [
  {
    value: 'OnPreparePropertys',
    label: '字段预加载(OnPreparePropertys)',
    desc: '加载单据数据包前触发，声明插件需要用到的字段；否则数据包可能缺字段',
    phase: '准备',
    in_transaction: false,
    order: 1
  },
  {
    value: 'OnAddValidators',
    label: '增加校验器(OnAddValidators)',
    desc: '构建校验器后、执行校验前触发；可增加自定义校验器或移除内置校验器',
    phase: '校验',
    in_transaction: false,
    order: 2
  },
  {
    value: 'BeforeExecuteOperationTransaction',
    label: '事务前(BeforeExecuteOperationTransaction)',
    desc: '校验通过后、开启事务前触发；可整理数据或取消操作，不可改库',
    phase: '事务前',
    in_transaction: false,
    order: 3
  },
  {
    value: 'BeginOperationTransaction',
    label: '事务开始(BeginOperationTransaction)',
    desc: '事务已开启，执行主操作写库；异常将回滚整个事务',
    phase: '事务中',
    in_transaction: true,
    order: 4
  },
  {
    value: 'EndOperationTransaction',
    label: '事务结束(EndOperationTransaction)',
    desc: '主操作写库完成、事务提交前触发；可在事务内做后续处理',
    phase: '事务中',
    in_transaction: true,
    order: 5
  },
  {
    value: 'AfterExecuteOperationTransaction',
    label: '事务后(AfterExecuteOperationTransaction)',
    desc: '事务提交后触发；可做通知、下游联动等非事务操作',
    phase: '事务后',
    in_transaction: false,
    order: 6
  }
]

// 数据设置类型（参考帆软单元格数据设置）
export const CELL_DATA_SETTING_OPTIONS = [
  { value: 'list', label: '列表(展开所有记录)' },
  { value: 'group', label: '分组(合并相同值)' },
  { value: 'sum', label: '汇总-求和' },
  { value: 'avg', label: '汇总-平均' },
  { value: 'max', label: '汇总-最大' },
  { value: 'min', label: '汇总-最小' },
  { value: 'count', label: '汇总-计数' }
]

// 单元格扩展方向（参考帆软）
export const CELL_EXPAND_OPTIONS = [
  { value: 'none', label: '不扩展' },
  { value: 'vertical', label: '纵向扩展(向下)' },
  { value: 'horizontal', label: '横向扩展(向右)' }
]

// 标准按钮 code（PRD 02.2）
export const STANDARD_BUTTONS = [
  'add', 'copy', 'draft', 'save', 'submit', 'audit', 'revoke', 'reject',
  'delete', 'close', 'cancel', 'change', 'push', 'trace', 'print'
]

export const STANDARD_BUTTON_LABELS: Record<string, string> = {
  add: '新增',
  copy: '复制',
  draft: '暂存',
  save: '保存',
  submit: '提交',
  audit: '审核',
  revoke: '撤销',
  reject: '驳回',
  delete: '删除',
  close: '关闭',
  cancel: '取消',
  change: '变更',
  push: '下推',
  trace: '联查',
  print: '打印'
}

// 查询运算符（PRD 03.2.3 - 14 种）
export const QUERY_OPERATORS = [
  { value: 'eq', label: '等于' },
  { value: 'ne', label: '不等于' },
  { value: 'gt', label: '大于' },
  { value: 'ge', label: '大于等于' },
  { value: 'lt', label: '小于' },
  { value: 'le', label: '小于等于' },
  { value: 'like', label: '包含' },
  { value: 'not_like', label: '不包含' },
  { value: 'begin_with', label: '以...开头' },
  { value: 'end_with', label: '以...结尾' },
  { value: 'is_null', label: '为空' },
  { value: 'is_not_null', label: '不为空' },
  { value: 'in', label: '属于' },
  { value: 'between', label: '介于' }
]
