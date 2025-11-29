<template>
  <div class="stats-canvas">
    <!-- 顶部导航 -->
    <div class="top-header">
      <div class="header-content">
        <div class="header-left">
          <h2>医院后台管理系统</h2>
        </div>
        <div class="header-right">
          <el-button type="primary" @click="handleExportPDF" size="small" :loading="exporting">
            <el-icon><Download /></el-icon>
            导出报表
          </el-button>
          <el-button type="danger" @click="handleExit" size="small">
            <el-icon><Close /></el-icon>
            退出大屏
          </el-button>
        </div>
      </div>
    </div>

    <!-- 返回按钮 -->
    <div class="back-area">
      <BackButton />
    </div>

    <!-- 顶部欢迎横幅 -->
    <div class="welcome-banner">
      <div class="banner-content">
        <h1>医院运营数据中心</h1>
        <p>实时监控核心运营指标，数据驱动决策</p>
      </div>
      <img :src="doctorImage" alt="医生形象" class="banner-image">
    </div>

    <!-- Tab 切换式内容区 -->
    <div class="content-wrapper">
      <el-tabs v-model="activeTab" type="border-card" class="dashboard-tabs" @tab-change="handleTabChange">
        <!-- Tab 1: 运营总览 -->
        <el-tab-pane label="运营总览" name="overview">
          <div class="tab-content">
            <!-- 核心指标卡片 -->
            <div class="top-cards">
              <div class="stat-card stat-card-green">
                <div class="stat-icon">
                  <el-icon :size="40"><Calendar /></el-icon>
                </div>
                <div class="stat-content">
                  <div class="stat-label">今日挂号量</div>
                  <div class="stat-value">{{ mockData.overview.todayAppointments }}</div>
                </div>
              </div>

              <div class="stat-card stat-card-blue">
                <div class="stat-icon">
                  <el-icon :size="40"><User /></el-icon>
                </div>
                <div class="stat-content">
                  <div class="stat-label">今日出诊医生</div>
                  <div class="stat-value">{{ mockData.overview.activeDoctorsToday }}</div>
                </div>
              </div>

              <div class="stat-card stat-card-red">
                <div class="stat-icon">
                  <el-icon :size="40"><Warning /></el-icon>
                </div>
                <div class="stat-content">
                  <div class="stat-label">当前候诊人数</div>
                  <div class="stat-value">{{ mockData.overview.pendingPatients }}</div>
                </div>
              </div>

              <div class="stat-card stat-card-purple">
                <div class="stat-icon">
                  <el-icon :size="40"><UserFilled /></el-icon>
                </div>
                <div class="stat-content">
                  <div class="stat-label">累计注册用户</div>
                  <div class="stat-value">{{ mockData.overview.totalPatients }}</div>
                </div>
              </div>
            </div>

            <!-- 图表区域 -->
            <div class="charts-grid">
              <el-card class="chart-card">
                <template #header>
                  <div class="card-header">全院挂号趋势</div>
                </template>
                <div id="appointmentTrendChart" class="chart"></div>
              </el-card>

              <el-card class="chart-card">
                <template #header>
                  <div class="card-header">支付状态分布</div>
                </template>
                <div id="paymentStatusChart" class="chart"></div>
              </el-card>
            </div>
          </div>
        </el-tab-pane>

        <!-- Tab 2: 医生资源分析 -->
        <el-tab-pane label="医生资源分析" name="doctors">
          <div class="tab-content">
            <!-- 关键指标卡片 -->
            <div class="top-cards">
              <div class="stat-card stat-card-blue">
                <div class="stat-icon">
                  <el-icon :size="40"><UserFilled /></el-icon>
                </div>
                <div class="stat-content">
                  <div class="stat-label">医生总数</div>
                  <div class="stat-value">{{ mockData.doctors.totalDoctors }}</div>
                </div>
              </div>

              <div class="stat-card stat-card-orange">
                <div class="stat-icon">
                  <el-icon :size="40"><Calendar /></el-icon>
                </div>
                <div class="stat-content">
                  <div class="stat-label">今日请假人数</div>
                  <div class="stat-value">{{ mockData.doctors.todayLeaveCount }}</div>
                </div>
              </div>

              <div class="stat-card stat-card-indigo">
                <div class="stat-icon">
                  <el-icon :size="40"><OfficeBuilding /></el-icon>
                </div>
                <div class="stat-content">
                  <div class="stat-label">科室总数</div>
                  <div class="stat-value">{{ mockData.doctors.totalDepartments }}</div>
                </div>
              </div>
            </div>

            <!-- 图表区域 -->
            <div class="charts-grid">
              <el-card class="chart-card">
                <template #header>
                  <div class="card-header">职称分布</div>
                </template>
                <div id="titleDistributionChart" class="chart"></div>
              </el-card>

              <el-card class="chart-card">
                <template #header>
                  <div class="card-header">科室繁忙度 Top 5</div>
                </template>
                <div id="departmentBusyChart" class="chart"></div>
              </el-card>

              <el-card class="chart-card chart-full-width">
                <template #header>
                  <div class="card-header">医生工作量 Top 5</div>
                </template>
                <div id="doctorWorkloadChart" class="chart"></div>
              </el-card>
            </div>
          </div>
        </el-tab-pane>

        <!-- Tab 3: 患者群体画像 -->
        <el-tab-pane label="患者群体画像" name="patients">
          <div class="tab-content">
            <!-- 关键指标卡片 -->
            <div class="top-cards">
              <div class="stat-card stat-card-green">
                <div class="stat-icon">
                  <el-icon :size="40"><User /></el-icon>
                </div>
                <div class="stat-content">
                  <div class="stat-label">本月新增注册</div>
                  <div class="stat-value">{{ mockData.patients.monthlyNewRegistrations }}</div>
                </div>
              </div>

              <div class="stat-card stat-card-purple">
                <div class="stat-icon">
                  <el-icon :size="40"><DataAnalysis /></el-icon>
                </div>
                <div class="stat-content">
                  <div class="stat-label">师生比例系数</div>
                  <div class="stat-value">{{ mockData.patients.studentTeacherRatio }}</div>
                </div>
              </div>

              <div class="stat-card stat-card-red">
                <div class="stat-icon">
                  <el-icon :size="40"><Warning /></el-icon>
                </div>
                <div class="stat-content">
                  <div class="stat-label">累计爽约次数</div>
                  <div class="stat-value">{{ mockData.patients.totalNoShows }}</div>
                </div>
              </div>
            </div>

            <!-- 图表区域 -->
            <div class="charts-grid">
              <el-card class="chart-card chart-full-width">
                <template #header>
                  <div class="card-header">用户增长趋势（近30天）</div>
                </template>
                <div id="userGrowthChart" class="chart"></div>
              </el-card>

              <el-card class="chart-card">
                <template #header>
                  <div class="card-header">患者类型构成</div>
                </template>
                <div id="patientTypeChart" class="chart"></div>
              </el-card>

              <el-card class="chart-card">
                <template #header>
                  <div class="card-header" style="display: flex; justify-content: space-between; align-items: center;">
                    <span>就诊时段热力图</span>
                    <div style="display: flex; gap: 10px; align-items: center;">
                      <el-date-picker
                        v-model="timeSlotDateRange"
                        type="daterange"
                        range-separator="至"
                        start-placeholder="起始日期"
                        end-placeholder="结束日期"
                        format="YYYY-MM-DD"
                        value-format="YYYY-MM-DD"
                        size="small"
                        style="width: 280px;"
                        @change="handleTimeSlotDateChange"
                      />
                      <el-button type="primary" size="small" @click="refreshTimeSlotChart">
                        <el-icon><Refresh /></el-icon>
                        刷新
                      </el-button>
                    </div>
                  </div>
                </template>
                <div id="timeSlotChart" class="chart"></div>
              </el-card>
            </div>
          </div>
        </el-tab-pane>
      </el-tabs>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted, onUnmounted, nextTick, watch } from 'vue'
import { useRouter } from 'vue-router'
import {
  Calendar,
  User,
  Warning,
  UserFilled,
  Close,
  OfficeBuilding,
  DataAnalysis,
  Download,
  Refresh
} from '@element-plus/icons-vue'
import * as echarts from 'echarts'
import doctorImage from '@/assets/doctor.jpg'
import BackButton from '@/components/BackButton.vue'
import html2canvas from 'html2canvas'
import jsPDF from 'jspdf'
import { ElMessage } from 'element-plus'
import { getOverviewStats, getDoctorsStats, getPatientsStats } from '@/api/dashboard'

const router = useRouter()
const activeTab = ref('overview')
const exporting = ref(false)
const loading = ref(false)
// 就诊时段热力图日期范围
const timeSlotDateRange = ref(null)

// 数据
const mockData = reactive({
  overview: {
    todayAppointments: 0,
    activeDoctorsToday: 0,
    pendingPatients: 0,
    totalPatients: 0,
    last7DaysDates: [],
    last7DaysCounts: [],
    paymentStatus: []
  },
  doctors: {
    totalDoctors: 0,
    todayLeaveCount: 0,
    totalDepartments: 0,
    titleDistribution: [],
    departmentBusy: [],
    doctorWorkload: []
  },
  patients: {
    monthlyNewRegistrations: 0,
    studentTeacherRatio: '0:0',
    totalNoShows: 0,
    last30DaysDates: [],
    last30DaysCounts: [],
    patientType: [],
    timeSlotData: []
  }
})

// ECharts 实例存储
const chartInstances = new Map()

// 初始化图表函数
const initChart = (id, option) => {
  const chartDom = document.getElementById(id)
  if (!chartDom) return null

  // 如果已存在实例，先销毁
  if (chartInstances.has(id)) {
    chartInstances.get(id).dispose()
  }

  const chart = echarts.init(chartDom)
  chart.setOption(option)
  chartInstances.set(id, chart)
  return chart
}

// Tab 1: 运营总览图表
const initOverviewCharts = () => {
  // 全院挂号趋势图
  initChart('appointmentTrendChart', {
    backgroundColor: 'transparent',
    tooltip: {
      trigger: 'axis',
      axisPointer: { type: 'cross' }
    },
    grid: {
      left: '3%',
      right: '4%',
      bottom: '3%',
      top: '10%',
      containLabel: true
    },
    xAxis: {
      type: 'category',
      boundaryGap: false,
      data: mockData.overview.last7DaysDates,
      axisLine: { lineStyle: { color: '#4a5568' } },
      axisLabel: { color: '#718096' }
    },
    yAxis: {
      type: 'value',
      axisLine: { lineStyle: { color: '#4a5568' } },
      axisLabel: { color: '#718096' },
      splitLine: { lineStyle: { color: '#e2e8f0', type: 'dashed' } }
    },
    series: [
      {
        name: '挂号量',
        type: 'line',
        smooth: true,
        data: mockData.overview.last7DaysCounts,
        areaStyle: {
          color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
            { offset: 0, color: 'rgba(79, 209, 197, 0.3)' },
            { offset: 1, color: 'rgba(79, 209, 197, 0.1)' }
          ])
        },
        lineStyle: { color: '#4FD1C5', width: 3 },
        itemStyle: { color: '#4FD1C5', borderWidth: 2, borderColor: '#fff' }
      }
    ]
  })

  // 支付状态分布图
  initChart('paymentStatusChart', {
    backgroundColor: 'transparent',
    tooltip: {
      trigger: 'item',
      formatter: '{a} <br/>{b}: {c} ({d}%)'
    },
    legend: {
      orient: 'vertical',
      left: 'left',
      top: 'middle',
      textStyle: { color: '#4a5568', fontSize: 14 }
    },
    series: [
      {
        name: '支付状态',
        type: 'pie',
        radius: ['40%', '70%'],
        center: ['60%', '50%'],
        avoidLabelOverlap: false,
        itemStyle: {
          borderRadius: 10,
          borderColor: '#fff',
          borderWidth: 2
        },
        label: {
          show: true,
          formatter: '{b}\n{d}%',
          color: '#2d3748',
          fontSize: 14,
          fontWeight: 'bold'
        },
        data: mockData.overview.paymentStatus.map((item, index) => ({
          ...item,
          itemStyle: {
            color: [
              new echarts.graphic.LinearGradient(0, 0, 0, 1, [
                { offset: 0, color: '#48bb78' },
                { offset: 1, color: '#38a169' }
              ]),
              new echarts.graphic.LinearGradient(0, 0, 0, 1, [
                { offset: 0, color: '#f59e0b' },
                { offset: 1, color: '#d97706' }
              ]),
              new echarts.graphic.LinearGradient(0, 0, 0, 1, [
                { offset: 0, color: '#f56565' },
                { offset: 1, color: '#e53e3e' }
              ])
            ][index]
          }
        }))
      }
    ]
  })
}

// Tab 2: 医生资源分析图表
const initDoctorsCharts = () => {
  // 职称分布图（环形图）
  initChart('titleDistributionChart', {
    backgroundColor: 'transparent',
    tooltip: {
      trigger: 'item',
      formatter: '{a} <br/>{b}: {c} ({d}%)'
    },
    legend: {
      orient: 'vertical',
      left: 'left',
      top: 'middle',
      textStyle: { color: '#4a5568', fontSize: 12 }
    },
    series: [
      {
        name: '职称分布',
        type: 'pie',
        radius: ['50%', '70%'],
        center: ['60%', '50%'],
        avoidLabelOverlap: false,
        itemStyle: {
          borderRadius: 8,
          borderColor: '#fff',
          borderWidth: 2
        },
        label: {
          show: true,
          formatter: '{b}\n{d}%',
          fontSize: 12
        },
        data: mockData.doctors.titleDistribution.map((item, index) => ({
          ...item,
          itemStyle: {
            color: [
              '#667eea',
              '#764ba2',
              '#f093fb',
              '#f5576c'
            ][index]
          }
        }))
      }
    ]
  })

  // 科室繁忙度 Top 5
  initChart('departmentBusyChart', {
    backgroundColor: 'transparent',
    tooltip: {
      trigger: 'axis',
      axisPointer: { type: 'shadow' }
    },
    grid: {
      left: '3%',
      right: '4%',
      bottom: '3%',
      top: '10%',
      containLabel: true
    },
    xAxis: {
      type: 'value',
      axisLine: { lineStyle: { color: '#4a5568' } },
      axisLabel: { color: '#718096' }
    },
    yAxis: {
      type: 'category',
      data: mockData.doctors.departmentBusy.map(d => d.name),
      axisLine: { lineStyle: { color: '#4a5568' } },
      axisLabel: { color: '#718096' }
    },
    series: [
      {
        name: '已预约数',
        type: 'bar',
        data: mockData.doctors.departmentBusy.map(d => d.value),
        itemStyle: {
          color: new echarts.graphic.LinearGradient(0, 0, 1, 0, [
            { offset: 0, color: '#4299e1' },
            { offset: 1, color: '#3182ce' }
          ])
        },
        label: {
          show: true,
          position: 'right',
          color: '#2d3748'
        }
      }
    ]
  })

  // 医生工作量 Top 5（横向柱状图）
  initChart('doctorWorkloadChart', {
    backgroundColor: 'transparent',
    tooltip: {
      trigger: 'axis',
      axisPointer: { type: 'shadow' },
      formatter: function (params) {
        const param = params[0]
        return `${param.name}<br/>${param.seriesName}: ${param.value}人<br/>科室: ${param.data.department}`
      }
    },
    grid: {
      left: '3%',
      right: '4%',
      bottom: '3%',
      top: '10%',
      containLabel: true
    },
    xAxis: {
      type: 'value',
      axisLine: { lineStyle: { color: '#4a5568' } },
      axisLabel: { color: '#718096' }
    },
    yAxis: {
      type: 'category',
      data: mockData.doctors.doctorWorkload.map(d => d.name),
      axisLine: { lineStyle: { color: '#4a5568' } },
      axisLabel: { color: '#718096' }
    },
    series: [
      {
        name: '接诊人数',
        type: 'bar',
        data: mockData.doctors.doctorWorkload.map(d => ({
          value: d.value,
          department: d.department
        })),
        itemStyle: {
          color: new echarts.graphic.LinearGradient(0, 0, 1, 0, [
            { offset: 0, color: '#9f7aea' },
            { offset: 1, color: '#805ad5' }
          ])
        },
        label: {
          show: true,
          position: 'right',
          color: '#2d3748'
        }
      }
    ]
  })
}

// Tab 3: 患者群体画像图表
const initPatientsCharts = () => {
  // 用户增长趋势图
  initChart('userGrowthChart', {
    backgroundColor: 'transparent',
    tooltip: {
      trigger: 'axis',
      axisPointer: { type: 'cross' }
    },
    grid: {
      left: '3%',
      right: '4%',
      bottom: '3%',
      top: '10%',
      containLabel: true
    },
    xAxis: {
      type: 'category',
      boundaryGap: false,
      data: mockData.patients.last30DaysDates,
      axisLine: { lineStyle: { color: '#4a5568' } },
      axisLabel: { color: '#718096', rotate: 45 }
    },
    yAxis: {
      type: 'value',
      axisLine: { lineStyle: { color: '#4a5568' } },
      axisLabel: { color: '#718096' },
      splitLine: { lineStyle: { color: '#e2e8f0', type: 'dashed' } }
    },
    series: [
      {
        name: '新增用户',
        type: 'line',
        smooth: true,
        data: mockData.patients.last30DaysCounts,
        areaStyle: {
          color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
            { offset: 0, color: 'rgba(102, 126, 234, 0.3)' },
            { offset: 1, color: 'rgba(102, 126, 234, 0.1)' }
          ])
        },
        lineStyle: { color: '#667eea', width: 3 },
        itemStyle: { color: '#667eea', borderWidth: 2, borderColor: '#fff' }
      }
    ]
  })

  // 患者类型构成图
  initChart('patientTypeChart', {
    backgroundColor: 'transparent',
    tooltip: {
      trigger: 'item',
      formatter: '{a} <br/>{b}: {c} ({d}%)'
    },
    legend: {
      orient: 'vertical',
      left: 'left',
      top: 'middle',
      textStyle: { color: '#4a5568', fontSize: 14 }
    },
    series: [
      {
        name: '患者类型',
        type: 'pie',
        radius: ['40%', '70%'],
        center: ['60%', '50%'],
        avoidLabelOverlap: false,
        itemStyle: {
          borderRadius: 10,
          borderColor: '#fff',
          borderWidth: 2
        },
        label: {
          show: true,
          formatter: '{b}\n{d}%',
          color: '#2d3748',
          fontSize: 14,
          fontWeight: 'bold'
        },
        data: [
          {
            value: mockData.patients.patientType[0].value,
            name: '学生',
            itemStyle: {
              color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
                { offset: 0, color: '#667eea' },
                { offset: 1, color: '#764ba2' }
              ])
            }
          },
          {
            value: mockData.patients.patientType[1].value,
            name: '教职工',
            itemStyle: {
              color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
                { offset: 0, color: '#f093fb' },
                { offset: 1, color: '#f5576c' }
              ])
            }
          }
        ]
      }
    ]
  })

  // 就诊时段热力图（柱状图）
  initChart('timeSlotChart', {
    backgroundColor: 'transparent',
    tooltip: {
      trigger: 'axis',
      axisPointer: { type: 'shadow' }
    },
    grid: {
      left: '3%',
      right: '4%',
      bottom: '3%',
      top: '10%',
      containLabel: true
    },
    xAxis: {
      type: 'category',
      data: mockData.patients.timeSlotData.map(d => d.time),
      axisLine: { lineStyle: { color: '#4a5568' } },
      axisLabel: { color: '#718096', rotate: 45 }
    },
    yAxis: {
      type: 'value',
      axisLine: { lineStyle: { color: '#4a5568' } },
      axisLabel: { color: '#718096' },
      splitLine: { lineStyle: { color: '#e2e8f0', type: 'dashed' } }
    },
    series: [
      {
        name: '挂号量',
        type: 'bar',
        data: mockData.patients.timeSlotData.map(d => d.count),
        itemStyle: {
          color: function (params) {
            const colors = [
              ['#4299e1', '#3182ce'],
              ['#48bb78', '#38a169'],
              ['#f59e0b', '#d97706'],
              ['#f56565', '#e53e3e']
            ]
            const colorIndex = Math.floor(params.dataIndex / 3) % colors.length
            return new echarts.graphic.LinearGradient(0, 0, 0, 1, [
              { offset: 0, color: colors[colorIndex][0] },
              { offset: 1, color: colors[colorIndex][1] }
            ])
          }
        },
        label: {
          show: true,
          position: 'top',
          color: '#2d3748'
        }
      }
    ]
  })
}


// 处理窗口大小变化
const handleResize = () => {
  resizeAllCharts()
}

// 调整所有图表大小
const resizeAllCharts = () => {
  chartInstances.forEach((chart) => {
    if (chart && !chart.isDisposed()) {
      chart.resize()
    }
  })
}

// 退出大屏
const handleExit = () => {
  router.push('/')
}

// 导出PDF
const handleExportPDF = async () => {
  exporting.value = true
  try {
    ElMessage.info('正在生成报表，请稍候...')
    
    // 等待所有图表渲染完成
    await nextTick()
    await new Promise(resolve => setTimeout(resolve, 1000))

    // 获取要导出的内容区域（不包括顶部导航和返回按钮）
    const contentWrapper = document.querySelector('.content-wrapper')
    const welcomeBanner = document.querySelector('.welcome-banner')
    
    if (!contentWrapper) {
      ElMessage.error('未找到要导出的内容')
      return
    }

    // 使用html2canvas分别捕获横幅和内容区域
    let bannerCanvas = null
    if (welcomeBanner) {
      bannerCanvas = await html2canvas(welcomeBanner, {
        backgroundColor: null,
        scale: 2,
        useCORS: true,
        logging: false
      })
    }

    const contentCanvas = await html2canvas(contentWrapper, {
      backgroundColor: '#f7fafc',
      scale: 2, // 提高清晰度
      useCORS: true,
      logging: false
    })

    // 使用A3横向页面，更大尺寸
    const pdf = new jsPDF('l', 'mm', 'a3') // A3横向: 420mm x 297mm
    const pdfWidth = pdf.internal.pageSize.getWidth() // 420mm
    const pdfHeight = pdf.internal.pageSize.getHeight() // 297mm
    
    const margin = 15 // 边距
    const availableWidth = pdfWidth - margin * 2 // 390mm
    const now = new Date()
    const dateStr = now.toLocaleString('zh-CN', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit'
    })

    // 创建标题和时间的canvas（避免中文乱码）
    const titleCanvas = document.createElement('canvas')
    titleCanvas.width = availableWidth * 2 // 提高清晰度
    titleCanvas.height = 80 // 增加高度，确保标题和时间不重叠
    const titleCtx = titleCanvas.getContext('2d')
    
    // 设置背景
    titleCtx.fillStyle = '#ffffff'
    titleCtx.fillRect(0, 0, titleCanvas.width, titleCanvas.height)
    
    // 绘制标题
    titleCtx.fillStyle = '#303133'
    titleCtx.font = 'bold 36px Arial, "Microsoft YaHei", "SimHei", sans-serif'
    titleCtx.textAlign = 'center'
    titleCtx.textBaseline = 'top'
    const titleY = 10 // 标题Y位置
    titleCtx.fillText('医院运营数据中心报表', titleCanvas.width / 2, titleY)
    
    // 绘制生成时间（在标题下方，留出足够间距）
    titleCtx.fillStyle = '#606266'
    titleCtx.font = '20px Arial, "Microsoft YaHei", "SimHei", sans-serif'
    titleCtx.textBaseline = 'top'
    const timeY = titleY + 50 // 时间Y位置，确保在标题下方有足够间距
    titleCtx.fillText(`生成时间: ${dateStr}`, titleCanvas.width / 2, timeY)
    
    // 将标题canvas转换为图片并添加到PDF
    const titleImgData = titleCanvas.toDataURL('image/png', 1.0)
    const titleImgHeight = 25 // PDF中的高度（mm），增加高度以容纳两行文字
    pdf.addImage(
      titleImgData,
      'PNG',
      margin,
      margin,
      availableWidth,
      titleImgHeight,
      undefined,
      'FAST'
    )

    let currentY = margin + titleImgHeight + 10 // 起始Y位置

    // 添加横幅（如果有）
    if (bannerCanvas) {
      // 计算横幅的缩放比例，保持宽高比
      const bannerScale = availableWidth / bannerCanvas.width
      const bannerImgWidth = availableWidth
      const bannerImgHeight = bannerCanvas.height * bannerScale
      
      const bannerImgData = bannerCanvas.toDataURL('image/png', 1.0)
      pdf.addImage(
        bannerImgData,
        'PNG',
        margin,
        currentY,
        bannerImgWidth,
        bannerImgHeight,
        undefined,
        'FAST'
      )
      currentY += bannerImgHeight + 10
    }

    // 计算内容区域的缩放比例，保持宽高比
    const contentScale = availableWidth / contentCanvas.width
    const contentImgWidth = availableWidth
    const contentImgHeight = contentCanvas.height * contentScale

    // 如果内容高度超过一页，需要分页
    const maxPageHeight = pdfHeight - currentY - margin
    const contentImgData = contentCanvas.toDataURL('image/png', 1.0)
    
    let heightLeft = contentImgHeight
    let position = 0

    while (heightLeft > 0) {
      if (position > 0) {
        pdf.addPage()
        currentY = margin
      }

      const pageHeight = Math.min(heightLeft, maxPageHeight)
      
      // 计算源图片的裁剪位置和高度
      const sourceY = (position / contentImgHeight) * contentCanvas.height
      const sourceHeight = (pageHeight / contentImgHeight) * contentCanvas.height
      
      // 创建临时canvas来裁剪当前页的内容
      const tempCanvas = document.createElement('canvas')
      tempCanvas.width = contentCanvas.width
      tempCanvas.height = Math.ceil(sourceHeight)
      const tempCtx = tempCanvas.getContext('2d')
      
      // 绘制裁剪后的内容
      tempCtx.drawImage(
        contentCanvas,
        0, Math.floor(sourceY), contentCanvas.width, Math.ceil(sourceHeight),
        0, 0, contentCanvas.width, Math.ceil(sourceHeight)
      )
      
      const pageImgData = tempCanvas.toDataURL('image/png', 1.0)
      const pageImgHeight = (tempCanvas.height * contentScale)
      
      pdf.addImage(
        pageImgData,
        'PNG',
        margin,
        currentY,
        contentImgWidth,
        pageImgHeight,
        undefined,
        'FAST'
      )

      heightLeft -= maxPageHeight
      position += maxPageHeight
    }

    // 生成文件名（使用英文避免编码问题，但可以在下载时显示中文）
    const tabNames = {
      overview: '运营总览',
      doctors: '医生资源分析',
      patients: '患者群体画像'
    }
    const tabNameEn = {
      overview: 'OperationsOverview',
      doctors: 'DoctorResources',
      patients: 'PatientProfile'
    }
    const tabName = tabNames[activeTab.value] || '报表'
    const tabNameEnValue = tabNameEn[activeTab.value] || 'Report'
    
    // 生成文件名（使用英文避免编码问题）
    const fileName = `HospitalDataReport_${tabNameEnValue}_${now.getFullYear()}${String(now.getMonth() + 1).padStart(2, '0')}${String(now.getDate()).padStart(2, '0')}_${String(now.getHours()).padStart(2, '0')}${String(now.getMinutes()).padStart(2, '0')}.pdf`
    
    // 使用 Blob 和 URL 来支持中文文件名
    const pdfBlob = pdf.output('blob')
    const url = URL.createObjectURL(pdfBlob)
    const link = document.createElement('a')
    link.href = url
    
    // 尝试使用中文文件名，如果浏览器不支持会自动回退
    try {
      // 使用 decodeURIComponent 和 encodeURIComponent 来处理中文
      link.download = `医院运营数据报表_${tabName}_${now.getFullYear()}${String(now.getMonth() + 1).padStart(2, '0')}${String(now.getDate()).padStart(2, '0')}_${String(now.getHours()).padStart(2, '0')}${String(now.getMinutes()).padStart(2, '0')}.pdf`
    } catch (e) {
      // 如果中文文件名失败，使用英文文件名
      link.download = fileName
    }
    
    // 触发下载
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
    
    // 清理 URL 对象
    setTimeout(() => {
      URL.revokeObjectURL(url)
    }, 100)
    
    ElMessage.success('报表导出成功')
  } catch (error) {
    console.error('导出PDF失败:', error)
    ElMessage.error('导出失败: ' + (error.message || '请重试'))
  } finally {
    exporting.value = false
  }
}

// 使用 ResizeObserver 监听图表容器大小变化
const setupResizeObserver = () => {
  const observer = new ResizeObserver(() => {
    resizeAllCharts()
  })

  // 监听所有图表容器
  const chartIds = [
    'appointmentTrendChart',
    'paymentStatusChart',
    'titleDistributionChart',
    'departmentBusyChart',
    'doctorWorkloadChart',
    'userGrowthChart',
    'patientTypeChart',
    'timeSlotChart'
  ]

  chartIds.forEach((id) => {
    const element = document.getElementById(id)
    if (element) {
      observer.observe(element)
    }
  })

  return observer
}

let resizeObserver = null

// 加载数据
const loadOverviewData = async () => {
  try {
    loading.value = true
    console.log('开始加载运营总览数据...')
    const response = await getOverviewStats()
    console.log('运营总览API响应:', response)
    console.log('响应类型:', typeof response)
    console.log('响应是否为对象:', response && typeof response === 'object')
    
    // Spring Boot 直接返回数据，不是包装在 data 中
    const data = response || {}
    console.log('解析后的数据:', data)
    
    mockData.overview.todayAppointments = data.todayAppointments ?? 0
    mockData.overview.activeDoctorsToday = data.activeDoctorsToday ?? 0
    mockData.overview.pendingPatients = data.pendingPatients ?? 0
    mockData.overview.totalPatients = data.totalPatients ?? 0
    mockData.overview.last7DaysDates = data.last7DaysDates || []
    mockData.overview.last7DaysCounts = data.last7DaysCounts || []
    mockData.overview.paymentStatus = data.paymentStatus || []
    
    console.log('更新后的运营总览数据:', mockData.overview)
    console.log('今日挂号量:', mockData.overview.todayAppointments)
    console.log('今日出诊医生:', mockData.overview.activeDoctorsToday)
    console.log('当前候诊人数:', mockData.overview.pendingPatients)
    console.log('累计注册用户:', mockData.overview.totalPatients)
  } catch (error) {
    console.error('加载运营总览数据失败:', error)
    console.error('错误详情:', {
      message: error.message,
      response: error.response,
      request: error.request,
      config: error.config
    })
    
    let errorMsg = '加载数据失败'
    if (error.response) {
      errorMsg = `后端错误 (${error.response.status}): ${error.response.data?.message || error.response.statusText}`
    } else if (error.request) {
      errorMsg = '无法连接到后端服务，请检查：1. 后端服务是否启动 2. 后端地址是否为 http://localhost:8080'
    } else {
      errorMsg = error.message || '未知错误'
    }
    
    ElMessage.error(errorMsg)
  } finally {
    loading.value = false
  }
}

const loadDoctorsData = async () => {
  try {
    loading.value = true
    const response = await getDoctorsStats()
    console.log('医生资源分析API响应:', response)
    // Spring Boot 直接返回数据，不是包装在 data 中
    const data = response || {}
    mockData.doctors.totalDoctors = data.totalDoctors || 0
    mockData.doctors.todayLeaveCount = data.todayLeaveCount || 0
    mockData.doctors.totalDepartments = data.totalDepartments || 0
    mockData.doctors.titleDistribution = data.titleDistribution || []
    mockData.doctors.departmentBusy = data.departmentBusy || []
    mockData.doctors.doctorWorkload = (data.doctorWorkload || []).map(item => ({
      name: item.name,
      department: item.department,
      value: item.value
    }))
    console.log('更新后的医生资源分析数据:', mockData.doctors)
  } catch (error) {
    console.error('加载医生资源分析数据失败:', error)
    ElMessage.error('加载数据失败: ' + (error.message || '请检查后端服务'))
  } finally {
    loading.value = false
  }
}

const loadPatientsData = async () => {
  try {
    loading.value = true
    // 获取日期范围参数
    const startDate = timeSlotDateRange.value && timeSlotDateRange.value.length > 0 ? timeSlotDateRange.value[0] : null
    const endDate = timeSlotDateRange.value && timeSlotDateRange.value.length > 1 ? timeSlotDateRange.value[1] : null
    const response = await getPatientsStats(startDate, endDate)
    console.log('患者群体画像API响应:', response)
    // Spring Boot 直接返回数据，不是包装在 data 中
    const data = response || {}
    mockData.patients.monthlyNewRegistrations = data.monthlyNewRegistrations || 0
    mockData.patients.studentTeacherRatio = data.studentTeacherRatio || '0:0'
    mockData.patients.totalNoShows = data.totalNoShows || 0
    mockData.patients.last30DaysDates = data.last30DaysDates || []
    mockData.patients.last30DaysCounts = (data.last30DaysCounts || []).map(count => Number(count))
    mockData.patients.patientType = data.patientType || []
    mockData.patients.timeSlotData = (data.timeSlotData || []).map(item => ({
      time: item.time,
      count: item.count
    }))
    console.log('更新后的患者群体画像数据:', mockData.patients)
  } catch (error) {
    console.error('加载患者群体画像数据失败:', error)
    ElMessage.error('加载数据失败: ' + (error.message || '请检查后端服务'))
  } finally {
    loading.value = false
  }
}

// 处理就诊时段日期范围变化
const handleTimeSlotDateChange = () => {
  // 日期变化时自动刷新图表
  refreshTimeSlotChart()
}

// 刷新就诊时段热力图
const refreshTimeSlotChart = async () => {
  try {
    loading.value = true
    // 只刷新就诊时段数据
    const startDate = timeSlotDateRange.value && timeSlotDateRange.value.length > 0 ? timeSlotDateRange.value[0] : null
    const endDate = timeSlotDateRange.value && timeSlotDateRange.value.length > 1 ? timeSlotDateRange.value[1] : null
    const response = await getPatientsStats(startDate, endDate)
    const data = response || {}
    mockData.patients.timeSlotData = (data.timeSlotData || []).map(item => ({
      time: item.time,
      count: item.count
    }))
    // 只更新就诊时段图表
    nextTick(() => {
      setTimeout(() => {
        initChart('timeSlotChart', {
          backgroundColor: 'transparent',
          tooltip: {
            trigger: 'axis',
            axisPointer: { type: 'shadow' }
          },
          grid: {
            left: '3%',
            right: '4%',
            bottom: '3%',
            top: '10%',
            containLabel: true
          },
          xAxis: {
            type: 'category',
            data: mockData.patients.timeSlotData.map(d => d.time),
            axisLine: { lineStyle: { color: '#4a5568' } },
            axisLabel: { color: '#718096', rotate: 45 }
          },
          yAxis: {
            type: 'value',
            axisLine: { lineStyle: { color: '#4a5568' } },
            axisLabel: { color: '#718096' },
            splitLine: { lineStyle: { color: '#e2e8f0', type: 'dashed' } }
          },
          series: [
            {
              name: '挂号量',
              type: 'bar',
              data: mockData.patients.timeSlotData.map(d => d.count),
              itemStyle: {
                color: function (params) {
                  const colors = [
                    ['#4299e1', '#3182ce'],
                    ['#48bb78', '#38a169'],
                    ['#f59e0b', '#d97706'],
                    ['#f56565', '#e53e3e']
                  ]
                  const colorIndex = Math.floor(params.dataIndex / 3) % colors.length
                  return new echarts.graphic.LinearGradient(0, 0, 0, 1, [
                    { offset: 0, color: colors[colorIndex][0] },
                    { offset: 1, color: colors[colorIndex][1] }
                  ])
                }
              },
              label: {
                show: true,
                position: 'top',
                color: '#2d3748'
              }
            }
          ]
        })
      }, 100)
    })
    ElMessage.success('数据已刷新')
  } catch (error) {
    console.error('刷新就诊时段数据失败:', error)
    ElMessage.error('刷新失败: ' + (error.message || '请检查后端服务'))
  } finally {
    loading.value = false
  }
}

// 处理 Tab 切换
const handleTabChange = (tabName) => {
  nextTick(() => {
    // 延迟初始化图表，确保 DOM 已渲染
    setTimeout(() => {
      switch (tabName) {
        case 'overview':
          loadOverviewData().then(() => {
            initOverviewCharts()
          })
          break
        case 'doctors':
          loadDoctorsData().then(() => {
            initDoctorsCharts()
          })
          break
        case 'patients':
          loadPatientsData().then(() => {
            initPatientsCharts()
          })
          break
      }
      // 触发所有图表 resize
      resizeAllCharts()
    }, 100)
  })
}

onMounted(() => {
  // 初始化第一个 Tab 的数据和图表
  loadOverviewData().then(() => {
    nextTick(() => {
      setTimeout(() => {
        initOverviewCharts()
        resizeObserver = setupResizeObserver()
      }, 300)
    })
  })

  window.addEventListener('resize', handleResize)
})

onUnmounted(() => {
  window.removeEventListener('resize', handleResize)
  if (resizeObserver) {
    resizeObserver.disconnect()
  }
  // 销毁所有图表实例
  chartInstances.forEach((chart) => {
    if (chart && !chart.isDisposed()) {
      chart.dispose()
    }
  })
  chartInstances.clear()
})
</script>

<style scoped>
.stats-canvas {
  min-height: 100vh;
  background-color: #f7fafc;
  padding: 0;
}

/* 顶部导航 */
.top-header {
  background-color: #fff;
  padding: 0 24px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  margin-bottom: 24px;
}

/* 返回按钮区域 */
.back-area {
  margin: 0 24px 12px 24px;
}

.header-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
  height: 60px;
}

.header-left h2 {
  margin: 0;
  font-size: 20px;
  color: #303133;
}

.header-right {
  display: flex;
  align-items: center;
}

/* 顶部欢迎横幅 */
.welcome-banner {
  background: linear-gradient(135deg, #9f7aea 0%, #667eea 100%);
  border-radius: 12px;
  padding: 30px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  color: white;
  margin: 0 24px 24px 24px;
}

.banner-content h1 {
  font-size: 24px;
  margin: 0 0 8px 0;
  font-weight: bold;
}

.banner-content p {
  font-size: 16px;
  margin: 0;
  opacity: 0.9;
}

.banner-image {
  border-radius: 50%;
  object-fit: cover;
  width: 120px;
  height: 120px;
  border: 4px solid white;
}

/* 内容包装器 */
.content-wrapper {
  padding: 0 24px 24px 24px;
}

.dashboard-tabs {
  background: transparent;
}

.dashboard-tabs :deep(.el-tabs__header) {
  margin-bottom: 20px;
}

.dashboard-tabs :deep(.el-tabs__item) {
  font-size: 14px;
  padding: 0 20px;
}

.tab-content {
  padding: 0;
}

/* 核心指标卡片 */
.top-cards {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
  gap: 20px;
  margin-bottom: 20px;
}

.stat-card {
  background: white;
  border-radius: 12px;
  padding: 24px;
  display: flex;
  align-items: center;
  border: 1px solid #e2e8f0;
  transition: all 0.3s ease;
  border-left: 4px solid;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
}

.stat-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
}

.stat-card-green {
  border-left-color: #48bb78;
}

.stat-card-blue {
  border-left-color: #4299e1;
}

.stat-card-red {
  border-left-color: #f56565;
}

.stat-card-purple {
  border-left-color: #9f7aea;
}

.stat-card-orange {
  border-left-color: #f59e0b;
}

.stat-card-indigo {
  border-left-color: #667eea;
}

.stat-icon {
  width: 64px;
  height: 64px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-right: 16px;
}

.stat-card-green .stat-icon {
  background: linear-gradient(135deg, #48bb78 0%, #38a169 100%);
  color: white;
}

.stat-card-blue .stat-icon {
  background: linear-gradient(135deg, #4299e1 0%, #3182ce 100%);
  color: white;
}

.stat-card-red .stat-icon {
  background: linear-gradient(135deg, #f56565 0%, #e53e3e 100%);
  color: white;
}

.stat-card-purple .stat-icon {
  background: linear-gradient(135deg, #9f7aea 0%, #805ad5 100%);
  color: white;
}

.stat-card-orange .stat-icon {
  background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);
  color: white;
}

.stat-card-indigo .stat-icon {
  background: linear-gradient(135deg, #667eea 0%, #5a67d8 100%);
  color: white;
}

.stat-content {
  flex: 1;
}

.stat-label {
  font-size: 14px;
  color: #606266;
  margin-bottom: 8px;
  font-weight: normal;
}

.stat-value {
  font-size: 32px;
  font-weight: bold;
  color: #303133;
  line-height: 1;
}

/* 图表区域 */
.charts-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 20px;
}

.chart-card {
  border-radius: 8px;
}

.chart-card :deep(.el-card__body) {
  padding: 20px;
}

.chart-card.chart-full-width {
  grid-column: 1 / -1;
}

.card-header {
  font-size: 16px;
  font-weight: 500;
  color: #303133;
}

.chart {
  width: 100%;
  height: 350px;
}

/* 响应式设计 */
@media (max-width: 1400px) {
  .charts-grid {
    grid-template-columns: 1fr;
  }

  .chart-card.chart-full-width {
    grid-column: 1;
  }
}

@media (max-width: 768px) {
  .welcome-banner {
    margin: 0 20px 20px 20px;
    padding: 20px;
    flex-direction: column;
    text-align: center;
  }

  .banner-content h1 {
    font-size: 20px;
  }

  .banner-content p {
    font-size: 14px;
  }

  .banner-image {
    width: 100px;
    height: 100px;
    margin-top: 15px;
  }

  .content-wrapper {
    padding: 0 20px 20px 20px;
  }

  .top-cards {
    grid-template-columns: 1fr;
  }

  .header-left h2 {
    font-size: 18px;
  }

  .stat-value {
    font-size: 28px;
  }
}
</style>
