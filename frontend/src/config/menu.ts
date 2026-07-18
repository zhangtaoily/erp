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
