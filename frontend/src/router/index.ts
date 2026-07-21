import { createRouter, createWebHistory, type RouteRecordRaw } from 'vue-router'
import MainLayout from '@/layouts/MainLayout.vue'
import MobileLayout from '@/layouts/MobileLayout.vue'

// 占位组件 - 后续阶段逐步替换为实际页面
const Placeholder = () => import('@/views/placeholder.vue')

const routes: RouteRecordRaw[] = [
  {
    path: '/login',
    name: 'Login',
    component: () => import('@/views/login/index.vue'),
    meta: { title: '登录', hidden: true }
  },
  {
    path: '/',
    component: MainLayout,
    redirect: '/bos/business-object',
    children: [
      // 业务对象建模
      { path: 'bos/business-object', name: 'BosBusinessObject', component: () => import('@/views/bos/business-object/index.vue'), meta: { title: '业务对象管理', group: '业务对象建模' } },
      { path: 'bos/entity-model', name: 'BosEntityModel', component: () => import('@/views/bos/entity-model/index.vue'), meta: { title: '实体与字段建模', group: '业务对象建模' } },
      { path: 'bos/entity-model/:boCode', name: 'BosEntityModelByCode', component: () => import('@/views/bos/entity-model/index.vue'), meta: { title: '实体与字段建模', group: '业务对象建模', hidden: true } },
      { path: 'bos/object-relation', name: 'BosObjectRelation', component: () => import('@/views/bos/object-relation/index.vue'), meta: { title: '对象关系配置', group: '业务对象建模' } },
      // 表单与渲染
      { path: 'bos/form-designer', name: 'BosFormDesigner', component: () => import('@/views/bos/form-designer/index.vue'), meta: { title: '表单设计器', group: '表单与渲染' } },
      { path: 'bos/form-designer/:boCode', name: 'BosFormDesignerByCode', component: () => import('@/views/bos/form-designer/index.vue'), meta: { title: '表单设计器', group: '表单与渲染', hidden: true } },
      { path: 'bos/form-plugin', name: 'BosFormPlugin', component: () => import('@/views/bos/form-plugin/index.vue'), meta: { title: '表单插件配置', group: '表单与渲染' } },
      // 状态与操作
      { path: 'bos/state-machine', name: 'BosStateMachine', component: () => import('@/views/bos/state-machine/index.vue'), meta: { title: '状态机配置', group: '状态与操作' } },
      { path: 'bos/push-rule', name: 'BosPushRule', component: () => import('@/views/bos/push-rule/index.vue'), meta: { title: '下推转换规则', group: '状态与操作' } },
      { path: 'bos/button-config', name: 'BosButtonConfig', component: () => import('@/views/bos/button-config/index.vue'), meta: { title: '自定义按钮配置', group: '状态与操作' } },
      { path: 'bos/print-designer', name: 'BosPrintDesigner', component: () => import('@/views/bos/print-designer/index.vue'), meta: { title: '打印模板设计器', group: '状态与操作' } },
      // 列表与查询
      { path: 'bos/list-config', name: 'BosListConfig', component: () => import('@/views/bos/list-config/index.vue'), meta: { title: '列表字段配置', group: '列表与查询' } },
      { path: 'bos/query-scheme', name: 'BosQueryScheme', component: () => import('@/views/bos/query-scheme/index.vue'), meta: { title: '查询方案管理', group: '列表与查询' } },
      // 编码与规则
      { path: 'bos/code-rule', name: 'BosCodeRule', component: () => import('@/views/bos/code-rule/index.vue'), meta: { title: '编码规则配置', group: '编码与规则' } },
      { path: 'bos/entity-rule', name: 'BosEntityRule', component: () => import('@/views/bos/entity-rule/index.vue'), meta: { title: '实体服务规则', group: '编码与规则' } },
      { path: 'bos/writeback-rule', name: 'BosWritebackRule', component: () => import('@/views/bos/writeback-rule/index.vue'), meta: { title: '反写规则配置', group: '编码与规则' } },
      // 权限管理
      { path: 'sys/org', name: 'SysOrg', component: () => import('@/views/sys/org/index.vue'), meta: { title: '组织架构', group: '权限管理' } },
      { path: 'sys/user', name: 'SysUser', component: () => import('@/views/sys/user/index.vue'), meta: { title: '用户管理', group: '权限管理' } },
      { path: 'sys/role', name: 'SysRole', component: () => import('@/views/sys/role/index.vue'), meta: { title: '角色管理', group: '权限管理' } },
      { path: 'sys/data-permission', name: 'SysDataPermission', component: () => import('@/views/sys/data-permission/index.vue'), meta: { title: '数据权限（行级）', group: '权限管理' } },
      { path: 'sys/field-permission', name: 'SysFieldPermission', component: () => import('@/views/sys/field-permission/index.vue'), meta: { title: '字段权限（列级）', group: '权限管理' } },
      { path: 'sys/dept', name: 'SysDept', component: () => import('@/views/sys/dept/index.vue'), meta: { title: '部门管理', group: '权限管理' } },
      { path: 'sys/security', name: 'SysSecurity', component: () => import('@/views/sys/security/index.vue'), meta: { title: '登录安全策略', group: '权限管理' } },
      { path: 'sys/menu', name: 'SysMenu', component: () => import('@/views/sys/menu/index.vue'), meta: { title: '菜单管理', group: '权限管理' } },
      // 集成与附件
      { path: 'sys/import-task', name: 'SysImportTask', component: () => import('@/views/sys/import-task/index.vue'), meta: { title: '导入任务管理', group: '集成与附件' } },
      { path: 'sys/import-template', name: 'SysImportTemplate', component: () => import('@/views/sys/import-template/index.vue'), meta: { title: '导入模板配置', group: '集成与附件' } },
      { path: 'sys/api-log', name: 'SysApiLog', component: () => import('@/views/sys/api-log/index.vue'), meta: { title: 'API 接口日志', group: '集成与附件' } },
      { path: 'sys/wf-instance', name: 'SysWfInstance', component: () => import('@/views/sys/wf-instance/index.vue'), meta: { title: '工作流实例', group: '集成与附件' } },
      { path: 'sys/storage', name: 'SysStorage', component: () => import('@/views/sys/storage/index.vue'), meta: { title: '附件存储配置', group: '集成与附件' } },
      { path: 'sys/api-auth', name: 'SysApiAuth', component: () => import('@/views/sys/api-auth/index.vue'), meta: { title: 'API 鉴权配置', group: '集成与附件' } },
      // 单据运行时
      { path: 'bill/sal_order', name: 'BillSalOrderList', component: () => import('@/views/bill/sal_order/list.vue'), meta: { title: '销售订单列表', group: '单据运行时' } },
      { path: 'bill/sal_order/:id', name: 'BillSalOrderDetail', component: () => import('@/views/bill/sal_order/detail.vue'), meta: { title: '销售订单详情', group: '单据运行时', hidden: true } },
      // 业务模块动态路由：/bill/<bo_code> 统一指向占位页（具体业务页面后续逐步替换）
      { path: 'bill/:boCode', name: 'BillRuntime', component: Placeholder, meta: { title: '单据', group: '业务模块', hidden: true } },
      // 主数据动态路由：/master/<bo_code> 统一指向占位页
      { path: 'master/:boCode', name: 'MasterRuntime', component: Placeholder, meta: { title: '主数据', group: '基础数据', hidden: true } }
    ]
  },
  {
    path: '/m',
    component: MobileLayout,
    redirect: '/m/approve',
    children: [
      { path: 'approve', name: 'MobileApprove', component: () => import('@/views/mobile/approve/index.vue'), meta: { title: '审批处理' } },
      { path: 'stock', name: 'MobileStock', component: () => import('@/views/mobile/stock/index.vue'), meta: { title: '库存查询' } },
      { path: 'bill-view', name: 'MobileBillView', component: () => import('@/views/mobile/bill-view/index.vue'), meta: { title: '单据查看' } },
      { path: 'message', name: 'MobileMessage', component: () => import('@/views/mobile/message/index.vue'), meta: { title: '消息预警' } }
    ]
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

// 全局前置守卫：未登录则跳转登录页；同时设置页面标题
const WHITE_LIST = ['/login', '/m/approve', '/m/stock', '/m/bill-view', '/m/message']

router.beforeEach((to, _from, next) => {
  // 设置页面标题
  const title = (to.meta?.title as string) || ''
  document.title = title ? `${title} - E-ERP BOS 平台` : 'E-ERP BOS 平台'

  const token = localStorage.getItem('token')
  if (token) {
    // 已登录访问登录页则重定向到首页
    if (to.path === '/login') {
      next({ path: '/' })
      return
    }
    next()
    return
  }
  // 未登录：白名单放行，其余重定向到登录页
  if (WHITE_LIST.includes(to.path)) {
    next()
    return
  }
  next({ path: '/login', query: { redirect: to.fullPath } })
})

export default router
