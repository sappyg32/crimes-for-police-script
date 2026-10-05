fx_version 'cerulean'
game 'gta5'

name 'vihtal_houserobbery'
author 'Vihtal'
description 'House Robbery System for ESX Legacy with noise mechanics, ox_target, and ox_inventory support'
version '1.1.0'
repository 'https://github.com/vihtal/vihtal_houserobbery'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

dependencies {
    'es_extended',
    'ox_lib',
    'ox_inventory',
    'ox_target'
}
