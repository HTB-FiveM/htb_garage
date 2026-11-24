import { fileURLToPath, URL } from 'node:url';
import { resolve } from 'path';
import { viteSingleFile } from 'vite-plugin-singlefile';

import { defineConfig } from 'vite';
import vue from '@vitejs/plugin-vue';
import vueJsx from '@vitejs/plugin-vue-jsx';
import vueDevTools from 'vite-plugin-vue-devtools';
import VueI18n from '@intlify/unplugin-vue-i18n/vite';

// https://vite.dev/config/
export default defineConfig({
  plugins: [
    vue(),
    vueJsx(),
    vueDevTools(),
    VueI18n({
      include: resolve(__dirname, './src/locales/**'),
    }),
    viteSingleFile(),
  ],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url)),
    },
  },
  build: {
    outDir: '../UI', // Set your desired output directory here
    emptyOutDir: true,
  },
  server: {
    host: '0.0.0.0',
    port: 5175,
    cors: true,
  },
});
