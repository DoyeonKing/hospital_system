<template>
	<view class="container">
		<view class="page-header">
			<text class="page-title">我的预约</text>
		</view>
		
		<view class="content">
			<!-- 预约列表 -->
			<view class="appointment-list" v-if="appointmentList.length > 0">
				<view 
					class="appointment-item" 
					v-for="appointment in appointmentList" 
					:key="appointment.id"
					:class="{ 'completed': appointment.status === 'completed', 'cancelled': appointment.status === 'cancelled' }"
				>
					<view class="appointment-header">
						<view class="department-info">
							<text class="department-name" :class="{ 'cancelled-line': appointment.status === 'cancelled' }">{{ appointment.departmentName }}</text>
							<text class="doctor-name">{{ appointment.doctorName }}</text>
						</view>
						<view class="status-badge-wrapper">
							<view class="status-badge cancelled-label" v-if="appointment.status === 'cancelled'">
								<text class="status-text">已取消</text>
							</view>
							<view class="status-badge" :class="appointment.status" v-else>
								<text class="status-text">{{ getStatusText(appointment.status) }}</text>
							</view>
						</view>
					</view>
					<view class="appointment-content">
						<view class="info-row">
							<text class="info-label">就诊时间：</text>
							<text class="info-value">{{ formatDateTime(appointment.scheduleTime) }}</text>
						</view>
						<view class="info-row">
							<text class="info-label">预约时间：</text>
							<text class="info-value">{{ formatDateTime(appointment.appointmentTime) }}</text>
						</view>
						<view class="info-row" v-if="appointment.status === 'confirmed'">
							<text class="info-label">排队号：</text>
							<text class="info-value queue-number">第{{ appointment.queueNumber }}号</text>
						</view>
					</view>
					<view class="appointment-actions" v-if="appointment.status === 'confirmed'">
						<view class="action-btn cancel-btn" @click="handleCancel(appointment.id)">
							<text class="btn-text">取消预约</text>
						</view>
					</view>
				</view>
			</view>
			
			<!-- 空状态 -->
			<view class="empty-state" v-else>
				<text class="empty-icon">🩺</text>
				<text class="empty-text">暂无预约记录</text>
				<text class="empty-desc">快去预约挂号吧～</text>
				<view class="empty-btn" @click="navigateToDepartments">
					<text class="empty-btn-text">去挂号</text>
				</view>
			</view>
		</view>
	</view>
</template>

<script>
	import { mockAppointments } from '../../api/mockData.js'
	
	export default {
		data() {
			return {
				appointmentList: []
			}
		},
		onLoad() {
			// 直接使用测试数据
			this.loadAppointments()
		},
		onShow() {
			// 页面显示时刷新数据
			this.loadAppointments()
		},
		methods: {
			// 加载预约列表 - 暂时没有后端，直接使用测试数据
			loadAppointments() {
				// 直接使用测试数据
				this.appointmentList = JSON.parse(JSON.stringify(mockAppointments))
				// TODO: 等后端接口准备好后，取消下面的注释并启用API调用
				// try {
				// 	const patientInfo = uni.getStorageSync('patientInfo')
				// 	const response = await getPatientAppointments(patientInfo?.id || 1)
				// 	if (response && response.code === 200 && response.data) {
				// 		this.appointmentList = response.data
				// 	} else {
				// 		this.appointmentList = JSON.parse(JSON.stringify(mockAppointments))
				// 	}
				// } catch (error) {
				// 	console.error('加载预约列表失败:', error)
				// 	this.appointmentList = JSON.parse(JSON.stringify(mockAppointments))
				// }
			},
			
			// 获取状态文本
			getStatusText(status) {
				const statusMap = {
					'confirmed': '已确认',
					'completed': '已完成',
					'cancelled': '已取消'
				}
				return statusMap[status] || '未知'
			},
			
			// 格式化日期时间
			formatDateTime(dateString) {
				if (!dateString) return ''
				const date = new Date(dateString)
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
			},
			
			// 取消预约
			handleCancel(appointmentId) {
				uni.showModal({
					title: '确认取消',
					content: '确定要取消这个预约吗？',
					success: (res) => {
						if (res.confirm) {
							// 直接更新本地数据
							const index = this.appointmentList.findIndex(item => item.id === appointmentId)
							if (index !== -1) {
								this.appointmentList[index].status = 'cancelled'
								uni.showToast({
									title: '预约已取消',
									icon: 'success'
								})
							}
							// TODO: 等后端接口准备好后，取消下面的注释并启用API调用
							// try {
							// 	await cancelAppointment(appointmentId)
							// 	this.loadAppointments()
							// } catch (error) {
							// 	console.error('取消预约失败:', error)
							// 	uni.showToast({
							// 		title: '取消失败，请重试',
							// 		icon: 'none'
							// 	})
							// }
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
		padding: 40rpx 30rpx;
	}

	.empty-state {
		text-align: center;
		padding: 120rpx 40rpx;
	}

	.empty-icon {
		display: block;
		font-size: 120rpx;
		margin-bottom: 30rpx;
		opacity: 0.5;
	}

	.empty-text {
		display: block;
		font-size: 32rpx;
		color: #718096;
		margin-bottom: 16rpx;
	}

	.empty-desc {
		display: block;
		font-size: 26rpx;
		color: #A0AEC0;
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

	.appointment-list {
		padding: 20rpx 0;
	}

	.appointment-item {
		background: #ffffff;
		border-radius: 16rpx;
		padding: 24rpx;
		margin-bottom: 20rpx;
		box-shadow: 0 2rpx 12rpx rgba(0, 0, 0, 0.06);
	}

	.appointment-item.completed {
		opacity: 0.7;
	}

	.appointment-item.cancelled {
		opacity: 0.6;
		background: #f7f7f7;
	}
	
	.department-name.cancelled-line {
		text-decoration: line-through;
		text-decoration-color: #DC2626;
		text-decoration-thickness: 2rpx;
	}
	
	.status-badge-wrapper {
		display: flex;
		flex-direction: column;
		align-items: flex-end;
		gap: 8rpx;
	}
	
	.status-badge.cancelled-label {
		background: #FEF2F2;
		color: #DC2626;
		border: 1rpx solid #FCA5A5;
	}

	.appointment-header {
		display: flex;
		justify-content: space-between;
		align-items: flex-start;
		margin-bottom: 20rpx;
		padding-bottom: 20rpx;
		border-bottom: 1rpx solid #f0f0f0;
	}

	.department-info {
		flex: 1;
	}

	.department-name {
		display: block;
		font-size: 32rpx;
		font-weight: 600;
		color: #1A202C;
		margin-bottom: 8rpx;
	}

	.doctor-name {
		display: block;
		font-size: 26rpx;
		color: #718096;
	}

	.status-badge {
		padding: 8rpx 16rpx;
		border-radius: 20rpx;
		font-size: 22rpx;
	}

	.status-badge.confirmed {
		background: #E6FFFA;
		color: #38A2AC;
	}

	.status-badge.completed {
		background: #F0FDF4;
		color: #16A34A;
	}

	.status-badge.cancelled {
		background: #FEF2F2;
		color: #DC2626;
	}

	.status-text {
		font-size: 22rpx;
		font-weight: 600;
	}

	.appointment-content {
		margin-bottom: 20rpx;
	}

	.info-row {
		display: flex;
		align-items: center;
		margin-bottom: 12rpx;
	}

	.info-label {
		font-size: 26rpx;
		color: #718096;
		margin-right: 8rpx;
	}

	.info-value {
		font-size: 26rpx;
		color: #1A202C;
	}

	.queue-number {
		color: $color-primary;
		font-weight: 600;
	}

	.appointment-actions {
		padding-top: 20rpx;
		border-top: 1rpx solid #f0f0f0;
	}

	.action-btn {
		padding: 16rpx 32rpx;
		border-radius: 8rpx;
		text-align: center;
	}

	.cancel-btn {
		background: #FFF5F5;
		border: 1rpx solid #FED7D7;
	}

	.btn-text {
		font-size: 26rpx;
		color: #DC2626;
		font-weight: 600;
	}
</style>
