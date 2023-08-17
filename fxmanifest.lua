fx_version "bodacious"
game "gta5"

client_script 'client.lua'

shared_scripts {
	'config.lua',
	'json.lua'
}

server_scripts {
    "@oxmysql/lib/MySQL.lua",
	'server.lua',
}

ui_page('web/index.html')

files {
    'json.lua',
    'web/index.html',
    'web/script.js',
    'web/style.css'
}