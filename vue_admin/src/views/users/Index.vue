<template>
  <div class="module-dashboard">
    <div class="back-area" style="margin-bottom: 12px;">
      <BackButton />
    </div>
    <!-- 欢迎横幅 -->
    <div class="welcome-banner">
      <div class="banner-content">
        <h1>专业的账户管理</h1>
        <p>安全、高效地维护系统用户数据</p>
      </div>
      <!-- 使用本地图片 -->
      <img :src="doctorImage" alt="医生卡通形象" class="banner-image">
    </div>

    <div class="module-header">
      <h2>功能导航</h2>
      <p>请选择下面的功能进行操作。</p>
    </div>

    <div class="feature-grid">
      <router-link to="/users/create" class="feature-card-link">
        <div class="feature-card">
          <div class="icon-wrapper primary">
            <el-icon :size="24"><Plus /></el-icon>
          </div>
          <h3>创建账户</h3>
          <p class="card-desc">创建新的用户账户</p>
        </div>
      </router-link>
      
      <router-link to="/users/import-patient" class="feature-card-link">
        <div class="feature-card">
          <div class="icon-wrapper info">
            <el-icon :size="24"><Upload /></el-icon>
          </div>
          <h3>批量导入患者</h3>
          <p class="card-desc">支持学生/教师/职工</p>
        </div>
      </router-link>
      
      <router-link to="/users/import-doctor" class="feature-card-link">
        <div class="feature-card">
          <div class="icon-wrapper warning">
            <el-icon :size="24"><Upload /></el-icon>
          </div>
          <h3>批量导入医生</h3>
          <p class="card-desc">支持职称/专长</p>
        </div>
      </router-link>
      
      <router-link to="/users/search" class="feature-card-link">
        <div class="feature-card">
          <div class="icon-wrapper success">
            <el-icon :size="24"><Search /></el-icon>
          </div>
          <h3>用户信息搜索</h3>
          <p class="card-desc">快速查找用户信息</p>
        </div>
      </router-link>
      
      <router-link to="/users/edit" class="feature-card-link">
        <div class="feature-card">
          <div class="icon-wrapper edit">
            <el-icon :size="24"><Edit /></el-icon>
          </div>
          <h3>编辑账户</h3>
          <p class="card-desc">修改用户账户信息</p>
        </div>
      </router-link>
      
      <router-link to="/users/history" class="feature-card-link">
        <div class="feature-card">
          <div class="icon-wrapper memo">
            <el-icon :size="24"><Memo /></el-icon>
          </div>
          <h3>用户病史修改</h3>
          <p class="card-desc">管理用户病史记录</p>
        </div>
      </router-link>
      
      <router-link to="/admin/identity-verification" class="feature-card-link">
        <div class="feature-card">
          <div class="icon-wrapper verification">
            <el-icon :size="24"><DocumentChecked /></el-icon>
          </div>
          <h3>身份验证审核</h3>
          <p class="card-desc">审核新注册用户身份验证申请</p>
        </div>
      </router-link>
    </div>
  </div>
</template>

<script setup>
import { Plus, Search, Edit, Memo, Upload, DocumentChecked } from '@element-plus/icons-vue';
// 导入本地图片
import doctorImage from '@/assets/doctor.jpg';
import BackButton from '@/components/BackButton.vue';
</script>

<style scoped>
.module-dashboard {
  padding: 24px;
  background-color: #f7fafc;
}

.welcome-banner {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-radius: 12px;
  padding: 20px 30px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  color: white;
  margin-bottom: 20px;
}
.banner-content h1 {
  font-size: 20px;
  margin: 0 0 4px 0;
  font-weight: 600;
}
.banner-content p {
  font-size: 14px;
  margin: 0;
  opacity: 0.9;
}
.banner-image {
  border-radius: 50%;
  object-fit: cover;
  width: 80px;
  height: 80px;
  border: 3px solid white;
}

.module-header {
  margin-bottom: 20px;
}
.module-header h2 {
  font-size: 20px;
  color: #2d3748;
  margin: 0 0 6px 0;
  font-weight: 600;
}
.module-header p {
  font-size: 14px;
  color: #718096;
  margin: 0;
}

.feature-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 24px;
  row-gap: 24px;
  max-width: 1300px;
  margin: 0 auto;
}

@media (max-width: 1200px) {
  .feature-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (max-width: 768px) {
  .feature-grid {
    grid-template-columns: 1fr;
  }
}

.feature-card-link { 
  text-decoration: none;
  display: block;
}

.feature-card {
  background-color: white;
  border-radius: 10px;
  padding: 24px 20px;
  text-align: center;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  border: 1px solid #e2e8f0;
  cursor: pointer;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
}

.feature-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 12px 20px -5px rgba(0, 0, 0, 0.1), 0 6px 8px -3px rgba(0, 0, 0, 0.04);
  border-color: #cbd5e0;
}

.icon-wrapper {
  width: 52px;
  height: 52px;
  border-radius: 50%;
  display: flex;
  justify-content: center;
  align-items: center;
  margin: 0 auto 14px;
  transition: all 0.3s ease;
}

.icon-wrapper :deep(.el-icon) {
  font-size: 24px;
}

.feature-card:hover .icon-wrapper {
  transform: scale(1.08);
}

.icon-wrapper.primary {
  background-color: #eff6ff;
  color: #3b82f6;
}

.icon-wrapper.info {
  background-color: #e0f2fe;
  color: #0ea5e9;
}

.icon-wrapper.warning {
  background-color: #fef3c7;
  color: #f59e0b;
}

.icon-wrapper.success {
  background-color: #d1fae5;
  color: #10b981;
}

.icon-wrapper.edit {
  background-color: #fce7f3;
  color: #ec4899;
}

.icon-wrapper.memo {
  background-color: #ede9fe;
  color: #8b5cf6;
}

.icon-wrapper.verification {
  background-color: #fee2e2;
  color: #ef4444;
}

.feature-card h3 {
  font-size: 15px;
  color: #1f2937;
  margin: 0 0 6px 0;
  font-weight: 600;
}

.card-desc {
  font-size: 12px;
  color: #6b7280;
  margin: 0;
  line-height: 1.4;
}
</style>

