<template>
	<view class="container">
		<view class="page-header">
			<text class="page-title">预约确认</text>
		</view>
		
		<view class="content">
			<!-- 患者信息卡片 -->
			<view class="info-card patient-card">
				<view class="card-title">
					<text>👤 患者信息</text>
				</view>
				<view class="info-content">
					<view class="info-row">
						<text class="label">姓名：</text>
						<text class="value">{{ patientInfo.name }}</text>
					</view>
					<view class="info-row">
						<text class="label">学号/工号：</text>
						<text class="value">{{ patientInfo.identifier }}</text>
					</view>
				</view>
			</view>
			
			<!-- 预约信息卡片 -->
			<view class="info-card appointment-card">
				<view class="card-title">
					<text>📅 预约信息</text>
				</view>
				<view class="info-content">
					<view class="info-row">
						<text class="label">科室：</text>
						<text class="value">{{ scheduleInfo.departmentName }}</text>
					</view>
					<view class="info-row">
						<text class="label">医生：</text>
						<text class="value">{{ scheduleInfo.doctorName }} {{ scheduleInfo.doctorTitle }}</text>
					</view>
					<view class="info-row">
						<text class="label">就诊时间：</text>
						<text class="value">{{ scheduleInfo.scheduleDate }} {{ scheduleInfo.slotName }}</text>
					</view>
					<view class="info-row">
						<text class="label">诊室：</text>
						<text class="value">{{ scheduleInfo.location }}</text>
					</view>
					<view class="info-row">
						<text class="label">挂号费用：</text>
						<text class="value price">¥{{ scheduleInfo.fee }}</text>
					</view>
				</view>
			</view>
			
			<!-- 温馨提示 -->
			<view class="tips-card">
				<text class="tips-title">💡 温馨提示</text>
				<text class="tips-text">1. 请提前15分钟到达诊室候诊</text>
				<text class="tips-text">2. 如无法按时就诊，请提前取消预约</text>
				<text class="tips-text">3. 取消预约需在就诊前24小时进行</text>
			</view>
			
			<!-- 确认按钮 -->
			<view class="confirm-section">
				<button class="confirm-btn" @click="handleConfirm">确认预约</button>
			</view>
		</view>
	</view>
</template>

<script>
	import { mockSchedules, mockPatientInfo } from '../../api/mockData.js'
	import { getScheduleById } from '../../api/schedule.js'
	import { adaptSchedule } from '../../utils/dataAdapter.js'
	
	export default {
		data() {
			return {
				scheduleId: null,
				scheduleInfo: {
					departmentName: '',
					doctorName: '',
					doctorTitle: '',
					scheduleDate: '',
					slotName: '',
					location: '',
					fee: 0
				},
				patientInfo: {
					name: '',
					identifier: ''
				}
			}
		},
		onLoad(options) {
			console.log('预约确认页加载 - options:', options)
			this.scheduleId = parseInt(options.scheduleId)
			console.log('预约确认页 - scheduleId:', this.scheduleId)
			this.loadScheduleInfo()
			this.loadPatientInfo()
		},
		methods: {
			async loadScheduleInfo() {
				try {
					console.log('加载排班信息 - scheduleId:', this.scheduleId)
					// 调用后端API获取排班详情
					const response = await getScheduleById(this.scheduleId)
					console.log('排班详情API响应:', response)
					
					if (response && response.scheduleId) {
						// 适配后端数据格式
						const adapted = adaptSchedule(response)
						console.log('适配后的排班数据:', adapted)
						
						this.scheduleInfo = {
							departmentName: adapted.departmentName || '',
							doctorName: adapted.doctorName || '',
							doctorTitle: adapted.doctorTitle || '',
							scheduleDate: adapted.scheduleDate || '',
							slotName: adapted.slotName || '',
							location: adapted.location || '',
							fee: adapted.fee || 0
						}
						console.log('设置后的scheduleInfo:', this.scheduleInfo)
					} else {
						throw new Error('返回数据格式异常')
					}
				} catch (error) {
					console.error('加载排班信息失败:', error)
					// 如果后端失败，使用Mock数据作为fallback
					try {
						const allSchedules = JSON.parse(JSON.stringify(mockSchedules))
						const found = allSchedules.find(s => s.scheduleId === this.scheduleId)
						if (found) {
							this.scheduleInfo = {
								departmentName: found.departmentName || '',
								doctorName: found.doctorName || '',
								doctorTitle: found.doctorTitle || '',
								scheduleDate: found.scheduleDate || '',
								slotName: found.slotName || '',
								location: found.location || '',
								fee: found.fee || 0
							}
						} else {
							uni.showToast({
								title: '排班信息不存在',
								icon: 'none'
							})
						}
					} catch (fallbackError) {
						console.error('Fallback失败:', fallbackError)
					}
				}
			},
			
			loadPatientInfo() {
				try {
					const stored = uni.getStorageSync('patientInfo')
					if (stored) {
						this.patientInfo = stored
					} else {
						this.patientInfo = mockPatientInfo || { name: '', identifier: '' }
					}
				} catch (error) {
					console.error('加载患者信息失败:', error)
					this.patientInfo = mockPatientInfo || { name: '', identifier: '' }
				}
			},
			
			async handleConfirm() {
				// 验证数据
				if (!this.scheduleInfo.doctorName || !this.patientInfo.name) {
					uni.showToast({
						title: '信息不完整',
						icon: 'none'
					})
					return
				}
				
		// 跳转到支付页面
		uni.navigateTo({
			url: `/pages/payment/payment?scheduleId=${this.scheduleId}&fee=${this.scheduleInfo.fee}&departmentName=${encodeURIComponent(this.scheduleInfo.departmentName)}&doctorName=${encodeURIComponent(this.scheduleInfo.doctorName)}&doctorTitle=${encodeURIComponent(this.scheduleInfo.doctorTitle)}&scheduleDate=${encodeURIComponent(this.scheduleInfo.scheduleDate)}&slotName=${encodeURIComponent(this.scheduleInfo.slotName)}`
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

	.info-content {
		display: flex;
		flex-direction: column;
	}

	.info-row {
		display: flex;
		align-items: center;
		margin-bottom: 20rpx;
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
		flex: 1;
	}

	.value.price {
		color: #FF6B6B;
		font-size: 32rpx;
		font-weight: 700;
	}

	.tips-card {
		background: #FEF3E2;
		border-radius: 16rpx;
		padding: 24rpx;
		margin-bottom: 20rpx;
		border-left: 4rpx solid #F59E0B;
	}

	.tips-title {
		display: block;
		font-size: 28rpx;
		font-weight: 600;
		color: #92400E;
		margin-bottom: 16rpx;
	}

	.tips-text {
		display: block;
		font-size: 24rpx;
		color: #78350F;
		margin-bottom: 8rpx;
		line-height: 1.6;
	}

	.confirm-section {
		position: fixed;
		bottom: 0;
		left: 0;
		right: 0;
		padding: 30rpx;
		background: #ffffff;
		box-shadow: 0 -2rpx 12rpx rgba(0, 0, 0, 0.08);
	}

	.confirm-btn {
		width: 100%;
		height: 96rpx;
		background: linear-gradient(135deg, #7be6d8 0%, #4FD9C3 100%);
		border-radius: 50rpx;
		color: #ffffff;
		font-size: 32rpx;
		font-weight: 600;
		border: none;
	}
</style>