-------------------------------------------------------------------------------------------
-- Bridge: pluggable adapters for the things that differ from server to server.
--
-- An adapter is a plain table of functions, registered under a name:
--
--     RegisterAdapter("notify", "ox_lib", { send = function(message, kind) ... end })
--
-- Config picks one by name, or "auto" picks the first registered adapter whose detect()
-- returns true. The chosen adapter is checked against the contract below when the
-- resource starts, so a missing function is reported straight away by name instead of
-- failing later in game.
-------------------------------------------------------------------------------------------

local side = IsDuplicityVersion() and "server" or "client"

-- What each kind of adapter must provide, per side
local contract = {
	framework = {
		client = {
			"onPlayerLoaded", -- onPlayerLoaded(callback): call callback when the player's character has loaded
			"showPrompt", -- showPrompt(text) -> boolean: show "Press [E] to ..." until hidePrompt; false if it can't
			"hidePrompt", -- hidePrompt()
		},
		server = {
			"getIdentifier", -- getIdentifier(playerId) -> string?: the id vehicles are owned by in the database
			"getPlayerNames", -- getPlayerNames() -> { [playerId] = name }
			"getJob", -- getJob(playerId) -> { name = string, grade = any }?
			"getBalance", -- getBalance(playerId, account: "cash" | "bank" | ...) -> number
			"removeMoney", -- removeMoney(playerId, account, amount) -> boolean
		},
	},
	-- One entry per query the server runs: { query = "SQL..." }
	queries = {
		server = {
			"SqlGetAllVehicles",
			"SqlGetVehicle",
			"SqlGetVehicleByPlate",
			"SqlSetVehicleStored",
			"SqlSaveAndStoreVehicle",
			"SqlSetVehicleName",
			"SqlTransferOwnership",
			"SqlImpoundVehicle",
			"SqlAddImpoundEntry",
			"SqlGetImpoundedPlayerVehicles",
			"SqlGetActiveImpoundByPlate",
			"SqlReleaseImpoundVehicle",
		},
	},
	notify = {
		client = {
			"send", -- send(message: string, kind?: "info" | "success" | "error")
		},
	},
	keys = {
		server = {
			"give", -- give(playerId: number, plate: string, lifetime: "permanent" | "temporary")
			"remove", -- remove(playerId: number, plate: string); may do nothing if unsupported
		},
	},
}

local adapters = {} -- [kind] = { [name] = impl }
local registrationOrder = {} -- [kind] = { name, ... } so "auto" is predictable

function RegisterAdapter(kind, name, impl)
	adapters[kind] = adapters[kind] or {}
	registrationOrder[kind] = registrationOrder[kind] or {}

	if not adapters[kind][name] then
		table.insert(registrationOrder[kind], name)
	end
	adapters[kind][name] = impl
end

function HasAdapter(kind, name)
	return adapters[kind] ~= nil and adapters[kind][name] ~= nil
end

local function availableNames(kind)
	return table.concat(registrationOrder[kind] or {}, ", ")
end

--- Pick, check and start an adapter.
-- @param kind     string  "framework", "notify", "keys", ...
-- @param wanted   string  adapter name, or "auto"
-- @param fallback string? adapter to use when "auto" finds nothing
-- @return table, string   the adapter and the name it was registered under
function LoadAdapter(kind, wanted, fallback)
	local available = adapters[kind] or {}
	local name = wanted

	if wanted == nil or wanted == "auto" then
		name = fallback
		for _, candidate in ipairs(registrationOrder[kind] or {}) do
			local impl = available[candidate]
			if impl.detect and impl.detect() then
				name = candidate
				break
			end
		end
	end

	local impl = available[name]
	if not impl then
		error(
			("[htb_garage] No %s adapter called '%s'. Available: %s"):format(kind, tostring(name), availableNames(kind)),
			0
		)
	end

	local missing = {}
	for _, field in ipairs((contract[kind] or {})[side] or {}) do
		if impl[field] == nil then
			missing[#missing + 1] = field
		end
	end
	if #missing > 0 then
		error(
			("[htb_garage] The %s adapter '%s' is missing: %s"):format(kind, name, table.concat(missing, ", ")),
			0
		)
	end

	if impl.init then
		impl.init()
	end

	print(("[htb_garage] %s: using '%s'"):format(kind, name))
	return impl, name
end
