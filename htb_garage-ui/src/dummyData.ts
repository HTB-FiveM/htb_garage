import { EnableGarageData, EnableImpoundStoreData, SetupImpoundStoreVehicleData, InitVehicleStatsData, MessageHandlers, SetVehiclesData } from "@/types/nuiMessageTypes";
import { Impound } from "./types/impoundTypes";

export default function initialiseDummyData(handlers: MessageHandlers, route: string) {
    if(route === '/vehicleMenu') {
        handlers['enableGarage']({
            type: 'enableGarage',
            isVisible: true,
        } as EnableGarageData);

        handlers['initVehicleStats']({
            type: 'initVehicleStats',
            showFuel: true,
            showEngine: true,
            showBody: true,
        } as InitVehicleStatsData);
    
        handlers['setVehicles']({
        type: "setVehicles",
        vehicles: JSON.stringify([
            {
                type: "adder",
                plate: "abc123",
                displayName: "Bob",
                modelName: "adssadads",
                spawnName: "34534543",
                import: 0,
                pound: 0,
                stored: 1,
                htmlId: "adsadad",
                fuel: 80,
                engine: 243,
                body: 675,
            },
            {
                type: "zentorno",
                plate: "def567",
                displayName: "Snoogans",
                modelName: "dsfgsdfg",
                spawnName: "657457",
                import: 1,
                pound: 0,
                stored: 0,
                htmlId: "sdfg",
                fuel: 59,
                engine: 567,
                body: 567,
            },

        ]),
        } as SetVehiclesData);

    }

    if(route === '/impound') {
        handlers['enableImpoundStore']({
            type: "enableImpoundStore",        
            isVisible: true,
        } as EnableImpoundStoreData);

        handlers['setupImpoundStoreVehicle']({
            type: "setupImpoundStoreVehicle",
            vehiclePlate: 'abc123',
            availableImpounds: [{
                id: 1,
                displayName: 'Union Depository',
            },
            {
                id: 2,
                displayName: 'First Garage',
            },
            {
                id: 3,
                displayName: 'Second Garage',
            },
            {
                id: 4,
                displayName: 'Third Garage',
            }] as Impound[],
            timePeriods: [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24]
        } as SetupImpoundStoreVehicleData);
    }

};
