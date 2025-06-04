import { createApp } from 'vue';
import { createPinia } from 'pinia';
import './style.css';
import App from './App.vue';
import router from './router';
import vSelect from 'vue-select';
import "vue-select/dist/vue-select.css";
import { setupI18n } from './i18n'
import { config }  from '@/config';
import messages from '@/locales/fr.json';

const pinia = createPinia();
const i18n = setupI18n({
  legacy: false,
  globalInjection: true,
  locale: config.locale,
  fallbackLocale: config.fallbackLocale,
  messages: { fr: messages }
});

createApp(App)
  .use(pinia)
  .use(router)
  .use(i18n)
  .component("v-select", vSelect)
  .provide('appConfig', config)
  .mount('#app');

