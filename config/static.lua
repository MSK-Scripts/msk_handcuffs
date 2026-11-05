----------------------------------------------------------------
-- STATIC CONFIG (code hooks)
--
-- These are NOT DB-managed: they are Lua functions / prop hashes / the control
-- blacklist that can't be serialised into the settings table. Loaded AFTER
-- config/settings.lua so it can reference Config.Voice / Config.Tape / the item
-- names defined there.
----------------------------------------------------------------

----------------------------------------------------------------
-- luxu_admin integration (for the admin dashboard access).
-- luxu_admin v2 keeps its staff groups internally, not as FiveM ACE principals,
-- so a normal IsPlayerAceAllowed('group.x') check does not see them. When enabled,
-- the dashboard also resolves a player's group through luxu_admin's export
-- (getPlayerStaffGroup). The resolved group is matched against your dashboard
-- groups by name (group.admin always = full access).
Config.LuxuAdmin = {
    enable = 'auto',          -- 'auto' (on when the resource is started), true, or false
    resource = 'luxu_admin',  -- change if you renamed the resource
    requireDuty = false,      -- true = the staff member must be ON DUTY to be recognized

    -- Optional: map luxu_admin staff group names to your dashboard groups.
    -- Unmapped groups are matched by their own (lowercased) name.
    -- Example: a luxu_admin 'owner' should get full access -> map it to 'admin'.
    groupMap = {
        -- ['owner'] = 'admin',
        -- ['superadmin'] = 'admin',
    },
}
----------------------------------------------------------------
-- !!! This function runs clientside AND serverside !!!
Config.Notification = function(source, message, typ)
    if IsDuplicityVersion() then -- serverside
        MSK.Notification(source, { title = 'MSK Handcuffs', message = message, type = typ, duration = 5000 })
    else -- clientside
        MSK.Notification({ title = 'MSK Handcuffs', message = message, type = typ, duration = 5000 })
    end
end

-- Deactivate the radio channel when someone gets handcuffed (clientside)
Config.SetRadioChannel = function()
    if not Config.Voice.enable then return end
    logging('debug', 'Config.SetRadioChannel')

    if Config.Voice.voice == 'salty' then
        exports["saltychat"]:SetRadioChannel(nil, true)
    elseif Config.Voice.voice == 'pma' then
        exports["pma-voice"]:setVoiceProperty('radioEnabled', false)
        exports["pma-voice"]:SetRadioChannel(0)
    end
end

-- Mute players for Config.Tape // runs clientside AND serverside
Config.MutePlayer = function(source, state)
    if not Config.Tape.enable then return end

    if IsDuplicityVersion() then
        -- serverside
        Player(source).state:set('muted', state, true)
        Player(source).state:set('SaltyChat_IsAlive', state, true)
        MumbleSetPlayerMuted(source, state)

        if Config.Voice.voice == 'salty' then
            exports["saltychat"]:SetPlayerAlive(source, not state)
        end
    else
        -- clientside
        Player(source).state:set('muted', state, true)
        Player(source).state:set('SaltyChat_IsAlive', state, true)

        if Config.Voice.voice == 'pma' then
            exports["pma-voice"]:toggleMutePlayer(source)
        end
    end
end
----------------------------------------------------------------
-- !!! This function is clientside ONLY and runs inside a per-frame thread !!!
Config.Method = 'blacklist' -- Set to 'whitelist' or 'blacklist'

-- Triggered every frame while the player is cuffed
Config.Handcuffed = function()
    if Config.Method == 'whitelist' then
        EnableControlAction(0, 1, true) -- Camera Movement
        EnableControlAction(0, 2, true) -- Camera Movement
        EnableControlAction(0, 245, true) -- T (Chat)
        EnableControlAction(0, 23, true) -- F (Enter Vehicle)
        EnableControlAction(0, 75, true) -- F (Exit Vehicle)
    elseif Config.Method == 'blacklist' then
        DisableControlAction(0, 24, true) -- Attack
        DisableControlAction(0, 257, true) -- Attack 2
        DisableControlAction(0, 25, true) -- Aim
        DisableControlAction(0, 263, true) -- Melee Attack 1
        DisableControlAction(0, 45, true) -- Reload

        DisableControlAction(0, 22, true) -- Jump
        DisableControlAction(0, 44, true) -- Cover
        DisableControlAction(0, 37, true) -- Select Weapon

        DisableControlAction(0, 288, true) -- F1
        DisableControlAction(0, 289, true) -- F2
        DisableControlAction(0, 170, true) -- F3
        DisableControlAction(0, 167, true) -- F6
        DisableControlAction(0, 73, true) -- X
        DisableControlAction(2, 199, true) -- P

        DisableControlAction(0, 59, true) -- Disable steering in vehicle
        DisableControlAction(0, 71, true) -- Disable driving forward in vehicle
        DisableControlAction(0, 72, true) -- Disable reversing in vehicle

        DisableControlAction(2, 36, true) -- Disable going stealth
        DisableControlAction(0, 47, true) -- Disable weapon
        DisableControlAction(0, 264, true) -- Disable melee
        DisableControlAction(0, 257, true) -- Disable melee
        DisableControlAction(0, 140, true) -- Disable melee
        DisableControlAction(0, 141, true) -- Disable melee
        DisableControlAction(0, 142, true) -- Disable melee
        DisableControlAction(0, 143, true) -- Disable melee
    end
end
----------------------------------------------------------------
Config.Props = {
    -- Use `` and NOT '' or ""
    -- Example: ['itemName'] = `prop`
    -- Set ['itemName'] = nil to deactivate the prop

    ['cuffs'] = `p_cs_cuffs_02_s`,
    ['cable_ties'] = `p_cs_cuffs_02_s`,

    ['hardcuff'] = nil,

    ['cuff_keys'] = `prop_cuff_keys_01`,
    ['scissors'] = `prop_cuff_keys_01`,

    [Config.AnkleTracker.item] = nil,
    [Config.HeadBag.item] = `prop_money_bag_01`,
    [Config.Tape.item] = `prop_gaffertape`,
}
----------------------------------------------------------------
exports('Config', function()
    return Config
end)
