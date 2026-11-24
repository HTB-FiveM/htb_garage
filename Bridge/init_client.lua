-- Load the client-side adapters chosen in Config.lua

local frameworkName
Framework, frameworkName = LoadAdapter("framework", Config.RolePlayFramework or "auto")

-- Once the player's character has loaded, ask the server for the vehicles it is tracking
Framework.onPlayerLoaded(function()
	TriggerServerEvent("htb_garage:playerLoaded")
end)

-- "framework" means the notifications built into the framework, or the game's own
-- notification feed if there's no notify adapter for it
local notify = Config.Notify or "framework"
if notify == "framework" then
	notify = HasAdapter("notify", frameworkName) and frameworkName or "gta"
end

Notify = LoadAdapter("notify", notify, "gta")
