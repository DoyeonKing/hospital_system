import { createRouter, createWebHistory } from 'vue-router';

// 导入页面组件
import DoctorLogin from '@/views/DoctorLogin.vue';
import DoctorDashboard from '@/views/DoctorDashboard.vue';
const NotFoundView = () => import('../views/404.vue');

const routes = [
    // 登录页面
    { path: '/login', name: 'DoctorLogin', component: DoctorLogin, meta: { title: '医生登录' } },
    
    // 医生工作台（需要登录）
    { path: '/doctor-dashboard', name: 'DoctorDashboard', component: DoctorDashboard, meta: { title: '医生工作台', requiresAuth: true } },
    
    // 根路径重定向到登录页面
    { path: '/', redirect: '/login' },

    // 404 未找到页面路由
    { path: '/404', name: 'NotFound', meta: { title: '404找不到页面' }, component: NotFoundView },

    // 所有其他路径重定向到 404 页面
    { path: '/:pathMatch(.*)*', redirect: '/404' }
];

const router = createRouter({
    history: createWebHistory(import.meta.env.BASE_URL),
    routes
});

// 导入doctorStore用于权限验证
import { useDoctorStore } from '@/stores/doctorStore';

router.beforeEach((to, from, next) => {
    document.title = to.meta.title || '医生工作台'; // 默认标题
    
    // 检查是否需要登录验证
    if (to.meta.requiresAuth) {
        const doctorStore = useDoctorStore();
        if (!doctorStore.isAuthenticated) {
            // 未登录，重定向到登录页面
            next('/login');
            return;
        }
    }
    
    // 如果已登录且访问登录页面，重定向到医生工作台
    if (to.path === '/login') {
        const doctorStore = useDoctorStore();
        if (doctorStore.isAuthenticated) {
            next('/doctor-dashboard');
            return;
        }
    }
    
    next();
});

export default router;
