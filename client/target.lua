----------------------------------------------------------------
-- Target integration (ox_target + qb-target) + undrag hotkey
--
-- Labels are localized via T() (the dashboard language). Toggle options are
-- split into an "on" and an "off" variant so the label always matches the
-- target's current state (e.g. "Sack aufsetzen" vs "Sack abnehmen"). When the
-- dashboard changes the language / target settings, everything is re-registered
-- live (msk_handcuffs:settingsApplied).
----------------------------------------------------------------
if not Config.Target then return end

local function plyFromEntity(entity)
    local ply = NetworkGetPlayerIndexFromPed(entity)
    if ply == -1 then return nil end
    return ply
end

local function stateOf(entity, key)
    local ply = plyFromEntity(entity)
    if not ply then return nil end
    return Player(GetPlayerServerId(ply)).state[key]
end

local function isPlayer(e) return plyFromEntity(e) ~= nil end
local function isCuffed(e) return stateOf(e, StateKeys.isHandcuffed) end
local function isHardcuffed(e) return stateOf(e, StateKeys.isHardcuffed) end
local function hasTracker(e) return stateOf(e, StateKeys.hasAnkleTracker) end
local function hasHeadbag(e) return stateOf(e, StateKeys.hasHeadbag) end
local function hasTape(e) return stateOf(e, StateKeys.hasTape) end

-- Stable option names (independent of the localized label) so removal works.
local ALL_NAMES = {
    'cuff', 'hardcuff', 'uncuff', 'tracker_on', 'tracker_off',
    'headbag_on', 'headbag_off', 'tape_on', 'tape_off', 'drag', 'putin', 'putout',
}
local function fullNames()
    local t = {}
    for i = 1, #ALL_NAMES do t[i] = 'msk_handcuffs:' .. ALL_NAMES[i] end
    return t
end

-- Rebuilt on every (re)register so labels reflect the current locale.
local function buildDefs()
    local opt = Config.Target.options or {}
    return {
        { name = 'cuff', enabled = opt.cuff, icon = 'fas fa-handcuffs', label = T('target_cuff'),
          can = function(e) return isPlayer(e) and not isCuffed(e) end, run = function(p) Actions.Cuff(nil, p) end },
        { name = 'hardcuff', enabled = opt.hardcuff, icon = 'fas fa-link', label = T('target_hardcuff'),
          can = function(e) return isCuffed(e) and not isHardcuffed(e) end, run = function(p) Actions.Hardcuff(nil, p) end },
        { name = 'uncuff', enabled = opt.uncuff, icon = 'fas fa-unlock', label = T('target_uncuff'),
          can = function(e) return isCuffed(e) end, run = function(p) Actions.Uncuff(nil, p) end },

        { name = 'tracker_on', enabled = opt.ankletracker, icon = 'fas fa-location-crosshairs', label = T('target_ankletracker_on'),
          can = function(e) return isCuffed(e) and not hasTracker(e) end, run = function(p) Actions.Ankletracker(p) end },
        { name = 'tracker_off', enabled = opt.ankletracker, icon = 'fas fa-location-crosshairs', label = T('target_ankletracker_off'),
          can = function(e) return isCuffed(e) and hasTracker(e) end, run = function(p) Actions.Ankletracker(p) end },

        { name = 'headbag_on', enabled = opt.headbag, icon = 'fas fa-mask', label = T('target_headbag_on'),
          can = function(e) return isPlayer(e) and not hasHeadbag(e) end, run = function(p) Actions.Headbag(p) end },
        { name = 'headbag_off', enabled = opt.headbag, icon = 'fas fa-mask', label = T('target_headbag_off'),
          can = function(e) return isPlayer(e) and hasHeadbag(e) end, run = function(p) Actions.Headbag(p) end },

        { name = 'tape_on', enabled = opt.tape, icon = 'fas fa-tape', label = T('target_tape_on'),
          can = function(e) return isPlayer(e) and not hasTape(e) end, run = function(p) Actions.Tape(p) end },
        { name = 'tape_off', enabled = opt.tape, icon = 'fas fa-tape', label = T('target_tape_off'),
          can = function(e) return isPlayer(e) and hasTape(e) end, run = function(p) Actions.Tape(p) end },

        { name = 'drag', enabled = opt.drag, icon = 'fas fa-person-walking', label = T('target_drag'),
          can = function(e) return isCuffed(e) end, run = function(p) Actions.Drag(p) end },
        { name = 'putin', enabled = opt.putInCar, icon = 'fas fa-car-side', label = T('target_putincar'),
          can = function(e) return isCuffed(e) end, run = function(p) Actions.PutInCar(p) end },
        { name = 'putout', enabled = opt.putOutOfCar, icon = 'fas fa-door-open', label = T('target_putoutofcar'),
          can = function(e) return isPlayer(e) end, run = function(p) Actions.PutOutOfCar(p) end },
    }
end

----------------------------------------------------------------
local activeSystem

local function resolveSystem()
    local system = Config.Target.system
    if system == 'auto' then
        if GetResourceState('ox_target') == 'started' then
            system = 'ox_target'
        elseif GetResourceState('qb-target') == 'started' then
            system = 'qb-target'
        end
    end
    if system == 'ox_target' and GetResourceState('ox_target') == 'started' then return 'ox_target' end
    if system == 'qb-target' and GetResourceState('qb-target') == 'started' then return 'qb-target' end
    return nil
end

local function removeTargets()
    if activeSystem == 'ox_target' then
        pcall(function() exports.ox_target:removeGlobalPlayer(fullNames()) end)
    elseif activeSystem == 'qb-target' then
        pcall(function() exports['qb-target']:RemoveGlobalPlayer(fullNames()) end)
    end
end

local function addTargets()
    local system = resolveSystem()
    if not system then
        logging('error', '[msk_handcuffs] Config.Target.enable is true but no supported target resource (ox_target / qb-target) is running.')
        return
    end
    activeSystem = system

    local defs = buildDefs()

    if system == 'ox_target' then
        local options = {}
        for _, d in ipairs(defs) do
            if d.enabled then
                options[#options + 1] = {
                    name = 'msk_handcuffs:' .. d.name,
                    icon = d.icon,
                    label = d.label,
                    distance = 2.0,
                    canInteract = function(entity) return d.can(entity) end,
                    onSelect = function(data) d.run(plyFromEntity(data.entity)) end,
                }
            end
        end
        exports.ox_target:addGlobalPlayer(options)
    else -- qb-target
        local options = {}
        for _, d in ipairs(defs) do
            if d.enabled then
                options[#options + 1] = {
                    name = 'msk_handcuffs:' .. d.name,
                    icon = d.icon,
                    label = d.label,
                    canInteract = function(entity) return d.can(entity) end,
                    action = function(entity) d.run(plyFromEntity(entity)) end,
                }
            end
        end
        exports['qb-target']:AddGlobalPlayer({ options = options, distance = 2.0 })
    end
end

local function register()
    if not Config.Target.enable then
        removeTargets()
        activeSystem = nil
        return
    end
    removeTargets()
    addTargets()
end

CreateThread(function()
    Wait(500) -- let the target resource come up
    register()
end)

-- Re-register when the dashboard pushes new settings (language / target options).
AddEventHandler('msk_handcuffs:settingsApplied', function()
    register()
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    removeTargets()
end)

----------------------------------------------------------------
-- Undrag hotkey (officer)
----------------------------------------------------------------
MSK.RegisterCommand('undragTarget', function()
    if not dragAnimation then return end
    TriggerServerEvent('msk_handcuffs:requestDrag', dragTarget)
end, false, {
    showSuggestion = false,
    hotkey = { key = Config.Target.undragHotkey, text = 'Undrag someone', type = 'keyboard' }
})
