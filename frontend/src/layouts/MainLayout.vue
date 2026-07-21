<template>
  <el-container class="main-layout">
    <!-- 顶栏 -->
    <el-header class="app-header" height="48px">
      <div class="header-left">
        <el-icon class="collapse-btn" @click="collapsed = !collapsed">
          <Fold v-if="!collapsed" />
          <Expand v-else />
        </el-icon>
        <span class="logo">Meta Data Driven ERP BOS 平台</span>
      </div>
      <div class="header-right">
        <el-dropdown @command="handleUserCommand">
          <span class="user-info">
            <el-avatar :size="26" style="background:#fff;color:#1564ff">A</el-avatar>
            <span class="ml-8">管理员</span>
            <el-icon><ArrowDown /></el-icon>
          </span>
          <template #dropdown>
            <el-dropdown-menu>
              <el-dropdown-item command="switch-org">切换组织</el-dropdown-item>
              <el-dropdown-item command="profile">个人设置</el-dropdown-item>
              <el-dropdown-item command="logout" divided>退出登录</el-dropdown-item>
            </el-dropdown-menu>
          </template>
        </el-dropdown>
      </div>
    </el-header>

    <el-container>
      <!-- 侧边导航 -->
      <el-aside :width="collapsed ? '64px' : '220px'" class="app-sidebar">
        <el-menu
          :default-active="activeMenu"
          :collapse="collapsed"
          :unique-opened="true"
          router
          class="sidebar-menu"
        >
          <template v-for="item in sidebarMenu" :key="item.menu_code || item.title">
            <el-sub-menu :index="item.menu_code || item.title">
              <template #title>
                <el-icon v-if="item.icon || item.menu_icon">
                  <component :is="item.icon || item.menu_icon" />
                </el-icon>
                <span>{{ item.menu_name || item.title }}</span>
              </template>
              <template v-for="child in (item.children || item.children_menu)" :key="child.path || child.menu_path">
                <el-menu-item :index="child.path || child.menu_path || ''">
                  {{ child.title || child.menu_name }}
                </el-menu-item>
              </template>
            </el-sub-menu>
          </template>
        </el-menu>
      </el-aside>

      <el-container direction="vertical">
        <!-- tags 标签页 -->
        <div class="app-tags">
          <el-tag
            v-for="tag in tags"
            :key="tag.path"
            :closable="tag.path !== '/bos/business-object'"
            :type="tag.path === activeMenu ? 'primary' : 'info'"
            :effect="tag.path === activeMenu ? 'dark' : 'plain'"
            class="tag-item"
            @click="router.push(tag.path)"
            @close="closeTag(tag)"
          >
            {{ tag.title }}
          </el-tag>
        </div>

        <!-- 主内容区 -->
        <el-main class="app-main">
          <router-view v-slot="{ Component }">
            <keep-alive :max="10">
              <component :is="Component" />
            </keep-alive>
          </router-view>
        </el-main>
      </el-container>
    </el-container>
  </el-container>
</template>

<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { menuConfig } from '@/config/menu'
import { menuApi, type SysMenu } from '@/api/perm'

const route = useRoute()
const router = useRouter()
const collapsed = ref(false)

const activeMenu = computed(() => route.path)

interface Tag {
  path: string
  title: string
}

const tags = ref<Tag[]>([{ path: '/bos/business-object', title: '业务对象管理' }])

// 统一菜单项结构（兼容后端动态加载与前端静态 fallback）
interface SidebarItem {
  menu_code?: string
  title?: string
  menu_name?: string
  icon?: string
  menu_icon?: string
  children?: { path: string; title: string }[]
  children_menu?: { menu_path: string; menu_name: string }[]
}

// 后端动态菜单优先，加载失败或为空时 fallback 到静态 menuConfig
const remoteMenu = ref<SysMenu[]>([])
const menuLoadError = ref(false)

const sidebarMenu = computed<SidebarItem[]>(() => {
  if (menuLoadError.value || !remoteMenu.value.length) {
    return menuConfig as unknown as SidebarItem[]
  }
  return remoteMenu.value.map(m => ({
    menu_code: m.menu_code,
    menu_name: m.menu_name,
    menu_icon: m.icon,
    children_menu: (m.children || []).map(c => ({ menu_path: c.path || '', menu_name: c.menu_name }))
  }))
})

async function loadMenu() {
  try {
    const data = await menuApi.tree()
    remoteMenu.value = data || []
    if (!remoteMenu.value.length) menuLoadError.value = true
  } catch (e) {
    menuLoadError.value = true
    // 静默 fallback 到静态菜单，不弹错误提示
  }
}

onMounted(loadMenu)

// 路由变化时添加标签
watch(
  () => route.path,
  (path) => {
    if (route.meta.hidden) return
    const title = (route.meta.title as string) || ''
    if (title && !tags.value.find(t => t.path === path)) {
      tags.value.push({ path, title })
    }
  },
  { immediate: true }
)

function closeTag(tag: Tag) {
  const idx = tags.value.findIndex(t => t.path === tag.path)
  if (idx > -1) {
    tags.value.splice(idx, 1)
    // 若关闭的是当前激活标签，跳转到最后一个
    if (tag.path === route.path) {
      const last = tags.value[tags.value.length - 1]
      router.push(last.path)
    }
  }
}

// 右上角下拉菜单命令处理
async function handleUserCommand(command: string) {
  if (command === 'logout') {
    try {
      await ElMessageBox.confirm('确定要退出登录吗？', '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      })
    } catch {
      return
    }
    localStorage.removeItem('token')
    router.push('/login')
    ElMessage.success('已退出登录')
  } else if (command === 'switch-org') {
    ElMessage.info('切换组织功能待实现')
  } else if (command === 'profile') {
    ElMessage.info('个人设置功能待实现')
  }
}
</script>

<style scoped lang="scss">
.main-layout {
  height: 100vh;
}

.header-left {
  display: flex;
  align-items: center;
  gap: 12px;
}
.collapse-btn {
  cursor: pointer;
  font-size: 18px;
}
.header-right {
  margin-left: auto;
}
.user-info {
  display: flex;
  align-items: center;
  cursor: pointer;
  color: #fff;
}

.app-sidebar {
  transition: width 0.2s;
  overflow-x: hidden;
}
.sidebar-menu {
  height: calc(100vh - 48px);
  overflow-y: auto;
  border-right: none;
}
.sidebar-menu:not(.el-menu--collapse) {
  width: 220px;
}

.app-tags {
  height: 34px;
  background: #fff;
  border-bottom: 1px solid #e4e7ed;
  display: flex;
  align-items: center;
  padding: 0 8px;
  gap: 6px;
  overflow-x: auto;
  flex-shrink: 0;
}
.tag-item {
  cursor: pointer;
  flex-shrink: 0;
}

.app-main {
  padding: 0;
  background: #f0f2f5;
  overflow: hidden;
}
</style>
