import { createRouter, createWebHistory } from 'vue-router';
// 【重要】导入您自己的 doctorStore
import { useDoctorStore } from '@/stores/doctorStore';

// 导入页面组件
import DoctorLogin from '@/views/DoctorLogin.vue';
import DoctorDashboard from '@/views/DoctorDashboard.vue';
import MySchedule from '@/views/MySchedule.vue';
import PatientInfo from '@/views/PatientInfo.vue';
import LeaveRequest from '@/views/LeaveRequest.vue'; // 导入休假页面
import SlotApplication from '@/views/SlotApplication.vue'; // 导入加号申请页面
import DoctorWorkHours from '@/views/DoctorWorkHours.vue'; // 导入工时统计页面
const NotFoundView = () => import('../views/404.vue');

const routes = [
    // 登录页面
    {
        path: '/login',
        name: 'DoctorLogin',
        component: DoctorLogin,
        meta: { title: '医生登录' }
    },

    // 医生工作台（需要登录）
    {
        path: '/doctor-dashboard',
        name: 'DoctorDashboard',
        component: DoctorDashboard,
        meta: { title: '医生工作台', requiresAuth: true }
    },

    // 我的排班页面
    {
        path: '/my-schedule',
        name: 'MySchedule',
        component: MySchedule,
        meta: { title: '我的排班', requiresAuth: true }
    },

    // 患者管理页面
    {
        path: '/patient-info',
        name: 'PatientInfo',
        component: PatientInfo,
        meta: { title: '患者管理', requiresAuth: true }
    },

    // 休假申请页面
    {
        path: '/leave-request',
        name: 'LeaveRequest',
        component: LeaveRequest,
        meta: { title: '休假申请', requiresAuth: true }
    },

    // 加号申请页面
    {
        path: '/slot-application',
        name: 'SlotApplication',
        component: SlotApplication,
        meta: { title: '申请加号', requiresAuth: true }
    },

    // 医生工时统计页面
    {
        path: '/doctor-work-hours',
        name: 'DoctorWorkHours',
        component: DoctorWorkHours,
        meta: { title: '我的工时统计', requiresAuth: true }
    },

    // 根路径
    {
        path: '/',
        redirect: '/login'
    },

    // 404
    {
        path: '/404',
        name: 'NotFound',
        meta: { title: '404找不到页面' },
        component: NotFoundView
    },
    {
        path: '/:pathMatch(.*)*',
        redirect: '/404'
    }
];

const router = createRouter({
    history: createWebHistory(import.meta.env.BASE_URL),
    routes
});


// 【重要】路由守卫
router.beforeEach(async (to, from, next) => {
    document.title = to.meta.title || '医生工作台';

    // 【已修改】使用您自己的 store
    const doctorStore = useDoctorStore();

    // 检查是否需要登录
    if (to.meta.requiresAuth) {
        // 使用您 store 中的 isAuthenticated getter
        if (!doctorStore.isAuthenticated) {
            console.log('🔒 路由守卫: 未认证，重定向到登录页');
            // 未登录，重定向到登录页面
            next('/login');
            return;
        }
        
        // 额外验证：检查 Token 格式是否合法（JWT Token 应该有3个部分，用.分隔）
        const token = doctorStore.loggedInDoctorBasicInfo?.token;
        if (token) {
            const tokenParts = token.split('.');
            if (tokenParts.length !== 3) {
                console.warn('🔒 路由守卫: Token 格式无效，清除登录状态');
                doctorStore.logout();
                next('/login');
                return;
            }
            
            // 验证Token的payload是否被篡改（检查过期时间）
            try {
                const payload = JSON.parse(atob(tokenParts[1]));
                const currentTime = Math.floor(Date.now() / 1000);
                
                // 检查Token是否过期
                if (payload.exp && payload.exp < currentTime) {
                    console.warn('🔒 路由守卫: Token已过期，清除登录状态');
                    doctorStore.logout();
                    next('/login');
                    return;
                }
                
                // 检查Token的基本字段是否存在
                if (!payload.identifier && !payload.sub) {
                    console.warn('🔒 路由守卫: Token payload无效，清除登录状态');
                    doctorStore.logout();
                    next('/login');
                    return;
                }
            } catch (e) {
                console.error('🔒 路由守卫: Token解析失败', e);
                doctorStore.logout();
                next('/login');
                return;
            }
        }
        
        console.log('🔒 路由守卫: 认证通过');
    }

    // 如果已登录且访问登录页面，重定向到医生工作台
    if (to.path === '/login' || to.path === '/') {
        if (doctorStore.isAuthenticated) {
            next('/doctor-dashboard');
            return;
        }
    }

    // 确保其他所有情况都能正常跳转
    next();
});

export default router;