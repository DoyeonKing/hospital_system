<template>
  <div class="app-container">
    <div class="back-area" style="margin-bottom: 12px;">
      <BackButton />
    </div>
    <h2>用户信息搜索</h2>
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
        <el-table-column prop="id_card" label="身份证号" />
        <el-table-column prop="phone" label="手机号" />
      </el-table>
    </el-card>
  </div>
</template>

<script setup>
import BackButton from '@/components/BackButton.vue';
import { ref, reactive } from 'vue';

const searchForm = reactive({ id: '', name: '' });
const allUsers = ref([
  { id: '2022001', name: '张三', role: 'patient', id_card: '110...', phone: '138...' },
  { id: '2022002', name: '李四', role: 'patient', id_card: '120...', phone: '139...' },
  { id: 'D001', name: '王医生', role: 'doctor', id_card: '130...', phone: '135...' },
]);
const filteredUsers = ref([...allUsers.value]);

const handleSearch = () => {
  filteredUsers.value = allUsers.value.filter(user => {
    const idMatch = user.id.includes(searchForm.id.trim());
    const nameMatch = user.name.includes(searchForm.name.trim());
    return idMatch && nameMatch;
  });
};
</script>

<style scoped>.app-container{padding:20px;}.search-form{margin-bottom:20px;}</style>
