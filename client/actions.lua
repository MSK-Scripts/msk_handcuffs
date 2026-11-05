----------------------------------------------------------------
-- Action initiators (client side)
--
-- These run the local UX: pick the closest player, play the officer
-- animation, do a fast client-side pre-check (item / target status) for
-- responsive feedback, then send a REQUEST. The server re-validates
-- everything authoritatively — the pre-checks here are UX only.
----------------------------------------------------------------
Actions = {}

-- Client job for the UX pre-checks only (the server re-validates everything).
--
-- Since msk_core 4.0.0 the job arrives in one shape on every framework, so the
-- per-framework lookup that used to sit here is gone. It existed because
-- MSK.Bridge resolved to a function in a consumer and could not be read, and it
-- covered ESX and QBCore only: on Qbox every player counted as unemployed.
local function playerJob()
    local job = MSK.GetPlayerJob()

    return job and job.name or 'unemployed'
end

-- Candidate items for the UX pre-check (server re-validates + resolves the real
-- item). Includes the item the player actually used plus, in RestrictItems mode,
-- the default item (always allowed) and the job item. Returns nil to skip.
local function uxItems(claimed, kind)
    local out, seen = {}, {}
    local function add(it)
        if type(it) == 'string' and it ~= '' and not seen[it] then
            seen[it] = true
            out[#out + 1] = it
        end
    end

    add(claimed)
    if Config.RestrictItems.enable then
        add((Config.RestrictItems.defaultItems or {})[kind]) -- default is always allowed
        local jobset = Config.RestrictItems.jobItems[playerJob()]
        if jobset then add(jobset[kind]) end
    else
        local list = (kind == 'cuffItem' and Config.cuffItems)
            or (kind == 'hardcuffItem' and Config.hardcuffItems)
            or Config.uncuffItems
        for _, it in ipairs(list or {}) do add(it) end
    end

    if #out == 0 then return nil end
    return out
end

local function hasAnyUX(items)
    if not items then return true end
    for _, it in ipairs(items) do
        local has = MSK.HasItem(it)
        if has and has.count and has.count > 0 then return true end
    end
    return false
end

-- Returns target server id + ped, or nil after notifying the player.
local function pickTarget(targetPlayer)
    local player, distance = MSK.GetClosestPlayer()
    if targetPlayer then player, distance = targetPlayer, 2.0 end

    if player == -1 or distance > 2.0 then
        Config.Notification(nil, T('no_player_nearby'), 'error')
        return
    end

    return GetPlayerServerId(player)
end

local function isTargetCuffed(targetId)
    return Player(targetId).state.isHandcuffed
end

----------------------------------------------------------------
-- Only the plain item name is a valid "claimed item"; a table means no specific
-- item (target menu). The server does the authoritative resolution either way.
local function claimedOf(item)
    return (type(item) ~= 'table') and item or nil
end

function Actions.Cuff(item, targetPlayer)
    local claimed = claimedOf(item)
    if not hasAnyUX(uxItems(claimed, 'cuffItem')) then return Config.Notification(nil, T('not_hasItem'), 'error') end

    local targetId = pickTarget(targetPlayer)
    if not targetId then return end
    if isTargetCuffed(targetId) then return Config.Notification(nil, T('player_already_cuffed'), 'error') end

    local ped = MSK.Player.ped
    FreezeEntityPosition(ped, true)
    MSK.Request.AnimDict('mp_arrest_paired')
    TaskPlayAnim(ped, 'mp_arrest_paired', 'cop_p2_back_right', 8.0, -8, 4000, 48, 0, 0, 0, 0)

    TriggerServerEvent('msk_handcuffs:request', targetId, 'cuff', claimed)
    Wait(4200)

    FreezeEntityPosition(ped, false)
    ClearPedTasks(ped)
end

function Actions.Hardcuff(item, targetPlayer)
    local claimed = claimedOf(item)
    if not hasAnyUX(uxItems(claimed, 'hardcuffItem')) then return Config.Notification(nil, T('not_hasItem'), 'error') end

    local targetId = pickTarget(targetPlayer)
    if not targetId then return end
    if not isTargetCuffed(targetId) then return Config.Notification(nil, T('has_no_handcuffs'), 'error') end

    local ped = MSK.Player.ped
    FreezeEntityPosition(ped, true)
    MSK.Request.AnimDict('amb@world_human_bum_wash@male@low@idle_a')
    TaskPlayAnim(ped, 'amb@world_human_bum_wash@male@low@idle_a', 'idle_a', 8.0, -8, -1, 32, 0, 0, 0, 0)

    TriggerServerEvent('msk_handcuffs:request', targetId, 'hardcuff', claimed)
    Wait(2800)

    FreezeEntityPosition(ped, false)
    ClearPedTasks(ped)
end

function Actions.Uncuff(item, targetPlayer)
    local claimed = claimedOf(item)
    if not hasAnyUX(uxItems(claimed, 'uncuffItem')) then return Config.Notification(nil, T('not_hasItem'), 'error') end

    local targetId = pickTarget(targetPlayer)
    if not targetId then return end
    if not isTargetCuffed(targetId) then return Config.Notification(nil, T('player_not_handcuffed'), 'error') end

    local ped = MSK.Player.ped
    Props.SetCuffKey(claimed)
    MSK.Request.AnimDict('mp_arresting')
    TaskPlayAnim(ped, 'mp_arresting', 'a_uncuff', 8.0, -8, 5000, 49, 0, 0, 0, 0)
    Wait(3500)
    Props.DeleteCuffKey()

    TriggerServerEvent('msk_handcuffs:request', targetId, 'uncuff', claimed)
    ClearPedTasks(ped)
end

----------------------------------------------------------------
local function statusAction(targetPlayer, optionKey, requestEvent, remove)
    if Config.RestrictItems.enable then
        -- Default options are always allowed; the job may allow more on top.
        local def = (Config.RestrictItems.defaultItems or {})[optionKey]
        local jobset = Config.RestrictItems.jobItems[playerJob()]
        local allowed = def == true or (jobset and jobset[optionKey] == true)
        if not allowed then return end
    end

    local targetId = pickTarget(targetPlayer)
    if not targetId then return end

    local ped = MSK.Player.ped
    FreezeEntityPosition(ped, true)
    MSK.Request.AnimDict('amb@world_human_bum_wash@male@low@idle_a')
    TaskPlayAnim(ped, 'amb@world_human_bum_wash@male@low@idle_a', 'idle_a', 8.0, -8, -1, 32, 0, 0, 0, 0)

    TriggerServerEvent(requestEvent, targetId, remove)
    Wait(2800)

    FreezeEntityPosition(ped, false)
    ClearPedTasks(ped)
end

function Actions.Ankletracker(targetPlayer, remove)
    statusAction(targetPlayer, 'enableAnkletracker', 'msk_handcuffs:requestAnkletracker', remove)
end

function Actions.Headbag(targetPlayer, remove)
    statusAction(targetPlayer, 'enableHeadbag', 'msk_handcuffs:requestHeadbag', remove)
end

function Actions.Tape(targetPlayer, remove)
    statusAction(targetPlayer, 'enableTape', 'msk_handcuffs:requestTape', remove)
end

----------------------------------------------------------------
function Actions.Drag(targetPlayer)
    local targetId = pickTarget(targetPlayer)
    if not targetId then return end
    TriggerServerEvent('msk_handcuffs:requestDrag', targetId)
end

function Actions.PutInCar(targetPlayer)
    local targetId = pickTarget(targetPlayer)
    if not targetId then return end
    if not isTargetCuffed(targetId) then return Config.Notification(nil, T('has_no_handcuffs'), 'error') end
    TriggerServerEvent('msk_handcuffs:requestPutInCar', targetId)
end

function Actions.PutOutOfCar(targetPlayer)
    local targetId = pickTarget(targetPlayer)
    if not targetId then return end
    TriggerServerEvent('msk_handcuffs:requestOutOfCar', targetId)
end

----------------------------------------------------------------
-- Exports (backwards-compatible names)
----------------------------------------------------------------
-- Signatures preserved from previous versions:
--   cuffPlayer/hardcuffPlayer/uncuffPlayer(item?, player?)
--   ankleTrackerPlayer/headbagPlayer/tapePlayer(player?, remove?)
--   dragPlayer/escortPlayer/putPlayerInCar/putPlayerOutOfCar(player?)
exports('cuffPlayer', Actions.Cuff)
exports('hardcuffPlayer', Actions.Hardcuff)
exports('uncuffPlayer', Actions.Uncuff)
exports('ankleTrackerPlayer', Actions.Ankletracker)
exports('headbagPlayer', Actions.Headbag)
exports('tapePlayer', Actions.Tape)
exports('dragPlayer', Actions.Drag)
exports('escortPlayer', Actions.Drag)
exports('putPlayerInCar', Actions.PutInCar)
exports('putPlayerOutOfCar', Actions.PutOutOfCar)

----------------------------------------------------------------
-- Item use bounce from the server (ESX/QBCore usable item or command)
----------------------------------------------------------------
RegisterNetEvent('msk_handcuffs:useItem', function(action, payload)
    if action == 'cuff' then Actions.Cuff(payload)
    elseif action == 'hardcuff' then Actions.Hardcuff(payload)
    elseif action == 'uncuff' then Actions.Uncuff(payload)
    elseif action == 'ankletracker' then Actions.Ankletracker(nil, payload)
    elseif action == 'headbag' then Actions.Headbag(nil, payload)
    elseif action == 'tape' then Actions.Tape(nil, payload)
    end
end)
