<template>
  <div class="schedule-dashboard">
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
            <span>{{ selectedDepartmentName }} - 一周排班表</span>
            <div>
              <el-button-group>
                <el-button :icon="ArrowLeft" @click="changeWeek(-1)">上一周</el-button>
                <el-button @click="changeWeek(0)">本周</el-button>
                <el-button :icon="ArrowRight" @click="changeWeek(1)">下一周</el-button>
              </el-button-group>
            </div>
          </div>
        </template>

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
              <td>{{ shift }}</td>
              <td v-for="day in weekDates" :key="day.fullDate + '-' + shift"
                  @dragover.prevent @drop="onDrop($event, day.fullDate, shift)">
                <div class="shift-cell">
                  <div class="doctor-tags">
                    <div v-for="doc in getDoctorsForShift(day.fullDate, shift)" :key="doc.id"
                         class="doctor-card-in-table" :data-doctor-id="doc.id" draggable="true" @dragstart="onDragStart($event, { type: 'doctor', data: doc }, day.fullDate, shift)">
                      <div class="doctor-card-header">
                        <img :src="getDoctorAvatar(doc.id)" alt="医生头像" class="doctor-avatar-small">
                        <span>{{ doc.name }}</span>
                        <el-icon class="remove-icon" @click="removeDoctorFromShift(doc, day.fullDate, shift)"><Close /></el-icon>
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
import { ref, computed, onMounted } from 'vue';
// [新增] 导入 CircleCloseFilled 图标
import { ArrowLeft, ArrowRight, Close, Location, OfficeBuilding, CircleCloseFilled } from '@element-plus/icons-vue';
import { ElMessage } from 'element-plus';
import doctorMaleImg from '@/assets/doctor.jpg';
import doctorFemaleImg from '@/assets/doctor1.jpg';

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


const scheduleData = ref({
  'p3': [
    { date: '2025-10-21', shift: '上午', doctors: [{id: 6, name: '王莉', location: null}] },
  ]
});

// --- 状态管理 ---
const currentMonday = ref(new Date('2025-10-20'));
const activeParent = ref(null);
const activeSub = ref(null);

const subDepartments = computed(() => {
  if (!activeParent.value) return [];
  const parent = departments.value.find(p => p.id === activeParent.value);
  return parent ? parent.children : [];
});

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
};

const getDoctorsForShift = (date, shift) => {
  if (!activeSub.value || !scheduleData.value[activeSub.value]) return [];
  const entry = scheduleData.value[activeSub.value].find(item => item.date === date && item.shift === shift);
  return entry ? entry.doctors : [];
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
  ElMessage.info(`已取消【${doctor.name}】医生的地点“${oldLocation}”`);
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
};

const handleSubSelect = (id) => {
  activeSub.value = id;
};

onMounted(() => {
  if (departments.value.length > 0) handleParentSelect(departments.value[0].id);
});

</script>

<style scoped>
.schedule-dashboard {
  display: flex;
  height: calc(100vh - 50px);
  background-color: #f7fafc;
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
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 20px;
}
.draggable-list-card {
  flex-shrink: 0;
}
.draggable-list {
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
  min-height: 100px;
}

.doctor-card {
  display: flex;
  align-items: center;
  background-color: #f9fafb;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  padding: 10px;
  cursor: grab;
  transition: box-shadow 0.2s;
  width: calc(50% - 6px);
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
  border-radius: 8px;
  padding: 10px;
  cursor: grab;
  transition: box-shadow 0.2s;
  width: calc(50% - 5px);
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
</style>

