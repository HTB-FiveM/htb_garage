<script lang="ts" setup>
import { ref, computed, inject } from "vue";
import VehicleItem from "@/components/VehicleItem.vue";
import { useGarageStore } from "@/stores/garage.store";

const store = useGarageStore();

const closeApp = inject<() => void>("closeApp")!;
function onCloseClick() {
  closeApp();
}

const searchBox = ref<HTMLInputElement | null>(null);
// const focusOnSearchBox = () => {
//   if(searchBox.value) {
//     searchBox.value.focus();
//   }
// };

const searchTerm = ref("");

const filteredVehicles = computed(() => {
  return store.filteredVehicles(searchTerm.value);
});
</script>

<template>
  <div id="app-border">
    <div class="menu-header">
      <div class="top-row">
        <div>
          <span id="vehicle-count-title">Total vehicles: </span>
          <span id="vehicle-count">{{ store.vehicles.length }}</span>
        </div>
        <button class="noselect btn btn-danger btn-sm" @click="onCloseClick">
          CLOSE
        </button>
      </div>

      <input
        type="text"
        ref="searchBox"
        class="form-control"
        placeholder="Search vehicle by plate or name"
        v-model="searchTerm"
      />
    </div>

    <div class="car-list">
      <li v-for="vehicle in filteredVehicles" class="garage-list-item">
        <VehicleItem :veh="vehicle"></VehicleItem>
      </li>
    </div>
  </div>
</template>

<style scoped>
#app-border {
  display: flex; /* make this a flex container */
  flex-direction: column; /* stack header + list vertically */
  flex: 1; /* fill all of its parent’s height */
  min-height: 0; /* allow children to shrink below content */
  background-color: rgba(255, 255, 255, 0.04);
  border: 1px solid #3a3a3a;
  padding: 12px;
  border-radius: 7px;
}

.menu-header {
  margin-bottom: 5px;
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

#vehicle-count-title {
  font-weight: 800;
}

#vehicle-count {
  font-weight: 500;
}

.car-list {
  /* max-height: 80vh; */
  flex: 1;
  min-height: 0;
  overflow-y: auto;
}

.car-list::-webkit-scrollbar-track {
  border-radius: 4px;
  background-color: rgba(0, 0, 0, 0.2);
}

.car-list::-webkit-scrollbar {
  width: 8px;
  background-color: rgba(0, 0, 0, 0.2);
  border-radius: 4px;
}

.car-list::-webkit-scrollbar-thumb {
  border-radius: 4px;
  background-color: rgba(150, 67, 67, 0.8);
}

.garage-list-item {
  border-radius: 6px;
  margin-top: 1px;
  margin-bottom: 0.5rem;
  background-color: rgba(255, 255, 255, 0.05);
  color: ghostwhite;
}

.car-list {
  border-width: 5px;
}

ul,
.garage-list-item {
  list-style-type: none;
  position: relative;
  display: block;
  padding: 0.6rem 0.7rem;
  border: 1px solid #3a3a3a;
}

.carModel,
.carName,
.impoundItem,
.vehicleListItem {
  text-transform: capitalize;
}

.setVehicleName {
  margin-top: 10px;
  margin-left: 15px;
}

.setVehicleName .nameField {
  width: 100%;
  margin-top: 0.5rem;
  margin-bottom: 0.5rem;
}

.setVehicleName button {
  margin-right: 10px;
}

.transferOwnership {
  margin-left: 15px;
}

.transferOwnership .dd {
  width: 100%;
}

.transferOwnership .buyer {
  width: 100%;
  margin-top: 0.5rem;
  margin-bottom: 0.5rem;
}

.transferOwnership .buyer .button {
  width: 100%;
}

.transferOwnership .dropdown-item,
.dropdown-menu {
  width: 100%;
}

.transferOwnership button {
  margin-right: 10px;
}
</style>
