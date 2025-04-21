export interface EnableData {
  type: 'enable';
  isVisible: boolean;
  showFuel: boolean;
  showEngine: boolean;
  showBody: boolean;
}

export interface SetVehiclesData {
  type: 'setVehicles';
  vehicles: string; // Assuming this is a JSON string that needs parsing
}

export interface SetNearbyPlayersListData {
  type: 'setNearbyPlayersList';
  nearbyPlayers: string; // Assuming this is a JSON string that needs parsing
}

export interface TransferCompleteData {
  type: 'transferComplete';
  plate: string; // Assuming this is a JSON string that needs parsing
}


// Union type for all message types
export type NuiMessageData = EnableData | SetVehiclesData | SetNearbyPlayersListData | TransferCompleteData;
