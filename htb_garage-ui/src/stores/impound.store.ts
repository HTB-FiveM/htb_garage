import type { ImpoundStore, ImpoundStoreVehicle, ImpoundVehicle } from '@/types/impoundTypes';
import { defineStore } from 'pinia';
import type { EnableImpoundData, SetupImpoundRetrieveVehicleData, SetupImpoundStoreVehicleData } from '@/types/nuiMessageTypes';
import { useAppStore } from './app.store';

export const useImpoundStore = defineStore('impound', {
  state: () =>
    ({
      mode: null,
      availableImpounds: null,
      timePeriods: null,

      storeVehicle: null,
      retrieveVehicle: null,
    }) as ImpoundStore,
  getters: {
    filteredVehicles(state): (searchTerm: string) => ImpoundVehicle[] | undefined {
      return (searchTerm: string) => {
        if (searchTerm === '') {
          return state.retrieveVehicle?.vehicles;
        }

        return state.retrieveVehicle?.vehicles.filter((veh) => {
          const searchLower = searchTerm.toLowerCase();
          return (
            veh.plate.toLowerCase().indexOf(searchLower) > -1 ||
            (veh.spawnName !== undefined && veh.spawnName.toLowerCase().indexOf(searchLower) > -1) ||
            (veh.modelName !== undefined && veh.modelName.toLowerCase().indexOf(searchLower) > -1) ||
            (veh.displayName !== undefined && veh.displayName.toLowerCase().indexOf(searchLower) > -1)
          );
        });
      };
    },
  },
  actions: {
    // Handle messages from game client
    initStore(messageData: EnableImpoundData) {
      const oldPlate = this.storeVehicle?.vehiclePlate ?? null;
      this.storeVehicle = {
        ...newStoreVehicle(),
        vehiclePlate: oldPlate,
      };

      const appStore = useAppStore();
      appStore.isVisible = messageData.isVisible;
    },
    setupImpoundStoreVehicle(messageData: SetupImpoundStoreVehicleData) {
      this.mode = 'store';
      this.storeVehicle = {
        ...(this.storeVehicle ?? newStoreVehicle()),
        vehiclePlate: messageData.vehiclePlate,
      };

      this.availableImpounds = [...messageData.availableImpounds];
      this.timePeriods = [...messageData.timePeriods];
    },
    setImpoundRetrieveVehicle(messageData: SetupImpoundRetrieveVehicleData) {
      this.mode = 'retrieve';
      this.retrieveVehicle = {
        vehicles: [...messageData.vehicles],
      };
    },

    // Actions specific to business of the Vue interface
    async impoundVehicle(impoundStoreDetails: ImpoundStoreVehicle) {
      const requestOptions = {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(impoundStoreDetails),
      };

      await fetch('https://htb_garage/impoundStore', requestOptions);
    },

    async takeOut(vehicle: ImpoundVehicle, payForRetrieve: boolean) {
      const requestOptions = {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          ...vehicle,
          payForRetrieve,
        }),
      };
      await fetch('https://htb_garage/takeOut', requestOptions);
    },

    async returnToOwner(vehicle: ImpoundVehicle) {
      const requestOptions = {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          ...vehicle,
        }),
      };
      await fetch('https://htb_garage/returnToOwner', requestOptions);
    },
  },
});

function newStoreVehicle(): ImpoundStoreVehicle {
  return {
    vehiclePlate: null,
    impoundId: null,
    reasonForImpound: null,
    expiryHours: null,
    allowPersonalUnimpound: false,
  };
}
