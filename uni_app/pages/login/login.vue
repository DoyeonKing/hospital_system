<template>
	<view class="container">
		<view class="form-container">
			<text class="title">{{ isActivation ? '账号激活' : '欢迎登录' }}</text>

			<view v-if="!isActivation">
				<input class="input-field" v-model="loginForm.identifier" placeholder="请输入学号/工号" />
				<input class="input-field" v-model="loginForm.password" type="password" placeholder="请输入密码" />
				<button class="submit-btn" @click="handleLogin">登 录</button>
				<view class="footer-text" @click="switchToActivation">
					<text>首次使用？点击激活</text>
				</view>
			</view>

			<view v-else>
				<view v-if="activationStep === 1">
					<input class="input-field" v-model="activationForm.identifier" placeholder="请输入学号/工号" />
					<input class="input-field" v-model="activationForm.initialPassword" type="password" placeholder="请输入初始密码" />
					<button class="submit-btn" @click="handleActivationStep1">下一步</button>
				</view>

				<view v-if="activationStep === 2">
					<view class="verification-section">
						<text class="verification-title">身份信息核验</text>
						<text class="verification-desc">为保障您的账户安全，需要核验您的身份信息。</text>
						<input class="input-field" v-model="activationForm.idCard" placeholder="请输入身份证号" />
						<input class="input-field" v-model="activationForm.phone" placeholder="请输入手机号" />
						<button class="submit-btn" @click="handleVerification">开始核验</button>
					</view>
				</view>

				<view v-if="activationStep === 3">
					<input class="input-field" v-model="activationForm.newPassword" type="password" placeholder="请输入新密码" />
					<input class="input-field" v-model="activationForm.confirmPassword" type="password" placeholder="请确认新密码" />
					<button class="submit-btn" @click="completeActivation">完成激活</button>
				</view>

				<view class="footer-text" @click="switchToLogin">
					<text>返回登录</text>
				</view>
			</view>
		</view>
	</view>
</template>

<script>
	export default {
		data() {
			return {
				isActivation: false,
				activationStep: 1, // 1: initial info, 2: verification, 3: set password
				loginForm: {
					identifier: '',
					password: ''
				},
				activationForm: {
					identifier: '',
					initialPassword: '',
					idCard: '',
					phone: '',
					newPassword: '',
					confirmPassword: ''
				}
			}
		},
		methods: {
			switchToActivation() {
				this.isActivation = true;
				this.activationStep = 1;
			},
			switchToLogin() {
				this.isActivation = false;
			},
			handleLogin() {
				if (!this.loginForm.identifier || !this.loginForm.password) {
					uni.showToast({ title: '请输入学号/工号和密码', icon: 'none' });
					return;
				}
				// TODO: Replace with actual API call for login
				console.log('Login attempt with:', this.loginForm);
				uni.showLoading({ title: '登录中...' });
				setTimeout(() => {
					uni.hideLoading();
					uni.showToast({ title: '登录成功（模拟）', icon: 'success' });
					// uni.navigateTo({ url: '/pages/index/index' });
				}, 1000);
			},
			handleActivationStep1() {
				if (!this.activationForm.identifier || !this.activationForm.initialPassword) {
					uni.showToast({ title: '请输入学号/工号和初始密码', icon: 'none' });
					return;
				}
				// TODO: API call to verify identifier and initial password
				console.log('Activation Step 1:', this.activationForm);
				uni.showLoading({ title: '请稍候...' });
				setTimeout(() => {
					uni.hideLoading();
					this.activationStep = 2; // Move to next step
				}, 500);
			},
			handleVerification() {
				if (!this.activationForm.idCard || !this.activationForm.phone) {
					uni.showToast({ title: '请输入身份证和手机号', icon: 'none' });
					return;
				}
				// TODO: API call to verify ID card and phone against database
				console.log('Verification Step 2:', this.activationForm);
				uni.showLoading({ title: '核验中...' });
				setTimeout(() => {
					uni.hideLoading();
					uni.showToast({ title: '核验成功', icon: 'success' });
					this.activationStep = 3; // Move to final step
				}, 1000);
			},
			completeActivation() {
				if (!this.activationForm.newPassword || !this.activationForm.confirmPassword) {
					uni.showToast({ title: '请输入新密码', icon: 'none' });
					return;
				}
				if (this.activationForm.newPassword !== this.activationForm.confirmPassword) {
					uni.showToast({ title: '两次输入的密码不一致', icon: 'none' });
					return;
				}
				// TODO: API call to update password and activate account
				console.log('Activation Complete Step 3:', this.activationForm);
				uni.showLoading({ title: '激活中...' });
				setTimeout(() => {
					uni.hideLoading();
					uni.showToast({ title: '激活成功！请使用新密码登录。', icon: 'success' });
					this.isActivation = false; // Switch back to login
				}, 1000);
			}
		}
	}
</script>

<style>
	.container {
		display: flex;
		justify-content: center;
		align-items: center;
		height: 100vh;
		background-color: #f0f2f5;
	}
	.form-container {
		width: 85%;
		padding: 40rpx;
		background-color: #ffffff;
		border-radius: 16rpx;
		box-shadow: 0 4rpx 12rpx rgba(0,0,0,0.1);
	}
	.title {
		display: block;
		font-size: 48rpx;
		font-weight: bold;
		text-align: center;
		margin-bottom: 60rpx;
	}
	.input-field {
		height: 88rpx;
		padding: 0 30rpx;
		border-radius: 8rpx;
		background-color: #f7f7f7;
		margin-bottom: 30rpx;
		font-size: 28rpx;
	}
	.submit-btn {
		background-color: #007aff;
		color: white;
		border-radius: 8rpx;
		height: 96rpx;
		line-height: 96rpx;
		font-size: 32rpx;
		margin-top: 20rpx;
	}
	.footer-text {
		text-align: center;
		margin-top: 40rpx;
		color: #007aff;
		font-size: 28rpx;
	}
	.verification-section {
		text-align: center;
	}
	.verification-title {
		font-size: 36rpx;
		font-weight: bold;
		margin-bottom: 20rpx;
	}
	.verification-desc {
		display: block;
		font-size: 26rpx;
		color: #888;
		margin-bottom: 40rpx;
	}
</style>