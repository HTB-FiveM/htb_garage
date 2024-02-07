import { createApp } from 'vue';
import { createPinia } from 'pinia';
import './style.css';
import App from './App.vue';
//import { useGarageStore } from './stores/garage.store';

const pinia = createPinia();

createApp(App).use(pinia).mount('#app');

// document.onreadystatechange = () => {
//   console.log(document.readyState);
//   if (document.readyState === "complete") {
//     const garageStore = useGarageStore();

//     // Check if running outside of FiveM
//     // This allows us to develop the UI outside of FiveM by mocking the incoming state on launch
//     console.log(window.location.protocol);
//     if (window.location.protocol.startsWith('http')) {
//       garageStore.initStore({
//         type: 'enable',
//         isVisible: true,
//         showFuel: true,
//         showEngine: true,
//         showBody: true,
//       });

//     } else {
//       window.addEventListener('message', (event) => {
//         garageStore.initStore(event.data);
//       });
//     }
//   }
// };
