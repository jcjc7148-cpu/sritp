-- Créateur de personnage en menu RageUI (NovaMenu)
-- mode 'new'  : première création (ou après un "register" staff), impossible de quitter sans valider
-- mode 'edit' : modification (ouvert par le staff), Retour = annuler les changements
Character = {}

local FATHERS = {
    { 0, 'Benjamin' }, { 1, 'Daniel' }, { 2, 'Joshua' }, { 3, 'Noah' }, { 4, 'Andrew' }, { 5, 'Juan' }, { 6, 'Alex' },
    { 7, 'Isaac' }, { 8, 'Evan' }, { 9, 'Ethan' }, { 10, 'Vincent' }, { 11, 'Angel' }, { 12, 'Diego' }, { 13, 'Adrian' },
    { 14, 'Gabriel' }, { 15, 'Michael' }, { 16, 'Santiago' }, { 17, 'Kevin' }, { 18, 'Louis' }, { 19, 'Samuel' },
    { 20, 'Anthony' }, { 42, 'Claude' }, { 43, 'Niko' }, { 44, 'John' },
}
local MOTHERS = {
    { 21, 'Hannah' }, { 22, 'Audrey' }, { 23, 'Jasmine' }, { 24, 'Giselle' }, { 25, 'Amelia' }, { 26, 'Isabella' },
    { 27, 'Zoe' }, { 28, 'Ava' }, { 29, 'Camila' }, { 30, 'Violet' }, { 31, 'Sophia' }, { 32, 'Evelyn' }, { 33, 'Nicole' },
    { 34, 'Ashley' }, { 35, 'Grace' }, { 36, 'Brianna' }, { 37, 'Natalie' }, { 38, 'Olivia' }, { 39, 'Elizabeth' },
    { 40, 'Charlotte' }, { 41, 'Emma' }, { 45, 'Misty' },
}
local FACE = {
    { 0, 'Largeur du nez' }, { 1, 'Hauteur du nez' }, { 2, 'Longueur du nez' }, { 3, 'Arête du nez' },
    { 4, 'Pointe du nez' }, { 5, 'Déviation du nez' }, { 6, 'Hauteur des sourcils' }, { 7, 'Profondeur des sourcils' },
    { 8, 'Hauteur des pommettes' }, { 9, 'Largeur des pommettes' }, { 10, 'Largeur des joues' }, { 11, 'Ouverture des yeux' },
    { 12, 'Épaisseur des lèvres' }, { 13, 'Largeur de la mâchoire' }, { 14, 'Forme de la mâchoire' }, { 15, 'Hauteur du menton' },
    { 16, 'Longueur du menton' }, { 17, 'Largeur du menton' }, { 18, 'Fossette du menton' }, { 19, 'Épaisseur du cou' },
}
-- overlays : index GTA, nom, type de couleur (1 = cheveux, 2 = maquillage, nil = pas de couleur), réservé à un sexe
local OVERLAYS = {
    skin = {
        { 0, 'Imperfections' }, { 3, 'Rides / vieillissement' }, { 6, 'Teint' }, { 7, 'Coups de soleil' },
        { 9, 'Grains de beauté / taches' }, { 11, 'Imperfections du corps' },
    },
    hair = {
        { 2, 'Sourcils', 1 }, { 1, 'Barbe', 1, 'm' }, { 10, 'Pilosité du torse', 1, 'm' },
    },
    makeup = {
        { 4, 'Maquillage des yeux', 2 }, { 5, 'Blush', 2 }, { 8, 'Rouge à lèvres', 2 },
    },
}

local session = nil -- { mode, original, hb = {...}, saved }

---------------------------------------------------------------------
-- HÉRITAGE (head blend)
---------------------------------------------------------------------
local function applyBlend()
    local hb = session.hb
    SetPedHeadBlendData(PlayerPedId(), hb.mother, hb.father, 0, hb.mother, hb.father, 0, hb.shape + 0.0, hb.skin + 0.0, 0.0, false)
end

local function readBlend()
    local b = Creator.APP:getPedHeadBlend(PlayerPedId()) or {}
    local function valid(list, id, default)
        for _, x in ipairs(list) do if x[1] == id then return id end end
        return default
    end
    return {
        mother = valid(MOTHERS, b.shapeFirst, 21),
        father = valid(FATHERS, b.shapeSecond, 0),
        shape = tonumber(b.shapeMix) or 0.5,
        skin = tonumber(b.skinMix) or 0.5,
    }
end

local function names(list)
    local t = {}
    for i, x in ipairs(list) do t[i] = x[2] end
    return t
end
local function indexOf(list, id)
    for i, x in ipairs(list) do if x[1] == id then return i end end
    return 1
end

local function heritageMenu()
    return {
        title = 'PERSONNAGE', subtitle = 'Héritage',
        items = function()
            local hb = session.hb
            return {
                { type = 'list', label = 'Mère', icon = '👩', values = names(MOTHERS), index = indexOf(MOTHERS, hb.mother),
                  onChange = function(_, i) hb.mother = MOTHERS[i][1] applyBlend() end },
                { type = 'list', label = 'Père', icon = '👨', values = names(FATHERS), index = indexOf(FATHERS, hb.father),
                  onChange = function(_, i) hb.father = FATHERS[i][1] applyBlend() end },
                { type = 'slider', label = 'Ressemblance', icon = '🧬', min = 0, max = 100, step = 5, value = math.floor(hb.shape * 100 + 0.5),
                  description = '0 = comme la mère, 100 = comme le père',
                  onChange = function(v) hb.shape = v / 100 applyBlend() end },
                { type = 'slider', label = 'Couleur de peau', icon = '🎨', min = 0, max = 100, step = 5, value = math.floor(hb.skin * 100 + 0.5),
                  description = '0 = peau de la mère, 100 = peau du père',
                  onChange = function(v) hb.skin = v / 100 applyBlend() end },
            }
        end,
    }
end

---------------------------------------------------------------------
-- VISAGE
---------------------------------------------------------------------
local function faceMenu()
    return {
        title = 'PERSONNAGE', subtitle = 'Traits du visage',
        items = function()
            local ped = PlayerPedId()
            local items = {}
            for _, f in ipairs(FACE) do
                items[#items + 1] = { type = 'slider', label = f[2], min = -100, max = 100, step = 10,
                    value = math.floor(GetPedFaceFeature(ped, f[1]) * 100 + 0.5),
                    onChange = function(v) SetPedFaceFeature(PlayerPedId(), f[1], v / 100 + 0.0) end }
            end
            items[#items + 1] = { type = 'separator' }
            items[#items + 1] = { label = 'Tout remettre à zéro', icon = '♻️', onSelect = function()
                for _, f in ipairs(FACE) do SetPedFaceFeature(PlayerPedId(), f[1], 0.0) end
                NovaMenu.Refresh()
            end }
            return items
        end,
    }
end

---------------------------------------------------------------------
-- OVERLAYS (sourcils, barbe, peau, maquillage)
---------------------------------------------------------------------
local function overlayData(ov)
    local ok, value, _, c1, _, opacity = GetPedHeadOverlayData(PlayerPedId(), ov)
    if not ok or value == 255 then return -1, c1 or 0, opacity or 1.0 end
    return value, c1, opacity
end

local function overlayItems(list)
    local ped = PlayerPedId()
    local male = Creator.IsMale(ped)
    local items = {}
    for _, o in ipairs(list) do
        local id, label, colorType, sex = o[1], o[2], o[3], o[4]
        if not sex or (sex == 'm') == male then
            local value, color, opacity = overlayData(id)
            local count = GetPedHeadOverlayNum(id)
            items[#items + 1] = { type = 'separator', label = label }
            items[#items + 1] = { type = 'list', label = 'Style', values = Creator.Range(count, 'Aucun'), index = value + 2,
                onChange = function(_, i)
                    local _, c, op = overlayData(id)
                    if i == 1 then SetPedHeadOverlay(PlayerPedId(), id, 255, 0.0)
                    else SetPedHeadOverlay(PlayerPedId(), id, i - 2, (op and op > 0.05) and op or 1.0) end
                    if colorType then SetPedHeadOverlayColor(PlayerPedId(), id, colorType, c, c) end
                    NovaMenu.Refresh()
                end }
            items[#items + 1] = { type = 'slider', label = 'Opacité', min = 0, max = 100, step = 10, value = math.floor((opacity or 1) * 100 + 0.5),
                disabled = value < 0,
                onChange = function(v)
                    local cur = overlayData(id)
                    if cur >= 0 then SetPedHeadOverlay(PlayerPedId(), id, cur, v / 100 + 0.0) end
                end }
            if colorType then
                local n = colorType == 2 and GetNumMakeupColors() or GetNumHairColors()
                items[#items + 1] = { type = 'list', label = 'Couleur', values = Creator.Range(n), index = math.min((color or 0) + 1, math.max(n, 1)),
                    disabled = value < 0,
                    onChange = function(_, i) SetPedHeadOverlayColor(PlayerPedId(), id, colorType, i - 1, i - 1) end }
            end
        end
    end
    return items
end

local function overlayMenu(title, list, cam)
    return function()
        Creator.Cam(cam or 'face')
        return { title = 'PERSONNAGE', subtitle = title, items = function() return overlayItems(list) end }
    end
end

---------------------------------------------------------------------
-- CHEVEUX + YEUX
---------------------------------------------------------------------
local function hairMenu()
    Creator.Cam('face')
    return {
        title = 'PERSONNAGE', subtitle = 'Cheveux et yeux',
        items = function()
            local ped = PlayerPedId()
            local style = GetPedDrawableVariation(ped, 2)
            local nColors = GetNumHairColors()
            local items = {
                { type = 'list', label = 'Coupe', icon = '💇', values = Creator.Range(GetNumberOfPedDrawableVariations(ped, 2)), index = style + 1,
                  onChange = function(_, i)
                      local p = PlayerPedId()
                      SetPedComponentVariation(p, 2, i - 1, 0, 0)
                      NovaMenu.Refresh()
                  end },
                { type = 'list', label = 'Couleur', icon = '🎨', values = Creator.Range(nColors), index = GetPedHairColor(ped) + 1,
                  onChange = function(_, i) local p = PlayerPedId() SetPedHairColor(p, i - 1, GetPedHairHighlightColor(p)) end },
                { type = 'list', label = 'Reflets', icon = '✨', values = Creator.Range(nColors), index = GetPedHairHighlightColor(ped) + 1,
                  onChange = function(_, i) local p = PlayerPedId() SetPedHairColor(p, GetPedHairColor(p), i - 1) end },
                { type = 'separator', label = 'Yeux' },
                { type = 'list', label = 'Couleur des yeux', icon = '👁️', values = Creator.Range(32), index = math.min(GetPedEyeColor(ped) + 1, 32),
                  onChange = function(_, i) SetPedEyeColor(PlayerPedId(), i - 1) end },
            }
            return items
        end,
    }
end

---------------------------------------------------------------------
-- SEXE
---------------------------------------------------------------------
local function setSex(female)
    local model = female and 'mp_f_freemode_01' or 'mp_m_freemode_01'
    if GetEntityModel(PlayerPedId()) == joaat(model) then return end
    Creator.SetModel(model)
    session.hb = readBlend()
    applyBlend()
    Creator.camKind = nil
    Creator.Cam('full')
end

---------------------------------------------------------------------
-- MENU PRINCIPAL
---------------------------------------------------------------------
local function finish(save)
    if not session then return end
    local s = session
    if save then
        Creator.SaveAppearance()
        s.saved = true
    elseif s.original then
        Creator.SetAppearance(s.original)
    end
    session = nil
    Creator.End()
    if s.onDone then CreateThread(function() s.onDone(save) end) end
end

function Character.IsOpen() return session ~= nil end

---Coupe la session en cours sans rien enregistrer (utilisé quand le staff relance l'identité)
function Character.Abort()
    if not session then return end
    local s = session
    session = nil
    NovaMenu.Close()
    if s.original then Creator.SetAppearance(s.original) end
    Creator.End()
end

---@param opts { mode: 'new'|'edit', sex?: 'm'|'f', onDone?: function }
function Character.Open(opts)
    opts = opts or {}
    if session then return end
    if Identity and Identity.open then return end -- la création d'identité passe avant
    if Creator.active then NovaMenu.Close() Wait(200) end
    local isNew = opts.mode == 'new'
    session = { mode = isNew and 'new' or 'edit', onDone = opts.onDone }

    if isNew then
        -- personnage neuf, du bon sexe
        local model = opts.sex == 'f' and 'mp_f_freemode_01' or 'mp_m_freemode_01'
        -- repart d'un personnage vierge
        Creator.SetModel(model == 'mp_f_freemode_01' and 'mp_m_freemode_01' or 'mp_f_freemode_01')
        Creator.SetModel(model)
    elseif not Creator.IsFreemode() then
        Creator.SetModel(Creator.IsMale() and 'mp_m_freemode_01' or 'mp_f_freemode_01')
    end
    session.original = (not isNew) and Creator.GetAppearance() or nil
    session.hb = readBlend()
    Creator.Begin({ cam = 'full', bucket = isNew })

    local def
    def = {
        title = 'PERSONNAGE',
        subtitle = isNew and 'Création du personnage' or 'Modifier l\'apparence',
        items = function()
            local female = not Creator.IsMale()
            return {
                { type = 'list', label = 'Sexe', icon = '⚧️', values = { 'Homme', 'Femme' }, index = female and 2 or 1,
                  description = 'Attention : changer de sexe remet l\'apparence à zéro.',
                  onHover = function() Creator.Cam('full') end,
                  onChange = function(_, i) setSex(i == 2) NovaMenu.Refresh() end },
                { label = 'Héritage', icon = '🧬', description = 'Parents, ressemblance et couleur de peau',
                  onHover = function() Creator.Cam('face') end,
                  submenu = function() Creator.Cam('face') return heritageMenu() end },
                { label = 'Traits du visage', icon = '🙂', onHover = function() Creator.Cam('face') end,
                  submenu = function() Creator.Cam('face') return faceMenu() end },
                { label = 'Cheveux et yeux', icon = '💇', onHover = function() Creator.Cam('face') end, submenu = hairMenu },
                { label = 'Pilosité', icon = '🧔', description = 'Sourcils, barbe, torse', onHover = function() Creator.Cam('face') end,
                  submenu = overlayMenu('Pilosité', OVERLAYS.hair) },
                { label = 'Peau', icon = '🧴', description = 'Imperfections, rides, teint, taches', onHover = function() Creator.Cam('face') end,
                  submenu = overlayMenu('Peau', OVERLAYS.skin) },
                { label = 'Maquillage', icon = '💄', onHover = function() Creator.Cam('face') end,
                  submenu = overlayMenu('Maquillage', OVERLAYS.makeup) },
                { label = 'Vêtements', icon = '👕', onHover = function() Creator.Cam('body') end,
                  submenu = function()
                      Creator.Cam('body')
                      return { title = 'PERSONNAGE', subtitle = 'Vêtements', items = function() return Clothing.Items() end,
                          onBack = function() Creator.Cam('full') end }
                  end },
                { type = 'separator' },
                { label = isNew and 'Terminer mon personnage' or 'Enregistrer', icon = '✅', color = '#7df2b9',
                  onHover = function() Creator.Cam('full') end,
                  confirm = isNew and 'Terminer ? Tu ne pourras plus changer ton visage ensuite (seulement coiffeur et magasins).' or nil,
                  onSelect = function()
                      finish(true)
                      NovaMenu.Close()
                      Nova.Notify(isNew and 'Bienvenue sur la ville !' or 'Apparence enregistrée.', 'success')
                  end },
                not isNew and { label = 'Annuler les changements', icon = '↩️', onSelect = function() NovaMenu.Close() end } or nil,
            }
        end,
        onBack = function()
            if isNew and session then
                Nova.Notify('Termine ton personnage pour entrer en ville (tout en bas du menu).', 'info')
                return false
            end
        end,
        onClose = function()
            if not session then return end
            if isNew then
                -- la création ne peut pas être quittée : on rouvre le menu
                SetTimeout(300, function() if session then NovaMenu.Open(def) end end)
            else
                -- fermé sans enregistrer = on remet l'apparence d'avant
                finish(false)
            end
        end,
    }
    NovaMenu.Open(def)
end

RegisterNetEvent('nova_creator:open', function(opts)
    Character.Open(type(opts) == 'table' and opts or { mode = 'edit' })
end)

exports('OpenCharacterCreator', function(opts) CreateThread(function() Character.Open(opts) end) end)

-- Personnage sans apparence enregistrée (déco pendant la création, register...) : on relance le créateur
AddEventHandler('esx:playerLoaded', function()
    CreateThread(function()
        Wait(6000)
        if session or (Identity and Identity.open) then return end
        local needs, sex = lib.callback.await('nova_creator:needsSkin', false)
        if needs and not session and not (Identity and Identity.open) then
            Character.Open({ mode = 'new', sex = sex })
        end
    end)
end)
