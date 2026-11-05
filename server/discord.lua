----------------------------------------------------------------
-- Discord logging (via MSK.AddWebhook)
-- The webhook URL is DB-managed: set it in the admin dashboard (Settings tab)
-- or as Config.DiscordWebhook in config/settings.lua.
----------------------------------------------------------------
DiscordLog = {}

local function send(description, xPlayer, xTarget)
    if not Config.DiscordLog then return end

    local webhookLink = Config.DiscordWebhook
    if type(webhookLink) ~= 'string' or webhookLink == "" then return end

    MSK.AddWebhook(
        webhookLink,
        Config.botColor,
        Config.botName,
        Config.botAvatar,
        "MSK Handcuffs",
        description,
        {
            { name = "Officer", value = ("%s (ID: %s)"):format(xPlayer.name, xPlayer.source), inline = true },
            { name = "Target",  value = ("%s (ID: %s)"):format(xTarget.name, xTarget.source), inline = true },
        },
        { text = "© MSK Scripts", link = "https://i.imgur.com/PizJGsh.png" },
        "%d/%m/%Y %H:%M:%S"
    )
end

local actionVerb = {
    cuff     = 'cuffed',
    hardcuff = 'hardcuffed',
    uncuff   = 'uncuffed',
}

-- cuff / hardcuff / uncuff
function DiscordLog.Action(xPlayer, xTarget, action)
    local verb = actionVerb[action]
    if not verb then return end
    send(('**%s (ID: %s)** has %s **%s (ID: %s)**'):format(
        xPlayer.name, xPlayer.source, verb, xTarget.name, xTarget.source), xPlayer, xTarget)
end

function DiscordLog.AnkleTracker(xPlayer, xTarget, activated)
    send(('**%s (ID: %s)** %s the AnkleTracker on **%s (ID: %s)**'):format(
        xPlayer.name, xPlayer.source, activated and 'activated' or 'deactivated',
        xTarget.name, xTarget.source), xPlayer, xTarget)
end

function DiscordLog.Headbag(xPlayer, xTarget, activated)
    send(('**%s (ID: %s)** put %s a Headbag on **%s (ID: %s)**'):format(
        xPlayer.name, xPlayer.source, activated and 'on' or 'off',
        xTarget.name, xTarget.source), xPlayer, xTarget)
end

function DiscordLog.Tape(xPlayer, xTarget, activated)
    send(('**%s (ID: %s)** put %s Tape on **%s (ID: %s)**'):format(
        xPlayer.name, xPlayer.source, activated and 'on' or 'off',
        xTarget.name, xTarget.source), xPlayer, xTarget)
end
