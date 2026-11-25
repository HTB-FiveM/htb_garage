# TODO

Outstanding items from the security review of the 2.1.0 changes.

## Bugs

- [ ] **NUI callbacks that never reply.** `impoundRetrieve` (when no spawn point is free) and `returnToOwner` (when the client-side check fails) in `Client/impound.lua` return without calling `cb`, so the UI's `fetch` never completes. Call `cb("ok")` (or an error response) on every path.
- [ ] **Old impound rows with no release time.** `FetchImpoundedPlayerVehicles` passes `releaseDateTime` to `ParseDateTime`, which errors on `NULL`. The server always sets it now, but rows created by older versions could break the impound list. Treat a missing value as already expired.
- [ ] **QBCore: spawning newly bought vehicles.** Spawning reads the model from the `mods` JSON (`json_value(mods, '$.model')` and `vehicleProps.model`), but qb-vehicleshop saves `mods` as `{}` and stores the model in the `vehicle` / `hash` columns. Fall back to `hash` when `mods` has no model. (Pre-existing; affects QBCore only.)

## Features

- [ ] **Staff view for returning vehicles to their owners.** The impound retrieve list only shows the player's own vehicles, so the "Return to owner" button is hidden (`allowReturn = false` in `Server/main.lua`). The server event `htb_garage:server:ReturnVehicleToOwner` is already secured (impound job, at the lot, not their own vehicle). Still needed:
    - a server event/list of all impounded vehicles at a lot for impound staff
    - set `allowReturn` for staff in that list
    - remove the `userIsImpoundManager` check in the `returnToOwner` NUI callback (the UI never sends it; the server is the authority)
- [ ] **Enforce impound hold time and "allow personal unimpound" server side.** Currently only the UI hides the retrieve button until the hold time has passed. Deliberately left open for now so owners can always retrieve by paying the fee.

## Hardening

- [ ] **Only send players their own tracked vehicles.** `htb_garage:UpdateLocalVehicleInstances` broadcasts the network ids of every tracked vehicle to every client, which lets anyone locate other players' vehicles. Each client only needs its own vehicles (for duplicate checks and GPS waypoints).
- [ ] **Vehicle mods are trusted from the client.** The server can't read most vehicle mods, so the properties saved on store come from the client. Plate, model and ownership are verified; mods and colours can't be.
- [ ] **Garage spawn bay is chosen by the client.** Impound spawn points are validated against the config, but garage spawn positions are calculated client side.

## Clean up

- [ ] **Check translated text in the built UI.** The impound "Pay for retrieve" button went blank because a leftover `$t('greeting', ...)` threw a `SyntaxError` in the built UI (removed). The cause isn't known: it is *not* the `[htb]` folder name (checked: the i18n plugin matches bracketed paths fine, and the HTB resource template builds and renders `$t` text from a `[htb]` folder). Before adding translated text here, build and open the screen in game (or follow the template's built-UI check) to confirm it renders.

- [ ] Remove the `/settime` debug command (`Server/main.lua`) and the `timeSync:updateTime` client handler (`Client/main.lua`).
