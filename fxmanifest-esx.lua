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
	"@es_extended/imports.lua",
	"@es_extended/locale.lua",

	"locales/locale.lua",
	"locales/en.lua",
	"common.lua",
})

server_scripts({
	"@mysql-async/lib/MySQL.lua",
	"Config.lua",
	"Server/utils.lua",
	"FrameworkSpecific/Interfaces.lua",
	"FrameworkSpecific/Server/*.lua",
	"FrameworkSpecific/Setup_Server.lua",
	"FrameworkSpecific/SQL/*.lua",
	"Server/main.lua",
})

client_scripts({
	"Config.lua",
	"Configs/*.lua",
	"FrameworkSpecific/Interfaces.lua";
	"VehicleStuff.lua",
	"FrameworkSpecific/Client/*.lua",
	"FrameworkSpecific/Setup_Client.lua",
	"Impound.lua",
	"Client/main.lua",
})

dependency 'es_extended'
