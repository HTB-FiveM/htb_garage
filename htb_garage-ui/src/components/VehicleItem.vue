<script setup lang="ts">
import { ref, computed } from "vue";
import { Vehicle, Player } from "../types/garageTypes";
import VehicleAttribute from "./VehicleAttribute.vue";

import { useGarageStore } from "../stores/garage.store";

const store = useGarageStore();

defineProps<{ veh: Vehicle }>();

const showDetails = ref(false);
const showSetName = ref(false);
const tempNickName = ref("");

const newOwner = ref(null as Player | null);

const showTransferOwnership = computed(() =>
  store.nearbyPlayers &&
  store.nearbyPlayers.length > 0
);

const modelName = (vehicle: Vehicle) => {
  if (!vehicle.modelName || vehicle.modelName === "null") {
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
};

const retrieveVehicle = async (vehicle: Vehicle) => {
  await store.takeOut(vehicle, true);
};

const showTransferOwnershipPanel = async () => {
  await store.fetchNearbyPlayers();
  hideSetName();
};

const hideTransferOwnership = () => {
  store.clearNearbyPlayers();
  newOwner.value = null;
};

const showSetNamePanel = () => {
  showSetName.value = true;
  hideTransferOwnership();
};

const hideSetName = () => {
  showSetName.value = false;
  tempNickName.value = "";
};

const toggleDetailsPanel = () => {
  showDetails.value = !showDetails.value;
  if(!showDetails.value) {
    hideTransferOwnership();
    hideSetName();
  }
};

</script>

<template>
  <div class="garageItemPanel" @click="toggleDetailsPanel">
    <div class="vehicleListItem">
      <span>{{ modelName(veh) }} - </span>
      <span v-if="veh.plate" class="badge badge-light">{{ veh.plate }}</span>
      <span v-if="veh.displayName"> - {{ veh.displayName }}</span>
      <small v-if="veh.import" class="carMake text-uppercase">, import</small>
    </div>
  </div>
  <div v-if="showDetails" class="details-body" :id="veh.htmlId">
    <div class="details-panel">
      <div class="action-buttons">
        <a
          v-if="veh.pound"
          type="button"
          class="vehicle-options btn btn-dark btn-sm disabled"
          >Impounded
        </a>
        <div v-else>
          <button
            v-if="veh.stored"
            type="button"
            class="vehicle-options btn btn-success btn-sm"
            @click="takeOutVehicle(veh)"
          >
            Take out
          </button>
          <button
            v-if="veh.stored === false"
            type="button"
            class="vehicle-options btn btn-warning btn-sm"
            @click="retrieveVehicle(veh)"
          >
            Pay for retrieve
          </button>
          <button
            type="button"
            class="btn btn-info btn-sm"
            @click="showTransferOwnershipPanel()"
          >
            Transfer
          </button>
          <button
            v-if="veh.stored === false"
            type="button"
            class="vehicle-options btn btn-warning btn-sm"
            @click="setGpsMarker(veh)"
          >
            Set GPS marker
          </button>
          <button
            type="button"
            class="vehicle-options btn btn-primary btn-sm"
            @click="showSetNamePanel"
          >
            Set Name
          </button>
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
      </div>
    </div>

    <div class="row transfer-ownership" v-if="showTransferOwnership">
      <div class="row dd">
        <div class="dropdown buyer">
          <v-select
            class="the-dropdown"
            :options="store.nearbyPlayers"
            placeholder="Select a buyer..."
            v-model="newOwner">
            <template #option="option">
              <span>{{ option.name }}</span>
            </template>
            <template #selected-option="{name}">
              <strong>{{ name }}</strong>
            </template>
          </v-select>
        </div>
      </div>
      <div class="row">
        <button
          type="button"
          class="btn btn-secondary modal-default-button"
          @click="hideTransferOwnership()"
        >
          Close
        </button>
        <button
          type="button"
          class="btn btn-warning"
          @click="transferVehicleOwnership(veh)"
          :disabled="!newOwner"
        >
          Transfer
        </button>
      </div>
    </div>

    <div class="setVehicleName" v-if="showSetName">
      <div class="nameField">
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
        <button
          type="button"
          class="btn btn-secondary modal-default-button"
          @click="hideSetName()"
        >
          Close
        </button>
        <button
          type="button"
          class="btn btn-primary modal-default-button"
          @click="setVehicleName(veh)"
        >
          Save
        </button>
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
</style>
