// import '@/assets/main.css';
//import '@/style.css';
import '@/style.scss';

import { createApp } from 'vue';
import { createPinia } from 'pinia';

import App from '@/App.vue';
import router from '@/router';
import { resourcePlugin } from '@/plugins/resourceName.plugin';

const app = createApp(App);

const pinia = createPinia();
pinia.use(resourcePlugin);

app.use(pinia);
app.use(router);

app.mount('#app');
