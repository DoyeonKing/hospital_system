<template>
  <div class="app-container">
    <div class="back-area" style="margin-bottom: 12px;">
      <BackButton />
    </div>
    <h2>编辑用户信息</h2>
    <el-card shadow="always">
      <el-form :inline="true" :model="searchForm" class="search-form">
        <el-form-item label="学号/工号"><el-input v-model="searchForm.id" clearable /></el-form-item>
        <el-form-item label="姓名"><el-input v-model="searchForm.name" clearable /></el-form-item>
        <el-form-item><el-button type="primary" @click="handleSearch">搜索</el-button></el-form-item>
      </el-form>
      <el-table :data="filteredUsers" border stripe>
        <el-table-column prop="id" label="学号/工号" />
        <el-table-column prop="name" label="姓名" />
        <el-table-column prop="role" label="角色" />
        <el-table-column prop="phone" label="手机号" />
        <el-table-column label="操作" width="120">
          <template #default="{ row }">
            <el-button type="primary" size="small" @click="openEditDialog(row)">编辑</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <el-dialog v-model="dialogVisible" title="编辑用户">
      <el-form :model="editForm" label-width="80px">
        <el-form-item label="姓名"><el-input v-model="editForm.name" /></el-form-item>
        <el-form-item label="角色">
          <el-select v-model="editForm.role"><el-option label="患者" value="patient"/><el-option label="医生" value="doctor"/></el-select>
        </el-form-item>
        <el-form-item label="手机号"><el-input v-model="editForm.phone" /></el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSave">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import BackButton from '@/components/BackButton.vue';
import { ref, reactive } from 'vue';
import { ElMessage } from 'element-plus';

const searchForm = reactive({ id: '', name: '' });
const allUsers = ref([
  { id: '2022001', name: '张三', role: 'patient', phone: '138...' },
  { id: 'D001', name: '王医生', role: 'doctor', phone: '135...' },
]);
const filteredUsers = ref([...allUsers.value]);
const dialogVisible = ref(false);
const editForm = reactive({ id: '', name: '', role: '', phone: '' });

const handleSearch = () => { /* ...搜索逻辑同上... */
  filteredUsers.value = allUsers.value.filter(user =>
      user.id.includes(searchForm.id) && user.name.includes(searchForm.name)
  );
};

const openEditDialog = (row) => {
  Object.assign(editForm, row);
  dialogVisible.value = true;
};

const handleSave = () => {
  const index = allUsers.value.findIndex(u => u.id === editForm.id);
  if (index !== -1) {
    allUsers.value[index] = { ...editForm };
    handleSearch(); // Refresh list
  }
  dialogVisible.value = false;
  ElMessage.success('保存成功');
};
</script>

<style scoped>.app-container{padding:20px;}.search-form{margin-bottom:20px;}</style>
