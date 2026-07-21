<template>
  <div class="code-rule-page">
    <!-- 顶部 -->
    <div class="page-header panel-card">
      <div class="header-left">
        <span class="header-title">编码规则配置</span>
        <el-tag size="small" type="info" effect="plain">共 {{ list.length }} 条</el-tag>
      </div>
      <div class="header-right">
        <el-button type="primary" size="small" @click="onAdd">
          <el-icon><Plus /></el-icon>新增规则
        </el-button>
      </div>
    </div>

    <!-- 主体 -->
    <div class="main-body">
      <!-- 左：规则列表 -->
      <div class="rule-list-panel panel-card">
        <div class="panel-header">
          <span class="panel-title">规则列表</span>
        </div>
        <div class="list-wrap">
          <el-empty v-if="!list.length" description="暂无规则" :image-size="50" />
          <ul v-else class="rule-list">
            <li
              v-for="r in list"
              :key="r.id"
              class="rule-item"
              :class="{ active: selectedId === r.id }"
              @click="onSelectRule(r)"
            >
              <div class="rule-item-head">
                <span class="rule-code">{{ r.rule_code }}</span>
                <el-tag size="small" :type="r.status === 1 ? 'success' : 'info'" effect="plain">
                  {{ r.status === 1 ? '启用' : '停用' }}
                </el-tag>
              </div>
              <div class="rule-name">{{ r.rule_name }}</div>
              <div class="rule-bo">
                <el-icon><Box /></el-icon>
                <span>{{ r.bo_code }}</span>
              </div>
              <div class="rule-org">
                <el-icon><OfficeBuilding /></el-icon>
                <span>{{ orgNameById(r.org_id) }}</span>
              </div>
            </li>
          </ul>
        </div>
      </div>

      <!-- 右：详情编辑 -->
      <div class="rule-detail-panel panel-card">
        <div class="panel-header">
          <span class="panel-title">{{ isNew ? '新增规则' : '规则详情' }}</span>
          <span v-if="form.rule_code" class="panel-tip">{{ form.rule_code }}</span>
        </div>
        <div class="detail-body">
          <!-- 基本信息 -->
          <div class="section">
            <div class="section-title">基本信息</div>
            <el-form :model="form" label-width="110px" size="small" label-position="right">
              <el-row :gutter="12">
                <el-col :span="12">
                  <el-form-item label="规则编码">
                    <el-input v-model="form.rule_code" placeholder="如 SO_CODE" />
                  </el-form-item>
                </el-col>
                <el-col :span="12">
                  <el-form-item label="规则名称">
                    <el-input v-model="form.rule_name" placeholder="如 销售订单编码" />
                  </el-form-item>
                </el-col>
                <el-col :span="12">
                  <el-form-item label="业务对象">
                    <el-input v-model="form.bo_code" placeholder="如 sal_order" />
                  </el-form-item>
                </el-col>
                <el-col :span="12">
                  <el-form-item label="适用组织">
                    <el-select
                      v-model="form.org_id"
                      placeholder="空表示集团通用"
                      clearable
                      filterable
                      style="width: 100%"
                    >
                      <el-option
                        v-for="o in orgOptions"
                        :key="o.id"
                        :label="`${o.org_name}（${orgTypeLabel(o.org_type)}）`"
                        :value="o.id"
                      />
                    </el-select>
                  </el-form-item>
                </el-col>
                <el-col :span="12">
                  <el-form-item label="重置类型">
                    <el-select v-model="form.reset_type" style="width: 100%">
                      <el-option
                        v-for="o in RESET_TYPE_OPTIONS"
                        :key="o.value"
                        :label="o.label"
                        :value="o.value"
                      />
                    </el-select>
                  </el-form-item>
                </el-col>
                <el-col :span="12">
                  <el-form-item label="允许手动录入">
                    <el-switch v-model="form.is_manual" :active-value="1" :inactive-value="0" />
                  </el-form-item>
                </el-col>
                <el-col :span="12">
                  <el-form-item label="状态">
                    <el-switch
                      v-model="form.status"
                      :active-value="1"
                      :inactive-value="0"
                      active-text="启用"
                      inactive-text="停用"
                      inline-prompt
                    />
                  </el-form-item>
                </el-col>
              </el-row>
            </el-form>
          </div>

          <!-- 段定义 -->
          <div class="section">
            <div class="section-title">段定义</div>
            <SegmentDesigner v-model="form.segments" @preview="onPreview" />
          </div>

          <!-- 编码预览 -->
          <div class="section">
            <div class="section-title">
              <span>编码预览</span>
              <el-button
                type="primary"
                link
                size="small"
                :disabled="isNew || !form.id"
                @click="onFetchPreview"
              >
                <el-icon><Refresh /></el-icon>服务端预览
              </el-button>
            </div>
            <div class="preview-box">
              <span class="preview-label">生成编号：</span>
              <span class="preview-code">{{ previewCode || '（请添加段定义）' }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 底部 -->
    <div class="page-footer panel-card">
      <div class="footer-right">
        <el-button type="danger" size="small" :disabled="isNew || !form.id" @click="onDelete">
          <el-icon><Delete /></el-icon>删除
        </el-button>
        <el-button type="primary" size="small" @click="onSave">
          <el-icon><Check /></el-icon>保存
        </el-button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Delete, Check, Refresh, Box, OfficeBuilding } from '@element-plus/icons-vue'
import SegmentDesigner from '@/components/SegmentDesigner/index.vue'
import { codeRuleApi } from '@/api/code'
import { orgApi } from '@/api/perm'
import { RESET_TYPE_OPTIONS, ORG_TYPE_OPTIONS } from '@/utils/enum'
import type { CodeRule, Org } from '@/types/bo'

const list = ref<CodeRule[]>([])
const selectedId = ref('')
const isNew = ref(false)
const previewCode = ref('')
const orgOptions = ref<Org[]>([])

function orgTypeLabel(t: string): string {
  return ORG_TYPE_OPTIONS.find(o => o.value === t)?.label || t
}

function orgNameById(id?: string): string {
  if (!id) return '集团通用'
  return orgOptions.value.find(o => o.id === id)?.org_name || id
}

async function loadOrgs() {
  try {
    const res = await orgApi.tree()
    orgOptions.value = (res || []).filter(o => o.status === 1)
  } catch {
    orgOptions.value = []
  }
}

function emptyForm(): CodeRule {
  return {
    id: '',
    rule_code: '',
    rule_name: '',
    bo_code: '',
    org_id: undefined,
    segments: [],
    reset_type: 'none',
    is_manual: 1,
    status: 1
  }
}

const form = reactive<CodeRule>(emptyForm())

async function loadList() {
  const res: any = await codeRuleApi.list()
  list.value = Array.isArray(res) ? res : res?.list || []
  if (list.value.length) {
    onSelectRule(list.value[0])
  } else {
    // 列表为空：进入新建态（避免 form.id 为空却走 update 分支导致 PUT /code-rule/ 403）
    const f = emptyForm()
    f.id = `cr_new_${Date.now()}`
    Object.assign(form, f)
    selectedId.value = form.id
    isNew.value = true
    previewCode.value = ''
  }
}

function onSelectRule(r: CodeRule) {
  selectedId.value = r.id
  isNew.value = false
  Object.assign(form, JSON.parse(JSON.stringify(r)))
  fetchPreview(r.id)
}

function onAdd() {
  const f = emptyForm()
  f.id = `cr_new_${Date.now()}`
  Object.assign(form, f)
  selectedId.value = form.id
  isNew.value = true
  previewCode.value = ''
}

function onPreview(code: string) {
  previewCode.value = code
}

async function fetchPreview(id: string) {
  if (!id) return
  try {
    const res: any = await codeRuleApi.preview(id)
    if (res && typeof res === 'object' && 'preview' in res) {
      previewCode.value = res.preview || ''
    } else if (typeof res === 'string') {
      previewCode.value = res
    }
  } catch {
    /* mock 容错 */
  }
}

function onFetchPreview() {
  if (form.id && !isNew.value) fetchPreview(form.id)
}

async function onSave() {
  if (!form.rule_code.trim()) {
    ElMessage.warning('请输入规则编码')
    return
  }
  if (!form.rule_name.trim()) {
    ElMessage.warning('请输入规则名称')
    return
  }
  if (!form.bo_code.trim()) {
    ElMessage.warning('请输入业务对象编码')
    return
  }
  const payload: Partial<CodeRule> = {
    rule_code: form.rule_code,
    rule_name: form.rule_name,
    bo_code: form.bo_code,
    org_id: form.org_id,
    segments: form.segments.map(s => ({ ...s })),
    reset_type: form.reset_type,
    is_manual: form.is_manual,
    status: form.status
  }
  try {
    // 防御性判断：临时 id（cr_new_ 前缀）或空 id 一律走 create，避免 PUT /code-rule/ 403
    const isTempId = !form.id || form.id.startsWith('cr_new_')
    if (isNew.value || isTempId) {
      const saved: any = await codeRuleApi.create(payload)
      const id = saved?.id || form.id
      Object.assign(form, { id }, payload)
      isNew.value = false
      ElMessage.success('新增成功')
    } else {
      await codeRuleApi.update(form.id, payload)
      ElMessage.success('保存成功')
    }
    await loadList()
    const found = list.value.find(r => r.id === form.id)
    if (found) onSelectRule(found)
  } catch {
    ElMessage.error('保存失败')
  }
}

function onDelete() {
  if (isNew.value || !form.id) return
  ElMessageBox.confirm(`确定删除规则「${form.rule_name || form.rule_code}」吗？`, '提示', {
    type: 'warning'
  })
    .then(async () => {
      try {
        await codeRuleApi.delete(form.id)
      } catch {
        /* mock 容错 */
      }
      ElMessage.success('删除成功')
      await loadList()
      if (list.value.length) onSelectRule(list.value[0])
      else {
        Object.assign(form, emptyForm())
        previewCode.value = ''
      }
    })
    .catch(() => {})
}

onMounted(async () => {
  await loadOrgs()
  await loadList()
})
</script>

<style scoped lang="scss">
.code-rule-page {
  height: 100%;
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 12px;
  overflow: hidden;
}
.page-header {
  flex-shrink: 0;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 12px;
  .header-left {
    display: flex;
    align-items: center;
    gap: 10px;
    .header-title {
      font-size: 15px;
      font-weight: 600;
      color: #303133;
    }
  }
  .header-right {
    display: flex;
    gap: 6px;
  }
}
.main-body {
  flex: 1;
  display: flex;
  gap: 12px;
  min-height: 0;
}
.rule-list-panel {
  width: 320px;
  flex-shrink: 0;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}
.list-wrap {
  flex: 1;
  overflow: auto;
  padding: 4px;
}
.rule-list {
  list-style: none;
  margin: 0;
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.rule-item {
  padding: 10px;
  border: 1px solid #e4e7ed;
  border-radius: 4px;
  cursor: pointer;
  transition: all 0.15s;
  &:hover {
    border-color: #1564ff;
    background: #f0f7ff;
  }
  &.active {
    border-color: #1564ff;
    background: #ecf5ff;
    box-shadow: 0 0 0 1px #1564ff inset;
    .rule-code {
      color: #1564ff;
    }
  }
  .rule-item-head {
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin-bottom: 4px;
    .rule-code {
      font-size: 13px;
      font-weight: 600;
      color: #303133;
      font-family: 'Consolas', 'Monaco', monospace;
    }
  }
  .rule-name {
    font-size: 12px;
    color: #606266;
    margin-bottom: 6px;
  }
  .rule-bo {
    display: flex;
    align-items: center;
    gap: 4px;
    font-size: 12px;
    color: #1564ff;
    font-family: 'Consolas', 'Monaco', monospace;
    background: #f0f7ff;
    padding: 1px 6px;
    border-radius: 3px;
    width: fit-content;
  }
  .rule-org {
    display: flex;
    align-items: center;
    gap: 4px;
    font-size: 12px;
    color: #67c23a;
    background: #f0f9eb;
    padding: 1px 6px;
    border-radius: 3px;
    width: fit-content;
    margin-top: 4px;
  }
}
.rule-detail-panel {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}
.panel-header {
  flex-shrink: 0;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 8px 12px;
  border-bottom: 1px solid #f0f0f0;
  background: #fafafa;
  .panel-title {
    font-size: 13px;
    font-weight: 600;
    color: #303133;
  }
  .panel-tip {
    font-size: 12px;
    color: #1564ff;
    font-family: 'Consolas', 'Monaco', monospace;
  }
}
.detail-body {
  flex: 1;
  overflow: auto;
  padding: 12px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}
.section {
  display: flex;
  flex-direction: column;
  gap: 8px;
}
.section-title {
  font-size: 13px;
  font-weight: 600;
  color: #303133;
  padding-left: 8px;
  border-left: 3px solid #1564ff;
  display: flex;
  align-items: center;
  justify-content: space-between;
}
.preview-box {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 14px 16px;
  background: linear-gradient(90deg, #f0f7ff 0%, #fff 100%);
  border: 1px solid #e4e7ed;
  border-radius: 4px;
  .preview-label {
    font-size: 13px;
    color: #606266;
    flex-shrink: 0;
  }
  .preview-code {
    font-family: 'Consolas', 'Monaco', monospace;
    font-size: 18px;
    font-weight: 700;
    color: #1564ff;
    letter-spacing: 1px;
  }
}
.page-footer {
  flex-shrink: 0;
  display: flex;
  align-items: center;
  justify-content: flex-end;
  padding: 8px 12px;
  .footer-right {
    display: flex;
    gap: 8px;
  }
}
:deep(.el-empty) {
  padding: 16px;
}
</style>
