----------------------------------------------------------------
-- Persistence layer (oxmysql)
--
-- Authoritative status lives in-memory in `Handcuffs[identifier]` and is
-- mirrored to MySQL. The MySQL row is the source of truth across restarts.
-- A one-time, idempotent migration imports the legacy database.json.
----------------------------------------------------------------

local RESOURCE = GetCurrentResourceName()

-- In-memory authoritative state, keyed by player identifier.
Handcuffs = {}

-- Set true once schema + migration + initial load have finished.
DatabaseReady = false

Database = {}

local SCHEMA = [[
CREATE TABLE IF NOT EXISTS `msk_handcuffs` (
    `identifier` VARCHAR(64) NOT NULL,
    `isCuffed` TINYINT(1) NOT NULL DEFAULT 0,
    `cuffItem` VARCHAR(64) DEFAULT NULL,
    `isAdminCuffed` TINYINT(1) NOT NULL DEFAULT 0,
    `isHardcuffed` TINYINT(1) NOT NULL DEFAULT 0,
    `hardcuffItem` VARCHAR(64) DEFAULT NULL,
    `hasAnkleTracker` TINYINT(1) NOT NULL DEFAULT 0,
    `hasHeadbag` TINYINT(1) NOT NULL DEFAULT 0,
    `hasTape` TINYINT(1) NOT NULL DEFAULT 0,
    PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
]]

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

-- An entry is "empty" when nothing is active anymore -> the row can be removed.
local function isEmpty(d)
    return not (d.isCuffed or d.isHardcuffed or d.isAdminCuffed
        or d.hasAnkleTracker or d.hasHeadbag or d.hasTape)
end

local function rowToState(r)
    return {
        isCuffed        = r.isCuffed == 1,
        cuffItem        = r.cuffItem,
        isAdminCuffed   = r.isAdminCuffed == 1,
        isHardcuffed    = r.isHardcuffed == 1,
        hardcuffItem    = r.hardcuffItem,
        hasAnkleTracker = r.hasAnkleTracker == 1,
        hasHeadbag      = r.hasHeadbag == 1,
        hasTape         = r.hasTape == 1,
    }
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

-- Get (never auto-creates).
function Database.Get(identifier)
    return Handcuffs[identifier]
end

-- Get or create the in-memory entry for an identifier.
function Database.Ensure(identifier)
    if not Handcuffs[identifier] then Handcuffs[identifier] = {} end
    return Handcuffs[identifier]
end

-- Persist a single identifier (fire-and-forget). Removes the row + memory
-- entry once it carries no active status anymore.
function Database.Save(identifier)
    local d = Handcuffs[identifier]

    if not d or isEmpty(d) then
        Handcuffs[identifier] = nil
        MySQL.update('DELETE FROM msk_handcuffs WHERE identifier = ?', { identifier })
        return
    end

    MySQL.insert([[
        INSERT INTO msk_handcuffs
            (identifier, isCuffed, cuffItem, isAdminCuffed, isHardcuffed, hardcuffItem, hasAnkleTracker, hasHeadbag, hasTape)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            isCuffed = VALUES(isCuffed),
            cuffItem = VALUES(cuffItem),
            isAdminCuffed = VALUES(isAdminCuffed),
            isHardcuffed = VALUES(isHardcuffed),
            hardcuffItem = VALUES(hardcuffItem),
            hasAnkleTracker = VALUES(hasAnkleTracker),
            hasHeadbag = VALUES(hasHeadbag),
            hasTape = VALUES(hasTape)
    ]], {
        identifier,
        d.isCuffed and 1 or 0,
        d.cuffItem,
        d.isAdminCuffed and 1 or 0,
        d.isHardcuffed and 1 or 0,
        d.hardcuffItem,
        d.hasAnkleTracker and 1 or 0,
        d.hasHeadbag and 1 or 0,
        d.hasTape and 1 or 0,
    })
end

----------------------------------------------------------------
-- Initialization: schema -> migration -> load
----------------------------------------------------------------

local function loadAll()
    local rows = MySQL.query.await('SELECT * FROM msk_handcuffs') or {}
    for i = 1, #rows do
        Handcuffs[rows[i].identifier] = rowToState(rows[i])
    end
    return #rows
end

-- One-time, non-destructive import of the legacy database.json.
-- Only inserts identifiers that don't already exist in SQL, then neutralizes
-- the json file (backup kept) so it never migrates twice.
local function migrateFromJson()
    local raw = LoadResourceFile(RESOURCE, 'database.json')
    if not raw then return end

    local data = json.decode(raw)
    if type(data) ~= 'table' or next(data) == nil then return end

    local migrated = 0
    for identifier, entry in pairs(data) do
        if type(entry) == 'table' and type(identifier) == 'string' then
            local exists = MySQL.scalar.await('SELECT 1 FROM msk_handcuffs WHERE identifier = ?', { identifier })

            if not exists then
                -- normalize legacy key 'ankleTracker' -> 'hasAnkleTracker'
                local hasAnkle = entry.hasAnkleTracker or entry.ankleTracker or false

                MySQL.insert.await([[
                    INSERT INTO msk_handcuffs
                        (identifier, isCuffed, cuffItem, isAdminCuffed, isHardcuffed, hardcuffItem, hasAnkleTracker, hasHeadbag, hasTape)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                ]], {
                    identifier,
                    entry.isCuffed and 1 or 0,
                    entry.cuffItem,
                    entry.isAdminCuffed and 1 or 0,
                    entry.isHardcuffed and 1 or 0,
                    entry.hardcuffItem,
                    hasAnkle and 1 or 0,
                    entry.hasHeadbag and 1 or 0,
                    entry.hasTape and 1 or 0,
                })
                migrated = migrated + 1
            end
        end
    end

    -- Back up the original and neutralize so the migration is one-shot.
    SaveResourceFile(RESOURCE, 'database.migrated.bak.json', raw, -1)
    SaveResourceFile(RESOURCE, 'database.json', '{}', -1)

    MSK.Logging('info', ('[msk_handcuffs] Migrated ^3%s^0 entries from database.json to MySQL (backup: database.migrated.bak.json).'):format(migrated))
end

CreateThread(function()
    while GetResourceState('oxmysql') ~= 'started' do Wait(100) end

    MySQL.query.await(SCHEMA)
    migrateFromJson()
    local loaded = loadAll()

    DatabaseReady = true
    MSK.Logging('info', ('[msk_handcuffs] Database ready — ^3%s^0 stored entries loaded.'):format(loaded))
end)
