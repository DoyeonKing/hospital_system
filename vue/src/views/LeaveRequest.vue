<template>
  <div class="app-container">
    <div class="back-area" style="margin-bottom: 12px;">
      <BackButton />
    </div>

    <el-card shadow="always" class="leave-card">
      <template #header>
        <div class="card-header">
          <span>我的休假申请</span>
          <el-button
              type="primary"
              :icon="Plus"
              @click="openApplyDialog">
            申请休假
          </el-button>
        </div>
      </template>

      <el-table
          v-loading="loading"
          :data="leaveHistory"
          style="width: 100%; margin-top: 20px;"
          border
          stripe
      >
        <el-table-column prop="requestType" label="假期类型" width="120">
          <template #default="{ row }">
            <el-tag :type="row.requestType === 'SICK_LEAVE' ? 'warning' : 'info'">
              {{ formatRequestType(row.requestType) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="startDate" label="开始日期" width="150" sortable />
        <el-table-column prop="endDate" label="结束日期" width="150" sortable />
        <el-table-column prop="reason" label="请假事由" min-width="250" />
        <el-table-column prop="status" label="审批状态" width="120" align="center">
          <template #default="{ row }">
            <el-tag :type="getStatusTag(row.status)">
              {{ formatStatus(row.status) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="120" align="center">
          <template #default="{ row }">
            <el-button
                type="danger"
                link
                size="small"
                :icon="Delete"
                @click="handleCancel(row)"
                v-if="row.status === 'PENDING'">
              撤销申请
            </el-button>
            <span v-else>-</span>
          </template>
        </el-table-column>
      </el-table>

      <el-empty v-if="!loading && leaveHistory.length === 0" description="暂无休假记录" />

    </el-card>

    <el-dialog
        v-model="dialogVisible"
        title="申请休假"
        width="600px"
        @close="resetForm"
    >
      <el-form :model="applyForm" :rules="formRules" ref="applyFormRef" label-position="top">
        <el-form-item label="假期类型" prop="requestType">
          <el-radio-group v-model="applyForm.requestType">
            <el-radio label="PERSONAL_LEAVE">事假</el-radio>
            <el-radio label="SICK_LEAVE">病假</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="起止日期" prop="dateRange">
          <el-date-picker
              v-model="applyForm.dateRange"
              type="daterange"
              range-separator="至"
              start-placeholder="开始日期"
              end-placeholder="结束日期"
              value-format="YYYY-MM-DD"
              style="width: 100%;"
          />
        </el-form-item>
        <el-form-item label="请假事由" prop="reason">
          <el-input
              v-model="applyForm.reason"
              type="textarea"
              :rows="4"
              placeholder="请输入详细的请假事由"
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSubmit">
          提交申请
        </el-button>
      </template>
    </el-dialog>

  </div>
</template>

<script setup>
import { ref, onMounted, reactive } from 'vue';
import { ElMessage, ElMessageBox } from 'element-plus';
import { Plus, Delete } from '@element-plus/icons-vue';
import BackButton from '@/components/BackButton.vue';
import { getMyLeaveRequests, createLeaveRequest, cancelLeaveRequest } from '@/api/leave';

// --- 状态 ---
const loading = ref(false);
const dialogVisible = ref(false);
const leaveHistory = ref([]);
const applyFormRef = ref(null);

// --- 虚拟数据 ---
const getMockData = () => {
  return [
    {
      leaveRequestId: 1,
      requestType: 'PERSONAL_LEAVE',
      startDate: '2025-11-10',
      endDate: '2025-11-10',
      reason: '（虚拟）处理个人事务',
      status: 'APPROVED' // 已批准
    },
    {
      leaveRequestId: 2,
      requestType: 'SICK_LEAVE',
      startDate: '2025-11-18',
      endDate: '2025-11-19',
      reason: '（虚拟）急性肠胃炎，需休息两天',
      status: 'PENDING' // 待审批
    },
    {
      leaveRequestId: 3,
      requestType: 'PERSONAL_LEAVE',
      startDate: '2025-10-01',
      endDate: '2025-10-07',
      reason: '（虚拟）国庆假期',
      status: 'DENIED' // 已驳回
    },
  ];
};

// --- 表单 ---
const applyForm = reactive({
  requestType: 'PERSONAL_LEAVE',
  dateRange: [],
  reason: ''
});

const formRules = reactive({
  requestType: [{ required: true, message: '请选择假期类型', trigger: 'change' }],
  dateRange: [{ required: true, message: '请选择起止日期', trigger: 'change' }],
  reason: [{ required: true, message: '请输入请假事由', trigger: 'blur' }]
});

// --- 方法 ---

// 加载历史记录
const fetchHistory = async () => {
  loading.value = true;
  await new Promise(r => setTimeout(r, 300)); // 模拟加载
  try {
    // 【使用虚拟数据】
    leaveHistory.value = getMockData();

    // --- 【真实接口 - 已注释】 ---
    // const response = await getMyLeaveRequests();
    // leaveHistory.value = response.content || [];
    // --- 【真实接口结束】 ---

  } catch (error) {
    ElMessage.error('加载历史记录失败');
  } finally {
    loading.value = false;
  }
};

// 打开弹窗
const openApplyDialog = () => {
  dialogVisible.value = true;
};

// 重置表单
const resetForm = () => {
  applyFormRef.value?.resetFields();
};

// 提交表单
const handleSubmit = async () => {
  if (!applyFormRef.value) return;
  await applyFormRef.value.validate(async (valid) => {
    if (valid) {
      const data = {
        requestType: applyForm.requestType,
        startDate: applyForm.dateRange[0],
        endDate: applyForm.dateRange[1],
        reason: applyForm.reason
      };

      try {
        // --- 【真实接口 - 已注释】 ---
        // await createLeaveRequest(data);
        // --- 【真实接口结束】 ---

        ElMessage.success('申请提交成功 (模拟)');
        dialogVisible.value = false;
        fetchHistory(); // 重新加载列表
      } catch (error) {
        ElMessage.error('提交失败：' + (error.message || '未知错误'));
      }
    }
  });
};

// 撤销申请
const handleCancel = (row) => {
  ElMessageBox.confirm(
      `确定要撤销从 ${row.startDate} 到 ${row.endDate} 的休假申请吗？`,
      '确认撤销',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning',
      }
  ).then(async () => {
    try {
      // --- 【真实接口 - 已注释】 ---
      // await cancelLeaveRequest(row.leaveRequestId);
      // --- 【真实接口结束】 ---

      ElMessage.success('撤销成功 (模拟)');
      fetchHistory(); // 重新加载列表
    } catch (error) {
      ElMessage.error('撤销失败：' + (error.message || '未知错误'));
    }
  }).catch(() => {
    // 用户取消
  });
};

// --- 格式化辅助函数 ---
const formatRequestType = (type) => {
  const map = {
    'PERSONAL_LEAVE': '事假',
    'SICK_LEAVE': '病假'
  };
  return map[type] || '其他';
};

const formatStatus = (status) => {
  const map = {
    'PENDING': '待审批',
    'APPROVED': '已批准',
    'DENIED': '已驳回'
  };
  return map[status] || '未知';
};

const getStatusTag = (status) => {
  const map = {
    'PENDING': 'warning',
    'APPROVED': 'success',
    'DENIED': 'danger'
  };
  return map[status] || 'info';
};

// --- 生命周期 ---
onMounted(() => {
  fetchHistory();
});
</script>

<style scoped>
.app-container {
  padding: 24px;
  background-color: #f7fafc;
  min-height: calc(100vh - 50px);
}
.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 18px;
  font-weight: bold;
}
:deep(.el-form-item__label) {
  font-weight: 600 !important;
  color: #303133 !important;
}
</style>