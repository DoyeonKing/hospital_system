<template>
  <div class="doctor-schedule">
    <div class="top-navbar">
      <div class="navbar-content">
        <div class="navbar-left">
          <BackButton />
          <div class="logo-section">
            <el-icon :size="28"><Calendar /></el-icon>
            <h2>我的排班</h2>
          </div>
        </div>
        <div class="navbar-right">
          <div class="user-info">
            <el-avatar :size="36" src="@/assets/doctor.jpg" />
            <span class="user-name">{{ doctorStore.displayName }} 医生</span>
          </div>
        </div>
      </div>
    </div>

    <div class="main-content">
      <el-card shadow="always" class="schedule-card">
        <template #header>
          <div class="card-header">
            <div class="header-title-row">
              <span class="department-title">{{ doctorStore.displayName }} - 排班查看</span>
            </div>

            <div class="header-controls">
              <el-button-group class="view-switcher">
                <el-button :type="currentView === 'week' ? 'primary' : ''" @click="changeView('week')">周视图</el-button>
                <el-button :type="currentView === 'month' ? 'primary' : ''" @click="changeView('month')">月视图</el-button>
              </el-button-group>

              <el-button-group v-if="currentView === 'week'" class="week-nav">
                <el-button :icon="ArrowLeft" @click="changeWeek(-1)">上一周</el-button>
                <el-button @click="changeWeek(0)">本周</el-button>
                <el-button :icon="ArrowRight" @click="changeWeek(1)">下一周</el-button>
              </el-button-group>

              <el-button-group v-if="currentView === 'month'" class="month-nav">
                <el-button :icon="ArrowLeft" @click="changeMonth(-1)">上一个月</el-button>
                <el-button @click="changeMonth(0)">本月</el-button>
                <el-button :icon="ArrowRight" @click="changeMonth(1)">下一个月</el-button>
              </el-button-group>

              <el-button :icon="Refresh" @click="loadSchedules" :loading="loading">刷新</el-button>
            </div>
          </div>
        </template>

        <div v-if="currentView === 'week'" class="table-container">
          <div class="schedule-table-wrapper">
            <table class="schedule-table">
              <thead>
              <tr>
                <th class="time-slot-column" style="width: 80px;">班次</th>
                <th class="time-slot-column" style="width: 140px;">时间段</th>
                <th v-for="date in weekDates" :key="date" class="date-column">
                  <div class="date-header">
                    <div class="date-label">{{ formatDateLabel(date) }}</div>
                    <div class="weekday-label">{{ getWeekday(date) }}</div>
                  </div>
                </th>
              </tr>
              </thead>
              <tbody>
              <template v-if="morningTimeSlots.length > 0">
                <tr v-for="(slot, index) in morningTimeSlots" :key="slot.name">
                  <td v-if="index === 0" class="time-slot-column shift-group-label" :rowspan="morningTimeSlots.length">
                    上午
                  </td>
                  <td class="time-slot-column slot-time-label">
                    {{ slot.startTime }} - {{ slot.endTime }}
                  </td>
                  <td v-for="date in weekDates" :key="date" class="schedule-cell">
                    <div class="schedule-content-cell">
                      <template v-if="getScheduleForCell(date, slot.name)">
                        <div class="schedule-item-card" :class="getScheduleStatusClass(getScheduleForCell(date, slot.name))">
                          <div class="schedule-location">
                            <el-icon><Location /></el-icon>
                            {{ getScheduleForCell(date, slot.name).location || '未分配地点' }}
                          </div>
                        </div>
                      </template>
                      <div v-else class="no-schedule">
                        -
                      </div>
                    </div>
                  </td>
                </tr>
              </template>
              <tr v-else>
                <td class="time-slot-column shift-group-label">上午</td>
                <td class="time-slot-column slot-time-label">-</td>
                <td v-for="date in weekDates" :key="date" class="schedule-cell">
                  <div class="no-schedule">-</div>
                </td>
              </tr>

              <template v-if="afternoonTimeSlots.length > 0">
                <tr v-for="(slot, index) in afternoonTimeSlots" :key="slot.name">
                  <td v-if="index === 0" class="time-slot-column shift-group-label" :rowspan="afternoonTimeSlots.length">
                    下午
                  </td>
                  <td class="time-slot-column slot-time-label">
                    {{ slot.startTime }} - {{ slot.endTime }}
                  </td>
                  <td v-for="date in weekDates" :key="date" class="schedule-cell">
                    <div class="schedule-content-cell">
                      <template v-if="getScheduleForCell(date, slot.name)">
                        <div class="schedule-item-card" :class="getScheduleStatusClass(getScheduleForCell(date, slot.name))">
                          <div class="schedule-location">
                            <el-icon><Location /></el-icon>
                            {{ getScheduleForCell(date, slot.name).location || '未分配地点' }}
                          </div>
                        </div>
                      </template>
                      <div v-else class="no-schedule">
                        -
                      </div>
                    </div>
                  </td>
                </tr>
              </template>
              <tr v-else>
                <td class="time-slot-column shift-group-label">下午</td>
                <td class="time-slot-column slot-time-label">-</td>
                <td v-for="date in weekDates" :key="date" class="schedule-cell">
                  <div class="no-schedule">-</div>
                </td>
              </tr>
              </tbody>
            </table>
          </div>
        </div>

        <div v-else-if="currentView === 'month'" class="month-view-container">
          <div class="month-header">
            <h3 class="month-title">{{ currentMonthYear }}</h3>
          </div>
          <div class="month-calendar">
            <div class="calendar-weekdays">
              <div class="weekday-cell" v-for="day in weekdays" :key="day">{{ day }}</div>
            </div>
            <div class="calendar-days">
              <div
                  v-for="(day, index) in monthDays"
                  :key="index"
                  class="calendar-day"
                  :class="{
                  'other-month': !day.isCurrentMonth,
                  'today': day.isToday,
                  'has-schedule': day.schedules && day.schedules.length > 0
                }"
                  @click="selectDay(day)"
              >
                <div class="day-number">{{ day.date }}</div>
                <div class="day-schedules">
                  <div
                      v-for="(schedule, idx) in (day.schedules || []).slice(0, 3)"
                      :key="idx"
                      class="schedule-dot"
                      :class="getScheduleStatusClass(schedule)"
                      :title="`${schedule.slotName || '时间段'} - ${schedule.location || '未分配地点'}`"
                  ></div>
                  <div v-if="day.schedules && day.schedules.length > 3" class="more-schedules">
                    +{{ day.schedules.length - 3 }}
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div v-if="selectedDaySchedules.length > 0" class="selected-day-details">
            <h4 class="details-title">{{ selectedDayDate }} 的排班详情</h4>
            <div class="details-list">
              <div
                  v-for="schedule in selectedDaySchedules"
                  :key="schedule.scheduleId"
                  class="detail-item"
                  :class="getScheduleStatusClass(schedule)"
              >
                <div class="detail-time">
                  <el-icon><Clock /></el-icon>
                  {{ schedule.slotName || (schedule.startTime ? schedule.startTime + '-' + schedule.endTime : '时间段') }}
                </div>
                <div class="detail-location">
                  <el-icon><Location /></el-icon>
                  {{ schedule.location || '未分配地点' }}
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="schedule-stats">
          <el-card shadow="never" class="stat-card-item">
            <div class="stat-content">
              <div class="stat-icon total">
                <el-icon :size="24"><Calendar /></el-icon>
              </div>
              <div class="stat-info">
                <div class="stat-label">总排班数</div>
                <div class="stat-value">{{ scheduleStats.total }}</div>
              </div>
            </div>
          </el-card>

          <el-card shadow="never" class="stat-card-item">
            <div class="stat-content">
              <div class="stat-icon available">
                <el-icon :size="24"><CircleCheck /></el-icon>
              </div>
              <div class="stat-info">
                <div class="stat-label">可用排班</div>
                <div class="stat-value">{{ scheduleStats.available }}</div>
              </div>
            </div>
          </el-card>

          <el-card shadow="never" class="stat-card-item">
            <div class="stat-content">
              <div class="stat-icon booked">
                <el-icon :size="24"><User /></el-icon>
              </div>
              <div class="stat-info">
                <div class="stat-label">总预约人次</div>
                <div class="stat-value">{{ scheduleStats.booked }}</div>
              </div>
            </div>
          </el-card>

        </div>
      </el-card>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import {
  ArrowLeft, ArrowRight, Calendar, Location, Refresh,
  CircleCheck, User, Clock
} from '@element-plus/icons-vue'
import { useDoctorStore } from '@/stores/doctorStore'
import request from '@/utils/request'
// 【新增】导入 BackButton
import BackButton from '@/components/BackButton.vue'

const router = useRouter()
const doctorStore = useDoctorStore()

// 状态
const currentView = ref('week')
const loading = ref(false)
const selectedDate = ref(new Date().toISOString().split('T')[0])
const currentMonth = ref(new Date().getMonth())
const currentYear = ref(new Date().getFullYear())
const selectedDayDate = ref('')

// 排班数据
const schedules = ref([])

// 当前周的周一日期
const currentMonday = ref(new Date())

// 计算当前周的日期数组
const weekDates = computed(() => {
  const monday = new Date(currentMonday.value)
  const dates = []
  for (let i = 0; i < 7; i++) {
    const date = new Date(monday)
    date.setDate(monday.getDate() + i)
    dates.push(date.toISOString().split('T')[0])
  }
  return dates
})

// 【已修改】这个值现在用于计算统计，而不是表格
const SHIFTS_PER_DAY = 2

const getDayCountForCurrentRange = () => {
  if (currentView.value === 'week') {
    return weekDates.value.length
  }
  const firstDay = new Date(currentYear.value, currentMonth.value, 1)
  const lastDay = new Date(currentYear.value, currentMonth.value + 1, 0)
  return lastDay.getDate()
}

// 排班统计
const scheduleStats = computed(() => {
  const total = schedules.value.length
  const theoreticalSlots = getDayCountForCurrentRange() * SHIFTS_PER_DAY
  const available = Math.max(theoreticalSlots - total, 0)
  const booked = schedules.value.reduce((sum, s) => sum + (s.bookedSlots || 0), 0)

  return { total, available, booked }
})


// 【新增】获取本周所有不重复的时间段 (用于生成表格行)
const uniqueTimeSlots = computed(() => {
  const slots = new Map();
  // 我们从 *所有* 虚拟数据中提取时间段，以确保周/月切换时时间段一致
  // 真实场景下，您可能需要一个专门的 "获取时间段" 接口
  const allMockSchedules = generateMockSchedules('2025-01-01', '2025-12-31');

  for (const s of allMockSchedules) {
    if (s.slotName && !slots.has(s.slotName)) {
      slots.set(s.slotName, {
        name: s.slotName,
        startTime: s.startTime,
        endTime: s.endTime,
        shift: (s.startTime < '12:00' ? '上午' : '下午')
      });
    }
  }
  return Array.from(slots.values()).sort((a, b) => a.startTime.localeCompare(b.startTime));
});

// 【新增】上午的时间段
const morningTimeSlots = computed(() => uniqueTimeSlots.value.filter(s => s.shift === '上午'));
// 【新增】下午的时间段
const afternoonTimeSlots = computed(() => uniqueTimeSlots.value.filter(s => s.shift === '下午'));

// 【新增】获取指定日期和 *特定时间段* 的排班
const getScheduleForCell = (date, slotName) => {
  // schedules.value 只包含当前医生在当前范围内的排班
  return schedules.value.find(s => s.scheduleDate === date && s.slotName === slotName);
}

// 【已废弃】
// const getSchedulesForDateAndShift = (date, shift) => { ... }

// 获取排班状态样式类
const getScheduleStatusClass = (schedule) => {
  if (!schedule) return '';
  const status = schedule.status?.toLowerCase()
  if (status === 'available' || status === 'AVAILABLE') {
    return 'status-available'
  } else if (status === 'full' || status === 'FULL') {
    return 'status-full'
  } else if (status === 'cancelled' || status === 'CANCELLED') {
    return 'status-cancelled'
  }
  return ''
}

// 格式化日期标签
const formatDateLabel = (dateStr) => {
  const date = new Date(dateStr)
  const month = date.getMonth() + 1
  const day = date.getDate()
  return `${month}/${day}`
}

// 获取星期几
const getWeekday = (dateStr) => {
  const date = new Date(dateStr)
  const weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六']
  return weekdays[date.getDay()]
}

// 星期数组（用于月视图）
const weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六']

// 当前月份和年份
const currentMonthYear = computed(() => {
  return `${currentYear.value}年${currentMonth.value + 1}月`
})

// 生成月视图的日期数组
const monthDays = computed(() => {
  const days = []
  const firstDay = new Date(currentYear.value, currentMonth.value, 1)
  const lastDay = new Date(currentYear.value, currentMonth.value + 1, 0)
  const firstDayOfWeek = firstDay.getDay()
  const daysInMonth = lastDay.getDate()
  const today = new Date()
  const todayStr = today.toISOString().split('T')[0]

  // 添加上个月的日期
  const prevMonth = new Date(currentYear.value, currentMonth.value, 0)
  const prevMonthDays = prevMonth.getDate()
  const prevMonthNum = currentMonth.value === 0 ? 11 : currentMonth.value - 1
  const prevYear = currentMonth.value === 0 ? currentYear.value - 1 : currentYear.value
  for (let i = firstDayOfWeek - 1; i >= 0; i--) {
    const date = prevMonthDays - i
    const dateStr = `${prevYear}-${String(prevMonthNum + 1).padStart(2, '0')}-${String(date).padStart(2, '0')}`
    days.push({
      date: date,
      dateStr: dateStr,
      isCurrentMonth: false,
      isToday: false,
      schedules: getSchedulesForDate(dateStr)
    })
  }

  // 添加当前月的日期
  for (let date = 1; date <= daysInMonth; date++) {
    const dateStr = `${currentYear.value}-${String(currentMonth.value + 1).padStart(2, '0')}-${String(date).padStart(2, '0')}`
    days.push({
      date: date,
      dateStr: dateStr,
      isCurrentMonth: true,
      isToday: dateStr === todayStr,
      schedules: getSchedulesForDate(dateStr)
    })
  }

  // 添加下个月的日期（填满6行）
  const remainingDays = 42 - days.length
  const nextMonthNum = currentMonth.value === 11 ? 0 : currentMonth.value + 1
  const nextYear = currentMonth.value === 11 ? currentYear.value + 1 : currentYear.value
  for (let date = 1; date <= remainingDays; date++) {
    const dateStr = `${nextYear}-${String(nextMonthNum + 1).padStart(2, '0')}-${String(date).padStart(2, '0')}`
    days.push({
      date: date,
      dateStr: dateStr,
      isCurrentMonth: false,
      isToday: false,
      schedules: getSchedulesForDate(dateStr)
    })
  }

  return days
})

// 获取指定日期的所有排班
const getSchedulesForDate = (dateStr) => {
  return schedules.value.filter(schedule => schedule.scheduleDate === dateStr)
}

// 选中日期的排班
const selectedDaySchedules = computed(() => {
  if (!selectedDayDate.value) return []
  return getSchedulesForDate(selectedDayDate.value)
})

// 切换视图
const changeView = (viewType) => {
  currentView.value = viewType
  // 切换视图时都重新加载数据
  loadSchedules()
}

// 切换月份
const changeMonth = (offset) => {
  if (offset === 0) {
    const today = new Date()
    currentMonth.value = today.getMonth()
    currentYear.value = today.getFullYear()
  } else {
    currentMonth.value += offset
    if (currentMonth.value < 0) {
      currentMonth.value = 11
      currentYear.value -= 1
    } else if (currentMonth.value > 11) {
      currentMonth.value = 0
      currentYear.value += 1
    }
  }
  loadSchedules()
}

// 选择日期
const selectDay = (day) => {
  if (day.isCurrentMonth) {
    selectedDayDate.value = day.dateStr
  }
}

// 切换周
const changeWeek = (offset) => {
  if (offset === 0) {
    const today = new Date()
    const dayOfWeek = today.getDay()
    const diff = today.getDate() - dayOfWeek + (dayOfWeek === 0 ? -6 : 1)
    currentMonday.value = new Date(today)
    currentMonday.value.setDate(diff)
  } else {
    const newMonday = new Date(currentMonday.value)
    newMonday.setDate(newMonday.getDate() + (offset * 7))
    currentMonday.value = newMonday
  }
  loadSchedules()
}

// 【已废弃】
// const handleDateChange = () => { ... }

// 【已修改】加载排班数据 - 强制使用虚拟数据
const loadSchedules = async () => {
  // 1. 确保有医生ID (用于虚拟数据)
  const doctorId = doctorStore.currentDoctorId || doctorStore.detailedDoctorInfo?.doctorId || doctorStore.doctorInfo?.doctorId
  if (!doctorId) {
    ElMessage.warning('未获取到医生ID，请重新登录')
    return
  }

  loading.value = true

  // 2. 计算日期范围
  let startDate, endDate
  if (currentView.value === 'week') {
    startDate = weekDates.value[0]
    endDate = weekDates.value[6]
  } else {
    // 月视图：需要加载T+30天 和 T-30天的数据以填充日历
    const firstDay = new Date(currentYear.value, currentMonth.value, 1 - 7) // 向前多看7天
    const lastDay = new Date(currentYear.value, currentMonth.value + 1, 0 + 7) // 向后多看7天
    startDate = firstDay.toISOString().split('T')[0]
    endDate = lastDay.toISOString().split('T')[0]
  }

  // 3. 模拟网络延迟
  await new Promise(resolve => setTimeout(resolve, 500));

  // 4. 【修改】直接调用虚拟数据
  try {
    // 虚拟数据现在只返回 *指定日期范围内* 的数据
    schedules.value = generateMockSchedules(startDate, endDate)
    ElMessage.info('已加载模拟排班数据')

    // 如果是月视图，自动选中今天
    if(currentView.value === 'month' && !selectedDayDate.value) {
      selectedDayDate.value = new Date().toISOString().split('T')[0];
    }

  } catch(e) {
    console.error("生成虚拟数据时出错:", e)
    ElMessage.error("加载模拟数据失败")
  } finally {
    loading.value = false
  }

  // --- 【真实接口 - 已注释掉】 ---
  // (您可以稍后恢复这段代码)
  // loading.value = true
  // try {
  //   const params = {
  //     doctorId: doctorId,
  //     startDate: startDate,
  //     endDate: endDate,
  //     page: 0,
  //     size: 1000
  //   }

  //   try {
  //     const response = await request({
  //       url: '/api/schedules',
  //       method: 'get',
  //       params: params
  //     })

  //     if (response && response.content) {
  //       schedules.value = response.content
  //       ElMessage.success('排班数据加载成功')
  //     } else {
  //       schedules.value = [] // 真实接口返回空
  //       ElMessage.info('当前范围暂无排班数据')
  //     }
  //   } catch (apiError) {
  //     console.log('API调用失败，使用虚拟数据:', apiError.message)
  //     schedules.value = generateMockSchedules(startDate, endDate) // API失败时才启用虚拟数据
  //     ElMessage.info('使用模拟数据展示（后端服务未连接）')
  //   }

  //   if(currentView.value === 'month' && !selectedDayDate.value) {
  //     selectedDayDate.value = new Date().toISOString().split('T')[0];
  //   }

  // } catch (error) {
  //   console.error('加载排班数据失败:', error)
  //   schedules.value = generateMockSchedules(startDate, endDate)
  //   ElMessage.info('使用模拟数据展示')
  // } finally {
  //   loading.value = false
  // }
}


// 返回
const goBack = () => {
  router.push('/doctor-dashboard')
}

// 生成虚拟排班数据 (只为当前医生)
const generateMockSchedules = (startDate, endDate) => {
  const mockSchedules = []
  const start = new Date(startDate)
  const end = new Date(endDate)
  const locations = ['门诊楼301室', '门诊楼203室', '门诊楼105室', '门诊楼402室', '门诊楼208室']
  // 【修改】固定的时间段
  const morningSlots = [
    { name: '上午 (08:00-12:00)', start: '08:00', end: '12:00', id: 1 }
  ]
  const afternoonSlots = [
    { name: '下午 (14:00-17:00)', start: '14:00', end: '17:00', id: 3 }
  ]

  // 【重要】只使用当前 store 中的 doctorId
  const doctorId = doctorStore.currentDoctorId || doctorStore.detailedDoctorInfo.doctorId || doctorStore.doctorInfo?.doctorId || '1'

  let scheduleId = 1000 // 从1000开始，避免与真实数据冲突

  for (let d = new Date(start); d <= end; d.setDate(d.getDate() + 1)) {
    const dateStr = d.toISOString().split('T')[0]
    const dayOfWeek = d.getDay()

    // 工作日（周一到周五）添加排班
    if (dayOfWeek >= 1 && dayOfWeek <= 5) {

      // 70%概率有上午排班
      if (Math.random() > 0.3) {
        const morningSlot = morningSlots[0] // 只有一个上午时间段
        const bookedSlots = Math.floor(Math.random() * 8)
        const status = bookedSlots >= 10 ? 'FULL' : 'AVAILABLE'

        mockSchedules.push({
          scheduleId: scheduleId++,
          doctorId: doctorId, // <--- 确保是当前医生
          scheduleDate: dateStr,
          slotId: morningSlot.id,
          slotName: morningSlot.name,
          startTime: morningSlot.start,
          endTime: morningSlot.end,
          locationId: Math.floor(Math.random() * locations.length) + 1,
          location: locations[Math.floor(Math.random() * locations.length)],
          totalSlots: 10,
          bookedSlots: bookedSlots,
          fee: (Math.random() * 15 + 5).toFixed(2),
          status: status,
          remarks: `(虚拟)`
        })
      }

      // 60%概率有下午排班
      if (Math.random() > 0.4) {
        const afternoonSlot = afternoonSlots[0] // 只有一个下午时间段
        const bookedSlots = Math.floor(Math.random() * 8)
        const status = bookedSlots >= 10 ? 'FULL' : 'AVAILABLE'

        mockSchedules.push({
          scheduleId: scheduleId++,
          doctorId: doctorId, // <--- 确保是当前医生
          scheduleDate: dateStr,
          slotId: afternoonSlot.id,
          slotName: afternoonSlot.name,
          startTime: afternoonSlot.start,
          endTime: afternoonSlot.end,
          locationId: Math.floor(Math.random() * locations.length) + 1,
          location: locations[Math.floor(Math.random() * locations.length)],
          totalSlots: 10,
          bookedSlots: bookedSlots,
          fee: (Math.random() * 15 + 5).toFixed(2),
          status: status,
          remarks: `(虚拟)`
        })
      }
    }
  }

  return mockSchedules
}

// 页面加载时获取排班数据
onMounted(() => {
  // 初始化当前周的周一
  const today = new Date()
  const dayOfWeek = today.getDay()
  const diff = today.getDate() - dayOfWeek + (dayOfWeek === 0 ? -6 : 1)
  currentMonday.value = new Date(today)
  currentMonday.value.setDate(diff)

  loadSchedules()
})
</script>

<style scoped>
.doctor-schedule {
  min-height: 100vh;
  background: linear-gradient(135deg, #f5f7fa 0%, #e8eef5 100%);
}

/* 顶部导航栏 */
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
  max-width: 1600px;
  margin: 0 auto;
  padding: 0 32px;
}

.navbar-left {
  display: flex;
  align-items: center;
  gap: 16px;
}

.logo-section {
  display: flex;
  align-items: center;
  gap: 12px;
  /* 【新增】 避免返回按钮挤压 */
  margin-left: 8px;
}

.logo-section h2 {
  margin: 0;
  font-size: 1.4rem;
  font-weight: 600;
  color: #2c3e50;
}

.navbar-right {
  display: flex;
  align-items: center;
  gap: 20px;
}

.user-info {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 8px 16px;
  background: #f5f7fa;
  border-radius: 20px;
}

.user-name {
  font-size: 0.95rem;
  font-weight: 500;
  color: #2c3e50;
}

.main-content {
  max-width: 1600px;
  margin: 0 auto;
  padding: 32px;
}

.schedule-card {
  background: #fff;
  border-radius: 16px;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.08);
}

.card-header {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.header-title-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.department-title {
  font-size: 18px;
  font-weight: 600;
  color: #303133;
}

.header-controls {
  display: flex;
  align-items: center;
  gap: 12px;
  flex-wrap: wrap;
}

.view-switcher :deep(.el-button),
.week-nav :deep(.el-button) {
  padding: 6px 12px;
}

/* 表格容器 */
.table-container {
  width: 100%;
  overflow-x: auto;
  margin-bottom: 24px;
}

.schedule-table-wrapper {
  min-width: 1200px;
}

.schedule-table {
  width: 100%;
  border-collapse: collapse;
  text-align: center;
}

.schedule-table th,
.schedule-table td {
  border: 1px solid #e4e7ed;
  padding: 12px;
}

.schedule-table th {
  background-color: #f5f7fa;
  font-weight: 600;
  color: #303133;
}

.time-slot-column {
  background-color: #f9fafb;
  vertical-align: middle;
}

/* 【新增】 班次 (上午/下午) 标签 */
.shift-group-label {
  font-weight: 600;
  color: #303133;
  font-size: 16px;
  background-color: #f5f7fa;
}

/* 【新增】 时间段 (08:00-12:00) 标签 */
.slot-time-label {
  font-weight: 500;
  color: #606266;
  font-size: 14px;
}


.date-header {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.date-label {
  font-size: 16px;
  font-weight: 600;
  color: #303133;
}

.weekday-label {
  font-size: 12px;
  color: #909399;
}

.schedule-cell {
  vertical-align: top;
  min-height: 80px; /* 【修改】 减小高度 */
}

.schedule-content-cell {
  min-height: 60px; /* 【修改】 减小高度 */
  padding: 8px;
}

/* 【已修改】 卡片样式 */
.schedule-item-card {
  background: #f0f9ff;
  border: 1px solid #bae6fd;
  border-radius: 8px;
  padding: 10px 12px; /* 【修改】 减小内边距 */
  margin-bottom: 8px;
  transition: all 0.2s ease;
  text-align: left; /* 文字左对齐 */
}

.schedule-item-card:hover {
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  transform: translateY(-2px);
}

.schedule-item-card.status-available {
  background: #f0f9ff;
  border-color: #bae6fd;
}
.schedule-item-card.status-available .schedule-location {
  color: #1e40af;
}

.schedule-item-card.status-full {
  background: #fef2f2;
  border-color: #fecaca;
}
.schedule-item-card.status-full .schedule-location {
  color: #b91c1c;
  text-decoration: line-through;
}

.schedule-item-card.status-cancelled {
  background: #f3f4f6;
  border-color: #d1d5db;
}
.schedule-item-card.status-cancelled .schedule-location {
  color: #6b7280;
  text-decoration: line-through;
}


/* 【已修改】 只保留地点 */
.schedule-location {
  display: flex;
  align-items: center;
  gap: 4px;
  font-weight: 500;
  font-size: 14px;
}

/* 【已删除】 .schedule-time, .schedule-info, .schedule-remarks */

.no-schedule {
  color: #c0c4cc;
  font-size: 13px;
  padding: 10px 0; /* 【修改】 减小内边距 */
  text-align: center;
}


/* 排班统计 */
.schedule-stats {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 16px;
  margin-top: 24px;
}

.stat-card-item {
  border: 1px solid #e4e7ed;
  border-radius: 8px;
}

.stat-content {
  display: flex;
  align-items: center;
  gap: 16px;
}

.stat-icon {
  width: 48px;
  height: 48px;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #fff;
}

.stat-icon.total {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.stat-icon.available {
  background: linear-gradient(135deg, #84fab0 0%, #8fd3f4 100%);
}

.stat-icon.booked {
  background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
}

.stat-info {
  flex: 1;
}

.stat-label {
  font-size: 13px;
  color: #909399;
  margin-bottom: 4px;
}

.stat-value {
  font-size: 20px;
  font-weight: 600;
  color: #303133;
}

/* 月视图样式 */
.month-view-container {
  margin-bottom: 24px;
}

.month-header {
  text-align: center;
  margin-bottom: 20px;
}

.month-title {
  font-size: 20px;
  font-weight: 600;
  color: #303133;
  margin: 0;
}

.month-calendar {
  border: 1px solid #e4e7ed;
  border-radius: 8px;
  overflow: hidden;
  background: #fff;
}

.calendar-weekdays {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  background-color: #f5f7fa;
  border-bottom: 2px solid #e4e7ed;
}

.weekday-cell {
  padding: 12px;
  text-align: center;
  font-weight: 600;
  color: #606266;
  font-size: 14px;
}

.calendar-days {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
}

.calendar-day {
  min-height: 100px;
  border: 1px solid #e4e7ed;
  padding: 8px;
  cursor: pointer;
  transition: all 0.2s ease;
  background: #fff;
  position: relative;
}

.calendar-day:hover {
  background-color: #f5f7fa;
  z-index: 1;
}

.calendar-day.other-month {
  background-color: #fafafa;
  color: #c0c4cc;
}

.calendar-day.today {
  background-color: #ecf5ff;
  border: 2px solid #409eff;
}

.calendar-day.today .day-number {
  color: #409eff;
  font-weight: 600;
}

.calendar-day.has-schedule {
  background-color: #f0f9ff;
}

.day-number {
  font-size: 14px;
  font-weight: 500;
  color: #303133;
  margin-bottom: 4px;
}

.day-schedules {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
  margin-top: 4px;
}

.schedule-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background-color: #67c23a;
  cursor: pointer;
}

.schedule-dot.status-available {
  background-color: #67c23a;
}

.schedule-dot.status-full {
  background-color: #f56c6c;
}

.schedule-dot.status-cancelled {
  background-color: #909399;
}

.more-schedules {
  font-size: 10px;
  color: #909399;
  margin-left: 2px;
}

.selected-day-details {
  margin-top: 24px;
  padding: 20px;
  background: #f9fafb;
  border-radius: 8px;
  border: 1px solid #e4e7ed;
}

.details-title {
  font-size: 16px;
  font-weight: 600;
  color: #303133;
  margin: 0 0 16px 0;
}

.details-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.detail-item {
  background: #fff;
  padding: 16px;
  border-radius: 8px;
  border: 1px solid #e4e7ed;
  transition: all 0.2s ease;
}

.detail-item:hover {
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  transform: translateY(-2px);
}

.detail-item.status-available {
  border-left: 4px solid #67c23a;
}

.detail-item.status-full {
  border-left: 4px solid #f56c6c;
}

.detail-item.status-cancelled {
  border-left: 4px solid #909399;
}

.detail-time {
  display: flex;
  align-items: center;
  gap: 8px;
  font-weight: 600;
  color: #303133;
  margin-bottom: 8px;
  font-size: 15px;
}

.detail-location {
  display: flex;
  align-items: center;
  gap: 8px;
  color: #606266;
  margin-bottom: 8px;
  font-size: 14px;
}

/* 【已删除】 .detail-info */

.view-switcher :deep(.el-button),
.week-nav :deep(.el-button),
.month-nav :deep(.el-button) {
  padding: 6px 12px;
}

/* 响应式设计 */
@media (max-width: 1200px) {
  .schedule-stats {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (max-width: 768px) {
  .main-content {
    padding: 16px;
  }

  .header-controls {
    flex-direction: column;
    align-items: stretch;
  }

  .schedule-stats {
    grid-template-columns: 1fr;
  }

  .calendar-day {
    min-height: 80px;
    padding: 4px;
  }

  .day-number {
    font-size: 12px;
  }

  .schedule-dot {
    width: 6px;
    height: 6px;
  }
}
</style>