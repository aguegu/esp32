import { defineConfig } from 'vite';
import vue from '@vitejs/plugin-vue';
import viteCompression from 'vite-plugin-compression';


// https://vitejs.dev/config/
export default defineConfig({
  plugins: [vue(), viteCompression({
    deleteOriginFile: true,
    threshold: 0,
    filter: /\.(js|mjs|json|css|html|ico)$/i
  })],
  server: {
    proxy: {
      '/api': 'http://192.168.1.102',
    }
  },
  build: {
    assetsDir: '',
  },
});
