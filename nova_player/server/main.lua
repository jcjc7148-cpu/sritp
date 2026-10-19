-- Données stockées dans les metadata ESX :
--   level, xp, playtime (minutes), starter (1 si kit reçu)

local function getData(xPlayer)
    return {
        level = tonumber(xPlayer.getMeta('level')) or 1,
        xp = tonumber(xPlayer.getMeta('xp')) or 0,
        playtime = tonumber(xPlayer.getMeta('playtime')) or 0,
    }
end

local function isNewbie(playtime)
    if not PlayerConfig.NewbieEnabled then return false end
    return playtime < PlayerConfig.NewbieHours * 60
end

local function sync(xPlayer)
    local d = getData(xPlayer)
    local st = Player(xPlayer.source).state
    st:set('level', d.level, true)
    st:set('newbie', isNewbie(d.playtime), true)
    TriggerClientEvent('nova_player:update', xPlayer.source, {
        level = d.level,
        xp = d.xp,
        needed = PlayerConfig.XPForLevel(d.level),
        playtime = d.playtime,
        newbie = isNewbie(d.playtime),
        newbieLeft = math.max(0, PlayerConfig.NewbieHours * 60 - d.playtime),
    })
end

local function giveReward(xPlayer, level)
    local r = PlayerConfig.LevelRewards[level]
    if not r then return end
    if r.bank then xPlayer.addAccountMoney('bank', r.bank, ('Récompense niveau %d'):format(level)) end
    if r.money then xPlayer.addAccountMoney('money', r.money, ('Récompense niveau %d'):format(level)) end
    if r.items and GetResourceState('ox_inventory') == 'started' then
        for _, it in ipairs(r.items) do exports.ox_inventory:AddItem(xPlayer.source, it.name, it.count or 1) end
    end
    Nova.Notify(xPlayer.source, ('Récompense du niveau %d : %s'):format(level, r.label or 'cadeau'), 'success', 8000, 'Récompense')
end

---Ajoute de l'XP à un joueur
local function addXP(src, amount, reason)
    local xPlayer = ESX.GetPlayerFromId(src)
    amount = math.floor(tonumber(amount) or 0)
    if not xPlayer or amount == 0 then return end
    local d = getData(xPlayer)
    d.xp = d.xp + amount

    local leveled = false
    while d.level < PlayerConfig.MaxLevel and d.xp >= PlayerConfig.XPForLevel(d.level) do
        d.xp = d.xp - PlayerConfig.XPForLevel(d.level)
        d.level = d.level + 1
        leveled = true
        giveReward(xPlayer, d.level)
    end
    if d.level >= PlayerConfig.MaxLevel then d.xp = 0 end
    if d.xp < 0 then d.xp = 0 end

    xPlayer.setMeta('level', d.level)
    xPlayer.setMeta('xp', d.xp)
    if leveled then
        TriggerClientEvent('nova_player:levelUp', src, d.level)
        Nova.Log('default', 'Niveau', ('%s est passé niveau %d'):format(GetPlayerName(src), d.level), src)
    elseif amount > 0 then
        TriggerClientEvent('nova_player:xp', src, amount, reason)
    end
    sync(xPlayer)
end

local function setLevel(src, level)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return false end
    level = math.max(1, math.min(PlayerConfig.MaxLevel, math.floor(tonumber(level) or 1)))
    xPlayer.setMeta('level', level)
    xPlayer.setMeta('xp', 0)
    sync(xPlayer)
    return true
end

exports('AddXP', addXP)
exports('SetLevel', setLevel)
exports('GetLevel', function(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    return xPlayer and getData(xPlayer).level or 1
end)
exports('IsNewbie', function(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    return xPlayer and isNewbie(getData(xPlayer).playtime) or false
end)
exports('GetPlaytime', function(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    return xPlayer and getData(xPlayer).playtime or 0
end)

-- Arrivée d'un joueur
AddEventHandler('esx:playerLoaded', function(src, xPlayer, isNew)
    if xPlayer.getMeta('level') == nil then xPlayer.setMeta('level', 1) end
    if xPlayer.getMeta('xp') == nil then xPlayer.setMeta('xp', 0) end
    if xPlayer.getMeta('playtime') == nil then xPlayer.setMeta('playtime', 0) end
    sync(xPlayer)

    if xPlayer.getMeta('starter') ~= 1 then
        SetTimeout(20000, function()
            local xp = ESX.GetPlayerFromId(src)
            if not xp or xp.getMeta('starter') == 1 then return end
            xp.setMeta('starter', 1)
            if GetResourceState('ox_inventory') == 'started' then
                for _, it in ipairs(PlayerConfig.StarterKit) do
                    exports.ox_inventory:AddItem(src, it.name, it.count)
                end
            end
            Nova.Notify(src, 'Tu as reçu ton kit de départ (téléphone, eau, pain).', 'success', 8000, 'Bienvenue')
            TriggerClientEvent('nova_player:welcome', src)
        end)
    end
end)

-- Temps de jeu + XP passive
CreateThread(function()
    local minute = 0
    while true do
        Wait(60000)
        minute = minute + 1
        for _, xPlayer in pairs(ESX.GetExtendedPlayers()) do
            local pt = (tonumber(xPlayer.getMeta('playtime')) or 0) + 1
            xPlayer.setMeta('playtime', pt)
            if pt % PlayerConfig.PlaytimeXP.every == 0 then
                addXP(xPlayer.source, PlayerConfig.PlaytimeXP.amount, 'Temps de jeu')
            elseif PlayerConfig.NewbieEnabled and pt == PlayerConfig.NewbieHours * 60 then
                sync(xPlayer)
                Nova.Notify(xPlayer.source, 'Tu n\'es plus un nouveau joueur. Bon jeu !', 'info', 8000)
            end
        end
    end
end)

lib.callback.register('nova_player:getData', function(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return nil end
    local d = getData(xPlayer)
    d.needed = PlayerConfig.XPForLevel(d.level)
    d.newbie = isNewbie(d.playtime)
    return d
end)

RegisterCommand('niveau', function(src)
    if src == 0 then return end
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    local d = getData(xPlayer)
    Nova.Notify(src, ('Niveau %d - %d / %d XP - %dh%02d de jeu'):format(d.level, d.xp, PlayerConfig.XPForLevel(d.level), d.playtime // 60, d.playtime % 60), 'info', 7000, 'Niveau')
end, false)
