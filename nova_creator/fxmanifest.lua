fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'nova_creator'
author 'Vexora'
description 'Création d\'identité, créateur de personnage et magasins de vêtements en menus RageUI (NovaMenu)'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    '@es_extended/imports.lua',
    '@nova_core/lib/shared.lua',
    'config.lua',
}

client_scripts {
    '@nova_core/lib/menu.lua',
    'client/utils.lua',
    'client/clothing.lua',
    'client/barber.lua',
    'client/character.lua',
    'client/identity.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

dependencies { 'nova_core', 'ox_lib', 'illenium-appearance', 'esx_identity' }
