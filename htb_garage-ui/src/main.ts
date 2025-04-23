import { createApp } from 'vue';
import { createPinia } from 'pinia';
import './style.css';
import App from './App.vue';
import router from './router';
import vSelect from 'vue-select';
import "vue-select/dist/vue-select.css";

const pinia = createPinia();

createApp(App)
  .use(pinia)
  .use(router)
  .component("v-select", vSelect)
  .mount('#app');

