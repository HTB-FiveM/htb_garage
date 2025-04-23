import { ImpoundStore, ImpoundStoreVehicle } from "@/types/impoundTypes";
import { defineStore } from "pinia";
import { EnableImpoundStoreData, ImpoundRetrieveVehicleData, ImpoundStoreVehicleData } from "@/types/nuiMessageTypes";
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
        this.storeVehicle = {
          vehiclePlate: messageData.vehiclePlate,
          selectedImpoundName: null,
          reasonForImpound: null,
          expiryHours: null,
          allowPersonalUnimpound: false
        };

        const appStore = useAppStore();
        appStore.isVisible = messageData.isVisible;
      },
      setImpoundStoreVehicle(messageData: ImpoundStoreVehicleData) {
        this.mode = 'store';
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
        console.log('Action: ', impoundStoreDetails);
        console.log(JSON.stringify(impoundStoreDetails));
        await fetch("https://htb_garage/impoundStore", requestOptions);
      }
    }
});
