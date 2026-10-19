-- Outils communs : caméra, gel du joueur, rotation, lecture / sauvegarde de l'apparence (illenium-appearance)
Creator = { active = false, cam = nil, camKind = nil, bucket = false }

local APP = exports['illenium-appearance']
Creator.APP = APP

function Creator.GetAppearance()
    return APP:getPedAppearance(PlayerPedId())
end

---Change le modèle du joueur (on le fait nous-mêmes : les exports qui attendent ne passent pas bien d'une ressource à l'autre)
function Creator.SetModel(model)
    local hash = type(model) == 'string' and joaat(model) or model
    if GetEntityModel(PlayerPedId()) == hash then return PlayerPedId() end
    if not IsModelInCdimage(hash) then return PlayerPedId() end
    RequestModel(hash)
    local t = GetGameTimer()
    while not HasModelLoaded(hash) and GetGameTimer() - t < 5000 do Wait(0) end
    SetPlayerModel(PlayerId(), hash)
    Wait(150)
    SetModelAsNoLongerNeeded(hash)
    local ped = PlayerPedId()
    SetPedDefaultComponentVariation(ped)
    if hash == joaat('mp_m_freemode_01') then
        SetPedHeadBlendData(ped, 0, 0, 0, 0, 0, 0, 0.0, 0.0, 0.0, false)
    elseif hash == joaat('mp_f_freemode_01') then
        SetPedHeadBlendData(ped, 45, 21, 0, 20, 15, 0, 0.3, 0.1, 0.0, false)
    end
    if Creator.active then
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
    end
    Wait(100) -- laisse illenium voir le nouveau ped
    return ped
end

function Creator.SetAppearance(appearance)
    if not appearance then return end
    if appearance.model then Creator.SetModel(appearance.model) end
    APP:setPedAppearance(PlayerPedId(), appearance)
end

function Creator.SaveAppearance()
    TriggerServerEvent('illenium-appearance:server:saveAppearance', Creator.GetAppearance())
end

function Creator.IsFreemode(ped)
    local m = GetEntityModel(ped or PlayerPedId())
    return m == joaat('mp_m_freemode_01') or m == joaat('mp_f_freemode_01')
end

function Creator.IsMale(ped)
    return GetEntityModel(ped or PlayerPedId()) ~= joaat('mp_f_freemode_01')
end

---------------------------------------------------------------------
-- CAMÉRA
---------------------------------------------------------------------
local CAMS = {
    face = { off = vector3(0.0, 0.75, 0.65), look = vector3(0.0, 0.0, 0.62), fov = 38.0 },
    body = { off = vector3(0.0, 1.75, 0.25), look = vector3(0.0, 0.0, 0.15), fov = 45.0 },
    legs = { off = vector3(0.0, 1.35, -0.4), look = vector3(0.0, 0.0, -0.5), fov = 45.0 },
    feet = { off = vector3(0.0, 1.05, -0.75), look = vector3(0.0, 0.0, -0.9), fov = 42.0 },
    full = { off = vector3(0.0, 2.8, 0.2), look = vector3(0.0, 0.0, 0.0), fov = 45.0 },
}

function Creator.Cam(kind)
    kind = CAMS[kind] and kind or 'full'
    if Creator.camKind == kind and Creator.cam then return end
    local ped = PlayerPedId()
    local c = CAMS[kind]
    local pos = GetOffsetFromEntityInWorldCoords(ped, c.off.x, c.off.y, c.off.z)
    local look = GetOffsetFromEntityInWorldCoords(ped, c.look.x, c.look.y, c.look.z)
    local cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', pos.x, pos.y, pos.z, 0.0, 0.0, 0.0, c.fov, false, 0)
    PointCamAtCoord(cam, look.x, look.y, look.z)
    if Creator.cam then
        SetCamActiveWithInterp(cam, Creator.cam, 650, 1, 1)
        local old = Creator.cam
        SetTimeout(700, function() if DoesCamExist(old) then DestroyCam(old, false) end end)
    else
        SetCamActive(cam, true)
        RenderScriptCams(true, true, 600, true, true)
    end
    Creator.cam, Creator.camKind = cam, kind
end

function Creator.StopCam()
    if Creator.cam then
        RenderScriptCams(false, true, 600, true, true)
        local old = Creator.cam
        SetTimeout(650, function() if DoesCamExist(old) then DestroyCam(old, false) end end)
    end
    Creator.cam, Creator.camKind = nil, nil
end

---------------------------------------------------------------------
-- DÉBUT / FIN D'UNE SESSION (création, magasin...)
---------------------------------------------------------------------
local function hud(state)
    if GetResourceState('nova_hud') == 'started' then pcall(function() exports.nova_hud:SetVisible(state) end) end
    DisplayRadar(state)
end

---@param opts { bucket?: boolean, cam?: string }
function Creator.Begin(opts)
    opts = opts or {}
    if Creator.active then return end
    Creator.active = true
    local ped = PlayerPedId()
    ClearPedTasksImmediately(ped)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    hud(false)
    if opts.bucket and CreatorConfig.PrivateBucket then
        Creator.bucket = true
        TriggerServerEvent('illenium-appearance:server:ChangeRoutingBucket')
    end
    Creator.Cam(opts.cam or 'full')

    CreateThread(function()
        while Creator.active do
            local p = PlayerPedId()
            -- pas de déplacement / attaque / téléphone pendant l'édition
            DisableControlAction(0, 30, true) DisableControlAction(0, 31, true)
            DisableControlAction(0, 21, true) DisableControlAction(0, 22, true)
            DisableControlAction(0, 24, true) DisableControlAction(0, 25, true)
            DisableControlAction(0, 23, true) DisableControlAction(0, 75, true)
            DisableControlAction(0, CreatorConfig.RotateLeft, true) DisableControlAction(0, CreatorConfig.RotateRight, true)
            DisableControlAction(0, 288, true) DisableControlAction(0, 289, true) DisableControlAction(0, 170, true)
            DisableControlAction(0, 166, true) DisableControlAction(0, 167, true) DisableControlAction(0, 168, true)
            if IsDisabledControlPressed(0, CreatorConfig.RotateLeft) then SetEntityHeading(p, GetEntityHeading(p) - 2.0) end
            if IsDisabledControlPressed(0, CreatorConfig.RotateRight) then SetEntityHeading(p, GetEntityHeading(p) + 2.0) end
            -- la caméra suit la rotation
            if Creator.cam and (IsDisabledControlPressed(0, CreatorConfig.RotateLeft) or IsDisabledControlPressed(0, CreatorConfig.RotateRight)) then
                local kind = Creator.camKind
                Creator.camKind = nil
                local old = Creator.cam
                local c = CAMS[kind]
                local pos = GetOffsetFromEntityInWorldCoords(p, c.off.x, c.off.y, c.off.z)
                local look = GetOffsetFromEntityInWorldCoords(p, c.look.x, c.look.y, c.look.z)
                SetCamCoord(old, pos.x, pos.y, pos.z)
                PointCamAtCoord(old, look.x, look.y, look.z)
                Creator.camKind = kind
            end
            SetTextFont(4) SetTextScale(0.0, 0.36) SetTextColour(255, 255, 255, 215) SetTextOutline() SetTextCentre(true)
            BeginTextCommandDisplayText('STRING')
            AddTextComponentSubstringPlayerName('~p~A~s~ / ~p~E~s~  tourner le personnage')
            EndTextCommandDisplayText(0.5, 0.94)
            Wait(0)
        end
    end)
end

function Creator.End()
    if not Creator.active then return end
    Creator.active = false
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, false)
    SetEntityInvincible(ped, false)
    Creator.StopCam()
    hud(true)
    if Creator.bucket then
        Creator.bucket = false
        TriggerServerEvent('illenium-appearance:server:ResetRoutingBucket')
    end
end

---------------------------------------------------------------------
-- Petits outils pour les listes des menus
---------------------------------------------------------------------
function Creator.Range(count, first)
    local t = {}
    if first then t[1] = first end
    for i = 1, math.max(count, 0) do t[#t + 1] = ('%d / %d'):format(i, count) end
    if #t == 0 then t[1] = '-' end
    return t
end

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() and Creator.active then
        FreezeEntityPosition(PlayerPedId(), false)
        SetEntityInvincible(PlayerPedId(), false)
        RenderScriptCams(false, false, 0, true, true)
        DisplayRadar(true)
        if Creator.bucket then TriggerServerEvent('illenium-appearance:server:ResetRoutingBucket') end
    end
end)
