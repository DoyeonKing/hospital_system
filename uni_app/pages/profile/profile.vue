<template>
	<view class="container">
		<view class="page-header">
			<text class="page-title">个人中心</text>
		</view>
		
		<view class="content">
			<!-- 用户信息卡片 -->
			<view class="user-card">
				<view class="user-info">
					<view class="avatar-wrapper">
						<text class="avatar">👤</text>
					</view>
					<view class="user-details">
						<text class="user-name">{{ patientInfo.name || '患者' }}</text>
						<view class="user-id-wrapper">
							<text class="user-id">{{ displayIdentifier }}</text>
							<text class="eye-icon" @click.stop="toggleIdentifierMask">👁️</text>
						</view>
					</view>
				</view>
			</view>
			
			<!-- 待就诊卡片 -->
			<view class="upcoming-card" v-if="upcomingAppointment" @click="navigateToAppointments">
				<view class="upcoming-icon">🩺</view>
				<view class="upcoming-content">
					<text class="upcoming-title">待就诊</text>
					<text class="upcoming-info">{{ formatAppointmentTime(upcomingAppointment.scheduleTime) }} · {{ upcomingAppointment.departmentName }}</text>
				</view>
				<text class="upcoming-arrow">></text>
			</view>

			<!-- 功能列表 -->
			<view class="menu-list">
				<view class="menu-item" @click="navigateToEditProfile">
					<text class="menu-icon">📝</text>
					<text class="menu-text">编辑资料</text>
					<text class="menu-arrow">></text>
				</view>
				<view class="menu-item" @click="navigateToSettings">
					<text class="menu-icon">⚙️</text>
					<text class="menu-text">设置</text>
					<text class="menu-arrow">></text>
				</view>
				<view class="menu-item" @click="showAbout">
					<text class="menu-icon">ℹ️</text>
					<text class="menu-text">关于我们</text>
					<text class="menu-arrow">></text>
				</view>
			</view>

			<!-- 退出登录 -->
			<view class="logout-btn" @click="handleLogout">
				<text class="logout-text">退出登录</text>
			</view>
		</view>
	</view>
</template>

<script>
	export default {
		data() {
			return {
				patientInfo: {
					name: '张三',
					identifier: '2021001001'
				},
				upcomingAppointment: null,
				identifierMasked: true
			}
		},
		computed: {
			displayIdentifier() {
				if (!this.patientInfo.identifier) return '学号/工号'
				if (this.identifierMasked && this.patientInfo.identifier.length >= 8) {
					const len = this.patientInfo.identifier.length
					return this.patientInfo.identifier.substring(0, 4) + '****' + this.patientInfo.identifier.substring(len - 2)
				}
				return this.patientInfo.identifier
			}
		},
		onLoad() {
			this.loadPatientInfo()
			this.loadUpcomingCount()
		},
		onShow() {
			// 页面显示时刷新数据
			this.loadPatientInfo()
			this.loadUpcomingCount()
		},
		methods: {
			loadPatientInfo() {
				const patientInfo = uni.getStorageSync('patientInfo')
				if (patientInfo) {
					this.patientInfo = patientInfo
				} else {
					// 如果没有登录信息，使用模拟数据
					this.patientInfo = {
						name: '张三',
						identifier: '2021001001'
					}
				}
			},
			navigateToEditProfile() {
				uni.showToast({
					title: '编辑资料功能开发中',
					icon: 'none',
					duration: 2000
				})
			},
			navigateToSettings() {
				uni.showToast({
					title: '设置功能开发中',
					icon: 'none',
					duration: 2000
				})
			},
			showAbout() {
				uni.showModal({
					title: '关于我们',
					content: 'XX大学校医院\n地址：XX市XX区XX路XX号\n总机：0512-66666666\n急诊：0512-66666120\n\n门诊时间\n工作日 8:00-11:30 / 14:00-17:30\n周末仅上午',
					showCancel: false,
					confirmText: '知道了'
				})
			},
			loadUpcomingCount() {
				const upcomingAppointment = uni.getStorageSync('upcomingAppointment')
				if (upcomingAppointment) {
					this.upcomingAppointment = upcomingAppointment
				} else {
					this.upcomingAppointment = null
				}
			},
			formatAppointmentTime(timeString) {
				if (!timeString) return ''
				const date = new Date(timeString)
				const month = date.getMonth() + 1
				const day = date.getDate()
				const hours = date.getHours().toString().padStart(2, '0')
				const minutes = date.getMinutes().toString().padStart(2, '0')
				return month + '月' + day + '日 ' + hours + ':' + minutes
			},
			navigateToAppointments() {
				uni.switchTab({
					url: '/pages/appointments/appointments'
				})
			},
			toggleIdentifierMask() {
				this.identifierMasked = !this.identifierMasked
			},
			handleLogout() {
				uni.showModal({
					title: '提示',
					content: '确定要退出登录吗？',
					success: (res) => {
						if (res.confirm) {
							uni.removeStorageSync('patientToken')
							uni.removeStorageSync('patientInfo')
							uni.reLaunch({
								url: '/pages/login/patient-login'
							})
						}
					}
				})
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
		background: linear-gradient(135deg, lighten($color-primary, 10%) 0%, $color-primary 100%);
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

	.user-card {
		background: #ffffff;
		border-radius: 20rpx;
		padding: 40rpx;
		margin-bottom: 30rpx;
		box-shadow: 0 4rpx 20rpx rgba(0, 0, 0, 0.08);
	}

	.user-info {
		display: flex;
		align-items: center;
	}

	.avatar-wrapper {
		width: 120rpx;
		height: 120rpx;
		background: linear-gradient(135deg, lighten($color-primary, 10%) 0%, $color-primary 100%);
		border-radius: 50%;
		display: flex;
		align-items: center;
		justify-content: center;
		margin-right: 30rpx;
	}

	.avatar {
		font-size: 60rpx;
	}

	.user-details {
		flex: 1;
	}

	.user-name {
		display: block;
		font-size: 36rpx;
		font-weight: 700;
		color: #1A202C;
		margin-bottom: 12rpx;
	}

	.user-id-wrapper {
		display: flex;
		align-items: center;
		gap: 8rpx;
	}
	
	.user-id {
		font-size: 26rpx;
		color: #718096;
	}
	
	.eye-icon {
		font-size: 20rpx;
		opacity: 0.7;
	}
	
	.upcoming-card {
		background: #ffffff;
		border-radius: 20rpx;
		padding: 24rpx 30rpx;
		margin-bottom: 30rpx;
		box-shadow: 0 4rpx 20rpx rgba(0, 0, 0, 0.08);
		display: flex;
		align-items: center;
		transition: all 0.3s ease;
	}
	
	.upcoming-card:active {
		transform: translateY(-2rpx);
		box-shadow: 0 6rpx 24rpx rgba(0, 0, 0, 0.12);
	}
	
	.upcoming-icon {
		font-size: 40rpx;
		margin-right: 20rpx;
	}
	
	.upcoming-content {
		flex: 1;
		display: flex;
		flex-direction: column;
	}
	
	.upcoming-title {
		font-size: 28rpx;
		font-weight: 600;
		color: #1A202C;
		margin-bottom: 8rpx;
	}
	
	.upcoming-info {
		font-size: 24rpx;
		color: #718096;
	}
	
	.upcoming-arrow {
		font-size: 32rpx;
		color: #CBD5E0;
	}

	.menu-list {
		background: #ffffff;
		border-radius: 20rpx;
		margin-bottom: 30rpx;
		overflow: hidden;
		box-shadow: 0 4rpx 20rpx rgba(0, 0, 0, 0.08);
	}

	.menu-item {
		display: flex;
		align-items: center;
		padding: 32rpx 30rpx;
		border-bottom: 1rpx solid #F0F0F0;
		transition: all 0.3s ease;
	}

	.menu-item:last-child {
		border-bottom: none;
	}

	.menu-item:active {
		background: #F8F9FA;
	}

	.menu-icon {
		font-size: 40rpx;
		margin-right: 24rpx;
	}

	.menu-text {
		flex: 1;
		font-size: 30rpx;
		color: #1A202C;
	}

	.menu-arrow {
		font-size: 32rpx;
		color: #CBD5E0;
	}

	.logout-btn {
		background: #ffffff;
		border-radius: 20rpx;
		padding: 32rpx;
		text-align: center;
		box-shadow: 0 4rpx 20rpx rgba(0, 0, 0, 0.08);
	}

	.logout-text {
		font-size: 32rpx;
		color: #FF6B6B;
		font-weight: 600;
	}
</style>