-- Barbier : cheveux, sourcils, barbe, yeux, maquillage (menu, caméra sur le visage, paiement à la fin)
local Barber = CreatorConfig.Barber
local open = false

-- [overlay GTA] = { clé illenium, nom, type de couleur (1 = cheveux, 2 = maquillage), sexe }
local OV = {
    eyebrows = { id = 2, label = 'Sourcils', color = 1 },
    beard    = { id = 1, label = 'Barbe', color = 1, sex = 'm' },
    makeUp   = { id = 4, label = 'Maquillage des yeux', color = 2 },
    blush    = { id = 5, label = 'Blush', color = 2 },
    lipstick = { id = 8, label = 'Rouge à lèvres', color = 2 },
}

local function ovData(id)
    local ok, value, _, c1, c2, opacity = GetPedHeadOverlayData(PlayerPedId(), id)
    if not ok or value == 255 then return -1, c1 or 0, c2 or 0, opacity or 1.0 end
    return value, c1 or 0, c2 or 0, opacity or 1.0
end

---------------------------------------------------------------------
-- Ce qui a changé depuis l'ouverture (pour le prix)
---------------------------------------------------------------------
local function snapshot()
    local ped = PlayerPedId()
    local s = {
        hair = { GetPedDrawableVariation(ped, 2), GetPedTextureVariation(ped, 2), GetPedHairColor(ped), GetPedHairHighlightColor(ped) },
        eyes = { GetPedEyeColor(ped) },
    }
    for key, o in pairs(OV) do
        local v, c1, c2, op = ovData(o.id)
        s[key] = { v, c1, c2, math.floor(op * 100 + 0.5) }
    end
    return s
end

local function changed(before)
    local now, keys = snapshot(), {}
    for k, v in pairs(before) do
        for i = 1, #v do
            if now[k][i] ~= v[i] then keys[#keys + 1] = k break end
        end
    end
    return keys
end

local function priceOf(keys)
    local t = 0
    for _, k in ipairs(keys) do t = t + (Barber.Prices[k] or 0) end
    return t
end

---------------------------------------------------------------------
-- Sous-menus
---------------------------------------------------------------------
local function hairMenu()
    return {
        title = 'BARBIER', subtitle = 'Cheveux',
        items = function()
            local ped = PlayerPedId()
            local style = GetPedDrawableVariation(ped, 2)
            local nTex = GetNumberOfPedTextureVariations(ped, 2, style)
            local nColors = GetNumHairColors()
            return {
                { type = 'list', label = 'Coupe', values = Creator.Range(GetNumberOfPedDrawableVariations(ped, 2)), index = style + 1,
                  description = 'Gauche / droite pour changer. Maintiens pour défiler vite.',
                  onChange = function(_, i) SetPedComponentVariation(PlayerPedId(), 2, i - 1, 0, 0) NovaMenu.Refresh() end },
                { type = 'list', label = 'Variante', values = Creator.Range(nTex), index = GetPedTextureVariation(ped, 2) + 1, disabled = nTex <= 1,
                  onChange = function(_, i) local p = PlayerPedId() SetPedComponentVariation(p, 2, GetPedDrawableVariation(p, 2), i - 1, 0) end },
                { type = 'separator', label = 'Couleur' },
                { type = 'list', label = 'Couleur', values = Creator.Range(nColors), index = GetPedHairColor(ped) + 1,
                  onChange = function(_, i) local p = PlayerPedId() SetPedHairColor(p, i - 1, GetPedHairHighlightColor(p)) end },
                { type = 'list', label = 'Reflets', values = Creator.Range(nColors), index = GetPedHairHighlightColor(ped) + 1,
                  onChange = function(_, i) local p = PlayerPedId() SetPedHairColor(p, GetPedHairColor(p), i - 1) end },
            }
        end,
    }
end

local function overlayMenu(key)
    local o = OV[key]
    return {
        title = 'BARBIER', subtitle = o.label,
        items = function()
            local value, c1, c2, opacity = ovData(o.id)
            local count = GetPedHeadOverlayNum(o.id)
            local nColors = o.color == 2 and GetNumMakeupColors() or GetNumHairColors()
            local items = {
                { type = 'list', label = 'Style', values = Creator.Range(count, 'Aucun'), index = value + 2,
                  onChange = function(_, i)
                      local _, a, b, op = ovData(o.id)
                      local p = PlayerPedId()
                      if i == 1 then SetPedHeadOverlay(p, o.id, 255, 0.0)
                      else
                          SetPedHeadOverlay(p, o.id, i - 2, (op and op > 0.05) and op or 1.0)
                          SetPedHeadOverlayColor(p, o.id, o.color, a, b)
                      end
                      NovaMenu.Refresh()
                  end },
                { type = 'slider', label = 'Opacité', min = 0, max = 100, step = 10, value = math.floor(opacity * 100 + 0.5), disabled = value < 0,
                  onChange = function(v)
                      local cur = ovData(o.id)
                      if cur >= 0 then SetPedHeadOverlay(PlayerPedId(), o.id, cur, v / 100 + 0.0) end
                  end },
                { type = 'list', label = 'Couleur', values = Creator.Range(nColors), index = math.min(c1 + 1, math.max(nColors, 1)), disabled = value < 0,
                  onChange = function(_, i) local _, _, b = ovData(o.id) SetPedHeadOverlayColor(PlayerPedId(), o.id, o.color, i - 1, b) end },
            }
            if o.color == 2 and key == 'makeUp' then
                items[#items + 1] = { type = 'list', label = 'Couleur secondaire', values = Creator.Range(nColors), index = math.min(c2 + 1, math.max(nColors, 1)), disabled = value < 0,
                    onChange = function(_, i) local _, a = ovData(o.id) SetPedHeadOverlayColor(PlayerPedId(), o.id, o.color, a, i - 1) end }
            end
            return items
        end,
    }
end

local function eyesMenu()
    return {
        title = 'BARBIER', subtitle = 'Yeux',
        items = function()
            return {
                { type = 'list', label = 'Couleur des yeux', values = Creator.Range(32), index = math.min(GetPedEyeColor(PlayerPedId()) + 1, 32),
                  onChange = function(_, i) SetPedEyeColor(PlayerPedId(), i - 1) end },
            }
        end,
    }
end

---------------------------------------------------------------------
-- Ouverture
---------------------------------------------------------------------
function OpenBarber()
    if open or Creator.active then return end
    if not Creator.IsFreemode() then return Nova.Notify('Ton personnage ne peut pas passer chez le barbier (ped spécial).', 'error') end
    open = true
    local original = Creator.GetAppearance()
    local before = snapshot()
    local paid = false
    Creator.Begin({ cam = 'face' })

    NovaMenu.Open({
        title = 'BARBIER', subtitle = 'Barbier',
        items = function()
            local male = Creator.IsMale()
            local keys = changed(before)
            local total = priceOf(keys)
            local function price(k) return ('%s $'):format(Nova.FormatMoney(Barber.Prices[k] or 0)) end
            local items = {
                { type = 'separator', label = 'Visage' },
                { label = 'Cheveux', rightLabel = price('hair'), submenu = hairMenu },
                { label = 'Sourcils', rightLabel = price('eyebrows'), submenu = function() return overlayMenu('eyebrows') end },
                { label = 'Barbe', rightLabel = price('beard'), hidden = not male, submenu = function() return overlayMenu('beard') end },
                { label = 'Yeux', rightLabel = price('eyes'), submenu = eyesMenu },
                { type = 'separator', label = 'Maquillage' },
                { label = 'Maquillage des yeux', rightLabel = price('makeUp'), submenu = function() return overlayMenu('makeUp') end },
                { label = 'Blush', rightLabel = price('blush'), submenu = function() return overlayMenu('blush') end },
                { label = 'Rouge à lèvres', rightLabel = price('lipstick'), submenu = function() return overlayMenu('lipstick') end },
                { type = 'separator', label = 'Caisse' },
                { label = total > 0 and ('Payer %s $'):format(Nova.FormatMoney(total)) or 'Rien à payer', disabled = total == 0,
                  description = total > 0 and ('%d modification(s). Payé en liquide, sinon par carte.'):format(#keys) or 'Change quelque chose pour le payer.',
                  onSelect = function()
                      local ok = lib.callback.await('nova_creator:payBarber', false, Creator.GetAppearance())
                      if ok then
                          paid = true
                          Nova.Notify('Ça te va très bien !', 'success')
                          NovaMenu.Close()
                      end
                  end },
                { label = 'Tout annuler', disabled = total == 0, onSelect = function()
                    Creator.SetAppearance(original)
                    NovaMenu.Refresh()
                end },
                { label = 'Partir', description = 'Les changements non payés sont annulés.', onSelect = function() NovaMenu.Close() end },
            }
            return items
        end,
        onClose = function()
            if not paid then Creator.SetAppearance(original) end
            Creator.End()
            open = false
        end,
    })
end

---------------------------------------------------------------------
-- Blips + points
---------------------------------------------------------------------
CreateThread(function()
    Nova.PlaceBuilder('barber', function(addPoint, addBlip)
    for _, c in ipairs(Barber.Locations) do
        addBlip(vector3(c.x, c.y, c.z), Barber.Blip)
        addPoint({
            coords = vector3(c.x, c.y, c.z),
            label = 'Barbier',
            distance = Barber.Distance,
            key = Barber.Key,
            canInteract = function() return not open and not Creator.active and not IsPedInAnyVehicle(PlayerPedId(), false) end,
            onPress = function() OpenBarber() end,
        })
    end
    end)
end)

exports('OpenBarber', function() CreateThread(OpenBarber) end)
