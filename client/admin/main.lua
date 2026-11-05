AdminState = AdminState or {}

-- Opens the admin dashboard NUI when the server grants access.
RegisterNetEvent('msk_handcuffs:admin:open', function(payload)
    if AdminState.isNuiOpen then return end
    AdminState.isNuiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'openAdmin', data = payload })
end)

-- Safety net: on (re)start, force-release any NUI focus left stuck from a
-- previous session so a `restart msk_handcuffs` always frees the cursor.
AddEventHandler('onClientResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    SetNuiFocus(false, false)
    AdminState.isNuiOpen = false
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    SetNuiFocus(false, false)
end)
