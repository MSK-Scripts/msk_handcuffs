Config = {}
----------------------------------------------------------------
-- DB-MANAGED SETTINGS
--
-- Everything in this file is seeded into `msk_handcuffs_settings` on first start
-- and afterwards LOADED FROM THE DB (see server/admin/*). The values below are
-- therefore only the initial defaults — edit them live in the in-game admin
-- dashboard (default command /handcuffadmin). Code hooks that can't live in a DB
-- (functions, prop hashes, the control blacklist) are in config/static.lua.
----------------------------------------------------------------
Config.Locale = 'de'
Config.Debug = false
Config.VersionChecker = true

-- Maximum distance (server-validated) between cop and target for any interaction.
-- A bit more lenient than the client's reach to absorb latency/movement.
Config.MaxDistance = 3.0
----------------------------------------------------------------
-- Discord logging (webhook editable in the dashboard's Settings tab)
Config.DiscordLog = true
Config.DiscordWebhook = "" -- Insert your Discord webhook URL (or set it in the dashboard)
Config.botColor = "6205745" -- https://www.mathsisfun.com/hexadecimal-decimal-colors.html
Config.botName = "MSK Scripts"
Config.botAvatar = "https://i.imgur.com/PizJGsh.png"
----------------------------------------------------------------
Config.Target = {
    enable = true, -- Set false to disable the target integration (ox_target / qb-target)

    -- 'auto' = use whichever of ox_target / qb-target is running.
    -- Force a system with 'ox_target' or 'qb-target'.
    system = 'auto',

    undragHotkey = 'X', -- Hotkey to undrag somebody // Only if option drag is enabled

    options = {
        cuff = true,
        hardcuff = true,
        uncuff = true,

        ankletracker = true,
        headbag = true,
        tape = true,

        drag = true,
        putInCar = true,
        putOutOfCar = true,
    }
}
----------------------------------------------------------------
-- You have to use 'cuffItems' before you can use 'hardcuffItems'
Config.cuffItems = {'cuffs', 'cable_ties'} -- DisableAllControlActions except Movement
Config.hardcuffItems = {'hardcuff'} -- Freeze Player Position
Config.uncuffItems = {'cuff_keys', 'scissors'}

Config.ItemSettings = {
    -- ['cuff_item'] = {'uncuff_item_1', 'uncuff_item_2', ...}
    -- You can only uncuff someone with 'uncuff_item' if the player was cuffed with the 'cuff_item'.
    -- Please don't add hardcuffItems, ankletracker, headbag or tape here!

    ['cuffs'] = {'cuff_keys'},
    ['cable_ties'] = {'scissors'},
}

-- Only add cuff items here and NOT uncuff items.
-- Set to false if you don't want to give the cuff item back when you uncuff someone.
Config.GiveCuffItemBack = {
    ['cuffs'] = true,
    ['cable_ties'] = false,
    ['hardcuff'] = true,
    ['ankletracker'] = true,
    ['headbag'] = true,
    ['tape'] = true,
}

-- Consume the uncuff item (e.g. cuff_keys / scissors) when uncuffing someone.
-- Default false = the key stays in the inventory (reusable).
Config.consumeUncuffItem = false

-- Restrict which item/option each player or job may use.
Config.RestrictItems = {
    enable = true, -- Set to true to restrict items/options

    -- Default options for every player and job
    defaultItems = {
        cuffItem = 'cable_ties',
        hardcuffItem = 'hardcuff',
        uncuffItem = 'scissors',
        enableAnkletracker = false,
        enableHeadbag = true,
        enableTape = true,
    },

    -- Specific options for jobs
    jobItems = {
        ['police'] = {
            cuffItem = 'cuffs',
            hardcuffItem = 'hardcuff',
            uncuffItem = 'cuff_keys',
            enableAnkletracker = true,
            enableHeadbag = true,
            enableTape = true,
        },
        ['doj'] = {
            cuffItem = 'cuffs',
            hardcuffItem = 'hardcuff',
            uncuffItem = 'cuff_keys',
            enableAnkletracker = true,
            enableHeadbag = true,
            enableTape = true,
        },
    }
}

Config.Commands = {
    cuff = {
        enable = true,
        command = 'cuff',
        item = 'cable_ties', -- Item for non specific jobs
        jobs = {
            ['police'] = 'cuffs',
            ['doj'] = 'cuffs',
        }
    },
    hardcuff = {
        enable = true,
        command = 'hardcuff',
        item = 'hardcuff',
        jobs = {
            ['police'] = 'hardcuff',
            ['doj'] = 'hardcuff',
        }
    },
    uncuff = {
        enable = true,
        command = 'uncuff',
        item = 'scissors',
        jobs = {
            ['police'] = 'cuff_keys',
            ['doj'] = 'cuff_keys',
        }
    },
}
----------------------------------------------------------------
-- Jobs can track the player's position // Saved even if the player reconnects
Config.AnkleTracker = {
    enable = true,
    refreshTime = 5.0, -- in seconds // Refresh time when player is NOT in OneSync distance // In OneSync distance it refreshes realtime
    item = 'ankletracker', -- Use this item to activate/deactivate // Will be removed after use
    removeItem = 'ankletracker_key', -- Item to remove the AnkleTracker // Must differ from the item above!
    consumeRemoveItem = false, -- If true, the removeItem is consumed when removing the ankletracker
    command = 'ankletracker', -- Needs the item in inventory // Set to false to deactivate the command
    blip = {id = 1, color = 15, scale = 0.8, prefix = 'Track'},
    jobs = {
        -- Jobs who can see players with an ankletracker
        'police',
        'fib',
        'sheriff',
        'doj'
    },
}
----------------------------------------------------------------
-- Bag on the head of the player and blackscreen
Config.HeadBag = {
    enable = true,
    item = 'headbag',
    removeItem = 'headbag_key', -- Must differ from the item above!
    needItemToRemove = false, -- If false, no item is needed to remove the headbag
    consumeRemoveItem = false, -- If true, the removeItem is consumed when removing (only when needItemToRemove is on)
    command = 'headbag', -- Set to false to deactivate the command
}
----------------------------------------------------------------
-- Tape to mute players
Config.Tape = {
    enable = true,
    item = 'tape',
    removeItem = 'tape_key', -- Must differ from the item above!
    needItemToRemove = false, -- If false, no item is needed to remove the tape
    consumeRemoveItem = false, -- If true, the removeItem is consumed when removing (only when needItemToRemove is on)
    command = 'tape', -- Set to false to deactivate the command
}
----------------------------------------------------------------
Config.UncuffOnPlayerDied = true -- Set to false if you don't want to uncuff the player when he dies

-- Re-apply status from DB on PlayerLoaded / player joined server
Config.checkOnPlayerLoaded = {
    cuff = true, -- recommended: true
    hardcuff = false,
    ankleTracker = true, -- recommended: true
    headbag = false,
    tape = false,
}

Config.playSound = {
    enable = true, -- Play sound on cuff and uncuff

    -- Add your own sounds here // Upload them into web/public/sounds
    cuff = 'cuff.ogg',
    hardcuff = 'cuff.ogg',
    uncuff = 'uncuff.ogg',
    ankleTracker = 'cuff.ogg',
    headBag = false,
    tape = false,
}

Config.Timer = {
    enable = true, -- Set false to disable the auto-uncuff timer
    time = 30 -- in minutes // After this time the player gets uncuffed (server-driven)
}

Config.EnableProps = true -- Set false to completely disable props
----------------------------------------------------------------
-- Voice: deactivate the radio channel while someone is handcuffed
Config.Voice = {
    enable = false, -- Deactivate the radio channel while someone is handcuffed
    voice = 'pma' -- Set to 'salty' or 'pma'
}
----------------------------------------------------------------
-- Admin Commands (chat commands; the in-game dashboard is separate)
Config.AdminGroups = {'superadmin', 'admin'} -- You can set multiple groups

Config.AdminCommands = {
    cuff = {
        enable = true,
        command = 'adcuff', -- /adcuff playerID
        playAnimation = false
    },
    hardcuff = {
        enable = true,
        command = 'adhardcuff' -- /adhardcuff playerID
    },
    uncuff = {
        enable = true,
        command = 'aduncuff' -- /aduncuff playerID
    },
    ankleTracker = {
        enable = true,
        command = 'adankletracker' -- /adankletracker playerID
    },
    headbag = {
        enable = true,
        command = 'adheadbag' -- /adheadbag playerID
    },
    tape = {
        enable = true,
        command = 'adtape' -- /adtape playerID
    }
}
----------------------------------------------------------------
-- In-Game Admin Dashboard
Config.adminCommand = 'handcuffadmin' -- Command to open the admin dashboard
Config.dashboardGroups = { 'mod' } -- ACE / framework groups (besides 'admin') that may open it
Config.BrandTag = 'MSK' -- Small badge shown next to the dashboard title
Config.Theme = {
    accent = '#00E676',
    bg = '#0a0b0d',
    panel = '#131317',
    textPrimary = '#f0ede8',
    textSecondary = '#b0adb8',
}
