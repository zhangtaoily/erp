// BOS 平台菜单配置 - 依据 PRD 01-平台基座 8 个模块归纳
export interface MenuItem {
  title: string
  icon?: string
  path?: string
  children?: MenuItem[]
}

export const menuConfig: MenuItem[] = [
  {
    title: '业务对象建模',
    icon: 'DataBoard',
    children: [
      { title: '业务对象管理', path: '/bos/business-object' },
      { title: '实体与字段建模', path: '/bos/entity-model' },
      { title: '对象关系配置', path: '/bos/object-relation' }
    ]
  },
  {
    title: '表单与渲染',
    icon: 'Document',
    children: [
      { title: '表单设计器', path: '/bos/form-designer' },
      { title: '表单插件配置', path: '/bos/form-plugin' }
    ]
  },
  {
    title: '状态与操作',
    icon: 'Switch',
    children: [
      { title: '状态机配置', path: '/bos/state-machine' },
      { title: '下推转换规则', path: '/bos/push-rule' },
      { title: '自定义按钮配置', path: '/bos/button-config' },
      { title: '打印模板设计器', path: '/bos/print-designer' }
    ]
  },
  {
    title: '列表与查询',
    icon: 'Search',
    children: [
      { title: '列表字段配置', path: '/bos/list-config' },
      { title: '查询方案管理', path: '/bos/query-scheme' }
    ]
  },
  {
    title: '编码与规则',
    icon: 'SetUp',
    children: [
      { title: '编码规则配置', path: '/bos/code-rule' },
      { title: '实体服务规则', path: '/bos/entity-rule' },
      { title: '反写规则配置', path: '/bos/writeback-rule' }
    ]
  },
  {
    title: '权限管理',
    icon: 'Lock',
    children: [
      { title: '组织架构', path: '/sys/org' },
      { title: '用户管理', path: '/sys/user' },
      { title: '角色管理', path: '/sys/role' },
      { title: '部门管理', path: '/sys/dept' },
      { title: '数据权限（行级）', path: '/sys/data-permission' },
      { title: '字段权限（列级）', path: '/sys/field-permission' },
      { title: '登录安全策略', path: '/sys/security' }
    ]
  },
  {
    title: '集成与附件',
    icon: 'Connection',
    children: [
      { title: '导入任务管理', path: '/sys/import-task' },
      { title: '导入模板配置', path: '/sys/import-template' },
      { title: 'API 接口日志', path: '/sys/api-log' },
      { title: '工作流实例', path: '/sys/wf-instance' },
      { title: '附件存储配置', path: '/sys/storage' },
      { title: 'API 鉴权配置', path: '/sys/api-auth' },
      { title: '移动端预览', path: '/m/approve' }
    ]
  },
  {
    title: '单据运行时',
    icon: 'Files',
    children: [
      { title: '销售订单列表', path: '/bill/sal_order' },
      { title: '销售订单详情', path: '/bill/sal_order/1' }
    ]
  },
  {
    title: '采购管理',
    icon: 'ShoppingCart',
    children: [
      { title: '采购申请', path: '/bill/pur_apply' },
      { title: '采购合同', path: '/bill/pur_cont' },
      { title: '采购订单', path: '/bill/pur_order' },
      { title: '收料通知', path: '/bill/pur_receive_notice' },
      { title: '采购入库', path: '/bill/pur_in_stock' },
      { title: '采购退料', path: '/bill/pur_return' },
      { title: '采购发票', path: '/bill/pur_invoice' }
    ]
  },
  {
    title: '销售管理',
    icon: 'Sell',
    children: [
      { title: '意向合同', path: '/bill/sal_int_cont' },
      { title: '销售报价', path: '/bill/sal_quote' },
      { title: '销售合同', path: '/bill/sal_contract' },
      { title: '销售订单', path: '/bill/sal_order' },
      { title: '发货通知', path: '/bill/sal_delivery_notice' },
      { title: '销售出库', path: '/bill/sal_out_stock' },
      { title: '销售退货', path: '/bill/sal_return' },
      { title: '退货通知', path: '/bill/sal_return_notice' },
      { title: '销售发票', path: '/bill/sal_invoice' },
      { title: '打样通知', path: '/bill/pp_notice' },
      { title: '打样记录', path: '/bill/pp_record' }
    ]
  },
  {
    title: '供应链',
    icon: 'Connection'
  },
  {
    title: '财务会计',
    icon: 'Money',
    children: [
      { title: '暂估应付', path: '/bill/fin_est_ap' },
      { title: '应收单', path: '/bill/fin_ar' },
      { title: '应付单', path: '/bill/fin_ap' },
      { title: '收款单', path: '/bill/fin_receipt' },
      { title: '付款单', path: '/bill/fin_payment' },
      { title: '核销单', path: '/bill/fin_writeoff' },
      { title: '客户回款', path: '/bill/fin_cust_receipt' },
      { title: '会计科目', path: '/bill/fin_account' },
      { title: '会计期间', path: '/bill/fin_period' },
      { title: '凭证模板', path: '/bill/fin_voucher_tpl' },
      { title: '凭证', path: '/bill/fin_voucher' },
      { title: '成本归集', path: '/bill/fin_cost_collect' },
      { title: '制造费用池', path: '/bill/fin_cost_pool' },
      { title: '成本差异', path: '/bill/fin_cost_variance' }
    ]
  },
  {
    title: '生产制造',
    icon: 'Tools',
    children: [
      { title: 'BOM配方', path: '/bill/mfg_bom' },
      { title: '工艺路线', path: '/bill/mfg_route' },
      { title: '生产通知单', path: '/bill/mfg_notice' },
      { title: '生产订单', path: '/bill/mfg_order' },
      { title: '领料单', path: '/bill/mfg_pick' },
      { title: '生产入库', path: '/bill/mfg_in_stock' },
      { title: 'MRP计划', path: '/bill/mfg_mrp_plan' },
      { title: '外协订单', path: '/bill/mfg_outsource' }
    ]
  },
  {
    title: '税务管理',
    icon: 'Tickets',
    children: [
      { title: '税率配置', path: '/bill/tax_rate' },
      { title: '税务计提', path: '/bill/tax_provide' },
      { title: '纳税申报', path: '/bill/tax_declare' }
    ]
  },
  {
    title: '库存管理',
    icon: 'Box',
    children: [
      { title: '即时库存', path: '/bill/inv_stock' },
      { title: '批次台账', path: '/bill/inv_batch' },
      { title: '盘点单', path: '/bill/inv_stocktake' },
      { title: '调拨单', path: '/bill/inv_transfer' },
      { title: '形态转换', path: '/bill/inv_form_conv' },
      { title: '其他入库', path: '/bill/inv_other_in' },
      { title: '其他出库', path: '/bill/inv_other_out' },
      { title: '锁库单', path: '/bill/inv_lock' },
      { title: '锁库申请', path: '/bill/inv_lock_apply' }
    ]
  },
  {
    title: '基础数据',
    icon: 'Files',
    children: [
      { title: '组织', path: '/master/md_org' },
      { title: '部门', path: '/master/md_dept' },
      { title: '员工', path: '/master/md_employee' },
      { title: '业务员', path: '/master/md_saler' },
      { title: '跟单员', path: '/master/md_merchandiser' },
      { title: '客户', path: '/master/md_customer' },
      { title: '供应商', path: '/master/md_supplier' },
      { title: '物料', path: '/master/md_material' },
      { title: '物料分组', path: '/master/md_material_group' },
      { title: '原料', path: '/master/md_raw_material' },
      { title: '原料分组', path: '/master/md_raw_material_group' },
      { title: '币别', path: '/master/md_currency' },
      { title: '汇率', path: '/master/md_exchange_rate' },
      { title: '仓库', path: '/master/md_warehouse' },
      { title: '仓位', path: '/master/md_bin' },
      { title: '计量单位', path: '/master/md_unit' },
      { title: '品牌', path: '/master/md_brand' },
      { title: '色系', path: '/master/md_color_series' },
      { title: '公司色号', path: '/master/md_comp_color' },
      { title: '打版色号', path: '/master/md_print_color' },
      { title: '集锦卡', path: '/master/md_hl_card' },
      { title: '贸易类型', path: '/master/md_trade_type' },
      { title: '港口', path: '/master/md_port' },
      { title: '印章', path: '/master/md_seal' },
      { title: '箱贴模板', path: '/master/md_box_label_tpl' },
      { title: '质量标准', path: '/master/md_quality_std' },
      { title: '结算方式', path: '/master/md_settle_type' },
      { title: '特殊纺工费', path: '/master/md_spin_fee' },
      { title: '信用管理', path: '/master/md_credit' }
    ]
  },
  {
    title: '消息与通知',
    icon: 'Bell',
    children: [
      { title: '系统参数', path: '/master/sys_param' },
      { title: '公告', path: '/master/sys_notice' },
      { title: '数据备份', path: '/master/sys_backup' },
      { title: '预警规则', path: '/master/alert_rule' },
      { title: '预警记录', path: '/master/alert_record' },
      { title: '站内信', path: '/master/inbox_msg' },
      { title: '邮件日志', path: '/master/email_log' }
    ]
  }
]

// 扁平化所有叶子菜单路径（用于路由生成）
export function flattenMenu(items: MenuItem[]): { path: string; title: string }[] {
  const result: { path: string; title: string }[] = []
  const walk = (list: MenuItem[]) => {
    list.forEach(item => {
      if (item.path) {
        result.push({ path: item.path, title: item.title })
      }
      if (item.children) walk(item.children)
    })
  }
  walk(items)
  return result
}
