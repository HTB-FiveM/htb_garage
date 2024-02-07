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
                        || veh.vehicleName !== undefined && veh.vehicleName.toLowerCase().indexOf(searchLower) > -1
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
    async takeOut(vehicle: Vehicle) {
        const requestOptions = {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({vehicle: vehicle, payForRetrieve: false})
            
        };
        const response = await fetch("https://htb_garage/takeOut", requestOptions);
        const resp = response.json();
            //.then(data => (this.postId = data.id));

        this.close();
    },
    async retrieve(vehicle: Vehicle) {
        const requestOptions = {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({vehicle: vehicle, payForRetrieve: true})
            
        };
        var response = await fetch("https://htb_garage/takeOut", requestOptions);
        var resp = response.json();
            // .then(response => response.json())
            // .then(data => (this.postId = data.id));

        this.close();
    },
    async setGpsMarker(vehicle: Vehicle) {
        const requestOptions = {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({vehicle: vehicle})
            
        };
        var response = await fetch("https://htb_garage/setGpsMarker", requestOptions);
        var resp = response.json();
        //     .then(response => response.json())
        //     .then(data => (this.postId = data.id));
    },
    async setVehicleName(vehicle: Vehicle, nickName: string) {
        const requestOptions = {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({plate: vehicle.plate, newName: nickName})
            
        };
        const response = await fetch("https://htb_garage/setVehicleName", requestOptions);
        const resp = response.json();

            // .then(data => {
            //     (this.postId = data.id);
            //     vehicle.displayName = vehicle.tempNickName;
            //     this.hideSetName(vehicle);
            // });

        // TODO: Might not need this
        let theVehicle = this.vehicles.find(veh => veh.plate === vehicle.plate);
        if(theVehicle) {
            theVehicle = {...vehicle, vehicleName: nickName};
        }
    },
    async fetchNearbyPlayers() {
        const requestOptions = {
            method: "POST",
            headers: { "Content-Type": "application/json" }                
        };
        var response = await fetch("https://htb_garage/fetchNearbyPlayers", requestOptions);
        var resp = response.json();
            // .then(response => response.json())
            // .then(data => (this.postId = data.id));
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
        var response = await fetch("https://htb_garage/transferOwnership", requestOptions);
        var resp = response.json();
            // .then(response => response.json())
            // .then(data => (this.postId = data.id));

    }
  }
});
