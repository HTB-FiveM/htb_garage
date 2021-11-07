fx_version 'cerulean'
game 'gta5'

author 'Harry The Bastard'
version '1.0.0'
description 'A better garage system'

ui_page 'ui/index.html'

files {
    'UI/index.html',
	'UI/css/bootstrap-5.1.3.css',
	'UI/css/stylesheet.css',
	'UI/js/bootstrap.bundle-5.1.3.js',
	'UI/js/script.js',
	'UI/js/vue.min.js'
}

shared_scripts {
	-- Uncomment if you're using ESX-Legacy
    --'@es_extended/imports.lua',
	'common.lua',
	'Config.lua',

	-- Uncomment if you're using QBCore
	'@qb-core/import.lua'

}

server_scripts {
	--'@mysql-async/lib/MySQL.lua',
	--'@oxmysql/lua/lib/MySQL.lua',
	'@oxmysql/lib/MySQL.lua',
	'locale.lua',
	'locales/*',
	'Server/utils.lua',
	'FrameworkSpecific/Server/*.lua',
	--'FrameworkSpecific/server_setup.lua',
	'Server/main.lua'
}

client_scripts {
	'locale.lua',
	'locales/*',
	'Configs/*.lua',
	'VehicleStuff.lua',
	'FrameworkSpecific/Client/*.lua',
	--'FrameworkSpecific/client_setup.lua',
	'Impound.lua',
	'Client/main.lua'

}



