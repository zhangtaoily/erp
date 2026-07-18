<template>
  <div class="aa-page page-container">
    <!-- 鉴权配置列表 -->
    <div class="panel-card table-panel">
      <div class="panel-header">
        <span class="panel-title">API 鉴权配置</span>
        <div class="header-actions">
          <el-button type="success" size="small" @click="onOpenSwagger">
            <el-icon><Link /></el-icon>&nbsp;Swagger 文档
          </el-button>
          <el-button type="primary" size="small" @click="onAdd">新增配置</el-button>
        </div>
      </div>
      <el-table :data="tableData" size="small" border stripe v-loading="loading">
        <el-table-column type="index" label="#" width="45" />
        <el-table-column label="鉴权方式" width="120">
          <template #default="{ row }">
            <el-tag :type="authTypeTag(row.auth_type) || 'info'" size="small">{{ authTypeLabel(row.auth_type) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="标识" min-width="180">
          <template #default="{ row }">
            <span v-if="row.auth_type === 'oauth2'">client_id：{{ row.client_id }}</span>
            <span v-else-if="row.auth_type === 'api_key'">{{ row.api_key_header || 'X-API-Key' }}：{{ row.api_key }}</span>
            <span v-else-if="row.auth_type === 'jwt'">密钥：{{ row.jwt_secret }}（{{ row.jwt_expire_minutes || 60 }} 分钟）</span>
            <span v-else>Basic Auth</span>
          </template>
        </el-table-column>
        <el-table-column label="幂等键" width="160">
          <template #default="{ row }">
            <el-tag v-if="row.idempotent_enabled === 1" size="small" type="success">启用</el-tag>
            <el-tag v-else size="small" type="info">未启用</el-tag>
            <span v-if="row.idempotent_enabled === 1" class="mono">&nbsp;{{ row.idempotent_header }}</span>
          </template>
        </el-table-column>
        <el-table-column label="幂等TTL" width="100" align="right">
          <template #default="{ row }">{{ row.idempotent_ttl_seconds ? row.idempotent_ttl_seconds + ' s' : '-' }}</template>
        </el-table-column>
        <el-table-column label="Swagger" width="90">
          <template #default="{ row }">
            <el-tag v-if="row.swagger_enabled === 1" size="small" type="success">启用</el-tag>
            <el-tag v-else size="small" type="info">未启用</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="状态" width="80">
          <template #default="{ row }">
            <el-tag :type="row.status === 1 ? 'success' : 'info'" size="small">{{ row.status === 1 ? '启用' : '停用' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="remark" label="备注" min-width="140" show-overflow-tooltip />
        <el-table-column label="操作" width="130" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" size="small" @click="onEdit(row as any)">编辑</el-button>
            <el-button link type="danger" size="small" @click="onDelete(row as any)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <!-- 幂等键记录 -->
    <div class="panel-card idem-panel">
      <div class="panel-header">
        <span class="panel-title">幂等键记录</span>
        <el-input v-model="idemQuery.keyword" clearable placeholder="按 Key/URL 过滤" style="width:240px" size="small" @keyup.enter="loadIdemRecords">
          <template #append>
            <el-button @click="loadIdemRecords">查询</el-button>
          </template>
        </el-input>
      </div>
      <el-table :data="idemRecords" size="small" border stripe v-loading="idemLoading">
        <el-table-column type="index" label="#" width="45" />
        <el-table-column label="幂等键" width="200">
          <template #default="{ row }"><span class="mono">{{ row.idempotent_key }}</span></template>
        </el-table-column>
        <el-table-column prop="method" label="方法" width="70" />
        <el-table-column prop="api_url" label="接口" min-width="160" show-overflow-tooltip />
        <el-table-column label="状态码" width="80" align="right">
          <template #default="{ row }">
            <el-tag :type="row.status_code === 200 ? 'success' : 'danger'" size="small">{{ row.status_code }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="create_time" label="创建时间" width="160" />
        <el-table-column prop="expire_time" label="过期时间" width="160" />
        <el-table-column label="请求体" min-width="200" show-overflow-tooltip>
          <template #default="{ row }"><span class="json-cell">{{ row.request_body }}</span></template>
        </el-table-column>
      </el-table>
      <div class="pagination-bar">
        <el-pagination
          v-model:current-page="idemQuery.pageNum"
          v-model:page-size="idemQuery.pageSize"
          :total="idemTotal"
          :page-sizes="[10, 20, 50]"
          layout="total, sizes, prev, pager, next, jumper"
          background
          @size-change="loadIdemRecords"
          @current-change="loadIdemRecords"
        />
      </div>
    </div>

    <!-- 新增/编辑弹窗 -->
    <el-dialog v-model="dialogVisible" :title="dialogTitle" width="640px" append-to-body>
      <el-form :model="form" label-width="140px" size="small">
        <el-form-item label="鉴权方式" required>
          <el-select v-model="form.auth_type" style="width:100%" :disabled="dialogMode === 'edit'">
            <el-option label="OAuth2" value="oauth2" />
            <el-option label="API Key" value="api_key" />
            <el-option label="JWT" value="jwt" />
            <el-option label="Basic Auth" value="basic" />
          </el-select>
        </el-form-item>
        <template v-if="form.auth_type === 'oauth2'">
          <el-form-item label="Client ID" required><el-input v-model="form.client_id" /></el-form-item>
          <el-form-item label="Client Secret" required><el-input v-model="form.client_secret" type="password" show-password /></el-form-item>
          <el-form-item label="Token URL"><el-input v-model="form.token_url" placeholder="/oauth2/token" /></el-form-item>
          <el-form-item label="Scope"><el-input v-model="form.scope" placeholder="bos.read bos.write" /></el-form-item>
        </template>
        <template v-else-if="form.auth_type === 'api_key'">
          <el-form-item label="API Key" required><el-input v-model="form.api_key" /></el-form-item>
          <el-form-item label="Header 名称"><el-input v-model="form.api_key_header" placeholder="X-API-Key" /></el-form-item>
        </template>
        <template v-else-if="form.auth_type === 'jwt'">
          <el-form-item label="签名密钥" required><el-input v-model="form.jwt_secret" type="password" show-password /></el-form-item>
          <el-form-item label="过期时间（分钟）"><el-input-number v-model="form.jwt_expire_minutes" :min="1" :max="1440" controls-position="right" style="width:100%" /></el-form-item>
        </template>
        <el-divider content-position="left">幂等键</el-divider>
        <el-form-item label="启用幂等键">
          <el-radio-group v-model="form.idempotent_enabled">
            <el-radio :value="1">启用</el-radio>
            <el-radio :value="0">不启用</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item v-if="form.idempotent_enabled === 1" label="Header 名称">
          <el-input v-model="form.idempotent_header" placeholder="X-Idempotency-Key" />
        </el-form-item>
        <el-form-item v-if="form.idempotent_enabled === 1" label="TTL（秒）">
          <el-input-number v-model="form.idempotent_ttl_seconds" :min="10" :max="86400" controls-position="right" style="width:100%" />
        </el-form-item>
        <el-divider content-position="left">Swagger / 状态</el-divider>
        <el-form-item label="启用 Swagger">
          <el-radio-group v-model="form.swagger_enabled">
            <el-radio :value="1">启用</el-radio>
            <el-radio :value="0">不启用</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item v-if="form.swagger_enabled === 1" label="Swagger URL">
          <el-input v-model="form.swagger_url" placeholder="/swagger-ui/index.html" />
        </el-form-item>
        <el-form-item label="状态">
          <el-radio-group v-model="form.status">
            <el-radio :value="1">启用</el-radio>
            <el-radio :value="0">停用</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="form.remark" type="textarea" :rows="2" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="onSave">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Link } from '@element-plus/icons-vue'
import { apiAuthApi } from '@/api/sys-ext'
import type { ApiAuthConfig, IdempotentRecord } from '@/types/bo'

const loading = ref(false)
const idemLoading = ref(false)
const tableData = ref<ApiAuthConfig[]>([])
const idemRecords = ref<IdempotentRecord[]>([])
const idemTotal = ref(0)
const dialogVisible = ref(false)
const dialogMode = ref<'add' | 'edit'>('add')

const form = reactive<Partial<ApiAuthConfig>>({
  auth_type: 'oauth2',
  client_id: '', client_secret: '', token_url: '/oauth2/token', scope: '',
  api_key: '', api_key_header: 'X-API-Key',
  jwt_secret: '', jwt_expire_minutes: 60,
  idempotent_enabled: 1, idempotent_header: 'X-Idempotency-Key', idempotent_ttl_seconds: 600,
  swagger_enabled: 1, swagger_url: '/swagger-ui/index.html',
  status: 1, remark: ''
})

const idemQuery = reactive({ keyword: '', pageNum: 1, pageSize: 10 })

const dialogTitle = computed(() => dialogMode.value === 'add' ? '新增鉴权配置' : '编辑鉴权配置')

const AUTH_LABELS: Record<string, string> = { oauth2: 'OAuth2', api_key: 'API Key', jwt: 'JWT', basic: 'Basic Auth' }
function authTypeLabel(t: string) { return AUTH_LABELS[t] || t }
function authTypeTag(t: string): '' | 'success' | 'warning' | 'info' | 'danger' {
  const m: Record<string, '' | 'success' | 'warning' | 'info' | 'danger'> = { oauth2: 'success', api_key: 'warning', jwt: '', basic: 'info' }
  return m[t] || 'info'
}

async function loadData() {
  loading.value = true
  try {
    tableData.value = await apiAuthApi.list()
  } finally {
    loading.value = false
  }
}

async function loadIdemRecords() {
  idemLoading.value = true
  try {
    const res: any = await apiAuthApi.idempotentRecords(idemQuery)
    idemRecords.value = res.list || []
    idemTotal.value = res.total || 0
  } finally {
    idemLoading.value = false
  }
}

function onAdd() {
  dialogMode.value = 'add'
  Object.assign(form, {
    id: undefined, auth_type: 'oauth2',
    client_id: '', client_secret: '', token_url: '/oauth2/token', scope: '',
    api_key: '', api_key_header: 'X-API-Key',
    jwt_secret: '', jwt_expire_minutes: 60,
    idempotent_enabled: 1, idempotent_header: 'X-Idempotency-Key', idempotent_ttl_seconds: 600,
    swagger_enabled: 1, swagger_url: '/swagger-ui/index.html',
    status: 1, remark: ''
  })
  dialogVisible.value = true
}

function onEdit(row: ApiAuthConfig) {
  dialogMode.value = 'edit'
  Object.assign(form, { ...row })
  dialogVisible.value = true
}

async function onSave() {
  if (dialogMode.value === 'add') {
    await apiAuthApi.create({ ...form })
    ElMessage.success('新增成功')
  } else {
    await apiAuthApi.update((form as ApiAuthConfig).id!, { ...form })
    ElMessage.success('保存成功')
  }
  dialogVisible.value = false
  loadData()
}

async function onDelete(row: ApiAuthConfig) {
  await ElMessageBox.confirm('确定删除该鉴权配置？', '提示', { type: 'warning' })
  await apiAuthApi.delete(row.id!)
  ElMessage.success('删除成功')
  loadData()
}

function onOpenSwagger() {
  const enabled = tableData.value.find(a => a.swagger_enabled === 1 && a.status === 1)
  if (!enabled || !enabled.swagger_url) {
    ElMessage.warning('未启用 Swagger 文档，请先在鉴权配置中启用')
    return
  }
  ElMessage.info(`Swagger 文档入口：${enabled.swagger_url}（原型不打开外链，实际部署为同源地址）`)
}

onMounted(() => {
  loadData()
  loadIdemRecords()
})
</script>

<style scoped lang="scss">
.aa-page {
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.table-panel, .idem-panel { padding: 12px; }
.idem-panel { flex: 1; }
.panel-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 12px;
  padding-bottom: 8px;
  border-bottom: 1px solid #ebeef5;
}
.panel-title { font-size: 14px; font-weight: 600; }
.header-actions { display: flex; gap: 8px; }
.mono { font-family: Consolas, Monaco, monospace; font-size: 12px; color: #1564ff; }
.json-cell { font-family: Consolas, Monaco, monospace; font-size: 12px; color: #606266; }
.pagination-bar { margin-top: 12px; display: flex; justify-content: flex-end; }
:deep(.el-divider__text) { font-size: 13px; font-weight: 600; }
</style>
