<template>
	<view class="container">
		<view class="page-header">
			<text class="page-title">{{ departmentName }}</text>
		</view>
		
		<view class="content">
			<!-- 日期选择器 -->
			<scroll-view class="date-selector" scroll-x="true">
				<view class="date-btn all-dates" :class="{ active: selectedDate === 'all' }" @click="selectAllDates">
					<text>全部</text>
				</view>
				<view 
					class="date-btn" 
					v-for="date in dateOptions" 
					:key="date.value"
					:class="{ active: selectedDate === date.value }"
					@click="selectDate(date.value)"
				>
					<text class="date-week">{{ date.week }}</text>
					<text class="date-detail">{{ date.detail }}</text>
				</view>
			</scroll-view>
			
			<!-- 医生列表和排班信息 -->
			<view class="doctor-schedule-container" v-if="doctorList.length > 0">
				<!-- 左侧：医生列表 -->
				<scroll-view class="doctor-list" scroll-y="true">
					<view 
						class="doctor-item" 
						v-for="doctor in doctorList" 
						:key="doctor.doctorId"
						:class="{ active: selectedDoctorId === doctor.doctorId }"
						@click="selectDoctor(doctor.doctorId)"
					>
						<image class="doctor-avatar-small" :src="doctor.photoUrl" mode="aspectFill" @error="handleImageError"></image>
						<view class="doctor-name-small">{{ doctor.doctorName }}</view>
						<view class="doctor-title-small">{{ doctor.doctorTitle }}</view>
					</view>
				</scroll-view>
				
				<!-- 右侧：该医生的排班信息 -->
				<scroll-view class="schedule-list" scroll-y="true">
					<view v-if="currentDoctorSchedules.length > 0">
						<!-- 医生简介卡片 -->
						<view class="doctor-intro-card" v-if="currentDoctorInfo" @click="navigateToDoctorDetail(currentDoctorInfo.doctorId)">
							<view class="intro-avatar-section">
								<image class="intro-avatar" :src="currentDoctorInfo.photoUrl" mode="aspectFill" @error="handleImageError"></image>
							</view>
							<view class="intro-info-section">
								<view class="intro-name-row">
									<text class="intro-name">{{ currentDoctorInfo.doctorName }}</text>
									<text class="intro-title-badge">{{ currentDoctorInfo.doctorTitle }}</text>
								</view>
								<view class="intro-department">
									<text class="dept-icon">🏥</text>
									<text class="dept-name">{{ currentDoctorInfo.departmentName }}</text>
								</view>
								<view class="intro-specialty">
									<text class="specialty-label">擅长：</text>
									<text class="specialty-text">{{ currentDoctorInfo.specialty }}</text>
								</view>
								<view class="intro-bio" v-if="currentDoctorInfo.bio">
									<text class="bio-text">{{ currentDoctorInfo.bio }}</text>
								</view>
								<view class="intro-more">
									<text class="more-text">查看详情 ></text>
								</view>
							</view>
						</view>
						
						<!-- 按日期分组显示 -->
						<view class="date-group" v-for="(group, date) in groupedCurrentDoctorSchedules" :key="date">
							<view class="date-header">
								<text class="date-title">{{ formatDateHeader(date) }}</text>
							</view>
							
							<!-- 每个排班卡片 -->
							<view 
								class="schedule-card" 
								v-for="schedule in group" 
								:key="schedule.scheduleId"
								@click="navigateToConfirm(schedule)"
							>
								<view class="card-top">
									<view class="time-info">
										<text class="time-label">🕐 就诊时间</text>
										<text class="time-value">{{ schedule.slotName }}</text>
									</view>
									<view class="status-tag" :class="{ 'full-tag': schedule.remainingSlots === 0 }">
										{{ schedule.remainingSlots === 0 ? '已约满' : '可预约' }}
									</view>
								</view>
								
								<view class="card-middle">
									<view class="info-item">
										<text class="info-icon">📍</text>
										<text class="info-text">{{ schedule.location }}</text>
									</view>
								</view>
								
								<view class="card-bottom">
									<view class="slots-display">
										<text class="slots-value">{{ schedule.remainingSlots }}</text>
										<text class="slots-unit">/{{ schedule.totalSlots }}</text>
										<text class="slots-label">号源</text>
									</view>
									<view class="price-display">
										<text class="price-symbol">¥</text>
										<text class="price-value-large">{{ schedule.fee }}</text>
									</view>
									<view 
										class="action-btn" 
										:class="{ 'full-btn': schedule.remainingSlots === 0 }"
									>
										{{ schedule.remainingSlots === 0 ? '候补' : '预约' }}
									</view>
								</view>
							</view>
						</view>
					</view>
					
					<view class="empty-state" v-else>
						<text class="empty-icon">🩺</text>
						<text class="empty-text">该医生暂无排班</text>
						<text class="empty-desc">请选择其他医生</text>
					</view>
				</scroll-view>
			</view>
			
			<!-- 全局空状态 -->
			<view class="empty-state" v-else>
				<text class="empty-icon">🩺</text>
				<text class="empty-text">该科室暂无医生排班</text>
				<text class="empty-desc">请选择其他科室</text>
			</view>
		</view>
	</view>
</template>

<script>
	import { mockSchedules } from '../../api/mockData.js'
	import { mockDoctorDetails } from '../../api/mockData.js'
	import { getSchedulesByDepartment } from '../../api/schedule.js'
	
	export default {
		data() {
			return {
				departmentId: null,
				departmentName: '',
				scheduleList: [],
				doctorList: [],
				doctorDetailsMap: {}, // 存储医生详细信息
				selectedDoctorId: null,
				selectedDate: 'all',
				dateOptions: []
			}
		},
		computed: {
			// 当前选中医生的信息
			currentDoctorInfo() {
				if (!this.selectedDoctorId) return null
				// 优先使用后端返回的医生信息
				if (this.doctorDetailsMap[this.selectedDoctorId]) {
					return this.doctorDetailsMap[this.selectedDoctorId]
				}
				// 如果没有，使用Mock数据
				return mockDoctorDetails.find(d => d.doctorId === this.selectedDoctorId) || null
			},
			
			// 当前选中医生的排班
			currentDoctorSchedules() {
				if (!this.selectedDoctorId) return []
				
				let filtered = this.scheduleList.filter(s => s.doctorId === this.selectedDoctorId)
				
				// 根据选中的日期筛选
				if (this.selectedDate !== 'all') {
					filtered = filtered.filter(s => s.scheduleDate === this.selectedDate)
				}
				
				return filtered
			},
			
			// 按日期分组显示
			groupedCurrentDoctorSchedules() {
				const groups = {}
				this.currentDoctorSchedules.forEach(schedule => {
					if (!groups[schedule.scheduleDate]) {
						groups[schedule.scheduleDate] = []
					}
					groups[schedule.scheduleDate].push(schedule)
				})
				
				// 按日期排序
				const sortedDates = Object.keys(groups).sort()
				const result = {}
				sortedDates.forEach(date => {
					result[date] = groups[date].sort((a, b) => {
						return a.startTime.localeCompare(b.startTime)
					})
				})
				
				return result
			}
		},
		onLoad(options) {
			try {
				this.departmentId = parseInt(options.departmentId)
				this.departmentName = decodeURIComponent(options.departmentName || '')
				console.log('排班页加载 - departmentId:', this.departmentId, 'departmentName:', this.departmentName)
				
				// 验证参数是否有效
				if (isNaN(this.departmentId)) {
					console.error('排班页加载失败 - departmentId 无效:', options.departmentId)
					uni.showToast({
						title: '参数错误',
						icon: 'error'
					})
					setTimeout(() => {
						uni.navigateBack()
					}, 1500)
					return
				}
				
				this.initDateOptions()
				this.loadSchedules()
			} catch (error) {
				console.error('排班页加载失败:', error)
				uni.showToast({
					title: '加载失败',
					icon: 'error'
				})
			}
		},
		methods: {
			// 初始化日期选项
			initDateOptions() {
				const options = []
				const today = new Date()
				
				// 生成7天的日期选项
				for (let i = 0; i < 7; i++) {
					const date = new Date(today)
					date.setDate(date.getDate() + i)
					
					const weekDays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六']
					const month = date.getMonth() + 1
					const day = date.getDate()
					
					options.push({
						value: this.formatDate(date),
						week: weekDays[date.getDay()],
						detail: `${month}.${day}`,
						label: i === 0 ? '今天' : ''
					})
				}
				
				this.dateOptions = options
				this.selectedDate = 'all' // 默认显示全部日期
		},
		
		// 格式化日期
		formatDate(date) {
			const year = date.getFullYear()
			const month = String(date.getMonth() + 1).padStart(2, '0')
			const day = String(date.getDate()).padStart(2, '0')
			return `${year}-${month}-${day}`
		},
		
		// 加载排班数据
		async loadSchedules() {
			try {
				// 生成日期范围：最近7天
				const today = new Date()
				const startDate = this.formatDate(today)
				const endDateObj = new Date(today)
				endDateObj.setDate(endDateObj.getDate() + 6)
				const endDate = this.formatDate(endDateObj)
				
				console.log('排班页 - 调用后端API', {
					departmentId: this.departmentId,
					startDate,
					endDate
				})
				
				// 调用后端API
				const response = await getSchedulesByDepartment(this.departmentId, startDate, endDate)
				console.log('排班页 - API响应:', response)
				
				// 提取数据
				let allSchedules = []
				if (response.data && Array.isArray(response.data)) {
					allSchedules = response.data
				} else if (Array.isArray(response)) {
					allSchedules = response
				} else {
					console.warn('排班页 - 响应格式异常，使用Mock数据')
					allSchedules = JSON.parse(JSON.stringify(mockSchedules))
				}
				
			console.log('排班页 - 获取到的排班数据量:', allSchedules.length)
			console.log('排班页 - 前3条排班数据:', allSchedules.slice(0, 3))
			
			this.scheduleList = allSchedules
			
			// 提取医生列表（去重）
			const doctorMap = {}
			const doctorDetailsMap = {}
			this.scheduleList.forEach(schedule => {
				if (!doctorMap[schedule.doctorId]) {
					console.log('排班页 - 处理医生数据:', {
						doctorId: schedule.doctorId,
						doctorName: schedule.doctorName,
						doctorTitle: schedule.doctorTitle,
						specialty: schedule.specialty,
						photoUrl: schedule.photoUrl,
						departmentName: schedule.departmentName
					})
					// 基础信息用于列表显示
					doctorMap[schedule.doctorId] = {
						doctorId: schedule.doctorId,
						doctorName: schedule.doctorName,
						doctorTitle: schedule.doctorTitle,
						specialty: schedule.specialty,
						photoUrl: schedule.photoUrl
					}
					// 详细信息用于简介卡片显示
					doctorDetailsMap[schedule.doctorId] = {
						doctorId: schedule.doctorId,
						doctorName: schedule.doctorName,
						doctorTitle: schedule.doctorTitle,
						specialty: schedule.specialty,
						photoUrl: schedule.photoUrl,
						departmentName: schedule.departmentName || this.departmentName,
						bio: '' // bio 字段需要从后端医生详情接口获取
					}
				}
			})
			
			this.doctorList = Object.values(doctorMap)
			this.doctorDetailsMap = doctorDetailsMap
			console.log('排班页 - 医生数量:', this.doctorList.length)
			console.log('排班页 - 医生列表:', this.doctorList)
			console.log('排班页 - 医生详情Map:', this.doctorDetailsMap)
			
			// 默认选中第一个医生
			if (this.doctorList.length > 0) {
				this.selectedDoctorId = this.doctorList[0].doctorId
				console.log('排班页 - 默认选中的医生ID:', this.selectedDoctorId)
			} else {
				console.warn('排班页 - 没有找到任何医生！')
			}
			} catch (error) {
				console.error('加载排班数据失败:', error)
				// 失败时使用Mock数据作为fallback
				try {
					const allSchedules = JSON.parse(JSON.stringify(mockSchedules))
					this.scheduleList = allSchedules.filter(s => s.departmentId === this.departmentId)
					
					const doctorMap = {}
					this.scheduleList.forEach(schedule => {
						if (!doctorMap[schedule.doctorId]) {
							doctorMap[schedule.doctorId] = {
								doctorId: schedule.doctorId,
								doctorName: schedule.doctorName,
								doctorTitle: schedule.doctorTitle,
								specialty: schedule.specialty,
								photoUrl: schedule.photoUrl
							}
						}
					})
					this.doctorList = Object.values(doctorMap)
					
					if (this.doctorList.length > 0) {
						this.selectedDoctorId = this.doctorList[0].doctorId
					}
				} catch (fallbackError) {
					console.error('Fallback失败:', fallbackError)
				}
			}
		},
		
		// 选择日期
		selectDate(date) {
			this.selectedDate = date
		},
		
		// 选择全部日期
		selectAllDates() {
			this.selectedDate = 'all'
		},
		
		// 选择医生
		selectDoctor(doctorId) {
			this.selectedDoctorId = doctorId
		},
		
		// 格式化日期标题
		formatDateHeader(date) {
			try {
				const d = new Date(date)
				if (isNaN(d.getTime())) {
					return date
				}
				const weekDays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六']
				const month = d.getMonth() + 1
				const day = d.getDate()
				const week = weekDays[d.getDay()]
				return `${date} (${week})`
			} catch (e) {
				return date
			}
		},
		
		// 图片加载失败处理
		handleImageError(e) {
			console.log('图片加载失败:', e)
			e.target.src = 'https://cube.elemecdn.com/0/88/03b0d39583f48206768a7534e55bcpng.png'
		},
		
		// 跳转到医生详情页
		navigateToDoctorDetail(doctorId) {
			uni.navigateTo({
				url: `/pages/doctor/doctor-detail?doctorId=${doctorId}`
			})
		},
		
		// 跳转到确认页面或候补页面
		navigateToConfirm(schedule) {
			if (schedule.remainingSlots === 0) {
				// 已约满，跳转到候补申请
				uni.showModal({
					title: '号源已满',
					content: '该时段已约满，是否申请候补排队？',
					confirmText: '申请候补',
					cancelText: '取消',
					success: (res) => {
						if (res.confirm) {
							this.navigateToWaitlist(schedule)
						}
					}
				})
				return
			}
			
			uni.navigateTo({
				url: `/pages/appointment/confirm?scheduleId=${schedule.scheduleId}`
			})
		},
		
		// 跳转到候补申请
		navigateToWaitlist(schedule) {
			// TODO: 调用后端API创建候补申请
			// 模拟：显示提示并跳转到候补列表
			uni.showToast({
				title: '候补申请成功',
				icon: 'success'
			})
			setTimeout(() => {
				uni.navigateTo({
					url: '/pages/waitlist/waitlist'
				})
			}, 1500)
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
		display: flex;
		flex-direction: column;
		height: calc(100vh - 200rpx);
	}

	.date-selector {
		background: #ffffff;
		padding: 20rpx 0;
		white-space: nowrap;
		border-bottom: 1rpx solid #f0f0f0;
	}

	.date-btn {
		display: inline-block;
		padding: 16rpx 28rpx;
		margin-right: 16rpx;
		border-radius: 8rpx;
		background: #f0f0f0;
		transition: all 0.3s ease;
	}

	.date-btn.active {
		background: linear-gradient(135deg, lighten($color-primary, 10%) 0%, $color-primary 100%);
		color: #ffffff;
	}

	.all-dates {
		margin-left: 30rpx;
	}

	.date-week {
		display: block;
		font-size: 24rpx;
		text-align: center;
		margin-bottom: 4rpx;
	}

	.date-detail {
		display: block;
		font-size: 26rpx;
		text-align: center;
		font-weight: 500;
	}

	.doctor-schedule-container {
		display: flex;
		flex: 1;
		overflow: hidden;
	}

	.doctor-list {
		width: 200rpx;
		background: #ffffff;
		border-right: 1rpx solid #f0f0f0;
	}

	.doctor-item {
		display: flex;
		flex-direction: column;
		align-items: center;
		padding: 30rpx 20rpx;
		border-bottom: 1rpx solid #f8f8f8;
		transition: all 0.3s ease;
	}

	.doctor-item.active {
		background: #F0FDFC;
		border-left: 4rpx solid $color-primary;
	}

	.doctor-avatar-small {
		width: 100rpx;
		height: 100rpx;
		border-radius: 50%;
		background: #f0f0f0;
		margin-bottom: 16rpx;
	}

	.doctor-name-small {
		font-size: 28rpx;
		font-weight: 600;
		color: #1A202C;
		margin-bottom: 8rpx;
		text-align: center;
	}

	.doctor-title-small {
		font-size: 22rpx;
		color: #718096;
		text-align: center;
	}

	.schedule-list {
		flex: 1;
		background: #f7fafc;
		padding: 20rpx;
	}
	
	// 医生简介卡片
	.doctor-intro-card {
		background: linear-gradient(135deg, rgba(79, 209, 197, 0.1) 0%, rgba(79, 209, 197, 0.05) 100%);
		border: 2rpx solid rgba(79, 209, 197, 0.3);
		border-radius: 20rpx;
		padding: 30rpx;
		margin-bottom: 30rpx;
		display: flex;
		align-items: flex-start;
		transition: all 0.3s ease;
	}
	
	.doctor-intro-card:active {
		transform: scale(0.98);
		background: linear-gradient(135deg, rgba(79, 209, 197, 0.15) 0%, rgba(79, 209, 197, 0.08) 100%);
	}
	
	.intro-avatar-section {
		margin-right: 24rpx;
	}
	
	.intro-avatar {
		width: 120rpx;
		height: 120rpx;
		border-radius: 16rpx;
		border: 3rpx solid rgba(79, 209, 197, 0.3);
		background: #f0f0f0;
	}
	
	.intro-info-section {
		flex: 1;
		display: flex;
		flex-direction: column;
	}
	
	.intro-name-row {
		display: flex;
		align-items: baseline;
		margin-bottom: 12rpx;
	}
	
	.intro-name {
		font-size: 36rpx;
		font-weight: 700;
		color: #1A202C;
		margin-right: 12rpx;
	}
	
	.intro-title-badge {
		font-size: 22rpx;
		color: #718096;
		padding: 4rpx 12rpx;
		background: #E6FFFA;
		border-radius: 8rpx;
		border: 1rpx solid rgba(79, 209, 197, 0.3);
	}
	
	.intro-department {
		display: flex;
		align-items: center;
		margin-bottom: 12rpx;
	}
	
	.dept-icon {
		font-size: 24rpx;
		margin-right: 8rpx;
	}
	
	.dept-name {
		font-size: 26rpx;
		color: #4A5568;
	}
	
	.intro-specialty {
		display: flex;
		align-items: flex-start;
		margin-bottom: 16rpx;
	}
	
	.specialty-label {
		font-size: 26rpx;
		color: #718096;
		margin-right: 8rpx;
		white-space: nowrap;
	}
	
	.specialty-text {
		font-size: 26rpx;
		color: #4FD9C3;
		font-weight: 500;
	}
	
	.intro-bio {
		margin-bottom: 16rpx;
		line-height: 1.6;
	}
	
	.bio-text {
		font-size: 24rpx;
		color: #718096;
		line-height: 1.6;
		display: -webkit-box;
		-webkit-box-orient: vertical;
		line-clamp: 2;
		-webkit-line-clamp: 2;
		overflow: hidden;
		text-overflow: ellipsis;
	}
	
	.intro-more {
		display: flex;
		justify-content: flex-end;
		padding-top: 12rpx;
		border-top: 1rpx solid rgba(79, 209, 197, 0.2);
	}
	
	.more-text {
		font-size: 24rpx;
		color: #4FD9C3;
		font-weight: 600;
	}

	.date-group {
		margin-bottom: 30rpx;
	}

	.date-header {
		padding: 20rpx 0;
		border-bottom: 2rpx solid $color-primary;
		margin-bottom: 20rpx;
	}

	.date-title {
		font-size: 28rpx;
		font-weight: 600;
		color: $color-primary;
	}

	.schedule-card {
		background: #ffffff;
		border-radius: 16rpx;
		padding: 30rpx;
		margin-bottom: 20rpx;
		box-shadow: 0 2rpx 12rpx rgba(0, 0, 0, 0.06);
	}

	.schedule-card.full {
		opacity: 0.8;
	}

	.card-top {
		display: flex;
		justify-content: space-between;
		align-items: flex-start;
		margin-bottom: 20rpx;
		padding-bottom: 20rpx;
		border-bottom: 1rpx solid #F0F0F0;
	}

	.time-info {
		flex: 1;
		display: flex;
		flex-direction: column;
	}

	.time-label {
		font-size: 24rpx;
		color: #718096;
		margin-bottom: 8rpx;
	}

	.time-value {
		font-size: 32rpx;
		font-weight: 600;
		color: #1A202C;
	}

	.status-tag {
		font-size: 24rpx;
		color: #38A169;
		background: #C6F6D5;
		padding: 6rpx 16rpx;
		border-radius: 20rpx;
	}

	.status-tag.full-tag {
		color: #E53E3E;
		background: #FED7D7;
	}

	.card-middle {
		margin-bottom: 20rpx;
	}

	.info-item {
		display: flex;
		align-items: center;
		margin-bottom: 12rpx;
	}

	.info-icon {
		font-size: 28rpx;
		margin-right: 12rpx;
	}

	.info-text {
		font-size: 26rpx;
		color: #4A5568;
	}

	.card-bottom {
		display: flex;
		justify-content: space-between;
		align-items: center;
		padding-top: 20rpx;
		border-top: 1rpx solid #F0F0F0;
	}

	.slots-display {
		display: flex;
		align-items: baseline;
		flex: 1;
	}

	.slots-value {
		font-size: 36rpx;
		font-weight: 700;
		color: $color-primary;
		margin-right: 4rpx;
	}

	.slots-unit {
		font-size: 24rpx;
		color: #A0AEC0;
		margin-right: 8rpx;
	}

	.slots-label {
		font-size: 24rpx;
		color: #718096;
	}

	.price-display {
		margin-right: 20rpx;
		display: flex;
		align-items: baseline;
	}

	.price-symbol {
		font-size: 24rpx;
		font-weight: 600;
		color: #FF6B6B;
	}

	.price-value-large {
		font-size: 32rpx;
		font-weight: 700;
		color: #FF6B6B;
	}

	.action-btn {
		padding: 12rpx 32rpx;
		background: linear-gradient(135deg, lighten($color-primary, 10%) 0%, $color-primary 100%);
		border-radius: 50rpx;
		color: #ffffff;
		font-size: 28rpx;
		font-weight: 600;
	}

	.action-btn.full-btn {
		background: #E2E8F0;
		color: #A0AEC0;
	}

	.empty-state {
		flex: 1;
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		padding: 120rpx 40rpx;
		text-align: center;
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
	}
</style>