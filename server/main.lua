----------------------------------------------------------------
-- Server core — authoritative validation + statebag replication
--
-- Security model:
--   * The client only ever SENDS REQUESTS. The server decides everything:
--     distance (OneSync coords), item possession (MSK.HasPlayerItem), job
--     restrictions and current status (in-memory authoritative `Handcuffs`).
--   * Status is replicated via player statebags (single source of truth that
--     any resource / client can read). Clients never write status statebags.
--   * Timer + death-uncuff run server-side (the old client-triggered
--     `autoUncuff` self-unlock exploit is gone).
----------------------------------------------------------------

Cuffs = {}                 -- server API used by commands.lua
activeAnkletrackers = {}   -- [src] = { player, netId, coords }
escortedPlayers = {}       -- [targetId] = officerSrc
local timers = {}          -- [identifier] = MSK.Timeout id

----------------------------------------------------------------
-- Small helpers
----------------------------------------------------------------
local function setState(src, key, value)
    Player(src).state:set(key, value, true) -- replicated
end

-- Push the whole authoritative status of `src` into its statebags.
local function syncState(src, d)
    d = d or {}
    -- cuffItem BEFORE isHandcuffed so the prop model is available when the
    -- client's isHandcuffed change handler fires.
    setState(src, StateKeys.cuffItem, d.cuffItem or false)
    setState(src, StateKeys.isHardcuffed, d.isHardcuffed or false)
    setState(src, StateKeys.hasAnkleTracker, d.hasAnkleTracker or false)
    setState(src, StateKeys.hasHeadbag, d.hasHeadbag or false)
    setState(src, StateKeys.hasTape, d.hasTape or false)
    setState(src, StateKeys.isHandcuffed, d.isCuffed or false)
    setState(src, StateKeys.inventoryCuffed, d.isCuffed or false) -- ox_inventory
end

local function distanceBetween(a, b)
    local pa = GetEntityCoords(GetPlayerPed(a))
    local pb = GetEntityCoords(GetPlayerPed(b))
    return #(pa - pb)
end

-- Safe job lookup (a player may be mid-disconnect / not fully loaded).
local function getJob(playerId)
    local ok, job = pcall(MSK.GetPlayerJob, { source = playerId })
    return ok and job or 'unemployed'
end

-- Validate an officer -> target interaction. Returns xPlayer, xTarget or nil.
local function validate(src, targetId, opts)
    opts = opts or {}
    targetId = tonumber(targetId)
    if not targetId or src == targetId then return end

    local xPlayer = MSK.GetPlayerFromId(src)
    local xTarget = MSK.GetPlayerFromId(targetId)
    if not xPlayer or not xTarget then return end

    if distanceBetween(src, targetId) > Config.MaxDistance then
        Config.Notification(src, T('no_player_nearby'), 'error')
        return
    end

    return xPlayer, xTarget
end

----------------------------------------------------------------
-- Item label lookup (for notifications) — best effort across inventories.
----------------------------------------------------------------
local itemSource
local function getItemSource()
    if itemSource ~= nil then return itemSource end
    itemSource = false
    if GetResourceState('ox_inventory') == 'started' then
        local ok, items = pcall(function() return exports.ox_inventory:Items() end)
        if ok and type(items) == 'table' then itemSource = { kind = 'ox', items = items } end
    elseif GetResourceState('es_extended') == 'started' then
        local ok, core = pcall(function() return exports['es_extended']:getSharedObject() end)
        if ok and core then itemSource = { kind = 'esx', core = core } end
    elseif GetResourceState('qb-core') == 'started' then
        local ok, core = pcall(function() return exports['qb-core']:GetCoreObject() end)
        if ok and core then itemSource = { kind = 'qb', core = core } end
    end
    return itemSource
end

-- Human-readable label for an item name (falls back to the name itself).
local function itemLabel(name)
    if type(name) ~= 'string' or name == '' then return name or '?' end
    local f = getItemSource()
    if f then
        if f.kind == 'ox' then
            local it = f.items[name]
            if it and it.label then return it.label end
        elseif f.kind == 'esx' then
            local items = f.core.Items
            if items and items[name] and items[name].label then return items[name].label end
        elseif f.kind == 'qb' then
            local shared = f.core.Shared
            if shared and shared.Items and shared.Items[name] and shared.Items[name].label then
                return shared.Items[name].label
            end
        end
    end
    return name
end
Cuffs._itemLabel = itemLabel

----------------------------------------------------------------
-- Item resolution
--
-- cuff / hardcuff: the DEFAULT item is always allowed; the job's item is
-- allowed on top (when RestrictItems is on). The officer's actually-used item
-- (claimedItem) wins when it is allowed, otherwise the first allowed item they
-- carry is used.
-- uncuff: dictated purely by the cuff item — only the matching remove item(s)
-- from Config.ItemSettings may open it (admin-cuffed = any uncuff item).
----------------------------------------------------------------
local function cuffCandidates(xPlayer, action)
    local out, seen = {}, {}
    local function add(it)
        if type(it) == 'string' and it ~= '' and not seen[it] then
            seen[it] = true
            out[#out + 1] = it
        end
    end

    local R = Config.RestrictItems
    if R.enable then
        local key = action == 'cuff' and 'cuffItem' or 'hardcuffItem'
        add((R.defaultItems or {})[key]) -- default items are ALWAYS usable
        local jobset = R.jobItems[xPlayer.job.name]
        if jobset then add(jobset[key]) end
    else
        for _, it in ipairs(action == 'cuff' and Config.cuffItems or Config.hardcuffItems) do add(it) end
    end
    return out
end

-- Returns item OR nil + the item to name in the "missing item" notification.
local function resolveCuffItem(xPlayer, src, action, claimedItem)
    local candidates = cuffCandidates(xPlayer, action)

    if claimedItem and MSK.Table.Contains(candidates, claimedItem) and MSK.HasPlayerItem(src, claimedItem) then
        return claimedItem
    end
    for _, it in ipairs(candidates) do
        if MSK.HasPlayerItem(src, it) then return it end
    end

    local need = (claimedItem and MSK.Table.Contains(candidates, claimedItem)) and claimedItem or candidates[1]
    return nil, need
end

local function uncuffCandidates(targetState)
    if targetState == 'isAdminCuffed' then return Config.uncuffItems end
    return Config.ItemSettings[targetState] or {}
end

-- An option (ankletracker / headbag / tape) is allowed if the DEFAULT set allows
-- it OR the officer's job allows it. Default options are always available.
local function jobAllows(xPlayer, optionKey)
    if not Config.RestrictItems.enable then return true end
    if (Config.RestrictItems.defaultItems or {})[optionKey] == true then return true end
    local jobset = Config.RestrictItems.jobItems[xPlayer.job.name]
    return (jobset and jobset[optionKey] == true) or false
end

local function broadcastSound(coords, sound, volume)
    if not Config.playSound.enable or not sound then return end
    TriggerClientEvent('msk_handcuffs:playSound', -1, coords, 5.0, sound, volume or 0.6)
end

----------------------------------------------------------------
-- Status readers (in-memory authoritative)
----------------------------------------------------------------
local function resolveIdentifier(player)
    if type(player) == 'number' then
        local x = MSK.GetPlayerFromId(player); return x and x.identifier
    elseif type(player) == 'table' then
        if player.identifier then return player.identifier end
        if player.source then local x = MSK.GetPlayerFromId(player.source); return x and x.identifier end
        if player.player then return player.player.identifier end
    end
end

function Cuffs.IsHandcuffed(player)
    local id = resolveIdentifier(player); if not id then return false end
    local d = Handcuffs[id]; if not d or not d.isCuffed then return false end
    if d.isAdminCuffed then return 'isAdminCuffed' end
    return d.cuffItem or true
end
exports('getIsPlayerHandcuffed', Cuffs.IsHandcuffed)

function Cuffs.IsHardcuffed(player)
    local id = resolveIdentifier(player); if not id then return false end
    local d = Handcuffs[id]; if not d or not d.isHardcuffed then return false end
    if d.isAdminCuffed then return 'isAdminCuffed' end
    return d.hardcuffItem or true
end
exports('getIsPlayerHardcuffed', Cuffs.IsHardcuffed)

function Cuffs.HasAnkleTracker(player)
    local id = resolveIdentifier(player); if not id then return false end
    return Handcuffs[id] and Handcuffs[id].hasAnkleTracker or false
end
exports('gethasPlayerAnkleTracker', Cuffs.HasAnkleTracker)

function Cuffs.HasHeadbag(player)
    local id = resolveIdentifier(player); if not id then return false end
    return Handcuffs[id] and Handcuffs[id].hasHeadbag or false
end
exports('gethasPlayerHeadbag', Cuffs.HasHeadbag)

function Cuffs.HasTape(player)
    local id = resolveIdentifier(player); if not id then return false end
    return Handcuffs[id] and Handcuffs[id].hasTape or false
end
exports('gethasPlayerTape', Cuffs.HasTape)

----------------------------------------------------------------
-- Timer (server-driven auto uncuff)
----------------------------------------------------------------
local function stopTimer(identifier)
    if timers[identifier] then
        MSK.Timeout.Clear(timers[identifier])
        timers[identifier] = nil
    end
end

local function startTimer(identifier)
    if not Config.Timer.enable then return end
    stopTimer(identifier)

    timers[identifier] = MSK.Timeout.Set(Config.Timer.time * 60000, function()
        timers[identifier] = nil
        local d = Handcuffs[identifier]
        if not d or not d.isCuffed then return end

        Cuffs.Clear(identifier)
        local x = MSK.GetPlayerFromIdentifier(identifier)
        if x then Config.Notification(x.source, T('uncuffed_timer'), 'info') end
    end)
end

----------------------------------------------------------------
-- State mutations
----------------------------------------------------------------
-- Clear cuff + hardcuff status for an identifier (online or not).
function Cuffs.Clear(identifier)
    local d = Handcuffs[identifier]
    if not d then return end

    d.isCuffed = false
    d.isHardcuffed = false
    d.isAdminCuffed = false
    d.cuffItem = nil
    d.hardcuffItem = nil
    Database.Save(identifier)
    stopTimer(identifier)

    local x = MSK.GetPlayerFromIdentifier(identifier)
    if x then syncState(x.source, Handcuffs[identifier]) end
end

local function applyCuff(xTarget, item)
    local d = Database.Ensure(xTarget.identifier)
    d.isCuffed = true
    if item then d.cuffItem = item else d.isAdminCuffed = true end
    Database.Save(xTarget.identifier)
    syncState(xTarget.source, d)
    startTimer(xTarget.identifier)
end

local function applyHardcuff(xTarget, item)
    local d = Database.Ensure(xTarget.identifier)
    d.isHardcuffed = true
    if item then d.hardcuffItem = item end
    Database.Save(xTarget.identifier)
    syncState(xTarget.source, d)
end

----------------------------------------------------------------
-- Request: cuff / hardcuff / uncuff
----------------------------------------------------------------
RegisterNetEvent('msk_handcuffs:request', function(targetId, action, claimedItem)
    local src = source
    local xPlayer, xTarget = validate(src, targetId)
    if not xPlayer then return end

    local targetState = Cuffs.IsHandcuffed({identifier = xTarget.identifier})
    local item

    if action == 'cuff' or action == 'hardcuff' then
        local need
        item, need = resolveCuffItem(xPlayer, src, action, claimedItem)
        if not item then
            return Config.Notification(src, T('not_hasItem_named', itemLabel(need)), 'error')
        end

        if action == 'cuff' then
            if targetState then
                return Config.Notification(src, T('player_already_cuffed'), 'error')
            end
            xPlayer.RemoveItem(item, 1)
            applyCuff(xTarget, item)
        else -- hardcuff
            if not targetState then
                return Config.Notification(src, T('has_no_handcuffs'), 'error')
            end
            xPlayer.RemoveItem(item, 1)
            applyHardcuff(xTarget, item)
        end

    elseif action == 'uncuff' then
        if not targetState then
            return Config.Notification(src, T('player_not_handcuffed'), 'error')
        end

        -- Only the item matching the cuff item may open it (Config.ItemSettings).
        -- Admin-cuffed accepts any uncuff item.
        local candidates = uncuffCandidates(targetState)
        if #candidates == 0 then
            return Config.Notification(src, T('wrong_uncuff_item'), 'error')
        end
        for _, it in ipairs(candidates) do
            if MSK.HasPlayerItem(src, it) then item = it break end
        end
        if not item then
            return Config.Notification(src, T('not_hasItem_named', itemLabel(candidates[1])), 'error')
        end

        -- Consume the uncuff item only when enabled (default: keep it, reusable).
        if Config.consumeUncuffItem then xPlayer.RemoveItem(item, 1) end

        -- Give cuff item(s) back to the officer per config.
        local d = Handcuffs[xTarget.identifier]
        if d then
            if d.cuffItem and Config.GiveCuffItemBack[d.cuffItem] then xPlayer.AddItem(d.cuffItem, 1) end
            if d.hardcuffItem and Config.GiveCuffItemBack[d.hardcuffItem] then xPlayer.AddItem(d.hardcuffItem, 1) end
        end

        Cuffs.Clear(xTarget.identifier)
    else
        return
    end

    broadcastSound(GetEntityCoords(GetPlayerPed(src)), Config.playSound[action], 0.6)
    DiscordLog.Action(xPlayer, xTarget, action)

    TriggerEvent('msk_handcuffs:handler', src, xTarget.source, action, item)
    TriggerClientEvent('msk_handcuffs:handler', xTarget.source, src, xTarget.source, action, item)
end)

----------------------------------------------------------------
-- Request: AnkleTracker (officer -> cuffed target)
----------------------------------------------------------------
local function activateTracker(xTarget)
    if activeAnkletrackers[xTarget.source] then return end
    local targetPed = GetPlayerPed(xTarget.source)

    activeAnkletrackers[xTarget.source] = {
        player = xTarget,
        netId  = NetworkGetNetworkIdFromEntity(targetPed),
        coords = GetEntityCoords(targetPed),
    }

    for _, playerId in ipairs(GetPlayers()) do
        if MSK.Table.Contains(Config.AnkleTracker.jobs, getJob(tonumber(playerId))) then
            TriggerClientEvent('msk_handcuffs:addBlipFromAnkletracker', tonumber(playerId), xTarget, activeAnkletrackers[xTarget.source])
        end
    end
end
Cuffs._activateTracker = activateTracker

local function removeTrackerBlips(src)
    if not activeAnkletrackers[src] then return end
    activeAnkletrackers[src] = nil

    for _, playerId in ipairs(GetPlayers()) do
        if MSK.Table.Contains(Config.AnkleTracker.jobs, getJob(tonumber(playerId))) then
            TriggerClientEvent('msk_handcuffs:removeBlipFromAnkletracker', tonumber(playerId), src)
        end
    end
end

RegisterNetEvent('msk_handcuffs:requestAnkletracker', function(targetId, remove)
    if not Config.AnkleTracker.enable then return end
    local src = source
    local xPlayer, xTarget = validate(src, targetId)
    if not xPlayer then return end
    if not jobAllows(xPlayer, 'enableAnkletracker') then return end

    if not Cuffs.IsHandcuffed({identifier = xTarget.identifier}) then
        return Config.Notification(src, T('has_no_handcuffs'), 'error')
    end

    local d = Database.Ensure(xTarget.identifier)
    local activate = not d.hasAnkleTracker
    local requiredItem = activate and Config.AnkleTracker.item or Config.AnkleTracker.removeItem

    if not MSK.HasPlayerItem(src, requiredItem) then
        return Config.Notification(src, T('not_hasItem_named', itemLabel(requiredItem)), 'error')
    end

    if activate then
        xPlayer.RemoveItem(Config.AnkleTracker.item, 1)
        d.hasAnkleTracker = true
        activateTracker(xTarget)
        Config.Notification(xTarget.source, T('ankletracker_activated'), 'info')
    else
        if Config.AnkleTracker.consumeRemoveItem then xPlayer.RemoveItem(Config.AnkleTracker.removeItem, 1) end
        d.hasAnkleTracker = false
        removeTrackerBlips(xTarget.source)
        Config.Notification(xTarget.source, T('ankletracker_deactivated'), 'info')
    end

    Database.Save(xTarget.identifier)
    syncState(xTarget.source, d)
    broadcastSound(GetEntityCoords(GetPlayerPed(src)), Config.playSound.ankleTracker, 0.6)
    DiscordLog.AnkleTracker(xPlayer, xTarget, activate)

    TriggerEvent('msk_handcuffs:handler', src, xTarget.source, activate and 'ankletrackerOn' or 'ankletrackerOff')
end)

----------------------------------------------------------------
-- Request: Headbag
----------------------------------------------------------------
RegisterNetEvent('msk_handcuffs:requestHeadbag', function(targetId, remove)
    if not Config.HeadBag.enable then return end
    local src = source
    local xPlayer, xTarget = validate(src, targetId)
    if not xPlayer then return end
    if not jobAllows(xPlayer, 'enableHeadbag') then return end

    local d = Database.Ensure(xTarget.identifier)
    local activate = not d.hasHeadbag

    if activate then
        if not MSK.HasPlayerItem(src, Config.HeadBag.item) then
            return Config.Notification(src, T('not_hasItem_named', itemLabel(Config.HeadBag.item)), 'error')
        end
        xPlayer.RemoveItem(Config.HeadBag.item, 1)
        d.hasHeadbag = true
    else
        -- Removing needs an item only when needItemToRemove is enabled.
        if Config.HeadBag.needItemToRemove then
            if not MSK.HasPlayerItem(src, Config.HeadBag.removeItem) then
                return Config.Notification(src, T('not_hasItem_named', itemLabel(Config.HeadBag.removeItem)), 'error')
            end
            if Config.HeadBag.consumeRemoveItem then xPlayer.RemoveItem(Config.HeadBag.removeItem, 1) end
        end
        d.hasHeadbag = false
    end

    Database.Save(xTarget.identifier)
    syncState(xTarget.source, d)
    broadcastSound(GetEntityCoords(GetPlayerPed(src)), Config.playSound.headBag, 0.6)
    DiscordLog.Headbag(xPlayer, xTarget, activate)

    TriggerEvent('msk_handcuffs:handler', src, xTarget.source, activate and 'headbagOn' or 'headbagOff')
end)

----------------------------------------------------------------
-- Request: Tape (mute)
----------------------------------------------------------------
RegisterNetEvent('msk_handcuffs:requestTape', function(targetId, remove)
    if not Config.Tape.enable then return end
    local src = source
    local xPlayer, xTarget = validate(src, targetId)
    if not xPlayer then return end
    if not jobAllows(xPlayer, 'enableTape') then return end

    local d = Database.Ensure(xTarget.identifier)
    local activate = not d.hasTape

    if activate then
        if not MSK.HasPlayerItem(src, Config.Tape.item) then
            return Config.Notification(src, T('not_hasItem_named', itemLabel(Config.Tape.item)), 'error')
        end
        xPlayer.RemoveItem(Config.Tape.item, 1)
        d.hasTape = true
    else
        -- Removing needs an item only when needItemToRemove is enabled.
        if Config.Tape.needItemToRemove then
            if not MSK.HasPlayerItem(src, Config.Tape.removeItem) then
                return Config.Notification(src, T('not_hasItem_named', itemLabel(Config.Tape.removeItem)), 'error')
            end
            if Config.Tape.consumeRemoveItem then xPlayer.RemoveItem(Config.Tape.removeItem, 1) end
        end
        d.hasTape = false
    end

    Database.Save(xTarget.identifier)
    syncState(xTarget.source, d)
    Config.MutePlayer(xTarget.source, activate)
    broadcastSound(GetEntityCoords(GetPlayerPed(src)), Config.playSound.tape, 0.6)
    DiscordLog.Tape(xPlayer, xTarget, activate)

    TriggerEvent('msk_handcuffs:handler', src, xTarget.source, activate and 'tapeOn' or 'tapeOff')
end)

----------------------------------------------------------------
-- Request: Drag / Put in car / Out of car
----------------------------------------------------------------
RegisterNetEvent('msk_handcuffs:requestDrag', function(targetId)
    local src = source
    local _, xTarget = validate(src, targetId)
    if not xTarget then return end

    if not Cuffs.IsHandcuffed({identifier = xTarget.identifier}) then
        return Config.Notification(src, T('drag_not_handcuffed'), 'error')
    end

    if escortedPlayers[xTarget.source] then
        escortedPlayers[xTarget.source] = nil
    else
        escortedPlayers[xTarget.source] = src
    end

    TriggerClientEvent('msk_handcuffs:drag', xTarget.source, src)
    TriggerClientEvent('msk_handcuffs:dragAnimation', src, false, xTarget.source)
end)

RegisterNetEvent('msk_handcuffs:stopDragAnimation', function(officerId)
    officerId = tonumber(officerId)
    if officerId then TriggerClientEvent('msk_handcuffs:dragAnimation', officerId, true) end
end)

RegisterNetEvent('msk_handcuffs:requestPutInCar', function(targetId)
    local src = source
    local _, xTarget = validate(src, targetId)
    if not xTarget then return end
    if not Cuffs.IsHandcuffed({identifier = xTarget.identifier}) then
        return Config.Notification(src, T('has_no_handcuffs'), 'error')
    end
    TriggerClientEvent('msk_handcuffs:putInCar', xTarget.source, src)
end)

RegisterNetEvent('msk_handcuffs:requestOutOfCar', function(targetId)
    local src = source
    local _, xTarget = validate(src, targetId)
    if not xTarget then return end
    TriggerClientEvent('msk_handcuffs:outOfCar', xTarget.source)
end)

----------------------------------------------------------------
-- Death uncuff
----------------------------------------------------------------
RegisterNetEvent('msk_core:onPlayerDeath', function()
    local src = source
    local xPlayer = MSK.GetPlayerFromId(src)
    if not xPlayer then return end
    local d = Handcuffs[xPlayer.identifier]
    if not d then return end

    if Config.UncuffOnPlayerDied and d.isCuffed then
        Cuffs.Clear(xPlayer.identifier)
    end

    if d.hasHeadbag then
        d.hasHeadbag = false
        Database.Save(xPlayer.identifier)
        syncState(src, Handcuffs[xPlayer.identifier])
    end

    if d.hasTape then
        d.hasTape = false
        Database.Save(xPlayer.identifier)
        syncState(src, Handcuffs[xPlayer.identifier])
        Config.MutePlayer(src, false)
    end
end)

----------------------------------------------------------------
-- Admin API (used by commands.lua) — no item / distance checks
----------------------------------------------------------------
function Cuffs.AdminCuff(targetId, playAnimation)
    local xTarget = MSK.GetPlayerFromId(targetId)
    if not xTarget then return end
    applyCuff(xTarget, nil) -- nil item -> isAdminCuffed; statebag drives the client visuals
end

function Cuffs.AdminHardcuff(targetId)
    local xTarget = MSK.GetPlayerFromId(targetId)
    if not xTarget then return end
    if not Cuffs.IsHandcuffed({identifier = xTarget.identifier}) then applyCuff(xTarget, nil) end
    applyHardcuff(xTarget, nil)
end

function Cuffs.AdminUncuff(targetId)
    local xTarget = MSK.GetPlayerFromId(targetId)
    if not xTarget then return end
    Cuffs.Clear(xTarget.identifier)
end

function Cuffs.AdminAnkleTracker(targetId)
    local xTarget = MSK.GetPlayerFromId(targetId)
    if not xTarget then return end
    local d = Database.Ensure(xTarget.identifier)
    d.hasAnkleTracker = not d.hasAnkleTracker
    if d.hasAnkleTracker then activateTracker(xTarget) else removeTrackerBlips(xTarget.source) end
    Database.Save(xTarget.identifier)
    syncState(xTarget.source, d)
    return d.hasAnkleTracker
end

function Cuffs.AdminHeadbag(targetId)
    local xTarget = MSK.GetPlayerFromId(targetId)
    if not xTarget then return end
    local d = Database.Ensure(xTarget.identifier)
    d.hasHeadbag = not d.hasHeadbag
    Database.Save(xTarget.identifier)
    syncState(xTarget.source, d)
    return d.hasHeadbag
end

function Cuffs.AdminTape(targetId)
    local xTarget = MSK.GetPlayerFromId(targetId)
    if not xTarget then return end
    local d = Database.Ensure(xTarget.identifier)
    d.hasTape = not d.hasTape
    Database.Save(xTarget.identifier)
    syncState(xTarget.source, d)
    Config.MutePlayer(xTarget.source, d.hasTape)
    return d.hasTape
end

----------------------------------------------------------------
-- Item registration (framework-agnostic) -> bounce to the user's client,
-- which runs the action UX and sends a server-validated request.
----------------------------------------------------------------
-- Register once per item name. MSK.RegisterItem routes through the framework's
-- usable-item API (ESX.RegisterUsableItem / QBCore.CreateUseableItem), which
-- ox_inventory and jaksam_inventory both hook. Registering a new item name at
-- runtime therefore makes it usable immediately — no server restart needed.
local registeredItems = {}
local function registerUsable(item, action, payload)
    if type(item) ~= 'string' or item == '' or registeredItems[item] then return end
    registeredItems[item] = true
    MSK.RegisterItem(item, function(src)
        TriggerClientEvent('msk_handcuffs:useItem', src, action, payload)
    end)
end

-- (Re)register every configured item. Safe to call again after a dashboard save;
-- already-registered items are skipped and newly added ones are registered.
function Cuffs.RegisterItems()
    for _, item in ipairs(Config.cuffItems or {}) do registerUsable(item, 'cuff', item) end
    for _, item in ipairs(Config.hardcuffItems or {}) do registerUsable(item, 'hardcuff', item) end
    for _, item in ipairs(Config.uncuffItems or {}) do registerUsable(item, 'uncuff', item) end

    if Config.AnkleTracker.enable then
        registerUsable(Config.AnkleTracker.item, 'ankletracker', false)
        if Config.AnkleTracker.removeItem ~= Config.AnkleTracker.item then
            registerUsable(Config.AnkleTracker.removeItem, 'ankletracker', true)
        end
    end

    if Config.HeadBag.enable then
        registerUsable(Config.HeadBag.item, 'headbag', false)
        if Config.HeadBag.removeItem ~= Config.HeadBag.item then
            registerUsable(Config.HeadBag.removeItem, 'headbag', true)
        end
    end

    if Config.Tape.enable then
        registerUsable(Config.Tape.item, 'tape', false)
        if Config.Tape.removeItem ~= Config.Tape.item then
            registerUsable(Config.Tape.removeItem, 'tape', true)
        end
    end
end

CreateThread(function()
    while not DatabaseReady do Wait(50) end
    Cuffs.RegisterItems()
end)

----------------------------------------------------------------
-- Lifecycle: re-apply on load, cleanup on drop/logout
----------------------------------------------------------------
local function reapplyStatus(playerId)
    local xPlayer = MSK.GetPlayerFromId(playerId)
    if not xPlayer then return end
    local d = Handcuffs[xPlayer.identifier]
    if not d then return end

    syncState(xPlayer.source, d)

    if d.isCuffed and Config.Timer.enable then startTimer(xPlayer.identifier) end
    if d.hasAnkleTracker then activateTracker(xPlayer) end
    if d.hasTape then Config.MutePlayer(xPlayer.source, true) end
end

-- Authoritative snapshot sent to the client on restore (avoids relying on
-- statebag replication timing).
local function buildSnapshot(identifier)
    local d = Handcuffs[identifier] or {}
    return {
        isCuffed        = d.isCuffed or false,
        cuffItem        = d.cuffItem or false,
        isHardcuffed    = d.isHardcuffed or false,
        hasAnkleTracker = d.hasAnkleTracker or false,
        hasHeadbag      = d.hasHeadbag or false,
        hasTape         = d.hasTape or false,
    }
end

-- The client requests its restore after spawning / on resource restart.
RegisterNetEvent('msk_handcuffs:requestRestore', function()
    local src = source
    local xPlayer = MSK.GetPlayerFromId(src)

    -- Always answer so the client can flip to "ready". If the player isn't
    -- loaded server-side yet, the client re-requests on its playerLoaded event.
    if not xPlayer then
        return TriggerClientEvent('msk_handcuffs:restore', src, {})
    end

    reapplyStatus(src)
    TriggerClientEvent('msk_handcuffs:restore', src, buildSnapshot(xPlayer.identifier))
end)

-- Server (re)start: restore everyone currently online.
AddEventHandler('onResourceStart', function(resource)
    if GetCurrentResourceName() ~= resource then return end
    CreateThread(function()
        while not DatabaseReady do Wait(50) end
        for _, playerId in ipairs(GetPlayers()) do
            playerId = tonumber(playerId)
            local xPlayer = MSK.GetPlayerFromId(playerId)
            if xPlayer then
                reapplyStatus(playerId)
                TriggerClientEvent('msk_handcuffs:restore', playerId, buildSnapshot(xPlayer.identifier))
            end
        end
    end)
end)

local function onPlayerGone(playerId)
    playerId = tonumber(playerId)
    removeTrackerBlips(playerId)

    if escortedPlayers[playerId] then escortedPlayers[playerId] = nil end
    for targetId, officerId in pairs(escortedPlayers) do
        if officerId == playerId then
            TriggerClientEvent('msk_handcuffs:dragAnimation', targetId, true)
            escortedPlayers[targetId] = nil
        end
    end
end

AddEventHandler('playerDropped', function()
    onPlayerGone(source)
end)
-- msk_core forwards every framework's logout as this fixed global event, and
-- since 4.0.0 it actually fires: before that nothing in msk_core ever triggered
-- it, so this handler never ran once.
--
-- AddEventHandler, not RegisterNetEvent: server side the event is local, and
-- registering it as a net event let any client fire it with an arbitrary player
-- id, which here means clearing someone else's handcuff state.
AddEventHandler('msk_core:playerLogout', function(playerId)
    onPlayerGone(playerId)
end)

----------------------------------------------------------------
-- AnkleTracker refresh thread
----------------------------------------------------------------
if Config.AnkleTracker.enable then
    CreateThread(function()
        while true do
            for src in pairs(activeAnkletrackers) do
                activeAnkletrackers[src].coords = GetEntityCoords(GetPlayerPed(src))
            end

            if next(activeAnkletrackers) then
                for _, playerId in ipairs(GetPlayers()) do
                    if MSK.Table.Contains(Config.AnkleTracker.jobs, getJob(tonumber(playerId))) then
                        TriggerClientEvent('msk_handcuffs:refreshBlipsFromAnkletracker', tonumber(playerId), activeAnkletrackers)
                    end
                end
            end

            Wait(math.floor(1000 * Config.AnkleTracker.refreshTime))
        end
    end)
end

----------------------------------------------------------------
-- Integration / debug hook. Server-only event (NOT net) so clients can't
-- spam it; other resources can AddEventHandler('msk_handcuffs:handler', ...).
----------------------------------------------------------------
AddEventHandler('msk_handcuffs:handler', function(officerId, targetId, action, item)
    logging('debug', ('handler: %s | officer %s -> target %s (item: %s)'):format(action, officerId, targetId, item or 'none'))
end)

-- Version check lives in server/versionchecker.lua (central MSK VERSIONS repo).
