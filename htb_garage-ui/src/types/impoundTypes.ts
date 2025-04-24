export interface Impound {
    id: number;
    displayName: string;

};

export interface ImpoundStoreVehicle {
    vehiclePlate: string | null;
    impoundId: number | null;
    reasonForImpound: string | null;
    expiryHours: number | null;
    allowPersonalUnimpound: boolean;
};

export interface ImpoundRetrieveVehicle {
    vehicles: ImpoundVehicle[]
};

export type ImpoundMode = 'store' | 'retrieve';
export interface ImpoundStore {    
    mode: ImpoundMode | null;
    availableImpounds: Impound[] | null;
    timePeriods: number[] | null,

    storeVehicle: ImpoundStoreVehicle | null;
    retrieveVehicle: ImpoundRetrieveVehicle | null;

};

export interface ImpoundVehicle {
    type: string,
    plate: string,
    displayName: string,
    modelName: string,
    spawnName: string,
    import: boolean,
    price: number,
    timeLeft: number
}
