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

    <!-- 详情对话框 -->
    <el-dialog v-model="detailDialogVisible" title="审计日志详情" width="700px">
      <el-descriptions :column="2" border>
        <el-descriptions-item label="日志ID">{{ currentLog.logId }}</el-descriptions-item>
        <el-descriptions-item label="操作者ID">{{ currentLog.actorId }}</el-descriptions-item>
        <el-descriptions-item label="操作者类型">
          {{ getActorTypeLabel(currentLog.actorType) }}
        </el-descriptions-item>
        <el-descriptions-item label="操作时间">{{ currentLog.createdAt }}</el-descriptions-item>
        <el-descriptions-item label="操作行为" :span="2">{{ currentLog.action }}</el-descriptions-item>
        <el-descriptions-item label="目标实体">{{ currentLog.targetEntity }}</el-descriptions-item>
        <el-descriptions-item label="目标ID">{{ currentLog.targetId }}</el-descriptions-item>
        <el-descriptions-item label="详细信息" :span="2">
          <pre style="max-height: 300px; overflow: auto;">{{ formatDetails(currentLog.details) }}</pre>
        </el-descriptions-item>
      </el-descriptions>
      <template #footer>
        <el-button @click="detailDialogVisible = false">关闭</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { Search, Refresh, RefreshRight, Download } from '@element-plus/icons-vue'
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
      statistics.total = response.data.total
      // 这里可以根据实际返回的数据设置今日、本周、本月的统计
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

pre {
  background-color: #f5f5f5;
  padding: 10px;
  border-radius: 4px;
  font-size: 12px;
}
</style>

