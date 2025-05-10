<script lang="ts" setup>
import { onMounted, onUnmounted, watch, computed, ref, provide } from "vue";
import { RouterView, useRoute, useRouter } from "vue-router";
import { useAppStore } from "./stores/app.store";
import { useGarageStore } from "@/stores/garage.store";
import { useImpoundStore } from "@/stores/impound.store";
import type { MessageHandlers, NuiMessageData } from "@/types/nuiMessageTypes";
import initialiseDummyData from "./dummyData";

const router = useRouter();
const route = useRoute();

const appStore = useAppStore();
const garageStore = useGarageStore();
const impoundStore = useImpoundStore();

const containerWidth = computed(() => {
  // route.meta.containerWidth is typed as unknown by default,
  // so we coerce it to a string
  return (route.meta.containerWidth as string) || '100%'
})

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
  setupImpoundRetrieveVehicle: (msg) =>
    impoundStore.setImpoundRetrieveVehicle(msg),
};

function onNuiMessage(e: MessageEvent) {
  const msg = e.data as NuiMessageData;

  // Navigate to the page's route
  if ("route" in msg && msg.route) {
    router.push(msg.route);
  }
  if ("isVisible" in msg) {
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

  window.addEventListener("keydown", onEscKey);
  window.addEventListener("message", onNuiMessage);
  document.addEventListener("mousedown", onClickOutside);

  // Determine if the display loads dummy data for development purposes
  const isNui = window.location.host.startsWith("cfx-nui-");
  if (!isNui) {
    initialiseDummyData(handlers, route.path);
  }
});

onUnmounted(() => {
  unwatch();
  window.removeEventListener("keydown", onEscKey);
  window.removeEventListener("message", onNuiMessage);
  document.removeEventListener("mousedown", onClickOutside);
});

const unwatch = watch(
  () => appStore.isVisible,
  (newValue) => {
    document.body.style.display = newValue ? "block" : "none";
  },
  {
    immediate: true,
  }
);

const onEscKey = (event: KeyboardEvent) => {
  if (event.key === "Escape") {
    close();
  }
};

const close = async () => {
  await fetch("https://htb_garage/close");
};

provide("closeApp", close);

const appContainer = ref<HTMLElement | null>(null);
function onClickOutside(event: MouseEvent) {
  // if click happened outside of `container`
  if (
    appContainer.value &&
    !appContainer.value.contains(event.target as Node)
  ) {
    close();
  }
}
</script>

<template>
  <section
    ref="appContainer"
    class="page-content"
    :style="{ width: containerWidth }">
    <router-view />
  </section>
</template>

<style scoped>
.page-content {
  /* all the old `#app` rules go here: */
  display: flex;
  position: absolute;
  top: 50.5%;
  left: 50.5%;
  transform: translate(-50%, -50.1%);
  max-width: 80%;
  max-height: 80vh;
  overflow-y: hidden;
  padding: 8px;
  background-color: gray;
  border-radius: 13px;

  /* plus your flex/grid for child alignment: */
  flex-direction: column;
  margin: auto;
  /* transition: width 0.3s ease; */
}

</style>
