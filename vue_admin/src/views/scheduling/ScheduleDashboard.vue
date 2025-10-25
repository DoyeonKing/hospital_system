<template>
  <div class="schedule-dashboard">
    <div class="back-area" style="margin-bottom: 12px;">
      <BackButton />
    </div>
    <!-- 左侧科室导航 -->
    <div class="department-sidebar">
      <div v-if="loadingDepartments" class="loading-container">
        <el-icon class="is-loading"><Loading /></el-icon>
        <span>加载科室数据中...</span>
      </div>
      <template v-else>
        <el-menu :default-active="activeParent" class="department-menu" @select="handleParentSelect">
          <el-menu-item v-for="parent in departments" :key="parent.id" :index="parent.id">
            <span>{{ parent.name }}</span>
          </el-menu-item>
        </el-menu>

        <div class="sub-department-panel" v-if="subDepartments.length > 0">
          <div v-for="sub in subDepartments" :key="sub.id" class="sub-department-item" :class="{ 'active': activeSub === sub.id }" @click="handleSubSelect(sub.id)">
            {{ sub.name }}
          </div>
        </div>
        <div v-else-if="activeParent && departments.find(p => p.id === activeParent)?.children?.length === 0" class="no-sub-departments">
          <el-empty description="该科室暂无子科室" :image-size="60"/>
        </div>
      </template>
    </div>

    <!-- 右侧内容区 -->
    <div class="schedule-content">
      <el-card shadow="always" class="schedule-card">
        <template #header>
          <div class="card-header">
             <span>{{ selectedDepartmentName }} ({{ selectedDepartmentCode }}) - 排班管理</span>
             
             <!-- 排班状态指示器 -->
             <div class="schedule-status-indicator">
               <div v-if="scheduleStatus.saving" class="status-saving">
                 <el-icon class="is-loading"><Loading /></el-icon>
                 <span>正在保存排班...</span>
               </div>
               <div v-else-if="scheduleStatus.lastSaved" class="status-success">
                 <el-icon><CircleCheck /></el-icon>
                 <span>最后保存：{{ scheduleStatus.lastSaved.doctor }} - {{ scheduleStatus.lastSaved.timestamp }}</span>
               </div>
               <div v-else-if="scheduleStatus.error" class="status-error">
                 <el-icon><CircleClose /></el-icon>
                 <span>保存失败：{{ scheduleStatus.error.doctor }} - {{ scheduleStatus.error.timestamp }}</span>
               </div>
             </div>
             
             <div class="header-controls">
               <!-- 冲突信息显示 -->
               <div class="conflict-controls">
                 <div v-if="conflictData.hasConflicts" class="conflict-summary">
                   <el-icon class="conflict-summary-icon" :class="conflictData.summary.critical > 0 ? 'critical-icon' : 'warning-icon'">
                     <Warning />
                   </el-icon>
                   <span class="conflict-text">
                     发现 {{ conflictData.summary.total }} 个冲突
                     <span v-if="conflictData.summary.critical > 0" class="critical-count">
                       (严重: {{ conflictData.summary.critical }})
                     </span>
                     <span v-if="conflictData.summary.warning > 0" class="warning-count">
                       (警告: {{ conflictData.summary.warning }})
                     </span>
                   </span>
                 </div>
               </div>
               
               <!-- 视图切换按钮 -->
               <el-button-group class="view-switcher">
                 <el-button 
                   :type="currentView === 'day' ? 'primary' : ''" 
                   @click="changeView('day')">
                   日视图
                 </el-button>
                 <el-button 
                   :type="currentView === 'week' ? 'primary' : ''" 
                   @click="changeView('week')">
                   周视图
                 </el-button>
                 <el-button 
                   :type="currentView === 'month' ? 'primary' : ''" 
                   @click="changeView('month')">
                   月视图
                 </el-button>
               </el-button-group>
               <!-- 周视图导航按钮 -->
               <el-button-group v-if="currentView === 'week'">
                <el-button :icon="ArrowLeft" @click="changeWeek(-1)">上一周</el-button>
                <el-button @click="changeWeek(0)">本周</el-button>
                <el-button :icon="ArrowRight" @click="changeWeek(1)">下一周</el-button>
              </el-button-group>
            </div>
          </div>
        </template>

         <!-- 日历视图 -->
         <div v-if="currentView !== 'week'" class="calendar-view">
           <div class="calendar-container">
             <FullCalendar 
               ref="fullCalendar"
               :options="calendarOptions"
             />
           </div>
         </div>

         <!-- 周视图表格 -->
         <div v-if="currentView === 'week'">
        <div v-if="activeSub">
          <table class="schedule-table">
            <thead>
            <tr>
              <th>门诊时段</th>
              <th v-for="day in weekDates" :key="day.fullDate">{{ day.date }} ({{ day.dayOfWeek }})</th>
            </tr>
            </thead>
            <tbody>
            <tr v-for="shift in ['上午', '下午']" :key="shift">
              <td class="time-slot-column" @dragover.prevent @drop="onDrop($event, null, shift)">
                <div class="shift-label">{{ shift }}</div>
                <!-- 时间段卡片区域 - 只显示在这个列中 -->
                <div class="time-slot-cards">
                  <div v-for="timeSlot in getTimeSlotsForShift(shift)" :key="timeSlot.slotId || timeSlot.slot_id"
                          class="time-slot-card" 
                          :class="{ 
                            'time-slot-mismatch': !isTimeSlotMatchShift(timeSlot, shift)
                          }"
                          draggable="true" 
                       @dragstart="onDragStart($event, { type: 'timeSlot', data: timeSlot })">
                    <div class="time-slot-card-content">
                      <div class="time-slot-name">{{ timeSlot.slotName || timeSlot.slot_name }}</div>
                      <div class="time-slot-time">{{ (timeSlot.startTime || timeSlot.start_time) }} - {{ (timeSlot.endTime || timeSlot.end_time) }}</div>
                         <!-- 班次不匹配警告 -->
                         <div v-if="!isTimeSlotMatchShift(timeSlot, shift)" class="shift-mismatch-warning">
                           <el-icon class="warning-icon"><Warning /></el-icon>
                           <span>班次不匹配</span>
                         </div>
                    </div>
                    <el-icon class="remove-icon" @click="removeTimeSlotFromColumn(timeSlot, shift)"><Close /></el-icon>
                  </div>
                </div>
              </td>
              <td v-for="day in weekDates" :key="day.fullDate + '-' + shift"
                  @dragover.prevent @drop="onDrop($event, day.fullDate, shift)">
                <div class="shift-cell">
                  <div class="doctor-tags">
                    <div v-for="doc in getDoctorsForShift(day.fullDate, shift)" :key="doc.id"
                            class="doctor-card-in-table" 
                            :class="getDoctorConflictClass(doc, day.fullDate, shift)"
                            :data-doctor-id="doc.id" 
                            draggable="true" 
                            @dragstart="onDragStart($event, { type: 'doctor', data: doc }, day.fullDate, shift)"
                            @click="showConflictDetails(doc, day.fullDate, shift)">
                      <div class="doctor-card-header">
                        <img :src="getDoctorAvatar(doc.id)" alt="医生头像" class="doctor-avatar-small">
                          <span>{{ doc.name }} (ID:{{ doc.identifier || doc.id }})</span>
                        <el-icon class="remove-icon" @click="removeDoctorFromShift(doc, day.fullDate, shift)"><Close /></el-icon>
                           <!-- [新增] 冲突图标 -->
                           <el-icon v-if="hasDoctorConflicts(doc, day.fullDate, shift)" class="conflict-icon" 
                                    :class="getDoctorConflictIconClass(doc, day.fullDate, shift)">
                             <Warning />
                           </el-icon>
                      </div>
                      <div class="doctor-card-location" :class="{ 'is-set': doc.location }">
                        <el-icon><Location /></el-icon>
                        <span>{{ doc.location || '待分配地点' }}</span>
                        <!-- [新增] 清除地点按钮 -->
                        <el-icon v-if="doc.location" class="clear-location-icon" @click.stop="clearLocation(doc)"><CircleCloseFilled /></el-icon>
                      </div>
                    </div>
                  </div>
                </div>
              </td>
            </tr>
            </tbody>
          </table>
        </div>
        <div v-else class="placeholder">
          <el-empty description="请在左侧选择一个子科室以查看排班表" />
           </div>
        </div>
      </el-card>

      <!-- 底部拖拽区域 - 只在周视图下显示 -->
      <div v-if="currentView === 'week'" class="bottom-panels">
        <!-- 待排班医生列表 -->
        <el-card shadow="always" class="draggable-list-card">
          <template #header>
            <div class="card-header">
              <span>待排班医生 (拖拽到上方进行排班)</span>
            </div>
          </template>
          <div v-if="loadingDoctors" class="loading-container">
            <el-icon class="is-loading"><Loading /></el-icon>
            <span>加载医生数据中...</span>
          </div>
          <div v-else class="draggable-list">
            <div v-for="doc in availableDoctors" :key="doc.id"
                 class="doctor-card" draggable="true" @dragstart="onDragStart($event, { type: 'doctor', data: doc })">
              <img :src="doc.gender === 'male' ? doctorMaleImg : doctorFemaleImg" alt="医生头像" class="doctor-avatar">
              <div class="doctor-info">
                <span class="doctor-name">{{ doc.name }} (ID:{{ doc.identifier }})</span>
                <span v-if="doc.title" class="doctor-title">{{ doc.title }}</span>
              </div>
            </div>
            <el-empty v-if="!availableDoctors.length" description="该科室暂无医生" :image-size="60"/>
          </div>
        </el-card>

        <!-- 时间段卡片列表 -->
        <el-card shadow="always" class="draggable-list-card">
          <template #header>
            <div class="card-header">
              <span>时间段卡片 (拖拽到上方进行排班)</span>
            </div>
          </template>
          <div class="draggable-list time-slot-list">
            
            <div v-for="timeSlot in timeSlots" :key="timeSlot.slotId || timeSlot.slot_id"
                 class="time-slot-card" draggable="true" @dragstart="onDragStart($event, { type: 'timeSlot', data: timeSlot })">
              <el-icon :size="20" class="time-slot-icon"><Clock /></el-icon>
              <div class="time-slot-info">
                <span class="time-slot-name">{{ timeSlot.slotName || timeSlot.slot_name }}</span>
                <span class="time-slot-time">{{ (timeSlot.startTime || timeSlot.start_time) }} - {{ (timeSlot.endTime || timeSlot.end_time) }}</span>
              </div>
            </div>
            <el-empty v-if="!timeSlots.length" description="暂无时间段" :image-size="60"/>
          </div>
        </el-card>

        <!-- 可用办公地点列表 -->
        <el-card shadow="always" class="draggable-list-card">
          <template #header>
            <div class="card-header">
              <span>可用办公地点 (拖拽到医生卡片上分配)</span>
            </div>
          </template>
          <div class="draggable-list location-list">
            <div v-for="loc in availableLocations" :key="loc.location_id"
                 class="location-card" draggable="true" @dragstart="onDragStart($event, { type: 'location', data: loc })">
              <el-icon :size="20" class="location-icon"><OfficeBuilding /></el-icon>
              <div class="location-info">
                <span class="location-name">{{ loc.name }}</span>
                <span class="location-desc">{{ `${loc.building} - ${loc.floor}` }}</span>
              </div>
            </div>
            <el-empty v-if="!availableLocations.length" description="暂无可用地点" :image-size="60"/>
          </div>
        </el-card>
      </div>

    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch, nextTick } from 'vue';
// [新增] 导入 CircleCloseFilled 图标
import { ArrowLeft, ArrowRight, Close, Location, OfficeBuilding, CircleCloseFilled, Clock, Document, Download, UploadFilled, Upload, Refresh, CircleCheck, CircleClose, Warning, Loading } from '@element-plus/icons-vue';
// [新增] 导入 FullCalendar 组件和插件
import FullCalendar from '@fullcalendar/vue3';
import dayGridPlugin from '@fullcalendar/daygrid';
import timeGridPlugin from '@fullcalendar/timegrid';
import interactionPlugin from '@fullcalendar/interaction';
// [新增] 导入 Excel 解析库
import * as XLSX from 'xlsx';
import { ElMessage } from 'element-plus';
import doctorMaleImg from '@/assets/doctor.jpg';
import doctorFemaleImg from '@/assets/doctor1.jpg';
import BackButton from '@/components/BackButton.vue';
import { getTimeSlots } from '@/api/timeslot';
import { getAllParentDepartments, getDepartmentsByParentId, getDoctorsByDepartmentId } from '@/api/department';
import { getLocationNamesByDepartmentId } from '@/api/location';
import { createSchedule } from '@/api/schedule';

// --- 科室数据（从API获取） ---
const departments = ref([]);
const loadingDepartments = ref(false);

// --- 医生数据（从API获取） ---
const loadingDoctors = ref(false);

// --- 排班状态管理 ---
const scheduleStatus = ref({
  saving: false,
  lastSaved: null,
  error: null
});

const doctorsData = ref({
  's1-2': [
    {id: 1, name: '杨青松', identifier: 'D001', title: '主任医师', gender: 'male'},
    {id: 2, name: '杨林', identifier: 'D002', title: '副主任医师', gender: 'male'},
    {id: 3, name: '席紫明', identifier: 'D003', title: '主治医师', gender: 'female'}
  ],
  'p3': [ {id: 6, name: '王莉', identifier: 'D006', title: '主任医师', gender: 'female'} ],
});

const availableLocations = ref([
  { location_id: 101, name: '门诊楼-201诊室', building: '门诊楼', floor: '二层', room_number: '201' },
  { location_id: 102, name: '门诊楼-203诊室', building: '门诊楼', floor: '二层', room_number: '203' },
  { location_id: 103, name: '门诊楼-305诊室', building: '门诊楼', floor: '三层', room_number: '305' },
  { location_id: 201, name: '住院部A栋-101', building: '住院部A栋', floor: '一层', room_number: '101' },
]);

// 时间段数据 - 从API获取
const timeSlots = ref([]);


const scheduleData = ref({
  'p3': [
    { date: '2025-10-21', shift: '上午', doctors: [{id: 6, name: '王莉', location: null}] },
  ]
});

// 存储拖拽到时段列中的时间段卡片
const timeSlotColumns = ref({
  '上午': [],
  '下午': []
});

// --- 状态管理 ---
const currentMonday = ref(new Date('2025-10-20'));
const activeParent = ref(null);
const activeSub = ref(null);

// [新增] 视图切换状态
const currentView = ref('week'); // 'day', 'week', 'month'
const fullCalendar = ref(null);
const calendarEvents = ref([]);

// [新增] 批量导入相关状态
const uploadRef = ref(null);
const selectedFile = ref(null);
const importing = ref(false);
const importProgress = ref({
  show: false,
  current: 0,
  total: 0,
  percentage: 0,
  status: 'success',
  message: ''
});
const importResult = ref({
  show: false,
  type: 'success', // 'success' | 'error'
  title: '',
  message: '',
  details: []
});

// [新增] 冲突检测相关状态
const conflictData = ref({
  hasConflicts: false,
  conflicts: [],
  summary: {
    total: 0,
    critical: 0,
    warning: 0
  }
});

const subDepartments = computed(() => {
  if (!activeParent.value) return [];
  const parent = departments.value.find(p => p.id === activeParent.value);
  return parent ? parent.children : [];
});

// [新增] FullCalendar 配置
const calendarOptions = computed(() => ({
  plugins: [dayGridPlugin, timeGridPlugin, interactionPlugin],
  initialView: currentView.value === 'day' ? 'timeGridDay' : 
               currentView.value === 'week' ? 'timeGridWeek' : 'dayGridMonth',
  headerToolbar: {
    left: 'prev,next today',
    center: 'title',
    right: ''
  },
  locale: 'zh-cn',
  buttonText: {
    today: '今天',
    month: '月',
    week: '周',
    day: '日'
  },
  slotMinTime: '08:00:00',
  slotMaxTime: '18:00:00',
  allDaySlot: false,
  height: 'auto',
  events: calendarEvents.value,
  eventClick: handleEventClick,
  dateClick: handleDateClick,
  drop: handleCalendarDrop,
  eventDrop: handleEventDrop,
  eventResize: handleEventResize,
  editable: true,
  selectable: true,
  selectMirror: true,
  dayMaxEvents: true,
  weekends: true,
  slotDuration: '00:30:00',
  eventTimeFormat: {
    hour: '2-digit',
    minute: '2-digit',
    hour12: false
  },
  droppable: true,
  dropAccept: '.time-slot-card, .location-card'
}));

const selectedDepartmentName = computed(() => {
  if (!activeSub.value) return '请选择科室';
  const parentAsSub = departments.value.find(p => p.id === activeSub.value);
  if (parentAsSub) return parentAsSub.name;
  for (const parent of departments.value) {
    const sub = parent.children.find(c => c.id === activeSub.value);
    if (sub) return sub.name;
  }
  return '未知科室';
});

const selectedDepartmentCode = computed(() => {
  if (!activeSub.value) return 'N/A';
  const parentAsSub = departments.value.find(p => p.id === activeSub.value);
  if (parentAsSub) return parentAsSub.code || 'N/A';
  for (const parent of departments.value) {
    const sub = parent.children.find(c => c.id === activeSub.value);
    if (sub) return sub.code || 'N/A';
  }
  return 'N/A';
});

const availableDoctors = computed(() => {
  if (!activeSub.value) return [];
  // 从科室ID中提取数字ID（去掉前缀 's' 或 'p'）
  const departmentId = activeSub.value.replace(/^[sp]/, '');
  return doctorsData.value[departmentId] || [];
});

// --- 日期和排班表逻辑 ---
const weekDates = computed(() => {
  const days = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
  return Array.from({ length: 7 }).map((_, i) => {
    const date = new Date(currentMonday.value);
    date.setDate(date.getDate() + i);
    const year = date.getFullYear();
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    const day = date.getDate().toString().padStart(2, '0');
    return {
      date: `${month}.${day}`,
      dayOfWeek: days[i],
      fullDate: `${year}-${month}-${day}`
    }
  });
});

const changeWeek = (offset) => {
  if (offset === 0) {
    currentMonday.value = new Date('2025-10-20');
  } else {
    const newDate = new Date(currentMonday.value);
    newDate.setDate(newDate.getDate() + (offset * 7));
    currentMonday.value = newDate;
  }
  // 切换周次时清空时间段列
  clearTimeSlotColumns();
};

const getDoctorsForShift = (date, shift) => {
  if (!activeSub.value || !scheduleData.value[activeSub.value]) return [];
  const entry = scheduleData.value[activeSub.value].find(item => item.date === date && item.shift === shift);
  return entry ? entry.doctors : [];
};

// 获取指定时段的时间段卡片（只显示在时段列中）
const getTimeSlotsForShift = (shift) => {
  // 优先显示拖拽到时段列的时间段
  if (timeSlotColumns.value[shift] && timeSlotColumns.value[shift].length > 0) {
    return timeSlotColumns.value[shift];
  }
  
  // 如果没有拖拽的时间段，则从所有时间段中筛选出匹配的时段
  return timeSlots.value.filter(timeSlot => {
    const period = timeSlot.period || timeSlot.period;
    return period === shift;
  });
};

const getDoctorAvatar = (doctorId) => {
  for (const deptId in doctorsData.value) {
    const doctor = doctorsData.value[deptId].find(doc => doc.id === doctorId);
    if (doctor) {
      return doctor.gender === 'male' ? doctorMaleImg : doctorFemaleImg;
    }
  }
  return doctorMaleImg;
};

// --- 拖拽逻辑 ---
const onDragStart = (event, item, fromDate = null, fromShift = null) => {
  const dragData = {
    type: item.type, // 'doctor' or 'location'
    data: item.data,
    source: { date: fromDate, shift: fromShift }
  };
  event.dataTransfer.setData('application/json', JSON.stringify(dragData));
  event.dataTransfer.effectAllowed = 'move';
};

const onDrop = (event, toDate, toShift) => {
  event.preventDefault();
  const dragData = JSON.parse(event.dataTransfer.getData('application/json'));

  if (dragData.type === 'doctor') {
    handleDoctorDrop(dragData, toDate, toShift);
  } else if (dragData.type === 'location') {
    handleLocationDrop(dragData, toDate, toShift, event.target);
  } else if (dragData.type === 'timeSlot') {
    handleTimeSlotDrop(dragData, toDate, toShift);
  }
};

const handleDoctorDrop = async (dragData, toDate, toShift) => {
  const { data: doctor, source } = dragData;
  if (source.date && source.shift) {
    if (source.date === toDate && source.shift === toShift) return;
    removeDoctorFromShift(doctor, source.date, source.shift, false);
  }
  addDoctorToShift(doctor, toDate, toShift);
  
  // 保存排班到后端
  try {
    // 获取当前时段的时间段信息
    const timeSlotsForShift = getTimeSlotsForShift(toShift);
    const timeSlot = timeSlotsForShift.length > 0 ? timeSlotsForShift[0] : null;
    
    // 获取默认办公地点
    const location = availableLocations.value.length > 0 ? availableLocations.value[0] : null;
    
    if (timeSlot) {
      await saveScheduleToBackend(doctor, toDate, toShift, timeSlot, location);
    } else {
      console.warn('没有找到对应的时间段信息，无法保存排班');
    }
  } catch (error) {
    console.error('保存排班失败:', error);
    // 如果保存失败，可以选择是否回滚前端状态
    // removeDoctorFromShift(doctor, toDate, toShift);
  }
};

const handleLocationDrop = (dragData, toDate, toShift, targetElement) => {
  const { data: location } = dragData;

  const doctorCard = targetElement.closest('.doctor-card-in-table');
  if (!doctorCard) {
    ElMessage.warning('请将地点直接拖拽到医生的卡片上。');
    return;
  }

  const doctorsInShift = getDoctorsForShift(toDate, toShift);
  if (!doctorsInShift || doctorsInShift.length === 0) return;

  // [修改] 优化逻辑，先找到目标医生
  const targetDoctorId = parseInt(doctorCard.dataset.doctorId, 10);
  const targetDoctor = doctorsInShift.find(doc => doc.id === targetDoctorId);

  if (!targetDoctor) return;

  // [修改] 检查新地点是否已被该班次中的【其他】医生占用
  const isLocationTakenByAnotherDoctor = doctorsInShift.some(
      doc => doc.id !== targetDoctor.id && doc.location === location.name
  );

  if (isLocationTakenByAnotherDoctor) {
    ElMessage.error(`地点【${location.name}】在该班次已被其他医生占用，请选择其他地点。`);
    return;
  }

  const oldLocation = targetDoctor.location;
  targetDoctor.location = location.name; // 分配或更换地点

  if (oldLocation && oldLocation !== location.name) {
    ElMessage.success(`已将【${targetDoctor.name}】医生的地点从“${oldLocation}”更换为“${location.name}”`);
  } else if (!oldLocation) {
    ElMessage.success(`已为【${targetDoctor.name}】医生分配地点：${location.name}`);
  }
};

const handleTimeSlotDrop = (dragData, toDate, toShift) => {
  const { data: timeSlot } = dragData;
  
  // 如果拖拽到时段列（toDate为null），将时间段添加到时段列中
  if (toDate === null) {
    // 检查时间段是否已存在于该时段列中
    if (!timeSlotColumns.value[toShift].some(ts => ts.slot_id === timeSlot.slot_id)) {
      timeSlotColumns.value[toShift].push({ ...timeSlot });
      ElMessage.success(`已将时间段 "${timeSlot.slotName || timeSlot.slot_name}" 添加到 ${toShift} 时段列中`);
    } else {
      ElMessage.warning(`时间段 "${timeSlot.slotName || timeSlot.slot_name}" 已存在于 ${toShift} 时段列中`);
    }
    return;
  }
  
  // 如果拖拽到具体日期，则存储数据
  if (!activeSub.value) {
    console.log('No activeSub, returning');
    return;
  }
  
  if (!scheduleData.value[activeSub.value]) {
    scheduleData.value[activeSub.value] = [];
    console.log('Initialized scheduleData for:', activeSub.value);
  }

  let shiftEntry = scheduleData.value[activeSub.value].find(s => s.date === toDate && s.shift === toShift);
  if (!shiftEntry) {
    shiftEntry = { date: toDate, shift: toShift, doctors: [], timeSlots: [] };
    scheduleData.value[activeSub.value].push(shiftEntry);
    console.log('Created new shiftEntry:', shiftEntry);
  }

  // 检查时间段是否已存在
  if (!shiftEntry.timeSlots.some(ts => ts.slot_id === timeSlot.slot_id)) {
    shiftEntry.timeSlots.push({ ...timeSlot });
    console.log('Added timeSlot to shiftEntry:', shiftEntry.timeSlots);
    ElMessage.success(`已将时间段 "${timeSlot.slot_name}" 排班到 ${toDate} ${toShift}`);
  } else {
    ElMessage.warning(`时间段 "${timeSlot.slot_name}" 已在该班次中。`);
  }
};

// --- 数据操作方法 ---
const addDoctorToShift = (doctor, date, shift) => {
  if (!activeSub.value) return;
  if (!scheduleData.value[activeSub.value]) scheduleData.value[activeSub.value] = [];

  let shiftEntry = scheduleData.value[activeSub.value].find(s => s.date === date && s.shift === shift);
  if (!shiftEntry) {
    shiftEntry = { date, shift, doctors: [] };
    scheduleData.value[activeSub.value].push(shiftEntry);
  }

  if (!shiftEntry.doctors.some(d => d.id === doctor.id)) {
    shiftEntry.doctors.push({ ...doctor, location: null });
    ElMessage.success(`已将 ${doctor.name} 排班到 ${date} ${shift}`);
  } else {
    ElMessage.warning(`${doctor.name} 医生已在该班次中。`);
  }
};

const removeDoctorFromShift = (doctor, date, shift, showMessage = true) => {
  if (!activeSub.value || !scheduleData.value[activeSub.value]) return;
  const shiftEntry = scheduleData.value[activeSub.value].find(s => s.date === date && s.shift === shift);
  if (shiftEntry) {
    const docIndex = shiftEntry.doctors.findIndex(d => d.id === doctor.id);
    if (docIndex > -1) {
      shiftEntry.doctors.splice(docIndex, 1);
      if (showMessage) ElMessage.success(`已取消 ${doctor.name} 在 ${date} ${shift} 的排班`);
      
      console.log(`移除医生 ${doctor.name} 从 ${date} ${shift}`);
      
      // 移除医生后重新检测冲突
      setTimeout(() => {
        detectAllConflicts();
      }, 100);
    }
  }
};

// [新增] 清除医生地点的方法
const clearLocation = (doctor) => {
  const oldLocation = doctor.location;
  doctor.location = null;
  ElMessage.info(`已取消【${doctor.name}】医生的地点"${oldLocation}"`);
};

// 从时段列中移除时间段
const removeTimeSlotFromColumn = (timeSlot, shift) => {
  const timeSlotIndex = timeSlotColumns.value[shift].findIndex(ts => ts.slot_id === timeSlot.slot_id);
  if (timeSlotIndex > -1) {
    timeSlotColumns.value[shift].splice(timeSlotIndex, 1);
    ElMessage.success(`已从 ${shift} 时段列中移除时间段 "${timeSlot.slot_name}"`);
  }
};

// 清空时间段列的方法
const clearTimeSlotColumns = () => {
  timeSlotColumns.value = {
    '上午': [],
    '下午': []
  };
};

// --- 侧边栏选择逻辑 ---
const handleParentSelect = (index) => {
  console.log('选择父科室:', index);
  activeParent.value = index;
  const parent = departments.value.find(p => p.id === index);
  if (parent) {
    console.log('找到父科室:', parent);
    if (parent.children && parent.children.length > 0) {
      activeSub.value = parent.children[0].id;
      console.log('选择第一个子科室:', parent.children[0]);
    } else {
      activeSub.value = parent.id;
      console.log('父科室无子科室，选择父科室本身');
    }
  } else {
    activeSub.value = null;
    console.log('未找到父科室');
  }
  // 切换科室时清空时间段列
  clearTimeSlotColumns();
};

const handleSubSelect = (id) => {
  console.log('选择子科室:', id);
  activeSub.value = id;
  // 切换科室时清空时间段列
  clearTimeSlotColumns();
  
  // 加载选中科室的医生和办公地点数据
  if (id) {
    // 从科室ID中提取数字ID（去掉前缀 's' 或 'p'）
    const departmentId = id.replace(/^[sp]/, '');
    console.log('提取的科室数字ID:', departmentId);
    loadDoctorsForDepartment(departmentId);
    loadLocationsForDepartment(departmentId);
  }
};

// [新增] 视图切换函数
const changeView = (viewType) => {
  currentView.value = viewType;
  if (fullCalendar.value) {
    const calendarApi = fullCalendar.value.getApi();
    if (viewType === 'day') {
      calendarApi.changeView('timeGridDay');
    } else if (viewType === 'week') {
      calendarApi.changeView('timeGridWeek');
    } else if (viewType === 'month') {
      calendarApi.changeView('dayGridMonth');
    }
  }
};

// [新增] 日历事件处理函数
const handleEventClick = (info) => {
  const event = info.event;
  const conflicts = event.extendedProps.conflicts;
  
  let message = `医生: ${event.title}\n时间: ${event.startStr} - ${event.endStr}\n地点: ${event.extendedProps.location || '未分配'}`;
  
  if (conflicts?.hasConflict) {
    message += `\n\n⚠️ 冲突警告: ${conflicts.conflictDetails}`;
    if (conflicts.severity === 'error') {
      ElMessage.error(message);
    } else {
      ElMessage.warning(message);
    }
  } else {
    ElMessage.info(message);
  }
};

const handleDateClick = (info) => {
  console.log('点击日期:', info.dateStr);
};

// [新增] 日历拖拽事件处理
const handleCalendarDrop = (info) => {
  const { date, allDay, resource } = info;
  
  // 尝试从不同位置获取拖拽数据
  let dragData = info.draggedEl.dragData || 
                 info.draggedEl.__vueParentComponent?.ctx?.dragData || 
                 info.draggedEl.__vueParentComponent?.setupState?.dragData;
  
  // 如果没有找到，尝试从全局拖拽状态获取
  if (!dragData && window.currentDragData) {
    dragData = window.currentDragData;
  }
  
  if (!dragData) {
    console.log('未找到拖拽数据');
    return;
  }
  
  const { type, data } = dragData;
  const dropDate = date.toISOString().split('T')[0];
  
  if (type === 'timeSlot') {
    // 拖拽时间段到日历
    handleTimeSlotDropToCalendar(data, dropDate, date);
  } else if (type === 'location') {
    // 拖拽地点到日历（这里可以显示提示）
    ElMessage.info('请将地点拖拽到医生卡片上');
  }
};

// [新增] 处理时间段拖拽到日历
const handleTimeSlotDropToCalendar = (timeSlot, date, dropDateTime) => {
  // 根据拖拽时间确定班次
  const hour = dropDateTime.getHours();
  const shift = hour < 12 ? '上午' : '下午';
  
  // 添加到时间段列
  if (!timeSlotColumns.value[shift].find(slot => slot.slot_id === timeSlot.slot_id)) {
    timeSlotColumns.value[shift].push(timeSlot);
  }
  
  ElMessage.success(`已将 ${timeSlot.slot_name} 添加到 ${shift} 时间段`);
};

// [新增] 处理日历事件拖拽
const handleEventDrop = (info) => {
  const event = info.event;
  const newStart = event.start;
  const newDate = newStart.toISOString().split('T')[0];
  
  // 更新排班数据中的日期
  updateScheduleDate(event.id, newDate);
  
  ElMessage.success('排班已更新');
};

// [新增] 处理日历事件调整大小
const handleEventResize = (info) => {
  const event = info.event;
  ElMessage.success('排班时间已调整');
};

// [新增] 更新排班日期
const updateScheduleDate = (eventId, newDate) => {
  if (!activeSub.value) return;
  
  // 解析事件ID获取原始信息
  const [originalDate, shift, doctorId] = eventId.split('-');
  
  // 找到原始排班记录
  const originalSchedule = scheduleData.value[activeSub.value].find(
    s => s.date === originalDate && s.shift === shift
  );
  
  if (originalSchedule) {
    // 移除原始记录中的医生
    const doctorIndex = originalSchedule.doctors.findIndex(d => d.id === doctorId);
    if (doctorIndex > -1) {
      const doctor = originalSchedule.doctors[doctorIndex];
      originalSchedule.doctors.splice(doctorIndex, 1);
      
      // 添加到新日期的排班
      addDoctorToSchedule(newDate, shift, doctor);
    }
  }
};

// [新增] 添加医生到排班
const addDoctorToSchedule = (date, shift, doctor) => {
  if (!activeSub.value) return;
  
  // 确保排班数据结构存在
  if (!scheduleData.value[activeSub.value]) {
    scheduleData.value[activeSub.value] = [];
  }
  
  // 查找或创建当天的排班记录
  let daySchedule = scheduleData.value[activeSub.value].find(s => s.date === date && s.shift === shift);
  if (!daySchedule) {
    daySchedule = { date, shift, doctors: [] };
    scheduleData.value[activeSub.value].push(daySchedule);
  }
  
  // 添加医生（如果不存在）
  if (!daySchedule.doctors.find(d => d.id === doctor.id)) {
    daySchedule.doctors.push({ ...doctor });
  }
};

// [新增] 批量导入功能函数
// 下载模板文件
const downloadTemplate = () => {
  const templateData = [
    ['日期', '班次', '医生姓名', '医生职称', '办公地点', '时间段1', '时间段2', '时间段3', '时间段4'],
    ['2025/10/20', '上午', '张三', '主治医师', '门诊楼-201诊室', '08:00-08:30', '08:30-09:00', '09:00-09:30', '09:30-10:00'],
    ['2025/10/20', '下午', '李四', '副主任医师', '门诊楼-203诊室', '14:00-14:30', '14:30-15:00', '15:00-15:30', '15:30-16:00'],
    ['', '', '', '', '', '', '', '', ''],
    ['说明：', '', '', '', '', '', '', '', ''],
    ['1. 日期格式：YYYY/MM/DD 或 YYYY-MM-DD', '', '', '', '', '', '', '', ''],
    ['2. 班次：上午/下午', '', '', '', '', '', '', '', ''],
    ['3. 时间段格式：HH:MM-HH:MM', '', '', '', '', '', '', '', ''],
    ['4. 办公地点请从可用地点中选择', '', '', '', '', '', '', '', '']
  ];
  
  // 创建工作簿
  const workbook = XLSX.utils.book_new();
  const worksheet = XLSX.utils.aoa_to_sheet(templateData);
  
  // 设置列宽
  worksheet['!cols'] = [
    { wch: 12 }, // 日期
    { wch: 8 },  // 班次
    { wch: 12 }, // 医生姓名
    { wch: 12 }, // 医生职称
    { wch: 20 }, // 办公地点
    { wch: 12 }, // 时间段1
    { wch: 12 }, // 时间段2
    { wch: 12 }, // 时间段3
    { wch: 12 }  // 时间段4
  ];
  
  // 添加工作表到工作簿
  XLSX.utils.book_append_sheet(workbook, worksheet, '排班模板');
  
  // 生成Excel文件并下载
  XLSX.writeFile(workbook, '排班导入模板.xlsx');
  
  ElMessage.success('Excel模板文件下载成功');
};

// 文件大小格式化
const formatFileSize = (bytes) => {
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
};

// 文件选择处理
const handleFileChange = (file) => {
  selectedFile.value = file.raw || file;
  importResult.value.show = false;
};

// 上传前验证
const beforeUpload = (file) => {
  const isValidType = ['application/vnd.ms-excel', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', 'text/csv'].includes(file.type);
  const isLt10M = file.size / 1024 / 1024 < 10;

  if (!isValidType) {
    ElMessage.error('只能上传 Excel 或 CSV 文件!');
    return false;
  }
  if (!isLt10M) {
    ElMessage.error('文件大小不能超过 10MB!');
    return false;
  }
  return true;
};

// 移除文件
const removeFile = () => {
  selectedFile.value = null;
  if (uploadRef.value) {
    uploadRef.value.clearFiles();
  }
  importResult.value.show = false;
  importProgress.value.show = false;
};

// Excel文件解析函数
const parseExcelFile = (file) => {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = (e) => {
      try {
        const data = new Uint8Array(e.target.result);
        const workbook = XLSX.read(data, { type: 'array' });
        
        console.log('Excel工作表:', workbook.SheetNames);
        
        // 获取第一个工作表
        const sheetName = workbook.SheetNames[0];
        const worksheet = workbook.Sheets[sheetName];
        
        // 将工作表转换为JSON数组
        const jsonData = XLSX.utils.sheet_to_json(worksheet, { header: 1 });
        
        console.log('Excel原始数据:', jsonData);
        
        // 转换为标准格式
        const result = [];
        for (let i = 0; i < jsonData.length; i++) {
          const row = jsonData[i];
          if (row && row.length >= 3 && row[0] && row[1] && row[2]) {
            // 过滤掉说明行
            if (typeof row[0] === 'string' && 
                !row[0].startsWith('说明') && 
                !row[0].startsWith('1.') && 
                !row[0].startsWith('2.') && 
                !row[0].startsWith('3.') && 
                !row[0].startsWith('4.')) {
              result.push(row);
            }
          }
        }
        
        console.log('处理后的数据:', result);
        resolve(result);
      } catch (error) {
        console.error('Excel解析错误:', error);
        reject(error);
      }
    };
    reader.onerror = reject;
    reader.readAsArrayBuffer(file);
  });
};

// 处理导入
const handleImport = async () => {
  if (!selectedFile.value) {
    ElMessage.warning('请先选择文件');
    return;
  }

  importing.value = true;
  importProgress.value = {
    show: true,
    current: 0,
    total: 0,
    percentage: 0,
    status: 'success',
    message: '开始解析文件...'
  };

  try {
    // 解析文件
    const data = await parseExcelFile(selectedFile.value);
    
    // 添加调试信息
    console.log('解析的数据:', data);
    
    if (data.length === 0) {
      throw new Error('文件中没有有效的排班数据');
    }

    importProgress.value.total = data.length;
    importProgress.value.message = `开始导入 ${data.length} 条排班记录...`;

    let successCount = 0;
    let errorCount = 0;
    const errors = [];

    // 模拟导入过程
    for (let i = 0; i < data.length; i++) {
      const row = data[i];
      importProgress.value.current = i + 1;
      importProgress.value.percentage = Math.round(((i + 1) / data.length) * 100);
      importProgress.value.message = `正在导入第 ${i + 1} 条记录...`;

      try {
        await importScheduleRow(row);
        successCount++;
      } catch (error) {
        errors.push(`第${i + 1}行: ${error.message}`);
        errorCount++;
      }

      // 模拟处理时间
      await new Promise(resolve => setTimeout(resolve, 100));
    }

    // 显示导入结果
    if (errors.length === 0) {
      importResult.value = {
        show: true,
        type: 'success',
        title: '导入成功',
        message: `成功导入 ${successCount} 条排班记录`,
        details: []
      };
      ElMessage.success('排班信息导入成功！');
    } else {
      importResult.value = {
        show: true,
        type: 'error',
        title: '导入完成（有错误）',
        message: `成功导入 ${successCount} 条，失败 ${errorCount} 条`,
        details: errors
      };
      ElMessage.warning(`导入完成，但有 ${errorCount} 条记录失败`);
    }
    
    // [新增] 导入完成后立即进行冲突检测
    setTimeout(() => {
      detectAllConflicts();
      if (conflictData.value.hasConflicts) {
        ElMessage.warning(
          `检测到 ${conflictData.value.summary.total} 个排班冲突，` +
          `其中严重冲突 ${conflictData.value.summary.critical} 个，` +
          `警告 ${conflictData.value.summary.warning} 个。请检查红色/黄色高亮的排班。`
        );
      }
    }, 500);

  } catch (error) {
    importResult.value = {
      show: true,
      type: 'error',
      title: '导入失败',
      message: error.message,
      details: []
    };
    ElMessage.error('导入失败：' + error.message);
  } finally {
    importing.value = false;
    importProgress.value.show = false;
  }
};

// 导入单行排班数据
const importScheduleRow = async (row) => {
  let [date, shift, doctorName, doctorTitle, location, ...timeSlots] = row;
  
  // 添加调试信息
  console.log('处理行数据:', row);
  console.log('解析后的字段:', { date, shift, doctorName, doctorTitle, location });
  
  // 验证必要字段
  if (!date || !shift || !doctorName) {
    throw new Error('日期、班次、医生姓名不能为空');
  }

  // 处理日期格式 - 支持多种格式
  console.log('原始日期:', date);
  
  // 移除可能的空白字符和特殊字符
  date = date.toString().trim().replace(/[\s\u00A0]/g, '');
  
  // 处理各种日期格式
  if (date.includes('/')) {
    // 处理 YYYY/MM/DD 格式
    const dateParts = date.split('/');
    if (dateParts.length === 3) {
      const year = dateParts[0];
      const month = dateParts[1].padStart(2, '0');
      const day = dateParts[2].padStart(2, '0');
      date = `${year}-${month}-${day}`;
    }
  } else if (date.includes('-')) {
    // 处理 YYYY-MM-DD 格式
    const dateParts = date.split('-');
    if (dateParts.length === 3) {
      const year = dateParts[0];
      const month = dateParts[1].padStart(2, '0');
      const day = dateParts[2].padStart(2, '0');
      date = `${year}-${month}-${day}`;
    }
  } else if (date.length === 8 && /^\d{8}$/.test(date)) {
    // 处理 YYYYMMDD 格式
    const year = date.substring(0, 4);
    const month = date.substring(4, 6);
    const day = date.substring(6, 8);
    date = `${year}-${month}-${day}`;
  }
  
  console.log('处理后的日期:', date);
  
  // 验证日期格式
  const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
  if (!dateRegex.test(date)) {
    console.error('日期验证失败:', date);
    throw new Error(`日期格式不正确: "${date}"，应为 YYYY-MM-DD 或 YYYY/MM/DD`);
  }

  // 验证班次
  if (!['上午', '下午'].includes(shift)) {
    throw new Error('班次只能是"上午"或"下午"');
  }

  // [新增] 检查是否存在冲突 - 防止同一医生同一时间在多个地点
  if (activeSub.value && scheduleData.value[activeSub.value]) {
    const existingSchedule = scheduleData.value[activeSub.value].find(
      s => s.date === date && s.shift === shift
    );
    
    if (existingSchedule) {
      // 检查是否已经有同名医生在这个时间段
      const duplicateDoctor = existingSchedule.doctors.find(d => d.name === doctorName);
      if (duplicateDoctor) {
        // 检查办公地点是否不同
        if (duplicateDoctor.location && location && duplicateDoctor.location !== location) {
          throw new Error(
            `医生 ${doctorName} 在 ${date} ${shift} 已被分配到 ${duplicateDoctor.location}，` +
            `不能再分配到 ${location}。同一医生不能同时在两个地方。`
          );
        } else if (duplicateDoctor.location && location && duplicateDoctor.location === location) {
          // 如果是同一地点，跳过（避免重复导入）
          console.log(`医生 ${doctorName} 在 ${date} ${shift} 已在 ${location}，跳过重复导入`);
          return;
        }
      }
      
      // 检查办公室是否已被其他医生占用（同一天同一办公室）
      if (location) {
        // 检查当天所有班次的所有医生
        const allSchedulesOnDate = scheduleData.value[activeSub.value].filter(s => s.date === date);
        for (const schedule of allSchedulesOnDate) {
          const doctorInSameOffice = schedule.doctors.find(
            d => d.location === location && d.name !== doctorName
          );
          if (doctorInSameOffice) {
            throw new Error(
              `办公室 ${location} 在 ${date} 已被医生 ${doctorInSameOffice.name} 占用，` +
              `不能再分配给医生 ${doctorName}。每个办公室每天只能分配给一个医生。`
            );
          }
        }
      }
    }
  }

  // 创建或获取医生
  const doctor = {
    id: `import_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
    identifier: `IMP${Date.now().toString().slice(-6)}`, // 生成导入医生的工号
    name: doctorName,
    title: doctorTitle || '医生',
    location: location || null,
    gender: 'male' // 默认性别，实际项目中可以从数据中获取
  };

  // 添加到排班数据
  addDoctorToSchedule(date, shift, doctor);

  // 添加时间段
  const validTimeSlots = timeSlots.filter(slot => slot && slot.toString().includes('-'));
  for (const timeSlot of validTimeSlots) {
    const timeSlotStr = timeSlot.toString();
    const [startTime, endTime] = timeSlotStr.split('-');
    const slotData = {
      slot_id: `import_slot_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      slot_name: `${shift}${startTime}-${endTime}`,
      start_time: startTime,
      end_time: endTime
    };

    // 添加到时间段列
    if (!timeSlotColumns.value[shift].find(slot => slot.slot_name === slotData.slot_name)) {
      timeSlotColumns.value[shift].push(slotData);
    }
  }
};

// 清空导入数据
const clearImportData = () => {
  selectedFile.value = null;
  importResult.value.show = false;
  importProgress.value.show = false;
  if (uploadRef.value) {
    uploadRef.value.clearFiles();
  }
  ElMessage.info('已清空导入数据');
};

// [新增] 将排班数据转换为日历事件
const convertScheduleToEvents = () => {
  const events = [];
  
  if (!activeSub.value || !scheduleData.value[activeSub.value]) {
    calendarEvents.value = [];
    return;
  }

  const schedules = scheduleData.value[activeSub.value];
  
  schedules.forEach(schedule => {
    const { date, shift, doctors } = schedule;
    
    // 确定时间段
    const startTime = shift === '上午' ? '08:00:00' : '14:00:00';
    const endTime = shift === '上午' ? '12:00:00' : '18:00:00';
    
    // 为每个医生创建事件
    doctors.forEach((doctor, index) => {
      // 如果有多个医生，稍微错开时间显示
      const offsetMinutes = index * 5;
      const start = new Date(`${date}T${startTime}`);
      start.setMinutes(start.getMinutes() + offsetMinutes);
      
      const end = new Date(`${date}T${endTime}`);
      end.setMinutes(end.getMinutes() + offsetMinutes);
      
      // 根据冲突状态设置颜色
      let backgroundColor = shift === '上午' ? '#67C23A' : '#409EFF';
      let borderColor = shift === '上午' ? '#529b2e' : '#337ecc';
      let className = '';
      
      // 检查该医生在这个日期和班次是否有冲突
      const hasConflict = hasDoctorConflicts(doctor, date, shift);
      if (hasConflict) {
        const conflictClass = getDoctorConflictClass(doctor, date, shift);
        if (conflictClass === 'conflict-error') {
          backgroundColor = '#F56C6C';
          borderColor = '#F56C6C';
          className = 'conflict-critical';
        } else if (conflictClass === 'conflict-warning') {
          backgroundColor = '#E6A23C';
          borderColor = '#E6A23C';
          className = 'conflict-warning';
        }
      }
      
      events.push({
        id: `${date}-${shift}-${doctor.id}`,
        title: `${doctor.name} (ID:${doctor.identifier || doctor.id})`,
        start: start.toISOString(),
        end: end.toISOString(),
        backgroundColor,
        borderColor,
        className,
        extendedProps: {
          doctorId: doctor.id,
          doctorTitle: doctor.title || '医生',
          location: doctor.location,
          shift: shift,
          departmentId: activeSub.value,
          hasConflict: hasConflict
        }
      });
    });
  });
  
  calendarEvents.value = events;
};

// [新增] 完整的冲突检测系统
const detectAllConflicts = () => {
  if (!activeSub.value || !scheduleData.value[activeSub.value]) {
    conflictData.value = {
      hasConflicts: false,
      conflicts: [],
      summary: { total: 0, critical: 0, warning: 0 }
    };
    return;
  }

  // 创建深拷贝，避免修改原始响应式数据
  const schedules = JSON.parse(JSON.stringify(scheduleData.value[activeSub.value]));
  const conflicts = [];
  
  console.log('开始冲突检测，排班数据:', schedules);
  
  // 1. 检测医生重复排班冲突（同一医生同一时间段多次排班）
  const doctorConflicts = detectDoctorDoubleBooking(schedules);
  console.log('医生重复排班冲突:', doctorConflicts);
  conflicts.push(...doctorConflicts);
  
  // 2. 检测办公室冲突（同一办公室同一时间段被多个医生占用）
  const officeConflicts = detectOfficeConflicts(schedules);
  console.log('办公室冲突:', officeConflicts);
  conflicts.push(...officeConflicts);
  
  // 3. 检测医生跨办公室冲突（同一医生同一时间段在不同办公室）
  conflicts.push(...detectDoctorMultiOfficeConflicts(schedules));
  
  // 4. 检测工作时间冲突（医生连续工作时间过长）
  conflicts.push(...detectWorkDurationConflicts(schedules));
  
  // 5. 检测医生休息时间冲突（医生没有足够的休息时间）
  conflicts.push(...detectRestTimeConflicts(schedules));
  
  // 6. 检测时间段重叠冲突
  conflicts.push(...detectTimeSlotOverlapConflicts(schedules));

  console.log('所有冲突:', conflicts);

  // 更新冲突数据
  conflictData.value = {
    hasConflicts: conflicts.length > 0,
    conflicts: conflicts,
    summary: {
      total: conflicts.length,
      critical: conflicts.filter(c => c.severity === 'critical').length,
      warning: conflicts.filter(c => c.severity === 'warning').length
    }
  };
};

// [新增] 检测医生重复排班冲突
const detectDoctorDoubleBooking = (schedules) => {
  const conflicts = [];
  const doctorScheduleMap = new Map();
  
  schedules.forEach(schedule => {
    const { date, shift, doctors } = schedule;
    const timeKey = `${date}-${shift}`;
    
    doctors.forEach(doctor => {
      const doctorKey = `${doctor.id}-${timeKey}`;
      
      if (doctorScheduleMap.has(doctorKey)) {
        const existingSchedule = doctorScheduleMap.get(doctorKey);
        conflicts.push({
          type: 'doctor_double_booking',
          severity: 'critical',
          title: '医生重复排班',
          description: `医生 ${doctor.name} 在 ${date} ${shift} 被重复排班`,
          details: [
            `医生: ${doctor.name}`,
            `时间: ${date} ${shift}`,
            `地点1: ${existingSchedule.location || '未分配'}`,
            `地点2: ${doctor.location || '未分配'}`
          ],
          doctorId: doctor.id,
          date: date,
          shift: shift
        });
      } else {
        doctorScheduleMap.set(doctorKey, { ...doctor, date, shift });
      }
    });
  });
  
  return conflicts;
};

// [新增] 检测办公室冲突 - 修改为同一日期同一办公室被多人使用即为冲突
const detectOfficeConflicts = (schedules) => {
  const conflicts = [];
  const officeDateMap = new Map(); // 改为按日期和办公室分组
  
  console.log('开始检测办公室冲突，排班数据:', schedules);
  
  schedules.forEach(schedule => {
    const { date, shift, doctors } = schedule;
    
    console.log(`检查 ${date} ${shift} 的医生:`, doctors);
    
    doctors.forEach(doctor => {
      if (doctor.location) {
        // 改为按日期和办公室分组，不区分时间段
        const officeDateKey = `${doctor.location}-${date}`;
        
        console.log(`检查医生 ${doctor.name} 在办公室 ${doctor.location} 日期 ${date}`);
        
        if (officeDateMap.has(officeDateKey)) {
          const existingDoctors = officeDateMap.get(officeDateKey);
          
          // 检查是否已经记录了这个医生
          const alreadyRecorded = existingDoctors.some(existing => existing.id === doctor.id);
          
          if (!alreadyRecorded) {
            existingDoctors.push({ ...doctor, date, shift });
            console.log(`发现办公室冲突: ${doctor.location} 在 ${date} 被多个医生使用`);
            
            // 为所有使用这个办公室的医生创建冲突记录
            existingDoctors.forEach(existingDoctor => {
              conflicts.push({
                type: 'office_conflict',
                severity: 'critical',
                title: '办公室冲突',
                description: `办公室 ${doctor.location} 在 ${date} 被多个医生使用`,
                details: [
                  `办公室: ${doctor.location}`,
                  `日期: ${date}`,
                  `使用医生: ${existingDoctors.map(d => d.name).join(', ')}`,
                  `建议: 每个办公室每天只能分配给一个医生`
                ],
                location: doctor.location,
                date: date,
                shift: shift,
                doctorIds: existingDoctors.map(d => d.id),
                allDoctors: existingDoctors
              });
            });
          }
        } else {
          officeDateMap.set(officeDateKey, [{ ...doctor, date, shift }]);
          console.log(`记录医生 ${doctor.name} 在办公室 ${doctor.location}`);
        }
      }
    });
  });
  
  console.log('办公室冲突检测完成，发现冲突:', conflicts);
  return conflicts;
};

// [新增] 检测医生跨办公室冲突
const detectDoctorMultiOfficeConflicts = (schedules) => {
  const conflicts = [];
  const doctorOfficeMap = new Map();
  
  schedules.forEach(schedule => {
    const { date, shift, doctors } = schedule;
    const timeKey = `${date}-${shift}`;
    
    doctors.forEach(doctor => {
      if (doctor.location) {
        const doctorKey = `${doctor.id}-${timeKey}`;
        
        if (doctorOfficeMap.has(doctorKey)) {
          const existingLocation = doctorOfficeMap.get(doctorKey);
          conflicts.push({
            type: 'doctor_multi_office',
            severity: 'critical',
            title: '医生跨办公室冲突',
            description: `医生 ${doctor.name} 在 ${date} ${shift} 被分配到多个办公室`,
            details: [
              `医生: ${doctor.name}`,
              `时间: ${date} ${shift}`,
              `办公室1: ${existingLocation}`,
              `办公室2: ${doctor.location}`
            ],
            doctorId: doctor.id,
            date: date,
            shift: shift,
            locations: [existingLocation, doctor.location]
          });
        } else {
          doctorOfficeMap.set(doctorKey, doctor.location);
        }
      }
    });
  });
  
  return conflicts;
};

// [新增] 检测工作时间冲突（连续工作时间过长）
const detectWorkDurationConflicts = (schedules) => {
  const conflicts = [];
  const doctorWorkMap = new Map();
  
  // 收集每个医生的工作安排
  schedules.forEach(schedule => {
    const { date, shift, doctors } = schedule;
    doctors.forEach(doctor => {
      if (!doctorWorkMap.has(doctor.id)) {
        doctorWorkMap.set(doctor.id, []);
      }
      doctorWorkMap.get(doctor.id).push({ date, shift, doctor });
    });
  });
  
  // 检查每个医生的工作安排
  doctorWorkMap.forEach((workList, doctorId) => {
    // 按日期排序
    workList.sort((a, b) => new Date(a.date) - new Date(b.date));
    
    // 检查连续工作天数
    let consecutiveDays = 1;
    let maxConsecutiveDays = 1;
    
    for (let i = 1; i < workList.length; i++) {
      const prevDate = new Date(workList[i-1].date);
      const currDate = new Date(workList[i].date);
      const dayDiff = (currDate - prevDate) / (1000 * 60 * 60 * 24);
      
      if (dayDiff === 1) {
        consecutiveDays++;
        maxConsecutiveDays = Math.max(maxConsecutiveDays, consecutiveDays);
      } else {
        consecutiveDays = 1;
      }
    }
    
    // 如果连续工作超过7天，标记为冲突
    if (maxConsecutiveDays > 7) {
      conflicts.push({
        type: 'work_duration_conflict',
        severity: 'warning',
        title: '工作时间冲突',
        description: `医生 ${workList[0].doctor.name} 连续工作 ${maxConsecutiveDays} 天，建议休息`,
        details: [
          `医生: ${workList[0].doctor.name}`,
          `连续工作天数: ${maxConsecutiveDays} 天`,
          `建议: 连续工作不应超过7天，请安排休息时间`
        ],
        doctorId: doctorId,
        consecutiveDays: maxConsecutiveDays
      });
    }
  });
  
  return conflicts;
};

// [新增] 检测休息时间冲突
const detectRestTimeConflicts = (schedules) => {
  const conflicts = [];
  return conflicts; // 暂时简化实现
};

// [新增] 检测时间段重叠冲突
const detectTimeSlotOverlapConflicts = (schedules) => {
  const conflicts = [];
  return conflicts; // 暂时简化实现
};

// [新增] 获取医生冲突样式类 - 修改为持久检查，显示所有冲突
const getDoctorConflictClass = (doctor, date, shift) => {
  const relevantConflicts = conflictData.value.conflicts.filter(conflict => {
    switch (conflict.type) {
      case 'doctor_double_booking':
      case 'doctor_multi_office':
        // 特定日期和班次的冲突
        return conflict.doctorId === doctor.id && 
               conflict.date === date && 
               conflict.shift === shift;
      case 'office_conflict':
        // 办公室冲突：只要日期匹配且医生在冲突列表中即可
        return conflict.date === date && 
               conflict.doctorIds && conflict.doctorIds.includes(doctor.id);
      case 'work_duration_conflict':
      case 'rest_time_conflict':
      case 'time_slot_overlap':
        // 全局性冲突：影响该医生的所有排班
        return conflict.doctorId === doctor.id || 
               (conflict.doctorIds && conflict.doctorIds.includes(doctor.id));
      default:
        return false;
    }
  });

  if (relevantConflicts.length > 0) {
    const hasCritical = relevantConflicts.some(c => c.severity === 'critical');
    return hasCritical ? 'conflict-error' : 'conflict-warning';
  }
  return '';
};

// [新增] 检查医生是否有冲突 - 修改为持久检查，显示所有冲突
const hasDoctorConflicts = (doctor, date, shift) => {
  const hasConflict = conflictData.value.conflicts.some(conflict => {
    switch (conflict.type) {
      case 'doctor_double_booking':
      case 'doctor_multi_office':
        // 特定日期和班次的冲突
        return conflict.doctorId === doctor.id && 
               conflict.date === date && 
               conflict.shift === shift;
      case 'office_conflict':
        // 办公室冲突：只要日期匹配且医生在冲突列表中即可
        return conflict.date === date && 
               conflict.doctorIds && conflict.doctorIds.includes(doctor.id);
      case 'work_duration_conflict':
      case 'rest_time_conflict':
      case 'time_slot_overlap':
        // 全局性冲突：影响该医生的所有排班，全部显示冲突图标
        return conflict.doctorId === doctor.id || 
               (conflict.doctorIds && conflict.doctorIds.includes(doctor.id));
      default:
        return false;
    }
  });
  
  return hasConflict;
};

// [新增] 检查时间段卡片是否匹配班次
const isTimeSlotMatchShift = (timeSlot, shift) => {
  if (!timeSlot) return true;
  
  // 获取时间段名称，支持多种字段名
  const slotName = (timeSlot.slotName || timeSlot.slot_name || '').toLowerCase();
  const shiftLower = shift.toLowerCase();
  
  // 如果时间段名称为空，默认允许
  if (!slotName) return true;
  
  // 检查时间段名称是否包含班次信息
  if (slotName.includes('上午') && shiftLower === '下午') {
    return false;
  }
  if (slotName.includes('下午') && shiftLower === '上午') {
    return false;
  }
  
  // 检查时间段名称是否包含"am"或"pm"标识
  if (slotName.includes('am') && shiftLower === '下午') {
    return false;
  }
  if (slotName.includes('pm') && shiftLower === '上午') {
    return false;
  }
  
  // 检查时间段名称是否包含"morning"或"afternoon"标识
  if (slotName.includes('morning') && shiftLower === '下午') {
    return false;
  }
  if (slotName.includes('afternoon') && shiftLower === '上午') {
    return false;
  }
  
  return true; // 默认允许，对于没有明确班次标识的时间段
};

// [新增] 获取医生冲突图标样式类
const getDoctorConflictIconClass = (doctor, date, shift) => {
  const relevantConflicts = conflictData.value.conflicts.filter(conflict => {
    switch (conflict.type) {
      case 'doctor_double_booking':
      case 'doctor_multi_office':
        // 特定日期和班次的冲突
        return conflict.doctorId === doctor.id && 
               conflict.date === date && 
               conflict.shift === shift;
      case 'office_conflict':
        // 办公室冲突：只要日期匹配且医生在冲突列表中即可
        return conflict.date === date && 
               conflict.doctorIds && conflict.doctorIds.includes(doctor.id);
      case 'work_duration_conflict':
      case 'rest_time_conflict':
      case 'time_slot_overlap':
        // 全局性冲突：影响该医生的所有排班
        return conflict.doctorId === doctor.id || 
               (conflict.doctorIds && conflict.doctorIds.includes(doctor.id));
      default:
        return false;
    }
  });

  if (relevantConflicts.length > 0) {
    const hasCritical = relevantConflicts.some(c => c.severity === 'critical');
    return hasCritical ? 'conflict-error-icon' : 'conflict-warning-icon';
  }
  return '';
};

// [新增] 显示冲突详情
const showConflictDetails = (doctor, date, shift) => {
  const relevantConflicts = conflictData.value.conflicts.filter(conflict => {
    switch (conflict.type) {
      case 'doctor_double_booking':
      case 'doctor_multi_office':
        // 特定日期和班次的冲突
        return conflict.doctorId === doctor.id && 
               conflict.date === date && 
               conflict.shift === shift;
      case 'office_conflict':
        // 办公室冲突：只要日期匹配且医生在冲突列表中即可
        return conflict.date === date && 
               conflict.doctorIds && conflict.doctorIds.includes(doctor.id);
      case 'work_duration_conflict':
      case 'rest_time_conflict':
      case 'time_slot_overlap':
        // 全局性冲突：影响该医生的所有排班
        return conflict.doctorId === doctor.id || 
               (conflict.doctorIds && conflict.doctorIds.includes(doctor.id));
      default:
        return false;
    }
  });

  if (relevantConflicts.length > 0) {
    const conflictTypes = relevantConflicts.map(c => c.title).join('、');
    const severity = relevantConflicts.some(c => c.severity === 'critical') ? 'critical' : 'warning';
    
    let message = `医生: ${doctor.name} (工号:${doctor.identifier || doctor.id})\n冲突类型: ${conflictTypes}\n\n详细信息:\n`;
    relevantConflicts.forEach(conflict => {
      message += `• ${conflict.description}\n`;
      if (conflict.details && conflict.details.length > 0) {
        conflict.details.forEach(detail => {
          message += `  - ${detail}\n`;
        });
      }
    });
    
    if (severity === 'critical') {
      ElMessage.error(message);
    } else {
      ElMessage.warning(message);
    }
  }
};

// [新增] 调试冲突函数
const debugConflicts = () => {
  console.log('=== 调试冲突信息 ===');
  console.log('当前选中的科室:', activeSub.value);
  console.log('排班数据:', scheduleData.value);
  console.log('冲突数据:', conflictData.value);
  
  if (activeSub.value && scheduleData.value[activeSub.value]) {
    const schedules = scheduleData.value[activeSub.value];
    console.log('当前科室的排班:', schedules);
    
    // 检查每个排班
    schedules.forEach((schedule, index) => {
      console.log(`排班 ${index}:`, schedule);
      if (schedule.doctors) {
        schedule.doctors.forEach((doctor, docIndex) => {
          console.log(`  医生 ${docIndex}:`, doctor);
        });
      }
    });
  }
  
  ElMessage.info('调试信息已输出到控制台，请按F12查看');
};

// [新增] 监听 activeSub 变化，自动更新日历事件
watch(activeSub, () => {
  convertScheduleToEvents();
});

// [新增] 监听 scheduleData 变化，自动更新日历事件
watch(() => scheduleData.value, () => {
  convertScheduleToEvents();
}, { deep: true });

// [新增] 单独监听 scheduleData 变化进行冲突检测，避免递归
let conflictDetectionTimeout = null;
watch(() => scheduleData.value, () => {
  // 使用防抖避免频繁触发冲突检测
  if (conflictDetectionTimeout) {
    clearTimeout(conflictDetectionTimeout);
  }
  conflictDetectionTimeout = setTimeout(() => {
    console.log('排班数据发生变化，重新检测冲突...');
    detectAllConflicts();
  }, 500); // 500ms 防抖，给更多时间让数据稳定
}, { deep: true });

// 加载科室数据
const loadDepartments = async () => {
  try {
    loadingDepartments.value = true;
    console.log('开始获取科室数据...');
    
    // 获取所有父科室
    const parentResponse = await getAllParentDepartments();
    console.log('父科室API响应:', parentResponse);
    
    if (parentResponse && Array.isArray(parentResponse)) {
      const parentDepartments = parentResponse;
      console.log('父科室数据:', parentDepartments);
      
      // 为每个父科室获取子科室
      const departmentsWithChildren = await Promise.all(
        parentDepartments.map(async (parent) => {
          try {
            const childrenResponse = await getDepartmentsByParentId(parent.parentDepartmentId);
            console.log(`父科室 ${parent.name} 的子科室响应:`, childrenResponse);
            
            const children = childrenResponse && Array.isArray(childrenResponse) ? childrenResponse : [];
            console.log(`父科室 ${parent.name} 的子科室:`, children);
            
            return {
              id: `p${parent.parentDepartmentId}`,
              name: parent.name,
              description: parent.description,
              parentDepartmentId: parent.parentDepartmentId,
              children: children.map(child => ({
                id: `s${child.departmentId}`,
                name: child.name,
                description: child.description,
                departmentId: child.departmentId,
                parentDepartmentId: child.parentDepartmentId
              }))
            };
          } catch (error) {
            console.error(`获取父科室 ${parent.name} 的子科室失败:`, error);
            return {
              id: `p${parent.parentDepartmentId}`,
              name: parent.name,
              description: parent.description,
              parentDepartmentId: parent.parentDepartmentId,
              children: []
            };
          }
        })
      );
      
      departments.value = departmentsWithChildren;
      console.log('最终科室数据结构:', departments.value);
      
      // 如果有科室数据，默认选择第一个父科室
      if (departments.value.length > 0) {
        handleParentSelect(departments.value[0].id);
      }
      
    } else {
      console.error('获取父科室数据失败:', parentResponse);
      ElMessage.warning('获取科室数据失败，使用默认数据');
      loadFallbackDepartments();
    }
  } catch (error) {
    console.error('获取科室数据出错:', error);
    ElMessage.warning('网络错误，使用默认科室数据');
    loadFallbackDepartments();
  } finally {
    loadingDepartments.value = false;
  }
};

// 备用科室数据
const loadFallbackDepartments = () => {
  departments.value = [
    { id: 'p1', name: '内科', children: [
        { id: 's1-1', name: '呼吸内科' }, { id: 's1-2', name: '心血管科' }
      ]},
    { id: 'p2', name: '外科', children: [ { id: 's2-1', name: '普外科' } ]},
    { id: 'p3', name: '妇产科', children: [] },
  ];
  if (departments.value.length > 0) {
    handleParentSelect(departments.value[0].id);
  }
};

// 加载选中科室的医生数据
const loadDoctorsForDepartment = async (departmentId) => {
  if (!departmentId) {
    doctorsData.value = {};
    return;
  }

  try {
    loadingDoctors.value = true;
    
    const response = await getDoctorsByDepartmentId(departmentId);
    
    if (response && Array.isArray(response)) {
      // 转换医生数据格式，适配前端显示
      const doctors = response.map(doctor => ({
        id: doctor.doctorId || doctor.id,
        name: doctor.fullName || doctor.name,
        identifier: doctor.identifier,
        title: doctor.title || '医生',
        gender: doctor.gender || 'male', // 默认性别
        specialty: doctor.specialty || '',
        phoneNumber: doctor.phoneNumber || ''
      }));
      
      // 将医生数据存储到对应的科室ID下
      doctorsData.value[departmentId] = doctors;
      
    } else {
      console.error('获取科室医生数据失败:', response);
      doctorsData.value[departmentId] = [];
    }
  } catch (error) {
    console.error('获取科室医生数据出错:', error);
    doctorsData.value[departmentId] = [];
    ElMessage.warning('获取医生数据失败');
  } finally {
    loadingDoctors.value = false;
  }
};

// 加载选中科室的办公地点数据
const loadLocationsForDepartment = async (departmentId) => {
  if (!departmentId) {
    availableLocations.value = [];
    return;
  }

  try {
    const response = await getLocationNamesByDepartmentId(departmentId);
    
    if (response && Array.isArray(response)) {
      // 转换办公地点数据格式，适配前端显示
      const locations = response.map((locationName, index) => ({
        location_id: index + 1, // 生成临时ID
        name: locationName,
        building: '门诊楼', // 默认建筑
        floor: '一层', // 默认楼层
        room_number: locationName.split('-').pop() || '001' // 从名称中提取房间号
      }));
      
      availableLocations.value = locations;
    } else {
      console.error('获取科室办公地点数据失败:', response);
      availableLocations.value = [];
    }
  } catch (error) {
    console.error('获取科室办公地点数据出错:', error);
    availableLocations.value = [];
    ElMessage.warning('获取办公地点数据失败');
  }
};

// 保存排班到后端
const saveScheduleToBackend = async (doctor, date, shift, timeSlot, location) => {
  // 设置保存状态
  scheduleStatus.value.saving = true;
  scheduleStatus.value.error = null;
  
  try {
    // 构建排班数据
    const scheduleData = {
      doctorId: doctor.id,
      scheduleDate: date,
      slotId: timeSlot.slotId || timeSlot.slot_id || 1, // 使用时间段ID，默认为1
      locationId: location?.location_id || 1, // 使用办公地点ID，默认为1
      totalSlots: 10, // 默认总号源数
      fee: 5.00, // 默认挂号费
      remarks: `排班：${doctor.name} - ${timeSlot.slotName || timeSlot.slot_name} - ${location?.name || '默认地点'}`
    };

    console.log('保存排班数据:', scheduleData);
    
    const response = await createSchedule(scheduleData);
    console.log('排班保存成功:', response);
    
    // 检查响应状态
    if (response && (response.scheduleId || response.data?.scheduleId)) {
      const scheduleId = response.scheduleId || response.data?.scheduleId;
      
      // 更新保存状态
      scheduleStatus.value.saving = false;
      scheduleStatus.value.lastSaved = {
        scheduleId: scheduleId,
        doctor: doctor.name,
        date: date,
        shift: shift,
        timeSlot: timeSlot.slotName || timeSlot.slot_name,
        location: location?.name || '默认地点',
        timestamp: new Date().toLocaleString()
      };
      
      ElMessage.success({
        message: `✅ 排班保存成功！\n医生：${doctor.name}\n日期：${date} ${shift}\n时间段：${timeSlot.slotName || timeSlot.slot_name}\n地点：${location?.name || '默认地点'}\n排班ID：${scheduleId}`,
        duration: 5000,
        showClose: true
      });
      
      // 在控制台显示详细信息
      console.log('🎉 排班创建成功！', {
        scheduleId: scheduleId,
        doctor: doctor.name,
        date: date,
        shift: shift,
        timeSlot: timeSlot.slotName || timeSlot.slot_name,
        location: location?.name || '默认地点',
        totalSlots: 10,
        fee: 5.00
      });
      
      return response;
    } else {
      scheduleStatus.value.saving = false;
      ElMessage.warning('排班保存成功，但未返回排班ID');
      return response;
    }
  } catch (error) {
    console.error('保存排班失败:', error);
    
    // 更新错误状态
    scheduleStatus.value.saving = false;
    scheduleStatus.value.error = {
      message: error.message || '未知错误',
      doctor: doctor.name,
      date: date,
      shift: shift,
      timestamp: new Date().toLocaleString()
    };
    
    // 更详细的错误提示
    let errorMessage = '排班保存失败';
    if (error.response) {
      // 服务器返回的错误
      errorMessage = `服务器错误：${error.response.status} - ${error.response.data?.message || error.response.statusText}`;
    } else if (error.request) {
      // 网络错误
      errorMessage = '网络连接失败，请检查后端服务是否启动';
    } else {
      // 其他错误
      errorMessage = error.message || '未知错误';
    }
    
    ElMessage.error({
      message: `❌ ${errorMessage}\n医生：${doctor.name}\n日期：${date} ${shift}`,
      duration: 8000,
      showClose: true
    });
    
    throw error;
  } finally {
    // 确保保存状态被重置
    scheduleStatus.value.saving = false;
  }
};

// 获取时间段数据
const loadTimeSlots = async () => {
  try {
    console.log('开始获取时间段数据...');
    const response = await getTimeSlots();
    console.log('时间段API响应:', response);
    
    // 根据后端返回格式调整解析逻辑
    if (response && (response.code === 200 || response.code === '200')) {
      timeSlots.value = response.data || [];
      console.log('时间段数据加载成功:', timeSlots.value);
    } else if (response && response.data && (response.data.code === 200 || response.data.code === '200')) {
      timeSlots.value = response.data.data || [];
      console.log('时间段数据加载成功:', timeSlots.value);
    } else {
      console.error('获取时间段数据失败:', response);
      // 使用备用数据
      loadFallbackTimeSlots();
      ElMessage.warning('使用默认时间段数据');
    }
  } catch (error) {
    console.error('获取时间段数据出错:', error);
    // 使用备用数据
    loadFallbackTimeSlots();
    ElMessage.warning('网络错误，使用默认时间段数据');
  }
};

// 备用时间段数据
const loadFallbackTimeSlots = () => {
  timeSlots.value = [
    { slot_id: 1, slot_name: '上午08:00-08:30', start_time: '08:00:00', end_time: '08:30:00', period: '上午' },
    { slot_id: 2, slot_name: '上午08:30-09:00', start_time: '08:30:00', end_time: '09:00:00', period: '上午' },
    { slot_id: 3, slot_name: '上午09:00-09:30', start_time: '09:00:00', end_time: '09:30:00', period: '上午' },
    { slot_id: 4, slot_name: '上午09:30-10:00', start_time: '09:30:00', end_time: '10:00:00', period: '上午' },
    { slot_id: 5, slot_name: '上午10:00-10:30', start_time: '10:00:00', end_time: '10:30:00', period: '上午' },
    { slot_id: 6, slot_name: '上午10:30-11:00', start_time: '10:30:00', end_time: '11:00:00', period: '上午' },
    { slot_id: 7, slot_name: '上午11:00-11:30', start_time: '11:00:00', end_time: '11:30:00', period: '上午' },
    { slot_id: 8, slot_name: '上午11:30-12:00', start_time: '11:30:00', end_time: '12:00:00', period: '上午' },
    { slot_id: 9, slot_name: '下午14:00-14:30', start_time: '14:00:00', end_time: '14:30:00', period: '下午' },
    { slot_id: 10, slot_name: '下午14:30-15:00', start_time: '14:30:00', end_time: '15:00:00', period: '下午' },
    { slot_id: 11, slot_name: '下午15:00-15:30', start_time: '15:00:00', end_time: '15:30:00', period: '下午' },
    { slot_id: 12, slot_name: '下午15:30-16:00', start_time: '15:30:00', end_time: '16:00:00', period: '下午' },
    { slot_id: 13, slot_name: '下午16:00-16:30', start_time: '16:00:00', end_time: '16:30:00', period: '下午' },
    { slot_id: 14, slot_name: '下午16:30-17:00', start_time: '16:30:00', end_time: '17:00:00', period: '下午' },
    { slot_id: 15, slot_name: '下午17:00-17:30', start_time: '17:00:00', end_time: '17:30:00', period: '下午' },
    { slot_id: 16, slot_name: '下午17:30-18:00', start_time: '17:30:00', end_time: '18:00:00', period: '下午' }
  ];
  console.log('使用备用时间段数据:', timeSlots.value);
};

onMounted(() => {
  // 加载科室数据
  loadDepartments();
  convertScheduleToEvents();
  // 加载时间段数据
  loadTimeSlots();
  // 如果API调用失败，立即使用备用数据
  setTimeout(() => {
    if (timeSlots.value.length === 0) {
      console.log('时间段数据为空，使用备用数据');
      loadFallbackTimeSlots();
    }
  }, 2000);
  // 延迟执行冲突检测，确保数据已经加载完成
  setTimeout(() => {
    detectAllConflicts();
  }, 1000);
});

</script>

<style scoped>
.schedule-dashboard {
  display: flex;
  height: calc(100vh - 50px);
  background-color: #f7fafc;
}

/* [新增] 头部控制按钮样式 */
.header-controls {
  display: flex;
  gap: 16px;
  align-items: center;
}

.view-switcher {
  margin-right: 16px;
}

/* [新增] 日历容器样式 */
.calendar-container {
  padding: 20px;
  min-height: 600px;
}

/* [新增] FullCalendar 自定义样式 */
.calendar-container :deep(.fc) {
  font-family: 'Microsoft YaHei', sans-serif;
}

.calendar-container :deep(.fc-toolbar-title) {
  font-size: 20px;
  font-weight: bold;
  color: #303133;
}

.calendar-container :deep(.fc-button) {
  background-color: #409EFF;
  border-color: #409EFF;
  text-transform: none;
  padding: 6px 12px;
}

.calendar-container :deep(.fc-button:hover) {
  background-color: #66b1ff;
  border-color: #66b1ff;
}

.calendar-container :deep(.fc-button-active) {
  background-color: #337ecc;
  border-color: #337ecc;
}

.calendar-container :deep(.fc-event) {
  cursor: pointer;
  border-radius: 4px;
  padding: 2px 4px;
  font-size: 12px;
}

.calendar-container :deep(.fc-event:hover) {
  opacity: 0.8;
}

.calendar-container :deep(.fc-daygrid-event) {
  white-space: normal;
}

.calendar-container :deep(.fc-timegrid-event) {
  border-radius: 4px;
}

.calendar-container :deep(.fc-col-header-cell) {
  background-color: #f5f7fa;
  font-weight: bold;
  padding: 10px 0;
}

.calendar-container :deep(.fc-day-today) {
  background-color: #ecf5ff !important;
}

.calendar-container :deep(.fc-timegrid-slot) {
  height: 2em;
}

.department-sidebar {
  width: 320px;
  display: flex;
  background-color: #fff;
  border-right: 1px solid #e2e8f0;
  flex-shrink: 0;
}

.loading-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 40px 20px;
  color: #909399;
  gap: 12px;
}

.loading-container .el-icon {
  font-size: 24px;
}

.no-sub-departments {
  padding: 20px;
  text-align: center;
}
.department-menu {
  width: 120px;
  border-right: none;
}
.sub-department-panel {
  flex: 1;
  padding: 8px;
  border-left: 1px solid #e2e8f0;
}
.sub-department-item {
  padding: 10px 15px;
  cursor: pointer;
  border-radius: 4px;
}
.sub-department-item:hover {
  background-color: #f5f7fa;
}
.sub-department-item.active {
  background-color: #ecf5ff;
  color: #409eff;
  font-weight: bold;
}
.schedule-content {
  flex: 1;
  padding: 20px;
  display: flex;
  flex-direction: column;
  gap: 20px;
  overflow: auto;
}
.schedule-card {
  flex-shrink: 0;
}
.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.placeholder {
  display: flex;
  justify-content: center;
  align-items: center;
  height: 200px;
}
.schedule-table {
  width: 100%;
  border-collapse: collapse;
  text-align: center;
  table-layout: fixed;
}
.schedule-table th, .schedule-table td {
  border: 1px solid #ebeef5;
  padding: 8px;
  font-size: 14px;
  vertical-align: top;
}
.schedule-table th {
  background-color: #f5f7fa;
}
.shift-cell {
  min-height: 120px;
  padding: 4px;
}
.doctor-tags {
  display: flex;
  flex-direction: column;
  gap: 8px;
  justify-content: flex-start;
  align-items: center;
  flex-grow: 1;
}

.doctor-card-in-table {
  width: 95%;
  padding: 8px;
  border-radius: 8px;
  background-color: #f0f9eb;
  border: 1px solid #e1f3d8;
  cursor: grab;
  position: relative;
  text-align: left;
}
.doctor-card-in-table:hover .remove-icon {
  display: inline-flex;
}
.doctor-card-header {
  display: flex;
  align-items: center;
  margin-bottom: 6px;
  font-weight: 500;
}

.doctor-avatar-small {
  width: 24px;
  height: 24px;
  border-radius: 50%;
  margin-right: 8px;
}
.remove-icon {
  display: none;
  position: absolute;
  top: 4px;
  right: 4px;
  background-color: rgba(255, 255, 255, 0.8);
  border-radius: 50%;
  cursor: pointer;
  font-size: 12px;
  color: #f56c6c;
}
.doctor-card-location {
  font-size: 12px;
  color: #909399;
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 4px 6px;
  border-radius: 4px;
  position: relative; /* 为了定位清除按钮 */
  transition: background-color 0.2s;
}
.doctor-card-location:hover {
  background-color: #e9e9eb;
}

.doctor-card-location.is-set {
  color: #67c23a;
  font-weight: bold;
}
/* [新增] 清除地点按钮样式 */
.clear-location-icon {
  display: none; /* 默认隐藏 */
  cursor: pointer;
  color: #f56c6c;
  margin-left: auto; /* 推到最右边 */
  padding: 2px;
}
.doctor-card-location:hover .clear-location-icon {
  display: inline-flex; /* 悬停时显示 */
}


.bottom-panels {
  display: flex;
  gap: 16px;
  margin-top: 20px;
  flex-wrap: nowrap;
  overflow-x: auto;
}
.draggable-list-card {
  flex-shrink: 0;
  min-width: 280px;
  max-width: 320px;
  width: 300px;
}
.draggable-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
  max-height: 400px;
  overflow-y: auto;
}

.doctor-card {
  display: flex;
  align-items: center;
  background-color: #f9fafb;
  border: 1px solid #e5e7eb;
  border-radius: 6px;
  padding: 8px 12px;
  cursor: grab;
  transition: box-shadow 0.2s;
  gap: 10px;
  min-height: 50px;
  width: 100%;
}
.doctor-card:hover {
  box-shadow: 0 4px 6px rgba(0,0,0,0.1);
}
.doctor-avatar {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  margin-right: 12px;
  object-fit: cover;
}
.doctor-info {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
}
.doctor-name {
  font-weight: bold;
  color: #111827;
}
.doctor-title {
  font-size: 12px;
  color: #6b7280;
}
/* 新增地点卡片样式 */
.location-list {
  gap: 10px;
}
.location-card {
  display: flex;
  align-items: center;
  background-color: #f4f4f5;
  border: 1px solid #e9e9eb;
  border-radius: 6px;
  padding: 8px 12px;
  cursor: grab;
  transition: box-shadow 0.2s;
  width: 100%;
  min-height: 50px;
  gap: 10px;
}
.location-card:hover {
  box-shadow: 0 4px 6px rgba(0,0,0,0.1);
}
.location-icon {
  color: #909399;
  margin-right: 12px;
}
.location-info {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
}
.location-name {
  font-weight: 500;
  color: #303133;
}
.location-desc {
  font-size: 12px;
  color: #909399;
}

/* 时间段卡片样式 */
.time-slot-column {
  width: 250px;
  vertical-align: top;
  background-color: #f8f9fa;
  min-height: 120px;
}

.shift-label {
  font-weight: bold;
  color: #303133;
  margin-bottom: 8px;
  padding: 4px 8px;
  background-color: #e9ecef;
  border-radius: 4px;
  text-align: center;
}

.time-slot-cards {
  display: flex;
  flex-direction: column;
  gap: 4px;
  max-height: 300px;
  overflow-y: auto;
  padding: 4px;
}

.time-slot-card {
  background-color: #e6f7ff;
  border: 1px solid #91d5ff;
  border-radius: 6px;
  padding: 6px 8px;
  cursor: grab;
  transition: all 0.2s;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
  position: relative;
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.time-slot-card:hover {
  border-color: #1890ff;
  box-shadow: 0 2px 6px rgba(24, 144, 255, 0.2);
  transform: translateY(-1px);
}

.time-slot-card:hover .remove-icon {
  display: inline-flex;
}

.time-slot-card:active {
  cursor: grabbing;
}

.time-slot-card-content {
  flex: 1;
}

.time-slot-name {
  font-size: 12px;
  font-weight: 500;
  color: #1890ff;
  margin-bottom: 2px;
}

.time-slot-time {
  font-size: 10px;
  color: #8c8c8c;
}

.time-slot-card .remove-icon {
  display: none;
  position: absolute;
  top: 4px;
  right: 4px;
  background-color: rgba(255, 255, 255, 0.8);
  border-radius: 50%;
  cursor: pointer;
  font-size: 12px;
  color: #f56c6c;
  padding: 2px;
}

/* 底部面板的时间段卡片样式 */
.time-slot-list {
  gap: 10px;
}

/* 排班状态指示器样式 */
.schedule-status-indicator {
  margin: 0 20px;
  font-size: 14px;
}

.status-saving {
  display: flex;
  align-items: center;
  gap: 8px;
  color: #409eff;
}

.status-success {
  display: flex;
  align-items: center;
  gap: 8px;
  color: #67c23a;
}

.status-error {
  display: flex;
  align-items: center;
  gap: 8px;
  color: #f56c6c;
}

.status-saving .el-icon {
  animation: rotate 1s linear infinite;
}

@keyframes rotate {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}

.time-slot-card {
  display: flex;
  align-items: center;
  background-color: #f0f9ff;
  border: 1px solid #bae6fd;
  border-radius: 6px;
  padding: 8px 12px;
  cursor: grab;
  transition: box-shadow 0.2s;
  width: 100%;
  min-height: 50px;
  gap: 10px;
}

.time-slot-card:hover {
  box-shadow: 0 4px 6px rgba(0,0,0,0.1);
}

.time-slot-icon {
  color: #0ea5e9;
  margin-right: 12px;
}

.time-slot-info {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
}

.time-slot-name {
  font-weight: 500;
  color: #0c4a6e;
  font-size: 13px;
}

.time-slot-time {
  font-size: 11px;
  color: #64748b;
}

/* [新增] 批量导入样式 */
.batch-import-panel {
  margin-bottom: 16px;
  min-width: 350px;
  max-width: 400px;
  width: 380px;
}

.batch-import-content {
  padding: 12px;
  max-height: 400px;
  overflow-y: auto;
}

.template-section {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
  padding: 12px;
  background-color: #f0f9ff;
  border-radius: 8px;
  border: 1px solid #e1f5fe;
}

.template-info {
  display: flex;
  align-items: center;
  gap: 8px;
  color: #1976d2;
  font-size: 14px;
}

.template-icon {
  font-size: 16px;
}

.upload-section {
  margin-bottom: 16px;
}

.upload-dragger {
  width: 100%;
}

.upload-content {
  padding: 20px;
  text-align: center;
}

.upload-icon {
  font-size: 48px;
  color: #c0c4cc;
  margin-bottom: 16px;
}

.upload-text p {
  margin: 8px 0;
  color: #606266;
}

.upload-hint {
  font-size: 12px;
  color: #909399;
}

.file-info {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
  padding: 12px;
  background-color: #f5f7fa;
  border-radius: 8px;
  border: 1px solid #e4e7ed;
}

.file-details {
  display: flex;
  align-items: center;
  gap: 8px;
}

.file-name {
  font-weight: 500;
  color: #303133;
}

.file-size {
  color: #909399;
  font-size: 12px;
}

.import-actions {
  display: flex;
  gap: 12px;
  margin-bottom: 16px;
}

.import-progress {
  margin-bottom: 16px;
  padding: 16px;
  background-color: #f9f9f9;
  border-radius: 8px;
  border: 1px solid #e4e7ed;
}

.progress-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
  font-size: 14px;
  color: #606266;
}

.progress-message {
  margin-top: 8px;
  font-size: 12px;
  color: #909399;
  text-align: center;
}

.import-result {
  padding: 16px;
  border-radius: 8px;
  border: 1px solid;
}

.import-result.success {
  background-color: #f0f9ff;
  border-color: #67c23a;
}

.import-result.error {
  background-color: #fef0f0;
  border-color: #f56c6c;
}

.result-header {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 12px;
  font-weight: 600;
  font-size: 16px;
}

.success-icon {
  color: #67c23a;
}

.error-icon {
  color: #f56c6c;
}

.result-content p {
  margin: 8px 0;
  color: #606266;
}

.result-details {
  margin-top: 12px;
}

.result-details h5 {
  margin: 8px 0;
  color: #303133;
  font-size: 14px;
}

.result-details ul {
  margin: 0;
  padding-left: 20px;
}

.result-details li {
  margin: 4px 0;
  color: #606266;
  font-size: 13px;
}

/* [新增] 冲突检测样式 */
.conflict-controls {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-right: 16px;
}

.conflict-summary {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 12px;
  background-color: #fff2e8;
  border: 1px solid #f5dab1;
  border-radius: 6px;
  font-size: 14px;
}

.detect-conflicts-btn {
  display: flex;
  align-items: center;
  gap: 4px;
}

.conflict-summary-icon {
  font-size: 16px;
}

.critical-icon {
  color: #f56c6c;
}

.warning-icon {
  color: #e6a23c;
}

.conflict-text {
  color: #e6a23c;
  font-weight: 500;
}

.critical-count {
  color: #f56c6c;
  font-weight: 600;
}

.warning-count {
  color: #e6a23c;
  font-weight: 600;
}

/* 医生卡片冲突样式 */
.conflict-error {
  background-color: #fef0f0 !important;
  border: 2px solid #f56c6c !important;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(245, 108, 108, 0.2);
}

.conflict-warning {
  background-color: #fdf6ec !important;
  border: 2px solid #e6a23c !important;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(230, 162, 60, 0.2);
}

.conflict-icon {
  margin-left: 8px;
  font-size: 16px;
}

.conflict-error-icon {
  color: #f56c6c;
}

.conflict-warning-icon {
  color: #e6a23c;
}

/* 冲突卡片悬停效果 */
.doctor-card-in-table.conflict-error:hover {
  background-color: #fde2e2 !important;
  transform: scale(1.02);
  transition: all 0.2s ease;
}

.doctor-card-in-table.conflict-warning:hover {
  background-color: #fce4d6 !important;
  transform: scale(1.02);
  transition: all 0.2s ease;
}

/* 日历事件冲突样式 */
.calendar-container :deep(.fc-event.conflict-critical) {
  background-color: #f56c6c !important;
  border-color: #f56c6c !important;
}

.calendar-container :deep(.fc-event.conflict-warning) {
  background-color: #e6a23c !important;
  border-color: #e6a23c !important;
}

/* 时间段班次不匹配样式 */
.time-slot-mismatch {
  background-color: #fef0f0 !important;
  border: 2px solid #f56c6c !important;
  box-shadow: 0 2px 8px rgba(245, 108, 108, 0.2);
}

.shift-mismatch-warning {
  display: flex;
  align-items: center;
  gap: 4px;
  margin-top: 4px;
  padding: 2px 6px;
  background-color: #f56c6c;
  color: white;
  border-radius: 4px;
  font-size: 12px;
}

.shift-mismatch-warning .warning-icon {
  font-size: 12px;
}
</style>

