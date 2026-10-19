-- Création de l'identité en menu RageUI (remplace la page d'esx_identity)
-- Enchaîne ensuite sur le créateur de personnage.
Identity = { open = false }

local function validName(v)
    v = Nova.Trim(v or '')
    if #v < CreatorConfig.NameMin or #v > CreatorConfig.NameMax then return false end
    -- lettres (accents compris), espace, tiret et apostrophe
    return v:match("^[%a\128-\255][%a\128-\255 %-]*$") ~= nil
end

local function isLeap(y) return (y % 4 == 0 and y % 100 ~= 0) or y % 400 == 0 end

local function validDob(v)
    local d, m, y = tostring(v or ''):match('^(%d%d?)/(%d%d?)/(%d%d%d%d)$')
    d, m, y = tonumber(d), tonumber(m), tonumber(y)
    if not d then return false, 'Format attendu : JJ/MM/AAAA (ex : 14/07/1998)' end
    local year = GetLocalTime and (GetLocalTime()) or 2026
    if y > year - CreatorConfig.MinAge then return false, ('Tu dois avoir au moins %d ans.'):format(CreatorConfig.MinAge) end
    if y < year - CreatorConfig.MaxAge then return false, ('%d ans maximum.'):format(CreatorConfig.MaxAge) end
    if m < 1 or m > 12 then return false, 'Mois invalide.' end
    local days = { 31, isLeap(y) and 29 or 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
    if d < 1 or d > days[m] then return false, 'Jour invalide.' end
    return true, ('%02d/%02d/%04d'):format(d, m, y)
end

local function openIdentity()
    if Identity.open then return end
    Identity.open = true
    -- une autre session est ouverte (créateur, magasin) : on la coupe proprement
    if Character.IsOpen() then Character.Abort() end
    if Creator.active then
        NovaMenu.Close()
        local t = GetGameTimer()
        while Creator.active and GetGameTimer() - t < 3000 do Wait(50) end
        if Creator.active then Creator.End() end
    end
    local data = { firstname = '', lastname = '', dob = '', sex = 'm', height = 175 }
    local sent = false

    Creator.Begin({ cam = 'full', bucket = true })
    DoScreenFadeIn(500)

    local def
    def = {
        title = 'IDENTITÉ', subtitle = 'Création de ta carte d\'identité',
        items = function()
            local ready = validName(data.firstname) and validName(data.lastname) and data.dob ~= ''
            return {
                { label = 'Prénom', icon = '🪪', rightLabel = data.firstname ~= '' and data.firstname or 'À remplir',
                  onSelect = function()
                      local v = Nova.TextInput('Prénom', ('%d à %d lettres'):format(CreatorConfig.NameMin, CreatorConfig.NameMax), data.firstname ~= '' and data.firstname or nil, { max = CreatorConfig.NameMax })
                      if not v then return end
                      if not validName(v) then return Nova.Notify('Prénom invalide (lettres uniquement).', 'error') end
                      v = Nova.Trim(v); data.firstname = v:sub(1, 1):upper() .. v:sub(2):lower()
                      NovaMenu.Refresh()
                  end },
                { label = 'Nom', icon = '🪪', rightLabel = data.lastname ~= '' and data.lastname or 'À remplir',
                  onSelect = function()
                      local v = Nova.TextInput('Nom de famille', ('%d à %d lettres'):format(CreatorConfig.NameMin, CreatorConfig.NameMax), data.lastname ~= '' and data.lastname or nil, { max = CreatorConfig.NameMax })
                      if not v then return end
                      if not validName(v) then return Nova.Notify('Nom invalide (lettres uniquement).', 'error') end
                      v = Nova.Trim(v); data.lastname = v:sub(1, 1):upper() .. v:sub(2):lower()
                      NovaMenu.Refresh()
                  end },
                { label = 'Date de naissance', icon = '🎂', rightLabel = data.dob ~= '' and data.dob or 'À remplir',
                  onSelect = function()
                      local v = Nova.TextInput('Date de naissance', 'JJ/MM/AAAA', data.dob ~= '' and data.dob or nil, { max = 10, placeholder = '14/07/1998' })
                      if not v then return end
                      local ok, res = validDob(Nova.Trim(v))
                      if not ok then return Nova.Notify(res, 'error') end
                      data.dob = res
                      NovaMenu.Refresh()
                  end },
                { type = 'list', label = 'Sexe', icon = '⚧️', values = { 'Homme', 'Femme' }, index = data.sex == 'f' and 2 or 1,
                  onChange = function(_, i)
                      data.sex = i == 2 and 'f' or 'm'
                      Creator.SetModel(data.sex == 'f' and 'mp_f_freemode_01' or 'mp_m_freemode_01')
                  end },
                { type = 'slider', label = 'Taille', icon = '📏', min = CreatorConfig.MinHeight, max = CreatorConfig.MaxHeight, step = 1, value = data.height,
                  description = 'En centimètres (gauche / droite)',
                  onChange = function(v) data.height = v end },
                { type = 'separator' },
                { label = 'Valider mon identité', icon = '✅', color = ready and '#7df2b9' or nil, disabled = not ready,
                  description = ready and ('%s %s, né(e) le %s, %d cm'):format(data.firstname, data.lastname, data.dob, data.height) or 'Remplis ton prénom, ton nom et ta date de naissance.',
                  confirm = 'Valider cette identité ? Elle ne pourra plus être changée.',
                  onSelect = function()
                      local ok, err = lib.callback.await('nova_creator:registerIdentity', false, {
                          firstname = data.firstname, lastname = data.lastname, dateofbirth = data.dob, sex = data.sex, height = data.height,
                      })
                      if not ok then return Nova.Notify(err or 'Identité refusée.', 'error') end
                      sent = true
                      NovaMenu.Close()
                  end },
            }
        end,
        onBack = function()
            Nova.Notify('Remplis ton identité pour continuer.', 'info')
            return false
        end,
        onClose = function()
            if not sent then
                -- fermé par autre chose : on rouvre
                SetTimeout(300, function() if Identity.open and not sent then NovaMenu.Open(def) end end)
                return
            end
            Identity.open = false
            Creator.End()
            Wait(300)
            -- on enchaîne sur le créateur de personnage
            Character.Open({ mode = 'new', sex = data.sex, onDone = function()
                TriggerEvent('nova_creator:finished')
            end })
        end,
    }
    NovaMenu.Open(def)
    if GetEntityModel(PlayerPedId()) ~= joaat('mp_m_freemode_01') then
        CreateThread(function() Creator.SetModel('mp_m_freemode_01') end)
    end
end

-- Appelé par esx_identity quand le joueur n'a pas encore d'identité
RegisterNetEvent('nova_creator:identity', function()
    CreateThread(openIdentity)
end)

exports('OpenIdentity', function() CreateThread(openIdentity) end)
