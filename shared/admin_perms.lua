AdminPerms = AdminPerms or {}

----------------------------------------------------------------
-- Permission keys. Order matters: the NUI renders the matrix in this order.
--   players.*     -> Players tab (live cuff/uncuff/tracker/headbag/tape)
--   items.manage  -> Items tab (cuff/hardcuff/uncuff item config)
--   restrictions.manage -> Restrictions tab (RestrictItems job matrix)
--   settings.manage / permissions.manage -> management rights
----------------------------------------------------------------
AdminPerms.PERMS = {
    'players.view',
    'players.cuff',
    'players.uncuff',
    'players.tracker',
    'players.headbag',
    'players.tape',
    'items.manage',
    'restrictions.manage',
    'settings.manage',
    'permissions.manage',
}

-- Settings that may be edited from the dashboard (requires `settings.manage`).
-- These are the DB-managed keys (see config/settings.lua). Static code hooks
-- (config/static.lua: functions, Method, Props) are intentionally NOT here.
-- The item lists (cuffItems/…) are edited via the Items tab (items.manage) and
-- RestrictItems via the Restrictions tab (restrictions.manage) — but they are
-- persisted as settings rows, so they must be listed here too.
AdminPerms.SETTINGS_KEYS = {
    'Locale', 'Debug', 'VersionChecker',
    'MaxDistance',
    'DiscordLog', 'DiscordWebhook', 'botColor', 'botName', 'botAvatar',
    'Target',
    'cuffItems', 'hardcuffItems', 'uncuffItems', 'ItemSettings', 'GiveCuffItemBack', 'consumeUncuffItem',
    'RestrictItems',
    'Commands',
    'AnkleTracker', 'HeadBag', 'Tape',
    'UncuffOnPlayerDied', 'checkOnPlayerLoaded',
    'playSound', 'Timer', 'EnableProps',
    'Voice',
    'AdminGroups', 'AdminCommands',
    'adminCommand', 'BrandTag', 'Theme',
}

-- Valid values used by the api sanitiser + UI dropdowns.
AdminPerms.LOCALES = { 'de', 'en', 'hu' }
AdminPerms.TARGET_SYSTEMS = { 'auto', 'ox_target', 'qb-target' }
AdminPerms.VOICE_SCRIPTS = { 'pma', 'salty' }

-- Editable UI colour keys (hex strings) managed via the Settings tab.
-- Keep in sync with web/src/lib/theme.ts (DEFAULT_THEME / THEME_KEYS).
AdminPerms.THEME_KEYS = { 'accent', 'bg', 'panel', 'textPrimary', 'textSecondary' }
AdminPerms.DEFAULT_THEME = {
    accent = '#00E676',
    bg = '#0a0b0d',
    panel = '#131317',
    textPrimary = '#f0ede8',
    textSecondary = '#b0adb8',
}

-- Suggested group names shown in the UI when adding a new group.
AdminPerms.SUGGESTED_GROUPS = { 'admin', 'mod', 'dev' }

-- group.admin always has every right and can never be edited.
AdminPerms.PROTECTED_GROUPS = { admin = true }

-- group.user may NEVER open the dashboard and can never be granted rights.
AdminPerms.BLACKLIST_GROUPS = { user = true }

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------
function AdminPerms.AllPerms()
    local t = {}
    for _, p in ipairs(AdminPerms.PERMS) do t[p] = true end
    return t
end

function AdminPerms.IsProtected(group)
    return AdminPerms.PROTECTED_GROUPS[tostring(group):lower()] == true
end

function AdminPerms.IsBlacklisted(group)
    return AdminPerms.BLACKLIST_GROUPS[tostring(group):lower()] == true
end
