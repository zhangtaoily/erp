<template>
  <div class="sec-page page-container">
    <!-- 策略配置 -->
    <div class="panel-card policy-panel">
      <div class="panel-header">
        <span class="panel-title">登录安全策略</span>
        <el-button type="primary" size="small" :loading="saving" @click="onSave">保存策略</el-button>
      </div>
      <el-form v-if="policy" :model="policy" label-width="140px" size="small" v-loading="loading">
        <el-divider content-position="left">密码策略</el-divider>
        <el-row :gutter="16">
          <el-col :span="8">
            <el-form-item label="最小长度">
              <el-input-number v-model="policy.pwd_min_length" :min="6" :max="32" controls-position="right" style="width:100%" />
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="密码复杂度">
              <el-select v-model="policy.pwd_complexity" style="width:100%">
                <el-option label="低（字母+数字）" value="low" />
                <el-option label="中（大小写+数字）" value="mid" />
                <el-option label="高（大小写+数字+特殊符号）" value="high" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="有效期（天）">
              <el-input-number v-model="policy.pwd_expire_days" :min="0" :max="365" controls-position="right" style="width:100%" />
              <div class="form-tip">0 表示永久</div>
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="历史密码不可重复">
              <el-input-number v-model="policy.pwd_history_count" :min="0" :max="24" controls-position="right" style="width:100%" />
            </el-form-item>
          </el-col>
        </el-row>

        <el-divider content-position="left">失败锁定</el-divider>
        <el-row :gutter="16">
          <el-col :span="8">
            <el-form-item label="锁定阈值（次）">
              <el-input-number v-model="policy.fail_lock_threshold" :min="3" :max="10" controls-position="right" style="width:100%" />
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="锁定时长（分钟）">
              <el-input-number v-model="policy.fail_lock_minutes" :min="1" :max="1440" controls-position="right" style="width:100%" />
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="验证码触发（次）">
              <el-input-number v-model="policy.captcha_threshold" :min="1" :max="10" controls-position="right" style="width:100%" />
              <div class="form-tip">失败 N 次后强制验证码</div>
            </el-form-item>
          </el-col>
        </el-row>

        <el-divider content-position="left">会话与审计</el-divider>
        <el-row :gutter="16">
          <el-col :span="8">
            <el-form-item label="会话超时（分钟）">
              <el-input-number v-model="policy.session_timeout_minutes" :min="5" :max="480" controls-position="right" style="width:100%" />
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="审计登录">
              <el-radio-group v-model="policy.audit_login">
                <el-radio :value="1">是</el-radio>
                <el-radio :value="0">否</el-radio>
              </el-radio-group>
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="审计关键操作">
              <el-radio-group v-model="policy.audit_operation">
                <el-radio :value="1">是</el-radio>
                <el-radio :value="0">否</el-radio>
              </el-radio-group>
            </el-form-item>
          </el-col>
        </el-row>
      </el-form>
    </div>

    <!-- 审计日志 -->
    <div class="panel-card table-panel">
      <div class="panel-header">
        <span class="panel-title">登录审计日志</span>
        <div class="filter-bar">
          <el-select v-model="query.login_type" clearable placeholder="类型" style="width:110px" @change="onSearch">
            <el-option v-for="t in loginTypes" :key="t.value" :label="t.label" :value="t.value" />
          </el-select>
          <el-select v-model="query.result" clearable placeholder="结果" style="width:100px" @change="onSearch">
            <el-option label="成功" value="success" />
            <el-option label="失败" value="fail" />
          </el-select>
          <el-input v-model="query.user_code" clearable placeholder="账号关键字" style="width:160px" @keyup.enter="onSearch" />
          <el-button type="primary" size="small" @click="onSearch">查询</el-button>
          <el-button size="small" @click="onReset">重置</el-button>
        </div>
      </div>
      <el-table :data="tableData" size="small" border stripe v-loading="logLoading">
        <el-table-column type="index" label="#" width="45" />
        <el-table-column prop="create_time" label="时间" width="160" />
        <el-table-column label="类型" width="90">
          <template #default="{ row }">
            <el-tag :type="loginTypeTag(row.login_type) || 'info'" size="small">{{ loginTypeLabel(row.login_type) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="user_code" label="账号" width="120" />
        <el-table-column prop="user_name" label="姓名" width="100" />
        <el-table-column prop="ip" label="IP" width="130" />
        <el-table-column prop="client" label="客户端" min-width="180" show-overflow-tooltip />
        <el-table-column label="结果" width="80">
          <template #default="{ row }">
            <el-tag :type="row.result === 'success' ? 'success' : 'danger'" size="small">{{ row.result === 'success' ? '成功' : '失败' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="error_msg" label="错误信息" min-width="200" show-overflow-tooltip />
      </el-table>
      <div class="pagination-bar">
        <el-pagination
          v-model:current-page="query.pageNum"
          v-model:page-size="query.pageSize"
          :total="total"
          :page-sizes="[10, 20, 50]"
          layout="total, sizes, prev, pager, next, jumper"
          background
          @size-change="loadLogs"
          @current-change="loadLogs"
        />
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { securityApi } from '@/api/sys-ext'
import type { SecurityPolicy, LoginAuditLog } from '@/types/bo'

const loading = ref(false)
const logLoading = ref(false)
const saving = ref(false)
const policy = ref<SecurityPolicy | null>(null)
const tableData = ref<LoginAuditLog[]>([])
const total = ref(0)

const query = reactive({
  login_type: '' as string,
  result: '' as string,
  user_code: '',
  pageNum: 1,
  pageSize: 10
})

const loginTypes = [
  { value: 'login', label: '登录' },
  { value: 'logout', label: '登出' },
  { value: 'fail', label: '失败' },
  { value: 'lock', label: '锁定' },
  { value: 'unlock', label: '解锁' }
]
function loginTypeLabel(t: string) {
  return loginTypes.find(x => x.value === t)?.label || t
}
function loginTypeTag(t: string): '' | 'success' | 'warning' | 'info' | 'danger' {
  const m: Record<string, '' | 'success' | 'warning' | 'info' | 'danger'> = {
    login: 'success', logout: 'info', fail: 'danger', lock: 'warning', unlock: ''
  }
  return m[t] || 'info'
}

async function loadPolicy() {
  loading.value = true
  try {
    policy.value = await securityApi.getPolicy()
  } finally {
    loading.value = false
  }
}

async function loadLogs() {
  logLoading.value = true
  try {
    const res: any = await securityApi.auditLogs(query)
    tableData.value = res.list || []
    total.value = res.total || 0
  } finally {
    logLoading.value = false
  }
}

function onSearch() {
  query.pageNum = 1
  loadLogs()
}
function onReset() {
  query.login_type = ''
  query.result = ''
  query.user_code = ''
  query.pageNum = 1
  loadLogs()
}

async function onSave() {
  if (!policy.value) return
  saving.value = true
  try {
    await securityApi.savePolicy({ ...policy.value })
    ElMessage.success('安全策略已保存')
  } finally {
    saving.value = false
  }
}

onMounted(() => {
  loadPolicy()
  loadLogs()
})
</script>

<style scoped lang="scss">
.sec-page {
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.policy-panel { padding: 12px 16px; }
.table-panel { padding: 12px; flex: 1; }
.panel-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 12px;
  padding-bottom: 8px;
  border-bottom: 1px solid #ebeef5;
}
.panel-title { font-size: 14px; font-weight: 600; }
.filter-bar {
  display: flex;
  align-items: center;
  gap: 8px;
}
.form-tip {
  font-size: 12px;
  color: #909399;
  line-height: 1.4;
  margin-top: 2px;
}
.pagination-bar { margin-top: 12px; display: flex; justify-content: flex-end; }
:deep(.el-divider__text) { font-size: 13px; font-weight: 600; }
</style>
