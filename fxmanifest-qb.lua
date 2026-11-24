fx_version("cerulean")
game("gta5")

author("Harry The Bastard")
version("2.1.0")
description("A better garage system")
lua54("yes")

ui_page("ui/index.html")

-- Switch to this ui_page and uncomment disable_nui_csp when you
-- need live updates in FiveM for debugging layout changes
-- ui_page 'http://127.0.0.1:5175/index.html'

-- -- THIS is critical to allow remote URLs:
-- disable_nui_csp 'yes'

files({
	"UI/index.html",
})

shared_scripts({
	"@qb-core/shared/locale.lua",

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
	"FrameworkSpecific/Interfaces.lua",
	"FrameworkSpecific/Server/*.lua",
	"FrameworkSpecific/Setup_Server.lua",
	"FrameworkSpecific/SQL/*.lua",
	"Server/main.lua",
})

client_scripts({
	"Config.lua",
	"Configs/*.lua",
	"FrameworkSpecific/Interfaces.lua",
	"VehicleStuff.lua",
	"FrameworkSpecific/Client/*.lua",
	"FrameworkSpecific/Setup_Client.lua",
	"Client/utils.lua",
	"Client/impound.lua",
	"Client/main.lua",
})

dependency("qb-core")
