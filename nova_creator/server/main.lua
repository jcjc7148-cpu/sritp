-- Serveur : identité (via esx_identity), paiement des vêtements, "register" (refaire identité + apparence)

---------------------------------------------------------------------
-- IDENTITÉ : on passe par esx_identity pour garder toute sa logique (base de données, ESX)
---------------------------------------------------------------------
lib.callback.register('nova_creator:registerIdentity', function(src, data)
    if type(data) ~= 'table' then return false, 'Données invalides' end
    if Nova.Cooldown(src, 'identity', 2000) then return false, 'Doucement...' end
    local h = tonumber(data.height) or 0
    if h < CreatorConfig.MinHeight or h > CreatorConfig.MaxHeight then return false, 'Taille invalide' end
    local ok, res = pcall(function()
        return exports.esx_identity:RegisterIdentity(src, {
            firstname = tostring(data.firstname or ''),
            lastname = tostring(data.lastname or ''),
            dateofbirth = tostring(data.dateofbirth or ''),
            sex = data.sex == 'f' and 'f' or 'm',
            height = math.floor(h),
        })
    end)
    if not ok then
        print(('^1[nova_creator] esx_identity:RegisterIdentity a échoué : %s^7'):format(tostring(res)))
        return false, 'Erreur serveur (esx_identity)'
    end
    if res then
        Nova.Log('player', 'Nouvelle identité', ('%s %s (%s)'):format(data.firstname, data.lastname, data.dateofbirth), src)
        return true
    end
    return false, 'Identité refusée : vérifie le prénom, le nom et la date.'
end)

---------------------------------------------------------------------
-- MAGASIN DE VÊTEMENTS
---------------------------------------------------------------------
local function mapBy(list, idKey)
    local m = {}
    for _, v in pairs(type(list) == 'table' and list or {}) do
        if type(v) == 'table' and tonumber(v[idKey]) then m[tonumber(v[idKey])] = v end
    end
    return m
end

lib.callback.register('nova_creator:payClothes', function(src, appearance)
    if type(appearance) ~= 'table' or type(appearance.components) ~= 'table' or type(appearance.props) ~= 'table' then return false end
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return false end
    if Nova.Cooldown(src, 'clothespay', 2000) then return false end
    -- doit être dans un magasin
    local near = false
    for _, c in ipairs(CreatorConfig.Shop.Locations) do
        if Nova.IsNear(src, vector3(c.x, c.y, c.z), 12.0) then near = true break end
    end
    if not near then return false end

    local identifier = xPlayer.getIdentifier()
    local raw = MySQL.scalar.await('SELECT skin FROM users WHERE identifier = ?', { identifier })
    local ok, old = pcall(json.decode, raw or '')
    if not ok or type(old) ~= 'table' then return false end

    local oldC, newC = mapBy(old.components, 'component_id'), mapBy(appearance.components, 'component_id')
    local oldP, newP = mapBy(old.props, 'prop_id'), mapBy(appearance.props, 'prop_id')

    -- prix recalculé ici, à partir de ce qui change vraiment
    local total = 0
    for _, cat in ipairs(CreatorConfig.Clothes) do
        local key = cat.key
        local o, n
        if type(key) == 'string' then local id = tonumber(key:sub(2)) o, n = oldP[id], newP[id]
        else o, n = oldC[key], newC[key] end
        if n and (not o or o.drawable ~= n.drawable or o.texture ~= n.texture) then
            total = total + (CreatorConfig.Shop.Prices[key] or 0)
        end
    end
    if total <= 0 then return false end

    if xPlayer.getMoney() >= total then
        xPlayer.removeMoney(total, 'Magasin de vêtements')
    elseif xPlayer.getAccount('bank').money >= total then
        xPlayer.removeAccountMoney('bank', total, 'Magasin de vêtements')
    else
        Nova.Notify(src, ('Il te manque de l\'argent (%s $).'):format(Nova.FormatMoney(total)), 'error')
        return false
    end

    -- on ne garde QUE les vêtements du client (visage, cheveux... restent ceux enregistrés)
    local allowedC, allowedP = {}, {}
    for _, cat in ipairs(CreatorConfig.Clothes) do
        if type(cat.key) == 'string' then allowedP[tonumber(cat.key:sub(2))] = true else allowedC[cat.key] = true end
    end
    for id, n in pairs(newC) do if allowedC[id] then oldC[id] = { component_id = id, drawable = math.floor(tonumber(n.drawable) or 0), texture = math.floor(tonumber(n.texture) or 0) } end end
    for id, n in pairs(newP) do if allowedP[id] then oldP[id] = { prop_id = id, drawable = math.floor(tonumber(n.drawable) or -1), texture = math.floor(tonumber(n.texture) or 0) } end end
    local comps, props = {}, {}
    for _, v in pairs(oldC) do comps[#comps + 1] = v end
    for _, v in pairs(oldP) do props[#props + 1] = v end
    table.sort(comps, function(a, b) return a.component_id < b.component_id end)
    table.sort(props, function(a, b) return a.prop_id < b.prop_id end)
    old.components, old.props = comps, props
    MySQL.update.await('UPDATE users SET skin = ? WHERE identifier = ?', { json.encode(old), identifier })
    Nova.Log('shop', 'Magasin de vêtements', ('%s a payé %s $'):format(GetPlayerName(src) or '?', Nova.FormatMoney(total)), src)
    return true
end)

---------------------------------------------------------------------
-- BARBIER : seuls cheveux, sourcils, barbe, yeux et maquillage sont repris du client
---------------------------------------------------------------------
local function same(a, b)
    if type(a) ~= 'table' or type(b) ~= 'table' then return a == b end
    for k, v in pairs(a) do
        if type(v) == 'number' and type(b[k]) == 'number' then
            if math.abs(v - b[k]) > 0.01 then return false end
        elseif v ~= b[k] then return false end
    end
    for k in pairs(b) do if a[k] == nil then return false end end
    return true
end

local function num(v, a, b, def)
    v = tonumber(v) or def
    return math.max(a, math.min(b, v))
end

lib.callback.register('nova_creator:payBarber', function(src, appearance)
    if type(appearance) ~= 'table' then return false end
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return false end
    if Nova.Cooldown(src, 'barberpay', 2000) then return false end
    local near = false
    for _, c in ipairs(CreatorConfig.Barber.Locations) do
        if Nova.IsNear(src, vector3(c.x, c.y, c.z), 12.0) then near = true break end
    end
    if not near then return false end

    local identifier = xPlayer.getIdentifier()
    local raw = MySQL.scalar.await('SELECT skin FROM users WHERE identifier = ?', { identifier })
    local ok, old = pcall(json.decode, raw or '')
    if not ok or type(old) ~= 'table' then return false end
    old.headOverlays = type(old.headOverlays) == 'table' and old.headOverlays or {}

    local P = CreatorConfig.Barber.Prices
    local total, parts = 0, {}

    -- cheveux (coupe = composant 2)
    local nh = type(appearance.hair) == 'table' and appearance.hair or nil
    local newC, oldC = mapBy(appearance.components, 'component_id'), mapBy(old.components, 'component_id')
    local nc2 = newC[2]
    local hairChanged = (nh and not same(nh, old.hair)) or (nc2 and (not oldC[2] or oldC[2].drawable ~= nc2.drawable or oldC[2].texture ~= nc2.texture))
    if hairChanged then
        total = total + (P.hair or 0)
        if nh then old.hair = { style = math.floor(num(nh.style, 0, 500, 0)), texture = math.floor(num(nh.texture, 0, 50, 0)), color = math.floor(num(nh.color, 0, 100, 0)), highlight = math.floor(num(nh.highlight, 0, 100, 0)) } end
        if nc2 then
            local list = {}
            for id, v in pairs(oldC) do list[#list + 1] = v end
            local found = false
            for _, v in ipairs(list) do if tonumber(v.component_id) == 2 then v.drawable = math.floor(tonumber(nc2.drawable) or 0) v.texture = math.floor(tonumber(nc2.texture) or 0) found = true end end
            if not found then list[#list + 1] = { component_id = 2, drawable = math.floor(tonumber(nc2.drawable) or 0), texture = math.floor(tonumber(nc2.texture) or 0) } end
            table.sort(list, function(a, b) return a.component_id < b.component_id end)
            old.components = list
        end
        parts[#parts + 1] = 'cheveux'
    end

    -- yeux
    if appearance.eyeColor ~= nil and tonumber(appearance.eyeColor) ~= tonumber(old.eyeColor) then
        total = total + (P.eyes or 0)
        old.eyeColor = math.floor(num(appearance.eyeColor, 0, 31, 0))
        parts[#parts + 1] = 'yeux'
    end

    -- sourcils, barbe, maquillage
    local nov = type(appearance.headOverlays) == 'table' and appearance.headOverlays or {}
    for _, key in ipairs({ 'eyebrows', 'beard', 'makeUp', 'blush', 'lipstick' }) do
        local n = nov[key]
        if type(n) == 'table' and not same(n, old.headOverlays[key]) then
            total = total + (P[key] or 0)
            old.headOverlays[key] = {
                style = math.floor(num(n.style, 0, 255, 0)), opacity = num(n.opacity, 0.0, 1.0, 1.0),
                color = math.floor(num(n.color, 0, 100, 0)), secondColor = math.floor(num(n.secondColor, 0, 100, 0)),
            }
            parts[#parts + 1] = key
        end
    end

    if total <= 0 then return false end
    if xPlayer.getMoney() >= total then
        xPlayer.removeMoney(total, 'Barbier')
    elseif xPlayer.getAccount('bank').money >= total then
        xPlayer.removeAccountMoney('bank', total, 'Barbier')
    else
        Nova.Notify(src, ('Il te manque de l\'argent (%s $).'):format(Nova.FormatMoney(total)), 'error')
        return false
    end
    MySQL.update.await('UPDATE users SET skin = ? WHERE identifier = ?', { json.encode(old), identifier })
    Nova.Log('shop', 'Barbier', ('%s a payé %s $ (%s)'):format(GetPlayerName(src) or '?', Nova.FormatMoney(total), table.concat(parts, ', ')), src)
    return true
end)

---------------------------------------------------------------------
-- Personnage sans apparence (déconnexion pendant la création, register...) : on relance le créateur
---------------------------------------------------------------------
lib.callback.register('nova_creator:needsSkin', function(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return false end
    local row = MySQL.single.await('SELECT skin, firstname, sex FROM users WHERE identifier = ?', { xPlayer.getIdentifier() })
    if not row or not row.firstname then return false end -- pas d'identité : esx_identity s'en occupe
    if row.skin == nil or row.skin == '' or row.skin == '{}' or row.skin == 'null' then
        return true, row.sex == 'f' and 'f' or 'm'
    end
    return false
end)

---------------------------------------------------------------------
-- REGISTER : efface l'identité + l'apparence (PAS l'inventaire, l'argent, les véhicules...)
-- puis le joueur refait son identité et son personnage.
---------------------------------------------------------------------
local function register(target)
    local xPlayer = ESX.GetPlayerFromId(target)
    if not xPlayer then return false end
    local ok, err = pcall(function() exports.esx_identity:ResetIdentity(target) end)
    if not ok then
        print(('^1[nova_creator] esx_identity:ResetIdentity a échoué : %s^7'):format(tostring(err)))
        return false
    end
    return true
end
exports('RegisterPlayer', register)
