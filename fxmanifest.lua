fx_version 'cerulean'
games { 'gta5' }

author 'Musiker15 - MSK Scripts'
name 'msk_handcuffs'
description 'Realistic Handcuffs — ESX & QBCore, in-game admin dashboard'
version '3.1.1'

lua54 'yes'

data_file 'DLC_ITYP_REQUEST' 'stream/prop_gaffertape.ytyp'

shared_scripts {
    '@msk_core/import.lua',
    'shared/admin_perms.lua',
    'config/settings.lua',
    'config/static.lua',
    'translation.lua',
    'shared/utils.lua',
}

client_scripts {
    'client/props.lua',
    'client/ankletracker.lua',
    'client/actions.lua',
    'client/main.lua',
    'client/target.lua',

    -- Admin dashboard
    'client/admin/main.lua',
    'client/admin/nui.lua',
    'client/admin/sync.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/database.lua',
    'server/discord.lua',
    'server/main.lua',
    'server/commands.lua',
    'server/versionchecker.lua',

    -- Admin dashboard (boot.lua must stay LAST: it depends on all of the above)
    'server/admin/store.lua',
    'server/admin/permissions.lua',
    'server/admin/seed.lua',
    'server/admin/api.lua',
    'server/admin/command.lua',
    'server/admin/boot.lua',
}

ui_page 'html/index.html'

files {
    'html/**/*.*',
}

-- msk_core detects the framework (ESX / QBCore / ox_core) itself.
-- es_extended / qb-core are therefore NOT hard dependencies here.
dependencies {
    'oxmysql',
    'msk_core',
}
