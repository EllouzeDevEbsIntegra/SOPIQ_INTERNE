import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  server: {
    port: 5173,
    host: true,
    proxy: { '/api': { target: process.env.POSCAISSE_API || 'http://localhost:8080', changeOrigin: true } }
  },
  build: { outDir: 'dist', sourcemap: false, chunkSizeWarningLimit: 900 }
})
