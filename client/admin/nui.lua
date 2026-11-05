-- NUI callbacks for the admin dashboard. CRUD callbacks forward to the gated
-- server callbacks and return the server response verbatim.
AdminState = AdminState or {}

local function forward(event)
    return function(data, cb)
        local res = MSK.Trigger(event, data)
        cb(res or { ok = false, err = 'no_response' })
    end
end

RegisterNUICallback('admin:close', function(_data, cb)
    SetNuiFocus(false, false)
    AdminState.isNuiOpen = false
    cb('ok')
end)

RegisterNUICallback('admin:bootstrap', forward('msk_handcuffs:admin:bootstrap'))

-- Players (live)
RegisterNUICallback('admin:players:list', forward('msk_handcuffs:admin:players:list'))
RegisterNUICallback('admin:player:action', forward('msk_handcuffs:admin:player:action'))

-- Items
RegisterNUICallback('admin:items:save', forward('msk_handcuffs:admin:items:save'))

-- Restrictions
RegisterNUICallback('admin:restrictions:save', forward('msk_handcuffs:admin:restrictions:save'))

-- Settings
RegisterNUICallback('admin:settings:save', forward('msk_handcuffs:admin:settings:save'))

-- Permissions
RegisterNUICallback('admin:perms:saveGroup', forward('msk_handcuffs:admin:perms:saveGroup'))
RegisterNUICallback('admin:perms:deleteGroup', forward('msk_handcuffs:admin:perms:deleteGroup'))
RegisterNUICallback('admin:perms:dashboardGroups', forward('msk_handcuffs:admin:perms:dashboardGroups'))
RegisterNUICallback('admin:perms:validateGroup', forward('msk_handcuffs:admin:perms:validateGroup'))
