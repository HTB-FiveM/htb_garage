export interface Vehicle{
  type: string;
  plate: string;
  displayName: string;
  modelName: string;
  spawnName: string;
  import: boolean;
  pound: boolean;
  stored: boolean;
  htmlId: string;

  fuel: number;
  engine: number;
  body: number;
}

export interface Player {
  serverId: string;
  identifier: string;
  name: string | null;
}

export interface GarageStore {
  isVisible: boolean;

  vehicles: Vehicle[];

  showFuel: boolean;
  showEngine: boolean;
  showBody: boolean;

  nearbyPlayers: Player[];

}
