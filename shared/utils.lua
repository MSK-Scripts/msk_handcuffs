----------------------------------------------------------------
-- Shared helpers (client + server)
----------------------------------------------------------------

-- Debug logging wrapper. Silent unless Config.Debug is enabled.
function logging(code, ...)
    if not Config.Debug then return end
    MSK.Logging(code, ...)
end

-- Translation shorthand: T('key', ...) -> Translation[Config.Locale]['key'] (optionally formatted).
function T(key, ...)
    local line = Translation[Config.Locale] and Translation[Config.Locale][key]
    if not line then return key end
    if ... ~= nil then return line:format(...) end
    return line
end

-- Canonical, replicated statebag keys used for handcuff status.
-- These are the single source of truth that other resources / clients can read.
StateKeys = {
    isHandcuffed    = 'isHandcuffed',
    isHardcuffed    = 'isHardcuffed',
    hasAnkleTracker = 'hasAnkleTracker',
    hasHeadbag      = 'hasHeadbag',
    hasTape         = 'hasTape',
    cuffItem        = 'cuffItem',
    -- Compatibility flag read by ox_inventory to block inventory while cuffed.
    inventoryCuffed = 'cuffed',
}
