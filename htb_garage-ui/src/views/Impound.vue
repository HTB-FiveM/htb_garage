<script lang="ts" setup>
import ImpoundStore from "@/components/ImpoundStoreVehicle.vue";
import ImpoundRetrieve from "@/components/ImpoundRetrieveVehicle.vue";
import ImpoundRelease from "@/components/ImpoundReleaseVehicle.vue";
import Button from "@/components/Button.vue";
import Label from "@/components/Label.vue";
import { useImpoundStore } from "@/stores/impound.store";
import { inject } from "vue";

const store = useImpoundStore();

const closeApp = inject<() => void>("closeApp")!;
function onCloseClick() {
  closeApp();
}

const impoundVehicle = () => {
  store.impoundVehicle({
    ...store.storeVehicle!,
  });
};

</script>

<template>
    <div v-if="store.mode === 'store'" class="menu-header">
        <div>
        <strong
            >Impound a vehicle - {{ store.storeVehicle?.vehiclePlate }}</strong
        >
        </div>
    </div>

    <div v-if="store.mode === 'release'" class="menu-header">
        <div><strong>Release an impounded vehicle</strong></div>
    </div>

    <div id="app-border">
        <div class="the-form">
        <ImpoundStore v-if="store.mode === 'store'" />
        <ImpoundRetrieve v-if="store.mode === 'retrieve'" />
        <ImpoundRelease v-if="store.mode === 'release'" />
        </div>
    </div>

    <div class="action-bar">
        <div v-if="store.mode === 'retrieve'" class="summary">
        <Label
            >Total vehicles: {{ store.retrieveVehicle?.vehicles.length }}</Label
        >
        </div>
        <div v-if="store.mode === 'release'" class="summary">
        <Label>Vehicles impounded: {{ store.releaseVehicles.length }}</Label>
        </div>
        <div class="buttons">
        <Button
            v-if="store.mode === 'store'"
            variant="primary"
            @click="impoundVehicle"
            >Send to impound</Button
        >
        <Button variant="outline" @click="onCloseClick">Cancel</Button>
        </div>
    </div>
    <!-- <pre>{{ store.storeVehicle }}</pre> -->

</template>

<style>
/* #app {
    width: 50%;
} */
</style>

<style scoped>
#app-border {
  background-color: rgba(255, 255, 255, 0.04);
  border: 1px solid #3a3a3a;
  padding: 12px;
  border-radius: 7px;
}

.menu-header {
  margin-bottom: 5px;
  padding-bottom: 8px;
  border-bottom: 1px solid #3a3a3a;
  color: #f0f0f0;
  font-size: 1.1rem;
}

.menu-header,
.top-row {
  margin-bottom: 10px;
}

.top-row {
  display: flex;
  flex-wrap: nowrap;
  justify-content: space-between;
}

.the-form {
  border-radius: 5px;
  margin-top: 1px;
  margin-bottom: 1px;
  color: ghostwhite;
}
</style>

<style>
.summarise {
  color: #a8a8a8;
}

.summary {
  margin-left: 0.5rem;
  color: #ddd;
}

.action-bar {
  display: flex;
  align-items: center;
  margin-right: 1rem;
  /* no justify-content here so items sit next to each other */
}

.buttons {
  margin-top: 1rem;
  margin-bottom: 1rem;
  margin-left: auto; /* pushes this block to the right */
  display: flex;
  gap: 1rem;
}
</style>
