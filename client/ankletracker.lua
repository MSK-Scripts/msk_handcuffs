----------------------------------------------------------------
-- AnkleTracker blips (shown to the configured jobs)
----------------------------------------------------------------
local trackerBlips = {}   -- [src] = { blip, isActive }

local function isSelf(src)
    return tonumber(src) == MSK.Player.serverId
end

local function inOneSync(netId)
    if not netId or not NetworkDoesNetworkIdExist(netId) then return false end
    local ped = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(ped) then return ped end
    return false
end

local function addBlip(player, data)
    if isSelf(player.source) then return end
    if trackerBlips[player.source] then return end

    local blip = AddBlipForCoord(data.coords.x, data.coords.y, data.coords.z)
    SetBlipSprite(blip, Config.AnkleTracker.blip.id)
    SetBlipScale(blip, Config.AnkleTracker.blip.scale)
    SetBlipColour(blip, Config.AnkleTracker.blip.color)
    SetBlipDisplay(blip, 2)
    SetBlipAsShortRange(blip, true)
    SetBlipCategory(blip, 7)

    AddTextEntry('NAME_' .. player.name, player.name)
    BeginTextCommandSetBlipName('NAME_' .. player.name)
    EndTextCommandSetBlipName(blip)

    trackerBlips[player.source] = { blip = blip, isActive = false }
end
RegisterNetEvent('msk_handcuffs:addBlipFromAnkletracker', addBlip)

RegisterNetEvent('msk_handcuffs:refreshBlipsFromAnkletracker', function(trackers)
    for src, data in pairs(trackers) do
        if not isSelf(src) then
            if not trackerBlips[src] then addBlip(data.player, data) end

            local entry = trackerBlips[src]
            local ped = inOneSync(data.netId)

            if ped and not entry.isActive then
                entry.isActive = true
                CreateThread(function()
                    while trackerBlips[src] and trackerBlips[src].isActive and DoesEntityExist(ped) do
                        local coords = GetEntityCoords(ped)
                        SetBlipCoords(trackerBlips[src].blip, coords.x, coords.y, coords.z)
                        Wait(0)
                    end
                end)
            elseif not ped then
                entry.isActive = false
                SetBlipCoords(entry.blip, data.coords.x, data.coords.y, data.coords.z)
            end
        end
    end
end)

RegisterNetEvent('msk_handcuffs:removeBlipFromAnkletracker', function(src)
    local entry = trackerBlips[src]
    if not entry then return end
    RemoveBlip(entry.blip)
    trackerBlips[src] = nil
end)

function ClearTrackerBlips()
    for src, entry in pairs(trackerBlips) do
        RemoveBlip(entry.blip)
        trackerBlips[src] = nil
    end
end
