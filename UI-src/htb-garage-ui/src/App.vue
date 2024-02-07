<script setup lang="ts">
import { ref, watch, onMounted, onUnmounted } from 'vue';
// import VehicleItem from './components/VehicleItem.vue';
import { useGarageStore } from './stores/garage.store';

const store = useGarageStore();

onMounted(() => {
  initialise();

  const unwatch = watch(() =>
    store.isVisible,
    (newValue) => {
      document.body.style.display = newValue ? "block" : "none";
    },
    {
      immediate: true
    });

    onUnmounted(() => {unwatch()});
});

const initialise = () => {
  if(window.location.protocol.startsWith("http")) {
    // Development mode initialisation
    store.initStore({
        type: 'enable',
        isVisible: true,
        showFuel: true,
        showEngine: true,
        showBody: true,
      });
  } else {
    // Running in FiveM initialisation
    window.addEventListener('message', (event) => {
      store.initStore(event.data);
    });
  }
};

const close = () => 
{

};

const search = ref(null);

////app.focusSearchBox();

// const filteredVehicles = computed(() => [
//   {

//   }
// ]);

</script>

<template>
  <div id="appBorder">
    <div class="menu-header">
      <div class="top-row">         
        <div><span id="vehicleCountTitle">Total vehicles: </span><span id="vehicleCount">{{ store.vehicles.length }}</span></div>
        <button id="close"
            type="button"
            class="noselect btn btn-danger btn-sm"
            @click="close()">
            CLOSE
        </button>
      </div>
      <div>
        <input type="text"
            ref="searchBox"
            class="form-control"
            placeholder="Search vehicle by plate or name"
            v-model="search" />
      </div>
    </div>

    <div class="overflow-auto car-list">
      <ul class="list-group">
        <!-- <li v-for="vehicle in store.vehicles" class="list-group-item garageListItem">
          <VehicleItem :veh="vehicle"></VehicleItem>
        </li> -->
      </ul>
    </div>

  </div>
</template>

<style scoped>
#appBorder {
  background-color: darkgray;
  padding: 10px 10px 15px 15px;
  border-radius: 7px;

}

.menu-header {
    margin-bottom: 5px;
}

.menu-header, .top-row {
    margin-bottom: 10px;
}
</style>
