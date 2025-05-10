<script lang="ts" setup>
import { useImpoundStore } from "@/stores/impound.store";
import { ImpoundVehicle } from "@/types/impoundTypes";
import { computed, inject, ref } from "vue";

import ImpoundVehiceItem from "@/components/ImpoundVehicleItem.vue";
import TextInput from "@/components/TextInput.vue";
import Button from "@/components/Button.vue";
import Alert from "@/components/Alert.vue";

const store = useImpoundStore();

const searchTerm = ref("");
const filteredVehicles = computed<ImpoundVehicle[]>(() => {
  return store.filteredVehicles(searchTerm.value) as ImpoundVehicle[];
});

const expandedPlate = ref<string | null>(null);

function toggleExpand(veh: ImpoundVehicle) {
  expandedPlate.value = expandedPlate.value === veh.plate ? null : veh.plate;
}

const closeApp = inject<() => void>("closeApp")!;
function onCloseClick() {
  closeApp();
}

const spawnVehicle = async (vehicle: ImpoundVehicle) => {
  await store.impoundRetrieve(vehicle);
  onCloseClick();
};

const returnToOwner = async (vehicle: ImpoundVehicle) => {
  await store.returnToOwner(vehicle);
  onCloseClick();
};
</script>

<template>
  <div>
    <TextInput
      type="text"
      ref="searchBox"
      class="form-control"
      placeholder="Search the vehicles by plate or name"
      v-model="searchTerm"
    />
  </div>
  <div class="car-list">
    <Alert
      v-if="store.retrieveVehicle!.vehicles.length > 0
      && (searchTerm ?? '').trim() !== ''
      && filteredVehicles?.length === 0"
      variant="warning"
      style="display: flex; margin: 0.5rem"
      >No vehicles matching criteria</Alert
    >
    <ul v-else>
      <li
        v-for="vehicle in filteredVehicles"
        :key="vehicle.plate"
        class="impound-list-item"
      >
        <!-- wrap the click on whichever part of the item should toggle it -->
        <div @click="toggleExpand(vehicle)">
          <ImpoundVehiceItem :veh="vehicle" />
        </div>

        <!-- only render the details‐panel if this one is “active” -->
        <div v-if="expandedPlate === vehicle.plate" class="details-panel">
          <div class="action-buttons">
            <div class="item-buttons">
              <div v-if="vehicle.canRetrieveHere && vehicle.allowPersonalUnimpound">
                <Button v-if="vehicle.expired" @click="spawnVehicle(vehicle)"
                    >Pay for retrieve</Button
                >
                <Alert v-else>Your vehicle will be available for release in {{ vehicle.timeLeft }}</Alert>
              </div>
              <template v-else>
                <Alert v-if="vehicle.allowPersonalUnimpound">Your vehicle is not held here. Please visit {{ vehicle.impoundName }} to retrieve.</Alert>
                <Alert v-else>Personal unimpounding has been denied on this vehicle. Please visit authorities to discuss.</Alert>
              </template>

              <Button
                v-if="vehicle.allowReturn"
                variant="secondary"
                @click="returnToOwner(vehicle)"
              >
                Return to owner
              </Button>
            </div>
          </div>
        </div>
      </li>
    </ul>
  </div>
</template>

<style scoped>
ul {
  padding: 0.5rem 0.3rem 0 0.3rem;
}

.impound-list-item {
  list-style-type: none;
  position: relative;
  display: block;
  padding: 0.2rem 0.2rem 0.2rem 0.2rem;
  margin-bottom: 1rem;
  /* border: 1px solid rgba(0, 0, 0, 0.125); */
  border-bottom: 1px sold rgba(0, 0, 0, 0.125);
}

.car-list {
  margin-top: 0.5rem;
  border-radius: 5px;
  /* border-style: solid;
    border-color: #a0a0a0; */
}

.impound-list-item {
  /* box-shadow: horizontal-offset vertical-offset blur-radius spread-radius color */
  box-shadow: 0 0 5px 2px rgba(0, 0, 0, 0.1);

  border-radius: 4px;
  padding: 1rem;
}

.item-buttons {
  display: flex; /* turn on flex layout */
  justify-content: center; /* center along the main axis (horizontally) */
  align-items: center; /* center along the cross axis (vertically) */
  gap: 1rem; /* optional spacing between buttons */
  /* if you want the wrapper to fill some height: */
}

.details-panel {
    margin: 1rem 0;
}

.not-here {
    background-color: darksalmon;
}
</style>
