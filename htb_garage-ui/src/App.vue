<script setup lang="ts">
import type { MessageHandlers, NuiMessageData } from '@/types/nuiMessageTypes';
import initialiseDummyData from '@/dummyData';
import { useRoute, useRouter } from 'vue-router';
import { onMounted, onUnmounted, watch, provide, ref } from 'vue';
import { useAppStore } from '@/stores/app.store';
import { useLayoutStore } from '@/stores/layout.store';

import { useGarageStore } from '@/stores/garage.store';
import { useImpoundStore } from '@/stores/impound.store';

const router = useRouter();
const route = useRoute();

const appStore = useAppStore();
const layoutStore = useLayoutStore();

const garageStore = useGarageStore();
const impoundStore = useImpoundStore();

// Map all the NUI messages to handler functions
const handlers: MessageHandlers = {
  toggleVisibility: (msg) => (appStore.isVisible = msg.isVisible),

  enableGarage: (msg) => garageStore.initStore(msg),
  initVehicleStats: (msg) => garageStore.initVehicleStats(msg),
  setVehicles: (msg) => garageStore.setVehicles(msg),
  setNearbyPlayersList: (msg) => garageStore.setNearbyPlayersList(msg),
  transferComplete: (msg) => garageStore.transferComplete(msg),

  enableImpound: (msg) => impoundStore.initStore(msg),
  setupImpoundStoreVehicle: (msg) => impoundStore.setupImpoundStoreVehicle(msg),
  setupImpoundRetrieveVehicle: (msg) => impoundStore.setImpoundRetrieveVehicle(msg),
};

function onNuiMessage(e: MessageEvent) {
  const msg = e.data as NuiMessageData;

  // Navigate to the page's route
  if ('route' in msg && msg.route) {
    router.push(msg.route);
  }
  if ('isVisible' in msg) {
    appStore.isVisible = msg.isVisible;
  }

  // Invoke the incoming message event's target function
  if (msg.type) {
    const fn = handlers[msg.type];
    if (fn) {
      fn(msg as any);
    }
  }
}

onMounted(async () => {
  await router.isReady();

  window.addEventListener('keydown', onEscKey);
  window.addEventListener('message', onNuiMessage);
  document.addEventListener('mousedown', onClickOutside);

  // Determine if the display loads dummy data for development purposes
  const isNui = window.location.host.startsWith('cfx-nui-');
  if (!isNui) {
    initialiseDummyData(handlers, route.path);
  }
});

onUnmounted(() => {
  unwatch();
  window.removeEventListener('keydown', onEscKey);
  window.removeEventListener('message', onNuiMessage);
  document.removeEventListener('mousedown', onClickOutside);
});

const unwatch = watch(
  () => appStore.isVisible,
  (newValue) => {
    document.body.style.display = newValue ? 'block' : 'none';
  },
  {
    immediate: true,
  },
);

const onEscKey = (event: KeyboardEvent) => {
  if (event.key === 'Escape') {
    close();
  }
};

const close = async () => {
  await fetch('https://htb_garage/close');
};

provide('closeApp', close);

const appContainer = ref<HTMLElement | null>(null);
function onClickOutside(event: MouseEvent) {
  // if click happened outside of `container`
  if (appContainer.value && !appContainer.value.contains(event.target as Node)) {
    close();
  }
}
</script>

<template>
  <div id="outer-panel" ref="appContainer">
    <div class="panel-header">
      <component :is="layoutStore.headerContent" v-if="layoutStore.headerContent" />
      <button class="close-button" @click="close">×</button>
    </div>

    <div class="panel-content">
      <router-view />
    </div>

    <div class="panel-footer"></div>
  </div>
  Footer
</template>

<style scoped>
#outer-panel {
  /* panel background, border, rounded corners, and shadow */
  background: rgba(25, 25, 25, 0.75);
  border: 1px solid #444;
  border-radius: 12px;
  box-shadow:
    inset 0 1px 1px rgba(255, 255, 255, 0.1),
    0 4px 10px rgba(0, 0, 0, 0.6);

  /* 2 rows: auto header height, flexible content */
  display: grid;
  grid-template-rows: auto 1fr;

  /* size constraints */
  width: 40%;
  max-width: 80%;
  max-height: 80vh;
  overflow: hidden;

  position: fixed; /* or absolute */
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
}

/* HEADER */
.panel-header {
  background: rgba(0, 0, 0, 1);
  padding: 20px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  border-top-left-radius: 12px;
  border-top-right-radius: 12px;
}

/* FOOTER */
.panel-footer {
  background: rgba(0, 0, 0, 1);
  padding: 20px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  border-bottom-left-radius: 12px;
  border-bottom-right-radius: 12px;
}

/* CLOSE BUTTON */
.close-button {
  background: #2c2c2c;
  color: white;
  border: none;
  border-radius: 6px;
  width: 36px;
  height: 36px;
  font-size: 1.2rem;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
}

/* CONTENT AREA */

.panel-content {
  padding: 20px;
  overflow-y: auto;
}

/* Firefox */
.panel-content {
  /* thin track + red thumb */
  scrollbar-width: thin;
  scrollbar-color: rgba(150, 67, 67, 0.8) rgba(0, 0, 0, 0.1);
}

/* WebKit browsers */
.panel-content::-webkit-scrollbar {
  width: 8px;
}

.panel-content::-webkit-scrollbar-track {
  background: rgba(0, 0, 0, 0.1);
  border-radius: 4px;
}

.panel-content::-webkit-scrollbar-thumb {
  background-color: rgba(150, 67, 67, 0.8);
  border-radius: 4px;
  border: 2px solid rgba(0, 0, 0, 0.25);
}

.panel-content::-webkit-scrollbar-thumb:hover {
  background-color: rgba(150, 67, 67, 1);
}
</style>
