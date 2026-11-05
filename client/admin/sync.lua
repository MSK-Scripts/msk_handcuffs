AdminSync = AdminSync or {}

-- Applies DB-authoritative settings live. The client's cuff visuals/controls read
-- Config.* directly, so overwriting the keys is enough. Static hooks (functions,
-- Config.Method, Config.Props) are never part of the settings payload and stay
-- as shipped in config/static.lua.
local function applyDefs(defs)
    if type(defs) ~= 'table' then return end
    if type(defs.settings) == 'table' then
        for k, v in pairs(defs.settings) do Config[k] = v end
        -- Let dependent systems (target labels/language, etc.) rebuild.
        TriggerEvent('msk_handcuffs:settingsApplied')
    end
end

AdminSync.Apply = applyDefs

-- Server broadcast after any admin mutation.
RegisterNetEvent('msk_handcuffs:syncDefinitions', function(defs)
    applyDefs(defs)
end)

-- Pull the authoritative settings once on join (covers edits made before the
-- player connected; the static client config may otherwise be stale).
CreateThread(function()
    while not (MSK and MSK.Player and MSK.Player.serverId) do Wait(250) end
    Wait(1500) -- let client/main.lua bootstrap build first
    local defs = MSK.Trigger('msk_handcuffs:admin:getDefinitions')
    applyDefs(defs)
end)
