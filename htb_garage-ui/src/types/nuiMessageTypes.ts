import { Impound, ImpoundVehicle } from "./impoundTypes";

export interface ToggleVisibilityData {
  type: 'toggleVisibility';
  isVisible: boolean;
}

export interface EnableGarageData {
  type: 'enableGarage';
  route: string;
  isVisible: boolean;
}

export interface SetVehiclesData {
  type: 'setVehicles';
  vehicles: string; // Assuming this is a JSON string that needs parsing
}

export interface InitVehicleStatsData {
  type: 'initVehicleStats';
  vehicles: string; // Assuming this is a JSON string that needs parsing
  showFuel: boolean;
  showEngine: boolean;
  showBody: boolean;  
}

export interface SetNearbyPlayersListData {
  type: 'setNearbyPlayersList';
  nearbyPlayers: string; // Assuming this is a JSON string that needs parsing
}

export interface TransferCompleteData {
  type: 'transferComplete';
  plate: string; // Assuming this is a JSON string that needs parsing
}

export interface EnableImpoundData {
  type: 'enableImpound';
  route: string;
  isVisible: boolean;
}

export interface SetupImpoundStoreVehicleData {
  type: 'setupImpoundStoreVehicle';
  vehiclePlate: 'abc123',
  availableImpounds: Impound[];
  timePeriods: number[];
}

export interface SetupImpoundRetrieveVehicleData {
  type: 'setupImpoundRetrieveVehicle';
  vehicles: ImpoundVehicle[]
}

// Union type for all message types
export type NuiMessageData =
ToggleVisibilityData |
  EnableGarageData |
  InitVehicleStatsData |
  SetVehiclesData |
  SetNearbyPlayersListData |
  TransferCompleteData |

  EnableImpoundData |
  SetupImpoundStoreVehicleData |
  SetupImpoundRetrieveVehicleData;

export type MessageHandlers = {
  toggleVisibility:          (msg: ToggleVisibilityData)            => void;

  enableGarage:              (msg: EnableGarageData)                => void;  
  initVehicleStats:          (msg: InitVehicleStatsData)            => void;
  setVehicles:               (msg: SetVehiclesData)                 => void;
  setNearbyPlayersList:      (msg: SetNearbyPlayersListData)        => void;
  transferComplete:          (msg: TransferCompleteData)            => void;

  enableImpound:             (msg: EnableImpoundData)               => void;
  setupImpoundStoreVehicle:  (msg: SetupImpoundStoreVehicleData)    => void;
  setupImpoundRetrieveVehicle: (msg: SetupImpoundRetrieveVehicleData) => void;

}
  