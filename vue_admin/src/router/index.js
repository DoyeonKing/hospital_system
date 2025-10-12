import { createRouter, createWebHistory } from 'vue-router';

// 通用视图组件导入
const NotFoundView = () => import('../views/404.vue');

const routes = [
    // 1. 唯一的根路径重定向
    { path: '/', redirect: '/404' },

    // 2. 404 未找到页面路由
    { path: '/404', name: 'NotFound', meta: { title: '404找不到页面' }, component: NotFoundView },

    // 3. 所有其他路径重定向到 404 页面
    { path: '/:pathMatch(.*)*', redirect: '/404' }
];

const router = createRouter({
    history: createWebHistory(import.meta.env.BASE_URL),
    routes
});

router.beforeEach((to, from, next) => {
    document.title = to.meta.title || '志愿服务平台'; // 默认标题
    next();
});

export default router;
