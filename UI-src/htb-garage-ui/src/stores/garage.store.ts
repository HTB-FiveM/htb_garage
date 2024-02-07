import { defineStore } from "pinia";
import { Vehicle, Player, GarageStore } from '../types/garageTypes';
import { NuiMessageData } from '../types/nuiMessageTypes';

export const useGarageStore = defineStore('garage', {
  state: () => ({
    isVisible: false,
    vehicles: [] as Vehicle[],
    showFuel: false,
    showEngine: false,
    showBody: false,
    nearbyPlayers: [] as Player[]

  } as GarageStore),
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
    close() {
      // this.vehicles.forEach(vehicle => {
      //     this.hideTransfer(vehicle);
      //     this.hideSetName(vehicle);
      // });
      
      // this.$refs.vehicleDetailsPanel -- Need to think about how to collapse all items at once with Vue.js, as in remove the 'show' class
      // But using jQuery here does actually work so using it for now
      // $('.collapse').collapse('hide');

      // this.search = '';
      // $.post('https://htb_garage/close', JSON.stringify({}));
    },
    takeOut(vehicle: Vehicle) {
        const requestOptions = {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({vehicle: vehicle, payForRetrieve: false})
            
        };
        fetch("https://htb_garage/takeOut", requestOptions)
            .then(response => response.json())
            .then(data => (this.postId = data.id));

        this.close(vehicle);
    },
    retrieve(vehicle: Vehicle) {
        const requestOptions = {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({vehicle: vehicle, payForRetrieve: true})
            
        };
        fetch("https://htb_garage/takeOut", requestOptions)
            .then(response => response.json())
            .then(data => (this.postId = data.id));

        this.close(vehicle);
    },
    setGpsMarker(vehicle: Vehicle) {
        const requestOptions = {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({vehicle: vehicle})
            
        };
        fetch("https://htb_garage/setGpsMarker", requestOptions)
            .then(response => response.json())
            .then(data => (this.postId = data.id));
    },
    setVehicleName(vehicle: Vehicle) {
        const requestOptions = {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({plate: vehicle.plate, newName: vehicle.tempNickName})
            
        };
        fetch("https://htb_garage/setVehicleName", requestOptions)
            .then(response => response.json())
            .then(data => {
                (this.postId = data.id);
                vehicle.displayName = vehicle.tempNickName;
                this.hideSetName(vehicle);
            });
    },
    fetchNearbyPlayers() {
        const requestOptions = {
            method: "POST",
            headers: { "Content-Type": "application/json" }                
        };
        fetch("https://htb_garage/fetchNearbyPlayers", requestOptions)
            .then(response => response.json())
            .then(data => (this.postId = data.id));
    },
    transferVehicleOwnership(vehicle: Vehicle) {
        const requestOptions = {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
                plate: vehicle.plate,
                newOwner: vehicle.selectedNewOwner
            })
            
        };
        fetch("https://htb_garage/transferOwnership", requestOptions)
            .then(response => response.json())
            .then(data => (this.postId = data.id));

        //this.hideTransfer(vehicle);

    }
  }
});
