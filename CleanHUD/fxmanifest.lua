fx_version 'adamant'
game 'gta5'

author 'GESUS'
description 'A sleek and modern info HUD for FiveM.'
version '1.0.0'
lua54 'on'

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

shared_script {
    '@ox_lib/init.lua',
    'config.lua'
}

files {
    'web/style.css',
    'web/script.js',
    'web/index.html',
}

ui_page 'web/index.html'

