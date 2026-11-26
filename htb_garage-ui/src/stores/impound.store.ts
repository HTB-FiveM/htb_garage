import type { ImpoundStore, ImpoundStoreVehicle, ImpoundVehicle } from '@/types/impoundTypes';
import { defineStore } from 'pinia';
import type {
  EnableImpoundData,
  ImpoundReleaseCompleteData,
  SetupImpoundReleaseVehicleData,
  SetupImpoundRetrieveVehicleData,
  SetupImpoundStoreVehicleData,
} from '@/types/nuiMessageTypes';
import { useAppStore } from '@/stores/app.store';

export const useImpoundStore = defineStore("impound", {
  state: () =>
    ({
      mode: null,
      availableImpounds: null,
      timePeriods: null,

      storeVehicle: null,
      retrieveVehicle: null,
      releaseVehicles: [],
    } as ImpoundStore),
  getters: {
    filteredVehicles(
      state
    ): (searchTerm: string) => ImpoundVehicle[] | undefined {
      return (t: string | null) => {
        const term = (t ?? "").trim().toLowerCase();
        if (!term) {
          return state.retrieveVehicle?.vehicles;
        }

        return state.retrieveVehicle?.vehicles.filter((veh: ImpoundVehicle) => {
          return (
            veh.plate.toLowerCase().includes(term) ||
            (veh.spawnName?.toLowerCase().includes(term) ?? false) ||
            (veh.modelName?.toLowerCase().includes(term) ?? false) ||
            (veh.displayName?.toLowerCase().includes(term) ?? false)
          );
        });
      };
    },
    // /ImpoundRelease: nothing until the operator types, then every vehicle matching the
    // owner's name, the plate or the vehicle type / model
    releaseMatches(state): (searchTerm: string | null) => ImpoundVehicle[] {
      return (t: string | null) => {
        const term = (t ?? "").trim().toLowerCase();
        if (!term) {
          return [];
        }
        const plateTerm = term.replace(/\s+/g, "");

        return state.releaseVehicles.filter((veh: ImpoundVehicle) => {
          return (
            veh.plate.toLowerCase().replace(/\s+/g, "").includes(plateTerm) ||
            (veh.ownerName?.toLowerCase().includes(term) ?? false) ||
            (veh.type?.toLowerCase().includes(term) ?? false) ||
            (veh.spawnName?.toLowerCase().includes(term) ?? false) ||
            (veh.modelName?.toLowerCase().includes(term) ?? false) ||
            (veh.displayName?.toLowerCase().includes(term) ?? false)
          );
        });
      };
    },
  },
  actions: {
    // Handle messages from game client
    initStore(messageData: EnableImpoundData) {
      // The game sends the vehicle (setupImpoundStoreVehicle) before this, so keep what it
      // set: the plate and the default release fee from Config.ImpoundDefaultRetrievePrice
      this.storeVehicle = {
        ...newStoreVehicle(),
        vehiclePlate: this.storeVehicle?.vehiclePlate ?? null,
        retrievePrice: this.storeVehicle?.retrievePrice ?? 0,
      };

      const appStore = useAppStore();
      appStore.isVisible = messageData.isVisible;
    },
    setupImpoundStoreVehicle(messageData: SetupImpoundStoreVehicleData) {
      this.mode = "store";
      this.storeVehicle = {
        ...(this.storeVehicle ?? newStoreVehicle()),
        vehiclePlate: messageData.vehiclePlate,
        retrievePrice: messageData.retrievePrice
      };

      this.availableImpounds = [...messageData.availableImpounds];
      this.timePeriods = [...messageData.timePeriods];
    },
    setImpoundRetrieveVehicle(messageData: SetupImpoundRetrieveVehicleData) {
      this.mode = "retrieve";
      this.retrieveVehicle = {
        vehicles: [...messageData.vehicles],
      };
    },

    setupImpoundReleaseVehicle(messageData: SetupImpoundReleaseVehicleData) {
      this.mode = "release";
      this.releaseVehicles = [...messageData.vehicles];
    },
    impoundReleaseComplete(messageData: ImpoundReleaseCompleteData) {
      // Drop the released vehicle from the list; nothing left to release closes the form
      this.releaseVehicles = this.releaseVehicles.filter((veh) => veh.plate !== messageData.plate);
      if (this.releaseVehicles.length === 0) {
        fetch("https://htb_garage/close");
      }
    },

    // Actions specific to business of the Vue interface
    async impoundVehicle(impoundStoreDetails: ImpoundStoreVehicle) {
      const requestOptions = {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(impoundStoreDetails),
      };

      await fetch("https://htb_garage/impoundStore", requestOptions);
    },

    async impoundRetrieve(vehicle: ImpoundVehicle) {
      const requestOptions = {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          ...vehicle,
        }),
      };
      await fetch("https://htb_garage/impoundRetrieve", requestOptions);
    },

    async impoundRelease(vehicle: ImpoundVehicle) {
      const requestOptions = {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ plate: vehicle.plate, model: vehicle.model }),
      };
      await fetch("https://htb_garage/impoundRelease", requestOptions);
    },

    async returnToOwner(vehicle: ImpoundVehicle) {
      const requestOptions = {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          vehicle: { ...vehicle },
        }),
      };

      await fetch("https://htb_garage/returnToOwner", requestOptions);
    },
  },
});

function newStoreVehicle(): ImpoundStoreVehicle {
  return {
    vehiclePlate: null,
    impoundId: null,
    reasonForImpound: null,
    expiryHours: null,
    allowPersonalUnimpound: true,
    retrievePrice: 0,
  };
}
