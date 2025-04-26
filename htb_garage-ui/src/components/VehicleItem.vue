<script setup lang="ts">
import { inject, ref } from 'vue';
import type { Vehicle, Player } from '@/types/garageTypes';
import VehicleAttribute from '@/components/VehicleAttribute.vue';

import { useGarageStore } from '../stores/garage.store';

const store = useGarageStore();

const closeApp = inject<() => void>('closeApp')!;
function onCloseClick() {
  closeApp();
}

defineProps<{ veh: Vehicle }>();

const showDetails = ref(false);
const showSetName = ref(false);
const tempNickName = ref('');

const newOwner = ref(null as Player | null);

const showTransferOwnership = ref(false);

const modelName = (vehicle: Vehicle) => {
  if (!vehicle.modelName || vehicle.modelName === 'null') {
    return vehicle.spawnName;
  }

  return vehicle.modelName;
};

const setGpsMarker = async (vehicle: Vehicle) => {
  await store.setGpsMarker(vehicle);
};

const transferVehicleOwnership = async (vehicle: Vehicle) => {
  if (newOwner.value) {
    await store.transferVehicleOwnership(vehicle, newOwner.value);
    hideTransferOwnership();
  }
};

const setVehicleName = async (vehicle: Vehicle) => {
  await store.setVehicleName(vehicle, tempNickName.value);
  hideSetName();
};

const takeOutVehicle = async (vehicle: Vehicle) => {
  await store.takeOut(vehicle, false);
  onCloseClick();
};

const retrieveVehicle = async (vehicle: Vehicle) => {
  await store.takeOut(vehicle, true);
  onCloseClick();
};

const showNoPlayersMessage = ref(false);
const showTransferOwnershipPanel = async () => {
  hideSetName();
  showTransferOwnership.value = true;
  await store.fetchNearbyPlayers();

  checkIfPlayersNearby();
};

//TODO: need to make this work
const checkIfPlayersNearby = () => {
  if (store.nearbyPlayersReady) {
    showNoPlayersMessage.value = true; // Show the message

    // Set a timeout to hide the message after 3 seconds
    setTimeout(() => {
      showNoPlayersMessage.value = false; // This will trigger the fade-out transition
    }, 3000);
  }
};

const hideTransferOwnership = () => {
  store.clearNearbyPlayers();
  showTransferOwnership.value = false;
  newOwner.value = null;
};

const showSetNamePanel = () => {
  showSetName.value = true;
  hideTransferOwnership();
};

const hideSetName = () => {
  showSetName.value = false;
  tempNickName.value = '';
};

const toggleDetailsPanel = () => {
  showDetails.value = !showDetails.value;
  if (!showDetails.value) {
    hideTransferOwnership();
    hideSetName();
  }
};
</script>

<template>
  <div @click="toggleDetailsPanel">
    <div class="vehicleListItem">
      <span>{{ modelName(veh) }} - </span>
      <span v-if="veh.plate" class="badge badge-light">{{ veh.plate }}</span>
      <span v-if="veh.displayName"> - {{ veh.displayName }}</span>
      <small v-if="veh.import">, import</small>
    </div>
  </div>
  <div v-if="showDetails" class="details-body" :id="veh.htmlId">
    <div class="details-panel">
      <div class="action-buttons">
        <a v-if="veh.pound" type="button" class="btn btn-dark btn-sm disabled">Impounded </a>
        <div v-else>
          <button v-if="veh.stored" type="button" class="btn btn-success btn-sm" @click="takeOutVehicle(veh)">Take out</button>
          <button v-if="!veh.stored" type="button" class="btn btn-warning btn-sm" @click="retrieveVehicle(veh)">Pay for retrieve</button>
          <button type="button" class="btn btn-info btn-sm" @click="showTransferOwnershipPanel()">Transfer</button>
          <button v-if="!veh.stored" type="button" class="btn btn-warning btn-sm" @click="setGpsMarker(veh)">Set GPS marker</button>
          <button type="button" class="btn btn-primary btn-sm" @click="showSetNamePanel">Set Name</button>
        </div>
      </div>
      <div class="vehicle-attributes">
        <VehicleAttribute
          v-if="store.showFuel"
          bar-colour="#FEC211"
          label="Fuel"
          :value="veh.fuel"
          :percentage="veh.fuel"
        ></VehicleAttribute>
        <VehicleAttribute
          v-if="store.showEngine"
          bar-colour="#DC3D4C"
          label="Engine"
          :value="veh.engine / 10"
          :percentage="veh.body"
        ></VehicleAttribute>
        <VehicleAttribute
          v-if="store.showBody"
          bar-colour="#1183FD"
          label="Body"
          :value="veh.body / 10"
          :percentage="veh.body"
        ></VehicleAttribute>
        <transition name="fade">
          <div v-if="showNoPlayersMessage" class="no-players">No players near you to transfer ownership</div>
        </transition>
      </div>
    </div>

    <div class="transfer-ownership" v-if="showTransferOwnership">
      <div class="dd">
        <div class="dropdown buyer">
          <v-select class="the-dropdown" :options="store.nearbyPlayers" placeholder="Select a buyer..." v-model="newOwner">
            <template #option="option">
              <span>{{ option.name }}</span>
            </template>
            <template #selected-option="{ name }">
              <strong>{{ name }}</strong>
            </template>
          </v-select>
        </div>
      </div>
      <div>
        <button type="button" class="btn btn-secondary" @click="hideTransferOwnership()">Close</button>
        <button type="button" class="btn btn-warning" @click="transferVehicleOwnership(veh)" :disabled="!newOwner">Transfer</button>
      </div>
    </div>

    <div class="setVehicleName" v-if="showSetName">
      <div>
        <input
          slot="body"
          type="text"
          id="vehicleNickName"
          class="form-control"
          placeholder="Choose a nick name for this car"
          v-model="tempNickName"
        />
      </div>
      <div class="nick-buttons">
        <button type="button" class="btn btn-secondary" @click="hideSetName()">Close</button>
        <button type="button" class="btn btn-primary" @click="setVehicleName(veh)">Save</button>
      </div>
    </div>
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
</style>
