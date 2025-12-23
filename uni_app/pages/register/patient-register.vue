<template>
	<view class="container">
		<view class="header">
			<image class="logo" src="/static/logo.png" mode="aspectFit"></image>
			<text class="app-title">"挂了吗"校医院挂号系统</text>
		</view>
		
		<view class="form-container">
			<text class="title">学生/教师注册</text>
			<text class="subtitle">请填写以下信息并上传身份证正反面照片</text>
			
			<view class="form-section">
				<view class="input-group">
					<text class="input-label">学号/工号 <text class="required">*</text></text>
					<input class="input-field" v-model="form.identifier" placeholder="请输入学号或工号" />
				</view>
				
				<view class="input-group">
					<text class="input-label">密码 <text class="required">*</text></text>
					<input class="input-field" v-model="form.password" type="password" placeholder="6-20位密码" />
				</view>
				
				<view class="input-group">
					<text class="input-label">姓名 <text class="required">*</text></text>
					<input class="input-field" v-model="form.fullName" placeholder="请输入真实姓名" />
				</view>
				
				<view class="input-group">
					<text class="input-label">手机号 <text class="required">*</text></text>
					<input class="input-field" v-model="form.phoneNumber" type="number" placeholder="请输入手机号" />
				</view>
				
				<view class="input-group">
					<text class="input-label">身份证号 <text class="required">*</text></text>
					<input class="input-field" v-model="form.idCardNumber" placeholder="请输入身份证号" />
				</view>
				
				<view class="input-group">
					<text class="input-label">身份类型 <text class="required">*</text></text>
					<picker :value="patientTypeIndex" :range="patientTypes" @change="onPatientTypeChange">
						<view class="picker-view">{{ patientTypes[patientTypeIndex] }}</view>
					</picker>
				</view>
				
				<view class="input-group">
					<text class="input-label">身份证正面 <text class="required">*</text></text>
					<text class="input-hint">请上传身份证正面照片</text>
					<view class="upload-section">
						<button class="upload-btn" @click="chooseImage('front')" :disabled="uploading.front">
							{{ uploading.front ? '上传中...' : '选择图片' }}
						</button>
						<image v-if="form.idCardFrontPreview" :src="form.idCardFrontPreview" mode="aspectFit" class="preview-image"></image>
					</view>
				</view>
				
				<view class="input-group">
					<text class="input-label">身份证背面 <text class="required">*</text></text>
					<text class="input-hint">请上传身份证背面照片</text>
					<view class="upload-section">
						<button class="upload-btn" @click="chooseImage('back')" :disabled="uploading.back">
							{{ uploading.back ? '上传中...' : '选择图片' }}
						</button>
						<image v-if="form.idCardBackPreview" :src="form.idCardBackPreview" mode="aspectFit" class="preview-image"></image>
					</view>
				</view>
				
				<button class="submit-btn" @click="submitRegister" :disabled="submitting">
					{{ submitting ? '提交中...' : '提交注册' }}
				</button>
				
				<view class="footer-text" @click="goToLogin">
					<text>已有账户？去登录</text>
				</view>
			</view>
		</view>
	</view>
</template>

<script>
	import { post } from '../../utils/request.js'
	import config from '../../config/index.js'
	
	export default {
		data() {
			return {
				form: {
					identifier: '',
					password: '',
					fullName: '',
					phoneNumber: '',
					idCardNumber: '',
					patientType: 'student',
					idCardFrontUrl: '',  // 服务器返回的URL，用于提交注册
					idCardBackUrl: '',  // 服务器返回的URL，用于提交注册
					idCardFrontFile: null,
					idCardBackFile: null,
					idCardFrontPreview: '',  // 本地预览路径
					idCardBackPreview: ''  // 本地预览路径
				},
				patientTypes: ['学生', '教师', '职工'],
				patientTypeIndex: 0,
				uploading: {
					front: false,
					back: false
				},
				submitting: false
			}
		},
		methods: {
			onPatientTypeChange(e) {
				this.patientTypeIndex = e.detail.value
				const types = ['student', 'teacher', 'staff']
				this.form.patientType = types[e.detail.value]
			},
			
			async chooseImage(type) {
				try {
					const res = await uni.chooseImage({
						count: 1,
						sourceType: ['camera', 'album'],
						sizeType: ['compressed']
					})
					
					if (res.tempFilePaths && res.tempFilePaths.length > 0) {
						if (type === 'front') {
							this.form.idCardFrontFile = res.tempFiles[0]
							this.form.idCardFrontPreview = res.tempFilePaths[0]  // 保存本地预览路径
							this.form.idCardFrontUrl = res.tempFilePaths[0]  // 临时设置，上传成功后会被替换
							console.log('[CHOOSE] 正面照片选择成功:', res.tempFilePaths[0])
							// 自动上传
							await this.uploadFile('front')
						} else if (type === 'back') {
							this.form.idCardBackFile = res.tempFiles[0]
							this.form.idCardBackPreview = res.tempFilePaths[0]  // 保存本地预览路径
							this.form.idCardBackUrl = res.tempFilePaths[0]  // 临时设置，上传成功后会被替换
							console.log('[CHOOSE] 背面照片选择成功:', res.tempFilePaths[0])
							// 自动上传
							await this.uploadFile('back')
						}
					}
				} catch (error) {
					console.error('选择图片失败:', error)
					uni.showToast({
						title: '选择图片失败',
						icon: 'none'
					})
				}
			},
			
			async uploadFile(type) {
				const fileField = type === 'front' ? 'idCardFrontFile' : 'idCardBackFile'
				const urlField = type === 'front' ? 'idCardFrontUrl' : 'idCardBackUrl'
				const uploadingField = type === 'front' ? 'front' : 'back'
				
				if (!this.form[fileField]) {
					throw new Error(`请先选择身份证${type === 'front' ? '正面' : '背面'}照片`)
				}
				
				this.uploading[uploadingField] = true
				try {
					const baseURL = config.baseURL
					const uploadUrl = baseURL + '/api/files/upload-identity-proof'
					const filePath = this.form[urlField]
					
					console.log('[UPLOAD] 开始上传:', { type, uploadUrl, filePath })
					
					// uni.uploadFile 返回 UploadTask，需要使用 Promise 包装
					const result = await new Promise((resolve, reject) => {
						uni.uploadFile({
							url: uploadUrl,
							filePath: filePath,
							name: 'file',
							header: {
								'Accept': 'application/json'
							},
							success: (res) => {
								console.log('[UPLOAD] 上传成功:', res)
								try {
									let data = typeof res.data === 'string' ? JSON.parse(res.data) : res.data
									console.log('[UPLOAD] 解析后的数据:', data)
									
									if (res.statusCode === 200 && data.success && data.url) {
										resolve(data)
									} else {
										reject(new Error(data.message || '文件上传失败'))
									}
								} catch (e) {
									console.error('[UPLOAD] 解析响应失败:', e)
									reject(new Error('服务器响应格式错误: ' + res.data))
								}
							},
							fail: (err) => {
								console.error('[UPLOAD] 上传失败:', err)
								reject(new Error(err.errMsg || '上传失败，请检查网络连接'))
							}
						})
					})
					
					if (result.success && result.url) {
						this.form[urlField] = result.url
						uni.showToast({
							title: `${type === 'front' ? '正面' : '背面'}照片上传成功`,
							icon: 'success',
							duration: 2000
						})
						return result.url
					} else {
						throw new Error(result.message || '文件上传失败')
					}
				} catch (error) {
					console.error('[UPLOAD] 上传异常:', error)
					uni.showToast({
						title: error.message || '上传失败，请重试',
						icon: 'none',
						duration: 3000
					})
					throw error
				} finally {
					this.uploading[uploadingField] = false
				}
			},
			
			validateForm() {
				if (!this.form.identifier) {
					uni.showToast({ title: '请输入学号/工号', icon: 'none' })
					return false
				}
				if (!this.form.password || this.form.password.length < 6 || this.form.password.length > 20) {
					uni.showToast({ title: '密码长度需在6-20位之间', icon: 'none' })
					return false
				}
				if (!this.form.fullName) {
					uni.showToast({ title: '请输入姓名', icon: 'none' })
					return false
				}
				if (!this.form.phoneNumber || !/^1[3-9]\d{9}$/.test(this.form.phoneNumber)) {
					uni.showToast({ title: '请输入正确的手机号', icon: 'none' })
					return false
				}
				if (!this.form.idCardNumber || this.form.idCardNumber.length < 15) {
					uni.showToast({ title: '请输入正确的身份证号', icon: 'none' })
					return false
				}
				// 检查是否已选择并上传成功（必须有服务器返回的URL）
				if (!this.form.idCardFrontUrl || !this.form.idCardFrontUrl.startsWith('/api/')) {
					uni.showToast({ title: '请上传身份证正面照片', icon: 'none' })
					return false
				}
				if (!this.form.idCardBackUrl || !this.form.idCardBackUrl.startsWith('/api/')) {
					uni.showToast({ title: '请上传身份证背面照片', icon: 'none' })
					return false
				}
				return true
			},
			
			async submitRegister() {
				if (!this.validateForm()) {
					return
				}
				
				this.submitting = true
				uni.showLoading({ title: '注册中...', mask: true })
				
				try {
					// 确保两张照片都已上传
					if (!this.form.idCardFrontUrl || !this.form.idCardBackUrl) {
						uni.showToast({ title: '请上传身份证正反面照片', icon: 'none' })
						return
					}
					
					// 提交注册信息（照片URL已在选择时上传）
					const res = await post('/api/auth/patient/register', {
						identifier: this.form.identifier,
						password: this.form.password,
						fullName: this.form.fullName,
						phoneNumber: this.form.phoneNumber,
						idCardNumber: this.form.idCardNumber,
						patientType: this.form.patientType,
						idCardFrontUrl: this.form.idCardFrontUrl,
						idCardBackUrl: this.form.idCardBackUrl
					})
					
					uni.hideLoading()
					
					if (res.code === '200' || res.status === 'pending') {
						uni.showModal({
							title: '注册成功',
							content: '您的注册申请已提交，请等待管理员审核。审核通过后即可登录。',
							showCancel: false,
							success: () => {
								uni.navigateTo({
									url: '/pages/login/patient-login'
								})
							}
						})
					} else {
						uni.showToast({
							title: res.msg || res.message || '注册失败',
							icon: 'none',
							duration: 3000
						})
					}
				} catch (error) {
					uni.hideLoading()
					console.error('注册失败:', error)
					uni.showToast({
						title: error.message || '注册失败，请重试',
						icon: 'none',
						duration: 3000
					})
				} finally {
					this.submitting = false
				}
			},
			
			goToLogin() {
				uni.navigateTo({
					url: '/pages/login/patient-login'
				})
			}
		}
	}
</script>

<style scoped>
	.container {
		min-height: 100vh;
		background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
		padding: 40rpx 30rpx;
	}
	
	.header {
		display: flex;
		flex-direction: column;
		align-items: center;
		margin-bottom: 60rpx;
	}
	
	.logo {
		width: 120rpx;
		height: 120rpx;
		margin-bottom: 20rpx;
	}
	
	.app-title {
		color: #fff;
		font-size: 36rpx;
		font-weight: bold;
	}
	
	.form-container {
		background: #fff;
		border-radius: 20rpx;
		padding: 50rpx 40rpx;
		box-shadow: 0 10rpx 40rpx rgba(0, 0, 0, 0.1);
	}
	
	.title {
		font-size: 44rpx;
		font-weight: bold;
		color: #333;
		text-align: center;
		margin-bottom: 10rpx;
	}
	
	.subtitle {
		font-size: 26rpx;
		color: #999;
		text-align: center;
		margin-bottom: 40rpx;
	}
	
	.form-section {
		display: flex;
		flex-direction: column;
	}
	
	.input-group {
		margin-bottom: 30rpx;
	}
	
	.input-label {
		display: block;
		font-size: 28rpx;
		color: #333;
		margin-bottom: 10rpx;
	}
	
	.required {
		color: #ff4444;
	}
	
	.input-hint {
		font-size: 24rpx;
		color: #999;
		margin-bottom: 10rpx;
	}
	
	.input-field {
		width: 100%;
		height: 80rpx;
		padding: 0 20rpx;
		border: 2rpx solid #e0e0e0;
		border-radius: 10rpx;
		font-size: 28rpx;
		box-sizing: border-box;
	}
	
	.picker-view {
		width: 100%;
		height: 80rpx;
		line-height: 80rpx;
		padding: 0 20rpx;
		border: 2rpx solid #e0e0e0;
		border-radius: 10rpx;
		font-size: 28rpx;
		background: #fff;
	}
	
	.upload-section {
		display: flex;
		flex-direction: column;
		gap: 20rpx;
	}
	
	.upload-btn {
		width: 200rpx;
		height: 60rpx;
		line-height: 60rpx;
		background: #667eea;
		color: #fff;
		border: none;
		border-radius: 10rpx;
		font-size: 26rpx;
	}
	
	.preview-image {
		width: 100%;
		max-height: 400rpx;
		border-radius: 10rpx;
		border: 2rpx solid #e0e0e0;
	}
	
	.submit-btn {
		width: 100%;
		height: 88rpx;
		line-height: 88rpx;
		background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
		color: #fff;
		border: none;
		border-radius: 10rpx;
		font-size: 32rpx;
		font-weight: bold;
		margin-top: 20rpx;
	}
	
	.submit-btn:disabled {
		opacity: 0.6;
	}
	
	.footer-text {
		text-align: center;
		margin-top: 30rpx;
		color: #667eea;
		font-size: 26rpx;
	}
</style>

