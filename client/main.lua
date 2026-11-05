----------------------------------------------------------------
-- Client core — statebag-driven visuals
--
-- Status lives in replicated statebags (set by the server). This file
-- reacts to changes of the LOCAL player's statebags and applies the
-- visuals/controls. Initial application on (re)spawn honors
-- Config.checkOnPlayerLoaded; live changes always apply.
----------------------------------------------------------------

local ready = false
local known = {}           -- last value we acted on, per state key
local cuffThreadsActive = false

----------------------------------------------------------------
-- Status getters (read the statebags) + exports
----------------------------------------------------------------
local function isHandcuffed() return LocalPlayer.state.isHandcuffed end
local function isHardcuffed() return LocalPlayer.state.isHardcuffed end

exports('getIsHandcuffed', function(player)
    if player then return Player(GetPlayerServerId(player) or player).state.isHandcuffed end
    return LocalPlayer.state.isHandcuffed
end)
exports('getIsHardcuffed', function(player)
    if player then return Player(GetPlayerServerId(player) or player).state.isHardcuffed end
    return LocalPlayer.state.isHardcuffed
end)
exports('getHasAnkletracker', function() return LocalPlayer.state.hasAnkleTracker end)
exports('getHasHeadbag', function() return LocalPlayer.state.hasHeadbag end)
exports('getHasTape', function() return LocalPlayer.state.hasTape end)

----------------------------------------------------------------
-- Threads while cuffed (controls + idle animation)
----------------------------------------------------------------
local function startCuffThreads()
    if cuffThreadsActive then return end
    cuffThreadsActive = true

    CreateThread(function() -- controls
        while isHandcuffed() do
            if Config.Method == 'whitelist' then
                DisableAllControlActions(0)
                DisableAllControlActions(2)
                if not isHardcuffed() then
                    EnableControlAction(0, 32, true) -- W
                    EnableControlAction(0, 34, true) -- A
                    EnableControlAction(0, 31, true) -- S
                    EnableControlAction(0, 30, true) -- D
                end
            else -- blacklist
                if isHardcuffed() then
                    DisableControlAction(0, 32, true) -- W
                    DisableControlAction(0, 34, true) -- A
                    DisableControlAction(0, 31, true) -- S
                    DisableControlAction(0, 30, true) -- D
                end
            end
            Config.Handcuffed()
            Wait(0)
        end

        if Config.Method == 'whitelist' then
            EnableAllControlActions(0)
            EnableAllControlActions(2)
        end
        cuffThreadsActive = false
    end)

    CreateThread(function() -- idle animation loop
        local pedGettingUp = false
        while isHandcuffed() do
            local ped = MSK.Player.ped
            if (not IsEntityPlayingAnim(ped, 'mp_arresting', 'idle', 3)
                and not IsEntityPlayingAnim(ped, 'mp_arrest_paired', 'crook_p2_back_right', 3))
                or (pedGettingUp and not IsPedGettingUp(ped)) then
                MSK.Request.AnimDict('mp_arresting')
                TaskPlayAnim(ped, 'mp_arresting', 'idle', 8.0, -8, -1, 49, 0, 0, 0, 0)
            end
            pedGettingUp = IsPedGettingUp(ped)
            Wait(0)
        end
        RemoveAnimDict('mp_arresting')
    end)
end

----------------------------------------------------------------
-- Apply / remove visuals
----------------------------------------------------------------
local function applyCuff(animate, item)
    CreateThread(function()
        local ped = MSK.Player.ped
        ClearPedTasks(ped)
        SetPedCanPlayAmbientBaseAnims(ped, true)
        SetEnableHandcuffs(ped, true)
        DisablePlayerFiring(ped, true)
        SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
        SetPedCanPlayGestureAnims(ped, false)
        SetPedPathCanUseLadders(ped, false)

        if animate then
            FreezeEntityPosition(ped, true)
            MSK.Request.AnimDict('mp_arrest_paired')
            TaskPlayAnim(ped, 'mp_arrest_paired', 'crook_p2_back_right', 8.0, -8, -1, 32, 0, 0, 0, 0)
            Wait(4300)
            FreezeEntityPosition(ped, false)
        end

        Props.SetCuff(item or LocalPlayer.state.cuffItem)
        startCuffThreads()
        Config.SetRadioChannel()
    end)
end

local function removeCuff()
    local ped = MSK.Player.ped
    ClearPedTasks(ped)
    ClearPedSecondaryTask(ped)
    SetEnableHandcuffs(ped, false)
    DisablePlayerFiring(ped, false)
    SetPedCanPlayGestureAnims(ped, true)
    SetPedPathCanUseLadders(ped, true)
    Props.DeleteCuff()
end

local function applyHeadbag()
    Props.SetHeadbag()
    SendNUIMessage({ action = 'blackscreen', toggle = 'On' })
end
local function removeHeadbag()
    Props.DeleteHeadbag()
    SendNUIMessage({ action = 'blackscreen', toggle = 'Off' })
end

local function toggleClientVoiceMute()
    if Config.Voice.enable and Config.Voice.voice == 'pma' then
        exports['pma-voice']:toggleMutePlayer(MSK.Player.serverId)
    end
end
local function applyTape()
    Props.SetTape()
    Config.Notification(nil, T('tape_activated'), 'info')
    toggleClientVoiceMute()
end
local function removeTape()
    Props.DeleteTape()
    Config.Notification(nil, T('tape_deactivated'), 'info')
    toggleClientVoiceMute()
end

local function applyAnkletracker() Props.SetAnkletracker() end
local function removeAnkletracker() Props.DeleteAnkletracker() end

----------------------------------------------------------------
-- Statebag change dispatch (own player only)
----------------------------------------------------------------
local handlers = {
    [StateKeys.isHandcuffed]    = { on = function() applyCuff(true) end, off = removeCuff },
    [StateKeys.hasHeadbag]      = { on = applyHeadbag,      off = removeHeadbag },
    [StateKeys.hasTape]         = { on = applyTape,         off = removeTape },
    [StateKeys.hasAnkleTracker] = { on = applyAnkletracker, off = removeAnkletracker },
}

local function onStateChange(key, value)
    if not ready then return end
    value = value and true or false
    if known[key] == value then return end
    known[key] = value

    local h = handlers[key]
    if not h then return end
    if value then h.on() else h.off() end
end

for key in pairs(handlers) do
    AddStateBagChangeHandler(key, nil, function(bagName, _, value)
        local ply = GetPlayerFromStateBagName(bagName)
        if ply == 0 or ply ~= PlayerId() then return end
        onStateChange(key, value)
    end)
end

----------------------------------------------------------------
-- Bootstrap: snapshot replicated statebags, apply per checkOnPlayerLoaded
----------------------------------------------------------------
local function requestRestore()
    TriggerServerEvent('msk_handcuffs:requestRestore')
end

AddEventHandler('onResourceStart', function(resource)
    if GetCurrentResourceName() ~= resource then return end
    requestRestore()
end)

-- Client spawn. One event is enough since msk_core 4.0.0: the bridge binds the
-- real framework events and turns them into this one, on ESX, QBCore and Qbox
-- alike.
--
-- The three registrations that used to stand here were a workaround for
-- msk_core 3.x, where nothing ever triggered msk_core:playerLoaded, so the two
-- framework events were the only ones that ever arrived. They also fired
-- requestRestore up to three times per spawn.
RegisterNetEvent('msk_core:playerLoaded', requestRestore)

-- Server sends the authoritative snapshot; apply it honoring checkOnPlayerLoaded.
RegisterNetEvent('msk_handcuffs:restore', function(data)
    data = data or {}
    ready = false

    known[StateKeys.isHandcuffed]    = data.isCuffed and true or false
    known[StateKeys.hasHeadbag]      = data.hasHeadbag and true or false
    known[StateKeys.hasTape]         = data.hasTape and true or false
    known[StateKeys.hasAnkleTracker] = data.hasAnkleTracker and true or false

    if Config.checkOnPlayerLoaded.cuff and data.isCuffed then applyCuff(false, data.cuffItem) end
    if Config.checkOnPlayerLoaded.ankleTracker and data.hasAnkleTracker then applyAnkletracker() end
    if Config.checkOnPlayerLoaded.headbag and data.hasHeadbag then applyHeadbag() end
    if Config.checkOnPlayerLoaded.tape and data.hasTape then applyTape() end

    ready = true
end)

----------------------------------------------------------------
-- Sound (NUI)
----------------------------------------------------------------
RegisterNetEvent('msk_handcuffs:playSound', function(coords, distance, sound, volume)
    if #(MSK.Player.coords - coords) > (distance or 5.0) then return end
    SendNUIMessage({ action = 'playSound', sound = sound, volume = volume })
end)

----------------------------------------------------------------
-- Drag / escort
----------------------------------------------------------------
local dragStatus = { status = false, officerId = nil }
dragAnimation, dragTarget = false, nil

local function dragThread()
    local wasDragged = false
    while isHandcuffed() and dragStatus.status do
        local officerPed = GetPlayerPed(GetPlayerFromServerId(dragStatus.officerId))
        local ped = MSK.Player.ped

        if DoesEntityExist(officerPed) and IsPedOnFoot(officerPed) and not IsPedDeadOrDying(officerPed, true) then
            if not wasDragged then
                AttachEntityToEntity(ped, officerPed, 11816, 0.54, 0.50, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
                wasDragged = true
            end
        else
            wasDragged = false
            dragStatus.status = false
            DetachEntity(ped, true, false)
        end
        Wait(0)
    end

    dragStatus.status = false
    DetachEntity(MSK.Player.ped, true, false)
end

local function dragThreadAnimation()
    local pedGettingUp = false
    while dragAnimation do
        local ped = MSK.Player.ped
        if not IsEntityPlayingAnim(ped, 'doors@', 'door_sweep_r_hand_medium', 3) or (pedGettingUp and not IsPedGettingUp(ped)) then
            MSK.Request.AnimDict('doors@')
            TaskPlayAnim(ped, 'doors@', 'door_sweep_r_hand_medium', 9.0, -8.0, -1, 50, 0, false, false, false)
        end
        pedGettingUp = IsPedGettingUp(ped)
        Wait(0)
    end
    RemoveAnimDict('doors@')
    ClearPedTasks(MSK.Player.ped)
end

-- Target being dragged
RegisterNetEvent('msk_handcuffs:drag', function(officerId)
    dragStatus.status = not dragStatus.status
    dragStatus.officerId = officerId
    if dragStatus.status then CreateThread(dragThread) end
end)

-- Reads the key the player currently has bound to the undrag keymapping, so the
-- TextUI reflects manual rebinds from the FiveM keybind settings. Falls back to
-- the config default if it can't be resolved (e.g. on a controller).
local function undragKey()
    local default = (Config.Target and Config.Target.undragHotkey) or 'X'
    local ok, raw = pcall(function()
        local control = (GetHashKey('+undragTarget') & 0xFFFFFFFF) | 0x80000000
        return GetControlInstructionalButton(0, control, true)
    end)
    if ok and type(raw) == 'string' then
        local key = raw:match('^t_(.+)$') -- keyboard buttons come back as 't_<KEY>'
        if key and key ~= '' then return key end
    end
    return default
end

-- Officer drag animation
RegisterNetEvent('msk_handcuffs:dragAnimation', function(stop, targetId)
    dragAnimation = not dragAnimation
    if stop then dragAnimation = false; dragTarget = nil end
    if dragAnimation then
        dragTarget = targetId
        -- Tell the escorting officer which key releases the person.
        MSK.TextUI.Show({ key = undragKey(), text = T('escort_release') })
        CreateThread(dragThreadAnimation)
    else
        MSK.TextUI.Hide()
    end
end)

----------------------------------------------------------------
-- Put in / out of car
----------------------------------------------------------------
RegisterNetEvent('msk_handcuffs:putInCar', function(officerId)
    if not isHandcuffed() then return end
    local ped = MSK.Player.ped
    local vehicle, distance = MSK.GetClosestVehicle()
    if not vehicle or distance >= 5 then return end

    local maxSeats = GetVehicleMaxNumberOfPassengers(vehicle)
    local freeSeat
    for i = maxSeats - 1, 0, -1 do
        if IsVehicleSeatFree(vehicle, i) then freeSeat = i break end
    end

    if freeSeat then
        dragStatus.status = false
        TriggerServerEvent('msk_handcuffs:stopDragAnimation', officerId)
        TaskEnterVehicle(ped, vehicle, -1, freeSeat, 1.5, 1, 0)
    end
end)

RegisterNetEvent('msk_handcuffs:outOfCar', function()
    local ped = MSK.Player.ped
    if IsPedSittingInAnyVehicle(ped) then
        TaskLeaveVehicle(ped, GetVehiclePedIsIn(ped, false), 64)
    end
end)

----------------------------------------------------------------
-- Debug handler log
----------------------------------------------------------------
RegisterNetEvent('msk_handcuffs:handler', function(officerId, targetId, action, item)
    logging('debug', ('handler: %s | officer %s -> target %s (item: %s)'):format(action, officerId, targetId, item or 'none'))
end)

----------------------------------------------------------------
-- Cleanup
----------------------------------------------------------------
AddEventHandler('onResourceStop', function(resource)
    if GetCurrentResourceName() ~= resource then return end
    Props.DeleteAll()
    ClearTrackerBlips()
    MSK.TextUI.Hide()
    SendNUIMessage({ action = 'blackscreen', toggle = 'Off' })
end)
