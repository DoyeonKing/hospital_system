<template>
  <div class="admin-dashboard">
    <!-- 顶部导航栏 -->
    <div class="top-navbar">
      <div class="navbar-content">
        <div class="navbar-left">
          <h2>医院后台管理系统</h2>
        </div>
        <div class="navbar-right">
          <span class="welcome-text">欢迎，{{ adminStore.displayName }}</span>
          <el-button type="danger" size="small" @click="handleLogout">退出登录</el-button>
        </div>
      </div>
    </div>

    <!-- 顶部欢迎横幅 -->
    <div class="welcome-banner">
      <div class="banner-content">
        <h1>贴心医疗关怀，守护全校健康</h1>
        <p>欢迎使用医院后台管理系统</p>
      </div>
      <!-- 使用本地图片 -->
      <img :src="doctorImage" alt="医生形象" class="banner-image">
    </div>

    <!-- 功能区 -->
    <div class="feature-grid">
      <!-- 科室管理入口 -->
      <router-link to="/departments" class="feature-card-link">
        <div class="feature-card">
          <div class="icon-wrapper" style="background-color: #E6FFFA;">
            <el-icon :size="32" color="#38A2AC"><Tickets /></el-icon>
          </div>
          <h3>科室信息管理</h3>
          <p>创建、编辑、分配科室成员</p>
        </div>
      </router-link>

      <!-- 用户管理入口 -->
      <router-link to="/users" class="feature-card-link">
        <div class="feature-card">
          <div class="icon-wrapper" style="background-color: #EBF4FF;">
            <el-icon :size="32" color="#4299E1"><UserFilled /></el-icon>
          </div>
          <h3>用户账户管理</h3>
          <p>创建、搜索、编辑用户信息</p>
        </div>
      </router-link>

      <!-- 新增：排班管理入口 -->
      <router-link to="/scheduling/dashboard" class="feature-card-link">
        <div class="feature-card">
          <div class="icon-wrapper" style="background-color: #f0e6ff;">
            <el-icon :size="32" color="#9f7aea"><Calendar /></el-icon>
          </div>
          <h3>排班管理</h3>
          <p>定义医生班次与安排工作日程</p>
        </div>
      </router-link>

      <!-- 新增：号别管理入口 -->
      <router-link to="/scheduling/fee-management" class="feature-card-link">
        <div class="feature-card">
          <div class="icon-wrapper" style="background-color: #FFF5E6;">
            <el-icon :size="32" color="#F59E0B"><Money /></el-icon>
          </div>
          <h3>号别管理</h3>
          <p>管理排班费用与号源限额</p>
        </div>
      </router-link>

      <!-- 新增：就医规范管理入口 -->
      <router-link to="/regulations" class="feature-card-link">
        <div class="feature-card">
          <div class="icon-wrapper" style="background-color: #FFF0F6;">
            <el-icon :size="32" color="#EC4899"><Document /></el-icon>
          </div>
          <h3>就医规范管理</h3>
          <p>编辑和管理就医规范与流程</p>
        </div>
      </router-link>
    </div>
  </div>
</template>

<script setup>
// 修改：增加了 Calendar, Money 和 Document 图标的导入
import { Tickets, UserFilled, Calendar, Money, Document } from '@element-plus/icons-vue';
import { useRouter } from 'vue-router';
import { ElMessage, ElMessageBox } from 'element-plus';
// 导入本地图片
import doctorImage from '@/assets/doctor.jpg';
// BackButton 组件在此页面未使用，可以按需移除
// import BackButton from '@/components/BackButton.vue';
import { useAdminStore } from '@/stores/adminStore';

const router = useRouter();
const adminStore = useAdminStore();

const handleLogout = async () => {
  try {
    await ElMessageBox.confirm(
        '确定要退出登录吗？',
        '提示',
        {
          confirmButtonText: '确定',
          cancelButtonText: '取消',
          type: 'warning',
        }
    );

    // 清除登录状态
    adminStore.logout();
    ElMessage.success('已退出登录');

    // 跳转到登录页面
    router.push('/login');
  } catch {
    // 用户取消操作
  }
};
</script>

<style scoped>
/* 增加了顶部导航栏的样式 */
.top-navbar {
  background-color: #fff;
  padding: 0 24px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  margin-bottom: 24px;
}
.navbar-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
  height: 60px;
}
.navbar-left h2 {
  margin: 0;
  font-size: 20px;
}
.navbar-right {
  display: flex;
  align-items: center;
}
.welcome-text {
  margin-right: 16px;
  color: #606266;
}
.admin-dashboard {
  padding: 24px;
  background-color: #f7fafc;
}
.welcome-banner {
  background: linear-gradient(135deg, #81E6D9 0%, #4FD1C5 100%);
  border-radius: 12px;
  padding: 30px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  color: white;
  margin-bottom: 24px;
}
.banner-content h1 {
  font-size: 24px;
  margin: 0 0 8px 0;
}
.banner-content p {
  font-size: 16px;
  margin: 0;
  opacity: 0.9;
}
.banner-image {
  border-radius: 50%; /* 改为圆形，更可爱 */
  object-fit: cover;
  width: 120px;
  height: 120px;
  border: 4px solid white;
}
.feature-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
  gap: 20px;
}
.feature-card-link {
  text-decoration: none;
}
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
  width: 64px;
  height: 64px;
  border-radius: 50%;
  display: flex;
  justify-content: center;
  align-items: center;
  margin: 0 auto 16px;
}
.feature-card h3 {
  font-size: 18px;
  color: #2d3748;
  margin: 0 0 8px 0;
}
.feature-card p {
  font-size: 14px;
  color: #718096;
  margin: 0;
}
</style>

