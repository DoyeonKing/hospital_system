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
                  <el-icon :size="30"><Calendar /></el-icon>
                </div>
                <div class="stat-content">
                  <div class="stat-label">今日挂号量</div>
                  <div class="stat-value">{{ mockData.overview.todayAppointments }}</div>
                </div>
              </div>

              <div class="stat-card stat-card-blue">
                <div class="stat-icon">
                  <el-icon :size="30"><User /></el-icon>
                </div>
                <div class="stat-content">
                  <div class="stat-label">今日出诊医生</div>
                  <div class="stat-value">{{ mockData.overview.activeDoctorsToday }}</div>
                </div>
              </div>

              <div class="stat-card stat-card-red">
                <div class="stat-icon">
                  <el-icon :size="30"><Warning /></el-icon>
                </div>
                <div class="stat-content">
                  <div class="stat-label">当前候诊人数</div>
                  <div class="stat-value">{{ mockData.overview.pendingPatients }}</div>
                </div>
              </div>

              <div class="stat-card stat-card-purple">
                <div class="stat-icon">
                  <el-icon :size="30"><UserFilled /></el-icon>
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
                  <el-icon :size="30"><UserFilled /></el-icon>
                </div>
                <div class="stat-content">
                  <div class="stat-label">医生总数</div>
                  <div class="stat-value">{{ mockData.doctors.totalDoctors }}</div>
                </div>
              </div>

              <div class="stat-card stat-card-orange">
                <div class="stat-icon">
                  <el-icon :size="30"><Calendar /></el-icon>
                </div>
                <div class="stat-content">
                  <div class="stat-label">今日请假人数</div>
                  <div class="stat-value">{{ mockData.doctors.todayLeaveCount }}</div>
                </div>
              </div>

              <div class="stat-card stat-card-indigo">
                <div class="stat-icon">
                  <el-icon :size="30"><OfficeBuilding /></el-icon>
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
                  <el-icon :size="30"><User /></el-icon>
                </div>
                <div class="stat-content">
                  <div class="stat-label">本月新增注册</div>
                  <div class="stat-value">{{ mockData.patients.monthlyNewRegistrations }}</div>
                </div>
              </div>

              <div class="stat-card stat-card-purple">
                <div class="stat-icon">
                  <el-icon :size="30"><DataAnalysis /></el-icon>
                </div>
                <div class="stat-content">
                  <div class="stat-label">教师/职工/学生比例</div>
                  <div class="stat-value">{{ mockData.patients.teacherStaffStudentRatio }}</div>
                </div>
              </div>

              <div class="stat-card stat-card-red">
                <div class="stat-icon">
                  <el-icon :size="30"><Warning /></el-icon>
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

    <!-- 隐藏的 PDF 报告内容 -->
    <div id="pdf-report-content" style="position: absolute; top: -9999px; left: -9999px; width: 794px; background: white; padding: 30px 20px; font-family: 'Microsoft YaHei', 'SimSun', sans-serif; z-index: -1; opacity: 0; pointer-events: none;">
      <!-- 报告标题 -->
      <div style="text-align: center; margin-bottom: 30px;">
        <h1 style="font-size: 24px; font-weight: bold; color: #1a202c; margin: 0 0 10px 0;">医院运营数据分析报告</h1>
        <p style="font-size: 14px; color: #606266; margin: 0;">{{ reportDate }}</p>
        <div style="border-bottom: 2px solid #e2e8f0; margin-top: 15px;"></div>
      </div>

      <!-- 报告时间段 -->
      <div style="margin-bottom: 25px;">
        <p style="font-size: 12px; color: #606266; margin: 0;">报告时间段：本日/本月至今</p>
      </div>

      <!-- 一、运营核心指标概览 -->
      <div style="margin-bottom: 30px; page-break-inside: avoid;">
        <h2 style="font-size: 18px; font-weight: bold; color: #1a202c; margin: 0 0 15px 0; border-left: 4px solid #667eea; padding-left: 10px; page-break-after: avoid;">一、运营核心指标概览</h2>
        <div style="background: #f7fafc; padding: 20px; border-radius: 8px;">
          <div style="margin-bottom: 10px;"><strong style="color: #2d3748;">累计注册用户：</strong><span style="color: #4a5568;">{{ mockData.overview.totalPatients }} 人</span></div>
          <div style="margin-bottom: 10px;"><strong style="color: #2d3748;">今日挂号量：</strong><span style="color: #4a5568;">{{ mockData.overview.todayAppointments }} 次</span></div>
          <div style="margin-bottom: 10px;"><strong style="color: #2d3748;">今日出诊医生：</strong><span style="color: #4a5568;">{{ mockData.overview.activeDoctorsToday }} 人</span></div>
          <div style="margin-bottom: 10px;"><strong style="color: #2d3748;">本月新增注册：</strong><span style="color: #4a5568;">{{ mockData.patients.monthlyNewRegistrations }} 人</span></div>
          <div style="margin-bottom: 10px;"><strong style="color: #2d3748;">当前候诊人数：</strong><span style="color: #4a5568;">{{ mockData.overview.pendingPatients }} 人</span></div>
          <div><strong style="color: #2d3748;">累计爽约次数：</strong><span style="color: #4a5568;">{{ mockData.patients.totalNoShows }} 次</span></div>
        </div>
      </div>

      <!-- 二、患者群体与用户分析 -->
      <div style="margin-bottom: 30px; page-break-inside: avoid;">
        <h2 style="font-size: 18px; font-weight: bold; color: #1a202c; margin: 0 0 15px 0; border-left: 4px solid #667eea; padding-left: 10px; page-break-after: avoid;">二、患者群体与用户分析</h2>
        
        <h3 style="font-size: 14px; font-weight: bold; color: #2d3748; margin: 0 0 10px 0; page-break-after: avoid;">1. 用户增长趋势</h3>
        <div style="background: #f7fafc; padding: 15px; border-radius: 8px; margin-bottom: 15px;">
          <div><strong style="color: #2d3748;">本月新增注册：</strong><span style="color: #4a5568;">{{ mockData.patients.monthlyNewRegistrations }} 人</span></div>
        </div>

        <h3 style="font-size: 14px; font-weight: bold; color: #2d3748; margin: 0 0 10px 0; page-break-after: avoid;">2. 患者类型构成</h3>
        <div style="background: #f7fafc; padding: 15px; border-radius: 8px; margin-bottom: 15px; page-break-inside: avoid;">
          <div v-for="type in mockData.patients.patientType" :key="type.name" style="margin-bottom: 8px;">
            <strong style="color: #2d3748;">{{ type.name }}：</strong>
            <span style="color: #4a5568;">{{ getPercentage(type.value, mockData.patients.patientType) }}%</span>
          </div>
        </div>

        <h3 style="font-size: 14px; font-weight: bold; color: #2d3748; margin: 0 0 10px 0; page-break-after: avoid;">3. 教师/职工/学生比例</h3>
        <div style="background: #f7fafc; padding: 15px; border-radius: 8px;">
          <div><strong style="color: #2d3748;">比例数据：</strong><span style="color: #4a5568;">{{ mockData.patients.teacherStaffStudentRatio }}</span></div>
        </div>
      </div>

      <!-- 三、医生与医疗资源分析 -->
      <div style="margin-bottom: 30px; page-break-before: always; page-break-inside: avoid;">
        <h2 style="font-size: 18px; font-weight: bold; color: #1a202c; margin: 0 0 15px 0; border-left: 4px solid #667eea; padding-left: 10px; page-break-after: avoid;">三、医生与医疗资源分析</h2>
        
        <h3 style="font-size: 14px; font-weight: bold; color: #2d3748; margin: 0 0 10px 0; page-break-after: avoid;">1. 医生资源概览</h3>
        <div style="background: #f7fafc; padding: 15px; border-radius: 8px; margin-bottom: 15px;">
          <div style="margin-bottom: 8px;"><strong style="color: #2d3748;">医生总数：</strong><span style="color: #4a5568;">{{ mockData.doctors.totalDoctors }} 人</span></div>
          <div style="margin-bottom: 8px;"><strong style="color: #2d3748;">今日请假人数：</strong><span style="color: #4a5568;">{{ mockData.doctors.todayLeaveCount }} 人</span></div>
          <div><strong style="color: #2d3748;">科室总数：</strong><span style="color: #4a5568;">{{ mockData.doctors.totalDepartments }} 个</span></div>
        </div>

        <h3 style="font-size: 14px; font-weight: bold; color: #2d3748; margin: 0 0 10px 0; page-break-after: avoid;">2. 医生工作量 Top 5</h3>
        <div style="background: #f7fafc; padding: 15px; border-radius: 8px; margin-bottom: 15px; page-break-inside: avoid;">
          <div v-for="(doctor, index) in mockData.doctors.doctorWorkload.slice(0, 5)" :key="index" style="margin-bottom: 8px;">
            <strong style="color: #2d3748;">{{ index + 1 }}. {{ doctor.name }}（{{ doctor.department }}）：</strong>
            <span style="color: #4a5568;">{{ doctor.value }} 人次</span>
          </div>
        </div>

        <h3 style="font-size: 14px; font-weight: bold; color: #2d3748; margin: 0 0 10px 0; page-break-after: avoid;">3. 科室繁忙度 Top 5</h3>
        <div style="background: #f7fafc; padding: 15px; border-radius: 8px;">
          <div v-for="(dept, index) in mockData.doctors.departmentBusy.slice(0, 5)" :key="index" style="margin-bottom: 8px;">
            <strong style="color: #2d3748;">{{ index + 1 }}. {{ dept.name }}：</strong>
            <span style="color: #4a5568;">{{ dept.value }} 人次</span>
          </div>
        </div>
      </div>

      <!-- 四、运营效率与财务分析 -->
      <div style="margin-bottom: 30px; page-break-inside: avoid;">
        <h2 style="font-size: 18px; font-weight: bold; color: #1a202c; margin: 0 0 15px 0; border-left: 4px solid #667eea; padding-left: 10px; page-break-after: avoid;">四、运营效率与财务分析</h2>
        
        <h3 style="font-size: 14px; font-weight: bold; color: #2d3748; margin: 0 0 10px 0; page-break-after: avoid;">支付状态分布</h3>
        <div style="background: #f7fafc; padding: 15px; border-radius: 8px;">
          <div v-for="status in mockData.overview.paymentStatus" :key="status.name" style="margin-bottom: 8px;">
            <strong style="color: #2d3748;">{{ status.name }}：</strong>
            <span style="color: #4a5568;">{{ getPercentage(status.value, mockData.overview.paymentStatus) }}%</span>
          </div>
        </div>
      </div>

      <!-- 数据详情 -->
      <div style="margin-bottom: 30px; page-break-before: always;">
        <h2 style="font-size: 18px; font-weight: bold; color: #1a202c; margin: 0 0 15px 0; border-left: 4px solid #667eea; padding-left: 10px;">五、数据详情</h2>
        
        <!-- 挂号趋势数据 -->
        <h3 style="font-size: 14px; font-weight: bold; color: #2d3748; margin: 0 0 10px 0; page-break-after: avoid;">1. 近7日挂号趋势</h3>
        <div style="background: #f7fafc; padding: 15px; border-radius: 8px; margin-bottom: 20px;">
          <table style="width: 100%; border-collapse: collapse;">
            <thead>
              <tr style="background: #e2e8f0;">
                <th style="padding: 8px; text-align: left; border: 1px solid #cbd5e0;">日期</th>
                <th style="padding: 8px; text-align: right; border: 1px solid #cbd5e0;">挂号量</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="(date, index) in mockData.overview.last7DaysDates" :key="index" style="border-bottom: 1px solid #e2e8f0;">
                <td style="padding: 8px; border: 1px solid #cbd5e0;">{{ date }}</td>
                <td style="padding: 8px; text-align: right; border: 1px solid #cbd5e0;">{{ mockData.overview.last7DaysCounts[index] }} 次</td>
              </tr>
            </tbody>
          </table>
        </div>
        
        <!-- 职称分布数据 -->
        <h3 style="font-size: 14px; font-weight: bold; color: #2d3748; margin: 0 0 10px 0; page-break-after: avoid;">2. 医生职称分布</h3>
        <div style="background: #f7fafc; padding: 15px; border-radius: 8px; margin-bottom: 20px;">
          <div v-for="item in mockData.doctors.titleDistribution" :key="item.name" style="margin-bottom: 8px;">
            <strong style="color: #2d3748;">{{ item.name }}：</strong>
            <span style="color: #4a5568;">{{ item.value }} 人 ({{ getPercentage(item.value, mockData.doctors.titleDistribution) }}%)</span>
          </div>
        </div>
        
        <!-- 用户增长数据 -->
        <h3 style="font-size: 14px; font-weight: bold; color: #2d3748; margin: 0 0 10px 0; page-break-after: avoid;">3. 近30日用户增长</h3>
        <div style="background: #f7fafc; padding: 15px; border-radius: 8px; margin-bottom: 20px;">
          <p style="margin: 0 0 10px 0; color: #2d3748;">
            <strong>总新增用户：</strong>{{ mockData.patients.last30DaysCounts.reduce((sum, count) => sum + count, 0) }} 人
          </p>
          <p style="margin: 0 0 10px 0; color: #2d3748;">
            <strong>日均新增：</strong>{{ (mockData.patients.last30DaysCounts.reduce((sum, count) => sum + count, 0) / 30).toFixed(1) }} 人
          </p>
          <p style="margin: 0; color: #2d3748;">
            <strong>峰值日期：</strong>{{ mockData.patients.last30DaysDates[mockData.patients.last30DaysCounts.indexOf(Math.max(...mockData.patients.last30DaysCounts))] }} 
            ({{ Math.max(...mockData.patients.last30DaysCounts) }} 人)
          </p>
        </div>
      </div>

      <!-- 结论与建议 -->
      <div style="page-break-before: always;">
        <h2 style="font-size: 18px; font-weight: bold; color: #1a202c; margin: 0 0 15px 0; border-left: 4px solid #667eea; padding-left: 10px;">💡 结论与行动建议</h2>
        
        <h3 style="font-size: 14px; font-weight: bold; color: #2d3748; margin: 0 0 10px 0;">主要发现：</h3>
        <div style="background: #f7fafc; padding: 15px; border-radius: 8px; margin-bottom: 20px;">
          <div v-for="(finding, index) in reportFindings" :key="index" style="margin-bottom: 10px; line-height: 1.6;">
            <span style="color: #2d3748;">{{ index + 1 }}. {{ finding }}</span>
          </div>
        </div>

        <h3 style="font-size: 14px; font-weight: bold; color: #2d3748; margin: 0 0 10px 0;">行动建议：</h3>
        <div style="background: #f7fafc; padding: 15px; border-radius: 8px;">
          <div v-for="(rec, index) in reportRecommendations" :key="index" style="margin-bottom: 10px; line-height: 1.6;">
            <span style="color: #2d3748;">{{ index + 1 }}. {{ rec }}</span>
          </div>
        </div>
      </div>

      <!-- 页脚 -->
      <div style="margin-top: 40px; text-align: center; font-size: 11px; color: #999999; border-top: 1px solid #e2e8f0; padding-top: 15px;">
        <p style="margin: 0;">报告生成时间：{{ reportGeneratedTime }} | 医院运营数据中心</p>
      </div>
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

// PDF 报告相关数据
const reportDate = ref('')
const reportGeneratedTime = ref('')
const reportFindings = ref([])
const reportRecommendations = ref([])

const getDefaultPatientType = () => ([
  { name: '教师', value: 0 },
  { name: '职工', value: 0 },
  { name: '学生', value: 0 }
])

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
    teacherStaffStudentRatio: '0:0:0',
    totalNoShows: 0,
    last30DaysDates: [],
    last30DaysCounts: [],
    patientType: getDefaultPatientType(),
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
  const patientTypeColors = [
    ['#667eea', '#764ba2'],
    ['#f093fb', '#f5576c'],
    ['#48bb78', '#38a169']
  ]
  const patientTypeData = mockData.patients.patientType.map((item, index) => ({
    value: item.value,
    name: item.name,
    itemStyle: {
      color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
        { offset: 0, color: patientTypeColors[index % patientTypeColors.length][0] },
        { offset: 1, color: patientTypeColors[index % patientTypeColors.length][1] }
      ])
    }
  }))
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
        data: patientTypeData
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

// 计算百分比的辅助函数
const getPercentage = (value, dataArray) => {
  const total = dataArray.reduce((sum, item) => sum + item.value, 0)
  return total > 0 ? ((value / total) * 100).toFixed(1) : '0.0'
}

// 生成结论与建议
const generateSummaryAndRecommendations = () => {
  const findings = []
  const recommendations = []
  
  // 综合分析所有数据
  // 运营总览分析
  if (mockData.overview.todayAppointments > 50) {
    findings.push('今日挂号量较高，医疗服务需求旺盛')
    recommendations.push('建议优化挂号流程，减少患者等待时间')
  } else if (mockData.overview.todayAppointments < 20) {
    findings.push('今日挂号量偏低，可能存在服务推广不足')
    recommendations.push('建议加强医疗服务宣传，提升患者就诊意愿')
  }
  
  if (mockData.overview.pendingPatients > 30) {
    findings.push('当前候诊人数较多，可能存在就诊高峰')
    recommendations.push('建议增加医生排班，优化候诊流程')
  }
  
  // 分析支付状态
  const unpaidCount = mockData.overview.paymentStatus.find(s => s.name === '待支付')?.value || 0
  if (unpaidCount > 10) {
    findings.push('待支付订单较多，可能影响医院收入')
    recommendations.push('建议优化支付流程，增加支付提醒功能')
  }
  
  // 医生资源分析
  if (mockData.doctors.todayLeaveCount > 5) {
    findings.push(`今日请假医生数量较多（${mockData.doctors.todayLeaveCount}人），可能影响正常接诊`)
    recommendations.push('建议建立医生排班备份机制，确保医疗服务连续性')
  }
  
  // 分析医生工作量
  if (mockData.doctors.doctorWorkload.length > 0) {
    const maxWorkload = Math.max(...mockData.doctors.doctorWorkload.map(d => d.value))
    const topDoctor = mockData.doctors.doctorWorkload[0]
    if (maxWorkload > 50) {
      findings.push(`${topDoctor.name}医生工作量已达到饱和状态（${maxWorkload}人次）`)
      recommendations.push('建议合理分配医生工作量，避免过度疲劳')
    }
  }
  
  // 分析科室繁忙度
  if (mockData.doctors.departmentBusy.length > 0) {
    const busiestDept = mockData.doctors.departmentBusy[0]
    findings.push(`${busiestDept.name}科室就诊量最高（${busiestDept.value}人次），为重点科室`)
    recommendations.push(`建议在${busiestDept.name}科室增加医生配置，提升服务能力`)
  }
  
  // 患者群体分析
  if (mockData.patients.monthlyNewRegistrations > 100) {
    findings.push('本月新增注册用户增长强劲，医疗服务影响力提升')
    recommendations.push('建议继续优化用户体验，提高用户留存率')
  }
  
  if (mockData.patients.totalNoShows > 20) {
    findings.push(`累计爽约次数较高（${mockData.patients.totalNoShows}次），影响医疗资源利用率`)
    recommendations.push('建议引入预约提醒机制，降低爽约率')
  }
  
  // 分析患者类型
  const studentType = mockData.patients.patientType.find(t => t.name === '学生')
  if (studentType && studentType.value > 50) {
    const percentage = ((studentType.value / mockData.patients.patientType.reduce((sum, t) => sum + t.value, 0)) * 100).toFixed(1)
    findings.push(`学生群体占比较高（${percentage}%），为主要服务对象`)
    recommendations.push('建议针对学生群体优化就诊时间安排，如增加晚间和周末门诊')
  }
  
  // 如果没有特殊发现，添加默认内容
  if (findings.length === 0) {
    findings.push('当前运营数据整体平稳，各项指标正常')
  }
  if (recommendations.length === 0) {
    recommendations.push('建议持续监控关键指标，及时发现并解决潜在问题')
  }
  
  return { findings, recommendations }
}

// 获取所有图表的 Base64 图片
const getAllChartsAsImages = async () => {
  const chartImages = []
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
  
  for (const chartId of chartIds) {
    const chartInstance = chartInstances.get(chartId)
    if (chartInstance && !chartInstance.isDisposed()) {
      try {
        // 获取图表截图
        const dataUrl = chartInstance.getDataURL({
          type: 'png',
          pixelRatio: 1.5,
          backgroundColor: '#fff'
        })
        chartImages.push({
          id: chartId,
          dataUrl
        })
      } catch (error) {
        console.warn(`无法获取图表 ${chartId} 的图片:`, error)
      }
    }
  }
  
  return chartImages
}

// 导出PDF - 使用 jsPDF.html() 方法
const handleExportPDF = async () => {
  exporting.value = true
  try {
    ElMessage.info('正在生成报表，请稍候...')
    
    // 确保所有数据都已加载
    if (mockData.overview.totalPatients === 0) {
      await loadOverviewData()
    }
    if (mockData.doctors.totalDoctors === 0) {
      await loadDoctorsData()
    }
    if (mockData.patients.monthlyNewRegistrations === 0) {
      await loadPatientsData()
    }
    
    await nextTick()
    await new Promise(resolve => setTimeout(resolve, 300))

    // 准备报告数据
    const now = new Date()
    reportDate.value = now.toLocaleString('zh-CN', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit'
    }).replace(/\//g, '-')
    reportGeneratedTime.value = now.toLocaleString('zh-CN')
    
    // 生成结论与建议
    const { findings, recommendations } = generateSummaryAndRecommendations()
    reportFindings.value = findings
    reportRecommendations.value = recommendations
    
    // 等待 Vue 更新 DOM
    await nextTick()
    await new Promise(resolve => setTimeout(resolve, 200))
    
    // 获取报告内容元素
    const reportContent = document.getElementById('pdf-report-content')
    if (!reportContent) {
      throw new Error('无法找到报告内容元素')
    }
    
    // 临时显示报告内容以便 html2canvas 可以渲染（但保持在屏幕外）
    const originalStyle = {
      position: reportContent.style.position,
      top: reportContent.style.top,
      left: reportContent.style.left,
      opacity: reportContent.style.opacity,
      zIndex: reportContent.style.zIndex,
      visibility: reportContent.style.visibility
    }
    
    // 将元素移到屏幕外但保持可渲染状态
    reportContent.style.position = 'fixed'
    reportContent.style.top = '0'
    reportContent.style.left = '-10000px'  // 保持在屏幕外，避免闪现
    reportContent.style.opacity = '1'
    reportContent.style.zIndex = '-1'
    reportContent.style.visibility = 'visible'
    
    // 等待样式应用
    await nextTick()
    await new Promise(resolve => setTimeout(resolve, 200))
    
    // 使用 html2canvas 直接渲染
    const canvas = await html2canvas(reportContent, {
      scale: 2,
      useCORS: true,
      logging: false,
      backgroundColor: '#ffffff',
      width: 794,
      windowWidth: 794,
      scrollX: 0,
      scrollY: 0
    })
    
    // 立即恢复原始样式
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
    
    // 计算合适的缩放比例，保持内容宽度适中
    const contentWidth = canvas.width  // 实际渲染的内容宽度（794px）
    const targetWidth = pdfWidth - 20  // 左右各留 10mm 边距
    const scale = targetWidth / contentWidth
    
    const imgWidth = targetWidth
    const imgHeight = canvas.height * scale
    
    // 计算居中位置
    const marginX = (pdfWidth - imgWidth) / 2  // 水平居中
    
    // 智能分页：检测内容并在合适的位置分页
    const pageHeightInPixels = pdfHeight / scale  // 转换为原始像素高度
    let currentY = 0
    let pageCount = 0
    
    // 添加第一页
    const tempCanvas = document.createElement('canvas')
    const tempCtx = tempCanvas.getContext('2d')
    
    while (currentY < canvas.height) {
      if (pageCount > 0) {
        pdf.addPage()
      }
      
      // 计算当前页应该显示的高度
      let sliceHeight = Math.min(pageHeightInPixels, canvas.height - currentY)
      
      // 如果不是最后一页，尝试找到更好的切割点（避免在标题处切割）
      if (currentY + sliceHeight < canvas.height) {
        // 在底部 20% 的区域内寻找空白区域
        const searchStart = currentY + sliceHeight * 0.75
        const searchEnd = currentY + sliceHeight
        let bestCutPoint = sliceHeight
        let maxWhiteLines = 0
        let currentWhiteLines = 0
        let bestWhiteLineStart = sliceHeight
        
        // 扫描这个区域，寻找连续的空白行（章节之间的间距）
        for (let y = searchStart; y < searchEnd && y < canvas.height; y++) {
          const imageData = canvas.getContext('2d').getImageData(0, y, canvas.width, 1)
          const pixels = imageData.data
          
          // 检查这一行是否主要是白色（空白）
          let whitePixelCount = 0
          for (let i = 0; i < pixels.length; i += 4) {
            const r = pixels[i]
            const g = pixels[i + 1]
            const b = pixels[i + 2]
            // 如果像素接近白色
            if (r > 245 && g > 245 && b > 245) {
              whitePixelCount++
            }
          }
          
          // 如果这一行超过 95% 是白色
          if (whitePixelCount / canvas.width > 0.95) {
            currentWhiteLines++
            // 记录连续空白行数最多的位置
            if (currentWhiteLines > maxWhiteLines) {
              maxWhiteLines = currentWhiteLines
              bestWhiteLineStart = y - currentY - currentWhiteLines + 1
            }
          } else {
            currentWhiteLines = 0
          }
        }
        
        // 如果找到了至少 3 行连续的空白（约 30px 的间距），在那里切割
        if (maxWhiteLines >= 3) {
          sliceHeight = bestWhiteLineStart + Math.floor(maxWhiteLines / 2)
        }
      }
      
      // 创建当前页的图片切片
      tempCanvas.width = canvas.width
      tempCanvas.height = sliceHeight
      tempCtx.drawImage(
        canvas,
        0, currentY, canvas.width, sliceHeight,
        0, 0, canvas.width, sliceHeight
      )
      
      const pageImgData = tempCanvas.toDataURL('image/png')
      const pageImgHeight = sliceHeight * scale
      
      pdf.addImage(pageImgData, 'PNG', marginX, 0, imgWidth, pageImgHeight)
      
      currentY += sliceHeight
      pageCount++
    }
    
    // 生成文件名并下载
    const fileName = `医院运营数据分析报告_${reportDate.value}.pdf`
    pdf.save(fileName)
    
    ElMessage.success('报表导出成功！')
    
  } catch (error) {
    console.error('导出 PDF 失败:', error)
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
    mockData.patients.teacherStaffStudentRatio = data.teacherStaffStudentRatio || '0:0:0'
    mockData.patients.totalNoShows = data.totalNoShows || 0
    mockData.patients.last30DaysDates = data.last30DaysDates || []
    mockData.patients.last30DaysCounts = (data.last30DaysCounts || []).map(count => Number(count))
    mockData.patients.patientType = (data.patientType && data.patientType.length > 0) ? data.patientType : getDefaultPatientType()
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

/* 顶部欢迎横幅 - 缩小尺寸 */
.welcome-banner {
  background: linear-gradient(135deg, #9f7aea 0%, #667eea 100%);
  border-radius: 8px;
  padding: 16px 24px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  color: white;
  margin: 0 24px 16px 24px;
}

.banner-content h1 {
  font-size: 20px;
  margin: 0 0 4px 0;
  font-weight: bold;
}

.banner-content p {
  font-size: 14px;
  margin: 0;
  opacity: 0.9;
}

.banner-image {
  border-radius: 50%;
  object-fit: cover;
  width: 80px;
  height: 80px;
  border: 3px solid white;
}

/* 内容包装器 - 减少内边距 */
.content-wrapper {
  padding: 0 24px 16px 24px;
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

/* 核心指标卡片 - 缩小尺寸 */
.top-cards {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: 12px;
  margin-bottom: 16px;
}

.stat-card {
  background: white;
  border-radius: 8px;
  padding: 16px;
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
  width: 48px;
  height: 48px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-right: 12px;
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
  font-size: 13px;
  color: #606266;
  margin-bottom: 4px;
  font-weight: normal;
}

.stat-value {
  font-size: 24px;
  font-weight: bold;
  color: #303133;
  line-height: 1;
}

/* 图表区域 - 减少间距 */
.charts-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 12px;
}

.chart-card {
  border-radius: 8px;
}

.chart-card :deep(.el-card__body) {
  padding: 16px;
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
  height: 280px;
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
