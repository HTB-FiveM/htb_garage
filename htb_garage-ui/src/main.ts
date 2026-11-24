// Global classes the existing screens use (btn, form-control, badge, ...), then the new panel styles
import '@/style.css';
import '@/style.scss';

import { createApp } from 'vue';
import { createPinia } from 'pinia';
import vSelect from 'vue-select';
import 'vue-select/dist/vue-select.css';

import App from '@/App.vue';
import router from '@/router';
import { setupI18n } from '@/i18n';
import { config } from '@/config';
import messages from '@/locales/fr.json';
import { resourcePlugin } from '@/plugins/resourceName.plugin';

const app = createApp(App);

// Every store gets $resourceName, the FiveM resource this UI belongs to
const pinia = createPinia();
pinia.use(resourcePlugin);

const i18n = setupI18n({
  legacy: false,
  globalInjection: true,
  locale: config.locale,
  fallbackLocale: config.fallbackLocale,
  messages: { fr: messages },
});

app.use(pinia);
app.use(router);
app.use(i18n);
app.component('v-select', vSelect);
app.provide('appConfig', config);

app.mount('#app');
