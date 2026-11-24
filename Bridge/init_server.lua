-- Load the server-side adapters chosen in Config.lua

local frameworkName
Framework, frameworkName = LoadAdapter("framework", Config.RolePlayFramework or "auto")

-- The database tables differ per framework, so the queries come with it
Queries = LoadAdapter("queries", frameworkName)

local wantedKeys = Config.VehicleKeys or "auto"

if wantedKeys == "auto" then
	-- A keys resource may be started after this one, so look for it the first time keys
	-- are actually needed rather than now. Falls back to "none" if none is running.
	local resolved
	Keys = setmetatable({}, {
		__index = function(_, fn)
			resolved = resolved or LoadAdapter("keys", "auto", "none")
			return resolved[fn]
		end,
	})
else
	-- A name set explicitly is checked now, so a typo is reported at startup
	Keys = LoadAdapter("keys", wantedKeys)
end
