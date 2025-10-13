import { createRouter, createWebHistory } from 'vue-router';

// 导入主入口
import AdminIndex from '@/views/AdminIndex.vue';

// 导入科室管理页面组件
import DepartmentIndex from '@/views/departments/Index.vue';
import CreateDepartment from '@/views/departments/CreateDepartment.vue';
import ManageDepartments from '@/views/departments/Manage.vue';
import DepartmentView from '@/views/departments/View.vue';
import DepartmentMembers from '@/views/departments/Members.vue';

// 导入用户管理页面组件
import UserIndex from '@/views/users/Index.vue';
import CreateUser from '@/views/users/Create.vue';
import ImportUser from '@/views/users/Import.vue'; // 确保导入 ImportUser
import SearchUser from '@/views/users/Search.vue';
import EditUser from '@/views/users/Edit.vue';
import UserHistory from '@/views/users/History.vue';

// 通用视图组件导入
const NotFoundView = () => import('../views/404.vue');

const routes = [
    // 根路径指向新的主入口页面
    { path: '/', component: AdminIndex, meta: { title: '后台管理主页' } },

    // =======================================================
    // 科室管理相关的所有路由
    {
        path: '/departments',
        name: 'DepartmentIndex',
        meta: { title: '科室管理' },
        component: DepartmentIndex
    },
    {
        path: '/departments/create',
        name: 'CreateDepartment',
        meta: { title: '创建新科室' },
        component: CreateDepartment
    },
    {
        path: '/departments/manage',
        name: 'ManageDepartments',
        meta: { title: '管理所有科室' },
        component: ManageDepartments
    },
    {
        path: '/departments/view',
        name: 'DepartmentView',
        meta: { title: '查看科室信息' },
        component: DepartmentView
    },
    {
        path: '/departments/members',
        name: 'DepartmentMembers',
        meta: { title: '科室成员管理' },
        component: DepartmentMembers
    },
    // =======================================================

    // =======================================================
    // 用户管理相关的所有路由
    {
        path: '/users',
        name: 'UserIndex',
        meta: { title: '用户账户管理' },
        component: UserIndex
    },
    {
        path: '/users/create',
        name: 'CreateUser',
        meta: { title: '创建新用户' },
        component: CreateUser
    },
    // 为批量导入功能添加路由
    {
        path: '/users/import',
        name: 'ImportUser',
        meta: { title: '批量导入用户' },
        component: ImportUser
    },
    {
        path: '/users/search',
        name: 'SearchUser',
        meta: { title: '搜索用户信息' },
        component: SearchUser
    },
    {
        path: '/users/edit',
        name: 'EditUser',
        meta: { title: '编辑用户信息' },
        component: EditUser
    },
    {
        path: '/users/history',
        name: 'UserHistory',
        meta: { title: '修改用户病史' },
        component: UserHistory
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

router.beforeEach((to, from, next) => {
    document.title = to.meta.title || '医院后台管理'; // 默认标题
    next();
});

export default router;

