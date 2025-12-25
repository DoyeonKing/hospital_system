import { fileURLToPath, URL } from 'node:url'

import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import vueDevTools from 'vite-plugin-vue-devtools'

import AutoImport from 'unplugin-auto-import/vite'
import Components from 'unplugin-vue-components/vite'
import { ElementPlusResolver } from 'unplugin-vue-components/resolvers'
import ElementPlus from 'unplugin-element-plus/vite'

// https://vite.dev/config/
export default defineConfig({
  base: '/doctor/',

  plugins: [
    vue(),
    vueDevTools(),
      // 按需定制主题配置
    ElementPlus({
      useSource: true,
    }),
    AutoImport({
      resolvers: [ElementPlusResolver({ importStyle: 'sass' })],
    }),
    Components({
      resolvers: [ElementPlusResolver({ importStyle: 'sass' })],
    }),
  ],

  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url))
    },
  },

  server: {
    proxy: {
      '/api': {
        target: 'http://localhost:8080',
        changeOrigin: true
        // 注意：不要去掉 /api 前缀，因为后端接口都是以 /api 开头的
        // rewrite: (path) => path.replace(/^\/api/, '')  // ❌ 这个配置会导致路径错误
      }
    }
  },

  css: {
  preprocessorOptions: {
    scss: {
      //自动导入定制化样式文件进行样式覆盖
      additionalData: `
       @use "@/assets/index.scss" as *;
      `,
      quietDeps: true, // 静默依赖中的警告
    }
  }
},
})
