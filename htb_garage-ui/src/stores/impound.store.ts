import {
  ImpoundStore,
  ImpoundStoreVehicle,
  ImpoundVehicle,
} from "@/types/impoundTypes";
import { defineStore } from "pinia";
import {
  EnableImpoundData,
  SetupImpoundRetrieveVehicleData,
  SetupImpoundStoreVehicleData,
} from "@/types/nuiMessageTypes";
import { useAppStore } from "./app.store";

export const useImpoundStore = defineStore("impound", {
  state: () =>
    ({
      mode: null,
      availableImpounds: null,
      timePeriods: null,

      storeVehicle: null,
      retrieveVehicle: null,
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
      this.mode = "store";
      this.storeVehicle = {
        ...(this.storeVehicle ?? newStoreVehicle()),
        vehiclePlate: messageData.vehiclePlate,
      };

      this.availableImpounds = [...messageData.availableImpounds];
      this.timePeriods = [...messageData.timePeriods];
    },
    setImpoundRetrieveVehicle(messageData: SetupImpoundRetrieveVehicleData) {
      this.mode = "retrieve";
      this.retrieveVehicle = {
        userIsImpoundManager: messageData.userIsImpoundManager,
        vehicles: [...messageData.vehicles],
      };
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

    async returnToOwner(vehicle: ImpoundVehicle) {
      const requestOptions = {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          ...vehicle,
          userIsImpoundManager: this.retrieveVehicle.userIsImpoundManager,
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
    allowPersonalUnimpound: false,
  };
}
