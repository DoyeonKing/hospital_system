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

      <el-table
          v-loading="loading"
          :data="patientList"
          style="width: 100%; margin-top: 20px;"
          border
          stripe
          @sort-change="handleSortChange"
          :default-sort="{ prop: 'appointmentNumber', order: 'ascending' }"
          class="custom-table"
      >
        <el-table-column type="index" label="序号" width="60" align="center" />

        <el-table-column
            prop="appointmentNumber"
            label="就诊序号"
            width="110"
            align="center"
            sortable="custom"
        />

        <el-table-column prop="patient.fullName" label="姓名" width="120" />

        <el-table-column label="患者类型" width="100">
          <template #default="{ row }">
            <el-tag :type="getPatientTypeTag(row.patient?.patientType)">
              {{ formatPatientType(row.patient?.patientType) }}
            </el-tag>
          </template>
        </el-table-column>

        <el-table-column prop="patient.phoneNumber" label="手机号" width="130" />

        <el-table-column
            prop="checkInTime"
            label="现场签到时间"
            width="170"
            sortable="custom"
        >
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
              <span class="text-truncate">
                {{ row.patient?.patientProfile?.allergies || '无' }}
              </span>
            </el-tooltip>
          </template>
        </el-table-column>

        <el-table-column label="基础病史" min-width="180">
          <template #default="{ row }">
            <el-tooltip effect="dark" :content="row.patient?.patientProfile?.medicalHistory || '无'" placement="top">
              <span class="text-truncate">
                {{ row.patient?.patientProfile?.medicalHistory || '无' }}
              </span>
            </el-tooltip>
          </template>
        </el-table-column>

        <el-table-column label="操作" width="220" fixed="right" align="center">
          <template #default="{ row }">
            <el-button type="primary" link size="small" :icon="Edit" @click="handleWriteRecord(row)">
              写病历
            </el-button>
            <el-button type="info" link size="small" :icon="View" @click="handleViewDetails(row)" style="font-size: 14px; margin-left: 8px;">
              查看患者信息
            </el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-pagination
          v-if="totalElements > 0"
          layout="total, sizes, prev, pager, next, jumper"
          :total="totalElements"
          :page-sizes="[10, 20, 50, 100]"
          :page-size="pageSize"
          :current-page="currentPage"
          @size-change="handleSizeChange"
          @current-change="handleCurrentChange"
          style="margin-top: 20px; justify-content: flex-end;"
      />

      <el-empty v-if="!loading && patientList.length === 0" description="当日暂无患者" :image-size="120" />

    </el-card>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue';
import { ElMessage } from 'element-plus';
import { Search, Refresh, Edit, View } from '@element-plus/icons-vue';
import BackButton from '@/components/BackButton.vue';
import { getTodaysPatients } from '@/api/patient'; // 导入 API
import { useRouter } from 'vue-router';

// --- 格式化辅助函数 (已移到顶部) ---
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

// --- 状态 ---
const router = useRouter();
const loading = ref(false);
const patientList = ref([]);
const selectedDate = ref(formatDateForAPI(new Date()));
const searchQuery = ref('');

// --- 分页状态 ---
const currentPage = ref(1);
const pageSize = ref(10);
const totalElements = ref(0);

// --- 排序状态 ---
const sortField = ref('appointmentNumber');
const sortOrder = ref('asc');

// --- 【已修改】数据获取 (增加了虚拟数据的前端排序) ---
const fetchPatients = async () => {
  loading.value = true;

  // 模拟网络延迟
  await new Promise(resolve => setTimeout(resolve, 500));

  try {
    // --- 【虚拟数据】 ---
    // 1. 虚拟数据列表
    const mockPatientData = [
      {
        appointmentId: 1,
        appointmentNumber: 1,
        checkInTime: '2025-11-17T09:05:00',
        status: 'scheduled',
        patient: {
          patientId: 101,
          fullName: '张三 (虚拟)',
          patientType: 'student',
          phoneNumber: '13800138001',
          patientProfile: {
            allergies: '青霉素过敏',
            medicalHistory: '无'
          }
        }
      },
      {
        appointmentId: 2,
        appointmentNumber: 2,
        checkInTime: null, // 未签到
        status: 'scheduled',
        patient: {
          patientId: 102,
          fullName: '李四 (虚拟)',
          patientType: 'teacher',
          phoneNumber: '13900139002',
          patientProfile: {
            allergies: '无',
            medicalHistory: '高血压, 需常年服药'
          }
        }
      },
      {
        appointmentId: 3,
        appointmentNumber: 3,
        checkInTime: '2025-11-17T09:15:00', // 签到时间晚
        status: 'completed',
        patient: {
          patientId: 103,
          fullName: '王五 (虚拟)',
          patientType: 'staff',
          phoneNumber: '13700137003',
          patientProfile: {
            allergies: '花粉, 芒果',
            medicalHistory: '糖尿病'
          }
        }
      },
      {
        appointmentId: 4,
        appointmentNumber: 4,
        checkInTime: '2025-11-17T09:02:00', // 签到时间早
        status: 'scheduled',
        patient: {
          patientId: 104,
          fullName: '赵六 (虚拟)',
          patientType: 'student',
          phoneNumber: '13600136004',
          patientProfile: {
            allergies: '无',
            medicalHistory: '无'
          }
        }
      },
      {
        appointmentId: 5,
        appointmentNumber: 5,
        checkInTime: null, // 未签到
        status: 'no_show',
        patient: {
          patientId: 105,
          fullName: '孙七 (虚拟)',
          patientType: 'student',
          phoneNumber: '13500135005',
          patientProfile: {
            allergies: '无',
            medicalHistory: '无'
          }
        }
      }
    ];

    // 2. 【修改】应用搜索
    let filteredData = mockPatientData.filter(p =>
        p.patient.fullName.includes(searchQuery.value) ||
        p.patient.phoneNumber.includes(searchQuery.value)
    );

    // 3. 【新增】应用排序
    filteredData.sort((a, b) => {
      const field = sortField.value;
      const order = sortOrder.value;

      let valA, valB;

      if (field === 'appointmentNumber') {
        valA = a.appointmentNumber;
        valB = b.appointmentNumber;
        return order === 'asc' ? valA - valB : valB - valA;
      }

      if (field === 'checkInTime') {
        valA = a.checkInTime;
        valB = b.checkInTime;

        // 核心排序逻辑：未签到(null)的总是排在最后
        if (valA === null && valB === null) return 0; // 两个都未签到
        if (valA === null) return 1; // a未签到, 排在b后面
        if (valB === null) return -1; // b未签到, 排在a后面

        // 两个都已签到, 按时间排序
        const dateA = new Date(valA);
        const dateB = new Date(valB);
        return order === 'asc' ? dateA - dateB : dateB - dateA;
      }

      return 0;
    });

    // 4. 【修改】应用分页
    patientList.value = filteredData.slice(
        (currentPage.value - 1) * pageSize.value,
        currentPage.value * pageSize.value
    );
    totalElements.value = filteredData.length;

    // --- 【真实接口 - 已注释】 ---
    // (当您准备好对接后端时，请删除上面的虚拟数据代码，并取消注释下面的代码)
    // const params = {
    //   date: selectedDate.value,
    //   query: searchQuery.value || null,
    //   page: currentPage.value - 1,
    //   size: pageSize.value,
    //   sort: `${sortField.value},${sortOrder.value}`
    // };
    // const response = await getTodaysPatients(params);
    // patientList.value = response.content || [];
    // totalElements.value = response.totalElements || 0;
    // --- 【真实接口结束】 ---

  } catch (error) {
    ElMessage.error('加载患者列表失败：' + (error.message || '未知错误'));
    patientList.value = [];
    totalElements.value = 0;
  } finally {
    loading.value = false;
  }
};

// --- 事件处理 ---
const handleSearch = () => {
  currentPage.value = 1; // 搜索时重置到第一页
  fetchPatients();
};

const handleSortChange = ({ prop, order }) => {
  // prop 是列的 prop 属性, order 是 'ascending' 或 'descending'
  sortField.value = prop;
  sortOrder.value = order === 'ascending' ? 'asc' : 'desc';
  // 【修改】现在调用 fetchPatients() 会触发前端排序
  fetchPatients();
};

const handleSizeChange = (newSize) => {
  pageSize.value = newSize;
  currentPage.value = 1; // 切换size时重置到第一页
  fetchPatients();
};

const handleCurrentChange = (newPage) => {
  currentPage.value = newPage;
  fetchPatients();
};

// --- 操作按钮 ---
const handleWriteRecord = (row) => {
  ElMessage.info(`正在为【${row.patient.fullName}】编写病历...`);
  // router.push(`/medical-record/${row.appointmentId}`); // 假设的病历页面
};

const handleViewDetails = (row) => {
  ElMessage.info(`正在查看【${row.patient.fullName}】的详细资料...`);
  // router.push(`/patient-detail/${row.patient.patientId}`); // 假设的详情页面
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

/* 【新增】优化表格字体大小和行高 */
.custom-table :deep(.el-table__cell) {
  font-size: 14px;
  padding: 12px 0;
}
.custom-table :deep(th.el-table__cell) {
  font-size: 14px;
  background-color: #f5f7fa;
}
</style>