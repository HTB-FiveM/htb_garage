import { createRouter, createWebHistory, type RouteRecordRaw } from 'vue-router';

const routes: RouteRecordRaw[] = [
  {
      path: '/vehicleMenu',
      name: 'vehicleMenu',
      component: () => import('@/views/VehicleMenu.vue'),
  },
  {
    path: '/impound',
    name: 'impound',
    component: () => import('@/views/Impound.vue'),
  },
  {
    path: '/retrieve',
    name: 'retrieve',
    component: () => import('@/views/Impound.vue'),
  },

];

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes,
});

export default router;
