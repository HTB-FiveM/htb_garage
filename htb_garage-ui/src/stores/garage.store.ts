import { Player } from './../types/garageTypes';
import { defineStore } from "pinia";
import { Vehicle, GarageStore } from '../types/garageTypes';
import { NuiMessageData } from '../types/nuiMessageTypes';

export const useGarageStore = defineStore('garage', {
  state: () => ({
    isVisible: false,
    vehicles: [],
    showFuel: false,
    showEngine: false,
    showBody: false,
    nearbyPlayers: [],

  } as GarageStore),
  getters: {
    vehicleCount: (state) => state.vehicles.length,
    filteredVehicles: (state) => {
        return (searchTerm: string) => {
            if(searchTerm === '') {
                return state.vehicles;
            }

            return state.vehicles.filter(veh => {
                const searchLower = searchTerm.toLowerCase();
                    return veh.plate.toLowerCase().indexOf(searchLower) > -1
                        || veh.spawnName !== undefined && veh.spawnName.toLowerCase().indexOf(searchLower) > -1
                        || veh.modelName !== undefined && veh.modelName.toLowerCase().indexOf(searchLower) > -1
                        || veh.displayName !== undefined && veh.displayName.toLowerCase().indexOf(searchLower) > -1
            });

        };
    }
  },
  actions: {
    initStore(data: unknown) {
      const messageData = data as NuiMessageData;
      switch (messageData.type) {
        case 'enable':
          this.isVisible = messageData.isVisible;
          this.showFuel = messageData.showFuel;
          this.showEngine = messageData.showEngine;
          this.showBody = messageData.showBody;
          break;

        case 'setVehicles':
          this.vehicles = JSON.parse(messageData.vehicles);
          break;

        case 'setNearbyPlayersList':
          this.nearbyPlayers = JSON.parse(messageData.nearbyPlayers);
          break;
      }
      // Handle other types as needed
    },
    async close() {      
      // this.$refs.vehicleDetailsPanel -- Need to think about how to collapse all items at once with Vue.js, as in remove the 'show' class
      // But using jQuery here does actually work so using it for now
      // $('.collapse').collapse('hide');

      await fetch("https://htb_garage/close");
      
    },
    async takeOut(vehicle: Vehicle, payForRetrieve: boolean) {
        const requestOptions = {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
                vehicle: {
                    ...vehicle,
                    stored: vehicle.stored === true ? 1 : 0,
                    pound: vehicle.pound === true ? 1 : 0
                },
                payForRetrieve: payForRetrieve
            })
            
        };
        await fetch("https://htb_garage/takeOut", requestOptions);

        this.close();
    },
    async setGpsMarker(vehicle: Vehicle) {
        const requestOptions = {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
                ...vehicle,
                stored: vehicle.stored === true ? 1 : 0,
                pound: vehicle.pound === true ? 1 : 0
            })
            
        };
        await fetch("https://htb_garage/setGpsMarker", requestOptions);
    },
    async setVehicleName(vehicle: Vehicle, nickName: string) {
        const requestOptions = {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({plate: vehicle.plate, newName: nickName})
            
        };

        await fetch("https://htb_garage/setVehicleName", requestOptions);

        // Update the vehicle name
        this.vehicles = this.vehicles.map((veh: Vehicle) => 
            veh.plate === vehicle.plate
                ? {
                    ...veh,
                    displayName: nickName
                } as Vehicle
                : veh
        );

    },
    async fetchNearbyPlayers() {
        const requestOptions = {
            method: "POST",
            headers: { "Content-Type": "application/json" }                
        };
        await fetch("https://htb_garage/fetchNearbyPlayers", requestOptions);

    },
    clearNearbyPlayers() {
        this.nearbyPlayers = [];
    },
    async transferVehicleOwnership(vehicle: Vehicle, newOwner: Player) {
        const requestOptions = {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
                plate: vehicle.plate,
                newOwner: newOwner
            })
            
        };
        await fetch("https://htb_garage/transferOwnership", requestOptions);

    }
  }
});
