import { createRouter, createWebHistory } from 'vue-router';

// 导入主入口
import AdminIndex from '@/views/AdminIndex.vue';
import AdminLogin from '@/views/AdminLogin.vue';
import Debug from '@/views/Debug.vue';

// 导入科室管理页面组件
import DepartmentIndex from '@/views/departments/Index.vue';
import CreateDepartment from '@/views/departments/CreateDepartment.vue';
import ManageDepartments from '@/views/departments/Manage.vue';
import DepartmentView from '@/views/departments/View.vue';
import DepartmentMembers from '@/views/departments/Members.vue';

// 导入用户管理页面组件
import UserIndex from '@/views/users/Index.vue';
import CreateUser from '@/views/users/Create.vue';
import ImportUser from '@/views/users/Import.vue';
import SearchUser from '@/views/users/Search.vue';
import EditUser from '@/views/users/Edit.vue';
import UserHistory from '@/views/users/History.vue';

// ===== 新增：导入排班管理页面组件 =====
import ShiftManagement from '@/views/scheduling/ShiftManagement.vue';
import ScheduleDashboard from '@/views/scheduling/ScheduleDashboard.vue';

// 通用视图组件导入
const NotFoundView = () => import('../views/404.vue');

const routes = [
    // 登录页面
    { path: '/login', name: 'AdminLogin', component: AdminLogin, meta: { title: '管理员登录' } },

    // 调试页面
    { path: '/debug', name: 'Debug', component: Debug, meta: { title: '调试页面' } },

    // 根路径重定向到登录页面
    { path: '/', redirect: '/login' },

    // 后台管理主页（需要登录）
    { path: '/admin', component: AdminIndex, meta: { title: '后台管理主页', requiresAuth: true } },

    // =======================================================
    // 科室管理相关的所有路由
    {
        path: '/departments',
        name: 'DepartmentIndex',
        meta: { title: '科室管理', requiresAuth: true },
        component: DepartmentIndex
    },
    {
        path: '/departments/create',
        name: 'CreateDepartment',
        meta: { title: '创建新科室', requiresAuth: true },
        component: CreateDepartment
    },
    {
        path: '/departments/manage',
        name: 'ManageDepartments',
        meta: { title: '管理所有科室', requiresAuth: true },
        component: ManageDepartments
    },
    {
        path: '/departments/view',
        name: 'DepartmentView',
        meta: { title: '查看科室信息', requiresAuth: true },
        component: DepartmentView
    },
    {
        path: '/departments/members',
        name: 'DepartmentMembers',
        meta: { title: '科室成员管理', requiresAuth: true },
        component: DepartmentMembers
    },
    // =======================================================

    // =======================================================
    // 用户管理相关的所有路由
    {
        path: '/users',
        name: 'UserIndex',
        meta: { title: '用户账户管理', requiresAuth: true },
        component: UserIndex
    },
    {
        path: '/users/create',
        name: 'CreateUser',
        meta: { title: '创建新用户', requiresAuth: true },
        component: CreateUser
    },
    {
        path: '/users/import',
        name: 'ImportUser',
        meta: { title: '批量导入用户', requiresAuth: true },
        component: ImportUser
    },
    {
        path: '/users/search',
        name: 'SearchUser',
        meta: { title: '搜索用户信息', requiresAuth: true },
        component: SearchUser
    },
    {
        path: '/users/edit',
        name: 'EditUser',
        meta: { title: '编辑用户信息', requiresAuth: true },
        component: EditUser
    },
    {
        path: '/users/history',
        name: 'UserHistory',
        meta: { title: '修改用户病史', requiresAuth: true },
        component: UserHistory
    },
    // =======================================================

    // ===== 新增：排班管理相关的所有路由 =====
    {
        path: '/scheduling/shifts',
        name: 'ShiftManagement',
        meta: { title: '班次定义与管理', requiresAuth: true },
        component: ShiftManagement
    },
    {
        path: '/scheduling/dashboard',
        name: 'ScheduleDashboard',
        meta: { title: '排班看板', requiresAuth: true },
        component: ScheduleDashboard
    },
    // =======================================================


    // 404 未找到页面路由
    { path: '/404', name: 'NotFound', meta: { title: '404找不到页面' }, component: NotFoundView },

    // 所有其他未匹配的路径重定向到 404 页面 (这条规则必须在最后)
    { path: '/:pathMatch(.*)*', redirect: '/404' }
];

const router = createRouter({
    history: createWebHistory(import.meta.env.BASE_URL),
    routes
});

// 导入adminStore用于权限验证
import { useAdminStore } from '@/stores/adminStore';

router.beforeEach((to, from, next) => {
    document.title = to.meta.title || '医院后台管理'; // 默认标题

    // 检查是否需要登录验证
    if (to.meta.requiresAuth) {
        const adminStore = useAdminStore();
        if (!adminStore.isAuthenticated) {
            // 未登录，重定向到登录页面
            next('/login');
            return;
        }
    }

    // 如果已登录且访问登录页面，重定向到管理主页
    if (to.path === '/login') {
        const adminStore = useAdminStore();
        if (adminStore.isAuthenticated) {
            next('/admin');
            return;
        }
    }

    next();
});

export default router;

