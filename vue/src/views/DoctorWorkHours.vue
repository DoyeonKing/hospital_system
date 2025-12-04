<template>
  <div class="doctor-work-hours">
    <div class="top-navbar">
      <div class="navbar-content">
        <div class="navbar-left">
          <el-button :icon="ArrowLeft" @click="goBack">返回</el-button>
          <h2>我的工时统计</h2>
        </div>
        <div class="navbar-right">
          <el-button type="primary" @click="exportData" :disabled="!workHoursList.length" :loading="exporting">导出PDF</el-button>
        </div>
      </div>
    </div>

    <div class="main-content">
      <!-- 统计卡片 -->
      <div class="stats-row" v-loading="loading">
        <div class="stat-card">
          <div class="stat-icon primary">
            <el-icon :size="32"><Clock /></el-icon>
          </div>
          <div class="stat-info">
            <p class="stat-label">总工时</p>
            <h3 class="stat-value">{{ totalHours.toFixed(2) }}h</h3>
          </div>
        </div>

        <div class="stat-card">
          <div class="stat-icon success">
            <el-icon :size="32"><User /></el-icon>
          </div>
          <div class="stat-info">
            <p class="stat-label">总接诊人次</p>
            <h3 class="stat-value">{{ totalVisits }}</h3>
          </div>
        </div>

        <div class="stat-card">
          <div class="stat-icon warning">
            <el-icon :size="32"><Moon /></el-icon>
          </div>
          <div class="stat-info">
            <p class="stat-label">夜班次数</p>
            <h3 class="stat-value">{{ nightShifts }}</h3>
          </div>
        </div>

        <div class="stat-card">
          <div class="stat-icon danger">
            <el-icon :size="32"><TrendCharts /></el-icon>
          </div>
          <div class="stat-info">
            <p class="stat-label">绩效点数</p>
            <h3 class="stat-value">{{ totalPerformance.toFixed(2) }}</h3>
          </div>
        </div>
      </div>

      <!-- 筛选区域 -->
      <el-card class="filter-card">
        <el-alert
          type="info"
          :closable="false"
          style="margin-bottom: 16px;"
          title="计算逻辑提示"
          description="仅统计状态为 completed 且存在 check_in_time 的号源；同一医生同一天按时间排序，空档 ≥ 90 分钟自动切成多段；每段工时 = 首诊至末诊跨度并统一 +0.5h 缓冲，夜班判定：首诊时间 > 18:00（不含18:00整点）。"
          show-icon
        />
        <el-form :inline="true" :model="filters">
          <el-form-item label="日期范围">
            <el-date-picker
              v-model="filters.dateRange"
              type="daterange"
              start-placeholder="开始日期"
              end-placeholder="结束日期"
              value-format="YYYY-MM-DD"
              range-separator="至"
              :unlink-panels="true"
            />
          </el-form-item>
          <el-form-item>
            <el-button type="primary" @click="loadWorkHours">查询</el-button>
            <el-button @click="resetFilters">重置</el-button>
          </el-form-item>
        </el-form>
      </el-card>

      <!-- 数据表格 -->
      <el-card class="table-card">
        <el-table :data="workHoursList" v-loading="loading" border stripe>
          <el-table-column prop="workDate" label="日期" width="120" />
          <el-table-column prop="segmentLabel" label="班段" width="100" />
          <el-table-column label="首诊时间" width="170">
            <template #default="{ row }">
              {{ row.firstCallDisplay || '-' }}
            </template>
          </el-table-column>
          <el-table-column label="末诊时间" width="170">
            <template #default="{ row }">
              {{ row.lastEndDisplay || '-' }}
            </template>
          </el-table-column>
          <el-table-column prop="rawHours" label="原始工时(h)" width="130">
            <template #default="{ row }">
              {{ Number(row.rawHours).toFixed(2) }}
            </template>
          </el-table-column>
          <el-table-column prop="regHours" label="挂号工时(h)" width="140">
            <template #default="{ row }">
              {{ Number(row.regHours).toFixed(2) }}
            </template>
          </el-table-column>
          <el-table-column prop="visitCount" label="门诊人次" width="110" />
          <el-table-column label="夜班" width="90">
            <template #default="{ row }">
              <el-tag :type="row.nightFlag ? 'danger' : 'info'" size="small">
                {{ row.nightFlag ? '夜班' : '否' }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="locations" label="诊室/地点" min-width="160" />
          <el-table-column prop="performancePoints" label="绩效点数" width="120">
            <template #default="{ row }">
              {{ Number(row.performancePoints).toFixed(2) }}
            </template>
          </el-table-column>
        </el-table>

        <el-empty v-if="!loading && workHoursList.length === 0" description="暂无工时数据" />
      </el-card>
    </div>

    <!-- 隐藏的PDF报告内容 -->
    <div id="pdf-report-content" style="position: fixed; top: -10000px; left: -10000px; width: 794px; background: white; padding: 50px 40px; visibility: hidden; font-family: 'Microsoft YaHei', Arial, sans-serif;">
      <div style="text-align: center; margin: 0 auto 35px; max-width: 600px; border-bottom: 2px solid #333; padding-bottom: 25px;">
        <h1 style="font-size: 26px; color: #333; margin: 0 0 20px 0; font-weight: bold; letter-spacing: 2px;">医生工时统计报告</h1>
        <p style="color: #666; font-size: 14px; margin: 8px 0; line-height: 1.8;">统计期间：{{ filters.dateRange[0] }} 至 {{ filters.dateRange[1] }}</p>
        <p style="color: #666; font-size: 14px; margin: 8px 0; line-height: 1.8;">医生姓名：{{ doctorStore.detailedDoctorInfo?.name || doctorStore.detailedDoctorInfo?.fullName || doctorStore.doctorInfo?.name || '未知' }}</p>
        <p style="color: #999; font-size: 13px; margin: 8px 0; line-height: 1.8;">生成时间：{{ new Date().toLocaleString('zh-CN') }}</p>
      </div>

      <!-- 统计概览 -->
      <div style="margin-bottom: 25px;">
        <h2 style="font-size: 16px; color: #333; margin: 0 0 12px 0; font-weight: bold;">一、统计概览</h2>
        <div style="line-height: 1.8; font-size: 13px; color: #333;">
          <p style="margin: 8px 0;">• 总工时：<strong>{{ totalHours.toFixed(2) }}</strong> 小时</p>
          <p style="margin: 8px 0;">• 总接诊人次：<strong>{{ totalVisits }}</strong> 人次</p>
          <p style="margin: 8px 0;">• 夜班次数：<strong>{{ nightShifts }}</strong> 次</p>
          <p style="margin: 8px 0;">• 绩效点数：<strong>{{ totalPerformance.toFixed(2) }}</strong> 点</p>
        </div>
      </div>

      <!-- 详细记录 -->
      <div>
        <h2 style="font-size: 16px; color: #333; margin: 0 0 12px 0; font-weight: bold;">二、详细记录</h2>
        <div v-for="(row, index) in workHoursList" :key="index" style="margin-bottom: 15px; padding: 12px; background: #f9f9f9; border-left: 3px solid #409EFF; font-size: 12px; line-height: 1.6;">
          <div style="margin-bottom: 8px; font-weight: bold; color: #333; font-size: 13px;">
            {{ index + 1 }}. {{ row.workDate }} {{ row.segmentLabel }}
            <span v-if="row.nightFlag" style="color: #F56C6C; margin-left: 10px;">[夜班]</span>
          </div>
          <div style="color: #666; padding-left: 15px;">
            <p style="margin: 4px 0;">首诊时间：{{ row.firstCallDisplay || '-' }}</p>
            <p style="margin: 4px 0;">末诊时间：{{ row.lastEndDisplay || '-' }}</p>
            <p style="margin: 4px 0;">原始工时：{{ Number(row.rawHours).toFixed(2) }} 小时</p>
            <p style="margin: 4px 0;">挂号工时：{{ Number(row.regHours).toFixed(2) }} 小时</p>
            <p style="margin: 4px 0;">门诊人次：{{ row.visitCount }} 人次</p>
            <p style="margin: 4px 0;">诊室地点：{{ row.locations || '-' }}</p>
            <p style="margin: 4px 0;">绩效点数：{{ Number(row.performancePoints).toFixed(2) }} 点</p>
          </div>
        </div>
      </div>

      <!-- 页脚说明 -->
      <div style="margin-top: 25px; padding-top: 15px; border-top: 1px solid #ddd; color: #666; font-size: 11px; line-height: 1.6;">
        <h3 style="font-size: 13px; color: #333; margin: 0 0 8px 0; font-weight: bold;">三、计算说明</h3>
        <p style="margin: 4px 0;">1. 仅统计状态为 completed 且存在 check_in_time 的号源</p>
        <p style="margin: 4px 0;">2. 同一医生同一天按时间排序，空档 ≥ 90 分钟自动切成多段</p>
        <p style="margin: 4px 0;">3. 每段工时 = 首诊至末诊跨度并统一 +0.5h 缓冲</p>
        <p style="margin: 4px 0;">4. 夜班判定：首诊时间 > 18:00（不含18:00整点）</p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted, nextTick } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { ArrowLeft, Clock, User, Moon, TrendCharts } from '@element-plus/icons-vue'
import { useDoctorStore } from '@/stores/doctorStore'
import request from '@/utils/request'
import html2canvas from 'html2canvas'
import jsPDF from 'jspdf'

const router = useRouter()
const doctorStore = useDoctorStore()

const loading = ref(false)
const exporting = ref(false)
const workHoursList = ref([])

// 筛选条件
const filters = reactive({
  dateRange: []
})

// 统计数据
const totalHours = computed(() => {
  return workHoursList.value.reduce((sum, item) => sum + Number(item.regHours || 0), 0)
})

const totalVisits = computed(() => {
  return workHoursList.value.reduce((sum, item) => sum + Number(item.visitCount || 0), 0)
})

const nightShifts = computed(() => {
  return workHoursList.value.filter(item => item.nightFlag).length
})

const totalPerformance = computed(() => {
  return workHoursList.value.reduce((sum, item) => sum + Number(item.performancePoints || 0), 0)
})

// 加载工时数据
const loadWorkHours = async () => {
  if (!doctorStore.detailedDoctorInfo?.doctorId) {
    ElMessage.error('未获取到医生信息')
    return
  }

  if (!filters.dateRange || filters.dateRange.length !== 2) {
    ElMessage.warning('请选择日期范围')
    return
  }

  loading.value = true
  try {
    const params = {
      doctorId: doctorStore.detailedDoctorInfo.doctorId,
      startDate: filters.dateRange[0],
      endDate: filters.dateRange[1]
    }

    const response = await request.get('/api/reports/registration-hours', { params })
    
    // 后端直接返回数组，不是 Result 格式
    if (Array.isArray(response)) {
      // 处理返回的数据，添加显示格式
      workHoursList.value = response.map(row => ({
        ...row,
        firstCallDisplay: formatDateTime(row.firstCallTime),
        lastEndDisplay: formatDateTime(row.lastEndTime)
      }))
    } else if (response.code === '200') {
      // 兼容 Result 格式
      workHoursList.value = (response.data || []).map(row => ({
        ...row,
        firstCallDisplay: formatDateTime(row.firstCallTime),
        lastEndDisplay: formatDateTime(row.lastEndTime)
      }))
    } else {
      ElMessage.error(response.msg || '加载工时数据失败')
    }
  } catch (error) {
    console.error('加载工时数据失败:', error)
    ElMessage.error('加载工时数据失败')
  } finally {
    loading.value = false
  }
}

// 格式化日期时间显示
const formatDateTime = (dt) => {
  if (!dt) return '-'
  if (typeof dt === 'string') return dt
  // 如果是日期对象，格式化为字符串
  const d = new Date(dt)
  if (isNaN(d.getTime())) return '-'
  const pad = (n) => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}`
}

// 重置筛选
const resetFilters = () => {
  // 重置为最近30天
  const end = new Date()
  const start = new Date()
  start.setDate(start.getDate() - 30)
  
  filters.dateRange = [
    start.toISOString().split('T')[0],
    end.toISOString().split('T')[0]
  ]
  
  workHoursList.value = []
}

// 导出数据为PDF
const exportData = async () => {
  if (!workHoursList.value.length) {
    ElMessage.warning('暂无数据可导出')
    return
  }

  exporting.value = true
  try {
    ElMessage.info('正在生成PDF报告，请稍候...')
    
    await nextTick()
    await new Promise(resolve => setTimeout(resolve, 300))

    // 获取报告内容元素
    const reportContent = document.getElementById('pdf-report-content')
    if (!reportContent) {
      throw new Error('无法找到报告内容元素')
    }
    
    // 临时显示报告内容（移到屏幕外）
    const originalStyle = {
      position: reportContent.style.position,
      top: reportContent.style.top,
      left: reportContent.style.left,
      opacity: reportContent.style.opacity,
      zIndex: reportContent.style.zIndex,
      visibility: reportContent.style.visibility
    }
    
    reportContent.style.position = 'fixed'
    reportContent.style.top = '0'
    reportContent.style.left = '-10000px'
    reportContent.style.opacity = '1'
    reportContent.style.zIndex = '-1'
    reportContent.style.visibility = 'visible'
    
    await nextTick()
    await new Promise(resolve => setTimeout(resolve, 200))
    
    // 使用 html2canvas 渲染
    const canvas = await html2canvas(reportContent, {
      scale: 2,
      useCORS: true,
      logging: false,
      backgroundColor: '#ffffff',
      width: 794,
      windowWidth: 794
    })
    
    // 恢复原始样式
    reportContent.style.position = originalStyle.position
    reportContent.style.top = originalStyle.top
    reportContent.style.left = originalStyle.left
    reportContent.style.opacity = originalStyle.opacity
    reportContent.style.zIndex = originalStyle.zIndex
    reportContent.style.visibility = originalStyle.visibility
    
    // 创建 PDF
    const pdf = new jsPDF({
      orientation: 'portrait',
      unit: 'mm',
      format: 'a4',
      compress: true
    })
    
    const imgData = canvas.toDataURL('image/png')
    const pdfWidth = pdf.internal.pageSize.getWidth()
    const pdfHeight = pdf.internal.pageSize.getHeight()
    
    const contentWidth = canvas.width
    const targetWidth = pdfWidth - 20
    const scale = targetWidth / contentWidth
    
    const imgWidth = targetWidth
    const imgHeight = canvas.height * scale
    const marginX = (pdfWidth - imgWidth) / 2
    
    // 智能分页
    const pageHeightInPixels = pdfHeight / scale
    let currentY = 0
    let pageCount = 0
    
    const tempCanvas = document.createElement('canvas')
    const tempCtx = tempCanvas.getContext('2d')
    
    while (currentY < canvas.height) {
      if (pageCount > 0) {
        pdf.addPage()
      }
      
      const sliceHeight = Math.min(pageHeightInPixels, canvas.height - currentY)
      
      tempCanvas.width = canvas.width
      tempCanvas.height = sliceHeight
      
      tempCtx.drawImage(
        canvas,
        0, currentY,
        canvas.width, sliceHeight,
        0, 0,
        canvas.width, sliceHeight
      )
      
      const pageImgData = tempCanvas.toDataURL('image/png')
      const pageImgHeight = sliceHeight * scale
      
      pdf.addImage(pageImgData, 'PNG', marginX, 10, imgWidth, pageImgHeight)
      
      currentY += sliceHeight
      pageCount++
    }
    
    // 保存 PDF
    const fileName = `我的工时统计-${filters.dateRange[0]}-${filters.dateRange[1]}.pdf`
    pdf.save(fileName)
    
    ElMessage.success('PDF导出成功！')
  } catch (error) {
    console.error('导出PDF失败:', error)
    ElMessage.error('导出PDF失败，请重试')
  } finally {
    exporting.value = false
  }
}

// 返回
const goBack = () => {
  router.back()
}

// 页面加载时
onMounted(() => {
  // 设置默认日期范围为最近30天
  const end = new Date()
  const start = new Date()
  start.setDate(start.getDate() - 30)
  
  filters.dateRange = [
    start.toISOString().split('T')[0],
    end.toISOString().split('T')[0]
  ]
  
  loadWorkHours()
})
</script>

<style scoped>
.doctor-work-hours {
  min-height: 100vh;
  background: linear-gradient(135deg, #f5f7fa 0%, #e8eef5 100%);
}

.top-navbar {
  background: #fff;
  border-bottom: 1px solid #e4e7ed;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.05);
  position: sticky;
  top: 0;
  z-index: 100;
}

.navbar-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
  height: 64px;
  max-width: 1400px;
  margin: 0 auto;
  padding: 0 32px;
}

.navbar-left {
  display: flex;
  align-items: center;
  gap: 16px;
}

.navbar-left h2 {
  margin: 0;
  font-size: 1.3rem;
  font-weight: 600;
  color: #2c3e50;
}

.main-content {
  max-width: 1400px;
  margin: 0 auto;
  padding: 24px 32px;
}

.stats-row {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
  gap: 20px;
  margin-bottom: 24px;
}

.stat-card {
  background: #fff;
  border-radius: 12px;
  padding: 24px;
  display: flex;
  align-items: center;
  gap: 20px;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.08);
  transition: all 0.3s ease;
}

.stat-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.12);
}

.stat-icon {
  width: 64px;
  height: 64px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.stat-icon.primary {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: #fff;
}

.stat-icon.success {
  background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
  color: #fff;
}

.stat-icon.warning {
  background: linear-gradient(135deg, #ffecd2 0%, #fcb69f 100%);
  color: #fff;
}

.stat-icon.danger {
  background: linear-gradient(135deg, #ff9a9e 0%, #fecfef 100%);
  color: #fff;
}

.stat-info {
  flex: 1;
}

.stat-label {
  margin: 0 0 8px 0;
  font-size: 14px;
  color: #909399;
}

.stat-value {
  margin: 0;
  font-size: 28px;
  font-weight: 700;
  color: #2c3e50;
}

.filter-card,
.table-card {
  margin-bottom: 20px;
}

.el-table {
  font-size: 14px;
}

:deep(.el-table th) {
  background: #f5f7fa;
  color: #606266;
  font-weight: 600;
}
</style>
