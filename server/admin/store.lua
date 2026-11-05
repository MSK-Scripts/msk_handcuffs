AdminStore = AdminStore or {}

-- In-memory permission matrix: [group_name] = { [perm] = true }
AdminStore.perms = {}
AdminStore.ready = false

----------------------------------------------------------------
-- JSON helpers
----------------------------------------------------------------
local function jdecode(s)
    if type(s) ~= 'string' then return false end
    local ok, v = pcall(json.decode, s)
    if not ok then return false end
    return true, v
end
AdminStore.Decode = jdecode

----------------------------------------------------------------
-- Load settings from the DB into Config.* (the runtime source of truth used by
-- server/main.lua, client/main.lua — all unchanged). dashboardGroups is stored
-- as its own row and mirrored to Config.dashboardGroups.
----------------------------------------------------------------
function AdminStore.LoadSettings()
    local rows = MySQL.query.await('SELECT `skey`, `svalue` FROM `msk_handcuffs_settings`') or {}
    for _, row in ipairs(rows) do
        if row.skey ~= '__seeded__' and row.skey ~= 'dashboardGroups' then
            local ok, v = jdecode(row.svalue)
            if ok then Config[row.skey] = v end
        end
    end

    for _, row in ipairs(rows) do
        if row.skey == 'dashboardGroups' then
            local ok, v = jdecode(row.svalue)
            if ok and type(v) == 'table' then Config.dashboardGroups = v end
        end
    end
end

function AdminStore.LoadPermissions()
    AdminStore.perms = {}
    local rows = MySQL.query.await('SELECT `group_name`, `perms` FROM `msk_handcuffs_permissions`') or {}
    for _, row in ipairs(rows) do
        local ok, p = jdecode(row.perms)
        AdminStore.perms[row.group_name] = (ok and type(p) == 'table') and p or {}
    end
end

function AdminStore.LoadAll()
    AdminStore.LoadSettings()
    AdminStore.LoadPermissions()
    AdminStore.ready = true
end
