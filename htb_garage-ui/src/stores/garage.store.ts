import { Player } from './../types/garageTypes';
import { defineStore } from "pinia";
import { Vehicle, GarageStore } from '../types/garageTypes';
import { EnableGarageData, InitVehicleStatsData, SetNearbyPlayersListData, SetVehiclesData, TransferCompleteData } from '../types/nuiMessageTypes';
import { useAppStore } from './app.store';

export const useGarageStore = defineStore('garage', {
  state: () => ({
    vehicles: [],
    showFuel: false,
    showEngine: false,
    showBody: false,
    nearbyPlayers: [],
    nearbyPlayersLoaded: false,

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
    },
    nearbyPlayersReady: (state) => state.nearbyPlayers.length > 0 && state.nearbyPlayersLoaded
    
  },
  actions: {
    // Handle messages from game client
    initStore(messageData: EnableGarageData) {
        const appStore = useAppStore();
        appStore.isVisible = messageData.isVisible;
    },
    initVehicleStats(messageData: InitVehicleStatsData) {
        this.showFuel = messageData.showFuel;
        this.showEngine = messageData.showEngine;
        this.showBody = messageData.showBody;
    },
    setVehicles(messageData: SetVehiclesData) {
        this.vehicles = JSON.parse(messageData.vehicles);
    },
    setNearbyPlayersList(messageData: SetNearbyPlayersListData) {
        this.nearbyPlayers = JSON.parse(messageData.nearbyPlayers);
        this.nearbyPlayersLoaded = true;
    },
    transferComplete(messageData: TransferCompleteData) {
        if(messageData.plate) {
            const index = this.vehicles.findIndex(vehicle => vehicle.plate === messageData.plate);
            if (index !== -1) {
                this.vehicles.splice(index, 1);
            }
        }      
    },

    // Actions specific to business of the Vue interface
    async takeOut(vehicle: Vehicle, payForRetrieve: boolean) {
        const requestOptions = {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
                vehicle,
                payForRetrieve
            })
            
        };
        await fetch("https://htb_garage/takeOut", requestOptions);

    },
    async setGpsMarker(vehicle: Vehicle) {
        const requestOptions = {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ vehicle })
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
        this.nearbyPlayersLoaded = false;
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
