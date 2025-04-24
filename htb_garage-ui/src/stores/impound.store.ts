import { ImpoundStore, ImpoundStoreVehicle } from "@/types/impoundTypes";
import { defineStore } from "pinia";
import { EnableImpoundStoreData, ImpoundRetrieveVehicleData, SetupImpoundStoreVehicleData } from "@/types/nuiMessageTypes";
import { useAppStore } from "./app.store";

export const useImpoundStore = defineStore('impound', {
    state: () => ({
      mode: null,
      availableImpounds: null,
      timePeriods: null,
      
      storeVehicle: null,
      retrieveVehicle: null,

    } as ImpoundStore),
    actions: {
      // Handle messages from game client
      initStore(messageData: EnableImpoundStoreData) {
        const oldPlate = this.storeVehicle?.vehiclePlate ?? null;
        this.storeVehicle = {
          ...newStoreVehicle(),
          vehiclePlate: oldPlate
        }

        const appStore = useAppStore();
        appStore.isVisible = messageData.isVisible;
      },
      setupImpoundStoreVehicle(messageData: SetupImpoundStoreVehicleData) {
        this.mode = 'store';
        this.storeVehicle = {
          ...this.storeVehicle ?? newStoreVehicle(),
          vehiclePlate: messageData.vehiclePlate
        }

        this.availableImpounds = [ ...messageData.availableImpounds ];
        this.timePeriods = [ ...messageData.timePeriods ];

      },
      setImpoundRetrieveVehicle(messageData: ImpoundRetrieveVehicleData) {
        this.mode = 'retrieve';
        this.retrieveVehicle = {
          vehiclePlate: messageData.type
        };

      },

      // Actions specific to business of the Vue interface
      async impoundVehicle(impoundStoreDetails: ImpoundStoreVehicle) {
        const requestOptions = {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(impoundStoreDetails)
            
        };

        await fetch("https://htb_garage/impoundStore", requestOptions);
      }
    }
});


function newStoreVehicle(): ImpoundStoreVehicle {
  return {
    vehiclePlate: null,
    impoundId: null,
    reasonForImpound: null,
    expiryHours: null,
    allowPersonalUnimpound: false
  };
}
