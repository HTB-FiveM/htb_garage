<script setup lang="ts">
import { ref, watch, onMounted, onUnmounted, computed } from "vue";
import VehicleItem from "./components/VehicleItem.vue";
import { useGarageStore } from "./stores/garage.store";

const store = useGarageStore();


const searchBox = ref<HTMLInputElement | null>(null);
// const focusOnSearchBox = () => {
//   if(searchBox.value) {
//     searchBox.value.focus();
//   }
// };

onMounted(() => {
  //focusOnSearchBox();

  initialise();

  window.addEventListener('keydown', onEscKey);

  const unwatch = watch(
    () => store.isVisible,
    (newValue) => {
      document.body.style.display = newValue ? "block" : "none";
    },
    {
      immediate: true,
    }
  );

  onUnmounted(() => {
    unwatch();
    window.removeEventListener('keydown', onEscKey);
  });
});

const onEscKey = (event: KeyboardEvent) => {
  if (event.key === 'Escape') {
    store.close();
  }
};

const initialise = () => {
  if (window.location.host.startsWith("cfx-nui-")) {
    // Running in FiveM initialisation
    window.addEventListener("message", (event) => {
      store.initStore(event.data);
    });
    
  } else {
    // Development mode initialisation
    store.initStore({
      type: "enable",
      isVisible: true,
      showFuel: true,
      showEngine: true,
      showBody: true,
    });

    store.initStore({
      type: "setVehicles",
      vehicles: JSON.stringify([
        {
          type: "adder",
          plate: "abc123",
          displayName: "Bob",
          modelName: "adssadads",
          spawnName: "34534543",
          import: false,
          pound: false,
          stored: true,
          htmlId: "adsadad",
          fuel: 80,
          engine: 243,
          body: 675,
        },
        {
          type: "zentorno",
          plate: "def567",
          displayName: "Snoogans",
          modelName: "dsfgsdfg",
          spawnName: "657457",
          import: true,
          pound: false,
          stored: false,
          htmlId: "sdfg",
          fuel: 59,
          engine: 567,
          body: 567,
        },
      ]),
    });

  }
};

const close = async () => {
  await store.close();
};

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
        <button class="noselect btn btn-danger btn-sm" @click="close()">CLOSE</button>
      </div>

      <input
        type="text"
        ref="searchBox"
        class="form-control"
        placeholder="Search vehicle by plate or name"
        v-model="searchTerm"
      />
    </div>

    <div class="overflow-auto car-list">
      <li v-for="vehicle in filteredVehicles" class="garage-list-item">
        <VehicleItem :veh="vehicle"></VehicleItem>
      </li>
    </div>
  </div>
</template>

<style scoped>
#app-border {
  background-color: darkgray;
  padding: 10px 10px 15px 15px;
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

.car-list /*You could also use an ID*/ {
  height: 50vh;
  overflow-y: auto;
}

.car-list::-webkit-scrollbar-track
{
	-webkit-box-shadow: inset 0 0 6px rgba(0,0,0,0.3);
	border-radius: 2px;
	background-color: #F5F5F5;
}

.car-list::-webkit-scrollbar
{
	width: 12px;
    background-color: #F5F5F5;
    border-radius:2px;
}

.car-list::-webkit-scrollbar-thumb
{
	border-radius: 2px;
	-webkit-box-shadow: inset 0 0 6px rgba(0,0,0,.3);
	background-color: #999;
}

.garage-list-item {
  border-radius: 5px;
  margin-top: 1px;
  margin-bottom: 1px;
  background-color: dimgray;
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
  padding: 0.6rem .7rem;
  border: 1px solid rgba(0, 0, 0, 0.125);
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
