<template>
  <div class="audit-log-container">
    <el-card class="filter-card">
      <template #header>
        <div class="card-header">
          <span>审计日志查询</span>
          <el-button type="primary" @click="handleRefresh" :icon="Refresh">刷新</el-button>
        </div>
      </template>

      <!-- 查询条件 -->
      <el-form :model="queryForm" inline>
        <el-form-item label="操作者ID">
          <el-input v-model.number="queryForm.actorId" placeholder="请输入操作者ID" clearable style="width: 150px" />
        </el-form-item>

        <el-form-item label="操作者类型">
          <el-select v-model="queryForm.actorType" placeholder="请选择" clearable style="width: 150px">
            <el-option label="管理员" value="admin" />
            <el-option label="医生" value="doctor" />
            <el-option label="患者" value="patient" />
          </el-select>
        </el-form-item>

        <el-form-item label="操作行为">
          <el-input v-model="queryForm.action" placeholder="请输入操作行为" clearable style="width: 200px" />
        </el-form-item>

        <el-form-item label="目标实体">
          <el-input v-model="queryForm.targetEntity" placeholder="请输入目标实体" clearable style="width: 150px" />
        </el-form-item>

        <el-form-item label="时间范围">
          <el-date-picker
            v-model="dateRange"
            type="datetimerange"
            range-separator="至"
            start-placeholder="开始时间"
            end-placeholder="结束时间"
            value-format="YYYY-MM-DDTHH:mm:ss"
            style="width: 380px"
          />
        </el-form-item>

        <el-form-item>
          <el-button type="primary" @click="handleSearch" :icon="Search">查询</el-button>
          <el-button @click="handleReset" :icon="RefreshRight">重置</el-button>
          <el-button type="success" @click="handleExport" :icon="Download">导出</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- 统计信息卡片 -->
    <el-row :gutter="20" style="margin: 20px 0">
      <el-col :span="6">
        <el-card>
          <el-statistic title="总记录数" :value="statistics.total" />
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card>
          <el-statistic title="今日操作" :value="statistics.today" />
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card>
          <el-statistic title="本周操作" :value="statistics.week" />
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card>
          <el-statistic title="本月操作" :value="statistics.month" />
        </el-card>
      </el-col>
    </el-row>

    <!-- 日志列表 -->
    <el-card>
      <el-table :data="logList" style="width: 100%" v-loading="loading" border stripe>
        <el-table-column prop="logId" label="日志ID" width="80" />
        <el-table-column prop="actorType" label="操作者类型" width="100">
          <template #default="scope">
            <el-tag :type="getActorTypeTag(scope.row.actorType)">
              {{ getActorTypeLabel(scope.row.actorType) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="actorId" label="操作者ID" width="100" />
        <el-table-column prop="action" label="操作行为" width="200" show-overflow-tooltip />
        <el-table-column prop="targetEntity" label="目标实体" width="120" />
        <el-table-column prop="targetId" label="目标ID" width="100" />
        <el-table-column prop="createdAt" label="操作时间" width="180" />
        <el-table-column label="操作">
          <template #default="scope">
            <el-button type="primary" size="small" @click="handleViewDetails(scope.row)">
              详情
            </el-button>
          </template>
        </el-table-column>
      </el-table>

      <!-- 分页 -->
      <div class="pagination-container">
        <el-pagination
          v-model:current-page="pagination.page"
          v-model:page-size="pagination.size"
          :page-sizes="[10, 20, 50, 100]"
          :total="pagination.total"
          layout="total, sizes, prev, pager, next, jumper"
          @size-change="handleSizeChange"
          @current-change="handlePageChange"
        />
      </div>
    </el-card>

    <!-- 详情对话框 - 美化版 -->
    <el-dialog 
      v-model="detailDialogVisible" 
      title="审计日志详情" 
      width="800px"
      :close-on-click-modal="false"
      class="audit-detail-dialog"
    >
      <div class="audit-detail-content">
        <!-- 基本信息卡片 -->
        <el-card class="info-card" shadow="never">
          <template #header>
            <div class="card-title">
              <el-icon><Document /></el-icon>
              <span>基本信息</span>
            </div>
          </template>
          <div class="info-grid">
            <div class="info-item">
              <span class="info-label">日志ID</span>
              <span class="info-value">
                <el-tag type="info" size="small">{{ currentLog.logId }}</el-tag>
              </span>
            </div>
            <div class="info-item">
              <span class="info-label">操作时间</span>
              <span class="info-value">
                <el-icon><Clock /></el-icon>
                {{ currentLog.createdAt }}
              </span>
            </div>
            <div class="info-item">
              <span class="info-label">操作者类型</span>
              <span class="info-value">
                <el-tag :type="getActorTypeTag(currentLog.actorType)" size="default">
                  {{ getActorTypeLabel(currentLog.actorType) }}
                </el-tag>
              </span>
            </div>
            <div class="info-item">
              <span class="info-label">操作者ID</span>
              <span class="info-value">
                <el-tag type="warning" size="small">{{ currentLog.actorId }}</el-tag>
              </span>
            </div>
          </div>
        </el-card>

        <!-- 操作信息卡片 -->
        <el-card class="info-card" shadow="never">
          <template #header>
            <div class="card-title">
              <el-icon><Operation /></el-icon>
              <span>操作信息</span>
            </div>
          </template>
          <div class="info-grid">
            <div class="info-item full-width">
              <span class="info-label">操作行为</span>
              <span class="info-value action-text">{{ currentLog.action }}</span>
            </div>
            <div class="info-item">
              <span class="info-label">目标实体</span>
              <span class="info-value">
                <el-tag type="success" effect="plain">{{ currentLog.targetEntity }}</el-tag>
              </span>
            </div>
            <div class="info-item">
              <span class="info-label">目标ID</span>
              <span class="info-value">
                <el-tag type="primary" effect="plain">{{ currentLog.targetId }}</el-tag>
              </span>
            </div>
          </div>
        </el-card>

        <!-- 详细信息卡片 -->
        <el-card class="info-card details-card" shadow="never">
          <template #header>
            <div class="card-title">
              <el-icon><Tickets /></el-icon>
              <span>详细信息</span>
              <el-button 
                v-if="currentLog.details" 
                size="small" 
                text 
                @click="copyDetails"
                style="margin-left: auto;"
              >
                <el-icon><CopyDocument /></el-icon>
                复制
              </el-button>
            </div>
          </template>
          <div class="json-viewer" v-if="currentLog.details">
            <pre class="json-content">{{ formatDetails(currentLog.details) }}</pre>
          </div>
          <div v-else class="no-details">
            <el-empty description="暂无详细信息" :image-size="80" />
          </div>
        </el-card>
      </div>

      <template #footer>
        <div class="dialog-footer">
          <el-button @click="detailDialogVisible = false" size="large">关闭</el-button>
        </div>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { Search, Refresh, RefreshRight, Download, Document, Clock, Operation, Tickets, CopyDocument } from '@element-plus/icons-vue'
import request from '@/utils/request'

// 查询表单
const queryForm = reactive({
  actorId: null,
  actorType: '',
  action: '',
  targetEntity: '',
  targetId: null,
  page: 0,
  size: 20
})

// 时间范围
const dateRange = ref([])

// 日志列表
const logList = ref([])
const loading = ref(false)

// 分页信息
const pagination = reactive({
  page: 1,
  size: 20,
  total: 0
})

// 统计信息
const statistics = reactive({
  total: 0,
  today: 0,
  week: 0,
  month: 0
})

// 详情对话框
const detailDialogVisible = ref(false)
const currentLog = ref({})

// 获取审计日志列表
const fetchAuditLogs = async () => {
  loading.value = true
  try {
    const params = {
      ...queryForm,
      page: pagination.page - 1, // 后端从0开始
      size: pagination.size
    }

    // 处理时间范围
    if (dateRange.value && dateRange.value.length === 2) {
      params.startTime = dateRange.value[0]
      params.endTime = dateRange.value[1]
    }

    // 移除空值
    Object.keys(params).forEach(key => {
      if (params[key] === '' || params[key] === null || params[key] === undefined) {
        delete params[key]
      }
    })

    const response = await request.post('/api/audit-logs/search', params)
    
    if (response.code === '200') {
      const data = response.data
      logList.value = data.content
      pagination.total = data.totalElements
    } else {
      ElMessage.error(response.msg || '查询失败')
    }
  } catch (error) {
    console.error('Failed to fetch audit logs:', error)
    ElMessage.error('查询审计日志失败')
  } finally {
    loading.value = false
  }
}

// 获取统计信息
const fetchStatistics = async () => {
  try {
    const response = await request.get('/api/audit-logs/statistics')
    if (response.code === '200') {
      const data = response.data
      statistics.total = data.total || 0
      statistics.today = data.today || 0
      statistics.week = data.week || 0
      statistics.month = data.month || 0
      console.log('统计信息已更新:', statistics)
    }
  } catch (error) {
    console.error('Failed to fetch statistics:', error)
  }
}

// 查询
const handleSearch = () => {
  pagination.page = 1
  fetchAuditLogs()
}

// 重置
const handleReset = () => {
  Object.assign(queryForm, {
    actorId: null,
    actorType: '',
    action: '',
    targetEntity: '',
    targetId: null
  })
  dateRange.value = []
  pagination.page = 1
  fetchAuditLogs()
}

// 刷新
const handleRefresh = () => {
  fetchAuditLogs()
  fetchStatistics()
}

// 分页大小改变
const handleSizeChange = (size) => {
  pagination.size = size
  fetchAuditLogs()
}

// 页码改变
const handlePageChange = (page) => {
  pagination.page = page
  fetchAuditLogs()
}

// 查看详情
const handleViewDetails = (row) => {
  currentLog.value = row
  detailDialogVisible.value = true
}

// 导出
const handleExport = () => {
  ElMessage.info('导出功能开发中...')
  // 这里可以实现导出Excel功能
}

// 获取操作者类型标签
const getActorTypeTag = (type) => {
  const tagMap = {
    admin: 'danger',
    doctor: 'success',
    patient: 'info'
  }
  return tagMap[type] || ''
}

// 获取操作者类型标签文本
const getActorTypeLabel = (type) => {
  const labelMap = {
    admin: '管理员',
    doctor: '医生',
    patient: '患者'
  }
  return labelMap[type] || type
}

// 格式化详细信息
const formatDetails = (details) => {
  if (!details) return '无'
  try {
    return JSON.stringify(JSON.parse(details), null, 2)
  } catch {
    return details
  }
}

// 复制详细信息
const copyDetails = async () => {
  try {
    const details = formatDetails(currentLog.value.details)
    await navigator.clipboard.writeText(details)
    ElMessage.success('复制成功！')
  } catch (error) {
    ElMessage.error('复制失败，请手动复制')
  }
}

// 初始化
onMounted(() => {
  fetchAuditLogs()
  fetchStatistics()
})
</script>

<style scoped>
.audit-log-container {
  padding: 20px;
}

.filter-card {
  margin-bottom: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.pagination-container {
  margin-top: 20px;
  display: flex;
  justify-content: flex-end;
}

/* 审计详情弹窗样式 */
.audit-detail-dialog :deep(.el-dialog__body) {
  padding: 20px;
  background: linear-gradient(to bottom, #f8f9fa 0%, #ffffff 100%);
}

.audit-detail-content {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.info-card {
  border-radius: 12px;
  overflow: hidden;
  transition: all 0.3s ease;
}

.info-card:hover {
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
}

.info-card :deep(.el-card__header) {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  padding: 12px 20px;
  border-bottom: none;
}

.info-card.details-card :deep(.el-card__header) {
  background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
}

.card-title {
  display: flex;
  align-items: center;
  gap: 8px;
  color: white;
  font-weight: 600;
  font-size: 15px;
}

.card-title .el-icon {
  font-size: 18px;
}

.info-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 20px;
  padding: 8px 0;
}

.info-item {
  display: flex;
  flex-direction: column;
  gap: 8px;
  padding: 12px;
  background: #f8f9fa;
  border-radius: 8px;
  transition: all 0.2s ease;
}

.info-item:hover {
  background: #e9ecef;
  transform: translateY(-2px);
}

.info-item.full-width {
  grid-column: 1 / -1;
}

.info-label {
  font-size: 13px;
  color: #6c757d;
  font-weight: 500;
  display: flex;
  align-items: center;
  gap: 4px;
}

.info-value {
  font-size: 14px;
  color: #212529;
  font-weight: 500;
  display: flex;
  align-items: center;
  gap: 6px;
}

.action-text {
  color: #495057;
  font-size: 14px;
  line-height: 1.6;
  padding: 4px 0;
}

/* JSON查看器样式 */
.json-viewer {
  border-radius: 8px;
  overflow: hidden;
  border: 1px solid #e9ecef;
}

.json-content {
  background: linear-gradient(to bottom, #2d3748 0%, #1a202c 100%);
  color: #68d391;
  padding: 20px;
  margin: 0;
  font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', 'Consolas', monospace;
  font-size: 13px;
  line-height: 1.6;
  overflow-x: auto;
  max-height: 400px;
  overflow-y: auto;
  border-radius: 8px;
  box-shadow: inset 0 2px 8px rgba(0, 0, 0, 0.3);
}

.json-content::-webkit-scrollbar {
  width: 8px;
  height: 8px;
}

.json-content::-webkit-scrollbar-track {
  background: #1a202c;
  border-radius: 4px;
}

.json-content::-webkit-scrollbar-thumb {
  background: #4a5568;
  border-radius: 4px;
}

.json-content::-webkit-scrollbar-thumb:hover {
  background: #718096;
}

.no-details {
  padding: 40px 0;
  text-align: center;
}

.dialog-footer {
  display: flex;
  justify-content: center;
  padding: 10px 0;
}

/* 美化标签 */
.info-value .el-tag {
  font-weight: 500;
  border-radius: 6px;
  padding: 4px 12px;
}

/* 时钟图标动画 */
.info-value .el-icon {
  color: #667eea;
  font-size: 16px;
}

/* 响应式 */
@media (max-width: 768px) {
  .info-grid {
    grid-template-columns: 1fr;
  }
  
  .audit-detail-dialog :deep(.el-dialog) {
    width: 95% !important;
  }
}
</style>


