fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'atmhack'
description 'ATM hacking using the datacrack minigame + ox_target + ox_inventory'
version '2.0.0'

shared_scripts {
    '@es_extended/imports.lua',
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

dependencies {
    'es_extended',
    'ox_lib',
    'ox_target',
    'ox_inventory',
    'datacrack'
}
