AdminApi = AdminApi or {}

----------------------------------------------------------------
-- Input sanitisation. NEVER trust client structures — every field is coerced
-- and whitelisted before it touches the DB or a mutating function.
----------------------------------------------------------------
local ID_PATTERN = '^[%w_%-]+$'

local function trim(s)
    return (tostring(s):gsub('^%s+', ''):gsub('%s+$', ''))
end

local function num(v, default)
    local n = tonumber(v)
    if n == nil then return default end
    return n + 0.0
end

local function int(v, default)
    local n = tonumber(v)
    if n == nil then return default end
    return math.floor(n)
end

local function bool(v) return v == true end

local function str(v, max)
    if type(v) ~= 'string' then return nil end
    v = trim(v)
    if #v > (max or 120) then v = v:sub(1, max or 120) end
    return v
end

-- Returns value if it is in the allowed list, otherwise the fallback.
local function oneOf(value, list, fallback)
    if type(value) == 'string' then
        for _, v in ipairs(list) do
            if v == value then return value end
        end
    end
    return fallback
end

local function tbl(v) return type(v) == 'table' and v or {} end

-- An explicitly `false` value stays false (used to disable a command/sound);
-- otherwise sanitise as a string, falling back to the current value.
local function optStr(v, cur, max)
    if v == false then return false end
    return str(v, max) or cur
end

-- Array of trimmed, deduped strings (item / job / group names).
local function stringList(list, max)
    if type(list) ~= 'table' then return {} end
    local out, seen = {}, {}
    for _, v in ipairs(list) do
        if type(v) == 'string' then
            local s = trim(v)
            if #s > 0 and #s <= (max or 50) and not seen[s] then
                seen[s] = true
                out[#out + 1] = s
            end
        end
    end
    return out
end

-- Map string -> string (e.g. Commands[x].jobs = { police = 'cuffs' }).
local function strMap(v, maxKey, maxVal)
    if type(v) ~= 'table' then return {} end
    local out = {}
    for k, val in pairs(v) do
        if type(k) == 'string' and #k > 0 and #k <= (maxKey or 50) and type(val) == 'string' then
            local vv = trim(val)
            if #vv > 0 and #vv <= (maxVal or 50) then out[k:lower()] = vv end
        end
    end
    return out
end

-- Map string -> string[] (ItemSettings = { cuffs = { 'cuff_keys' } }).
local function itemListMap(v)
    if type(v) ~= 'table' then return {} end
    local out = {}
    for k, list in pairs(v) do
        if type(k) == 'string' and #k > 0 and #k <= 50 then
            out[k] = stringList(list, 50)
        end
    end
    return out
end

-- Map string -> bool (GiveCuffItemBack = { cuffs = true }).
local function boolKeyMap(v)
    if type(v) ~= 'table' then return {} end
    local out = {}
    for k, val in pairs(v) do
        if type(k) == 'string' and #k > 0 and #k <= 50 then out[k] = val == true end
    end
    return out
end

----------------------------------------------------------------
-- Settings normalisers (nested tables rebuilt from scratch, current config as
-- the fallback base so partial patches and unknown fields are always safe).
----------------------------------------------------------------
local function normTarget(v, cur)
    v, cur = tbl(v), tbl(cur)
    local vo, co = tbl(v.options), tbl(cur.options)
    local opts = {}
    for _, k in ipairs({ 'cuff', 'hardcuff', 'uncuff', 'ankletracker', 'headbag', 'tape', 'drag', 'putInCar', 'putOutOfCar' }) do
        opts[k] = (v.options ~= nil) and bool(vo[k]) or (co[k] == true)
    end
    return {
        enable = bool(v.enable),
        system = oneOf(v.system, AdminPerms.TARGET_SYSTEMS, cur.system or 'auto'),
        undragHotkey = str(v.undragHotkey, 20) or cur.undragHotkey or 'X',
        options = opts,
    }
end

local function normCommands(v, cur)
    v, cur = tbl(v), tbl(cur)
    local out = {}
    for _, name in ipairs({ 'cuff', 'hardcuff', 'uncuff' }) do
        local iv, ic = tbl(v[name]), tbl(cur[name])
        out[name] = {
            enable = (v[name] ~= nil) and bool(iv.enable) or (ic.enable == true),
            command = str(iv.command, 32) or ic.command or name,
            item = str(iv.item, 50) or ic.item or '',
            jobs = (v[name] ~= nil) and strMap(iv.jobs, 50, 50) or (ic.jobs or {}),
        }
    end
    return out
end

local function normAnkleTracker(v, cur)
    v, cur = tbl(v), tbl(cur)
    local blip, cblip = tbl(v.blip), tbl(cur.blip)
    return {
        enable = bool(v.enable),
        refreshTime = num(v.refreshTime, cur.refreshTime or 5.0),
        item = str(v.item, 50) or cur.item or 'ankletracker',
        removeItem = str(v.removeItem, 50) or cur.removeItem or 'ankletracker_key',
        consumeRemoveItem = (v.consumeRemoveItem ~= nil) and bool(v.consumeRemoveItem) or (cur.consumeRemoveItem == true),
        command = optStr(v.command, cur.command or 'ankletracker', 32),
        blip = {
            id = int(blip.id, cblip.id or 1),
            color = int(blip.color, cblip.color or 15),
            scale = num(blip.scale, cblip.scale or 0.8),
            prefix = str(blip.prefix, 20) or cblip.prefix or 'Track',
        },
        jobs = (v.jobs ~= nil) and stringList(v.jobs, 50) or (cur.jobs or {}),
    }
end

local function normBagTape(v, cur, defItem, defRemove, defCmd)
    v, cur = tbl(v), tbl(cur)
    return {
        enable = bool(v.enable),
        item = str(v.item, 50) or cur.item or defItem,
        removeItem = str(v.removeItem, 50) or cur.removeItem or defRemove,
        needItemToRemove = (v.needItemToRemove ~= nil) and bool(v.needItemToRemove) or (cur.needItemToRemove == true),
        consumeRemoveItem = (v.consumeRemoveItem ~= nil) and bool(v.consumeRemoveItem) or (cur.consumeRemoveItem == true),
        command = optStr(v.command, cur.command or defCmd, 32),
    }
end

local function normCheckLoaded(v, cur)
    v, cur = tbl(v), tbl(cur)
    local out = {}
    for _, k in ipairs({ 'cuff', 'hardcuff', 'ankleTracker', 'headbag', 'tape' }) do
        out[k] = (v[k] ~= nil) and bool(v[k]) or (cur[k] == true)
    end
    return out
end

local function normPlaySound(v, cur)
    v, cur = tbl(v), tbl(cur)
    local out = { enable = bool(v.enable) }
    for _, k in ipairs({ 'cuff', 'hardcuff', 'uncuff', 'ankleTracker', 'headBag', 'tape' }) do
        if v[k] == false then out[k] = false
        else out[k] = str(v[k], 60) or cur[k] or false end
    end
    return out
end

local function normTimer(v, cur)
    v, cur = tbl(v), tbl(cur)
    return { enable = bool(v.enable), time = math.max(1, int(v.time, cur.time or 30)) }
end

local function normVoice(v, cur)
    v, cur = tbl(v), tbl(cur)
    return { enable = bool(v.enable), voice = oneOf(v.voice, AdminPerms.VOICE_SCRIPTS, cur.voice or 'pma') }
end

local function normAdminCommands(v, cur)
    v, cur = tbl(v), tbl(cur)
    local out = {}
    for _, name in ipairs({ 'cuff', 'hardcuff', 'uncuff', 'ankleTracker', 'headbag', 'tape' }) do
        local iv, ic = tbl(v[name]), tbl(cur[name])
        out[name] = {
            enable = (v[name] ~= nil) and bool(iv.enable) or (ic.enable == true),
            command = str(iv.command, 32) or ic.command or name,
        }
    end
    local ivc, icc = tbl(v.cuff), tbl(cur.cuff)
    out.cuff.playAnimation = (v.cuff ~= nil) and bool(ivc.playAnimation) or (icc.playAnimation == true)
    return out
end

local function normTheme(v, cur)
    v = tbl(v)
    cur = (type(cur) == 'table') and cur or AdminPerms.DEFAULT_THEME
    local theme = {}
    for _, ck in ipairs(AdminPerms.THEME_KEYS) do
        local hex = type(v[ck]) == 'string' and v[ck]:match('^#%x%x%x%x%x%x$')
        theme[ck] = hex or cur[ck] or AdminPerms.DEFAULT_THEME[ck]
    end
    return theme
end

-- Validates a general settings patch against the editable whitelist. The item
-- lists + RestrictItems are intentionally NOT handled here (Items / Restrictions
-- tabs -> items:save / restrictions:save).
function AdminApi.SanitizeSettings(patch)
    local out = {}
    if type(patch) ~= 'table' then return out end

    for _, key in ipairs(AdminPerms.SETTINGS_KEYS) do
        local v = patch[key]
        if v ~= nil then
            if key == 'Locale' then
                local loc = oneOf(v, AdminPerms.LOCALES, nil)
                if loc then out[key] = loc end
            elseif key == 'Debug' or key == 'VersionChecker' or key == 'DiscordLog'
                or key == 'UncuffOnPlayerDied' or key == 'EnableProps' then
                out[key] = bool(v)
            elseif key == 'MaxDistance' then
                out[key] = math.max(0.5, math.min(50.0, num(v, Config.MaxDistance or 3.0)))
            elseif key == 'DiscordWebhook' then
                local url = str(v, 300) or ''
                url = url:gsub('%s', '')
                if url == '' or url:match('^https://') then out[key] = url end
            elseif key == 'botColor' then
                out[key] = str(v, 20) or Config.botColor
            elseif key == 'botName' then
                out[key] = str(v, 60) or Config.botName
            elseif key == 'botAvatar' then
                out[key] = str(v, 300) or Config.botAvatar
            elseif key == 'Target' then
                out[key] = normTarget(v, Config.Target)
            elseif key == 'Commands' then
                out[key] = normCommands(v, Config.Commands)
            elseif key == 'AnkleTracker' then
                out[key] = normAnkleTracker(v, Config.AnkleTracker)
            elseif key == 'HeadBag' then
                out[key] = normBagTape(v, Config.HeadBag, 'headbag', 'headbag_key', 'headbag')
            elseif key == 'Tape' then
                out[key] = normBagTape(v, Config.Tape, 'tape', 'tape_key', 'tape')
            elseif key == 'checkOnPlayerLoaded' then
                out[key] = normCheckLoaded(v, Config.checkOnPlayerLoaded)
            elseif key == 'playSound' then
                out[key] = normPlaySound(v, Config.playSound)
            elseif key == 'Timer' then
                out[key] = normTimer(v, Config.Timer)
            elseif key == 'Voice' then
                out[key] = normVoice(v, Config.Voice)
            elseif key == 'AdminGroups' then
                out[key] = stringList(v, 40)
            elseif key == 'AdminCommands' then
                out[key] = normAdminCommands(v, Config.AdminCommands)
            elseif key == 'adminCommand' then
                local cmd = str(v, 32)
                if cmd and cmd:match('^[%w_]+$') then out[key] = cmd end
            elseif key == 'BrandTag' then
                local tag = str(v, 16)
                if tag ~= nil then out[key] = tag:gsub('[%c]', '') end
            elseif key == 'Theme' then
                out[key] = normTheme(v, Config.Theme)
            end
            -- cuffItems / hardcuffItems / uncuffItems / ItemSettings /
            -- GiveCuffItemBack / RestrictItems: handled by items:save /
            -- restrictions:save.
        end
    end
    return out
end

-- Items tab -----------------------------------------------------
function AdminApi.SanitizeItems(patch)
    local out = {}
    if type(patch) ~= 'table' then return out end
    if patch.cuffItems ~= nil then out.cuffItems = stringList(patch.cuffItems, 50) end
    if patch.hardcuffItems ~= nil then out.hardcuffItems = stringList(patch.hardcuffItems, 50) end
    if patch.uncuffItems ~= nil then out.uncuffItems = stringList(patch.uncuffItems, 50) end
    if patch.ItemSettings ~= nil then out.ItemSettings = itemListMap(patch.ItemSettings) end
    if patch.GiveCuffItemBack ~= nil then out.GiveCuffItemBack = boolKeyMap(patch.GiveCuffItemBack) end
    if patch.consumeUncuffItem ~= nil then out.consumeUncuffItem = bool(patch.consumeUncuffItem) end
    return out
end

-- Restrictions tab ----------------------------------------------
local function normItemSet(v, cur)
    v, cur = tbl(v), tbl(cur)
    return {
        cuffItem = str(v.cuffItem, 50) or cur.cuffItem or '',
        hardcuffItem = str(v.hardcuffItem, 50) or cur.hardcuffItem or '',
        uncuffItem = str(v.uncuffItem, 50) or cur.uncuffItem or '',
        enableAnkletracker = (v.enableAnkletracker ~= nil) and bool(v.enableAnkletracker) or (cur.enableAnkletracker == true),
        enableHeadbag = (v.enableHeadbag ~= nil) and bool(v.enableHeadbag) or (cur.enableHeadbag == true),
        enableTape = (v.enableTape ~= nil) and bool(v.enableTape) or (cur.enableTape == true),
    }
end

function AdminApi.SanitizeRestrictions(patch)
    patch = tbl(patch)
    local cur = tbl(Config.RestrictItems)
    local jobItems = {}
    if type(patch.jobItems) == 'table' then
        local curJobs = tbl(cur.jobItems)
        for job, def in pairs(patch.jobItems) do
            if type(job) == 'string' and #job > 0 and #job <= 50 then
                jobItems[job:lower()] = normItemSet(def, curJobs[job:lower()])
            end
        end
    else
        jobItems = cur.jobItems or {}
    end
    return {
        enable = (patch.enable ~= nil) and bool(patch.enable) or (cur.enable == true),
        defaultItems = normItemSet(patch.defaultItems, cur.defaultItems),
        jobItems = jobItems,
    }
end

----------------------------------------------------------------
-- Live player data (not part of the bootstrap cache)
----------------------------------------------------------------
function AdminApi.OnlinePlayers()
    local out = {}
    for _, pid in ipairs(GetPlayers()) do
        pid = tonumber(pid)
        local xPlayer = MSK.GetPlayerFromId(pid)
        if xPlayer then
            local id = xPlayer.identifier
            local cuffed = Cuffs.IsHandcuffed({ identifier = id })
            out[#out + 1] = {
                serverId = pid,
                identifier = id,
                name = GetPlayerName(pid) or ('[' .. pid .. ']'),
                job = (xPlayer.job and xPlayer.job.name) or 'unemployed',
                status = {
                    cuffed = cuffed and true or false,
                    adminCuffed = cuffed == 'isAdminCuffed',
                    hardcuffed = Cuffs.IsHardcuffed({ identifier = id }) and true or false,
                    ankletracker = Cuffs.HasAnkleTracker({ identifier = id }) and true or false,
                    headbag = Cuffs.HasHeadbag({ identifier = id }) and true or false,
                    tape = Cuffs.HasTape({ identifier = id }) and true or false,
                },
            }
        end
    end
    table.sort(out, function(a, b) return a.serverId < b.serverId end)
    return out
end

-- Job list for the dropdown suggestions. Empty on STANDALONE, in which case the
-- UI just uses free-text job names.
--
-- msk_core 4.0.0 answers this for every framework. The version before read the
-- framework itself, because MSK.Bridge could not be reached from a consumer,
-- and it knew ESX and QBCore only: on Qbox the dropdown stayed empty.
function AdminApi.JobsList()
    local out = {}

    for name, job in pairs(MSK.GetJobs() or {}) do
        out[#out + 1] = { name = name, label = job.label or name }
    end

    table.sort(out, function(a, b) return (a.label or a.name):lower() < (b.label or b.name):lower() end)
    return out
end

----------------------------------------------------------------
-- Bootstrap / sync payloads
----------------------------------------------------------------
function AdminApi.SettingsPayload()
    local out = {}
    for _, key in ipairs(AdminPerms.SETTINGS_KEYS) do out[key] = Config[key] end
    out.dashboardGroups = Config.dashboardGroups or {}
    return out
end

function AdminApi.GroupsArray()
    local out = {}
    out[#out + 1] = { name = 'admin', protected = true, perms = AdminPerms.AllPerms() }
    for name, matrix in pairs(AdminStore.perms) do
        if name ~= 'admin' then
            out[#out + 1] = { name = name, protected = false, perms = matrix }
        end
    end
    return out
end

function AdminApi.BuildBootstrap(src)
    return {
        locale = Config.Locale,
        perms = AdminPerms.GetPlayerPerms(src),
        permKeys = AdminPerms.PERMS,
        settings = AdminApi.SettingsPayload(),
        groups = AdminApi.GroupsArray(),
        suggestedGroups = AdminPerms.SUGGESTED_GROUPS,
        jobsList = AdminApi.JobsList(),
        players = AdminApi.OnlinePlayers(),
        meta = {
            locales = AdminPerms.LOCALES,
            targetSystems = AdminPerms.TARGET_SYSTEMS,
            voiceScripts = AdminPerms.VOICE_SCRIPTS,
        },
    }
end

-- Push settings to all clients so their config-driven visuals/controls update.
function AdminApi.Broadcast()
    TriggerClientEvent('msk_handcuffs:syncDefinitions', -1, {
        settings = AdminApi.SettingsPayload(),
    })
end

local function ok(src) return { ok = true, data = AdminApi.BuildBootstrap(src) } end
local function fail(err) return { ok = false, err = err } end

local function setSetting(key, value)
    MySQL.insert.await(
        'INSERT INTO `msk_handcuffs_settings` (`skey`, `svalue`) VALUES (?, ?) ' ..
        'ON DUPLICATE KEY UPDATE `svalue` = VALUES(`svalue`)',
        { key, json.encode(value) }
    )
end

----------------------------------------------------------------
-- Callbacks (client -> server via MSK.Trigger). Every mutation is gated.
----------------------------------------------------------------

-- Public: client pulls the authoritative settings on join.
MSK.Register('msk_handcuffs:admin:getDefinitions', function(_src)
    return { settings = AdminApi.SettingsPayload() }
end)

MSK.Register('msk_handcuffs:admin:bootstrap', function(src)
    if not AdminPerms.CanOpen(src) then return fail('no_permission') end
    return ok(src)
end)

-- Players -------------------------------------------------------
MSK.Register('msk_handcuffs:admin:players:list', function(src)
    if not AdminPerms.Has(src, 'players.view') then return fail('no_permission') end
    return { ok = true, players = AdminApi.OnlinePlayers() }
end)

local ACTION_PERM = {
    cuff = 'players.cuff',
    hardcuff = 'players.cuff',
    uncuff = 'players.uncuff',
    ankletracker = 'players.tracker',
    headbag = 'players.headbag',
    tape = 'players.tape',
}

MSK.Register('msk_handcuffs:admin:player:action', function(src, data)
    if type(data) ~= 'table' then return fail('bad_input') end
    local action = type(data.action) == 'string' and data.action or nil
    local perm = action and ACTION_PERM[action]
    if not perm then return fail('bad_input') end
    if not AdminPerms.Has(src, perm) then return fail('no_permission') end

    local targetId = int(data.serverId, nil)
    if not targetId then return fail('bad_input') end
    local xTarget = MSK.GetPlayerFromId(targetId)
    if not xTarget then return fail('not_found') end
    local id = xTarget.identifier
    local cuffed = Cuffs.IsHandcuffed({ identifier = id })

    if action == 'cuff' then
        if cuffed then return fail('already_cuffed') end
        Cuffs.AdminCuff(targetId, Config.AdminCommands.cuff.playAnimation)
    elseif action == 'hardcuff' then
        Cuffs.AdminHardcuff(targetId)
    elseif action == 'uncuff' then
        if not cuffed then return fail('not_cuffed') end
        Cuffs.AdminUncuff(targetId)
    elseif action == 'ankletracker' then
        if not Config.AnkleTracker.enable then return fail('feature_disabled') end
        Cuffs.AdminAnkleTracker(targetId)
    elseif action == 'headbag' then
        if not Config.HeadBag.enable then return fail('feature_disabled') end
        Cuffs.AdminHeadbag(targetId)
    elseif action == 'tape' then
        if not Config.Tape.enable then return fail('feature_disabled') end
        Cuffs.AdminTape(targetId)
    end

    return { ok = true, players = AdminApi.OnlinePlayers() }
end)

-- Items ---------------------------------------------------------
MSK.Register('msk_handcuffs:admin:items:save', function(src, data)
    if not AdminPerms.Has(src, 'items.manage') then return fail('no_permission') end
    if type(data) ~= 'table' or type(data.items) ~= 'table' then return fail('bad_input') end

    local clean = AdminApi.SanitizeItems(data.items)
    for k, v in pairs(clean) do setSetting(k, v) end
    AdminStore.LoadSettings()
    if Cuffs and Cuffs.RegisterItems then Cuffs.RegisterItems() end -- new items usable without restart
    AdminApi.Broadcast()
    return ok(src)
end)

-- Restrictions --------------------------------------------------
MSK.Register('msk_handcuffs:admin:restrictions:save', function(src, data)
    if not AdminPerms.Has(src, 'restrictions.manage') then return fail('no_permission') end
    if type(data) ~= 'table' or type(data.restrictions) ~= 'table' then return fail('bad_input') end

    setSetting('RestrictItems', AdminApi.SanitizeRestrictions(data.restrictions))
    AdminStore.LoadSettings()
    AdminApi.Broadcast()
    return ok(src)
end)

-- Settings ------------------------------------------------------
MSK.Register('msk_handcuffs:admin:settings:save', function(src, data)
    if not AdminPerms.Has(src, 'settings.manage') then return fail('no_permission') end
    if type(data) ~= 'table' or type(data.settings) ~= 'table' then return fail('bad_input') end

    local clean = AdminApi.SanitizeSettings(data.settings)
    for k, v in pairs(clean) do setSetting(k, v) end

    local oldCmd = Config.adminCommand
    AdminStore.LoadSettings()
    if Config.adminCommand ~= oldCmd then AdminCommand.Register(Config.adminCommand) end
    if Cuffs and Cuffs.RegisterItems then Cuffs.RegisterItems() end -- ankletracker/headbag/tape items usable without restart
    AdminApi.Broadcast()
    return ok(src)
end)

-- Permissions ---------------------------------------------------
local function normGroup(name)
    if type(name) ~= 'string' then return nil end
    name = name:lower():gsub('^group%.', '')
    if not name:match(ID_PATTERN) then return nil end
    return name
end

MSK.Register('msk_handcuffs:admin:perms:saveGroup', function(src, data)
    if not AdminPerms.Has(src, 'permissions.manage') then return fail('no_permission') end
    local name = normGroup(type(data) == 'table' and data.name or nil)
    if not name then return fail('bad_name') end
    if AdminPerms.IsProtected(name) then return fail('protected') end
    if AdminPerms.IsBlacklisted(name) then return fail('blacklisted') end

    local matrix = {}
    local incoming = type(data) == 'table' and type(data.perms) == 'table' and data.perms or {}
    for _, key in ipairs(AdminPerms.PERMS) do
        matrix[key] = incoming[key] == true
    end

    MySQL.insert.await(
        'INSERT INTO `msk_handcuffs_permissions` (`group_name`, `perms`) VALUES (?, ?) ' ..
        'ON DUPLICATE KEY UPDATE `perms` = VALUES(`perms`)',
        { name, json.encode(matrix) }
    )
    AdminStore.LoadPermissions()
    AdminPerms.EnsureAces()
    AdminPerms.Invalidate()
    return ok(src)
end)

MSK.Register('msk_handcuffs:admin:perms:deleteGroup', function(src, data)
    if not AdminPerms.Has(src, 'permissions.manage') then return fail('no_permission') end
    local name = normGroup(type(data) == 'table' and data.name or nil)
    if not name then return fail('bad_name') end
    if AdminPerms.IsProtected(name) then return fail('protected') end

    MySQL.query.await('DELETE FROM `msk_handcuffs_permissions` WHERE `group_name` = ?', { name })
    AdminStore.LoadPermissions()
    AdminPerms.Invalidate()
    return ok(src)
end)

MSK.Register('msk_handcuffs:admin:perms:dashboardGroups', function(src, data)
    if not AdminPerms.Has(src, 'permissions.manage') then return fail('no_permission') end
    local list, seen = {}, {}
    if type(data) == 'table' and type(data.groups) == 'table' then
        for _, g in ipairs(data.groups) do
            local name = normGroup(g)
            if name and not AdminPerms.IsBlacklisted(name) and not AdminPerms.IsProtected(name) and not seen[name] then
                seen[name] = true
                list[#list + 1] = name
            end
        end
    end
    setSetting('dashboardGroups', list)
    AdminStore.LoadSettings()
    AdminPerms.EnsureAces()
    AdminPerms.Invalidate()
    return ok(src)
end)

MSK.Register('msk_handcuffs:admin:perms:validateGroup', function(src, data)
    if not AdminPerms.Has(src, 'permissions.manage') then return fail('no_permission') end
    local name = normGroup(type(data) == 'table' and data.name or nil)
    if not name then return { ok = true, valid = false } end
    if AdminPerms.IsBlacklisted(name) then return { ok = true, valid = false, blacklisted = true } end

    -- A group that was never used before has no ace object yet, so the membership
    -- check below would come back empty for everyone. Register it first and give
    -- the command buffer a frame to catch up.
    AdminPerms.EnsureAce(name)
    Wait(0)

    local found = false
    for _, pid in ipairs(GetPlayers()) do
        if AdminPerms.PlayerInGroup(tonumber(pid), name) then found = true; break end
    end
    return { ok = true, valid = true, exists = found }
end)
