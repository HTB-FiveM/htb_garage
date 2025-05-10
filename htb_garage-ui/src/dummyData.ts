import {
  EnableGarageData,
  EnableImpoundData,
  SetupImpoundStoreVehicleData,
  InitVehicleStatsData,
  MessageHandlers,
  SetVehiclesData,
  SetupImpoundRetrieveVehicleData,
} from "@/types/nuiMessageTypes";
import { Impound } from "./types/impoundTypes";

export default function initialiseDummyData(
  handlers: MessageHandlers,
  route: string
) {
  if (route === "/vehicleMenu") {
    handlers["enableGarage"]({
      type: "enableGarage",
      isVisible: true,
    } as EnableGarageData);

    handlers["initVehicleStats"]({
      type: "initVehicleStats",
      showFuel: true,
      showEngine: true,
      showBody: true,
    } as InitVehicleStatsData);

    handlers["setVehicles"]({
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

  if (route === "/impound") {
    handlers["enableImpound"]({
      type: "enableImpound",
      isVisible: true,
    } as EnableImpoundData);

    handlers["setupImpoundStoreVehicle"]({
      type: "setupImpoundStoreVehicle",
      vehiclePlate: "abc123",
      availableImpounds: [
        {
          id: "HG",
          displayName: "Harry's garage",
        },
        {
          id: "FG",
          displayName: "First Garage",
        },
        {
          id: "SG",
          displayName: "Second Garage",
        },
        {
          id: "TG",
          displayName: "Third Garage",
        },
      ] as Impound[],
      timePeriods: [
        0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19,
        20, 21, 22, 23, 24,
      ],
    } as SetupImpoundStoreVehicleData);
  }

  if (route === "/retrieve") {
    handlers["enableImpound"]({
      type: "enableImpound",
      isVisible: true,
    } as EnableImpoundData);

    handlers["setupImpoundRetrieveVehicle"]({
      type: "setupImpoundRetrieveVehicle",
      userIsImpoundManager: false,
      vehicles: [
        {
          type: "adder",
          plate: "abc123",
          displayName: "Bob",
          modelName: "adssadads",
          spawnName: "34534543",
          import: false,
          priceToRelease: 1000,
          timeLeft: 0,
          impoundId: "LosSantos",
          impoundName: "David Sherriff Station",
          impoundVehicleId: 5,
          canRetrieveHere: false
        },
        {
          type: "zentorno",
          plate: "def567",
          displayName: "Snoogans",
          modelName: "dsfgsdfg",
          spawnName: "657457",
          import: true,
          priceToRelease: 700,
          timeLeft: 3,
          impoundId: "David_Sherriff_Station",
          impoundName: "David Sherriff Station",
          impoundVehicleId: 56,
          canRetrieveHere: true
        },
      ],
    } as SetupImpoundRetrieveVehicleData);
  }
}
