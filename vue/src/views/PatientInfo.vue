<template>
  <div class="app-container">
    <div class="back-area" style="margin-bottom: 12px;">
      <BackButton />
    </div>

    <el-card shadow="always" class="patient-card">
      <template #header>
        <div class="card-header">
          <span>患者管理</span>
          <el-date-picker
              v-model="selectedDate"
              type="date"
              placeholder="选择日期"
              format="YYYY-MM-DD"
              value-format="YYYY-MM-DD"
              @change="handleSearch"
              style="width: 150px; margin-left: 20px;"
          />
        </div>
      </template>

      <div class="toolbar">
        <el-input
            v-model="searchQuery"
            placeholder="搜索患者姓名、手机号..."
            class="search-input"
            :prefix-icon="Search"
            @keyup.enter="handleSearch"
            clearable
            @clear="handleSearch"
        />
        <el-button
            type="primary"
            :icon="Refresh"
            @click="fetchPatients"
            :loading="loading">
          刷新
        </el-button>
      </div>

      <!-- 上午排班 -->
      <div class="schedule-section">
        <div class="section-header morning-header">
          <span class="section-title"> 上午排班</span>
          <span class="patient-count">{{ morningPatients.length }} 人</span>
        </div>
        <el-table
            v-loading="loading"
            :data="morningPatients"
            style="width: 100%;"
            border
            stripe
        >
          <el-table-column type="index" label="序号" width="60" align="center" />
          <el-table-column prop="appointmentNumber" label="就诊序号" width="110" align="center" />
          <el-table-column prop="patient.fullName" label="姓名" width="100" />
          <el-table-column label="患者类型" width="100">
            <template #default="{ row }">
              <el-tag :type="getPatientTypeTag(row.patient?.patientType)">
                {{ formatPatientType(row.patient?.patientType) }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="patient.phoneNumber" label="手机号" width="130" />
          <el-table-column prop="checkInTime" label="现场签到时间" width="170">
            <template #default="{ row }">
              <span :class="{'checked-in': !!row.checkInTime}">
                {{ formatDateTime(row.checkInTime) || '未签到' }}
              </span>
            </template>
          </el-table-column>
          <el-table-column prop="status" label="预约状态" width="110" align="center">
            <template #default="{ row }">
              <el-tag :type="getStatusTag(row.status)" size="small">
                {{ formatStatus(row.status) }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column label="过敏史" width="150">
            <template #default="{ row }">
              <el-tooltip effect="dark" :content="row.patient?.patientProfile?.allergies || '无'" placement="top">
                <span class="text-truncate">{{ row.patient?.patientProfile?.allergies || '无' }}</span>
              </el-tooltip>
            </template>
          </el-table-column>
          <el-table-column label="基础病史" min-width="180">
            <template #default="{ row }">
              <el-tooltip effect="dark" :content="row.patient?.patientProfile?.medicalHistory || '无'" placement="top">
                <span class="text-truncate">{{ row.patient?.patientProfile?.medicalHistory || '无' }}</span>
              </el-tooltip>
            </template>
          </el-table-column>
        </el-table>
        <el-empty v-if="!loading && morningPatients.length === 0" description="上午暂无患者" :image-size="100" />
      </div>

      <!-- 下午排班 -->
      <div class="schedule-section">
        <div class="section-header afternoon-header">
          <span class="section-title"> 下午排班</span>
          <span class="patient-count">{{ afternoonPatients.length }} 人</span>
        </div>
        <el-table
            v-loading="loading"
            :data="afternoonPatients"
            style="width: 100%;"
            border
            stripe
        >
          <el-table-column type="index" label="序号" width="60" align="center" />
          <el-table-column prop="appointmentNumber" label="就诊序号" width="110" align="center" />
          <el-table-column prop="patient.fullName" label="姓名" width="100" />
          <el-table-column label="患者类型" width="100">
            <template #default="{ row }">
              <el-tag :type="getPatientTypeTag(row.patient?.patientType)">
                {{ formatPatientType(row.patient?.patientType) }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="patient.phoneNumber" label="手机号" width="130" />
          <el-table-column prop="checkInTime" label="现场签到时间" width="170">
            <template #default="{ row }">
              <span :class="{'checked-in': !!row.checkInTime}">
                {{ formatDateTime(row.checkInTime) || '未签到' }}
              </span>
            </template>
          </el-table-column>
          <el-table-column prop="status" label="预约状态" width="110" align="center">
            <template #default="{ row }">
              <el-tag :type="getStatusTag(row.status)" size="small">
                {{ formatStatus(row.status) }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column label="过敏史" width="150">
            <template #default="{ row }">
              <el-tooltip effect="dark" :content="row.patient?.patientProfile?.allergies || '无'" placement="top">
                <span class="text-truncate">{{ row.patient?.patientProfile?.allergies || '无' }}</span>
              </el-tooltip>
            </template>
          </el-table-column>
          <el-table-column label="基础病史" min-width="180">
            <template #default="{ row }">
              <el-tooltip effect="dark" :content="row.patient?.patientProfile?.medicalHistory || '无'" placement="top">
                <span class="text-truncate">{{ row.patient?.patientProfile?.medicalHistory || '无' }}</span>
              </el-tooltip>
            </template>
          </el-table-column>
        </el-table>
        <el-empty v-if="!loading && afternoonPatients.length === 0" description="下午暂无患者" :image-size="100" />
      </div>

      <el-empty v-if="!loading && allPatients.length === 0" description="当日暂无患者" :image-size="120" />

    </el-card>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue';
import { ElMessage } from 'element-plus';
import { Search, Refresh } from '@element-plus/icons-vue';
import BackButton from '@/components/BackButton.vue';
import { getTodaysPatients } from '@/api/patient';
import { useRouter } from 'vue-router';
import { useDoctorStore } from '@/stores/doctorStore';

const formatDateForAPI = (date) => {
  const year = date.getFullYear();
  const month = (date.getMonth() + 1).toString().padStart(2, '0');
  const day = date.getDate().toString().padStart(2, '0');
  return `${year}-${month}-${day}`;
};

const formatDateTime = (dateTimeStr) => {
  if (!dateTimeStr) return '';
  const date = new Date(dateTimeStr);
  return date.toLocaleString('zh-CN', { hour12: false });
};

const formatPatientType = (type) => {
  const types = {
    'student': '学生',
    'teacher': '教师',
    'staff': '职工'
  };
  return types[type] || '未知';
};

const getPatientTypeTag = (type) => {
  const tags = {
    'student': 'success',
    'teacher': 'warning',
    'staff': 'info'
  };
  return tags[type] || 'default';
};

const formatStatus = (status) => {
  const statuses = {
    'scheduled': '已预约',
    'completed': '已完成',
    'cancelled': '已取消',
    'no_show': '爽约'
  };
  return statuses[status] || '未知';
};

const getStatusTag = (status) => {
  const tags = {
    'scheduled': 'primary',
    'completed': 'success',
    'cancelled': 'info',
    'no_show': 'danger'
  };
  return tags[status] || 'default';
};

const router = useRouter();
const doctorStore = useDoctorStore();
const loading = ref(false);
const allPatients = ref([]);
const selectedDate = ref(formatDateForAPI(new Date()));
const searchQuery = ref('');

const morningPatients = computed(() => {
  return allPatients.value.filter(p => {
    if (!p.startTime) return false;
    const hour = parseInt(p.startTime.split(':')[0]);
    return hour < 12;
  });
});

const afternoonPatients = computed(() => {
  return allPatients.value.filter(p => {
    if (!p.startTime) return false;
    const hour = parseInt(p.startTime.split(':')[0]);
    return hour >= 12;
  });
});

const fetchPatients = async () => {
  loading.value = true;

  try {
    const savedInfo = JSON.parse(localStorage.getItem('xm-pro-doctor'))
    const doctorId = savedInfo?.doctorId || doctorStore.currentDoctorId;
    
    if (!doctorId) {
      ElMessage.error('无法获取医生ID，请重新登录');
      loading.value = false;
      return;
    }
    
    console.log('=== 获取患者列表 ===');
    console.log('doctorId:', doctorId);
    console.log('date:', selectedDate.value);
    
    const response = await getTodaysPatients(doctorId, selectedDate.value);
    console.log('API响应:', response);
    
    let patients = Array.isArray(response) ? response : [];
    
    if (searchQuery.value) {
      patients = patients.filter(p =>
          (p.patient?.fullName || '').includes(searchQuery.value) ||
          (p.patient?.phoneNumber || '').includes(searchQuery.value)
      );
    }
    
    allPatients.value = patients;
    console.log('患者列表:', allPatients.value);
    console.log('上午患者:', morningPatients.value.length);
    console.log('下午患者:', afternoonPatients.value.length);
    
  } catch (error) {
    ElMessage.error('加载患者列表失败：' + (error.message || '未知错误'));
    allPatients.value = [];
  } finally {
    loading.value = false;
  }
};

const handleSearch = () => {
  fetchPatients();
};

// --- 生命周期 ---
onMounted(() => {
  fetchPatients();
});
</script>

<style scoped>
.app-container {
  padding: 24px;
  background-color: #f7fafc;
  min-height: calc(100vh - 50px);
}
.patient-card {
  flex: 1;
  overflow: auto;
}
.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 18px;
  font-weight: bold;
}
.toolbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.search-input {
  max-width: 300px;
}
.text-truncate {
  display: -webkit-box;
  -webkit-box-orient: vertical;
  -webkit-line-clamp: 2; /* 最多显示2行 */
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: normal;
  line-height: 1.5;
}

.checked-in {
  color: var(--el-color-success);
  font-weight: bold;
}

/* 排班区域样式 */
.schedule-section {
  margin-top: 24px;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 16px;
  margin-bottom: 12px;
  border-radius: 8px;
  font-weight: bold;
}

.morning-header {
  background: linear-gradient(135deg, #a8edea 0%, #fed6e3 100%);
  color: #2c3e50;
}

.afternoon-header {
  background: linear-gradient(135deg, #ffecd2 0%, #fcb69f 100%);
  color: #2c3e50;
}

.section-title {
  font-size: 16px;
  display: flex;
  align-items: center;
  gap: 8px;
}

.patient-count {
  font-size: 14px;
  padding: 4px 12px;
  background: rgba(255, 255, 255, 0.8);
  border-radius: 12px;
  color: #606266;
}
</style>
