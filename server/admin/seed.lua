AdminSeed = AdminSeed or {}

local function isSeeded()
    local row = MySQL.single.await("SELECT `skey` FROM `msk_handcuffs_settings` WHERE `skey` = '__seeded__'")
    return row ~= nil
end

local function setSetting(key, value)
    MySQL.insert.await(
        'INSERT INTO `msk_handcuffs_settings` (`skey`, `svalue`) VALUES (?, ?) ' ..
        'ON DUPLICATE KEY UPDATE `svalue` = VALUES(`svalue`)',
        { key, json.encode(value) }
    )
end

----------------------------------------------------------------
-- One-time import of the static config into the DB.
----------------------------------------------------------------
function AdminSeed.Run(force)
    if not force and isSeeded() then return false end

    -- Settings (editable whitelist).
    for _, key in ipairs(AdminPerms.SETTINGS_KEYS) do
        if Config[key] ~= nil then
            setSetting(key, Config[key])
        end
    end

    -- dashboardGroups is permission-managed but still persisted as a setting.
    setSetting('dashboardGroups', Config.dashboardGroups or {})

    -- Default permission groups: admin = all, mod = view-only.
    local adminPerms = AdminPerms.AllPerms()
    local modPerms = { ['players.view'] = true }
    MySQL.insert.await(
        'INSERT INTO `msk_handcuffs_permissions` (`group_name`, `perms`) VALUES (?, ?) ' ..
        'ON DUPLICATE KEY UPDATE `perms` = VALUES(`perms`)',
        { 'admin', json.encode(adminPerms) }
    )
    MySQL.insert.await(
        'INSERT INTO `msk_handcuffs_permissions` (`group_name`, `perms`) VALUES (?, ?) ' ..
        'ON DUPLICATE KEY UPDATE `perms` = VALUES(`perms`)',
        { 'mod', json.encode(modPerms) }
    )

    -- Mark as seeded.
    setSetting('__seeded__', os.time())

    print('^2[msk_handcuffs]^0 Admin seed complete (settings/permissions imported into DB).')
    return true
end
