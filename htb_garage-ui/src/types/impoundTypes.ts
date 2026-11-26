export interface Impound {
  id: string;
  displayName: string;
}

export interface ImpoundStoreVehicle {
  vehiclePlate: string | null;
  impoundId: number | null;
  reasonForImpound: string | null;
  expiryHours: number | null;
  allowPersonalUnimpound: boolean;
  retrievePrice: number;
}

export interface ImpoundRetrieveVehicle {
  vehicles: ImpoundVehicle[];
}

export type ImpoundMode = "store" | "retrieve" | "release";
export interface ImpoundStore {
  mode: ImpoundMode | null;
  availableImpounds: Impound[] | null;
  timePeriods: number[] | null;

  storeVehicle: ImpoundStoreVehicle | null;
  retrieveVehicle: ImpoundRetrieveVehicle | null;
  releaseVehicles: ImpoundVehicle[];
}

export interface ImpoundVehicle {
  type: string;
  plate: string;
  displayName: string;
  modelName: string;
  spawnName: string;
  import: boolean;
  priceToRelease: number;
  timeLeft: string | null;
  expired: boolean;
  impoundId: string;
  impoundName: string;
  impoundVehicleId: number;
  canRetrieveHere: boolean;
  allowPersonalUnimpound: boolean;
  allowReturn: boolean;
  // Only on the /ImpoundRelease list
  model?: number;
  ownerName?: string | null;
  reasonForImpound?: string | null;
  ownedByOfficer?: boolean; // belongs to one of the operator's own characters
}
