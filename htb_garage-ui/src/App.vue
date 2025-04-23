<script lang="ts" setup>
import { onMounted, onUnmounted, watch, ref, provide } from 'vue';
import { RouterView, useRoute, useRouter } from 'vue-router';
import { useAppStore } from './stores/app.store';
import { useGarageStore } from '@/stores/garage.store';
import { useImpoundStore } from '@/stores/impound.store';
import type { MessageHandlers, NuiMessageData } from '@/types/nuiMessageTypes';
import initialiseDummyData from './dummyData';

const router = useRouter();
const route = useRoute();

const appStore = useAppStore();
const garageStore = useGarageStore();
const impoundStore = useImpoundStore();

// Map all the NUI messages to handler functions
const handlers: MessageHandlers = {
  toggleVisibility: (msg) => appStore.isVisible = msg.isVisible,

  enableGarage: (msg) => garageStore.initStore(msg),
  initVehicleStats: (msg) => garageStore.initVehicleStats(msg),
  setVehicles: (msg) => garageStore.setVehicles(msg),
  setNearbyPlayersList: (msg) => garageStore.setNearbyPlayersList(msg),
  transferComplete: (msg) => garageStore.transferComplete(msg),

  enableImpoundStore: (msg) => impoundStore.initStore(msg),
  setImpoundStoreVehicle: (msg) => impoundStore.setImpoundStoreVehicle(msg),
  setImpoundRetrieveVehicle: (msg) => impoundStore.setImpoundRetrieveVehicle(msg)

};

function onNuiMessage(e: MessageEvent) {
  const msg = e.data as NuiMessageData

  // Navigate to the page's route
  if ('route' in msg && msg.route) {
    console.log(msg.route);
    router.push(msg.route)
  }
  if ('isVisible' in msg) {
    console.log('New: ', msg.isVisible);
    appStore.isVisible = msg.isVisible;
  }

  // Invoke the incoming message event's target function
  if(msg.type) {
    console.log('Handling NuiMessageData');
    const fn = handlers[msg.type];
    if(fn) {
      fn(msg as any);
    }
  }

}

onMounted(async () => {
  await router.isReady();
  console.log(route.path);
  window.addEventListener('keydown', onEscKey);
  window.addEventListener('message', onNuiMessage);
  document.addEventListener('mousedown', onClickOutside)
  console.log('Main isVisible: ', appStore.isVisible);

  // Determine if the display loads dummy data for development purposes
  const isNui = window.location.host.startsWith('cfx-nui-');
  console.log('isNui', isNui);
  if(!isNui) {
    console.log(route.path);
    initialiseDummyData(handlers, route.path);
  }
})

onUnmounted(() => {
  unwatch();
  window.removeEventListener('keydown', onEscKey);
  window.removeEventListener('message', onNuiMessage);
  document.removeEventListener('mousedown', onClickOutside);
});

const unwatch = watch(() => appStore.isVisible,
    (newValue) => {
      console.log('newValue:', newValue);
      document.body.style.display = newValue ? "block" : "none";
    },
    {
      immediate: true,
    }
);

const onEscKey = (event: KeyboardEvent) => {
  if (event.key === 'Escape') {
    close();
  }
};

const close = async () => {
  await fetch("https://htb_garage/close");  
};

provide('closeApp', close);

const appContainer = ref<HTMLElement|null>(null);
function onClickOutside(event: MouseEvent) {
  // if click happened outside of `container`
  if (appContainer.value && !appContainer.value.contains(event.target as Node)) {
    close()
  }
}

</script>

<template>
  <section ref="appContainer" class="page-content">
    <router-view />
  </section>
</template>

<style scoped>
.page-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  min-height: 0;
}
</style>
