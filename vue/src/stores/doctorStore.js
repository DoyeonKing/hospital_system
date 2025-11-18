import { defineStore } from 'pinia';
import request from '@/utils/request.js';
// 【新增】导入 auth.js (即使是空的，也需要导入)
import { doctorLogin } from '@/api/auth';

// Key for localStorage
const DOCTOR_SESSION_KEY = 'xm-pro-doctor'; // 基础会话信息的key
const DETAILED_INFO_KEY = 'xm-pro-doctor-detail'; // 详细信息的key

export const useDoctorStore = defineStore('doctor', {
    state: () => ({
        // 1. 基础信息 (Token, ID)
        // 从 localStorage 读取，防止刷新丢失
        loggedInDoctorBasicInfo: JSON.parse(localStorage.getItem(DOCTOR_SESSION_KEY)) || null,

        // 2. 详细信息 (姓名、科室、头像等)
        // 从 localStorage 读取，防止刷新丢失。如果没读到，给定默认空对象结构
        detailedDoctorInfo: JSON.parse(localStorage.getItem(DETAILED_INFO_KEY)) || {
            doctorId: '',
            name: '',
            department: '',
            position: '',
            phone: '',
            username: '',
            specialty: '',
            bio: '',
            photoUrl: '',
        },
        isLoading: false,
        error: null,
    }),

    getters: {
        // isAuthenticated: 检查 token 是否存在
        isAuthenticated: (state) => !!state.loggedInDoctorBasicInfo?.token,

        // 显示名称: 优先显示真实姓名，没有则显示工号
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
            // 从 API 响应中提取详细信息
            const info = apiResponseData.doctorInfo || {};

            // 1. 更新 State 中的详细信息
            this.detailedDoctorInfo = {
                doctorId: String(info.doctorId || ''),
                name: info.name || '',
                department: info.department || '',
                position: info.position || '',
                phone: info.phone || '',
                username: info.username || basicLoginInfoFromLogin.identifier || '',
                specialty: info.specialty || '',
                bio: info.bio || '',
                photoUrl: info.photoUrl || '',
            };

            // 2. 更新 State 中的基础信息
            const basicInfo = {
                identifier: basicLoginInfoFromLogin.identifier,
                token: basicLoginInfoFromLogin.token || '',
                loginTime: new Date().toISOString(),
            };
            this.loggedInDoctorBasicInfo = basicInfo;

            // 3. 持久化存储到 localStorage (存两份，确保刷新后数据还在)
            localStorage.setItem(DOCTOR_SESSION_KEY, JSON.stringify(basicInfo));
            localStorage.setItem(DETAILED_INFO_KEY, JSON.stringify(this.detailedDoctorInfo));

            console.log('DoctorStore: 登录状态已更新并缓存');
            this.error = null;
        },

        // 登出 action
        logout() {
            // 清除 localStorage
            localStorage.removeItem(DOCTOR_SESSION_KEY);
            localStorage.removeItem(DETAILED_INFO_KEY);

            // 重置 State
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

        // 获取详细医生信息（用于页面刷新或数据同步）
        async fetchDetailedDoctorInfo() {
            if (!this.isAuthenticated) {
                this.error = '未登录';
                return;
            }

            this.isLoading = true;
            this.error = null;

            try {
                const response = await request({
                    url: '/api/doctor/profile',
                    method: 'GET',
                    headers: {
                        'Authorization': `Bearer ${this.loggedInDoctorBasicInfo.token}`
                    }
                });

                if (response.code === '200' || response.code === 200) {
                    // 更新 State (合并新数据)
                    const data = response.data || {};
                    this.detailedDoctorInfo = {
                        ...this.detailedDoctorInfo,
                        name: data.fullName || this.detailedDoctorInfo.name,
                        department: data.departmentName || this.detailedDoctorInfo.department,
                        position: data.title || this.detailedDoctorInfo.position,
                        phone: data.phoneNumber || this.detailedDoctorInfo.phone,
                        specialty: data.specialty || this.detailedDoctorInfo.specialty,
                        bio: data.bio || this.detailedDoctorInfo.bio,
                        photoUrl: data.photoUrl || this.detailedDoctorInfo.photoUrl
                    };
                    // 更新缓存
                    localStorage.setItem(DETAILED_INFO_KEY, JSON.stringify(this.detailedDoctorInfo));
                }
            } catch (error) {
                console.error('获取医生详细信息失败:', error);
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
                const response = await request({
                    url: '/api/doctor/update-profile',
                    method: 'PUT',
                    data: updateData,
                    headers: {
                        'Authorization': `Bearer ${this.loggedInDoctorBasicInfo.token}`
                    }
                });

                if (response.code === '200' || response.code === 200) {
                    // 更新本地状态
                    this.detailedDoctorInfo = {
                        ...this.detailedDoctorInfo,
                        ...updateData
                    };
                    // 更新缓存
                    localStorage.setItem(DETAILED_INFO_KEY, JSON.stringify(this.detailedDoctorInfo));
                    return true;
                } else {
                    this.error = response.msg || '更新医生信息失败';
                    return false;
                }
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
                const response = await request({
                    url: '/api/doctor/change-password',
                    method: 'PUT',
                    data: {
                        oldPassword,
                        newPassword
                    },
                    headers: {
                        'Authorization': `Bearer ${this.loggedInDoctorBasicInfo.token}`
                    }
                });

                if (response.code === '200' || response.code === 200) {
                    return true;
                } else {
                    this.error = response.msg || '修改密码失败';
                    return false;
                }
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