import { defineStore } from 'pinia';
import request from '@/utils/request.js';
// 【新增】导入 auth.js (即使是空的，也需要导入)
import { doctorLogin } from '@/api/auth';

// Key for localStorage
const DOCTOR_SESSION_KEY = 'xm-pro-doctor'; // 医生会话的localStorage key

export const useDoctorStore = defineStore('doctor', {
    state: () => ({
        // 【已修改】如果 localStorage 中没有，默认为 null
        loggedInDoctorBasicInfo: JSON.parse(localStorage.getItem(DOCTOR_SESSION_KEY)) || null,

        // 【已修改】详细信息默认为空对象
        detailedDoctorInfo: {
            doctorId: '',
            name: '',
            department: '',
            position: '',
            phone: '',
            username: '',
            specialty: '', // 擅长领域
            bio: '',       // 个人简介
            photoUrl: '',  // 头像URL
        },
        isLoading: false,
        error: null,
    }),

    getters: {
        // 【已修改】 isAuthenticated 现在会检查 token 是否存在
        isAuthenticated: (state) => !!state.loggedInDoctorBasicInfo?.token,

        // 显示名称
        displayName: (state) => state.detailedDoctorInfo.name || state.loggedInDoctorBasicInfo?.name || state.loggedInDoctorBasicInfo?.identifier || '医生',
        // 获取医生ID
        currentDoctorId: (state) => state.detailedDoctorInfo.doctorId || state.loggedInDoctorBasicInfo?.identifier || '1',
        // 获取科室信息
        currentDepartment: (state) => state.detailedDoctorInfo.department,
        // 获取职位信息
        currentPosition: (state) => state.detailedDoctorInfo.position,
    },

    actions: {
        // 登录成功后调用的 action
        loginSuccess(apiResponseData, basicLoginInfoFromLogin) {
            // 保存详细医生信息
            this.detailedDoctorInfo = {
                doctorId: apiResponseData.doctorInfo?.doctorId || '1', // 虚拟ID
                name: apiResponseData.doctorInfo?.name || '测试医生', // 虚拟名称
                department: apiResponseData.doctorInfo?.department || '内科',
                position: apiResponseData.doctorInfo?.position || '主治医师',
                phone: apiResponseData.doctorInfo?.phone || '13900139000',
                username: basicLoginInfoFromLogin.identifier || 'D001',
                // --- 【新增字段】 ---
                specialty: apiResponseData.doctorInfo?.specialty || '高血压、糖尿病',
                bio: apiResponseData.doctorInfo?.bio || '经验丰富的内科医生。',
                photoUrl: apiResponseData.doctorInfo?.photoUrl || '@/assets/doctor.jpg',
                // ---------------------
            };

            // 保存基本登录信息到 localStorage
            const basicInfo = {
                identifier: basicLoginInfoFromLogin.identifier,
                token: basicLoginInfoFromLogin.token || 'mock-token', // 虚拟Token
                loginTime: new Date().toISOString(),
            };

            localStorage.setItem(DOCTOR_SESSION_KEY, JSON.stringify(basicInfo));
            this.loggedInDoctorBasicInfo = basicInfo;

            // 确保状态立即更新
            console.log('DoctorStore: 登录状态已更新', this.loggedInDoctorBasicInfo);

            // 清除错误状态
            this.error = null;
        },

        // 登出 action
        logout() {
            // 清除 localStorage
            localStorage.removeItem(DOCTOR_SESSION_KEY);

            // 重置状态
            this.loggedInDoctorBasicInfo = null;
            this.detailedDoctorInfo = {
                doctorId: '',
                name: '',
                department: '',
                position: '',
                phone: '',
                username: '',
                specialty: '',
                bio: '',
                photoUrl: '',
            };
            this.error = null;
        },

        // 获取详细医生信息（如果需要的话）
        async fetchDetailedDoctorInfo() {
            if (!this.isAuthenticated) {
                this.error = '未登录';
                return;
            }

            this.isLoading = true;
            this.error = null;

            try {
                // 【模拟】在 Store 中直接使用模拟数据，跳过 API
                this.detailedDoctorInfo = {
                    ...this.detailedDoctorInfo,
                    doctorId: '1',
                    name: '测试医生 (虚拟)',
                    department: '内科 (虚拟)',
                    position: '主治医师 (虚拟)',
                    phone: '13900139000',
                    username: this.loggedInDoctorBasicInfo.identifier,
                    specialty: '高血压、糖尿病、冠心病等心脑血管疾病。',
                    bio: '从事内科临床工作10余年，经验丰富，擅长各种内科常见病及多发病的诊治。',
                    photoUrl: '@/assets/doctor.jpg'
                };

                // --- 【真实接口 - 已注释】 ---
                // const response = await request({
                //     url: '/api/doctor/profile',
                //     method: 'GET',
                //     headers: {
                //         'Authorization': `Bearer ${this.loggedInDoctorBasicInfo.token}`
                //     }
                // });
                // if (response.code === '200' || response.code === 200) {
                //     this.detailedDoctorInfo = {
                //         ...this.detailedDoctorInfo,
                //         ...response.data
                //     };
                // } else {
                //     this.error = response.msg || '获取医生信息失败';
                // }

            } catch (error) {
                console.error('获取医生详细信息失败:', error);
                this.error = '网络错误，请稍后重试';
            } finally {
                this.isLoading = false;
            }
        },

        // 更新医生信息
        async updateDoctorInfo(updateData) {
            if (!this.isAuthenticated) {
                this.error = '未登录';
                return false;
            }
            this.isLoading = true;
            this.error = null;

            try {
                // 【模拟】
                await new Promise(r => setTimeout(r, 500)); // 模拟网络延迟
                this.detailedDoctorInfo = {
                    ...this.detailedDoctorInfo,
                    ...updateData
                };
                return true; // 模拟成功

                // --- 【真实接口 - 已注释】 ---
                // const response = await request({
                //     url: '/api/doctor/update-profile',
                //     method: 'PUT',
                //     data: updateData,
                //     headers: {
                //         'Authorization': `Bearer ${this.loggedInDoctorBasicInfo.token}`
                //     }
                // });

                // if (response.code === '200' || response.code === 200) {
                //     this.detailedDoctorInfo = {
                //         ...this.detailedDoctorInfo,
                //         ...updateData
                //     };
                //     return true;
                // } else {
                //     this.error = response.msg || '更新医生信息失败';
                //     return false;
                // }
            } catch (error) {
                console.error('更新医生信息失败:', error);
                this.error = '网络错误，请稍后重试';
                return false;
            } finally {
                this.isLoading = false;
            }
        },

        // 修改密码
        async changePassword(oldPassword, newPassword) {
            if (!this.isAuthenticated) {
                this.error = '未登录';
                return false;
            }
            this.isLoading = true;
            this.error = null;

            try {
                // 【模拟】
                await new Promise(r => setTimeout(r, 500));
                if (oldPassword !== '123456') { // 模拟旧密码错误
                    this.error = '旧密码错误 (模拟)';
                    return false;
                }
                return true; // 模拟成功

                // --- 【真实接口 - 已注释】 ---
                // const response = await request({
                //     url: '/api/doctor/change-password',
                //     method: 'PUT',
                //     data: {
                //         oldPassword,
                //         newPassword
                //     },
                //     headers: {
                //         'Authorization': `Bearer ${this.loggedInDoctorBasicInfo.token}`
                //     }
                // });

                // if (response.code === '200' || response.code === 200) {
                //     return true;
                // } else {
                //     this.error = response.msg || '修改密码失败';
                //     return false;
                // }
            } catch (error) {
                console.error('修改密码失败:', error);
                this.error = '网络错误，请稍后重试';
                return false;
            } finally {
                this.isLoading = false;
            }
        }
    }
});