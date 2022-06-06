fx_version("cerulean")
game("gta5")

author("Harry The Bastard")
version("1.0.0")
description("A better garage system")

ui_page("ui/index.html")

files({
	"UI/index.html",
	"UI/css/bootstrap-4.6.css",
	"UI/css/stylesheet.css",
	"UI/js/bootstrap.bundle-4.6.js",
	"UI/js/jquery-3.5.1.js",
	"UI/js/script.js",
	"UI/js/vue.min.js",
})

shared_scripts({
	-- Uncomment if you're using ESX-Legacy
	"@es_extended/imports.lua",
	"common.lua",
})

server_scripts({
	"@mysql-async/lib/MySQL.lua",
	"@es_extended/locale.lua",
	"locales/en.lua",
	"Config.lua",
	"Server/utils.lua",
	"FrameworkSpecific/Server/*.lua",
	--'FrameworkSpecific/server_setup.lua',
	"Server/main.lua",
})

client_scripts({
	"@es_extended/locale.lua",
	"locales/en.lua",
	"Config.lua",
	"Configs/*.lua",
	"VehicleStuff.lua",
	"FrameworkSpecific/Client/*.lua",
	--'FrameworkSpecific/client_setup.lua',
	"Impound.lua",
	"Client/main.lua",
})
