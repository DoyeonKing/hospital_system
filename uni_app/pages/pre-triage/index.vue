<template>
	<view class="container">
		<!-- A. 症状输入区 -->
		<view class="section input-section">
			<view class="section-header">
				<text class="section-title">请描述您的症状</text>
				<text class="section-subtitle">AI 助手将为您分析病情并推荐科室</text>
			</view>

			<!-- 热门症状标签 -->
			<view class="quick-tags">
				<view 
					class="tag" 
					v-for="(item, index) in popularSymptoms" 
					:key="index"
					@click="addSymptomTag(item)"
				>
					{{item}}
				</view>
			</view>

			<!-- 症状描述框 -->
			<view class="textarea-wrapper">
				<textarea 
					class="symptom-textarea" 
					placeholder="请输入详细病情描述，例如：头痛伴有发热，持续两天..." 
					placeholder-class="placeholder"
					v-model="symptomText"
					maxlength="200"
				></textarea>
				<text class="word-count">{{symptomText.length}}/200</text>
			</view>

			<!-- 提交按钮 -->
			<button 
				class="submit-btn" 
				:class="{ loading: loading }"
				@click="submitAnalysis" 
				:disabled="loading || !symptomText"
			>
				{{loading ? 'AI 正在分析...' : '智能分析与挂号'}}
			</button>
		</view>

		<!-- B. AI 分析与科室推荐区 -->
		<view class="section result-section" v-if="analysisResult">
			<view class="section-header">
				<text class="section-title">AI 分析结果</text>
			</view>
			
			<!-- 病情预测卡片 -->
			<view class="analysis-card">
				<view class="ai-icon">🤖</view>
				<text class="analysis-text">{{analysisResult.analysis}}</text>
			</view>

			<!-- 推荐科室列表 -->
			<view class="dept-list">
				<text class="sub-title">推荐就诊科室：</text>
				<view 
					class="dept-card" 
					:class="{ selected: selectedDeptId === item.id }"
					v-for="item in analysisResult.recommendedDepartments" 
					:key="item.id"
					@click="selectDepartment(item.id, item.name)"
				>
					<view class="dept-info">
						<text class="dept-name">{{item.name}}</text>
						<text class="dept-reason" v-if="item.reason">推荐理由: {{item.reason}}</text>
					</view>
					<view class="arrow-icon">></view>
				</view>
			</view>
		</view>

		<!-- C. 医生推荐区 -->
		<view class="section doctor-section" v-if="doctorList.length > 0">
			<view class="section-header">
				<text class="section-title">为您推荐 {{selectedDeptName}} 专家</text>
			</view>
			
			<view class="doctor-list">
				<view 
					class="doctor-card" 
					v-for="(item, index) in doctorList" 
					:key="item.id"
				>
					<view class="doctor-info">
						<view class="doctor-header">
							<text class="doctor-name">{{item.name}}</text>
							<text class="doctor-title">{{item.title}}</text>
						</view>
						<view 
							class="doctor-specialty" 
							:class="{ expanded: item.expanded }"
							@click="toggleDoctorExpand(index)"
						>
							擅长：{{item.specialty}}
						</view>
					</view>
					<button 
						class="book-btn" 
						@click="bookDoctor(item.id)"
					>
						去挂号
					</button>
				</view>
			</view>
		</view>
	</view>
</template>

<script>
	import { get, post } from '../../utils/request.js'
	import config from '../../config/index.js'
	
	export default {
		data() {
			return {
				symptomText: '',
				popularSymptoms: [],
				loading: false,
				analysisResult: null,
				selectedDeptId: null,
				selectedDeptName: '',
				doctorList: []
			}
		},
		onLoad() {
			this.fetchPopularSymptoms()
		},
		methods: {
			// 获取患者ID（从本地存储）
			getPatientId() {
				const patientInfo = uni.getStorageSync('patientInfo')
				return patientInfo && patientInfo.id ? patientInfo.id : null
			},

			// 获取热门症状 - 调用真实 API
			async fetchPopularSymptoms() {
				try {
					uni.showLoading({ title: '加载中...' })
					
					// 使用 AI 服务的 baseURL
					const response = await new Promise((resolve, reject) => {
						uni.request({
							url: config.aiBaseURL + '/api/symptoms/popular',
							method: 'GET',
							header: {
								'Content-Type': 'application/json'
							},
							success: (res) => {
								if (res.statusCode === 200) {
									resolve(res.data)
								} else {
									reject(new Error(`请求失败: ${res.statusCode}`))
								}
							},
							fail: (err) => {
								reject(err)
							}
						})
					})
					
					// 处理响应数据（可能是数组或包装在 data 中）
					if (Array.isArray(response)) {
						this.popularSymptoms = response.slice(0, 10) // 最多显示10个
					} else if (response && Array.isArray(response.data)) {
						this.popularSymptoms = response.data.slice(0, 10)
					} else {
						console.warn('热门症状数据格式异常:', response)
						this.popularSymptoms = ['头痛', '发热', '咳嗽', '腹痛', '皮疹', '失眠'] // 降级到默认值
					}
				} catch (error) {
					console.error('获取热门症状失败:', error)
					uni.showToast({
						title: '加载失败，请重试',
						icon: 'none',
						duration: 2000
					})
					// 降级到默认症状
					this.popularSymptoms = ['头痛', '发热', '咳嗽', '腹痛', '皮疹', '失眠']
				} finally {
					uni.hideLoading()
				}
			},

			// 点击标签添加症状
			addSymptomTag(tag) {
				let currentText = this.symptomText
				if (currentText && !currentText.endsWith('，') && !currentText.endsWith(' ')) {
					currentText += '，'
				}
				this.symptomText = currentText + tag
			},

			// 提交分析 - 调用真实 API
			async submitAnalysis() {
				if (!this.symptomText.trim()) {
					uni.showToast({
						title: '请输入症状描述',
						icon: 'none'
					})
					return
				}

				this.loading = true
				this.analysisResult = null
				this.doctorList = []
				this.selectedDeptId = null

				try {
					uni.showLoading({ title: 'AI 正在分析...' })

					const patientId = this.getPatientId()
					
					const requestData = {
						symptoms: this.symptomText.trim()
					}
					
					// 如果获取到患者ID，添加到请求中
					if (patientId) {
						requestData.patient_id = patientId
					}

					// 使用 AI 服务的 baseURL
					const response = await new Promise((resolve, reject) => {
						uni.request({
							url: config.aiBaseURL + '/api/pre-triage/recommend-department',
							method: 'POST',
							data: requestData,
							header: {
								'Content-Type': 'application/json'
							},
							success: (res) => {
								if (res.statusCode === 200) {
									resolve(res.data)
								} else {
									const errorMsg = res.data && res.data.message ? res.data.message : '未知错误';
									console.error('❌ 后端报错详情:', res.data);
									reject(new Error(`请求失败 ${res.statusCode}: ${errorMsg}`))
								}
							},
							fail: (err) => {
								console.error('❌ 网络请求失败:', err);
								reject(err)
							}
						})
					})
					
					// 处理响应数据
					let result = null
					if (response && response.analysis) {
						// 标准响应格式
						result = {
							analysis: response.analysis,
							recommendedDepartments: []
						}
						
						// 处理推荐科室（可能是单个对象或数组）
						if (response.recommended_department) {
							const dept = response.recommended_department
							result.recommendedDepartments = [{
								id: dept.id,
								name: dept.name,
								reason: dept.reason || 'AI 智能推荐'
							}]
						} else if (response.recommendedDepartments && Array.isArray(response.recommendedDepartments)) {
							result.recommendedDepartments = response.recommendedDepartments
						} else if (response.data && response.data.recommended_department) {
							// 如果数据包装在 data 中
							const dept = response.data.recommended_department
							result.analysis = response.data.analysis || response.analysis
							result.recommendedDepartments = [{
								id: dept.id,
								name: dept.name,
								reason: dept.reason || 'AI 智能推荐'
							}]
						}
					} else if (response && response.data) {
						// 响应包装在 data 中
						result = {
							analysis: response.data.analysis || '分析完成',
							recommendedDepartments: response.data.recommended_department ? [{
								id: response.data.recommended_department.id,
								name: response.data.recommended_department.name,
								reason: response.data.recommended_department.reason || 'AI 智能推荐'
							}] : []
						}
					}

					if (result && result.recommendedDepartments.length > 0) {
						this.analysisResult = result
						
						// 自动选择第一个推荐的科室，并获取医生列表
						const firstDept = result.recommendedDepartments[0]
						this.selectDepartment(firstDept.id, firstDept.name)
					} else {
						uni.showToast({
							title: '未找到推荐科室',
							icon: 'none'
						})
					}
				} catch (error) {
					console.error('AI 分析失败:', error)
					uni.showToast({
						title: error.message || '分析失败，请重试',
						icon: 'none',
						duration: 2000
					})
				} finally {
					this.loading = false
					uni.hideLoading()
				}
			},

			// 选择科室
			selectDepartment(id, name) {
				this.selectedDeptId = id
				this.selectedDeptName = name
				this.fetchRecommendedDoctors(id, this.symptomText)
			},

			// 获取推荐医生 - 调用真实 API
			async fetchRecommendedDoctors(deptId, symptomText) {
				try {
					uni.showLoading({ title: '查找专家中...' })
					
					const requestData = {
						department_id: deptId,
						symptoms: symptomText || this.symptomText.trim()
					}

					// 使用 AI 服务的 baseURL
					const response = await new Promise((resolve, reject) => {
						uni.request({
							url: config.aiBaseURL + '/api/pre-triage/recommend-doctor',
							method: 'POST',
							data: requestData,
							header: {
								'Content-Type': 'application/json'
							},
							timeout: 60000, // 60秒超时，因为AI调用可能需要较长时间
							success: (res) => {
								if (res.statusCode === 200) {
									resolve(res.data)
								} else {
									reject(new Error(`请求失败: ${res.statusCode}`))
								}
							},
							fail: (err) => {
								reject(err)
							}
						})
					})
					
					// 处理响应数据
					let doctors = []
					if (Array.isArray(response)) {
						doctors = response
					} else if (response && Array.isArray(response.data)) {
						doctors = response.data
					} else if (response && response.recommended_doctors && Array.isArray(response.recommended_doctors)) {
						doctors = response.recommended_doctors
					} else if (response && response.data && Array.isArray(response.data.recommended_doctors)) {
						doctors = response.data.recommended_doctors
					}

					// 格式化医生数据，添加 expanded 字段用于展开/收起
					this.doctorList = doctors.map(doctor => ({
						id: doctor.id || doctor.doctor_id,
						name: doctor.name || doctor.full_name,
						title: doctor.title || '医师',
						specialty: doctor.specialty || doctor.specialty_description || '暂无',
						expanded: false
					}))

					if (this.doctorList.length === 0) {
						uni.showToast({
							title: '该科室暂无推荐医生',
							icon: 'none'
						})
					}
				} catch (error) {
					console.error('获取推荐医生失败:', error)
					uni.showToast({
						title: error.message || '获取医生列表失败',
						icon: 'none',
						duration: 2000
					})
					this.doctorList = []
				} finally {
					uni.hideLoading()
				}
			},

			// 展开医生擅长
			toggleDoctorExpand(index) {
				this.doctorList[index].expanded = !this.doctorList[index].expanded
			},

			// 挂号
			bookDoctor(doctorId) {
				uni.showToast({
					title: '正在前往挂号...',
					icon: 'none'
				})
				
				uni.navigateTo({
					url: `/pages/doctor/doctor-detail?id=${doctorId}`
				})
			}
		}
	}
</script>

<style lang="scss" scoped>
	page {
		background-color: #f6f8fa;
		font-family: -apple-system, BlinkMacSystemFont, 'Helvetica Neue', Helvetica,
			Segoe UI, Arial, Roboto, 'PingFang SC', 'miui', 'Hiragino Sans GB', 'Microsoft Yahei',
			sans-serif;
	}

	.container {
		padding: 30rpx;
		padding-bottom: 60rpx;
	}

	.section {
		background: #ffffff;
		border-radius: 24rpx;
		padding: 30rpx;
		margin-bottom: 30rpx;
		box-shadow: 0 4rpx 20rpx rgba(0, 0, 0, 0.05);
	}

	.section-header {
		margin-bottom: 24rpx;
	}

	.section-title {
		display: block;
		font-size: 34rpx;
		font-weight: 600;
		color: #333;
		margin-bottom: 8rpx;
	}

	.section-subtitle {
		display: block;
		font-size: 26rpx;
		color: #999;
	}

	/* Tags */
	.quick-tags {
		display: flex;
		flex-wrap: wrap;
		gap: 20rpx;
		margin-bottom: 30rpx;
	}

	.tag {
		background: #f0f9f8;
		color: #4FD9C3;
		font-size: 26rpx;
		padding: 12rpx 24rpx;
		border-radius: 30rpx;
		border: 1rpx solid rgba(79, 217, 195, 0.3);
		transition: all 0.2s;
	}

	.tag:active {
		background: #4FD9C3;
		color: #fff;
	}

	/* Textarea */
	.textarea-wrapper {
		position: relative;
		background: #f9f9f9;
		border-radius: 16rpx;
		padding: 24rpx;
		margin-bottom: 40rpx;
		border: 1rpx solid #eee;
	}

	.symptom-textarea {
		width: 100%;
		height: 200rpx;
		font-size: 28rpx;
		color: #333;
		line-height: 1.6;
	}

	.placeholder {
		color: #ccc;
	}

	.word-count {
		position: absolute;
		bottom: 16rpx;
		right: 24rpx;
		font-size: 24rpx;
		color: #ccc;
	}

	/* Button */
	.submit-btn {
		background: linear-gradient(135deg, #4FD9C3 0%, #38A2AC 100%);
		color: #fff;
		font-size: 32rpx;
		font-weight: 600;
		border-radius: 44rpx;
		padding: 0;
		line-height: 88rpx;
		border: none;
		width: 100%;
	}

	.submit-btn::after {
		border: none;
	}

	.submit-btn:active {
		opacity: 0.9;
	}

	.submit-btn[disabled] {
		background: #e0e0e0;
		color: #999;
	}

	/* Analysis Result */
	.analysis-card {
		background: #E6FFFA;
		border-radius: 16rpx;
		padding: 24rpx;
		margin-bottom: 30rpx;
		display: flex;
		align-items: flex-start;
	}

	.ai-icon {
		font-size: 40rpx;
		margin-right: 20rpx;
	}

	.analysis-text {
		font-size: 28rpx;
		color: #2C7A7B;
		line-height: 1.6;
		flex: 1;
	}

	.sub-title {
		display: block;
		font-size: 28rpx;
		font-weight: 600;
		color: #333;
		margin-bottom: 20rpx;
	}

	/* Dept List */
	.dept-card {
		display: flex;
		justify-content: space-between;
		align-items: center;
		background: #fff;
		border: 2rpx solid #eee;
		border-radius: 16rpx;
		padding: 24rpx;
		margin-bottom: 20rpx;
		transition: all 0.2s;
	}

	.dept-card.selected {
		border-color: #4FD9C3;
		background-color: #f0f9f8;
	}

	.dept-info {
		flex: 1;
	}

	.dept-name {
		display: block;
		font-size: 30rpx;
		font-weight: 600;
		color: #333;
		margin-bottom: 8rpx;
	}

	.dept-reason {
		display: block;
		font-size: 24rpx;
		color: #666;
	}

	.arrow-icon {
		color: #ccc;
		font-size: 32rpx;
	}

	/* Doctor List */
	.doctor-card {
		display: flex;
		align-items: center;
		padding: 24rpx 0;
		border-bottom: 1rpx solid #f0f0f0;
	}

	.doctor-card:last-child {
		border-bottom: none;
	}

	.doctor-info {
		flex: 1;
		margin-right: 20rpx;
	}

	.doctor-header {
		margin-bottom: 12rpx;
	}

	.doctor-name {
		font-size: 32rpx;
		font-weight: 600;
		color: #333;
		margin-right: 16rpx;
	}

	.doctor-title {
		font-size: 24rpx;
		color: #666;
		background: #f5f5f5;
		padding: 4rpx 12rpx;
		border-radius: 8rpx;
	}

	.doctor-specialty {
		font-size: 24rpx;
		color: #999;
		line-height: 1.4;
		display: -webkit-box;
		-webkit-box-orient: vertical;
		-webkit-line-clamp: 1;
		overflow: hidden;
	}

	.doctor-specialty.expanded {
		-webkit-line-clamp: unset;
	}

	.book-btn {
		font-size: 24rpx;
		color: #fff;
		background: #4FD9C3;
		border-radius: 30rpx;
		padding: 0 24rpx;
		line-height: 56rpx;
		margin: 0;
	}

	.book-btn::after {
		border: none;
	}
</style>

