<template>
  <div class="schedule-fee-management">
    <div class="back-area" style="margin-bottom: 12px;">
      <BackButton />
    </div>
    <div class="management-layout">
      <!-- 左侧科室导航 -->
      <div class="department-sidebar">
        <el-menu :default-active="activeParent" class="department-menu" @select="handleParentSelect">
          <el-menu-item v-for="parent in departments" :key="parent.id" :index="parent.id">
            <span>{{ parent.name }}</span>
          </el-menu-item>
        </el-menu>

        <div class="sub-department-panel" v-if="subDepartments.length > 0">
          <div v-for="sub in subDepartments" :key="sub.id" 
               class="sub-department-item" 
               :class="{ 'active': activeSub === sub.id }" 
               @click="handleSubSelect(sub.id)">
            {{ sub.name }}
          </div>
        </div>
      </div>

      <!-- 右侧内容区 -->
      <div class="management-content">
        <!-- 顶部工具栏 -->
        <el-card shadow="always" class="toolbar-card">
          <div class="toolbar">
            <div class="toolbar-left">
              <el-button-group>
                <el-button :icon="ArrowLeft" @click="changeWeek(-1)">上一周</el-button>
                <el-button @click="changeWeek(0)">本周</el-button>
                <el-button :icon="ArrowRight" @click="changeWeek(1)">下一周</el-button>
              </el-button-group>
              <el-divider direction="vertical" />
              <span class="week-info">{{ weekRangeText }}</span>
            </div>
            <div class="toolbar-right">
              <el-button 
                type="primary" 
                :icon="Money" 
                @click="showBatchEditDialog('fee')" 
                :disabled="selectedSchedules.length === 0">
                批量修改费用 ({{ selectedSchedules.length }})
              </el-button>
              <el-button 
                type="success" 
                :icon="Tickets" 
                @click="showBatchEditDialog('slots')" 
                :disabled="selectedSchedules.length === 0">
                批量修改限额 ({{ selectedSchedules.length }})
              </el-button>
              <el-divider direction="vertical" />
              <el-button 
                type="danger" 
                :icon="RefreshLeft" 
                @click="handleResetChanges"
                :disabled="!hasChanges">
                取消修改
              </el-button>
              <el-button 
                type="warning" 
                :icon="Check" 
                @click="handleSaveAll"
                :disabled="!hasChanges">
                保存所有修改 ({{ modifiedCount }})
              </el-button>
            </div>
          </div>
        </el-card>

        <!-- 排班列表 -->
        <el-card shadow="always" class="schedule-card" v-if="activeSub">
          <template #header>
            <div class="card-header">
              <span>{{ selectedDepartmentName }} - 本周排班号别管理</span>
              <el-checkbox v-model="selectAll" @change="handleSelectAll" label="全选" />
            </div>
          </template>

          <el-table 
            ref="tableRef"
            :data="scheduleList" 
            border 
            stripe 
            row-key="scheduleId"
            @selection-change="handleSelectionChange"
            :row-class-name="tableRowClassName"
            :max-height="500">
            <el-table-column type="selection" width="50" />
            <el-table-column prop="scheduleDate" label="日期" width="120">
              <template #default="{ row }">
                <div class="date-cell">
                  <div>{{ formatDate(row.scheduleDate) }}</div>
                  <div class="week-day">{{ getWeekDay(row.scheduleDate) }}</div>
                </div>
              </template>
            </el-table-column>
            <el-table-column label="班次" width="100">
              <template #default="{ row }">
                <el-tag :type="getShift(row.startTime) === '上午' ? 'success' : 'warning'" size="small">
                  {{ getShift(row.startTime) }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="slotName" label="时间段" width="150" />
            <el-table-column prop="doctorName" label="医生" width="120" />
            <el-table-column prop="doctorTitle" label="职称" width="120" />
            <el-table-column prop="location" label="诊室" width="150" />
            
            <!-- 号源限额列 -->
            <el-table-column label="号源限额" width="150" align="center">
              <template #default="{ row }">
                <el-input-number 
                  v-model="row.totalSlots" 
                  :min="1" 
                  :max="100" 
                  size="small"
                  @change="handleSlotsChange(row)"
                  style="width: 120px;"
                />
              </template>
            </el-table-column>

            <!-- 挂号费用列 -->
            <el-table-column label="挂号费用(元)" width="150" align="center">
              <template #default="{ row }">
                <el-input-number 
                  v-model="row.fee" 
                  :min="0" 
                  :max="500" 
                  :precision="2"
                  :step="1"
                  size="small"
                  @change="handleFeeChange(row)"
                  style="width: 120px;"
                />
              </template>
            </el-table-column>

            <el-table-column prop="bookedSlots" label="已预约" width="80" align="center">
              <template #default="{ row }">
                <el-tag :type="row.bookedSlots > 0 ? 'info' : ''" size="small">
                  {{ row.bookedSlots }}
                </el-tag>
              </template>
            </el-table-column>

            <el-table-column label="剩余" width="80" align="center">
              <template #default="{ row }">
                <el-tag :type="getRemainTagType(row)" size="small">
                  {{ row.totalSlots - row.bookedSlots }}
                </el-tag>
              </template>
            </el-table-column>
          </el-table>

          <el-empty v-if="!scheduleList.length" description="本周该科室暂无排班" :image-size="120" />
        </el-card>

        <div v-else class="placeholder">
          <el-empty description="请在左侧选择一个子科室以查看排班" />
        </div>

        <!-- 统计信息 -->
        <el-card shadow="always" class="stats-card" v-if="activeSub && scheduleList.length">
          <div class="stats-grid">
            <div class="stat-item">
              <div class="stat-label">总排班数</div>
              <div class="stat-value">{{ scheduleList.length }}</div>
            </div>
            <div class="stat-item">
              <div class="stat-label">平均费用</div>
              <div class="stat-value stat-warning">¥{{ averageFee }}</div>
            </div>
            <div class="stat-item">
              <div class="stat-label">总号源</div>
              <div class="stat-value stat-success">{{ totalSlots }}</div>
            </div>
            <div class="stat-item">
              <div class="stat-label">已预约</div>
              <div class="stat-value stat-info">{{ totalBooked }}</div>
            </div>
            <div class="stat-item">
              <div class="stat-label">剩余号源</div>
              <div class="stat-value stat-primary">{{ totalSlots - totalBooked }}</div>
            </div>
            <div class="stat-item">
              <div class="stat-label">预约率</div>
              <div class="stat-value stat-danger">{{ bookingRate }}%</div>
            </div>
          </div>
        </el-card>
      </div>
    </div>

    <!-- 批量修改对话框 -->
    <el-dialog 
      v-model="batchEditDialogVisible" 
      :title="batchEditTitle" 
      width="500px">
      <el-form :model="batchForm" label-width="100px">
        <el-form-item label="选中数量">
          <span class="selected-count">{{ selectedSchedules.length }} 条排班</span>
        </el-form-item>
        
        <el-form-item v-if="batchEditType === 'fee'" label="新费用(元)">
          <el-input-number 
            v-model="batchForm.value" 
            :min="0" 
            :max="500" 
            :precision="2"
            :step="5"
            style="width: 100%;"
          />
        </el-form-item>

        <el-form-item v-if="batchEditType === 'slots'" label="新限额(个)">
          <el-input-number 
            v-model="batchForm.value" 
            :min="1" 
            :max="100" 
            :step="5"
            style="width: 100%;"
          />
        </el-form-item>

        <el-alert 
          :title="batchAlertText" 
          type="warning" 
          :closable="false"
          show-icon
        />
      </el-form>
      <template #footer>
        <el-button @click="batchEditDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleBatchSave">确认修改</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue';
import { ArrowLeft, ArrowRight, Money, Tickets, RefreshLeft, Check } from '@element-plus/icons-vue';
import { ElMessage, ElMessageBox } from 'element-plus';
import BackButton from '@/components/BackButton.vue';
// import { getSchedules, batchUpdateSchedules } from '@/api/schedule'; // 等后端接口完成后启用

// --- 科室数据 ---
const departments = ref([
  { id: 'p1', name: '内科', children: [
      { id: 's1-1', name: '呼吸内科' }, 
      { id: 's1-2', name: '心血管内科' },
      { id: 's1-3', name: '消化内科' }
    ]},
  { id: 'p2', name: '外科', children: [ 
      { id: 's2-1', name: '普外科' },
      { id: 's2-2', name: '骨科' }
    ]},
  { id: 'p3', name: '专科', children: [
      { id: 's3-1', name: '口腔科' },
      { id: 's3-2', name: '眼科' }
    ]},
]);

// --- 排班数据（模拟，完全匹配数据库表结构）---
const mockScheduleData = ref({
  's1-2': [
    // === 本周 (2025-10-20 ~ 2025-10-26) ===
    { 
      scheduleId: 1,
      doctorId: 5,
      scheduleDate: '2025-10-20',
      slotId: 3,
      location: '门诊楼201',
      totalSlots: 20,
      bookedSlots: 15,
      fee: 20.00,
      status: 'available',
      remarks: '',
      doctorName: '张主任',
      doctorTitle: '主任医师',
      departmentId: 2,
      slotName: '上午 08:00-12:00',
      startTime: '08:00:00',
      endTime: '12:00:00'
    },
    { 
      scheduleId: 2,
      doctorId: 6,
      scheduleDate: '2025-10-20',
      slotId: 9,
      location: '门诊楼201',
      totalSlots: 30,
      bookedSlots: 8,
      fee: 5.00,
      status: 'available',
      remarks: '',
      doctorName: '李医生',
      doctorTitle: '主治医师',
      departmentId: 2,
      slotName: '下午 14:00-18:00',
      startTime: '14:00:00',
      endTime: '18:00:00'
    },
    { 
      scheduleId: 3,
      doctorId: 7,
      scheduleDate: '2025-10-21',
      slotId: 3,
      location: '门诊楼203',
      totalSlots: 25,
      bookedSlots: 0,
      fee: 15.00,
      status: 'available',
      remarks: '',
      doctorName: '王医生',
      doctorTitle: '副主任医师',
      departmentId: 2,
      slotName: '上午 08:00-12:00',
      startTime: '08:00:00',
      endTime: '12:00:00'
    },
    { 
      scheduleId: 4,
      doctorId: 5,
      scheduleDate: '2025-10-22',
      slotId: 3,
      location: '门诊楼201',
      totalSlots: 20,
      bookedSlots: 12,
      fee: 20.00,
      status: 'available',
      remarks: '',
      doctorName: '张主任',
      doctorTitle: '主任医师',
      departmentId: 2,
      slotName: '上午 08:00-12:00',
      startTime: '08:00:00',
      endTime: '12:00:00'
    },
    { 
      scheduleId: 5,
      doctorId: 6,
      scheduleDate: '2025-10-23',
      slotId: 9,
      location: '门诊楼201',
      totalSlots: 30,
      bookedSlots: 5,
      fee: 5.00,
      status: 'available',
      remarks: '',
      doctorName: '李医生',
      doctorTitle: '主治医师',
      departmentId: 2,
      slotName: '下午 14:00-18:00',
      startTime: '14:00:00',
      endTime: '18:00:00'
    },
    // === 下一周 (2025-10-27 ~ 2025-11-02) ===
    { 
      scheduleId: 6,
      doctorId: 5,
      scheduleDate: '2025-10-27',
      slotId: 3,
      location: '门诊楼201',
      totalSlots: 25,
      bookedSlots: 5,
      fee: 20.00,
      status: 'available',
      remarks: '',
      doctorName: '张主任',
      doctorTitle: '主任医师',
      departmentId: 2,
      slotName: '上午 08:00-12:00',
      startTime: '08:00:00',
      endTime: '12:00:00'
    },
    { 
      scheduleId: 7,
      doctorId: 6,
      scheduleDate: '2025-10-28',
      slotId: 9,
      location: '门诊楼201',
      totalSlots: 35,
      bookedSlots: 10,
      fee: 5.00,
      status: 'available',
      remarks: '',
      doctorName: '李医生',
      doctorTitle: '主治医师',
      departmentId: 2,
      slotName: '下午 14:00-18:00',
      startTime: '14:00:00',
      endTime: '18:00:00'
    },
    { 
      scheduleId: 8,
      doctorId: 7,
      scheduleDate: '2025-10-29',
      slotId: 3,
      location: '门诊楼203',
      totalSlots: 30,
      bookedSlots: 8,
      fee: 15.00,
      status: 'available',
      remarks: '',
      doctorName: '王医生',
      doctorTitle: '副主任医师',
      departmentId: 2,
      slotName: '上午 08:00-12:00',
      startTime: '08:00:00',
      endTime: '12:00:00'
    },
    // === 上一周 (2025-10-13 ~ 2025-10-19) ===
    { 
      scheduleId: 9,
      doctorId: 5,
      scheduleDate: '2025-10-13',
      slotId: 3,
      location: '门诊楼201',
      totalSlots: 20,
      bookedSlots: 18,
      fee: 20.00,
      status: 'available',
      remarks: '',
      doctorName: '张主任',
      doctorTitle: '主任医师',
      departmentId: 2,
      slotName: '上午 08:00-12:00',
      startTime: '08:00:00',
      endTime: '12:00:00'
    },
    { 
      scheduleId: 10,
      doctorId: 6,
      scheduleDate: '2025-10-14',
      slotId: 9,
      location: '门诊楼201',
      totalSlots: 30,
      bookedSlots: 20,
      fee: 5.00,
      status: 'available',
      remarks: '',
      doctorName: '李医生',
      doctorTitle: '主治医师',
      departmentId: 2,
      slotName: '下午 14:00-18:00',
      startTime: '14:00:00',
      endTime: '18:00:00'
    },
  ],
  's3-1': [
    { 
      scheduleId: 11,
      doctorId: 8,
      scheduleDate: '2025-10-20',
      slotId: 3,
      location: '门诊楼305',
      totalSlots: 15,
      bookedSlots: 10,
      fee: 10.00,
      status: 'available',
      remarks: '',
      doctorName: '陈医生',
      doctorTitle: '主治医师',
      departmentId: 5,
      slotName: '上午 08:00-12:00',
      startTime: '08:00:00',
      endTime: '12:00:00'
    },
    { 
      scheduleId: 12,
      doctorId: 9,
      scheduleDate: '2025-10-21',
      slotId: 3,
      location: '门诊楼305',
      totalSlots: 20,
      bookedSlots: 8,
      fee: 15.00,
      status: 'available',
      remarks: '',
      doctorName: '刘医生',
      doctorTitle: '副主任医师',
      departmentId: 5,
      slotName: '上午 08:00-12:00',
      startTime: '08:00:00',
      endTime: '12:00:00'
    },
    { 
      scheduleId: 13,
      doctorId: 8,
      scheduleDate: '2025-10-22',
      slotId: 9,
      location: '门诊楼305',
      totalSlots: 15,
      bookedSlots: 0,
      fee: 10.00,
      status: 'available',
      remarks: '',
      doctorName: '陈医生',
      doctorTitle: '主治医师',
      departmentId: 5,
      slotName: '下午 14:00-18:00',
      startTime: '14:00:00',
      endTime: '18:00:00'
    },
  ]
});

// --- 状态管理 ---
const currentMonday = ref(new Date('2025-10-20'));
const activeParent = ref(null);
const activeSub = ref(null);
const selectedSchedules = ref([]);
const selectAll = ref(false);
const tableRef = ref(null);

// 修改跟踪
const originalData = ref({}); // 保存原始数据
const modifiedSchedules = ref(new Set()); // 记录被修改的排班ID

const batchEditDialogVisible = ref(false);
const batchEditType = ref('fee'); // 'fee' 或 'slots'
const batchForm = ref({
  value: 0
});

// --- 计算属性 ---
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

const scheduleList = computed(() => {
  if (!activeSub.value) return [];
  const allSchedules = mockScheduleData.value[activeSub.value] || [];
  
  // 计算当前周的日期范围
  const weekStart = new Date(currentMonday.value);
  const weekEnd = new Date(currentMonday.value);
  weekEnd.setDate(weekEnd.getDate() + 6); // 周一到周日（7天）
  
  // 过滤出本周的排班数据
  return allSchedules.filter(schedule => {
    const scheduleDate = new Date(schedule.scheduleDate);
    return scheduleDate >= weekStart && scheduleDate <= weekEnd;
  });
});

// 【后端接口完成后启用】
// /**
//  * 加载排班数据（从后端获取）
//  */
// const loadSchedules = async () => {
//   if (!activeSub.value) return;
//   
//   loading.value = true;
//   try {
//     const weekStart = new Date(currentMonday.value);
//     const weekEnd = new Date(currentMonday.value);
//     weekEnd.setDate(weekEnd.getDate() + 6);
//     
//     const response = await getSchedules({
//       departmentId: activeSub.value,
//       startDate: formatDateForAPI(weekStart),
//       endDate: formatDateForAPI(weekEnd)
//     });
//     
//     // 将后端数据存储到 mockScheduleData 中对应的科室
//     if (!mockScheduleData.value[activeSub.value]) {
//       mockScheduleData.value[activeSub.value] = [];
//     }
//     mockScheduleData.value[activeSub.value] = response.data;
//     
//   } catch (error) {
//     ElMessage.error('加载排班数据失败：' + (error.message || '未知错误'));
//   } finally {
//     loading.value = false;
//   }
// };
// 
// // 格式化日期为 API 需要的格式 (YYYY-MM-DD)
// const formatDateForAPI = (date) => {
//   const year = date.getFullYear();
//   const month = (date.getMonth() + 1).toString().padStart(2, '0');
//   const day = date.getDate().toString().padStart(2, '0');
//   return `${year}-${month}-${day}`;
// };

const weekRangeText = computed(() => {
  const start = new Date(currentMonday.value);
  const end = new Date(currentMonday.value);
  end.setDate(end.getDate() + 6);
  return `${formatDateShort(start)} - ${formatDateShort(end)}`;
});

const batchEditTitle = computed(() => {
  return batchEditType.value === 'fee' ? '批量修改费用' : '批量修改号源限额';
});

const batchAlertText = computed(() => {
  const text = batchEditType.value === 'fee' ? '费用' : '号源限额';
  const unit = batchEditType.value === 'fee' ? '元' : '个';
  return `将为选中的 ${selectedSchedules.value.length} 条排班统一设置${text}为 ${batchForm.value.value} ${unit}`;
});

// 统计
const averageFee = computed(() => {
  if (scheduleList.value.length === 0) return '0.00';
  const sum = scheduleList.value.reduce((acc, cur) => acc + cur.fee, 0);
  return (sum / scheduleList.value.length).toFixed(2);
});

const totalSlots = computed(() => {
  return scheduleList.value.reduce((acc, cur) => acc + cur.totalSlots, 0);
});

const totalBooked = computed(() => {
  return scheduleList.value.reduce((acc, cur) => acc + cur.bookedSlots, 0);
});

const bookingRate = computed(() => {
  if (totalSlots.value === 0) return '0';
  return ((totalBooked.value / totalSlots.value) * 100).toFixed(1);
});

// 是否有修改
const hasChanges = computed(() => {
  return modifiedSchedules.value.size > 0;
});

// 修改数量
const modifiedCount = computed(() => {
  return modifiedSchedules.value.size;
});

// --- 方法 ---
const tableRowClassName = ({ row }) => {
  return modifiedSchedules.value.has(row.scheduleId) ? 'modified-row' : '';
};

const getShift = (startTime) => {
  if (!startTime) return '';
  const hour = parseInt(startTime.split(':')[0]);
  return hour < 12 ? '上午' : hour < 18 ? '下午' : '晚上';
};

const formatDate = (dateStr) => {
  const date = new Date(dateStr);
  const month = (date.getMonth() + 1).toString().padStart(2, '0');
  const day = date.getDate().toString().padStart(2, '0');
  return `${month}月${day}日`;
};

const formatDateShort = (date) => {
  const month = (date.getMonth() + 1).toString().padStart(2, '0');
  const day = date.getDate().toString().padStart(2, '0');
  return `${month}/${day}`;
};

const getWeekDay = (dateStr) => {
  const days = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
  const date = new Date(dateStr);
  return days[date.getDay()];
};

const getRemainTagType = (row) => {
  const remain = row.totalSlots - row.bookedSlots;
  if (remain === 0) return 'danger';
  if (remain < 5) return 'warning';
  return 'success';
};

const changeWeek = (offset) => {
  // 检查是否有未保存的修改
  if (modifiedSchedules.value.size > 0) {
    ElMessageBox.confirm(
      `当前有 ${modifiedSchedules.value.size} 条未保存的修改，切换周次将丢失这些修改，是否继续？`,
      '提示',
      {
        confirmButtonText: '继续',
        cancelButtonText: '取消',
        type: 'warning',
      }
    ).then(() => {
      if (offset === 0) {
        currentMonday.value = new Date('2025-10-20');
      } else {
        const newDate = new Date(currentMonday.value);
        newDate.setDate(newDate.getDate() + (offset * 7));
        currentMonday.value = newDate;
      }
      // 切换周次时清除选择
      selectedSchedules.value = [];
      selectAll.value = false;
      if (tableRef.value) {
        tableRef.value.clearSelection();
      }
      // 【后端接口完成后启用】加载新周次的数据
      // loadSchedules();
      // 保存新周次的原始数据
      setTimeout(() => {
        saveOriginalData();
      }, 100);
    }).catch(() => {
      // 取消切换
    });
  } else {
    if (offset === 0) {
      currentMonday.value = new Date('2025-10-20');
    } else {
      const newDate = new Date(currentMonday.value);
      newDate.setDate(newDate.getDate() + (offset * 7));
      currentMonday.value = newDate;
    }
    // 切换周次时清除选择
    selectedSchedules.value = [];
    selectAll.value = false;
    if (tableRef.value) {
      tableRef.value.clearSelection();
    }
    // 【后端接口完成后启用】加载新周次的数据
    // loadSchedules();
    // 保存新周次的原始数据
    setTimeout(() => {
      saveOriginalData();
    }, 100);
  }
};

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
  selectedSchedules.value = [];
  selectAll.value = false;
  // 切换科室时清除表格选择
  if (tableRef.value) {
    tableRef.value.clearSelection();
  }
};

const handleSubSelect = (id) => {
  // 检查是否有未保存的修改
  if (modifiedSchedules.value.size > 0) {
    ElMessageBox.confirm(
      `当前有 ${modifiedSchedules.value.size} 条未保存的修改，切换科室将丢失这些修改，是否继续？`,
      '提示',
      {
        confirmButtonText: '继续',
        cancelButtonText: '取消',
        type: 'warning',
      }
    ).then(() => {
      activeSub.value = id;
      selectedSchedules.value = [];
      selectAll.value = false;
      // 切换科室时清除表格选择
      if (tableRef.value) {
        tableRef.value.clearSelection();
      }
      // 【后端接口完成后启用】加载新科室的数据
      // loadSchedules();
      // 保存新科室的原始数据
      setTimeout(() => {
        saveOriginalData();
      }, 100);
    }).catch(() => {
      // 取消切换
    });
  } else {
    activeSub.value = id;
    selectedSchedules.value = [];
    selectAll.value = false;
    // 切换科室时清除表格选择
    if (tableRef.value) {
      tableRef.value.clearSelection();
    }
    // 【后端接口完成后启用】加载新科室的数据
    // loadSchedules();
    // 保存新科室的原始数据
    setTimeout(() => {
      saveOriginalData();
    }, 100);
  }
};

const handleSelectionChange = (selection) => {
  selectedSchedules.value = selection;
  selectAll.value = selection.length === scheduleList.value.length && scheduleList.value.length > 0;
};

const handleSelectAll = (val) => {
  if (tableRef.value) {
    if (val) {
      scheduleList.value.forEach(row => {
        tableRef.value.toggleRowSelection(row, true);
      });
    } else {
      tableRef.value.clearSelection();
    }
  }
};

const handleFeeChange = (row) => {
  // 检查是否与原始数据不同
  const original = originalData.value[row.scheduleId];
  if (original && original.fee !== row.fee) {
    modifiedSchedules.value.add(row.scheduleId);
  } else if (original && original.fee === row.fee) {
    modifiedSchedules.value.delete(row.scheduleId);
  }
};

const handleSlotsChange = (row) => {
  if (row.totalSlots < row.bookedSlots) {
    ElMessage.warning(`号源限额不能小于已预约数(${row.bookedSlots})，已自动调整`);
    row.totalSlots = row.bookedSlots;
    return;
  }
  // 检查是否与原始数据不同
  const original = originalData.value[row.scheduleId];
  if (original && original.totalSlots !== row.totalSlots) {
    modifiedSchedules.value.add(row.scheduleId);
  } else if (original && original.totalSlots === row.totalSlots) {
    modifiedSchedules.value.delete(row.scheduleId);
  }
};

const showBatchEditDialog = (type) => {
  if (selectedSchedules.value.length === 0) {
    ElMessage.warning('请先选择要修改的排班');
    return;
  }
  batchEditType.value = type;
  batchForm.value.value = type === 'fee' ? 10.00 : 20;
  batchEditDialogVisible.value = true;
};

const handleBatchSave = () => {
  const fieldName = batchEditType.value === 'fee' ? 'fee' : 'totalSlots';
  const text = batchEditType.value === 'fee' ? '费用' : '号源限额';
  
  selectedSchedules.value.forEach(schedule => {
    // 如果是修改号源，检查是否小于已预约数
    if (batchEditType.value === 'slots' && batchForm.value.value < schedule.bookedSlots) {
      ElMessage.warning(`${schedule.doctorName} 的已预约数为 ${schedule.bookedSlots}，限额不能小于此值`);
      return;
    }
    schedule[fieldName] = batchForm.value.value;
    
    // 标记为已修改
    const original = originalData.value[schedule.scheduleId];
    if (original) {
      if (batchEditType.value === 'fee' && original.fee !== schedule.fee) {
        modifiedSchedules.value.add(schedule.scheduleId);
      } else if (batchEditType.value === 'slots' && original.totalSlots !== schedule.totalSlots) {
        modifiedSchedules.value.add(schedule.scheduleId);
      }
    }
  });
  
  ElMessage.info(`已批量修改 ${selectedSchedules.value.length} 条排班的${text}，请点击"保存所有修改"按钮保存`);
  batchEditDialogVisible.value = false;
  selectedSchedules.value = [];
  selectAll.value = false;
  // 清除表格选择
  if (tableRef.value) {
    tableRef.value.clearSelection();
  }
};

// 保存原始数据
const saveOriginalData = () => {
  originalData.value = {};
  scheduleList.value.forEach(schedule => {
    originalData.value[schedule.scheduleId] = {
      fee: schedule.fee,
      totalSlots: schedule.totalSlots
    };
  });
  modifiedSchedules.value.clear();
};

// 保存所有修改
const handleSaveAll = () => {
  if (modifiedSchedules.value.size === 0) {
    ElMessage.warning('没有需要保存的修改');
    return;
  }

  ElMessageBox.confirm(
    `确定要保存 ${modifiedSchedules.value.size} 条排班的修改吗？`,
    '确认保存',
    {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning',
    }
  ).then(async () => {
    // 准备要保存的数据（只包含修改过的排班）
    const updates = [];
    modifiedSchedules.value.forEach(scheduleId => {
      const schedule = scheduleList.value.find(s => s.scheduleId === scheduleId);
      if (schedule) {
        updates.push({
          scheduleId: schedule.scheduleId,  // 后端接口字段名
          fee: schedule.fee,
          totalSlots: schedule.totalSlots
        });
      }
    });
    
    // 【模拟保存】等后端接口完成后删除
    console.log('准备保存的数据：', updates);
    ElMessage.success(`成功保存 ${modifiedSchedules.value.size} 条排班的修改`);
    saveOriginalData();
    
    // 【后端接口完成后启用】
    // try {
    //   await batchUpdateSchedules({ updates });
    //   ElMessage.success(`成功保存 ${modifiedSchedules.value.size} 条排班的修改`);
    //   saveOriginalData();
    //   // 可选：重新加载数据
    //   // await loadSchedules();
    // } catch (error) {
    //   ElMessage.error('保存失败：' + (error.message || '未知错误'));
    // }
  }).catch(() => {
    // 取消保存
  });
};

// 取消所有修改
const handleResetChanges = () => {
  if (modifiedSchedules.value.size === 0) {
    return;
  }

  ElMessageBox.confirm(
    `确定要取消 ${modifiedSchedules.value.size} 条排班的修改吗？`,
    '确认取消',
    {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning',
    }
  ).then(() => {
    // 恢复原始数据
    scheduleList.value.forEach(schedule => {
      const original = originalData.value[schedule.scheduleId];
      if (original && modifiedSchedules.value.has(schedule.scheduleId)) {
        schedule.fee = original.fee;
        schedule.totalSlots = original.totalSlots;
      }
    });
    
    modifiedSchedules.value.clear();
    ElMessage.info('已取消所有修改');
  }).catch(() => {
    // 取消操作
  });
};

onMounted(() => {
  if (departments.value.length > 0) {
    handleParentSelect(departments.value[0].id);
    // 【后端接口完成后启用】初始加载时从后端获取数据
    // loadSchedules();
    // 初始加载时保存原始数据
    setTimeout(() => {
      saveOriginalData();
    }, 200);
  }
});
</script>

<style scoped>
.schedule-fee-management {
  padding: 20px;
  background-color: #f7fafc;
  min-height: calc(100vh - 50px);
}

.management-layout {
  display: flex;
  height: calc(100vh - 100px);
}

.department-sidebar {
  width: 320px;
  display: flex;
  background-color: #fff;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
  flex-shrink: 0;
  margin-right: 20px;
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
  transition: all 0.2s;
}

.sub-department-item:hover {
  background-color: #f5f7fa;
}

.sub-department-item.active {
  background-color: #ecf5ff;
  color: #409eff;
  font-weight: bold;
}

.management-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 20px;
  overflow: auto;
}

.toolbar-card {
  flex-shrink: 0;
}

.toolbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.toolbar-left {
  display: flex;
  align-items: center;
  gap: 15px;
}

.toolbar-right {
  display: flex;
  gap: 10px;
}

.week-info {
  font-size: 14px;
  color: #606266;
  font-weight: 500;
}

.schedule-card {
  flex: 1;
  overflow: auto;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 16px;
  font-weight: bold;
}

.date-cell {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.week-day {
  font-size: 12px;
  color: #909399;
}

.placeholder {
  display: flex;
  justify-content: center;
  align-items: center;
  height: 300px;
}

.stats-card {
  flex-shrink: 0;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(6, 1fr);
  gap: 15px;
}

.stat-item {
  text-align: center;
  padding: 15px;
  background-color: #f9fafb;
  border-radius: 8px;
  transition: all 0.3s;
}

.stat-item:hover {
  background-color: #ecf5ff;
  transform: translateY(-2px);
}

.stat-label {
  font-size: 14px;
  color: #909399;
  margin-bottom: 8px;
}

.stat-value {
  font-size: 24px;
  font-weight: bold;
  color: #606266;
}

.stat-value.stat-success {
  color: #67c23a;
}

.stat-value.stat-warning {
  color: #f59e0b;
}

.stat-value.stat-info {
  color: #909399;
}

.stat-value.stat-primary {
  color: #409eff;
}

.stat-value.stat-danger {
  color: #f56c6c;
}

.selected-count {
  font-size: 16px;
  font-weight: bold;
  color: #409eff;
}

/* 已修改行高亮 */
:deep(.modified-row) {
  background-color: #fff7e6 !important;
}

:deep(.modified-row:hover) {
  background-color: #ffe7ba !important;
}
</style>

