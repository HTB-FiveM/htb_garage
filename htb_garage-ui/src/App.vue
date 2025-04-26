<script setup lang="ts">
import type { MessageHandlers, NuiMessageData } from '@/types/nuiMessageTypes';
import initialiseDummyData from '@/dummyData';
import { useRoute, useRouter } from 'vue-router';
import { onMounted, onUnmounted, watch, provide, ref } from 'vue';
import { useAppStore } from '@/stores/app.store';
import { useGarageStore } from '@/stores/garage.store';
import { useImpoundStore } from '@/stores/impound.store';

import MetalPanel from '@/components/layout/MetalPanel.vue';

const router = useRouter();
const route = useRoute();

const appStore = useAppStore();
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

<!-- <template>
  <section ref="appContainer" class="page-content">
    <router-view />
  </section>
</template> -->

<template>
  <div id="app-root">
    <MetalPanel>
      <router-view />
    </MetalPanel>
  </div>
</template>

<style scoped>
#app-root {
  width: 100vw;
  height: 100vh;
  display: flex;
  justify-content: center;
  align-items: center;
}
</style>

<!-- <style scoped>
header {
  line-height: 1.5;
  max-height: 100vh;
}

.logo {
  display: block;
  margin: 0 auto 2rem;
}

nav {
  width: 100%;
  font-size: 12px;
  text-align: center;
  margin-top: 2rem;
}

nav a.router-link-exact-active {
  color: var(--color-text);
}

nav a.router-link-exact-active:hover {
  background-color: transparent;
}

nav a {
  display: inline-block;
  padding: 0 1rem;
  border-left: 1px solid var(--color-border);
}

nav a:first-of-type {
  border: 0;
}

@media (min-width: 1024px) {
  header {
    display: flex;
    place-items: center;
    padding-right: calc(var(--section-gap) / 2);
  }

  .logo {
    margin: 0 2rem 0 0;
  }

  header .wrapper {
    display: flex;
    place-items: flex-start;
    flex-wrap: wrap;
  }

  nav {
    text-align: left;
    margin-left: -1rem;
    font-size: 1rem;

    padding: 1rem 0;
    margin-top: 1rem;
  }
}
</style> -->
