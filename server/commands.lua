----------------------------------------------------------------
-- Commands
----------------------------------------------------------------

local playerIdParam = {
    { name = 'playerId', type = 'playerId', help = 'Target players server id' }
}

----------------------------------------------------------------
-- Admin commands (server-authoritative, no items required)
----------------------------------------------------------------
if Config.AdminCommands.cuff.enable then
    MSK.RegisterCommand(Config.AdminCommands.cuff.command, function(source, args)
        local targetId = args.playerId
        if Cuffs.IsHandcuffed({source = targetId}) then return end

        Cuffs.AdminCuff(targetId, Config.AdminCommands.cuff.playAnimation)
        if source > 0 then Config.Notification(source, T('admin_cuff', targetId), 'info') end
    end, { allowConsole = true, restricted = Config.AdminGroups, help = 'Cuff a Player', params = playerIdParam })
end

if Config.AdminCommands.hardcuff.enable then
    MSK.RegisterCommand(Config.AdminCommands.hardcuff.command, function(source, args)
        local targetId = args.playerId
        Cuffs.AdminHardcuff(targetId)
        if source > 0 then Config.Notification(source, T('admin_hardcuff', targetId), 'info') end
    end, { allowConsole = true, restricted = Config.AdminGroups, help = 'Hardcuff a Player', params = playerIdParam })
end

if Config.AdminCommands.uncuff.enable then
    MSK.RegisterCommand(Config.AdminCommands.uncuff.command, function(source, args)
        local targetId = args.playerId
        if not Cuffs.IsHandcuffed({source = targetId}) then return end

        Cuffs.AdminUncuff(targetId)
        if source > 0 then Config.Notification(source, T('admin_uncuff', targetId), 'info') end
    end, { allowConsole = true, restricted = Config.AdminGroups, help = 'Uncuff a Player', params = playerIdParam })
end

if Config.AdminCommands.ankleTracker.enable and Config.AnkleTracker.enable then
    MSK.RegisterCommand(Config.AdminCommands.ankleTracker.command, function(source, args)
        local active = Cuffs.AdminAnkleTracker(args.playerId)
        if source > 0 then
            Config.Notification(source, T(active and 'admin_ankletracker_activated' or 'admin_ankletracker_deactivated', args.playerId), 'info')
        end
    end, { allowConsole = true, restricted = Config.AdminGroups, help = 'Toggle Ankletracker for a Player', params = playerIdParam })
end

if Config.AdminCommands.headbag.enable and Config.HeadBag.enable then
    MSK.RegisterCommand(Config.AdminCommands.headbag.command, function(source, args)
        local active = Cuffs.AdminHeadbag(args.playerId)
        if source > 0 then
            Config.Notification(source, T(active and 'admin_headbag_activated' or 'admin_headbag_deactivated', args.playerId), 'info')
        end
    end, { allowConsole = true, restricted = Config.AdminGroups, help = 'Toggle Headbag for a Player', params = playerIdParam })
end

if Config.AdminCommands.tape.enable and Config.Tape.enable then
    MSK.RegisterCommand(Config.AdminCommands.tape.command, function(source, args)
        local active = Cuffs.AdminTape(args.playerId)
        if source > 0 then
            Config.Notification(source, T(active and 'admin_tape_activated' or 'admin_tape_deactivated', args.playerId), 'info')
        end
    end, { allowConsole = true, restricted = Config.AdminGroups, help = 'Toggle Tape for a Player', params = playerIdParam })
end

----------------------------------------------------------------
-- Player commands -> bounce to the caller's client, which runs the
-- interaction UX and sends a server-validated request.
----------------------------------------------------------------
if Config.Commands.cuff.enable then
    MSK.RegisterCommand(Config.Commands.cuff.command, function(xPlayer)
        local item = Config.Commands.cuff.jobs[xPlayer.job.name] or Config.Commands.cuff.item
        TriggerClientEvent('msk_handcuffs:useItem', xPlayer.source, 'cuff', item)
    end, { allowConsole = false, returnPlayer = true, help = 'Handcuff the player next to you' })
end

if Config.Commands.hardcuff.enable then
    MSK.RegisterCommand(Config.Commands.hardcuff.command, function(xPlayer)
        local item = Config.Commands.hardcuff.jobs[xPlayer.job.name] or Config.Commands.hardcuff.item
        TriggerClientEvent('msk_handcuffs:useItem', xPlayer.source, 'hardcuff', item)
    end, { allowConsole = false, returnPlayer = true, help = 'Hardcuff the player next to you' })
end

if Config.Commands.uncuff.enable then
    MSK.RegisterCommand(Config.Commands.uncuff.command, function(xPlayer)
        local item = Config.Commands.uncuff.jobs[xPlayer.job.name] or Config.Commands.uncuff.item
        TriggerClientEvent('msk_handcuffs:useItem', xPlayer.source, 'uncuff', item)
    end, { allowConsole = false, returnPlayer = true, help = 'Uncuff the player next to you' })
end

if Config.AnkleTracker.enable and Config.AnkleTracker.command and Config.AnkleTracker.command ~= 'false' then
    MSK.RegisterCommand(Config.AnkleTracker.command, function(source)
        TriggerClientEvent('msk_handcuffs:useItem', source, 'ankletracker', false)
    end, { allowConsole = false, help = 'Set Ankletracker on the player next to you' })
end

if Config.HeadBag.enable and Config.HeadBag.command and Config.HeadBag.command ~= 'false' then
    MSK.RegisterCommand(Config.HeadBag.command, function(source)
        TriggerClientEvent('msk_handcuffs:useItem', source, 'headbag', false)
    end, { allowConsole = false, help = 'Set Headbag on the player next to you' })
end

if Config.Tape.enable and Config.Tape.command and Config.Tape.command ~= 'false' then
    MSK.RegisterCommand(Config.Tape.command, function(source)
        TriggerClientEvent('msk_handcuffs:useItem', source, 'tape', false)
    end, { allowConsole = false, help = 'Set Tape on the player next to you' })
end
