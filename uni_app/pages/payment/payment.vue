<template>
	<view class="container">
		<view class="page-header">
			<text class="page-title">支付挂号费</text>
		</view>
		
		<view class="content">
			<!-- 费用详情卡片 -->
			<view class="amount-card">
				<text class="amount-label">挂号费用</text>
				<text class="amount-value">¥{{ fee }}</text>
			</view>
			
			<!-- 预约信息 -->
			<view class="info-card">
				<view class="card-title">预约信息</view>
				<view class="info-row">
					<text class="label">科室：</text>
					<text class="value">{{ departmentName }}</text>
				</view>
			<view class="info-row">
				<text class="label">医生：</text>
				<text class="value">{{ doctorName }} {{ doctorTitle }}</text>
			</view>
			<view class="info-row">
				<text class="label">就诊时间：</text>
				<text class="value">{{ scheduleDate }} {{ slotName }}</text>
			</view>
			</view>
			
			<!-- 支付方式 -->
			<view class="payment-methods">
				<text class="methods-title">选择支付方式</text>
				<view 
					class="method-item" 
					v-for="method in paymentMethods" 
					:key="method.value"
					:class="{ active: selectedMethod === method.value }"
					@click="selectMethod(method.value)"
				>
					<text class="method-icon">{{ method.icon }}</text>
					<text class="method-name">{{ method.name }}</text>
					<view class="method-radio" v-if="selectedMethod === method.value">
						<text class="radio-icon">✓</text>
					</view>
				</view>
			</view>
			
			<!-- 支付按钮 -->
			<view class="payment-section">
				<view class="total-info">
					<text class="total-label">实付：</text>
					<text class="total-value">¥{{ fee }}</text>
				</view>
				<button class="pay-btn" @click="handlePayment">立即支付</button>
			</view>
		</view>
	</view>
</template>

<script>
	import { mockSchedules, mockPatientInfo } from '../../api/mockData.js'
	// import { createAppointment } from '../../api/appointment.js'
	
	export default {
		data() {
			return {
				scheduleId: null,
				waitlistId: null, // 候补ID
				fee: 0,
				departmentName: '',
				doctorName: '',
				doctorTitle: '',
				scheduleDate: '',
				slotName: '',
				patientInfo: {},
				appointmentId: null, // 预约ID
				isWaitlist: false, // 是否为候补支付
				selectedMethod: 'wechat',
				paymentMethods: [
					{ value: 'wechat', name: '微信支付', icon: '💚' },
					{ value: 'alipay', name: '支付宝', icon: '🔵' },
					{ value: 'balance', name: '校园卡余额', icon: '💳' }
				]
			}
		},
		onLoad(options) {
			this.scheduleId = options.scheduleId ? parseInt(options.scheduleId) : null
			this.waitlistId = options.waitlistId ? parseInt(options.waitlistId) : null
			this.fee = parseFloat(options.fee || 0)
			this.departmentName = decodeURIComponent(options.departmentName || '')
			this.doctorName = decodeURIComponent(options.doctorName || '')
			this.doctorTitle = decodeURIComponent(options.doctorTitle || '')
			this.scheduleDate = decodeURIComponent(options.scheduleDate || '')
			this.slotName = decodeURIComponent(options.slotName || '')
			this.isWaitlist = !!this.waitlistId
			this.loadPatientInfo()
			this.createAppointment()
		},
		methods: {
			loadPatientInfo() {
				const stored = uni.getStorageSync('patientInfo')
				this.patientInfo = stored || mockPatientInfo
			},
			
			selectMethod(method) {
				this.selectedMethod = method
			},
			
		async createAppointment() {
			try {
				if (this.isWaitlist) {
					// 候补支付：使用候补ID
					this.appointmentId = this.waitlistId
				} else {
					// 创建预约（状态为待支付）
					// const response = await createAppointment({
					// 	scheduleId: this.scheduleId,
					// 	patientId: this.patientInfo.id
					// })
					// this.appointmentId = response.appointmentId
					
					// 模拟创建预约
					this.appointmentId = Math.floor(Math.random() * 10000) + 1000
				}
			} catch (error) {
				console.error('创建预约失败:', error)
				uni.showModal({
					title: '预约失败',
					content: '创建预约失败，请重试',
					showCancel: false,
					success: () => {
						uni.navigateBack()
					}
				})
			}
		},
			
			async handlePayment() {
				if (!this.appointmentId) {
					uni.showToast({
						title: '请先创建预约',
						icon: 'none'
					})
					return
				}
				
				uni.showLoading({ title: '支付中...' })
				
				try {
					// 模拟支付处理（等待2秒）
					await new Promise(resolve => setTimeout(resolve, 2000))
					
					// 更新支付状态
					// await updateAppointmentPayment(this.appointmentId, {
					// 	paymentStatus: 'paid',
					// 	paymentMethod: this.selectedMethod,
					// 	transactionId: 'TXN' + Date.now()
					// })
					
					uni.hideLoading()
					
					// 显示支付成功
					uni.showToast({
						title: '支付成功',
						icon: 'success',
						duration: 2000
					})
					
			// 跳转到预约详情页面，显示二维码
			setTimeout(() => {
				uni.redirectTo({
					url: `/pages/appointment/detail?appointmentId=${this.appointmentId}&departmentName=${encodeURIComponent(this.departmentName)}&doctorName=${encodeURIComponent(this.doctorName)}&doctorTitle=${encodeURIComponent(this.doctorTitle)}&scheduleDate=${encodeURIComponent(this.scheduleDate)}&slotName=${encodeURIComponent(this.slotName)}`
				})
			}, 2000)
				} catch (error) {
					uni.hideLoading()
					uni.showToast({
						title: '支付失败，请重试',
						icon: 'none'
					})
				}
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

	.amount-card {
		background: linear-gradient(135deg, #FF6B6B 0%, #FF8E8E 100%);
		border-radius: 20rpx;
		padding: 60rpx 30rpx;
		margin-bottom: 20rpx;
		text-align: center;
		box-shadow: 0 4rpx 20rpx rgba(255, 107, 107, 0.3);
	}

	.amount-label {
		display: block;
		font-size: 28rpx;
		color: rgba(255, 255, 255, 0.9);
		margin-bottom: 16rpx;
	}

	.amount-value {
		display: block;
		font-size: 72rpx;
		font-weight: 700;
		color: #ffffff;
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
		margin-bottom: 20rpx;
	}

	.info-row:last-child {
		margin-bottom: 0;
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

	.payment-methods {
		background: #ffffff;
		border-radius: 20rpx;
		padding: 30rpx;
		margin-bottom: 20rpx;
		box-shadow: 0 2rpx 12rpx rgba(0, 0, 0, 0.06);
	}

	.methods-title {
		display: block;
		font-size: 30rpx;
		font-weight: 600;
		color: #1A202C;
		margin-bottom: 24rpx;
	}

	.method-item {
		display: flex;
		align-items: center;
		padding: 24rpx;
		margin-bottom: 12rpx;
		border-radius: 16rpx;
		border: 2rpx solid #E2E8F0;
		transition: all 0.3s ease;
	}

	.method-item.active {
		border-color: #4FD9C3;
		background: #F0FDFC;
	}

	.method-icon {
		font-size: 40rpx;
		margin-right: 20rpx;
	}

	.method-name {
		flex: 1;
		font-size: 28rpx;
		color: #1A202C;
		font-weight: 500;
	}

	.method-radio {
		width: 48rpx;
		height: 48rpx;
		border-radius: 50%;
		background: #4FD9C3;
		display: flex;
		align-items: center;
		justify-content: center;
	}

	.radio-icon {
		font-size: 28rpx;
		color: #ffffff;
		font-weight: 700;
	}

	.payment-section {
		position: fixed;
		bottom: 0;
		left: 0;
		right: 0;
		padding: 30rpx;
		background: #ffffff;
		box-shadow: 0 -2rpx 12rpx rgba(0, 0, 0, 0.08);
		display: flex;
		align-items: center;
		justify-content: space-between;
	}

	.total-info {
		display: flex;
		align-items: baseline;
		margin-right: 20rpx;
	}

	.total-label {
		font-size: 28rpx;
		color: #718096;
	}

	.total-value {
		font-size: 40rpx;
		color: #FF6B6B;
		font-weight: 700;
		margin-left: 8rpx;
	}

	.pay-btn {
		flex: 1;
		height: 96rpx;
		background: linear-gradient(135deg, #7be6d8 0%, #4FD9C3 100%);
		border-radius: 50rpx;
		color: #ffffff;
		font-size: 32rpx;
		font-weight: 600;
		border: none;
	}
</style>
