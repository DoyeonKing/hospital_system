import {createRouter, createWebHistory} from 'vue-router';
//志愿者
import Home from '../views/Volunteer/Volunteer_Dashboard.vue'

//管理员组件
import managerHome from '../views/Administrator/Manager_managerHome.vue'; // 确保路径正确
import personalData from '../views/Administrator/Manager_personalData.vue';
import manageVolunteer from '../views/Administrator/Manager_manageVolunteer.vue';
import manageGroup from '../views/Administrator/Manager_manageGroup.vue';
import manageActivity from '../views/Administrator/Manager_manageActivity.vue';
import complaint from '../views/Administrator/Manager_complaint.vue';
import message from '../views/Administrator/Manager_message.vue';
import managerOperation from '../views/Administrator/Manager_managerOperation.vue';
import password from '../views/Administrator/Manager_password.vue';
import handle from '../views/Administrator/Manager_handle.vue';
import manageTraining from '../views/Administrator/Manager_manageTraining.vue';

// 志愿组织页面组件导入 (这些是你已有的)
import OrganizationOrganizationInfo from '../views/Organization/Organization-OrganizationInfo.vue'
import OrganizationApplyActivity from '../views/Organization/Organization-ApplyActivity.vue'
import OrganizationViewActivityRecords from '../views/Organization/Organization-ViewActivityRecords.vue'
import OrganizationViewTrainingRecords from '../views/Organization/Organization-ViewTrainingRecords.vue'
import OrganizationManagePersonnel from '../views/Organization/Organization-ManagePersonnel.vue'
import OrganizationApplyTraining from '../views/Organization/Organization-ApplyTraining.vue'
import OrganizationHome from "@/views/Organization/Organization-Home.vue";
import OrganizationChangeOrganizationInfo from "@/views/Organization/Organization-ChangeOrganizationInfo.vue";
import OrganizationDetailedVolunteerInfoForMember
    from "@/views/Organization/Organization-DetailedVolunteerInfoForMember.vue";
import OrganizationJoinMember from "@/views/Organization/Organization-JoinMember.vue";
import OrganizationTrainAddMember from "@/views/Organization/Organization-TrainAddMember.vue";
import OrganizationDetailedActivityInfo from "@/views/Organization/Organization-DetailedActivityInfo.vue";
import OrganizationDetailedTrainInfo from "@/views/Organization/Organization-DetailedTrainInfo.vue";
import OrganizationChangeActivityInfo from "@/views/Organization/Organization-ChangeActivityInfo.vue";
import OrganizationChangeTrainInfo from "@/views/Organization/Organization-ChangeTrainInfo.vue";
import OrganizationDetailedVolunteerInfoForAddTrain
    from "@/views/Organization/Organization-DetailedVolunteerInfoForAddTrain.vue";
import OrganizationDetailedVolunteerInfoForAdd from "@/views/Organization/Organization-DetailedVolunteerInfoForAdd.vue";
import OrganizationAddMemberForActivity from "@/views/Organization/Organization-AddMemberForActivity.vue";
import OrganizationAddedMemberForActivity from "@/views/Organization/Organization-AddedMemberForActivity.vue";
import OrganizationDetailedInfoForAddActivity from "@/views/Organization/Organization-DetailedInfoForAddActivity.vue";
import OrganizationDetailedInfoForAddedActivity
    from "@/views/Organization/Organization-DetailedInfoForAddedActivity.vue";
import OrganizationActivityDetail from "@/views/Organization/Organization-ActivityDetail.vue";
import OrganizationTrainingDetail from "@/views/Organization/Organization-TrainingDetail.vue";
import OrganizationCheckVolunteer from "@/views/Organization/Organization-CheckVolunteer.vue";

// 志愿者区域的布局/父组件 (这是你刚刚提供的配置中用到的 VolunteerHome.vue)
//import VolunteerAreaLayout from '../views/VolunteerHome.vue';
//import volunteerHome from "@/views/Volunteer/VolunteerHome.vue"; // 我给它重命名为 VolunteerAreaLayout 以明确其用途，但它指向你的 VolunteerHome.vue

// 通用/认证视图组件的动态导入 (这些是你已有的)
const LoginView = () => import('../views/Login.vue');
const RegisterView = () => import('../views/Register.vue');
const NotFoundView = () => import('../views/404.vue');
const VolunteerRegisterView = () => import('../views/Volunteer/VolunteerRegister.vue');
const VolunteerLoginView = () => import('../views/Volunteer/VolunteerLogin.vue');
const AdministratorLoginView = () => import('../views/Administrator/AdministratorLogin.vue');
const OrganizationLoginView = () => import('../views/Organization/OrganizationLogin.vue');
const OrganizationRegisterView = () => import('../views/Organization/OrganizationRegister.vue');
const LoginFormView = () => import('../views/LoginForm.vue');


const routes = [
    // 1. 唯一的根路径重定向 (来自你的主项目配置)
    {path: '/', redirect: '/loginform'},

    // 2. 认证和角色选择相关的路由 (来自你的主项目配置)
    {path: '/loginform', name: 'LoginForm', meta: {title: '角色选择'}, component: LoginFormView},
    {path: '/login', name: 'Login', meta: {title: '登陆界面'}, component: LoginView},
    {path: '/register', name: 'Register', meta: {title: '注册界面'}, component: RegisterView},
    {
        path: '/volunteerregister',
        name: 'VolunteerRegister',
        meta: {title: '志愿者注册界面'},
        component: VolunteerRegisterView
    },
    {path: '/volunteerlogin', name: 'VolunteerLogin', meta: {title: '志愿者登陆界面'}, component: VolunteerLoginView},
    {
        path: '/administratorlogin',
        name: 'AdministratorLogin',
        meta: {title: '管理员登陆界面'},
        component: AdministratorLoginView
    },
    {
        path: '/organizationlogin',
        name: 'OrganizationLogin',
        meta: {title: '志愿组织机构登陆界面'},
        component: OrganizationLoginView
    },
    {
        path: '/organizationregister',
        name: 'OrganizationRegister',
        meta: {title: '志愿组织机构注册界面'},
        component: OrganizationRegisterView
    },

    // 3. 管理员区域路由 (来自你的主项目配置，保持为顶级路由，因为你说不使用额外布局)
    {path: '/manager', name: 'managerHome', component: managerHome},
    {path: '/personalData', name: 'personalData', component: personalData},
    {path: '/manageVolunteer', name: 'manageVolunteer', component: manageVolunteer},
    {path: '/manageGroup', name: 'manageGroup', component: manageGroup},
    {path: '/manageActivity', name: 'manageActivity', component: manageActivity},
    {path: '/complaint', name: 'complaint', component: complaint},
    {path: '/message', name: 'message', component: message},
    {path: '/managerOperation', name: 'managerOperation', component: managerOperation},
    {path: '/managerPassword', name: 'password', component: password},
    {path: '/handle', name: 'handle', component: handle},
    {path: '/manageTraining', name: 'manageTraining', component: manageTraining},


    // 4. 整合的志愿者区域 (基于你刚刚提供的配置)
    {
        path: '/volunteer', name: 'Home',
        component: Home,
        children: [
            {path: '', name: 'Dashboard', component: () => import('../views/Volunteer/Volunteer_Home.vue')},
            {path: 'profile', name: 'Profile', component: () => import('../views/Volunteer/Volunteer_ProfileEdit.vue')},
            {path: 'reviews', name: 'Reviews', component: () => import('../views/Volunteer/Volunteer_Evaluate.vue')},
            {
                path: 'complaints',
                name: 'Complaints',
                component: () => import('../views/Volunteer/Volunteer_Complaint.vue')
            },
            {path: 'training', name: 'Training', component: () => import('../views/Volunteer/Volunteer_Trainings.vue')},
            {path: 'projects', name: 'Projects', component: () => import('../views/Volunteer/Volunteer_Projects.vue')},
            {
                path: 'project-apply',
                name: 'ProjectApply',
                component: () => import('../views/Volunteer/Volunteer_PendingProjects.vue')
            },
            {path: 'teams', name: 'Teams', component: () => import('../views/Volunteer/Volunteer_Teams.vue')},
        {
        path: 'teams-more',
        name: 'TeamsMore',
        component: () => import('../views/Volunteer/Volunteer_TeamsMore.vue')
      },
      {
        path: 'projects-more',
        name: 'ProjectsMore',
        component: () => import('../views/Volunteer/Volunteer_ProjectsMore.vue')
      }]
    },


    // 5. 志愿组织机构
    {path: '/organization-home', name: 'organization-home', component: OrganizationHome,},
    {path: '/organization-info', name: 'organization-info', component: OrganizationOrganizationInfo,},
    {path: '/apply-activity', name: 'apply-activity', component: OrganizationApplyActivity,},
    {path: '/view-activity-records', name: 'view-activity-records', component: OrganizationViewActivityRecords,},
    {path: '/view-training-records', name: 'view-training-records', component: OrganizationViewTrainingRecords,},
    {path: '/manage-personnel', name: 'manage-personnel', component: OrganizationManagePersonnel,},
    {path: '/apply-training', name: 'apply-training', component: OrganizationApplyTraining,},
    {
        path: '/change-organization-info',
        name: 'change-organization-info',
        component: OrganizationChangeOrganizationInfo,
    },
    {
        path: '/detailed-volunteer-info',
        name: 'detailed-volunteer-info',
        component: OrganizationDetailedVolunteerInfoForMember,
    },
    {path: '/join-member', name: 'join-member', component: OrganizationJoinMember,},
    {path: '/train-add-member', name: 'train-add-member', component: OrganizationTrainAddMember,},
    {path: '/detailed-activity-info', name: 'detailed-activity-info', component: OrganizationDetailedActivityInfo,},
    {path: '/detailed-train-info', name: 'detailed-train-info', component: OrganizationDetailedTrainInfo,},
    {path: '/change-train-info', name: 'change-train-info', component: OrganizationChangeTrainInfo,},
    {path: '/change-activity-info', name: 'change-activity-info', component: OrganizationChangeActivityInfo,},
    {
        path: '/detailed-volunteer-info-for-add-train',
        name: 'detailed-volunteer-info-for-add-train',
        component: OrganizationDetailedVolunteerInfoForAddTrain,
    },
    {
        path: '/detailed-volunteer-info-for-add',
        name: 'detailed-volunteer-info-for-add',
        component: OrganizationDetailedVolunteerInfoForAdd,
    },
      {
     path: '/OrganizationCheckVolunteer',
      name: '/OrganizationCheckVolunteer',
      component:OrganizationCheckVolunteer
},
    {path: '/add-member-for-activity', name: 'add-member-for-activity', component: OrganizationAddMemberForActivity},
    {
        path: '/added-member-for-activity',
        name: 'added-member-for-activity',
        component: OrganizationAddedMemberForActivity
    },
    {
        path: '/detailed-info-for-add-activity',
        name: 'detailed-info-for-add-activity',
        component: OrganizationDetailedInfoForAddActivity
    },
    {
        path: '/detailed-info-for-added-activity',
        name: 'detailed-info-for-added-activity',
        component: OrganizationDetailedInfoForAddedActivity
    },
    {
        path: '/activity-detail/:id',
        name: 'activity-detail',
        component: OrganizationActivityDetail
    },
    {
        path: '/training-detail/:id',
        name: 'training-detail',
        component: OrganizationTrainingDetail
    },
    // 6. 404 未找到页面路由 (必须放在 routes 数组的最后)
    {path: '/404', name: 'NotFound', meta: {title: '404找不到页面'}, component: NotFoundView},
    {path: '/:pathMatch(.*)*', redirect: '/404'}
];

const router = createRouter({
    history: createWebHistory(import.meta.env.BASE_URL),
    routes
});

router.beforeEach((to, from, next) => {
    document.title = to.meta.title || '志愿服务平台'; // 你可以设置一个默认的应用标题
    // 在这里实现登录验证和权限控制
    next();
});

export default router;