fx_version 'cerulean'
game 'gta5'

author 'CUK'
description 'Character Saving Bridge'
version '1.0.0'

shared_script '@fivem-appearance/shared/config.lua' -- To use their config

client_scripts {
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

dependencies {
    'oxmysql',
    'fivem-appearance'
}