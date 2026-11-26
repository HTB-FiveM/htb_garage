fx_version("cerulean")
game("gta5")

author("Harry The Bastard")
version("2.3.2")
description("A better garage system")
lua54("yes")

ui_page("UI/index.html")

-- Switch to this ui_page and uncomment disable_nui_csp when you
-- need live updates in FiveM for debugging layout changes
-- ui_page 'http://127.0.0.1:5175/index.html'

-- -- THIS is critical to allow remote URLs:
-- disable_nui_csp 'yes'

files({
	"UI/index.html",
})

shared_scripts({
	"@es_extended/imports.lua",
	"@es_extended/locale.lua",

	"locales/locale.lua",
	"locales/en.lua",
	"common.lua",
	"constants.lua",
})

server_scripts({
	"@oxmysql/lib/MySQL.lua",
	"Config.lua",
	"Configs/*.lua",
	"Server/utils.lua",
	"Server/security.lua",
	"Bridge/registry.lua",
	"Bridge/framework/server/*.lua",
	"Bridge/queries/*.lua",
	"Bridge/keys/*.lua",
	"Bridge/init_server.lua",
	"Server/main.lua",
})

client_scripts({
	"Config.lua",
	"Configs/*.lua",
	"VehicleStuff.lua",
	"Bridge/registry.lua",
	"Bridge/framework/client/*.lua",
	"Bridge/notify/*.lua",
	"Bridge/init_client.lua",
	"Client/utils.lua",
	"Client/zones.lua",
	"Client/impound.lua",
	"Client/main.lua",
})

dependency("es_extended")
