-- Admin dashboard boot: create tables, seed once, load DB into Config, register
-- the command. Runs as its own onResourceStart handler; waits for oxmysql the
-- same way server/database.lua does.

local function createTables()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `msk_handcuffs_settings` (
            `skey` varchar(80) NOT NULL,
            `svalue` longtext DEFAULT NULL,
            PRIMARY KEY (`skey`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `msk_handcuffs_permissions` (
            `group_name` varchar(80) NOT NULL,
            `perms` longtext DEFAULT NULL,
            PRIMARY KEY (`group_name`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
end

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    CreateThread(function()
        while GetResourceState('oxmysql') ~= 'started' do Wait(100) end

        createTables()
        AdminSeed.Run(false)
        AdminStore.LoadAll()
        -- Needs the loaded permission matrix, so it has to run after LoadAll().
        AdminPerms.EnsureAces()
        AdminCommand.Register(Config.adminCommand)

        -- On a live restart, push the freshly loaded settings to everyone already
        -- connected so their config-driven visuals/controls match the DB.
        AdminApi.Broadcast()

        print(('^2[msk_handcuffs]^0 Admin dashboard ready — command: ^5/%s^0'):format(Config.adminCommand or 'handcuffadmin'))
    end)
end)
