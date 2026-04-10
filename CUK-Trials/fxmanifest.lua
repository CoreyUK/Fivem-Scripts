fx_version 'cerulean'
game 'gta5'

author 'CUK'
description 'Custom Time Trials'
version '1.1.0'

lua54 'yes'

ui_page 'index.html'

files {
    'index.html'
}

shared_scripts {
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

dependencies {
    'oxmysql'
}
