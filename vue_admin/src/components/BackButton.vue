<template>
  <div class="back-button" @click="goBack" role="button" aria-label="返回上一级" tabindex="0" @keydown.enter="goBack" @keydown.space.prevent="goBack">
    <img :src="icon" alt="返回" class="back-icon" />
    <span class="back-text">返回</span>
  </div>
</template>

<script setup>
import { useRouter } from 'vue-router'
import icon from '@/assets/dog1.jpg'

const router = useRouter()

function goBack() {
  if (window.history.length > 1) {
    router.back()
  } else {
    router.push('/')
  }
}
</script>

<style scoped>
.back-button {
  display: inline-flex;
  align-items: center;
  cursor: pointer;
  user-select: none;
}
.back-icon {
  width: 32px;
  height: 32px;
  border-radius: 50%;
  object-fit: cover;
  box-shadow: 0 2px 8px rgba(0,0,0,0.15);
}
.back-text {
  margin-left: 8px;
  font-size: 14px;
  color: #303133;
}
</style>


