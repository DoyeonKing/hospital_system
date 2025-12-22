<template>
	<view class="container">
		<view class="page-header">
			<text class="page-title">编辑个人资料</text>
		</view>
		
		<view class="content">
			<view class="form-card">
				<!-- 基本信息 -->
				<view class="section-title">基本信息</view>
				
				<view class="form-item">
					<text class="label">姓名</text>
					<input class="input" v-model="form.fullName" placeholder="请输入姓名" />
				</view>
				
				<view class="form-item">
					<text class="label">性别</text>
					<picker mode="selector" :range="genderOptions" range-key="label" @change="onGenderChange">
						<view class="picker">
							{{ form.genderLabel || '请选择性别' }}
						</view>
					</picker>
				</view>
				
				<view class="form-item">
					<text class="label">出生日期</text>
					<picker mode="date" :value="form.birthDate" @change="onBirthDateChange">
						<view class="picker">
							{{ form.birthDate || '请选择出生日期' }}
						</view>
					</picker>
				</view>
				
				<view class="form-item">
					<text class="label">身份</text>
					<view class="picker read-only">
						{{ form.patientTypeLabel || '请选择身份' }}
					</view>
				</view>
				
				<view class="form-item">
					<text class="label">身高(cm)</text>
					<input class="input" v-model="form.height" type="digit" placeholder="请输入身高" />
				</view>
				
				<view class="form-item">
					<text class="label">体重(kg)</text>
					<input class="input" v-model="form.weight" type="digit" placeholder="请输入体重" />
				</view>
			</view>
			
			<!-- 联系信息 -->
			<view class="form-card">
				<view class="section-title">联系信息</view>
				
				<view class="form-item">
					<text class="label">手机号码</text>
					<input class="input" v-model="form.phoneNumber" type="number" placeholder="请输入手机号码" maxlength="11" />
				</view>
				
				<view class="form-item">
					<text class="label">家庭地址</text>
					<input class="input" v-model="form.homeAddress" placeholder="请输入家庭地址" />
				</view>
				
				<view class="form-item">
					<text class="label">紧急联系人</text>
					<input class="input" v-model="form.emergencyContactName" placeholder="请输入紧急联系人姓名" />
				</view>
				
				<view class="form-item">
					<text class="label">联系人电话</text>
					<input class="input" v-model="form.emergencyContactPhone" type="number" placeholder="请输入紧急联系人电话" maxlength="11" />
				</view>
			</view>
			
			<!-- 医疗信息 -->
			<view class="form-card">
				<view class="section-title">医疗信息</view>
				
				<view class="form-item">
					<text class="label">身份证号</text>
					<input class="input" v-model="form.idCardNumber" type="idcard" placeholder="请输入身份证号" maxlength="18" />
				</view>
				
				<view class="form-item vertical">
					<text class="label">过敏史</text>
					<textarea class="textarea" v-model="form.allergies" placeholder="请输入过敏史（如：青霉素过敏）" maxlength="500" />
				</view>
				
				<view class="form-item vertical">
					<text class="label">既往病史</text>
					<textarea class="textarea" v-model="form.medicalHistory" placeholder="请输入既往病史（如：高血压、糖尿病等）" maxlength="500" />
				</view>
			</view>
			
			<!-- 保存按钮 -->
			<view class="save-section">
				<button class="save-btn" @click="handleSave">保存资料</button>
			</view>
		</view>
	</view>
</template>

<script>
	import { put, get } from '../../utils/request.js'
	
	export default {
		data() {
			return {
				patientId: null,
				form: {
					fullName: '',
					gender: '',
					genderLabel: '',
					birthDate: '',
					patientType: '',
					patientTypeLabel: '',
					height: '',
					weight: '',
					phoneNumber: '',
					homeAddress: '',
					emergencyContactName: '',
					emergencyContactPhone: '',
					idCardNumber: '',
					allergies: '',
					medicalHistory: ''
				},
				genderOptions: [
					{ value: 'male', label: '男' },
					{ value: 'female', label: '女' },
					{ value: 'other', label: '其他' }
				],
				patientTypeOptions: [
					{ value: 'student', label: '学生' },
					{ value: 'teacher', label: '教师' },
					{ value: 'staff', label: '职工' }
				]
			}
		},
		onLoad() {
			this.loadPatientInfo()
		},
		methods: {
			async loadPatientInfo() {
				try {
					const patientInfo = uni.getStorageSync('patientInfo')
					if (!patientInfo || !patientInfo.id) {
						uni.showToast({
							title: '请先登录',
							icon: 'none'
						})
						setTimeout(() => {
							uni.reLaunch({ url: '/pages/login/patient-login' })
						}, 1500)
						return
					}
					
					this.patientId = patientInfo.id
					
					// 先使用本地存储的基本信息填充表单（确保至少显示基本信息）
					this.form.fullName = patientInfo.name || ''
					this.form.phoneNumber = patientInfo.phoneNumber || ''
					this.form.patientType = patientInfo.patientType || 'student'
					this.setPatientTypeLabel()
					
					// 获取患者详细信息
					const response = await get(`/api/users/${this.patientId}?role=PATIENT`)
					
					console.log('患者信息响应:', response)
					
					if (response && response.userDetails) {
						this.populateForm(response.userDetails)
					} else if (response && response.code === '200' && response.data && response.data.userDetails) {
						this.populateForm(response.data.userDetails)
					} else if (response) {
						// 如果返回格式不同，尝试直接使用response
						this.populateForm(response)
					}
				} catch (error) {
					console.error('加载患者信息失败:', error)
					uni.showToast({
						title: '加载信息失败',
						icon: 'none'
					})
				}
			},
			
			populateForm(data) {
				this.form.fullName = data.fullName || ''
				this.form.phoneNumber = data.phoneNumber || ''
				this.form.patientType = data.patientType || 'student'
				this.setPatientTypeLabel()
				
				// 患者档案信息
				if (data.patientProfile) {
					const profile = data.patientProfile
					this.form.idCardNumber = profile.idCardNumber || ''
					this.form.allergies = profile.allergies || ''
					this.form.medicalHistory = profile.medicalHistory || ''
					this.form.birthDate = profile.birthDate || ''
					this.form.gender = profile.gender || ''
					this.setGenderLabel()
					this.form.homeAddress = profile.homeAddress || ''
					this.form.emergencyContactName = profile.emergencyContactName || ''
					this.form.emergencyContactPhone = profile.emergencyContactPhone || ''
					this.form.height = profile.height || ''
					this.form.weight = profile.weight || ''
				}
			},
			
			onGenderChange(e) {
				const index = e.detail.value
				this.form.gender = this.genderOptions[index].value
				this.form.genderLabel = this.genderOptions[index].label
			},
			
			setGenderLabel() {
				const option = this.genderOptions.find(opt => opt.value === this.form.gender)
				if (option) {
					this.form.genderLabel = option.label
				}
			},
			
			// 移除 onPatientTypeChange 方法，因为身份不允许修改
			
			setPatientTypeLabel() {
				const option = this.patientTypeOptions.find(opt => opt.value === this.form.patientType)
				if (option) {
					this.form.patientTypeLabel = option.label
				}
			},
			
			onBirthDateChange(e) {
				this.form.birthDate = e.detail.value
			},
			
			async handleSave() {
				// 验证必填项
				if (!this.form.fullName) {
					uni.showToast({ title: '请输入姓名', icon: 'none' })
					return
				}
				if (!this.form.phoneNumber) {
					uni.showToast({ title: '请输入手机号码', icon: 'none' })
					return
				}
				
				// 验证手机号格式
				if (!/^1[3-9]\d{9}$/.test(this.form.phoneNumber)) {
					uni.showToast({ title: '手机号码格式不正确', icon: 'none' })
					return
				}
				
				// 验证紧急联系人电话格式（如果填写了）
				if (this.form.emergencyContactPhone && !/^1[3-9]\d{9}$/.test(this.form.emergencyContactPhone)) {
					uni.showToast({ title: '紧急联系人电话格式不正确', icon: 'none' })
					return
				}
				
				uni.showLoading({ title: '保存中...' })
				
				try {
					const requestData = {
						role: 'PATIENT',
						patientUpdateRequest: {
							fullName: this.form.fullName,
							phoneNumber: this.form.phoneNumber,
							// 身份类型不允许患者自己修改，不发送此字段
							idCardNumber: this.form.idCardNumber || null,
							allergies: this.form.allergies || null,
							medicalHistory: this.form.medicalHistory || null,
							birthDate: this.form.birthDate || null,
							gender: this.form.gender || null,
							homeAddress: this.form.homeAddress || null,
							emergencyContactName: this.form.emergencyContactName || null,
							emergencyContactPhone: this.form.emergencyContactPhone || null,
							height: this.form.height ? parseFloat(this.form.height) : null,
							weight: this.form.weight ? parseFloat(this.form.weight) : null
						}
					}
					
					console.log('保存患者信息，请求数据:', requestData)
					
					const response = await put(`/api/users/${this.patientId}`, requestData)
					
					console.log('保存响应:', response)
					
					uni.hideLoading()
					
					// 后端直接返回 UserResponse 对象，格式为 {role: "PATIENT", userDetails: {...}}
					// 检查是否有 userDetails 或 role 字段来判断成功
					if (response && (response.userDetails || response.role === 'PATIENT' || (response.code === '200' || response.code === 200))) {
						// 更新本地存储的患者信息
						const patientInfo = uni.getStorageSync('patientInfo') || {}
						patientInfo.name = this.form.fullName
						patientInfo.phoneNumber = this.form.phoneNumber
						patientInfo.patientType = this.form.patientType
						uni.setStorageSync('patientInfo', patientInfo)
						
						uni.showToast({
							title: '保存成功',
							icon: 'success'
						})
						
						setTimeout(() => {
							uni.navigateBack()
						}, 1500)
					} else {
						uni.showToast({
							title: response?.msg || '保存失败',
							icon: 'none'
						})
					}
				} catch (error) {
					uni.hideLoading()
					console.error('保存患者信息失败:', error)
					uni.showToast({
						title: error.message || '保存失败',
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

	.form-card {
		background: #ffffff;
		border-radius: 20rpx;
		padding: 30rpx;
		margin-bottom: 20rpx;
		box-shadow: 0 2rpx 12rpx rgba(0, 0, 0, 0.06);
	}

	.section-title {
		font-size: 32rpx;
		font-weight: 600;
		color: #1A202C;
		margin-bottom: 30rpx;
		padding-bottom: 20rpx;
		border-bottom: 2rpx solid #f0f0f0;
	}

	.form-item {
		display: flex;
		align-items: center;
		margin-bottom: 30rpx;
	}

	.form-item.vertical {
		flex-direction: column;
		align-items: flex-start;
	}

	.label {
		font-size: 28rpx;
		color: #4A5568;
		width: 180rpx;
		flex-shrink: 0;
	}

	.form-item.vertical .label {
		margin-bottom: 16rpx;
	}

	.input {
		flex: 1;
		height: 80rpx;
		line-height: 80rpx;
		padding: 0 24rpx;
		background: #F7FAFC;
		border-radius: 12rpx;
		font-size: 28rpx;
		color: #1A202C;
		box-sizing: border-box;
	}

	.picker {
		flex: 1;
		height: 80rpx;
		padding: 0 24rpx;
		background: #F7FAFC;
		border-radius: 12rpx;
		font-size: 28rpx;
		color: #1A202C;
		display: flex;
		align-items: center;
	}

	.picker.read-only {
		background: #F0F0F0;
		color: #999999;
	}

	.textarea {
		width: 100%;
		min-height: 180rpx;
		padding: 24rpx;
		background: #F7FAFC;
		border-radius: 12rpx;
		font-size: 28rpx;
		color: #1A202C;
		line-height: 1.6;
	}

	.save-section {
		position: fixed;
		bottom: 0;
		left: 0;
		right: 0;
		padding: 30rpx;
		background: #ffffff;
		box-shadow: 0 -2rpx 12rpx rgba(0, 0, 0, 0.08);
		z-index: 100;
	}

	.save-btn {
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

