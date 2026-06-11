fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rde_sleepmod'
author 'Red Dragon Elite | SerpentsByte'
description 'Next-Gen Sleep System - Proximity Loading | GlobalState Sync | ox_core'
version '1.2.4'

dependencies {
    '/server:7290',
    'oxmysql',
    'ox_lib',
    'ox_core',
    'ox_inventory',
    'ox_target',
}

shared_scripts {
    '@ox_lib/init.lua',
    '@ox_core/lib/init.lua',
    'config.lua',
}

client_scripts {
    'client.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua',
}
