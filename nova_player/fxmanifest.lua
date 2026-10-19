fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'nova_player'
author 'Vexora'
description 'Niveaux / XP, temps de jeu, système nouveaux joueurs, kit de départ'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    '@es_extended/imports.lua',
    '@nova_core/lib/shared.lua',
    'config.lua',
}

client_script 'client/main.lua'
server_script 'server/main.lua'
