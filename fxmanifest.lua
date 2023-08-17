fx_version "bodacious"
game "gta5"
name 'fezz_impound'
author 'fbfezz & real_benzo'
version '1.0.0'
repository   'https://github.com/FBFezz/fezz_impound'

shared_scripts {'config.lua','json.lua'}

server_scripts {"@oxmysql/lib/MySQL.lua",'bridge/**/server.lua', 'server.lua'}

client_script {'bridge/**/client.lua', 'client.lua'}

ui_page('web/index.html')

files {
    'json.lua',
    'web/index.html',
    'web/script.js',
    'web/style.css'
}