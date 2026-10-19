local data = { level = 1, xp = 0, needed = 100, playtime = 0, newbie = false }

RegisterNetEvent('nova_player:update', function(d)
    data = d
end)

RegisterNetEvent('nova_player:levelUp', function(level)
    exports.nova_core:Announce('NIVEAU ' .. level, 'Félicitations, tu passes au niveau ' .. level .. ' !', 6000)
    PlaySoundFrontend(-1, 'RANK_UP', 'HUD_AWARDS', true)
end)

RegisterNetEvent('nova_player:xp', function(amount, reason)
    Nova.Notify(('+%d XP%s'):format(amount, reason and (' • ' .. reason) or ''), 'info', 2500, 'Expérience')
end)

RegisterNetEvent('nova_player:welcome', function()
    exports.nova_core:Announce('BIENVENUE', PlayerConfig.WelcomeMessage, 12000)
end)

exports('GetData', function() return data end)

-- Tag "NOUVEAU" au-dessus des nouveaux joueurs
if PlayerConfig.NewbieTag then
    CreateThread(function()
        while true do
            local sleep = 1000
            local myPed = PlayerPedId()
            local myCoords = GetEntityCoords(myPed)
            for _, pid in ipairs(GetActivePlayers()) do
                local ped = GetPlayerPed(pid)
                if ped ~= myPed then
                    local sid = GetPlayerServerId(pid)
                    if Player(sid).state.newbie then
                        local c = GetEntityCoords(ped)
                        if #(myCoords - c) < 15.0 and HasEntityClearLosToEntity(myPed, ped, 17) then
                            sleep = 0
                            Nova.Draw3DText(vector3(c.x, c.y, c.z + 1.05), '~p~NOUVEAU', 0.45)
                        end
                    end
                end
            end
            Wait(sleep)
        end
    end)
end
