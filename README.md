# A better vehicle garage system for FiveM RP by Harry The Bastard

## Features
 * Vehicle menu - basic garage menu, walk up to a zone and press E. Select vehicle from a simple list
 * Impound
    * Screen for police and mechanics to impound vehicles
    * Screen for owners to retrieve their impounded vehicles
 * 🚧 **Under Construction** - Personal property garages - enter you personal garage, walk up to your vehicles to drive away or inspect stats
 * 🚧 **Under Construction** - Job and garages - Both Vehicle Menu and full garage modes

 ### Vehicle menu
 * Every parking garage has a set number of spawn locations. If the first position is occupied by a vehicle or ped then the next spawn location is checked, looping through until one is free or the player is notified that there a no positions available.
 * Vehicle menu can filter the vehicle list as you type. The text compares the internal model name of the vehicle as well as plate, display and nickname.
 * Set a nickname for the vehicle.
 * If a vehicle is out in the world you can pay for a retrieve.
 * If you prefer not to pay for a retrieve a GPS waypoint can be added to the minimap.
 * If the vehicle is marked as impounded you won't be able to spawn it.
 * Transfer ownership to another player.
 * All players occupying seats of a boat will be spawned on the dock rather than dropped in the water where the boat was prior to despawn.
 * Server exports allow vehicle instances to be tracked to avoid vehicle duplication. eg, esx_vehicleshop adds an owned_vehicles record but if you don't put the vehicle away first you can get the vehicle out and have a duplicate, at least with some garages. Call `exports.htb_garage:StartTrackingVehicle(plate, networkId)` from your server code when another resource spawns an owned vehicle, and `exports.htb_garage:StopTrackingVehicle(plate)` when it removes one (e.g. an external impound system). See *Security* below.

# Changelog

## [2.2.0] – 2026-11-26

### Added
- `Config.Zones` chooses how garage, dock, hangar and impound points are shown: the ground marker or none, the prompt as the framework's own (ESX text UI or QBCore draw text, the default), GTA's help box, floating text or ox_lib's text UI, optional name labels, blips, draw distance, transparency and marker animation. Each setting can be set per kind of point. A single point can override its marker shape and transparency in `Configs/*.lua`.
- Store points only appear while you're in a vehicle you own (of the garage's kind), checked with the server.
- `/garagezones` (client) prints what happens at a garage point in the F8 console: entering, the key press and the server's reply. Handy when "E does nothing".
- When the server refuses a garage action because the player is too far away, the server console now says how far, where the server thinks they are, and the likely fix. A common cause is noclip: the server keeps the last position it had until the player reconnects.
- `Config.Notify` chooses who shows notifications: the framework's own (default), ox_lib or the game's feed. Others can be added as a small file in `Bridge/notify`.
- `Config.VehicleKeys` chooses the vehicle keys resource: `auto` (default), jaksam's `vehicles_keys`, `qb-vehiclekeys` or `none`. Others can be added as a small file in `Bridge/keys`.

### Changed
- **ft_libs is no longer needed.** Markers, blips and prompts are drawn by the resource itself (`Client/zones.lua`) and look the same as before. Remove `ensure ft_libs` if nothing else uses it, re-copy your manifest and run `refresh`.
- The framework layer (`FrameworkSpecific`, the Strategy/Context classes) is replaced by plain adapters in `Bridge/`: framework, queries, notifications and keys. See *Framework bridge*. Re-copy your manifest and run `refresh`.
- `Config.RolePlayFramework` also accepts `auto`. The unused `none` and `custom` options and `Config.UsingEsxLegacy` have been removed (ESX is found automatically).
- Charging cash then bank is written once for all frameworks instead of once per framework.
- Vehicle keys are handed out by the server once it has confirmed a spawn, instead of the client asking for them. The `htb_garage:giveKeys` network event has been removed.
- Transfers take the keys from the seller and give them to the buyer through the configured keys resource, on every framework.

### Fixed
- Garage and impound points no longer disappear after restarting htb_garage on a running server.
- ESX: the transfer list could show the wrong names, or none, for nearby players.
- The SQL queries were registered with the database twice on start.
- QBCore key events were sent after every spawn and impound retrieve even on servers without qb-vehiclekeys.

## [2.1.0] – 2026-11-24

### Added
- Support for dynamic route-aware dummy data loader.  
- Click outside the user interface closes the UI.
- Impound Vehicle User Interface to allow specified jobs the ability to impound vehicles.
- Vehicle body deformation model is re-applied when retrieving vehicle. It's a little flaky, not sure if the issue is with the 3rd party resource.

### Changed
- Vehicle Menu now shrinks the list to fit the size of the car list.
- Changed the way dummy data is loaded to simplify code.
- Using vue router to name different pages within the application and allow easy changing between pages. This avoids the need to use v-if on every possible div that might be displayed when using a single page.
- Handling messages from NUI engine in a more modular way allowing messages to typed and then call any function in the system to handle specific messages more cleanly.
- **Breaking:** oxmysql replaces mysql-async. See *Upgrading from 2.0.x* below.
- **Breaking:** `Config.ImpoundPrice` renamed to `Config.RetrieveVehiclePrice`.
- **Breaking:** OneSync is required. The server now checks real vehicle entities and player positions.
- **Breaking:** the `htb_garage:StartTrackingEntity` / `htb_garage:StopTrackingEntity` events no longer accept calls from other resources' clients. Use the `StartTrackingVehicle` / `StopTrackingVehicle` server exports instead.
- Every network event is now registered through a guard that rejects non-player sources, rate limits callers and type checks arguments. Suspicious requests fire `htb_garage:server:suspiciousActivity` for server owners to hook into.
- The server now owns vehicle state: it marks vehicles as out when handing them over, removes stored and impounded vehicles itself and moves boat passengers to the dock itself.
- Retrieval fee for vehicles left out in the world is now charged by the server instead of the client.
- Impound release fees, vehicle ownership and impound job permissions are now validated server side rather than trusting values sent by the client.

### Fixed
- Players could avoid or reduce impound release and retrieval fees by sending their own values to the server.
- Anyone could release an impounded vehicle through an unprotected server event, which has been removed.
- QBCore: impound queries referenced the ESX `owned_vehicles` table and columns.
- QBCore: vehicles were never flagged as impounded due to a mismatched SQL parameter.
- QBCore: job lookup errored, breaking every impound permission check.
- QBCore: the `impound_vehicle_htb` foreign keys referenced ESX tables, so the table couldn't be created.
- ESX: `SetupESX.sql` created the impound column as `pound` instead of `pound_htb`, and had a syntax error in the `owned_vehicles` table.
- Impound markers had no marker type configured.
- Framework manifests were missing the new impound script files.
- Any player could overwrite another player's saved vehicle (including changing its model) through the store event.
- Any player could give themselves keys to any vehicle.
- Any player could teleport other players to any position through the boat dock event.
- Vehicles could be duplicated by marking them as stored while still out in the world.
- The transfer screen sent every player's license identifier to the client.
- Vehicle transfers trusted the buyer's identifier sent by the client.
- Impounds could be made remotely, for vehicles already impounded, or with invalid lots, hold times or prices.
- Debug commands could be run by any player.
- A car retrieved for a fee could occasionally be marked as stored while still out in the world, because the clean-up of unclaimed spawns could run in the middle of the retrieve.
- The GPS marker option errored when the car wasn't tracked or was too far away to be seen.

### TODO:
- Confirm that vehicle health stats are being saved and re-applied correctly

---

## [2.0.0] – 2025-04-21

### Added
- Full re-write of the front end UI using Node.JS based Vue.JS 3 Single Page Application.
- Implement strategy pattern to make specific code strategy selection easier.

### Fixed
- Finalised the QBCore integration.

## [1.0.0] - 2022-10-03
### Added
- Initial release:  
  - Vehicle menu to replace old school garages like Eden Garage.

**Motivation**

We started our Role Play server with a basic garage system which worked nicely but had many issues. The ESX default menu used was limited and once you start acquiring many vehicles there was no sorting or filtering possible. We investigated other options including commercial resources which were mostly disappointing. One company in particular whose garage we purchased had some brilliant features and was visually exactly what I wanted to use, but past experiences with their support team on other of their products was disappointing and given I was having trouble integrating their garage and their system was obfuscated the thought of having to deal with them for support was frustrating enough to decide that writing my own system from the ground up was the only option. I have included features that I've seen in other garages and also implemented some of my own unique ideas. The only code that isn't original is the garage configuration which I lifted from jb eden garage as the configuration was pretty solid and locations were all there and ready to go.

This started as a Vue JS project as a single inline html file attaching vue to the #app id and a basic Options API style script.js and custom stylesheet. It also used Bootstrap or general layout and getting clean button stylings and dropdowns. Version 2.x of this containes a complete front end re-write using a Node JS project including Vue JS 3 with Pinia. I've taken skills I've acquired in my day job and tried to do a far better job of architecting this and creating a solid foundation for creating other NUI projects going forward.

I've also integrated some code from ESX for spawning and despawning vehicles and other stuff so that the resource can run fully stand alone. One interesting metric...in the city we run my character has 248 owned vehicles. When we installed a premium paid garage it took in excess of 5 seconds to list the vehicles and the whole game would lock up during the fetch time. htb_garage on the exact same dataset takes under 1 second and nothing freezes.

**Goals**

I'd been developing for FiveM for almost 12 months now. I had never worked with LUA so there was alot of leaning on existing examples to try to learn the syntax and general coding practices for the base language but there's also how to cater for the architecture that FiveM mandates. Using ESX 1.2 Final provided us with a fairly solid starting point but that framework has such a fundamentally flawed architecture that we spent alot of time re-writing many of the supporting addon resources to get a stable system. My key goal with this first public resource is to build something that can be re-used by anyone and integrate with any framework, be clearly written and easy to adapt over time. I am trying to use clean code to demonstrate how people could approach coding to produce better quality work. I would like to think that what I do here triggers clearer thinking, particularly for new developers for whom FiveM is their first coding experience. I have included some original ideas and re-used standard patterns, for example I've included a clean way for people to configure the identifier they wish to use, eg steam, identifier, discord, etc as well as a neat way to configure the framework in use and be able to cleanly switch between them. For sorting a list rather than looping and coming up with the slowest possible pattern in LUA I've used a Binary Tree to add potentially random data into a list sorting efficiently at the time of insert and being able to traverse it efficiently for display. I hope my work can help show a different way of thinking about coding for FiveM.

**Future Direction**

Since the initial release I've applied many changes to help make the code cleaner and more abstracted away from the the specific implementations of certain frameworks. Everything that differs between frameworks lives in the `Bridge` folder as small, swappable adapters (see *Framework bridge* below), including the framework specific SQL: for example ESX stores the vehicle configuration in the 'vehicle' column of owned_vehicles, whereas QBCore uses the 'mods' column of player_vehicles. Pick the framework with the matching fxmanifest file and `Config.RolePlayFramework`. If a framework in use provides a different definition then this system needs to customised by the server developers and I'll probably never see a pull request to back integrate...plus it's likely to be a bandaid hack, so I'd rather provide a clean and modular way to provide support for different Role Play frameworks out of the box as well as accomodate custom frameworks allowing the server developers to put their custom code into a dedicated source file without needing to modify the core system.

I plan to be actively maintaining this project and I'm open to suggestions and pull requests to merge back any fixes to issues that people with to contribute.

If you need any assistance feel free to reach out at https://discord.gg/Ngg75byBbB

**Sample Screenshots**
<img width="906" height="700" alt="image" src="https://github.com/user-attachments/assets/f197edcf-1a51-40cb-8860-5cb4fefcafe1" />

<img width="946" height="891" alt="image" src="https://github.com/user-attachments/assets/56ad87dd-4fdc-4550-aeaf-e7af0a786914" />

To impound a vehicle be close to it and be facing it then type the command /impound then fill out the details in the form:
<img width="1272" height="994" alt="image" src="https://github.com/user-attachments/assets/e22b9a90-6b46-478e-8556-aab75b46b23a" />

When retrieving if a time was specified with "Impound for" you will have to wait for that time period to expire:
<img width="1664" height="890" alt="image" src="https://github.com/user-attachments/assets/91d074a6-99b9-45ab-aff3-ccfbc99032ee" />
<img width="1308" height="647" alt="image" src="https://github.com/user-attachments/assets/32049282-1833-4549-b461-6be5dbf9a66e" />

Impounds have dedicated parking spaces and releasing a vehicle will spawn it to a random unoccupied space:
<img width="2509" height="1616" alt="image" src="https://github.com/user-attachments/assets/f89805ff-4ec8-4b24-b40b-e080074ca518" />
<img width="2558" height="1738" alt="image" src="https://github.com/user-attachments/assets/1a31d539-76d2-4cd0-9a74-95c3e638055b" />


**Database version**

The queries use `JSON_VALUE`, so you need MySQL 8.0.21+ or MariaDB 10.3+. The queries and the upgrade scripts have been run against MySQL 9.3 and MariaDB 11.7.


**Framework bridge**

Anything that differs from server to server is an *adapter*: a plain Lua table of functions registered under a name. `Config.lua` picks one of each kind by name, or `auto` picks whichever matching resource is running.

| Kind | Side | Adapters | Config |
|---|---|---|---|
| `framework` | client and server | `esx`, `qbcore` | `Config.RolePlayFramework` |
| `queries` | server | `esx`, `qbcore` (follows the framework) | |
| `notify` | client | `esx`, `qbcore`, `ox_lib`, `gta` | `Config.Notify` |
| `keys` | server | `vehicles_keys`, `qb-vehiclekeys`, `none` | `Config.VehicleKeys` |

The rest of the resource calls them directly, e.g. `Framework.getIdentifier(playerId)`, `Notify.send(message)` or `Keys.give(playerId, plate, "permanent")`. Rules that are the same for every framework, such as charging cash before bank, are written once in the resource and use the adapter's small building blocks (`getBalance`, `removeMoney`).

To add your own, copy an existing file in `Bridge/<kind>`, give it a new name and set that name in `Config.lua`:

```lua
-- Bridge/notify/okokNotify.lua
RegisterAdapter("notify", "okokNotify", {
    send = function(message, kind)
        exports["okokNotify"]:Alert("Garage", message, 5000, kind or "info")
    end,
})
```

`Bridge/registry.lua` lists the functions each kind must provide. They're checked when the resource starts, so a missing one is reported by name straight away (*The keys adapter 'mine' is missing: remove*) rather than failing later in game. After adding a file, run `refresh` before restarting the resource.


**Installation**
* Install oxmysql https://github.com/overextended/oxmysql if you don't already have it and add the ensure statement to your server.cfg. mysql-async is no longer supported.
* Install VehicleDeformation https://github.com/Kiminaze/VehicleDeformation if you don't already have it and add the ensure statement to you server.cfg
* Install htb_garage and add the ensure statement after oxmysql in the server.cfg
* Run **one** SQL script, picked from the table below. Each script builds the complete, current database schema (impound table included), so you never need to run more than one. Back up your database first.

    | Your server | ESX | QBCore |
    |---|---|---|
    | No vehicles table yet | `SQL/SetupESX.sql` | n/a (qb-core creates `player_vehicles`) |
    | Has a vehicles table, htb_garage never installed (e.g. stock ESX Legacy from the fxserver recipe deployer, or stock qb-core) | `SQL/UpdateESX.sql` | `SQL/UpdateQB-Core.sql` |
    | htb_garage already installed (any older version) | `SQL/Upgrade-2.1.0-ESX.sql` | `SQL/Upgrade-2.1.0-QBCore.sql` |

    The `Upgrade-2.1.0` scripts upgrade an existing install in place and keep your data. They're not a step to run on top of `SetupESX.sql` / `Update*.sql`: those already create the 2.1.0 schema. See *Upgrading from 2.0.x* below.
* Easiest: download `htb_garage-vX.Y.Z-esx.zip` or `htb_garage-vX.Y.Z-qbcore.zip` from the GitHub release. It already has the right `fxmanifest.lua` and the built UI, so just set `Config.RolePlayFramework` to match.
* From the source code instead: rename `fxmanifest-esx.lua` or `fxmanifest-qb.lua` to `fxmanifest.lua` based on the Role Play framework you're running, and set `Config.RolePlayFramework` to match.
* Check `Config.Notify` (who shows notifications) and `Config.VehicleKeys` (your keys resource). The defaults use your framework's notifications and whichever supported keys resource is running.
* Optionally change how garage points look with `Config.Zones`: ground markers or none, the prompt as the framework's own (default), GTA's help box, floating text or ox_lib's text UI, name labels, blips, draw distance and marker transparency, for everything or per kind of point (car, boat, plane, impound).

**Upgrading from 2.0.x**
* **oxmysql is now required.** The resource uses oxmysql's `MySQL.single.await` / `MySQL.scalar.await` and will not run on mysql-async. Swap the dependency in your server.cfg.
* **Database.** Back up your database, then run `SQL/Upgrade-2.1.0-ESX.sql` or `SQL/Upgrade-2.1.0-QBCore.sql` with HeidiSQL or the mysql/mariadb command line client (it works on MySQL and MariaDB). It upgrades the database in place from any earlier version, is safe to run more than once, and finishes with two review queries (impounds pointing at unknown lots, and vehicles stuck as impounded) to check before starting the server. Don't re-run the old `Update*.sql` scripts on an existing database.
* **Config changes.** If you are carrying over a customised `Config.lua`:
    * `Config.ImpoundPrice` has been renamed to `Config.RetrieveVehiclePrice` (the fee to recall a vehicle that is out in the world).
    * New impound settings: `Config.Blips.impound`, `Config.ImpoundMarkerType`, `Config.ImpoundTimePeriods`, `Config.ImpoundDefaultRetrievePrice`, `Config.UseInGameClock` and `Config.InGameHourSeconds`. Impound locations live in `Configs/Impounds.lua`.
* **Manifest changes.** New script files were added (`constants.lua`, `Server/security.lua`, `Client/utils.lua`, `Client/impound.lua`) and `Configs/*.lua` is now loaded server side. Re-copy `fxmanifest-esx.lua` or `fxmanifest-qb.lua` over your `fxmanifest.lua`, then run `refresh` in the server console before `restart htb_garage` (or restart the whole server). A plain restart doesn't pick up new files in a manifest.
* **OneSync is required.** It is on by default when using txAdmin and is required by ESX Legacy.
* **Vehicle tracking from other resources.** If you triggered `htb_garage:StartTrackingEntity` / `htb_garage:StopTrackingEntity` from another resource, switch to the server exports described under *Security*.

**Security**

Never trust the client: cheat menus can run code inside this resource's client scripts and send any event with any values, so a secret key sent by the client can't stop them. Instead every request is checked on the server:
* Network events are registered through `Security.RegisterNetEvent` (`Server/security.lua`), which only accepts connected players, rate limits each player per event and type checks the arguments.
* Each handler validates against the database, the config and the real game entities: vehicle ownership, prices, impound lots, the vehicle's plate and model, and that the player is actually standing at the garage, impound or vehicle.
* Limits and distances can be tuned in `Config.Security`.

Requests that could only come from a modified client are printed to the server console and fire a server-only event you can connect to your own anticheat, ban system or logging:

```lua
AddEventHandler("htb_garage:server:suspiciousActivity", function(playerId, eventName, reason)
    -- e.g. log to Discord, notify staff or ban
end)
```

Never `RegisterNetEvent` that event name, or clients will be able to send fake reports. Set `Config.Security.KickOnSuspicious = true` to kick automatically.

Other server resources should use the exports rather than network events. Clients can't call exports:
* `exports.htb_garage:StartTrackingVehicle(plate, networkId)`
* `exports.htb_garage:StopTrackingVehicle(plate)`
* `exports.htb_garage:GiveVehicleKeys(playerId, plate, lifetime)` where lifetime is `permanent` or `temporary`

The admin commands `garageToggleDebug` and `dumpVehicleInstances` are restricted. Grant them with `add_ace group.admin command.garageToggleDebug allow`.

**Note regarding ESX-Legacy**

There's been some changes to ESX and they now have a built in garage system that uses a column named *pound* that's a varchar which clashes with mine. I've adjusted the database column name to be pound_htb. If you've been running an old version my this resource please add that column to your database. You can take the update SQL and just comment out the other columns so you only add the pound_htb one.
