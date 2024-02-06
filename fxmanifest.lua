fx_version("cerulean")
game("gta5")

author("Harry The Bastard")
version("1.3.0")
description("A better garage system")
lua54 'yes'

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
	-- "@es_extended/imports.lua",
	-- "@es_extended/locale.lua",

	-- Uncomment if you're using QB Core
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

--dependency 'es_extended'
dependency 'qb-core'
