ui_page 'html/index.html'
client_script {
    "@vrp/lib/utils.lua",
    "lib/Tunnel.lua",
    "lib/Proxy.lua",
    'config.lua',
    'client.lua'
}
server_script {
    "@vrp/lib/utils.lua",
    '@mysql-async/lib/MySQL.lua',
    "lib/Tunnel.lua",
    "lib/Proxy.lua",
    'config.lua',
    'server.lua'
}
files {
    'html/face/*.*',
    'html/img/*.*',
    'html/img/body/*.*',
    'html/img/vehicle/*.*',
    'html/assets/style/*.*',
    'html/assets/fonts/*.*',
    'html/assets/javascript/*.*',
    'html/index.html',
}



