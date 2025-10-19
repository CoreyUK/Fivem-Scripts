fx_version 'bodacious'
game 'gta5'

author 'CoreyUK'
description 'Adds durability and the need to change tires with UI and server sync.'
version '3.1.0'

-- Client scripts must load config first
client_scripts {
    'config.lua',
    'client.lua'
}

server_scripts {
    'server.lua'
}

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/style.css',
    'ui/script.js'
}
