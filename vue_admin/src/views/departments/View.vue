<template>
  <div class="app-container">
    <div class="back-area" style="margin-bottom: 12px;">
      <BackButton />
    </div>
    <el-card shadow="always">
      <template #header>
        <div class="card-header">
          <span>查看所有科室信息</span>
        </div>
      </template>

      <!-- 搜索区域 -->
      <el-form :inline="true" :model="searchForm" class="search-form">
        <el-form-item label="科室名称">
          <el-input
              v-model="searchForm.name"
              placeholder="按科室名称搜索"
              clearable
          />
        </el-form-item>
        <el-form-item label="科室描述">
          <el-input
              v-model="searchForm.description"
              placeholder="按科室描述搜索"
              clearable
          />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" :icon="Search" @click="handleSearch">搜索</el-button>
          <el-button :icon="Refresh" @click="resetSearch">重置</el-button>
        </el-form-item>
      </el-form>

      <!-- 科室信息表格 -->
      <el-table :data="displayedDepartments" border stripe style="width: 100%">
        <el-table-column prop="id" label="科室编号" width="120" />
        <el-table-column prop="clinic_id" label="诊所编号" width="120" />
        <el-table-column prop="name" label="科室名称" width="180" />
        <el-table-column prop="description" label="科室描述" />
      </el-table>

      <!-- 如果搜索结果为空 -->
      <el-empty v-if="displayedDepartments.length === 0" description="未找到匹配的科室信息" />

    </el-card>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue';
import { Search, Refresh } from '@element-plus/icons-vue';
import BackButton from '@/components/BackButton.vue';

// 模拟的科室原始数据 (未来从API获取)
const allDepartments = ref([
  { id: 'DEPT_001', clinic_id: 'CLI_A', name: '心血管内科', description: '专注于心脏和血管相关疾病的诊断与治疗。' },
  { id: 'DEPT_002', clinic_id: 'CLI_A', name: '神经外科', description: '负责脑部、脊髓及神经系统的外科手术治疗。' },
  { id: 'DEPT_003', clinic_id: 'CLI_B', name: '儿科', description: '为儿童提供全面的医疗保健服务，包括常见病和心脏发育问题。' },
  { id: 'DEPT_004', clinic_id: 'CLI_B', name: '骨科', description: '处理骨骼、关节、韧带等运动系统损伤和疾病。' },
  { id: 'DEPT_005', clinic_id: 'CLI_C', name: '皮肤科', description: '诊断和治疗各种皮肤疾病，以及皮肤美容。' },
  { id: 'DEPT_006', clinic_id: 'CLI_C', name: '眼科', description: '提供眼部疾病的检查、治疗和手术，包括神经视觉问题。' }
]);

// 用于绑定搜索输入框的表单对象
const searchForm = reactive({
  name: '',
  description: ''
});

// 用于在表格中展示的数据
const displayedDepartments = ref([...allDepartments.value]);

// 点击“搜索”按钮时触发的方法
const handleSearch = () => {
  let filtered = allDepartments.value;

  const searchName = searchForm.name.trim().toLowerCase();
  const searchDesc = searchForm.description.trim().toLowerCase();

  // 如果输入了科室名称，则先按名称过滤
  if (searchName) {
    filtered = filtered.filter(dept =>
        dept.name.toLowerCase().includes(searchName)
    );
  }

  // 如果输入了科室描述，则在上面的结果基础上再按描述过滤
  if (searchDesc) {
    filtered = filtered.filter(dept =>
        dept.description.toLowerCase().includes(searchDesc)
    );
  }

  displayedDepartments.value = filtered;
};

// 点击“重置”按钮时触发的方法
const resetSearch = () => {
  searchForm.name = '';
  searchForm.description = '';
  displayedDepartments.value = [...allDepartments.value]; // 恢复显示所有数据
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
.search-form {
  margin-bottom: 20px;
  padding: 10px;
  background-color: #f5f7fa;
  border-radius: 4px;
}
</style>

