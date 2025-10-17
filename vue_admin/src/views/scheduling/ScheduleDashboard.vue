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
              <th>门诊科室</th>
              <th v-for="day in weekDates" :key="day.fullDate">{{ day.date }} ({{ day.dayOfWeek }})</th>
            </tr>
            </thead>
            <tbody>
            <tr v-for="shift in ['上午', '下午']" :key="shift">
              <td v-if="shift === '上午'" :rowspan="2">{{ selectedDepartmentName }}</td>
              <td v-for="day in weekDates" :key="day.fullDate + '-' + shift"
                  @dragover.prevent @drop="onDrop($event, day.fullDate, shift)">
                <div class="shift-cell">
                  <span class="shift-label">{{ shift }}</span>
                  <div class="doctor-tags">
                    <div v-for="doc in getDoctorsForShift(day.fullDate, shift)" :key="doc.id"
                         class="doctor-card-in-table" draggable="true" @dragstart="onDragStart($event, doc, day.fullDate, shift)">
                      <img :src="getDoctorAvatar(doc.id)" alt="医生头像" class="doctor-avatar-small">
                      <span>{{ doc.name }}</span>
                      <el-icon class="remove-icon" @click="removeDoctorFromShift(doc, day.fullDate, shift)"><Close /></el-icon>
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

      <!-- 待排班医生列表 -->
      <el-card shadow="always" class="doctor-list-card" v-if="activeSub">
        <template #header>
          <div class="card-header">
            <span>待排班医生 (拖拽到上方进行排班)</span>
          </div>
        </template>
        <div class="doctor-list">
          <div v-for="doc in availableDoctors" :key="doc.id"
               class="doctor-card" draggable="true" @dragstart="onDragStart($event, doc)">
            <img :src="doc.gender === 'male' ? doctorMaleImg : doctorFemaleImg" alt="医生头像" class="doctor-avatar">
            <div class="doctor-info">
              <span class="doctor-name">{{ doc.name }}</span>
              <span class="doctor-title">{{ doc.title }}</span>
            </div>
          </div>
          <el-empty v-if="!availableDoctors.length" description="该科室暂无医生" :image-size="60"/>
        </div>
      </el-card>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue';
import { ArrowLeft, ArrowRight, Close } from '@element-plus/icons-vue';
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

const scheduleData = ref({
  'p3': [ // 妇产科的排班数据
    // 修改：只保留本周的数据，以正确演示周切换功能
    { date: '2025-10-21', shift: '上午', doctors: [{id: 6, name: '王莉'}] },
  ]
});
// --- 模拟数据结束 ---

// --- 核心修改：日期管理 ---
const currentMonday = ref(new Date('2025-10-20')); // 使用一个Date对象来追踪当前周的周一

const changeWeek = (offset) => {
  if (offset === 0) {
    // 回到本周 (我们定义本周的周一为2025-10-20)
    currentMonday.value = new Date('2025-10-20');
  } else {
    // 上/下一周
    const newDate = new Date(currentMonday.value);
    newDate.setDate(newDate.getDate() + (offset * 7));
    currentMonday.value = newDate;
  }
};
// --- 核心修改结束 ---

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

// --- 日期和排班表逻辑 (现在是动态的) ---
const weekDates = computed(() => {
  const days = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
  return Array.from({ length: 7 }).map((_, i) => {
    const date = new Date(currentMonday.value);
    date.setDate(date.getDate() + i);

    // 格式化日期 (YYYY-MM-DD)
    const year = date.getFullYear();
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    const day = date.getDate().toString().padStart(2, '0');

    return {
      date: `${year}.${month}.${day}`,
      dayOfWeek: days[i],
      fullDate: `${year}-${month}-${day}`
    }
  });
});

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
  return doctorMaleImg; // 默认头像
};

// --- 拖拽逻辑 (无修改) ---
const onDragStart = (event, doctor, fromDate = null, fromShift = null) => {
  const dragData = { doctorId: doctor.id, doctorName: doctor.name, source: { date: fromDate, shift: fromShift, } };
  event.dataTransfer.setData('application/json', JSON.stringify(dragData));
  event.dataTransfer.effectAllowed = 'move';
};

const onDrop = (event, toDate, toShift) => {
  event.preventDefault();
  const dragData = JSON.parse(event.dataTransfer.getData('application/json'));
  const { doctorId, doctorName, source } = dragData;
  const newDoctor = { id: doctorId, name: doctorName };
  if (source.date && source.shift) {
    if (source.date === toDate && source.shift === toShift) return;
    removeDoctorFromShift(newDoctor, source.date, source.shift, false);
  }
  addDoctorToShift(newDoctor, toDate, toShift);
};

const removeDoctorFromShift = (doctor, date, shift, showMessage = true) => {
  if (!activeSub.value || !scheduleData.value[activeSub.value]) return;
  const shiftEntry = scheduleData.value[activeSub.value].find(s => s.date === date && s.shift === shift);
  if (shiftEntry) {
    const docIndex = shiftEntry.doctors.findIndex(d => d.id === doctor.id);
    if (docIndex > -1) {
      shiftEntry.doctors.splice(docIndex, 1);
      if (showMessage) console.log(`已取消 ${doctor.name} 在 ${date} ${shift} 的排班`);
    }
  }
};

const addDoctorToShift = (doctor, date, shift) => {
  if (!activeSub.value) return;
  if (!scheduleData.value[activeSub.value]) scheduleData.value[activeSub.value] = [];
  let shiftEntry = scheduleData.value[activeSub.value].find(s => s.date === date && s.shift === shift);
  if (!shiftEntry) {
    shiftEntry = { date, shift, doctors: [] };
    scheduleData.value[activeSub.value].push(shiftEntry);
  }
  if (!shiftEntry.doctors.some(d => d.id === doctor.id)) {
    shiftEntry.doctors.push(doctor);
    console.log(`已将 ${doctor.name} 排班到 ${date} ${shift}`);
  }
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
}
.schedule-table th {
  background-color: #f5f7fa;
}
.shift-cell {
  min-height: 80px;
  display: flex;
  flex-direction: column;
  padding: 4px;
}
.shift-label {
  font-weight: bold;
  margin-bottom: 8px;
  color: #909399;
  font-size: 12px;
}
.doctor-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  justify-content: center;
  align-items: center;
  flex-grow: 1;
}
.remove-icon {
  display: none;
  position: absolute;
  top: 2px;
  right: 2px;
  background-color: rgba(255, 255, 255, 0.8);
  border-radius: 50%;
  cursor: pointer;
  font-size: 12px;
  color: #f56c6c;
}
.doctor-list-card {
  margin-top: 20px;
}
.doctor-list {
  display: flex;
  flex-wrap: wrap;
  gap: 16px;
}
.doctor-card {
  display: flex;
  align-items: center;
  background-color: #f9fafb;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  padding: 12px;
  cursor: grab;
  transition: box-shadow 0.2s;
}
.doctor-card:hover {
  box-shadow: 0 4px 6px rgba(0,0,0,0.1);
}
.doctor-avatar {
  width: 48px;
  height: 48px;
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
.doctor-card-in-table {
  display: inline-flex;
  align-items: center;
  padding: 4px 8px;
  border-radius: 6px;
  background-color: #ecf5ff;
  border: 1px solid #d9ecff;
  cursor: grab;
  position: relative;
}
.doctor-card-in-table:hover .remove-icon {
  display: inline-flex;
}
.doctor-avatar-small {
  width: 24px;
  height: 24px;
  border-radius: 50%;
  margin-right: 8px;
}
</style>

