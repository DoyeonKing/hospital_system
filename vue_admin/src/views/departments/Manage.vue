<template>
  <div class="app-container">
    <div class="back-area" style="margin-bottom: 12px;">
      <BackButton />
    </div>
    <el-card shadow="always">
      <template #header>
        <div class="card-header">
          <span>科室列表与管理</span>
        </div>
      </template>

      <!-- 科室信息表格 -->
      <el-table :data="departmentList" border style="width: 100%">
        <el-table-column prop="id" label="科室编号" width="100" />
        <el-table-column prop="clinic_id" label="诊所编号" width="120" />
        <el-table-column prop="name" label="科室名称" width="180" />
        <el-table-column prop="description" label="科室描述" />

        <!-- 操作列 -->
        <el-table-column label="操作" width="180" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" :icon="Edit" circle @click="handleEdit(row)" />
            <el-button type="danger" :icon="Delete" circle @click="handleDelete(row)" />
          </template>
        </el-table-column>
      </el-table>

    </el-card>

    <!-- 编辑科室信息的弹窗 -->
    <el-dialog v-model="editDialogVisible" title="编辑科室信息" width="500">
      <el-form :model="currentEditDepartment" label-width="100px">
        <el-form-item label="科室名称">
          <el-input v-model="currentEditDepartment.name" />
        </el-form-item>
        <el-form-item label="诊所编号">
          <el-input v-model="currentEditDepartment.clinic_id" />
        </el-form-item>
        <el-form-item label="科室描述">
          <el-input v-model="currentEditDepartment.description" type="textarea" :rows="3" />
        </el-form-item>
      </el-form>
      <template #footer>
        <div class="dialog-footer">
          <el-button @click="editDialogVisible = false">取消</el-button>
          <el-button type="primary" @click="submitEdit">
            确认修改
          </el-button>
        </div>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue';
import { ElMessage, ElMessageBox } from 'element-plus';
import { Edit, Delete } from '@element-plus/icons-vue';
import BackButton from '@/components/BackButton.vue';

// --- 模拟数据 ---
// 正常情况下，这些数据应该从后端 API 获取
const departmentList = ref([
  { id: 1, clinic_id: 'CLI-001', name: '内科', description: '负责诊治成人内科疾病，如心血管、呼吸系统疾病等。' },
  { id: 2, clinic_id: 'CLI-002', name: '外科', description: '负责处理外伤、感染、肿瘤等需要手术治疗的疾病。' },
  { id: 3, clinic_id: 'CLI-003', name: '儿科', description: '专注于婴幼儿、儿童及青少年的健康与疾病问题。' },
  { id: 4, clinic_id: 'CLI-001', name: '皮肤科', description: '诊治各种皮肤、指甲和头发相关的疾病。' },
]);
// --- 模拟数据结束 ---


// 控制编辑弹窗的显示与隐藏
const editDialogVisible = ref(false);

// 存储当前正在编辑的科室信息
const currentEditDepartment = reactive({
  id: null,
  name: '',
  clinic_id: '',
  description: ''
});

// 处理编辑按钮点击事件
const handleEdit = (row) => {
  // 将点击的行数据复制到 currentEditDepartment 中，用于在弹窗中显示
  Object.assign(currentEditDepartment, row);
  // 显示弹窗
  editDialogVisible.value = true;
};

// 提交编辑
const submitEdit = () => {
  // 1. 找到在原始列表 departmentList 中对应的科室
  const index = departmentList.value.findIndex(item => item.id === currentEditDepartment.id);

  if (index !== -1) {
    // 2. 将修改后的信息更新到原始列表中
    departmentList.value[index] = { ...currentEditDepartment };

    // 3. 关闭弹窗
    editDialogVisible.value = false;

    // 4. 给出成功提示
    ElMessage.success('科室信息更新成功！');
  } else {
    ElMessage.error('更新失败，未找到对应科室。');
  }
};

// 处理删除按钮点击事件
const handleDelete = (row) => {
  ElMessageBox.confirm(
      `您确定要删除科室【${row.name}】吗？此操作不可逆！`,
      '危险操作警告',
      {
        confirmButtonText: '确定删除',
        cancelButtonText: '取消',
        type: 'warning',
      }
  )
      .then(() => {
        // 用户点击了“确定删除”
        // 通过 filter 方法创建一个不包含被删除项的新数组
        departmentList.value = departmentList.value.filter(item => item.id !== row.id);
        ElMessage.success('删除成功！');
      })
      .catch(() => {
        // 用户点击了“取消”
        ElMessage.info('已取消删除操作。');
      });
};
</script>

<style scoped>
.app-container {
  padding: 20px;
}
.card-header {
  font-size: 18px;
  font-weight: bold;
}
</style>
