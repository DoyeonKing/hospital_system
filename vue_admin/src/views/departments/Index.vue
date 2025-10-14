<template>
  <div class="module-dashboard">
    <div class="back-area" style="margin-bottom: 12px;">
      <BackButton />
    </div>
    <div class="module-header">
      <h2>科室信息管理</h2>
      <p>在这里，您可以管理医院的所有科室信息。请选择下面的功能进行操作。</p>
    </div>

    <div class="feature-grid">
      <router-link to="/departments/create" class="feature-card-link">
        <div class="feature-card"><div class="icon-wrapper"><el-icon :size="32"><Plus /></el-icon></div><h3>创建新科室</h3></div>
      </router-link>
      <router-link to="/departments/manage" class="feature-card-link">
        <div class="feature-card"><div class="icon-wrapper"><el-icon :size="32"><Setting /></el-icon></div><h3>管理科室信息</h3></div>
      </router-link>
      <router-link to="/departments/view" class="feature-card-link">
        <div class="feature-card"><div class="icon-wrapper"><el-icon :size="32"><Search /></el-icon></div><h3>查看科室信息</h3></div>
      </router-link>
      <router-link to="/departments/members" class="feature-card-link">
        <div class="feature-card"><div class="icon-wrapper"><el-icon :size="32"><User /></el-icon></div><h3>科室成员管理</h3></div>
      </router-link>
    </div>
  </div>
</template>

<script setup>
import { Plus, Setting, Search, User } from '@element-plus/icons-vue';
import BackButton from '@/components/BackButton.vue';
</script>

<style scoped>
.module-dashboard {
  padding: 24px;
  background-color: #f7fafc;
}
.module-header {
  margin-bottom: 24px;
}
.module-header h2 {
  font-size: 22px;
  color: #2d3748;
}
.module-header p {
  font-size: 16px;
  color: #718096;
}
.feature-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
  gap: 20px;
}
.feature-card-link { text-decoration: none; }
.feature-card {
  background-color: white;
  border-radius: 12px;
  padding: 24px;
  text-align: center;
  transition: all 0.3s ease;
  border: 1px solid #e2e8f0;
}
.feature-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
}
.icon-wrapper {
  width: 64px; height: 64px;
  border-radius: 50%;
  display: flex; justify-content: center; align-items: center;
  margin: 0 auto 16px;
  background-color: #edf2f7;
  color: #4a5568;
}
.feature-card h3 {
  font-size: 16px;
  color: #2d3748;
  margin: 0;
}
</style>

