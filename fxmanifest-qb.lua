fx_version("cerulean")
game("gta5")

author("Harry The Bastard")
version("1.3.0")
description("A better garage system")
lua54 'yes'

ui_page("ui/index.html")

files({
	"UI/index.html",
})

shared_scripts({
	"@qb-core/shared/locale.lua",

	"locales/locale.lua",
	"locales/en.lua",
	"common.lua",
})

server_scripts({
	"@mysql-async/lib/MySQL.lua",
	"Config.lua",
	"Server/utils.lua",
	"FrameworkSpecific/Server/*.lua",
	"FrameworkSpecific/SQL/*.lua",
	--'FrameworkSpecific/server_setup.lua',
	"Server/main.lua",
})

client_scripts({
	"Config.lua",
	"Configs/*.lua",
	"VehicleStuff.lua",
	"FrameworkSpecific/Client/*.lua",
	--'FrameworkSpecific/client_setup.lua',
	"Impound.lua",
	"Client/main.lua",
})

dependency 'qb-core'
