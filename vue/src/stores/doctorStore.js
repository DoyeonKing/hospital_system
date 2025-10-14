import { defineStore } from 'pinia';
import request from '@/utils/request.js';

// Key for localStorage
const DOCTOR_SESSION_KEY = 'xm-pro-doctor'; // 医生会话的localStorage key

export const useDoctorStore = defineStore('doctor', {
    state: () => ({
        // 存储从 localStorage 读取的基本医生登录信息
        loggedInDoctorBasicInfo: JSON.parse(localStorage.getItem(DOCTOR_SESSION_KEY)) || null,
        // 存储通过 API 获取的详细医生信息
        detailedDoctorInfo: {
            doctorId: '',
            name: '',
            department: '',
            position: '',
            phone: '',
            username: '',
            // 其他医生相关信息
        },
        isLoading: false, // 可选：用于跟踪API请求状态
        error: null,      // 可选：用于存储API请求错误
    }),

    getters: {
        // 显示名称
        displayName: (state) => state.detailedDoctorInfo.name || state.loggedInDoctorBasicInfo?.name || state.loggedInDoctorBasicInfo?.identifier || '医生',
        // 是否已登录
        isAuthenticated: (state) => !!state.loggedInDoctorBasicInfo,
        // 获取医生ID
        currentDoctorId: (state) => state.detailedDoctorInfo.doctorId || state.loggedInDoctorBasicInfo?.identifier,
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
                doctorId: apiResponseData.doctorInfo?.doctorId || '',
                name: apiResponseData.doctorInfo?.name || '',
                department: apiResponseData.doctorInfo?.department || '',
                position: apiResponseData.doctorInfo?.position || '',
                phone: apiResponseData.doctorInfo?.phone || '',
                username: basicLoginInfoFromLogin.identifier || '',
            };

            // 保存基本登录信息到 localStorage
            const basicInfo = {
                identifier: basicLoginInfoFromLogin.identifier,
                token: basicLoginInfoFromLogin.token,
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
                const response = await request({
                    url: '/api/doctor/profile',
                    method: 'GET',
                    headers: {
                        'Authorization': `Bearer ${this.loggedInDoctorBasicInfo.token}`
                    }
                });

                if (response.code === '200') {
                    this.detailedDoctorInfo = {
                        ...this.detailedDoctorInfo,
                        ...response.data
                    };
                } else {
                    this.error = response.msg || '获取医生信息失败';
                }
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
                const response = await request({
                    url: '/api/doctor/update-profile',
                    method: 'PUT',
                    data: updateData,
                    headers: {
                        'Authorization': `Bearer ${this.loggedInDoctorBasicInfo.token}`
                    }
                });

                if (response.code === '200') {
                    // 更新本地状态
                    this.detailedDoctorInfo = {
                        ...this.detailedDoctorInfo,
                        ...updateData
                    };
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

                if (response.code === '200') {
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
