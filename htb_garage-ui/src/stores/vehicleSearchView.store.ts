import { defineStore } from 'pinia';

export const useVehicleSearchViewStore = defineStore('vehicleSearchView', {
  state: () => ({
    searchTerm: '',
  }),
});
