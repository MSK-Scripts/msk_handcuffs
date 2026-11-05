----------------------------------------------------------------
-- Attached props (cuffs, cuff key, ankletracker, headbag, tape)
----------------------------------------------------------------
Props = {}

local handles = {}

local function attach(name, model, bone, off, rot)
    if not Config.EnableProps or not model then return end
    if handles[name] and DoesEntityExist(handles[name]) then return end

    MSK.Request.Model(model)
    local ped = PlayerPedId()
    local obj = CreateObject(model, 0.0, 0.0, 0.0, true, true, true)

    AttachEntityToEntity(obj, ped, GetPedBoneIndex(ped, bone),
        off.x, off.y, off.z, rot.x, rot.y, rot.z,
        true, true, false, true, 0, true)

    handles[name] = obj
    SetModelAsNoLongerNeeded(model)
end

local function detach(name)
    local obj = handles[name]
    if not obj then return end
    if DoesEntityExist(obj) then
        DeleteEntity(obj)
        SetEntityAsNoLongerNeeded(obj)
    end
    handles[name] = nil
end

----------------------------------------------------------------
function Props.SetCuff(item)
    local model = (item and Config.Props[item]) or `p_cs_cuffs_02_s`
    attach('cuff', model, 60309, vec3(-0.055, 0.06, 0.04), vec3(80.0, 155.0, 80.0))
end
function Props.DeleteCuff() detach('cuff') end

function Props.SetCuffKey(item)
    local model = (item and Config.Props[item]) or `prop_cuff_keys_01`
    attach('cuffKey', model, 28422, vec3(0.055, 0.05, 0.0), vec3(0.0, 0.0, 0.0))
end
function Props.DeleteCuffKey() detach('cuffKey') end

function Props.SetAnkletracker()
    attach('ankletracker', Config.Props[Config.AnkleTracker.item], 60309, vec3(-0.055, 0.06, 0.04), vec3(80.0, 155.0, 80.0))
end
function Props.DeleteAnkletracker() detach('ankletracker') end

function Props.SetHeadbag()
    attach('headbag', Config.Props[Config.HeadBag.item], 12844, vec3(0.2, 0.02, 0.0), vec3(0.0, 270.0, 80.0))
end
function Props.DeleteHeadbag() detach('headbag') end

function Props.SetTape()
    attach('tape', Config.Props[Config.Tape.item], 12844, vec3(-0.02, 0.146, -0.047), vec3(180.0, 0.0, 0.0))
end
function Props.DeleteTape() detach('tape') end

function Props.DeleteAll()
    for name in pairs(handles) do detach(name) end
end
