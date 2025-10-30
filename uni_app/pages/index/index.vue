<template>
	<view class="container">
		<!-- 顶部用户信息区域 -->
		<view class="header">
			<view class="header-bg"></view>
			<view class="user-info">
				<view class="logo-wrapper">
					<image class="logo" src="/static/logo.png" mode="aspectFit"></image>
				</view>
				<view class="user-details">
					<text class="greeting">您好，</text>
					<text class="user-name">{{ patientInfo.name || '患者' }}</text>
					<view class="user-id-wrapper">
						<text class="user-id">{{ displayIdentifier }}</text>
						<text class="eye-icon" @click.stop="toggleIdentifierMask">👁️</text>
					</view>
				</view>
				<view class="notification-bell" @click="navigateToMessages">
					<text class="bell-icon">🔔</text>
					<view class="notification-badge" v-if="unreadCount > 0">
						<text class="badge-text">{{ unreadCount > 99 ? '99+' : unreadCount }}</text>
					</view>
				</view>
			</view>
		</view>

		<!-- 主要功能入口（2x2网格布局） -->
		<view class="main-functions">
			<view class="function-card card-1" @click="navigateToDepartments">
				<view class="icon-wrapper">
					<view class="function-icon">🏥</view>
				</view>
				<text class="function-title">预约挂号</text>
			</view>
			
			<view class="function-card card-2" @click="navigateToMyAppointments">
				<view class="icon-wrapper">
					<view class="function-icon">📅</view>
				</view>
				<text class="function-title">我的预约</text>
			</view>
			
			<view class="function-card card-3" @click="navigateToProfile">
				<view class="icon-wrapper">
					<view class="function-icon">👤</view>
				</view>
				<text class="function-title">个人中心</text>
			</view>
			
			<view class="function-card card-4" @click="showContactInfo">
				<view class="icon-wrapper">
					<view class="function-icon">📞</view>
				</view>
				<text class="function-title">联系我们</text>
			</view>
		</view>

		<!-- 合并的信息卡片：今日可预约 + 热门科室 -->
		<view class="info-card">
			<view class="card-header">
				<text class="card-title">今日可预约</text>
				<text class="view-all" @click="navigateToDepartments">查看全部 ></text>
			</view>
			<!-- 骨架屏 -->
			<view class="skeleton-container" v-if="loading && todaySchedules.length === 0">
				<view class="skeleton-item" v-for="i in 4" :key="i" :style="{ animationDelay: `${(i - 1) * 100}ms` }"></view>
			</view>
			<!-- 数据列表 -->
			<view class="schedule-grid" v-else-if="todaySchedules.length > 0">
				<view 
					class="schedule-item" 
					v-for="schedule in todaySchedules.slice(0, 4)" 
					:key="schedule.id"
					@click="navigateToDepartmentSchedule(schedule.departmentId)"
				>
					<text class="dept-name">{{ schedule.departmentName }}</text>
					<text class="available-count">还剩 {{ schedule.availableSlots }} 号</text>
				</view>
			</view>
			<!-- 空状态 -->
			<view class="empty-state" v-else>
				<text class="empty-icon">🩺</text>
				<text class="empty-text">今日号源已约满，明日 8:00 放号</text>
				<view class="empty-btn" @click="navigateToDepartments">
					<text class="empty-btn-text">去挂号</text>
				</view>
			</view>
			<view class="card-divider"></view>
			<view class="card-header">
				<text class="card-title">热门科室</text>
			</view>
			<!-- 热门科室骨架屏 -->
			<view class="skeleton-tags" v-if="loading && popularDepartments.length === 0">
				<view class="skeleton-tag" v-for="i in 6" :key="i" :style="{ animationDelay: `${(i - 1) * 200}ms` }"></view>
			</view>
			<!-- 热门科室列表 -->
			<view v-else-if="popularDepartments.length > 0">
				<view class="department-tags" :class="{ 'tags-collapsed': !showAllDepartments }">
					<view 
						class="department-tag" 
						v-for="dept in popularDepartments" 
						:key="dept.id"
						@click="navigateToDepartmentSchedule(dept.id)"
					>
						<text class="tag-text">{{ dept.name }}</text>
					</view>
				</view>
				<view class="more-btn" @click="toggleDepartments" v-if="popularDepartments.length > 4">
					<text class="more-btn-text">{{ showAllDepartments ? '收起 ∧' : '更多 ∨' }}</text>
				</view>
			</view>
			<!-- 热门科室空状态 -->
			<view class="empty-state-small" v-else>
				<text class="empty-icon-small">🏥</text>
				<text class="empty-text-small">暂无热门科室</text>
				<view class="empty-btn-small" @click="navigateToDepartments">
					<text class="empty-btn-text-small">去挂号</text>
				</view>
			</view>
		</view>

		<!-- 即将就诊提醒卡片（简化版） -->
		<view class="appointment-card" v-if="upcomingAppointment && isWithin24Hours">
			<view class="appointment-icon">🔔</view>
			<view class="appointment-content">
				<text class="appointment-title">即将就诊</text>
				<text class="appointment-info-text">{{ formatTime(upcomingAppointment.scheduleTime) }} · {{ upcomingAppointment.departmentName }} · {{ upcomingAppointment.doctorName }}</text>
			</view>
			<text class="appointment-number">#{{ upcomingAppointment.queueNumber }}</text>
		</view>

		<!-- 加载状态 -->
		<view class="loading" v-if="loading">
			<text class="loading-text">加载中...</text>
		</view>
	</view>
</template>

<script>
	import { mockTodaySchedules, mockUpcomingAppointment, mockPopularDepartments, mockPatientInfo, mockMessages } from '../../api/mockData.js'
	
	export default {
		data() {
			return {
				loading: false,
				hasNetworkError: false,
				isRefreshing: false,
				patientInfo: {
					name: '张三',
					identifier: '2021001001'
				},
				todaySchedules: [],
				upcomingAppointment: null,
				popularDepartments: [],
				unreadCount: 0,
				showAllDepartments: false,
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
			},
			isWithin24Hours() {
				if (!this.upcomingAppointment || !this.upcomingAppointment.scheduleTime) return false
				const scheduleTime = new Date(this.upcomingAppointment.scheduleTime)
				const now = new Date()
				const diff = scheduleTime - now
				return diff > 0 && diff <= 24 * 60 * 60 * 1000
			}
		},
		onLoad() {
			this.checkLoginStatus()
			this.loadPageData()
		},
		onShow() {
			// 页面显示时刷新数据
			this.loadPageData()
			// 同步待就诊数量到storage
			if (this.upcomingAppointment) {
				uni.setStorageSync('upcomingAppointment', this.upcomingAppointment)
			} else {
				uni.removeStorageSync('upcomingAppointment')
			}
		},
		onPullDownRefresh() {
			// 下拉刷新
			this.isRefreshing = true
			this.loadPageData()
			this.isRefreshing = false
			uni.stopPullDownRefresh()
		},
		methods: {
			// 检查登录状态
			checkLoginStatus() {
				const token = uni.getStorageSync('patientToken')
				const patientInfo = uni.getStorageSync('patientInfo')
				
				// 如果没有登录信息，使用模拟数据（仅用于演示）
				if (!token || !patientInfo) {
					console.log('使用模拟数据演示页面功能')
					this.patientInfo = mockPatientInfo
					return true
				}
				
				this.patientInfo = patientInfo
				return true
			},
			
			// 加载页面数据 - 直接使用模拟数据，避免API调用失败
			loadPageData() {
				// 先检查登录状态
				this.checkLoginStatus()
				
				this.loading = true
				this.hasNetworkError = false
				
				// 直接使用测试数据，确保页面有内容显示
				this.todaySchedules = JSON.parse(JSON.stringify(mockTodaySchedules))
				this.upcomingAppointment = JSON.parse(JSON.stringify(mockUpcomingAppointment))
				this.popularDepartments = JSON.parse(JSON.stringify(mockPopularDepartments))
				this.unreadCount = mockMessages.filter(msg => !msg.isRead).length
				
				this.loading = false
			},
			
			
			// 导航到消息中心
			navigateToMessages() {
				uni.switchTab({
					url: '/pages/messages/messages'
				})
			},
			
			// 格式化时间
			formatTime(timeString) {
				if (!timeString) return ''
				const date = new Date(timeString)
				const month = date.getMonth() + 1
				const day = date.getDate()
				const hours = date.getHours().toString().padStart(2, '0')
				const minutes = date.getMinutes().toString().padStart(2, '0')
				return month + '月' + day + '日 ' + hours + ':' + minutes
			},
			
			// 导航到科室列表
			navigateToDepartments() {
				uni.showToast({
					title: '跳转到科室列表',
					icon: 'none',
					duration: 2000
				})
				// TODO: 实现科室列表页面跳转
				// uni.navigateTo({
				//     url: '/pages/departments/departments'
				// })
			},
			
			// 导航到我的预约
			navigateToMyAppointments() {
				uni.switchTab({
					url: '/pages/appointments/appointments'
				})
			},
			
			// 导航到个人中心
			navigateToProfile() {
				uni.switchTab({
					url: '/pages/profile/profile'
				})
			},
			
			// 显示联系方式
			showContactInfo() {
				uni.showActionSheet({
					itemList: ['客服电话', '紧急求助', '医院地址', '更多信息'],
					success: (res) => {
						switch(res.tapIndex) {
							case 0:
								// 客服电话
								uni.makePhoneCall({
									phoneNumber: '400-123-4567',
									fail: () => {
										uni.showModal({
											title: '客服电话',
											content: '400-123-4567\n工作时间：周一至周日 8:00-18:00',
											showCancel: false,
											confirmText: '知道了'
										})
									}
								})
								break
							case 1:
								// 紧急求助
								uni.showModal({
									title: '紧急求助',
									content: '如有紧急情况，请拨打120急救电话\n或直接前往医院急诊科',
									confirmText: '拨打120',
									cancelText: '取消',
									success: (modalRes) => {
										if (modalRes.confirm) {
											uni.makePhoneCall({
												phoneNumber: '120',
												fail: () => {
													uni.showToast({
														title: '请手动拨打120',
														icon: 'none',
														duration: 2000
													})
												}
											})
										}
									}
								})
								break
							case 2:
								// 医院地址
								uni.showModal({
									title: '医院地址',
									content: 'XX大学校医院\n地址：XX市XX区XX路XX号\n邮编：100000',
									showCancel: false,
									confirmText: '知道了'
								})
								break
							case 3:
								// 更多信息
								uni.showModal({
									title: '联系我们',
									content: '客服电话：400-123-4567\n工作时间：周一至周日 8:00-18:00\n邮箱：service@hospital.edu.cn\n地址：XX市XX区XX路XX号',
									showCancel: false,
									confirmText: '知道了'
								})
								break
						}
					}
				})
			},
			
			// 导航到科室排班
			navigateToDepartmentSchedule(departmentId) {
				uni.showToast({
					title: '跳转到科室' + departmentId + '排班',
					icon: 'none',
					duration: 2000
				})
				// TODO: 实现科室排班页面跳转
				// uni.navigateTo({
				//     url: `/pages/schedule/schedule?departmentId=${departmentId}`
				// })
			},
			
			// 切换热门科室展开/收起
			toggleDepartments() {
				this.showAllDepartments = !this.showAllDepartments
			},
			
			// 切换学号脱敏显示
			toggleIdentifierMask() {
				this.identifierMasked = !this.identifierMasked
			}
		}
	}
</script>

<style lang="scss">
	.container {
		min-height: 100vh;
		background-color: #f7fafc;
		padding-bottom: 30rpx;
	}

	/* 头部用户信息区域 */
	.header {
		position: relative;
		padding: 40rpx 30rpx 35rpx;
		overflow: hidden;
	}

	.header-bg {
		position: absolute;
		top: 0;
		left: 0;
		right: 0;
		bottom: 0;
		background: linear-gradient(135deg, lighten($color-primary, 10%) 0%, $color-primary 100%);
		opacity: 0.95;
	}

	.header-bg::after {
		content: '';
		position: absolute;
		top: -50%;
		right: -20%;
		width: 400rpx;
		height: 400rpx;
		background: radial-gradient(circle, rgba(255,255,255,0.2) 0%, transparent 70%);
		border-radius: 50%;
	}

	.user-info {
		position: relative;
		z-index: 1;
		display: flex;
		align-items: center;
	}

	.logo-wrapper {
		width: 90rpx;
		height: 90rpx;
		background: rgba(255, 255, 255, 0.25);
		border-radius: 20rpx;
		display: flex;
		align-items: center;
		justify-content: center;
		backdrop-filter: blur(10rpx);
		margin-right: 24rpx;
		padding: 8rpx;
	}

	.logo {
		width: 100%;
		height: 100%;
		border-radius: 16rpx;
	}

	.user-details {
		flex: 1;
	}

	.greeting {
		display: block;
		font-size: 24rpx;
		color: rgba(255, 255, 255, 0.9);
		margin-bottom: 4rpx;
	}

	.user-name {
		display: block;
		font-size: 36rpx;
		font-weight: 700;
		color: #ffffff;
		margin-bottom: 6rpx;
		text-shadow: 0 2rpx 8rpx rgba(0, 0, 0, 0.15);
	}

	.user-id-wrapper {
		display: flex;
		align-items: center;
		gap: 8rpx;
	}
	
	.user-id {
		font-size: 24rpx;
		color: rgba(255, 255, 255, 0.8);
	}
	
	.eye-icon {
		font-size: 20rpx;
		opacity: 0.7;
	}

	/* 消息通知图标 */
	.notification-bell {
		position: relative;
		width: 64rpx;
		height: 64rpx;
		display: flex;
		align-items: center;
		justify-content: center;
		background: rgba(255, 255, 255, 0.25);
		border-radius: 50%;
		backdrop-filter: blur(10rpx);
		margin-left: 20rpx;
		transition: all 0.3s ease;
	}

	.notification-bell:active {
		transform: scale(0.9);
		background: rgba(255, 255, 255, 0.35);
	}

	.bell-icon {
		font-size: 36rpx;
	}

	.notification-badge {
		position: absolute;
		top: -4rpx;
		right: -4rpx;
		background: #FF6B6B;
		border-radius: 20rpx;
		min-width: 32rpx;
		height: 32rpx;
		display: flex;
		align-items: center;
		justify-content: center;
		padding: 0 8rpx;
		border: 2rpx solid #ffffff;
		box-shadow: 0 2rpx 8rpx rgba(255, 107, 107, 0.4);
	}

	.badge-text {
		font-size: 20rpx;
		color: #ffffff;
		font-weight: 700;
		line-height: 1;
	}

	/* 主要功能入口（2x2网格布局） */
	.main-functions {
		padding: 30rpx 30rpx 25rpx;
		display: grid;
		grid-template-columns: 1fr 1fr;
		gap: 20rpx;
	}

	.function-card {
		background: #ffffff;
		border-radius: 20rpx;
		padding: 32rpx 20rpx;
		text-align: center;
		box-shadow: 0 4rpx 20rpx rgba(0, 0, 0, 0.08);
		transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
		position: relative;
		overflow: hidden;
	}

	.function-card::before {
		content: '';
		position: absolute;
		top: 0;
		left: 0;
		right: 0;
		bottom: 0;
		opacity: 0;
		transition: opacity 0.3s ease;
	}

	.function-card:active {
		transform: translateY(-4rpx);
		box-shadow: 0 8rpx 24rpx rgba(0, 0, 0, 0.12);
	}

	.function-card:active::before {
		opacity: 1;
	}

	/* 无障碍支持 */
	.function-card:focus {
		outline: 2rpx solid $color-primary;
		outline-offset: 2rpx;
	}

	.card-1 .icon-wrapper {
		background-color: #E6FFFA;
	}

	.card-2 .icon-wrapper {
		background-color: #EBF4FF;
	}

	.card-3 .icon-wrapper {
		background-color: #F0F9FF;
	}

	.card-4 .icon-wrapper {
		background-color: #FEF3C7;
	}

	.icon-wrapper {
		width: 88rpx;
		height: 88rpx;
		margin: 0 auto 16rpx;
		border-radius: 20rpx;
		display: flex;
		align-items: center;
		justify-content: center;
		box-shadow: 0 4rpx 12rpx rgba(0, 0, 0, 0.15);
	}

	.function-icon {
		font-size: 44rpx;
		color: $color-primary;
	}

	.function-title {
		display: block;
		font-size: 28rpx;
		font-weight: 600;
		color: #2D3748;
	}

	/* 信息卡片通用样式 */
	.info-card {
		background: #ffffff;
		margin: 0 30rpx 20rpx;
		border-radius: 24rpx;
		padding: 28rpx;
		box-shadow: 0 4rpx 20rpx rgba(0, 0, 0, 0.08);
	}

	.card-header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: 20rpx;
	}

	.card-title {
		font-size: 32rpx;
		font-weight: 700;
		color: #1A202C;
		position: relative;
		padding-left: 12rpx;
	}

	.card-title::before {
		content: '';
		position: absolute;
		left: 0;
		top: 50%;
		transform: translateY(-50%);
		width: 4rpx;
		height: 24rpx;
		background: linear-gradient(180deg, lighten($color-primary, 10%) 0%, $color-primary 100%);
		border-radius: 2rpx;
	}

	.view-all {
		font-size: 24rpx;
		color: $color-primary;
		font-weight: 500;
	}

	.card-divider {
		height: 1rpx;
		background: linear-gradient(90deg, transparent 0%, #E2E8F0 50%, transparent 100%);
		margin: 24rpx 0;
	}

	/* 今日可预约网格样式 */
	.schedule-grid {
		display: grid;
		grid-template-columns: 1fr 1fr;
		gap: 16rpx;
	}

	.schedule-item {
		background: linear-gradient(135deg, #F7FAFC 0%, #EDF2F7 100%);
		border-radius: 16rpx;
		padding: 20rpx 18rpx;
		display: flex;
		flex-direction: column;
		justify-content: space-between;
		border: 1rpx solid #E2E8F0;
		transition: all 0.3s ease;
	}

	.schedule-item:active {
		background: linear-gradient(135deg, lighten($color-primary, 10%) 0%, $color-primary 100%);
		transform: translateY(-2rpx);
		box-shadow: 0 6rpx 16rpx rgba(79, 209, 197, 0.3);
	}

	.schedule-item:active .dept-name,
	.schedule-item:active .available-count {
		color: #ffffff;
	}

	.dept-name {
		font-size: 28rpx;
		color: #2D3748;
		font-weight: 600;
		margin-bottom: 10rpx;
		transition: color 0.3s ease;
	}

	.available-count {
		font-size: 24rpx;
		color: $color-primary;
		font-weight: 700;
		transition: color 0.3s ease;
	}

	.department-tags {
		display: flex;
		gap: 12rpx;
		padding: 4rpx 0;
		flex-wrap: wrap;
	}
	
	.department-tags.tags-collapsed {
		max-height: 120rpx;
		overflow: hidden;
	}
	
	.department-tag {
		background: linear-gradient(135deg, lighten($color-primary, 10%) 0%, $color-primary 100%);
		border-radius: 16rpx;
		padding: 6rpx 16rpx;
		white-space: nowrap;
		transition: all 0.3s ease;
		box-shadow: 0 4rpx 12rpx rgba(79, 209, 197, 0.25);
	}

	.department-tag:active {
		transform: translateY(-2rpx) scale(0.98);
		box-shadow: 0 6rpx 16rpx rgba(79, 209, 197, 0.35);
	}
	
	.more-btn {
		margin-top: 16rpx;
		text-align: center;
		padding: 12rpx;
	}
	
	.more-btn-text {
		font-size: 24rpx;
		color: $color-primary;
		font-weight: 500;
	}

	.tag-text {
		font-size: 22rpx;
		color: #ffffff;
		font-weight: 600;
	}

	/* 即将就诊提醒卡片 */
	.appointment-card {
		background: linear-gradient(135deg, lighten($color-primary, 10%) 0%, $color-primary 100%);
		margin: 0 30rpx 20rpx;
		border-radius: 24rpx;
		padding: 24rpx 28rpx;
		display: flex;
		align-items: center;
		box-shadow: 0 8rpx 24rpx rgba(79, 209, 197, 0.3);
		position: relative;
		overflow: hidden;
	}

	.appointment-card::before {
		content: '';
		position: absolute;
		top: -50%;
		right: -20%;
		width: 300rpx;
		height: 300rpx;
		background: radial-gradient(circle, rgba(255,255,255,0.2) 0%, transparent 70%);
		border-radius: 50%;
	}

	.appointment-icon {
		font-size: 40rpx;
		margin-right: 20rpx;
		position: relative;
		z-index: 1;
	}

	.appointment-content {
		flex: 1;
		display: flex;
		flex-direction: column;
		position: relative;
		z-index: 1;
	}

	.appointment-title {
		font-size: 28rpx;
		color: #ffffff;
		font-weight: 700;
		margin-bottom: 8rpx;
	}

	.appointment-info-text {
		font-size: 24rpx;
		color: rgba(255, 255, 255, 0.95);
		line-height: 1.4;
	}

	.appointment-number {
		font-size: 36rpx;
		color: #ffffff;
		font-weight: 800;
		position: relative;
		z-index: 1;
	}

	/* 加载状态 */
	.loading {
		position: fixed;
		top: 50%;
		left: 50%;
		transform: translate(-50%, -50%);
		background: rgba(0, 0, 0, 0.75);
		color: #ffffff;
		padding: 24rpx 48rpx;
		border-radius: 16rpx;
		z-index: 9999;
		backdrop-filter: blur(10rpx);
	}

	.loading-text {
		font-size: 28rpx;
	}

	/* 骨架屏样式 */
	.skeleton-container {
		display: grid;
		grid-template-columns: 1fr 1fr;
		gap: 16rpx;
	}

	.skeleton-item {
		background: linear-gradient(90deg, #F7FAFC 25%, #EDF2F7 50%, #F7FAFC 75%);
		background-size: 200% 100%;
		border-radius: 16rpx;
		padding: 20rpx 18rpx;
		height: 100rpx;
		animation: skeleton-loading 1.5s ease-in-out infinite;
		opacity: 0;
		animation-fill-mode: both;
	}

	.skeleton-tags {
		display: flex;
		gap: 14rpx;
		padding: 6rpx 0;
	}

	.skeleton-tag {
		background: linear-gradient(90deg, #F7FAFC 25%, #EDF2F7 50%, #F7FAFC 75%);
		background-size: 200% 100%;
		border-radius: 24rpx;
		padding: 14rpx 24rpx;
		height: 60rpx;
		width: 120rpx;
		animation: skeleton-loading 1.5s ease-in-out infinite;
		opacity: 0;
		animation-fill-mode: both;
	}

	@keyframes skeleton-loading {
		0% {
			background-position: 200% 0;
		}
		100% {
			background-position: -200% 0;
		}
	}

	/* 空状态样式 */
	.empty-state {
		padding: 60rpx 20rpx;
		text-align: center;
	}

	.empty-icon {
		display: block;
		font-size: 80rpx;
		margin-bottom: 20rpx;
		opacity: 0.5;
	}

	.empty-text {
		display: block;
		font-size: 28rpx;
		color: #718096;
		margin-bottom: 24rpx;
	}
	
	.empty-btn {
		margin-top: 24rpx;
		padding: 16rpx 48rpx;
		background: linear-gradient(135deg, lighten($color-primary, 10%) 0%, $color-primary 100%);
		border-radius: 24rpx;
		display: inline-block;
	}
	
	.empty-btn-text {
		font-size: 28rpx;
		color: #ffffff;
		font-weight: 600;
	}

	.empty-state-small {
		padding: 30rpx 20rpx;
		text-align: center;
	}
	
	.empty-icon-small {
		display: block;
		font-size: 60rpx;
		margin-bottom: 16rpx;
		opacity: 0.5;
	}

	.empty-text-small {
		font-size: 24rpx;
		color: #A0AEC0;
		margin-bottom: 20rpx;
	}
	
	.empty-btn-small {
		margin-top: 20rpx;
		padding: 12rpx 40rpx;
		background: linear-gradient(135deg, lighten($color-primary, 10%) 0%, $color-primary 100%);
		border-radius: 20rpx;
		display: inline-block;
	}
	
	.empty-btn-text-small {
		font-size: 24rpx;
		color: #ffffff;
		font-weight: 600;
	}

	/* 响应式设计 */
	@media screen and (min-width: 768px) {
		.container {
			max-width: 750rpx;
			margin: 0 auto;
		}
	}

	/* 触摸目标大小优化 */
	.function-card,
	.schedule-item,
	.department-tag {
		min-height: 88rpx;
	}

	/* 字体大小优化 */
	.function-title,
	.card-title,
	.dept-name {
		font-size: 28rpx;
	}

	/* 对比度优化 */
	.view-all,
	.available-count {
		color: $color-primary;
		font-weight: 600;
	}
</style>
