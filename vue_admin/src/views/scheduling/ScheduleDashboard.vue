<template>
  <div class="schedule-dashboard">
    <div class="back-area" style="margin-bottom: 12px;">
      <BackButton />
    </div>
    <!-- 左侧科室导航 -->
    <div class="department-sidebar">
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
    </div>

     <!-- 右侧内容区 -->
     <div class="schedule-content">
       <el-card shadow="always" class="schedule-card">
         <template #header>
           <div class="card-header">
             <span>{{ selectedDepartmentName }} ({{ selectedDepartmentCode }}) - 排班管理</span>
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
                 <!-- 手动检测冲突按钮 -->
                 <el-button size="small" type="primary" @click="detectAllConflicts" class="detect-conflicts-btn">
                   <el-icon><Refresh /></el-icon>
                   检测冲突
                 </el-button>
                 <!-- 调试按钮 -->
                 <el-button size="small" type="info" @click="debugConflicts" class="debug-btn">
                   <el-icon><Warning /></el-icon>
                   调试冲突
                 </el-button>
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
                     <div v-for="timeSlot in getTimeSlotsForShift(shift)" :key="timeSlot.slot_id"
                          class="time-slot-card" 
                          :class="{ 
                            'time-slot-mismatch': !isTimeSlotMatchShift(timeSlot, shift)
                          }"
                          draggable="true" 
                          @dragstart="onDragStart($event, { type: 'timeSlot', data: timeSlot })">
                       <div class="time-slot-card-content">
                         <div class="time-slot-name">{{ timeSlot.slot_name }}</div>
                         <div class="time-slot-time">{{ timeSlot.start_time }} - {{ timeSlot.end_time }}</div>
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
                           <span>{{ doc.name }}</span>
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

      <!-- 底部拖拽区域 -->
      <div class="bottom-panels">
        <!-- 待排班医生列表 -->
        <el-card shadow="always" class="draggable-list-card">
          <template #header>
            <div class="card-header">
              <span>待排班医生 (拖拽到上方进行排班)</span>
            </div>
          </template>
          <div class="draggable-list">
            <div v-for="doc in availableDoctors" :key="doc.id"
                 class="doctor-card" draggable="true" @dragstart="onDragStart($event, { type: 'doctor', data: doc })">
              <img :src="doc.gender === 'male' ? doctorMaleImg : doctorFemaleImg" alt="医生头像" class="doctor-avatar">
              <div class="doctor-info">
                <span class="doctor-name">{{ doc.name }}</span>
                <span class="doctor-title">{{ doc.title }}</span>
              </div>
            </div>
            <el-empty v-if="!availableDoctors.length" description="该科室暂无医生" :image-size="60"/>
          </div>
        </el-card>

        <!-- 批量导入排班信息 -->
        <el-card shadow="always" class="draggable-list-card batch-import-panel">
          <template #header>
            <div class="card-header">
              <span>批量导入排班信息</span>
            </div>
          </template>
          <div class="batch-import-content">
            <!-- 模板下载 -->
            <div class="template-section">
              <div class="template-info">
                <el-icon class="template-icon"><Document /></el-icon>
                <span>请先下载模板文件，按格式填写后上传</span>
              </div>
              <el-button type="primary" size="small" @click="downloadTemplate">
                <el-icon><Download /></el-icon>
                下载模板
              </el-button>
            </div>

            <!-- 文件上传 -->
            <div class="upload-section">
              <el-upload
                ref="uploadRef"
                class="upload-dragger"
                drag
                :auto-upload="false"
                :show-file-list="false"
                accept=".xlsx,.xls,.csv"
                :on-change="handleFileChange"
                :before-upload="beforeUpload">
                <div class="upload-content">
                  <el-icon class="upload-icon"><UploadFilled /></el-icon>
                  <div class="upload-text">
                    <p>点击或拖拽文件到此区域上传</p>
                    <p class="upload-hint">支持 .xlsx、.xls、.csv 格式</p>
                  </div>
                </div>
              </el-upload>
            </div>

            <!-- 文件信息显示 -->
            <div v-if="selectedFile" class="file-info">
              <div class="file-details">
                <el-icon><Document /></el-icon>
                <span class="file-name">{{ selectedFile.name }}</span>
                <span class="file-size">({{ formatFileSize(selectedFile.size) }})</span>
              </div>
              <el-button type="danger" size="small" @click="removeFile">
                <el-icon><Close /></el-icon>
                移除
              </el-button>
            </div>

            <!-- 导入按钮 -->
            <div class="import-actions">
              <el-button 
                type="success" 
                :loading="importing" 
                :disabled="!selectedFile"
                @click="handleImport">
                <el-icon><Upload /></el-icon>
                {{ importing ? '导入中...' : '开始导入' }}
              </el-button>
              <el-button @click="clearImportData">
                <el-icon><Refresh /></el-icon>
                清空数据
              </el-button>
            </div>

            <!-- 导入进度 -->
            <div v-if="importProgress.show" class="import-progress">
              <div class="progress-header">
                <span>导入进度</span>
                <span>{{ importProgress.current }}/{{ importProgress.total }}</span>
              </div>
              <el-progress 
                :percentage="importProgress.percentage" 
                :status="importProgress.status"
                :stroke-width="8">
              </el-progress>
              <div v-if="importProgress.message" class="progress-message">
                {{ importProgress.message }}
              </div>
            </div>

            <!-- 导入结果 -->
            <div v-if="importResult.show" class="import-result">
              <div class="result-header">
                <el-icon :class="importResult.type === 'success' ? 'success-icon' : 'error-icon'">
                  <component :is="importResult.type === 'success' ? 'CircleCheck' : 'CircleClose'" />
                </el-icon>
                <span>{{ importResult.title }}</span>
              </div>
              <div class="result-content">
                <p>{{ importResult.message }}</p>
                <div v-if="importResult.details && importResult.details.length > 0" class="result-details">
                  <h5>详细信息：</h5>
                  <ul>
                    <li v-for="detail in importResult.details" :key="detail">{{ detail }}</li>
                  </ul>
                </div>
              </div>
            </div>
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
            <div v-for="timeSlot in timeSlots" :key="timeSlot.slot_id"
                 class="time-slot-card" draggable="true" @dragstart="onDragStart($event, { type: 'timeSlot', data: timeSlot })">
              <el-icon :size="20" class="time-slot-icon"><Clock /></el-icon>
              <div class="time-slot-info">
                <span class="time-slot-name">{{ timeSlot.slot_name }}</span>
                <span class="time-slot-time">{{ timeSlot.start_time }} - {{ timeSlot.end_time }}</span>
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
import { ArrowLeft, ArrowRight, Close, Location, OfficeBuilding, CircleCloseFilled, Clock, Document, Download, UploadFilled, Upload, Refresh, CircleCheck, CircleClose, Warning } from '@element-plus/icons-vue';
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

// --- 模拟数据 ---
const departments = ref([
  { id: 'p1', name: '内科', children: [
      { id: 's1-1', name: '呼吸内科' }, { id: 's1-2', name: '心血管科' }
    ]},
  { id: 'p2', name: '外科', children: [ { id: 's2-1', name: '普外科' } ]},
  { id: 'p3', name: '妇产科', children: [] },
]);

const doctorsData = ref({
  's1-2': [
    {id: 1, name: '杨青松', title: '主任医师', gender: 'male'},
    {id: 2, name: '杨林', title: '副主任医师', gender: 'male'},
    {id: 3, name: '席紫明', title: '主治医师', gender: 'female'}
  ],
  'p3': [ {id: 6, name: '王莉', title: '主任医师', gender: 'female'} ],
});

const availableLocations = ref([
  { location_id: 101, name: '门诊楼-201诊室', building: '门诊楼', floor: '二层', room_number: '201' },
  { location_id: 102, name: '门诊楼-203诊室', building: '门诊楼', floor: '二层', room_number: '203' },
  { location_id: 103, name: '门诊楼-305诊室', building: '门诊楼', floor: '三层', room_number: '305' },
  { location_id: 201, name: '住院部A栋-101', building: '住院部A栋', floor: '一层', room_number: '101' },
]);

// 时间段数据
const timeSlots = ref([
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
  { slot_id: 16, slot_name: '下午17:30-18:00', start_time: '17:30:00', end_time: '18:00:00', period: '下午' },
]);


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

const availableDoctors = computed(() => {
  if (!activeSub.value) return [];
  return doctorsData.value[activeSub.value] || [];
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
  return timeSlotColumns.value[shift] || [];
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

const handleDoctorDrop = (dragData, toDate, toShift) => {
  const { data: doctor, source } = dragData;
  if (source.date && source.shift) {
    if (source.date === toDate && source.shift === toShift) return;
    removeDoctorFromShift(doctor, source.date, source.shift, false);
  }
  addDoctorToShift(doctor, toDate, toShift);
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
      ElMessage.success(`已将时间段 "${timeSlot.slot_name}" 添加到 ${toShift} 时段列中`);
    } else {
      ElMessage.warning(`时间段 "${timeSlot.slot_name}" 已存在于 ${toShift} 时段列中`);
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
  activeParent.value = index;
  const parent = departments.value.find(p => p.id === index);
  if (parent) {
    if (parent.children && parent.children.length > 0) {
      activeSub.value = parent.children[0].id;
    } else {
      activeSub.value = parent.id;
    }
  } else {
    activeSub.value = null;
  }
  // 切换科室时清空时间段列
  clearTimeSlotColumns();
};

const handleSubSelect = (id) => {
  activeSub.value = id;
  // 切换科室时清空时间段列
  clearTimeSlotColumns();
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
      
      if (doctor.conflicts?.hasConflict) {
        if (doctor.conflicts.severity === 'error') {
          backgroundColor = '#F56C6C';
          borderColor = '#F56C6C';
        } else if (doctor.conflicts.severity === 'warning') {
          backgroundColor = '#E6A23C';
          borderColor = '#E6A23C';
        }
      }
      
      events.push({
        id: `${date}-${shift}-${doctor.id}`,
        title: `${doctor.name} (${doctor.title || '医生'})`,
        start: start.toISOString(),
        end: end.toISOString(),
        backgroundColor,
        borderColor,
        extendedProps: {
          doctorId: doctor.id,
          location: doctor.location,
          shift: shift,
          departmentId: activeSub.value,
          conflicts: doctor.conflicts
        }
      });
    });
  });
  
  calendarEvents.value = events;
};

// [新增] 监听 activeSub 变化，自动更新日历事件
watch(activeSub, () => {
  convertScheduleToEvents();
});

// [新增] 监听 scheduleData 变化，自动更新日历事件
watch(() => scheduleData.value, () => {
  convertScheduleToEvents();
}, { deep: true });

onMounted(() => {
  if (departments.value.length > 0) handleParentSelect(departments.value[0].id);
  convertScheduleToEvents();
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
  color: #e6a23corn;
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

