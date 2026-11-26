<script lang="ts" setup>
import { useImpoundStore } from "@/stores/impound.store";
import type { ImpoundVehicle } from "@/types/impoundTypes";
import { computed, ref } from "vue";

import ImpoundVehiceItem from "@/components/ImpoundVehicleItem.vue";
import TextInput from "@/components/TextInput.vue";
import Button from "@/components/Button.vue";
import Alert from "@/components/Alert.vue";

const store = useImpoundStore();

// Starts empty; the list only shows vehicles matching what the operator types
const searchTerm = ref<string | null>("");
const hasSearch = computed(() => (searchTerm.value ?? "").trim() !== "");
const matches = computed<ImpoundVehicle[]>(() => store.releaseMatches(searchTerm.value));

const expandedPlate = ref<string | null>(null);
function toggleExpand(veh: ImpoundVehicle) {
  expandedPlate.value = expandedPlate.value === veh.plate ? null : veh.plate;
}

// Stops a double click releasing twice while the server works
const releasing = ref<string | null>(null);
const releaseVehicle = async (vehicle: ImpoundVehicle) => {
  releasing.value = vehicle.plate;
  try {
    await store.impoundRelease(vehicle);
  } finally {
    // The row disappears when the server confirms; allow a retry if it refused
    setTimeout(() => {
      if (releasing.value === vehicle.plate) releasing.value = null;
    }, 2500);
  }
};
</script>

<template>
  <div>
    <TextInput
      type="text"
      class="form-control"
      placeholder="Search by owner name, plate or vehicle type"
      v-model="searchTerm"
      autofocus
    />
  </div>
  <div class="car-list">
    <Alert
      v-if="hasSearch && matches.length === 0"
      variant="warning"
      style="display: flex; margin: 0.5rem"
      >No impounded vehicles match</Alert
    >
    <ul v-else-if="hasSearch">
      <li v-for="vehicle in matches" :key="vehicle.plate" class="impound-list-item">
        <div @click="toggleExpand(vehicle)">
          <ImpoundVehiceItem :veh="vehicle" />
        </div>

        <div v-if="expandedPlate === vehicle.plate" class="details-panel">
          <div class="details">
            <div><span class="summarise">Type:</span> {{ vehicle.type }}</div>
            <div v-if="vehicle.reasonForImpound">
              <span class="summarise">Reason:</span> {{ vehicle.reasonForImpound }}
            </div>
            <div>
              <span class="summarise">Owner collection:</span>
              {{ vehicle.allowPersonalUnimpound ? "allowed" : "not allowed" }}
            </div>
          </div>
          <div class="item-buttons">
            <Alert v-if="vehicle.ownedByOfficer" variant="warning"
              >This is your own vehicle. Another officer has to release it.</Alert
            >
            <Button
              v-else
              :disabled="releasing === vehicle.plate"
              @click="releaseVehicle(vehicle)"
              >Release Vehicle</Button
            >
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

.car-list {
  margin-top: 0.5rem;
  border-radius: 5px;
}

.impound-list-item {
  list-style-type: none;
  position: relative;
  display: block;
  margin-bottom: 1rem;
  background-color: rgba(255, 255, 255, 0.05);
  border: 1px solid #3a3a3a;
  border-radius: 6px;
  padding: 1rem;
}

.details-panel {
  margin: 1rem 0 0 0;
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.details {
  display: flex;
  flex-direction: column;
  gap: 0.3rem;
}

.item-buttons {
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 1rem;
}
</style>
