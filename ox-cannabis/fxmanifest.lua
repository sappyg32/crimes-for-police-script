fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'you'
description 'Harvestable cannabis field + weed distributor (networked field)'
version '1.1.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

dependencies {
    'ox_lib',
    'ox_target',
    'ox_inventory'
}
