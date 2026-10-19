-- Éditeur de vêtements (menu RageUI) : utilisé par le magasin de vêtements et par le créateur de personnage
Clothing = {}

local Shop = CreatorConfig.Shop

---------------------------------------------------------------------
-- Lecture / écriture d'une catégorie (composant = nombre, accessoire = 'pN')
---------------------------------------------------------------------
local function isProp(key) return type(key) == 'string' end
local function propId(key) return tonumber(key:sub(2)) end

local function getDrawable(ped, key)
    if isProp(key) then return GetPedPropIndex(ped, propId(key)) end
    return GetPedDrawableVariation(ped, key)
end
local function getTexture(ped, key)
    if isProp(key) then return math.max(0, GetPedPropTextureIndex(ped, propId(key))) end
    return GetPedTextureVariation(ped, key)
end
local function drawableCount(ped, key)
    if isProp(key) then return GetNumberOfPedPropDrawableVariations(ped, propId(key)) end
    return GetNumberOfPedDrawableVariations(ped, key)
end
local function textureCount(ped, key, drawable)
    if drawable < 0 then return 0 end
    if isProp(key) then return GetNumberOfPedPropTextureVariations(ped, propId(key), drawable) end
    return GetNumberOfPedTextureVariations(ped, key, drawable)
end
local function apply(ped, key, drawable, texture)
    if isProp(key) then
        if drawable < 0 then ClearPedProp(ped, propId(key))
        else SetPedPropIndex(ped, propId(key), drawable, texture, true) end
    else
        SetPedComponentVariation(ped, key, drawable, texture, 0)
    end
end
Clothing.Get = function(ped, key) return getDrawable(ped, key), getTexture(ped, key) end

---------------------------------------------------------------------
-- Sous-menu d'une catégorie
---------------------------------------------------------------------
local function categoryMenu(cat, onChange)
    return {
        title = 'VÊTEMENTS', subtitle = cat.label,
        items = function()
            local ped = PlayerPedId()
            local d = getDrawable(ped, cat.key)
            local n = drawableCount(ped, cat.key)
            local prop = isProp(cat.key)
            local values = Creator.Range(n, prop and 'Aucun' or nil)
            local idx = prop and (d + 2) or (d + 1)
            local tn = textureCount(ped, cat.key, d)
            local tex = getTexture(ped, cat.key)
            return {
                { type = 'list', label = 'Modèle', icon = cat.icon, values = values, index = idx,
                  description = 'Gauche / droite pour changer. Maintiens pour défiler vite.',
                  onChange = function(_, i)
                      local nd = prop and (i - 2) or (i - 1)
                      apply(PlayerPedId(), cat.key, nd, 0)
                      if onChange then onChange() end
                      NovaMenu.Refresh()
                  end },
                { type = 'list', label = 'Couleur / variante', icon = '🎨', values = Creator.Range(tn), index = math.min(tex + 1, math.max(tn, 1)),
                  disabled = tn <= 1,
                  onChange = function(_, i)
                      apply(PlayerPedId(), cat.key, getDrawable(PlayerPedId(), cat.key), i - 1)
                      if onChange then onChange() end
                  end },
            }
        end,
    }
end

---Liste des catégories (items de menu) pour l'éditeur
function Clothing.Items(onChange)
    local items = {}
    for _, cat in ipairs(CreatorConfig.Clothes) do
        items[#items + 1] = {
            label = cat.label, icon = cat.icon,
            onHover = function() Creator.Cam(cat.cam) end,
            submenu = function() Creator.Cam(cat.cam) return categoryMenu(cat, onChange) end,
        }
    end
    return items
end

---------------------------------------------------------------------
-- MAGASIN DE VÊTEMENTS
---------------------------------------------------------------------
local shopOpen = false

local function snapshotClothes(ped)
    local s = {}
    for _, cat in ipairs(CreatorConfig.Clothes) do
        s[cat.key] = { getDrawable(ped, cat.key), getTexture(ped, cat.key) }
    end
    return s
end

local function changedKeys(before)
    local ped, keys = PlayerPedId(), {}
    for _, cat in ipairs(CreatorConfig.Clothes) do
        local b = before[cat.key]
        if b and (getDrawable(ped, cat.key) ~= b[1] or getTexture(ped, cat.key) ~= b[2]) then keys[#keys + 1] = cat.key end
    end
    return keys
end

local function priceOf(keys)
    local total = 0
    for _, k in ipairs(keys) do total = total + (Shop.Prices[k] or 0) end
    return total
end

function Clothing.OpenShop()
    if shopOpen or Creator.active then return end
    if not Creator.IsFreemode() then return Nova.Notify('Ton personnage ne peut pas porter de vêtements (ped spécial).', 'error') end
    shopOpen = true
    local original = Creator.GetAppearance()
    local before = snapshotClothes(PlayerPedId())
    local paid = false
    Creator.Begin({ cam = 'body' })

    -- tenues déjà possédées : gratuites, deviennent la nouvelle base (rien à payer)
    local function outfitsMenu()
        return {
            title = 'VÊTEMENTS', subtitle = 'Mes tenues',
            items = function()
                local list = lib.callback.await('illenium-appearance:server:getOutfits', false) or {}
                local model = GetEntityModel(PlayerPedId())
                local items = {}
                for _, o in ipairs(list) do
                    if not o.model or joaat(o.model) == model or tonumber(o.model) == model then
                        items[#items + 1] = { label = o.name, icon = '👔', description = 'Entrée pour enfiler cette tenue (gratuit, elle t\'appartient déjà).',
                            onSelect = function()
                                local ped = PlayerPedId()
                                Creator.APP:setPedComponents(ped, o.components)
                                Creator.APP:setPedProps(ped, o.props)
                                Creator.SaveAppearance()
                                before = snapshotClothes(ped)
                                original = Creator.GetAppearance()
                                Nova.Notify(('Tenue « %s » enfilée.'):format(o.name), 'success')
                            end }
                    end
                end
                if #items == 0 then items[1] = { label = 'Aucune tenue enregistrée', disabled = true } end
                return items
            end,
        }
    end

    NovaMenu.Open({
        title = 'VÊTEMENTS', subtitle = 'Magasin de vêtements',
        items = function()
            local keys = changedKeys(before)
            local total = priceOf(keys)
            local items = Clothing.Items()
            items[#items + 1] = { type = 'separator', label = 'Tenues' }
            items[#items + 1] = { label = 'Mes tenues', icon = '👔', submenu = outfitsMenu }
            items[#items + 1] = { label = 'Enregistrer cette tenue', icon = '💾', disabled = #keys > 0,
                description = #keys > 0 and 'Paie d\'abord tes vêtements pour pouvoir enregistrer la tenue.' or 'Garde la tenue actuelle dans ta garde-robe.',
                onSelect = function()
                    if #changedKeys(before) > 0 then return Nova.Notify('Paie d\'abord tes vêtements.', 'error') end
                    local name = Nova.TextInput('Nom de la tenue', 'Ex : Tenue de soirée', nil, { max = 40 })
                    if not name then return end
                    local ped = PlayerPedId()
                    local model = GetEntityModel(ped) == joaat('mp_f_freemode_01') and 'mp_f_freemode_01' or 'mp_m_freemode_01'
                    TriggerServerEvent('illenium-appearance:server:saveOutfit', name, model, Creator.APP:getPedComponents(ped), Creator.APP:getPedProps(ped))
                end }
            items[#items + 1] = { type = 'separator', label = 'Caisse' }
            items[#items + 1] = { label = total > 0 and ('Payer %s $'):format(Nova.FormatMoney(total)) or 'Rien à payer', icon = '💳',
                color = total > 0 and '#7df2b9' or nil, disabled = total == 0,
                description = total > 0 and ('%d article(s) modifié(s). Payé en liquide, sinon par carte.'):format(#keys) or 'Change un vêtement pour l\'acheter.',
                onSelect = function()
                    -- le serveur compare avec l'apparence enregistrée, calcule le prix et sauvegarde
                    local ok = lib.callback.await('nova_creator:payClothes', false, Creator.GetAppearance())
                    if ok then
                        paid = true
                        Nova.Notify('Merci pour ton achat !', 'success')
                        NovaMenu.Close()
                    end
                end }
            items[#items + 1] = { label = 'Partir sans acheter', icon = '🚪', onSelect = function() NovaMenu.Close() end }
            return items
        end,
        onClose = function()
            if not paid then Creator.SetAppearance(original) end
            Creator.End()
            shopOpen = false
        end,
    })
end

-- Les points des magasins de vêtements sont dans nova_clothing (nouveau magasin).
-- Clothing.Items reste utilisé par le créateur de personnage.

exports('OpenClothingShop', Clothing.OpenShop)
