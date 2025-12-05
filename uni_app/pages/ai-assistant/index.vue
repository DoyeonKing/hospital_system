<template>
	<view class="container">
		<!-- 步骤指示器 -->
		<view class="steps-indicator">
			<view class="step-item" :class="{ active: currentStep >= 1, completed: currentStep > 1 }">
				<view class="step-number">1</view>
				<text class="step-label">输入症状</text>
			</view>
			<view class="step-line" :class="{ active: currentStep > 1 }"></view>
			<view class="step-item" :class="{ active: currentStep >= 2, completed: currentStep > 2 }">
				<view class="step-number">2</view>
				<text class="step-label">选择科室</text>
			</view>
			<view class="step-line" :class="{ active: currentStep > 2 }"></view>
			<view class="step-item" :class="{ active: currentStep >= 3, completed: currentStep > 3 }">
				<view class="step-number">3</view>
				<text class="step-label">选择医生</text>
			</view>
		</view>

		<!-- 第一步：输入症状描述 -->
		<view class="step-content" v-if="currentStep === 1">
			<view class="section-header">
				<text class="section-title">请描述您的症状</text>
				<text class="section-subtitle">AI将为您智能推荐合适的科室和医生</text>
			</view>

			<!-- 症状输入框 -->
			<view class="textarea-wrapper">
				<textarea 
					class="symptom-textarea" 
					placeholder="例如：最近几天一直头痛，伴有发热，体温38度左右..." 
					placeholder-class="placeholder"
					v-model="symptomDescription"
					maxlength="200"
				></textarea>
				<text class="word-count">{{ symptomDescription.length }}/200</text>
			</view>

			<!-- 提交按钮 -->
			<button 
				class="submit-btn" 
				:class="{ loading: loading }"
				@click="submitSymptoms" 
				:disabled="loading || !symptomDescription.trim()"
			>
				{{ loading ? 'AI 正在分析...' : '开始智能推荐' }}
			</button>
		</view>

		<!-- 第二步：选择科室 -->
		<view class="step-content" v-if="currentStep === 2">
			<view class="section-header">
				<text class="section-title">推荐科室</text>
				<text class="section-subtitle">根据您的症状，AI为您推荐以下科室</text>
			</view>

			<!-- 科室列表 -->
			<view class="department-list" v-if="departmentRecommendations.length > 0">
				<view 
					class="department-card" 
					v-for="dept in departmentRecommendations" 
					:key="dept.departmentId"
					@click="selectDepartment(dept)"
				>
					<view class="dept-header">
						<text class="dept-name">{{ dept.departmentName }}</text>
						<view class="score-badge" v-if="dept.score">
							<text class="score-text">匹配度 {{ Math.round(dept.score * 100) }}%</text>
						</view>
					</view>
					<text class="dept-reason" v-if="dept.reason">{{ dept.reason }}</text>
					<text class="dept-description" v-if="dept.description">{{ dept.description }}</text>
				</view>
			</view>

			<!-- 加载状态 -->
			<view class="loading-state" v-if="loading">
				<text class="loading-text">正在加载科室推荐...</text>
			</view>

			<!-- 返回按钮 -->
			<button class="back-btn" @click="goBackToStep1">返回修改症状</button>
		</view>

		<!-- 第三步：选择医生和排班 -->
		<view class="step-content" v-if="currentStep === 3">
			<view class="section-header">
				<text class="section-title">{{ selectedDepartment.departmentName }}</text>
				<text class="section-subtitle">选择医生和就诊时间</text>
			</view>

			<!-- 医生列表 -->
			<view class="doctor-list" v-if="doctorRecommendations.length > 0">
				<view 
					class="doctor-card" 
					v-for="doctor in doctorRecommendations" 
					:key="doctor.doctorId"
				>
					<view class="doctor-info">
						<image 
							class="doctor-avatar" 
							:src="getDoctorImageUrl(doctor.photoUrl)" 
							mode="aspectFill"
							@error="handleImageError"
						></image>
						<view class="doctor-details">
							<view class="doctor-name-row">
								<text class="doctor-name">{{ doctor.doctorName }}</text>
								<text class="doctor-title">{{ doctor.title }}</text>
							</view>
							<text class="doctor-specialty" v-if="doctor.specialty">{{ doctor.specialty }}</text>
							<text class="doctor-reason" v-if="doctor.reason">{{ doctor.reason }}</text>
						</view>
					</view>

					<!-- 排班信息 -->
					<view class="schedule-list" v-if="doctor.availableSchedules && doctor.availableSchedules.length > 0">
						<view 
							class="schedule-item" 
							v-for="schedule in doctor.availableSchedules" 
							:key="schedule.scheduleId"
							:class="{ disabled: schedule.availableSlots === 0 }"
							@click="selectSchedule(doctor, schedule)"
						>
							<view class="schedule-time">
								<text class="schedule-date">{{ formatDate(schedule.scheduleDate) }}</text>
								<text class="schedule-time-range">{{ formatTime(schedule.startTime) }} - {{ formatTime(schedule.endTime) }}</text>
							</view>
							<view class="schedule-info">
								<text class="schedule-location" v-if="schedule.locationName">{{ schedule.locationName }}</text>
								<text class="schedule-slots" :class="{ full: schedule.availableSlots === 0 }">
									{{ schedule.availableSlots === 0 ? '已满' : `剩余 ${schedule.availableSlots} 号` }}
								</text>
							</view>
						</view>
					</view>
					<view class="no-schedule" v-else>
						<text class="no-schedule-text">暂无可用排班</text>
					</view>
				</view>
			</view>

			<!-- 加载状态 -->
			<view class="loading-state" v-if="loading">
				<text class="loading-text">正在加载医生推荐...</text>
			</view>

			<!-- 返回按钮 -->
			<button class="back-btn" @click="goBackToStep2">返回选择科室</button>
		</view>
	</view>
</template>

<script>
	import { recommendDepartments, recommendDoctorsByDepartment } from '../../api/recommendation.js'
	import { createAppointment } from '../../api/appointment.js'
	import { processDoctorPhotoUrl } from '../../utils/imageUtil.js'
	
	export default {
		data() {
			return {
				currentStep: 1, // 当前步骤：1-输入症状，2-选择科室，3-选择医生
				symptomDescription: '', // 症状描述
				departmentRecommendations: [], // 科室推荐列表
				doctorRecommendations: [], // 医生推荐列表
				selectedDepartment: {}, // 选中的科室
				symptomKeywords: [], // 提取的症状关键词
				loading: false
			}
		},
		methods: {
			// 提交症状描述（第一步）
			async submitSymptoms() {
				if (!this.symptomDescription.trim()) {
					uni.showToast({
						title: '请输入症状描述',
						icon: 'none'
					})
					return
				}

				this.loading = true
				try {
					// 获取患者ID（如果有登录）
					const patientInfo = uni.getStorageSync('patientInfo')
					const patientId = patientInfo && patientInfo.id ? patientInfo.id : null

					// 调用科室推荐接口
					const response = await recommendDepartments(this.symptomDescription, patientId)
					
					if (response && response.code === '200' && response.data && response.data.length > 0) {
						this.departmentRecommendations = response.data
						// 进入第二步
						this.currentStep = 2
					} else if (Array.isArray(response) && response.length > 0) {
						this.departmentRecommendations = response
						this.currentStep = 2
					} else {
						uni.showToast({
							title: response.msg || '未找到匹配的科室，请尝试更详细的描述',
							icon: 'none',
							duration: 3000
						})
					}
				} catch (error) {
					console.error('获取科室推荐失败:', error)
					uni.showToast({
						title: '推荐失败，请重试',
						icon: 'none'
					})
				} finally {
					this.loading = false
				}
			},

			// 选择科室（第二步）
			async selectDepartment(department) {
				this.selectedDepartment = department
				this.loading = true

				try {
					// 获取患者ID
					const patientInfo = uni.getStorageSync('patientInfo')
					const patientId = patientInfo && patientInfo.id ? patientInfo.id : null

					// 调用医生推荐接口（带排班信息）
					const response = await recommendDoctorsByDepartment(
						department.departmentId,
						this.symptomKeywords, // 可以传递症状关键词用于更精准的推荐
						patientId,
						10 // 返回Top-10个医生
					)

					if (response && response.code === '200' && response.data && response.data.length > 0) {
						this.doctorRecommendations = response.data
						// 进入第三步
						this.currentStep = 3
					} else if (Array.isArray(response) && response.length > 0) {
						this.doctorRecommendations = response
						this.currentStep = 3
					} else {
						uni.showToast({
							title: response.msg || '该科室暂无可用医生',
							icon: 'none'
						})
					}
				} catch (error) {
					console.error('获取医生推荐失败:', error)
					uni.showToast({
						title: '加载失败，请重试',
						icon: 'none'
					})
				} finally {
					this.loading = false
				}
			},

			// 选择排班（第三步）
			async selectSchedule(doctor, schedule) {
				if (schedule.availableSlots === 0) {
					uni.showToast({
						title: '该时段已满',
						icon: 'none'
					})
					return
				}

				// 确认预约
				uni.showModal({
					title: '确认预约',
					content: `确认预约 ${doctor.doctorName} ${doctor.title}\n${this.formatDate(schedule.scheduleDate)} ${this.formatTime(schedule.startTime)}-${this.formatTime(schedule.endTime)}`,
					success: async (res) => {
						if (res.confirm) {
							await this.createAppointment(doctor, schedule)
						}
					}
				})
			},

			// 创建预约
			async createAppointment(doctor, schedule) {
				uni.showLoading({ title: '正在预约...' })
				try {
					const patientInfo = uni.getStorageSync('patientInfo')
					if (!patientInfo || !patientInfo.id) {
						uni.showToast({
							title: '请先登录',
							icon: 'none'
						})
						uni.navigateTo({
							url: '/pages/login/patient-login'
						})
						return
					}

					// 构建预约数据
					const appointmentData = {
						patientId: patientInfo.id,
						scheduleId: schedule.scheduleId,
						doctorId: doctor.doctorId,
						departmentId: doctor.departmentId
					}

					const response = await createAppointment(appointmentData)

					if (response && response.code === '200') {
						uni.showToast({
							title: '预约成功',
							icon: 'success'
						})
						// 跳转到预约详情页
						setTimeout(() => {
							uni.navigateTo({
								url: `/pages/appointment/detail?appointmentId=${response.data.appointmentId}`
							})
						}, 1500)
					} else {
						uni.showToast({
							title: response.msg || '预约失败',
							icon: 'none'
						})
					}
				} catch (error) {
					console.error('创建预约失败:', error)
					uni.showToast({
						title: '预约失败，请重试',
						icon: 'none'
					})
				} finally {
					uni.hideLoading()
				}
			},

			// 返回第一步
			goBackToStep1() {
				this.currentStep = 1
				this.departmentRecommendations = []
			},

			// 返回第二步
			goBackToStep2() {
				this.currentStep = 2
				this.doctorRecommendations = []
			},

			// 格式化日期
			formatDate(dateString) {
				if (!dateString) return ''
				const date = new Date(dateString)
				const month = date.getMonth() + 1
				const day = date.getDate()
				return `${month}月${day}日`
			},

			// 格式化时间
			formatTime(timeString) {
				if (!timeString) return ''
				// 处理 LocalTime 格式 (HH:mm:ss) 或 (HH:mm)
				const time = timeString.split(':')
				return `${time[0]}:${time[1]}`
			},

			// 处理医生图片URL
			getDoctorImageUrl(photoUrl) {
				return processDoctorPhotoUrl(photoUrl)
			},

			// 图片加载错误处理
			handleImageError(e) {
				console.log('医生头像加载失败，使用默认头像')
				// 设置默认头像
				if (e && e.target) {
					e.target.src = 'https://cube.elemecdn.com/0/88/03b0d39583f48206768a7534e55bcpng.png'
				}
			}
		}
	}
</script>

<style lang="scss" scoped>
	.container {
		min-height: 100vh;
		background-color: #f7fafc;
		padding: 30rpx;
	}

	/* 步骤指示器 */
	.steps-indicator {
		display: flex;
		align-items: center;
		justify-content: center;
		margin-bottom: 40rpx;
		padding: 30rpx 0;
		background: #ffffff;
		border-radius: 20rpx;
		box-shadow: 0 4rpx 20rpx rgba(0, 0, 0, 0.08);
	}

	.step-item {
		display: flex;
		flex-direction: column;
		align-items: center;
		position: relative;
	}

	.step-number {
		width: 60rpx;
		height: 60rpx;
		border-radius: 50%;
		background: #E2E8F0;
		color: #718096;
		display: flex;
		align-items: center;
		justify-content: center;
		font-size: 28rpx;
		font-weight: 600;
		transition: all 0.3s ease;
	}

	.step-item.active .step-number {
		background: linear-gradient(135deg, lighten($color-primary, 10%) 0%, $color-primary 100%);
		color: #ffffff;
	}

	.step-item.completed .step-number {
		background: #48BB78;
		color: #ffffff;
	}

	.step-label {
		margin-top: 12rpx;
		font-size: 24rpx;
		color: #718096;
	}

	.step-item.active .step-label {
		color: $color-primary;
		font-weight: 600;
	}

	.step-line {
		width: 120rpx;
		height: 4rpx;
		background: #E2E8F0;
		margin: 0 20rpx;
		transition: all 0.3s ease;
	}

	.step-line.active {
		background: $color-primary;
	}

	/* 步骤内容 */
	.step-content {
		background: #ffffff;
		border-radius: 24rpx;
		padding: 40rpx;
		box-shadow: 0 4rpx 20rpx rgba(0, 0, 0, 0.08);
	}

	.section-header {
		margin-bottom: 30rpx;
	}

	.section-title {
		display: block;
		font-size: 36rpx;
		font-weight: 700;
		color: #1A202C;
		margin-bottom: 12rpx;
	}

	.section-subtitle {
		display: block;
		font-size: 26rpx;
		color: #718096;
	}

	/* 症状输入 */
	.textarea-wrapper {
		position: relative;
		margin-bottom: 30rpx;
	}

	.symptom-textarea {
		width: 100%;
		min-height: 300rpx;
		padding: 24rpx;
		background: #F7FAFC;
		border-radius: 16rpx;
		border: 2rpx solid #E2E8F0;
		font-size: 28rpx;
		line-height: 1.6;
		box-sizing: border-box;
	}

	.word-count {
		position: absolute;
		bottom: 16rpx;
		right: 24rpx;
		font-size: 22rpx;
		color: #A0AEC0;
	}

	.submit-btn {
		width: 100%;
		height: 88rpx;
		background: linear-gradient(135deg, lighten($color-primary, 10%) 0%, $color-primary 100%);
		color: #ffffff;
		border-radius: 20rpx;
		font-size: 32rpx;
		font-weight: 600;
		border: none;
	}

	.submit-btn.loading {
		opacity: 0.7;
	}

	/* 科室列表 */
	.department-list {
		display: flex;
		flex-direction: column;
		gap: 20rpx;
	}

	.department-card {
		padding: 28rpx;
		background: linear-gradient(135deg, #F7FAFC 0%, #EDF2F7 100%);
		border-radius: 16rpx;
		border: 2rpx solid #E2E8F0;
		transition: all 0.3s ease;
	}

	.department-card:active {
		background: linear-gradient(135deg, lighten($color-primary, 10%) 0%, $color-primary 100%);
		transform: translateY(-2rpx);
		box-shadow: 0 6rpx 16rpx rgba(79, 209, 197, 0.3);
	}

	.department-card:active .dept-name,
	.department-card:active .dept-reason,
	.department-card:active .dept-description {
		color: #ffffff;
	}

	.dept-header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: 12rpx;
	}

	.dept-name {
		font-size: 32rpx;
		font-weight: 700;
		color: #1A202C;
	}

	.score-badge {
		padding: 6rpx 16rpx;
		background: rgba(79, 209, 197, 0.15);
		border-radius: 12rpx;
	}

	.score-text {
		font-size: 22rpx;
		color: $color-primary;
		font-weight: 600;
	}

	.dept-reason {
		display: block;
		font-size: 26rpx;
		color: $color-primary;
		margin-bottom: 8rpx;
		font-weight: 500;
	}

	.dept-description {
		display: block;
		font-size: 24rpx;
		color: #718096;
		line-height: 1.5;
	}

	/* 医生列表 */
	.doctor-list {
		display: flex;
		flex-direction: column;
		gap: 30rpx;
	}

	.doctor-card {
		padding: 28rpx;
		background: #F7FAFC;
		border-radius: 20rpx;
		border: 2rpx solid #E2E8F0;
	}

	.doctor-info {
		display: flex;
		margin-bottom: 24rpx;
	}

	.doctor-avatar {
		width: 120rpx;
		height: 120rpx;
		border-radius: 16rpx;
		margin-right: 24rpx;
		background: #E2E8F0;
	}

	.doctor-details {
		flex: 1;
	}

	.doctor-name-row {
		display: flex;
		align-items: center;
		margin-bottom: 8rpx;
	}

	.doctor-name {
		font-size: 32rpx;
		font-weight: 700;
		color: #1A202C;
		margin-right: 16rpx;
	}

	.doctor-title {
		font-size: 24rpx;
		color: $color-primary;
		background: rgba(79, 209, 197, 0.15);
		padding: 4rpx 12rpx;
		border-radius: 8rpx;
	}

	.doctor-specialty {
		display: block;
		font-size: 26rpx;
		color: #718096;
		margin-bottom: 8rpx;
	}

	.doctor-reason {
		display: block;
		font-size: 24rpx;
		color: $color-primary;
	}

	/* 排班列表 */
	.schedule-list {
		display: flex;
		flex-direction: column;
		gap: 12rpx;
	}

	.schedule-item {
		padding: 20rpx;
		background: #ffffff;
		border-radius: 12rpx;
		border: 2rpx solid #E2E8F0;
		display: flex;
		justify-content: space-between;
		align-items: center;
		transition: all 0.3s ease;
	}

	.schedule-item:active:not(.disabled) {
		background: linear-gradient(135deg, lighten($color-primary, 10%) 0%, $color-primary 100%);
		border-color: $color-primary;
		transform: translateY(-2rpx);
	}

	.schedule-item.disabled {
		opacity: 0.5;
		background: #F7FAFC;
	}

	.schedule-time {
		display: flex;
		flex-direction: column;
	}

	.schedule-date {
		font-size: 28rpx;
		font-weight: 600;
		color: #1A202C;
		margin-bottom: 4rpx;
	}

	.schedule-time-range {
		font-size: 24rpx;
		color: #718096;
	}

	.schedule-info {
		display: flex;
		flex-direction: column;
		align-items: flex-end;
	}

	.schedule-location {
		font-size: 24rpx;
		color: #718096;
		margin-bottom: 4rpx;
	}

	.schedule-slots {
		font-size: 26rpx;
		font-weight: 600;
		color: $color-primary;
	}

	.schedule-slots.full {
		color: #FC8181;
	}

	.no-schedule {
		padding: 40rpx;
		text-align: center;
	}

	.no-schedule-text {
		font-size: 26rpx;
		color: #A0AEC0;
	}

	/* 加载状态 */
	.loading-state {
		padding: 60rpx;
		text-align: center;
	}

	.loading-text {
		font-size: 28rpx;
		color: #718096;
	}

	/* 返回按钮 */
	.back-btn {
		width: 100%;
		height: 80rpx;
		background: #EDF2F7;
		color: #718096;
		border-radius: 16rpx;
		font-size: 28rpx;
		margin-top: 30rpx;
		border: none;
	}
</style>

