<template>
	<view class="container">
		<view class="page-header">
			<text class="page-title">预约详情</text>
		</view>
		
		<view class="content">
			<!-- 状态卡片 -->
			<view class="status-card">
				<view class="status-icon" :class="appointment.status">
					<text>{{ getStatusIcon(appointment.status) }}</text>
				</view>
				<text class="status-text">{{ getStatusText(appointment.status) }}</text>
			</view>
			
			<!-- 患者信息 -->
			<view class="info-card">
				<view class="card-title">患者信息</view>
				<view class="info-row">
					<text class="label">姓名：</text>
					<text class="value">{{ appointment.patientName }}</text>
				</view>
				<view class="info-row">
					<text class="label">学号/工号：</text>
					<text class="value">{{ patientInfo.identifier }}</text>
				</view>
			</view>
			
			<!-- 预约信息 -->
			<view class="info-card">
				<view class="card-title">预约信息</view>
				<view class="info-row">
					<text class="label">科室：</text>
					<text class="value">{{ appointment.departmentName }}</text>
				</view>
				<view class="info-row">
					<text class="label">医生：</text>
					<text class="value">{{ appointment.doctorName }}</text>
				</view>
				<view class="info-row">
					<text class="label">就诊时间：</text>
					<text class="value">{{ formatDateTime(appointment.scheduleTime) }}</text>
				</view>
				<view class="info-row" v-if="appointment.status === 'confirmed'">
					<text class="label">排队号：</text>
					<text class="value queue-number">第{{ appointment.queueNumber }}号</text>
				</view>
				<view class="info-row">
					<text class="label">预约时间：</text>
					<text class="value">{{ formatDateTime(appointment.appointmentTime) }}</text>
				</view>
			</view>
			
			<!-- 签到二维码（仅已确认状态显示） -->
			<view class="qr-code-card" v-if="appointment.status === 'confirmed'">
				<view class="qr-title">
					<text class="qr-icon">📱</text>
					<text class="qr-text">签到二维码</text>
				</view>
				<view class="qr-container">
					<image class="qr-code" :src="qrCodeUrl" mode="aspectFit"></image>
				</view>
				<text class="qr-desc">就诊时出示此二维码进行签到</text>
			</view>
			
			<!-- 操作按钮 -->
			<view class="action-section" v-if="appointment.status === 'confirmed'">
				<button class="home-btn" @click="handleBackToHome">返回主页</button>
				<button class="cancel-btn" @click="handleCancel">取消预约</button>
			</view>
		</view>
	</view>
</template>

<script>
	import { mockAppointments, mockPatientInfo } from '../../api/mockData.js'
	
	export default {
	data() {
		return {
			appointmentId: null,
			appointment: {},
			patientInfo: {},
			qrCodeUrl: '',
			urlParams: {} // 存储URL传递的参数
		}
	},
onLoad(options) {
	this.appointmentId = parseInt(options.appointmentId)
	// 如果URL传了参数，说明是新建的预约
	this.urlParams = {
		departmentName: options.departmentName ? decodeURIComponent(options.departmentName) : '',
		doctorName: options.doctorName ? decodeURIComponent(options.doctorName) : '',
		doctorTitle: options.doctorTitle ? decodeURIComponent(options.doctorTitle) : '',
		scheduleDate: options.scheduleDate ? decodeURIComponent(options.scheduleDate) : '',
		slotName: options.slotName ? decodeURIComponent(options.slotName) : ''
	}
	// 先加载患者信息，因为 loadAppointmentDetail 可能用到
	this.loadPatientInfo()
	this.loadAppointmentDetail()
	this.generateQRCode()
},
		methods: {
	loadAppointmentDetail() {
		// 如果有URL参数，说明是新建的预约，使用URL参数
		if (this.urlParams.departmentName && this.urlParams.doctorName) {
			const now = new Date()
			// 解析就诊日期
			let scheduleTime
			if (this.urlParams.scheduleDate) {
				// scheduleDate 格式：2024-01-15
				scheduleTime = new Date(this.urlParams.scheduleDate + 'T12:00:00').toISOString()
			} else {
				scheduleTime = new Date(now.getTime() + 24 * 60 * 60 * 1000).toISOString()
			}
			
		this.appointment = {
			id: this.appointmentId,
			departmentName: this.urlParams.departmentName,
			doctorName: this.urlParams.doctorTitle ? `${this.urlParams.doctorName} ${this.urlParams.doctorTitle}` : this.urlParams.doctorName,
			scheduleTime: scheduleTime,
			appointmentTime: now.toISOString(),
			status: 'confirmed',
			queueNumber: Math.floor(Math.random() * 20) + 1,
			patientName: this.patientInfo.name || '张三',
			patientId: this.patientInfo.id || 1
		}
		} else {
			// TODO: 调用后端API获取预约详情
			const allAppointments = JSON.parse(JSON.stringify(mockAppointments))
			this.appointment = allAppointments.find(a => a.id === this.appointmentId) || {}
		}
	},
			
			generateQRCode() {
				// 生成二维码 - 使用在线二维码API
				// 实际项目中应该调用后端API生成二维码
				if (this.appointmentId) {
					this.qrCodeUrl = `https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=APPOINTMENT${this.appointmentId}_${Date.now()}`
				}
			},
			
			loadPatientInfo() {
				const stored = uni.getStorageSync('patientInfo')
				this.patientInfo = stored || mockPatientInfo
			},
			
			getStatusText(status) {
				const statusMap = {
					'confirmed': '已确认',
					'completed': '已完成',
					'cancelled': '已取消'
				}
				return statusMap[status] || '未知'
			},
			
			getStatusIcon(status) {
				const iconMap = {
					'confirmed': '✅',
					'completed': '✔️',
					'cancelled': '❌'
				}
				return iconMap[status] || '❓'
			},
			
			formatDateTime(dateString) {
				if (!dateString) return ''
				const date = new Date(dateString)
				const month = date.getMonth() + 1
				const day = date.getDate()
				const hours = date.getHours().toString().padStart(2, '0')
				const minutes = date.getMinutes().toString().padStart(2, '0')
				return `${month}月${day}日 ${hours}:${minutes}`
			},
			
			handleCancel() {
				uni.showModal({
					title: '确认取消',
					content: '确定要取消这个预约吗？',
					success: (res) => {
						if (res.confirm) {
							uni.showLoading({ title: '取消中...' })
							
							// TODO: 调用后端API取消预约
							setTimeout(() => {
								uni.hideLoading()
								uni.showToast({
									title: '预约已取消',
									icon: 'success'
								})
								
								setTimeout(() => {
									uni.navigateBack()
								}, 1500)
							}, 1000)
						}
					}
				})
			},
			
			handleBackToHome() {
				uni.switchTab({
					url: '/pages/index/index'
				})
			}
		}
	}
</script>

<style lang="scss">
	.container {
		min-height: 100vh;
		background-color: #f7fafc;
		padding-bottom: 120rpx;
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

	.status-card {
		background: linear-gradient(135deg, #7be6d8 0%, #4FD9C3 100%);
		border-radius: 20rpx;
		padding: 60rpx 30rpx;
		margin-bottom: 20rpx;
		text-align: center;
		box-shadow: 0 4rpx 20rpx rgba(79, 209, 197, 0.3);
	}

	.status-icon {
		font-size: 80rpx;
		margin-bottom: 16rpx;
	}

	.status-text {
		display: block;
		font-size: 32rpx;
		color: #ffffff;
		font-weight: 600;
	}

	.info-card {
		background: #ffffff;
		border-radius: 20rpx;
		padding: 30rpx;
		margin-bottom: 20rpx;
		box-shadow: 0 2rpx 12rpx rgba(0, 0, 0, 0.06);
	}

	.card-title {
		font-size: 30rpx;
		font-weight: 600;
		color: #1A202C;
		margin-bottom: 24rpx;
		padding-bottom: 20rpx;
		border-bottom: 1rpx solid #f0f0f0;
	}

	.info-row {
		display: flex;
		align-items: center;
		margin-bottom: 24rpx;
	}

	.label {
		font-size: 28rpx;
		color: #718096;
		width: 160rpx;
	}

	.value {
		font-size: 28rpx;
		color: #1A202C;
		font-weight: 500;
	}

	.queue-number {
		color: #4FD9C3;
		font-weight: 700;
		font-size: 32rpx;
	}

	.qr-code-card {
		background: #ffffff;
		border-radius: 20rpx;
		padding: 30rpx;
		margin-bottom: 20rpx;
		box-shadow: 0 2rpx 12rpx rgba(0, 0, 0, 0.06);
	}

	.qr-title {
		display: flex;
		align-items: center;
		justify-content: center;
		margin-bottom: 20rpx;
	}

	.qr-icon {
		font-size: 32rpx;
		margin-right: 8rpx;
	}

	.qr-text {
		font-size: 30rpx;
		font-weight: 600;
		color: #1A202C;
	}

	.qr-container {
		display: flex;
		justify-content: center;
		align-items: center;
		margin-bottom: 16rpx;
		padding: 20rpx;
		background: #f7fafc;
		border-radius: 16rpx;
	}

	.qr-code {
		width: 400rpx;
		height: 400rpx;
	}

	.qr-desc {
		display: block;
		text-align: center;
		font-size: 24rpx;
		color: #718096;
	}

	.action-section {
		position: fixed;
		bottom: 0;
		left: 0;
		right: 0;
		padding: 30rpx;
		background: #ffffff;
		box-shadow: 0 -2rpx 12rpx rgba(0, 0, 0, 0.08);
		display: flex;
		gap: 20rpx;
	}

	.home-btn {
		flex: 1;
		height: 96rpx;
		background: linear-gradient(135deg, #4FD9C3 0%, #7be6d8 100%);
		border: none;
		border-radius: 50rpx;
		color: #ffffff;
		font-size: 32rpx;
		font-weight: 600;
	}

	.cancel-btn {
		flex: 1;
		height: 96rpx;
		background: #FFF5F5;
		border: 2rpx solid #FED7D7;
		border-radius: 50rpx;
		color: #DC2626;
		font-size: 32rpx;
		font-weight: 600;
	}
</style>
