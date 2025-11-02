<template>
	<view class="container">
		<view class="page-header">
			<text class="page-title">医生简介</text>
		</view>
		
		<view class="content">
			<!-- 医生基本信息卡片 -->
			<view class="doctor-header-card">
				<image class="doctor-avatar" :src="doctorInfo.photoUrl" mode="aspectFill"></image>
				<view class="doctor-basic">
					<view class="doctor-name-row">
						<text class="doctor-name">{{ doctorInfo.doctorName }}</text>
						<text class="doctor-title-badge">{{ doctorInfo.doctorTitle }}</text>
					</view>
					<view class="doctor-department">
						<text class="dept-icon">🏥</text>
						<text class="dept-text">{{ doctorInfo.departmentName }}</text>
					</view>
					<view class="doctor-specialty">
						<text class="specialty-icon">💊</text>
						<text class="specialty-text">{{ doctorInfo.specialty }}</text>
					</view>
				</view>
			</view>
			
			<!-- 个人简介 -->
			<view class="info-card">
				<view class="card-title">
					<text class="title-icon">📝</text>
					<text class="title-text">个人简介</text>
				</view>
				<view class="card-content">
					<text class="content-text">{{ doctorInfo.bio || '暂无简介' }}</text>
				</view>
			</view>
			
			<!-- 教育背景 -->
			<view class="info-card" v-if="doctorInfo.education">
				<view class="card-title">
					<text class="title-icon">🎓</text>
					<text class="title-text">教育背景</text>
				</view>
				<view class="card-content">
					<text class="content-text">{{ doctorInfo.education }}</text>
				</view>
			</view>
			
			<!-- 工作经验 -->
			<view class="info-card" v-if="doctorInfo.experience">
				<view class="card-title">
					<text class="title-icon">💼</text>
					<text class="title-text">工作经验</text>
				</view>
				<view class="card-content">
					<text class="content-text">{{ doctorInfo.experience }}</text>
				</view>
			</view>
			
			<!-- 荣誉奖项 -->
			<view class="info-card" v-if="doctorInfo.awards">
				<view class="card-title">
					<text class="title-icon">🏆</text>
					<text class="title-text">荣誉奖项</text>
				</view>
				<view class="card-content">
					<text class="content-text">{{ doctorInfo.awards }}</text>
				</view>
			</view>
		</view>
	</view>
</template>
<script>
	import { mockDoctorDetails } from '../../api/mockData.js'
	import { getDoctorById } from '../../api/schedule.js'
	
	export default {
		data() {
			return {
				doctorId: null,
				doctorInfo: {}
			}
		},
		onLoad(options) {
			this.doctorId = parseInt(options.doctorId || '1')
			this.loadDoctorInfo()
		},
		methods: {
			async loadDoctorInfo() {
				try {
					// 调用后端API获取医生详情
					const response = await getDoctorById(this.doctorId)
					console.log('医生详情API响应:', response)
					
					// 后端返回 DoctorResponse，需要适配格式
					if (response && response.fullName) {
						this.doctorInfo = {
							doctorName: response.fullName,
							doctorTitle: response.title || '医师',
							departmentName: response.department ? response.department.name : '未知科室',
							specialty: response.specialty || '暂无专长信息',
							photoUrl: response.photoUrl || 'https://cube.elemecdn.com/0/88/03b0d39583f48206768a7534e55bcpng.png',
							bio: response.bio || '医生详情功能开发中...'
						}
					} else {
						throw new Error('返回数据格式异常')
					}
				} catch (error) {
					console.error('获取医生详情失败:', error)
					// 如果后端失败，使用Mock数据作为fallback
					const doctor = mockDoctorDetails.find(d => d.doctorId === this.doctorId)
					if (doctor) {
						this.doctorInfo = doctor
					} else {
						// 如果没有找到医生，使用默认数据
						this.doctorInfo = {
							doctorName: '未知医生',
							doctorTitle: '医师',
							departmentName: '未知科室',
							specialty: '暂无专长信息',
							photoUrl: 'https://cube.elemecdn.com/0/88/03b0d39583f48206768a7534e55bcpng.png',
							bio: '医生详情功能开发中...'
						}
					}
				}
			}
		}
	}
</script>
<style lang="scss">
	.container {
		min-height: 100vh;
		background-color: #f7fafc;
	}

	.page-header {
		background: linear-gradient(135deg, #7be6d8 0%, #4FD9C3 100%);
		padding: 40rpx 30rpx 30rpx;
	}

	.page-title {
		font-size: 36rpx;
		font-weight: 700;
		color: #ffffff;
	}

	.content {
		padding: 30rpx;
	}

	.doctor-header-card {
		background: #ffffff;
		border-radius: 20rpx;
		padding: 40rpx;
		margin-bottom: 20rpx;
		display: flex;
		align-items: center;
		box-shadow: 0 2rpx 12rpx rgba(0, 0, 0, 0.06);
	}

	.doctor-avatar {
		width: 160rpx;
		height: 160rpx;
		border-radius: 50%;
		margin-right: 30rpx;
		background: #f0f0f0;
	}

	.doctor-basic {
		flex: 1;
	}

	.doctor-name-row {
		display: flex;
		align-items: baseline;
		margin-bottom: 16rpx;
	}

	.doctor-name {
		font-size: 40rpx;
		font-weight: 700;
		color: #1A202C;
		margin-right: 16rpx;
	}

	.doctor-title-badge {
		font-size: 24rpx;
		color: #718096;
		padding: 4rpx 12rpx;
		background: #F0FDFC;
		border-radius: 8rpx;
	}

	.doctor-department,
	.doctor-specialty {
		display: flex;
		align-items: center;
		margin-bottom: 8rpx;
	}

	.dept-icon,
	.specialty-icon {
		font-size: 28rpx;
		margin-right: 8rpx;
	}

	.dept-text,
	.specialty-text {
		font-size: 28rpx;
		color: #4A5568;
	}

	.info-card {
		background: #ffffff;
		border-radius: 20rpx;
		padding: 30rpx;
		margin-bottom: 20rpx;
		box-shadow: 0 2rpx 12rpx rgba(0, 0, 0, 0.06);
	}

	.card-title {
		display: flex;
		align-items: center;
		margin-bottom: 20rpx;
		padding-bottom: 20rpx;
		border-bottom: 1rpx solid #f0f0f0;
	}

	.title-icon {
		font-size: 32rpx;
		margin-right: 12rpx;
	}

	.title-text {
		font-size: 30rpx;
		font-weight: 600;
		color: #1A202C;
	}

	.card-content {
		padding: 10rpx 0;
	}

	.content-text {
		font-size: 28rpx;
		color: #4A5568;
		line-height: 2;
	}
</style>