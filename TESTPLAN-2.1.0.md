# htb_garage 2.1.0 test plan

Covers the impound feature and the server side security changes. Work through the sections in order: later sections assume the earlier ones pass.

Notation: **A** = vehicle owner, **B** = second player, **P** = player with the `police` job (an impound job in `Config.AllowedImpoundJobs`). Two game clients are needed for transfers, boats and impounds (a second PC, or a friend).

---

## 0. Preparation

### 0.1 Server and dependencies
- [ ] Update FXServer artifacts, txAdmin, `es_extended` (or `qb-core`), `oxmysql`, `ft_libs` and `VehicleDeformation`.
- [ ] OneSync is enabled (txAdmin > Settings > FXServer). The security checks need it.
- [ ] `server.cfg` ensures `oxmysql` and `ft_libs` before `htb_garage`.
- [ ] Copy `fxmanifest-esx.lua` (or `fxmanifest-qb.lua`) over `fxmanifest.lua`.
- [ ] `Config.RolePlayFramework` matches the framework.
- [ ] Admin ace for debug commands: `add_ace group.admin command.garageToggleDebug allow` and `add_ace group.admin command.dumpVehicleInstances allow`.

### 0.2 Database
- [ ] Back up the database (HeidiSQL: Tools > Export database as SQL).
- [ ] Run `SQL/Upgrade-2.1.0-ESX.sql` (or `-QBCore.sql`) in HeidiSQL. It must complete without errors.
- [ ] Run it a **second** time. It must also complete without errors (proves it is safe to re-run).
- [ ] Check the two review queries at the end of the script:
  - every active impound's `impoundName` is a key in `Configs/Impounds.lua` (`LosSantos`, `PaletoBay`)
  - no vehicles are listed as impounded without an active impound record (fix or release any that are)
- [ ] `SHOW CREATE TABLE impound_vehicle_htb;` has `impoundName`, `priceToRelease` (NOT NULL), `impoundedByUser`, `active` and no `impoundId`.

### 0.3 Test helpers
Create a throwaway resource `htb_sectest` (don't deploy it to a live server). It plays the part of a cheat menu by sending events directly, and logs the security hook.

`htb_sectest/fxmanifest.lua`
```lua
fx_version("cerulean")
game("gta5")
client_script("client.lua")
server_script("server.lua")
```

`htb_sectest/server.lua`
```lua
AddEventHandler("htb_garage:server:suspiciousActivity", function(playerId, eventName, reason)
    print(("^1[sectest] FLAGGED %s (%s): %s^0"):format(GetPlayerName(playerId), eventName, reason))
end)
```

`htb_sectest/client.lua` is filled in from the snippets in section 9.

### 0.4 Useful queries
```sql
-- A vehicle's state
SELECT plate, owner, `stored`, pound_htb, vehiclename, JSON_VALUE(vehicle, '$.model') AS model
FROM owned_vehicles WHERE plate = 'ABC123';

-- Impound records for a vehicle
SELECT * FROM impound_vehicle_htb WHERE vehiclePlate = 'ABC123' ORDER BY id DESC;
```
(QBCore: `player_vehicles`, `license` instead of `owner`, `mods` instead of `vehicle`.)

---

## 1. Start up
- [ ] `ensure htb_garage`: no errors in the server console or the F8 client console.
- [ ] Garage, dock and impound blips appear on the map. Impound markers are drawn (`Config.ImpoundMarkerType`).
- [ ] `restart htb_garage` with players connected: no errors.

## 2. Garage menu
- [ ] A: at a garage spawn marker press E. The menu lists A's cars with model, plate, fuel/engine/body.
- [ ] Filter by plate, model and nickname.
- [ ] Set a nickname. It persists after reopening. A 60+ character name is cut to 50.
- [ ] Clicking outside the UI closes it.
- [ ] Docks list boats only; garages list cars only.

## 3. Taking vehicles out
- [ ] Stored car: spawns in a free bay, A is put in the driver seat, keys are given. DB: `stored = 0`.
- [ ] As admin: `garageToggleDebug` then `dumpVehicleInstances` lists the plate.
- [ ] Taking the same car out again: "You can not take this vehicle out!" and no second copy.
- [ ] Block every bay with other vehicles, then take a car out: "All retrieval locations are blocked". DB: `stored` goes back to `1` and the car can be taken out once a bay is free.
- [ ] Impounded car: shown as impounded and can't be taken out.

## 4. Storing vehicles
- [ ] A drives own car into the store marker: A climbs out, then the car disappears. DB: `stored = 1`, `vehicle` JSON updated (damage, fuel, mods).
- [ ] Take it out again: damage, mods and deformation are restored.
- [ ] A as a **passenger** at the store marker: "not the driver" message; nothing stored.
- [ ] A stores **B's** owned car: allowed by design. B's car is stored without B paying a retrieval fee.
- [ ] A stores an NPC or unowned car: "you can not store this vehicle"; the car stays.
- [ ] With `Config.AnimateExitOnStore = false`: the car is removed straight away.

## 5. Boats
- [ ] A takes a boat out at a dock.
- [ ] B boards as a passenger. A stores the boat at the dock store marker: both A and B are moved onto the dock (`DryPoint`) and the boat disappears.

## 6. Paying to recall a vehicle left out
- [ ] A takes a car out, drives off and leaves it somewhere. Back at a garage the menu offers "Pay for retrieve" and a GPS option.
- [ ] GPS sets a waypoint to the car.
- [ ] Pay with enough money: `Config.RetrieveVehiclePrice` deducted (cash first, then bank), the old car disappears, a new one spawns.
- [ ] Pay without enough money: "Not enough money for retrieval", nothing changes.
- [ ] Click pay twice quickly: charged once, one car.
- [ ] After a paid retrieve, drive off and leave the car. Wait at least 90 seconds (longer than the 60 second spawn ticket plus the 30 second clean-up), then open the garage again: the car still shows "Pay for retrieve" and GPS, not the stored options. Repeat a few times; this used to fail now and then.
- [ ] GPS for a car that isn't tracked (e.g. after `restart htb_garage`) or is too far away to be seen: "Your vehicle can't be found" notification, no client error.
- [ ] `restart htb_garage` while the car is out, then recall: still works (the server finds the old car by plate and removes it).

## 7. Transfer ownership
- [ ] B stands next to A. A opens transfer on a car: B is listed (closest first, at most `Config.MaxPlayersInTransferList`).
- [ ] B 30+ m away: B isn't listed.
- [ ] A transfers to B: "Sold vehicle" for A, "Purchased vehicle" for B. DB: owner is B. The car leaves A's list and appears in B's.
- [ ] A selects B, B walks away, A confirms: "The buyer needs to be standing near you", no change.

## 8. Impound

### 8.1 Impounding (P)
- [ ] P faces A's parked car and types `/impound`: the form opens with the plate and both lots.
- [ ] Submit with a lot, reason, hold time and price: the car disappears. DB: new active row with those values and `impoundedByUser` = P; `pound_htb = 1`.
- [ ] `/impound` again on a car already impounded (needs a stray copy, or use section 9): "already impounded".
- [ ] `/impound` with someone sitting in the car: "Everyone must get out..." Also: open the form, have B get in, then submit: same message.
- [ ] Open the form, drive the car 20 m away, submit: "The vehicle is no longer nearby".
- [ ] `/impound` on an NPC car: "Only citizen vehicles can be impounded".
- [ ] A (not police) uses `/impound`: "You are not authorised to impound vehicles".

### 8.2 Retrieving (A)
- [ ] A at the lot holding the car, before the hold time ends: the car is listed with time left and no retrieve button.
- [ ] After the hold time (`Config.UseInGameClock`: 1 hour = 2 real minutes): retrieve shows the price. Retrieve: price deducted, car spawns in one of the lot's spawn points, keys given. DB: record `active = 0`, `pound_htb = 0`.
- [ ] Not enough money: "Unable to charge retrieval fee", nothing changes.
- [ ] Impounded with "allow personal unimpound" off: no retrieve button.
- [ ] A at the **other** lot: the car is listed but can't be retrieved there.
- [ ] No "Return to owner" button is shown to anyone (hidden until a staff view exists).
- [ ] Impound price 0: retrieves without charging.

## 9. Security (simulated cheats)

Start `htb_sectest`. For each test add the snippet to `htb_sectest/client.lua`, `restart htb_sectest`, run the command in F8. **Expected for all**: no change in the database or game, and (where marked ⚑) a `[htb_garage] Suspicious call` line in the server console plus the `[sectest] FLAGGED` line from the hook.

Replace `VICTIM` with a plate owned by B (impound it first for `t_return`), `MINE` with one of A's plates (impound it first for `t_retrieve`), `<garage>` with a garage key from `Configs/Garages.lua` (e.g. `Garage_Paleto`).

```lua
local function cmd(name, fn) RegisterCommand(name, fn, false) end

-- ⚑ Overwrite someone else's vehicle with a different model (A driving any car near no store point)
cmd("t_store", function()
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    TriggerServerEvent("htb_garage:SaveAndStoreVehicle", { plate = "VICTIM", model = `adder` },
        NetworkGetNetworkIdFromEntity(veh), "car", "<garage>")
end)

-- ⚑ Keys for a vehicle you don't own
cmd("t_keys", function() TriggerServerEvent("htb_garage:giveKeys", GetPlayerServerId(PlayerId()), "VICTIM", "permanent") end)

-- ⚑ Open a garage / spawn a vehicle from across the map
cmd("t_list", function() TriggerServerEvent("htb_garage:GetPlayerVehicles", "car", "<garage>") end)
cmd("t_spawn", function() TriggerServerEvent("htb_garage:GetVehicleForSpawn", "MINE", "<garage>", false) end)

-- ⚑ Register a fake vehicle for tracking / spawn a different model under your plate
cmd("t_track", function() TriggerServerEvent("htb_garage:StartTrackingEntity", "VICTIM", 1) end)

-- ⚑ Retrieve from the impound away from the lot, with a made up spawn point
cmd("t_retrieve", function()
    TriggerServerEvent("htb_garage:server:ImpoundRetrieveVehicle", { plate = "MINE", priceToRelease = 0 },
        { Pos = { x = 0.0, y = 0.0, z = 70.0 }, Heading = 0.0 })
end)

-- Impound without the setup step / as a non police player
cmd("t_impound", function()
    TriggerServerEvent("htb_garage:ImpoundVehicle", { vehiclePlate = "VICTIM", impoundId = "LosSantos",
        expiryHours = 0, retrievePrice = 0, reasonForImpound = "x", allowPersonalUnimpound = true })
end)

-- Release someone's vehicle for free
cmd("t_return", function() TriggerServerEvent("htb_garage:server:ReturnVehicleToOwner", { plate = "VICTIM" }) end)

-- ⚑ Transfer to a made up player / identifier
cmd("t_transfer", function()
    TriggerServerEvent("htb_garage:transferOwnership", "MINE", { serverId = 9999, identifier = "license:fake" })
end)

-- ⚑ Wrong argument types
cmd("t_types", function() TriggerServerEvent("htb_garage:SetVehicleName", { "not", "a", "string" }, 5) end)

-- Very long vehicle name (cut to 50 characters, not flagged)
cmd("t_name", function() TriggerServerEvent("htb_garage:SetVehicleName", "MINE", string.rep("A", 500)) end)

-- Spam: only the first call in each cooldown window is processed, no console flood
cmd("t_spam", function() for i = 1, 200 do TriggerServerEvent("htb_garage:GetPlayerVehicles", "car", "<garage>") end end)

-- Removed events: nothing should happen at all
cmd("t_removed", function()
    TriggerServerEvent("htb_garage:TeleportAllInVehicleToDock", { GetPlayerServerId(PlayerId()) }, { x = 0, y = 0, z = 900, h = 0 })
    TriggerServerEvent("htb_garage:SetVehicleStored", "MINE", 1)
    TriggerServerEvent("htb_garage:ReleaseVehicle", "VICTIM")
    TriggerServerEvent("htb_garage:MakePayment", "money", -1000000)
end)
```

| Command | Expected |
|---|---|
| `t_store` (far from a store point) | ⚑ "stored a vehicle away from garage". B's vehicle unchanged in the DB |
| `t_store` (at a store point, driving your own car) | ⚑ "doesn't match the vehicle's plate". Nothing saved |
| `t_keys` | ⚑ "requested keys for vehicle ... they don't own". No keys |
| `t_list`, `t_spawn` (far from that garage) | ⚑ "from a distance" / "away from garage". No menu, no vehicle |
| `t_track` | Ignored (no spawn ticket). Not in `dumpVehicleInstances` |
| `t_retrieve` (away from the lot) | ⚑ "away from impound". No charge, still impounded |
| `t_retrieve` (at the lot) | ⚑ "spawn point that isn't part of impound". Still impounded |
| `t_impound` (as A) | "not authorised", no impound row |
| `t_impound` (as P, without `/impound` first) | "no longer nearby", no impound row |
| `t_return` (as A) | "not authorised" |
| `t_return` (as P, away from the lot) | ⚑ "away from its impound" |
| `t_transfer` | ⚑ "invalid buyer". Owner unchanged |
| `t_types` | ⚑ "argument 1 should be string" |
| `t_name` | Name saved as 50 characters |
| `t_spam` | At most a few requests processed; server stays responsive |
| `t_removed` | Nothing happens: no teleport, no state change, no money change. The server console may log that the events aren't registered for network use |

- [ ] Set `Config.Security.KickOnSuspicious = true`, restart, run `t_keys`: the player is kicked with the configured message. Set it back afterwards.
- [ ] A non-admin runs `garageToggleDebug`: refused.

## 10. Exports (from another server resource)
Add to `htb_sectest/server.lua` temporarily:
```lua
RegisterCommand("t_exports", function(src)
    local veh = GetVehiclePedIsIn(GetPlayerPed(src), false)
    local plate = GetVehicleNumberPlateText(veh)
    print("track", exports.htb_garage:StartTrackingVehicle(plate, NetworkGetNetworkIdFromEntity(veh)))
    exports.htb_garage:GiveVehicleKeys(src, plate, "temporary")
end, false)
```
- [ ] Sitting in an owned car, run `t_exports`: prints `track true`; `dumpVehicleInstances` lists the plate; keys given.
- [ ] Clients can't call exports: there is no client equivalent to test, which is the point.

## 11. Edge cases
- [ ] A takes a car out and disconnects before it finishes spawning. After reconnecting (and up to 60 seconds) the car is back in the garage, not stuck as "out".
- [ ] Server restart with cars out: after restart they can be recalled with "Pay for retrieve".
- [ ] Server console stays free of `Couldn't confirm the spawn of ...` warnings during normal take-outs. If one appears, the server didn't see the new car in time; note the plate and check the car isn't later put back in the garage while it's still out.
- [ ] Two officers impound the same car at the same moment: only one impound record is created.

## 12. QBCore (only if shipping QBCore support)
Repeat sections 2, 3, 4, 7 and 8 on a QBCore server with `fxmanifest-qb.lua` and `Config.RolePlayFramework = "qbcore"`.
- [ ] Known issue (see `TODO.md`): vehicles bought from qb-vehicleshop have no model in `mods` until they've been stored once, so they may not spawn from the garage.

## 13. Sign off
- [ ] No errors in the server or client consoles during the whole run.
- [ ] Remove `htb_sectest`.
- [ ] Restore any config changed for testing.
