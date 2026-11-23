<script setup lang="ts">
import { ref } from "vue";
import { ImpoundVehicle } from "../types/impoundTypes";
import Label from "@/components/Label.vue";

import { useCurrency } from "@/composables/useCurrency";

defineProps<{ veh: ImpoundVehicle }>();

const showDetails = ref(false);

const modelName = (vehicle: ImpoundVehicle) => {
  if (!vehicle.modelName || vehicle.modelName === "null") {
    return vehicle.spawnName;
  }

  return vehicle.modelName;
};

const toggleDetailsPanel = () => {
  showDetails.value = !showDetails.value;
  if (!showDetails.value) {
  }
};

// Using the composable this way rather than directly in the template
// prevent the output value being wrapped in double quotes
const formatCurrency = (amount: number) => {
  return useCurrency(amount).value;
};
</script>

<template>
  <div class="vehicle-row" @click="toggleDetailsPanel">
    <div class="vehicle-details">
      <div class="vehicleListItem">
        <span
          ><strong>{{ modelName(veh) }}</strong>
          <small v-if="veh.import">, import</small> -
        </span>
        <span v-if="veh.plate" class="badge badge-light">{{ veh.plate }}</span>
        <span v-if="veh.displayName"> - {{ veh.displayName }}</span>
      </div>
      <div style="color: #466f52">{{ formatCurrency(veh.priceToRelease) }}</div>
    </div>
    <div class="impound-details">
      <div>{{ veh.impoundName }}</div>
      <div v-if="veh.timeLeft">{{ veh.timeLeft }} remaining</div>
      <div v-else><Label class="ready">Ready</Label></div>
    </div>
  </div>
  <div v-if="showDetails" class="details-body">
    <!-- :id="veh.htmlId">-->
    <slot />
  </div>
</template>

<style scoped>
.carModel,
.carName,
.impoundItem,
.vehicleListItem {
  text-transform: capitalize;
}

.details-body {
  -ms-flex: 1 1 auto;
  flex: 1 1 auto;
  min-height: 1px;
  padding: 0.5rem 0 0 0;
}

.details-panel {
  display: flex;
  /* gap: 10px; */
}

.details-panel button {
  margin-bottom: 5px !important; /* Force space between buttons */
  width: 100%;
}

.action-buttons,
.vehicle-attributes {
  display: flex;
  flex-direction: column;
  gap: 0.3em; /* Adds spacing between the vertically stacked items */
}

.action-buttons {
  flex: 1; /* Takes up 1/3 of the space */
  padding: 10px;
}

.vehicle-attributes {
  flex: 2; /* Takes up the remaining 2/3 of the space */
  padding: 10px;
}

VehicleAttribute {
  margin-bottom: 10px; /* Adds some space between the elements */
  /* Style your VehicleAttribute elements here */
}
.nick-buttons {
  margin-top: 0.5rem;
}

.transfer-ownership {
  margin-left: 15px;
}

.transfer-ownership .dd {
  width: 100%;
}

.transfer-ownership .buyer {
  width: 100%;
  margin-top: 0.5rem;
  margin-bottom: 0.5rem;
}

.transfer-ownership .buyer .button {
  width: 100%;
}

.transfer-ownership .dropdown-item,
.dropdown-menu {
  width: 100%;
}

.transfer-ownership button,
.setVehicleName button {
  margin-right: 10px;
}

.the-dropdown {
  --vs-border-color: #444;
  --vs-dropdown-bg: #696969;
  --vs-selected-color: #fff;
}

.no-players {
  border-radius: 5px;
  border-color: #444;
  border-width: 1px;
  background-color: orangered;
  padding: 0.5rem;
  font-size: 0.7rem;
  text-align: center;
  margin: 0.5rem 0.3rem 0 0.3rem;
}

.fade-enter-active {
  transition: opacity 0s;
}

.fade-leave-active {
  transition: opacity 1s;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

.fade-enter-to,
.fade-leave-from {
  opacity: 1;
}

.vehicle-row {
  display: flex;
  /* Option A: space them out evenly */
  justify-content: space-between;
  align-items: center;
  /* Option B: remove justify-content and instead push the second child
     .impound-details { margin-left: auto; } */
}

.impound-details {
  /* push to right if you didn’t use justify-content: space-between */
  /* margin-left: auto; */

  /* right-align its contents */
  text-align: right;

  /* optionally vertically center if its height differs */
  display: flex;
  flex-direction: column;
  justify-content: center;
}

/* if you want the .vehicle-details to take all the space up to the impound div */
.vehicle-details {
  /* flex: 1;   <-- only if you need it to grow/shrink */
}

.ready {
  background-color: #259D44;
  text-align: center;
  border-radius: 5px;
  margin: 4px 0 10px 0;
  padding: 10px 0;
}
</style>
