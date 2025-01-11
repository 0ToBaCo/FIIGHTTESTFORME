local Tunnel = module("vrp", "lib/Tunnel")
local Proxy = module("vrp", "lib/Proxy")
vRPclient = Tunnel.getInterface("vRP", "AR_Fight")
vRPclient2 = Tunnel.getInterface("AR_Fight", "AR_Fight")
vRP = Proxy.getInterface("vRP")
vRPts = {}
Tunnel.bindInterface("AR_Fight", vRPts)

local fights = {}
local allfights = {}
local allfightsindex = 0

RegisterNetEvent("AR_Fight:server:showallfighs")
AddEventHandler("AR_Fight:server:showallfighs", function()
    local source = source
    TriggerClientEvent("AR_Fight:client:showallfighs", source, fights, allfights)
end)

RegisterNetEvent("AR_Fight:server:hideRespawn")
AddEventHandler("AR_Fight:server:hideRespawn", function()
    local source = source
    vRP.closeMenu({source})
end)
RegisterNetEvent("AR_Fight:server:setFightStatus")
AddEventHandler("AR_Fight:server:setFightStatus", function(fightname, status)
    TriggerClientEvent("AR_Fight:client:setFightStatus", -1, fightname, status)
end)
RegisterNetEvent("AR_Fight:server:setFightStart")
AddEventHandler("AR_Fight:server:setFightStart", function(data)
    local source = source
    local self_user_id = vRP.getUserId({source})
    local host_id = tostring(vRP.getUserId({source}))
    if (fights[host_id] ~= nil) then fights[host_id] = nil end
    local users = data.users
    local round = data.round
    local tunc = false
    local tunc_id = 0
    local nearfounder = true
    vRPclient.getNearestPlayers(source, {10}, function(nplayer)
        for k, v in next, users do
            if self_user_id ~= tonumber(v.user_id) then
                local founderstate = false
                for nearsource, nearuser_id in next, nplayer do
                    if tonumber(v.user_id) == tonumber(vRP.getUserId({nearsource})) then founderstate = true end
                end
                if not founderstate then nearfounder = false tunc_id = v.user_id break end
            end
        end
        for k, v in next, users do if (vRP.getUserSource({tonumber(v.user_id)}) == nil) then tunc_id = v.user_id tunc = true end end
        if (tunc) then
            if (fights[host_id] ~= nil) then fights[host_id] = nil end
            TriggerClientEvent("AR_Fight:client:setFightStatus", -1, data.name, false)
            TriggerClientEvent('LuaNotify:Send', source, {
                name = 'addNotification',
                type = 'error',
                message = 'اللاعب '..tunc_id..' غير متصل',
                sound = 'https://cdn.discordapp.com/attachments/789848563928268850/883543701903798302/Desktop_2021.09.04_-_05.46.07.14_Trim.mp3',
                img = 'https://cdn.discordapp.com/attachments/727685588974567435/882963697230827571/close_1.svg',
                time = 5000
            })
        elseif not nearfounder then
            if (fights[host_id] ~= nil) then fights[host_id] = nil end
            TriggerClientEvent("AR_Fight:client:setFightStatus", -1, data.name, false)
            TriggerClientEvent('LuaNotify:Send', source, {
                name = 'addNotification',
                type = 'error',
                message = 'اللاعب '..tunc_id..' بعيد عن ساحة القتال',
                sound = 'https://cdn.discordapp.com/attachments/789848563928268850/883543701903798302/Desktop_2021.09.04_-_05.46.07.14_Trim.mp3',
                img = 'https://cdn.discordapp.com/attachments/727685588974567435/882963697230827571/close_1.svg',
                time = 5000
            })
        else
            fights[host_id] = {}
            fights[host_id]["isplaying"] = false
            fights[host_id]["name"] = data.name
            fights[host_id]["round"] = data.round
            fights[host_id]["team_a"] = 0
            fights[host_id]["team_b"] = 0
            fights[host_id]["team_a_score"] = 0
            fights[host_id]["team_b_score"] = 0
            fights[host_id]["players"] = 0
            fights[host_id]['hoster'] = host_id
            fights[host_id]['users'] = {}
            for k, v in next, users do
                if (v.user_id) then
                    local nsource = vRP.getUserSource({tonumber(v.user_id)})
                    v.source = nsource
                    table.insert(fights[host_id]['users'], {user_id = v.user_id, team = v.team, username = GetPlayerName(nsource)})
                    local team = tonumber(v.team)
                    if (team == 1) then team = "A" else team = "B" end
                    vRP.request({nsource, team.."هل تريد بدء المباراة بفريق", 30, function(player, ok)
                        if (not ok) then
                            if fights[host_id] ~= nil then
                                if (team == "A") then fights[host_id]["team_a"] = tonumber(fights[host_id]["team_a"]) + 1 else fights[host_id]["team_b"] = tonumber(fights[host_id]["team_b"]) + 1 end
                                TriggerClientEvent("AR_Fight:client:setFightStatus", -1, data.name, false)
                                TriggerClientEvent('LuaNotify:Send', source, {
                                        name = 'addNotification',
                                        type = 'error',
                                        message = 'اللاعب '..v.user_id..' رفض البدء',
                                        sound = 'https://cdn.discordapp.com/attachments/789848563928268850/883543701903798302/Desktop_2021.09.04_-_05.46.07.14_Trim.mp3',
                                        img = 'https://cdn.discordapp.com/attachments/727685588974567435/882963697230827571/close_1.svg',
                                        time = 5000
                                    })
                                if (fights[host_id] ~= nil) then fights[host_id] = nil end
                            end
                        else
                            TriggerEvent("AR_Fight:server:setReject", source, data)
                        end
                    end})
                end
            end
        end
    end)
end)
RegisterNetEvent("AR_Fight:server:setSpectate")
AddEventHandler("AR_Fight:server:setSpectate", function(userid, fightname)
    local source = source
    local nsource = vRP.getUserSource({tonumber(userid)})
    if (nsource) then
        for k, v in next, fights do
            if (v.name == fightname) then
                if (v.isplaying) then TriggerClientEvent("AR_Fight:client:setSpectate", source, nsource) end
                break
            end
        end
    end
end)
RegisterNetEvent("AR_Fight:server:setReject")
AddEventHandler("AR_Fight:server:setReject", function(source, data)
    local source = source
    local host_id = tostring(vRP.getUserId({source}))
    local counter = 0
    fights[host_id]["players"] = tonumber(fights[host_id]["players"]) + 1
    for k, v in next, data.users do counter = counter + 1 end
    if (counter == tonumber(fights[host_id]["players"])) then
        fights[host_id]["isplaying"] = true
        for k, v in next, data.users do
            local nsource = vRP.getUserSource({tonumber(v.user_id)})
            TriggerClientEvent("AR_Fight:client:startFightForAll", nsource, {name = data.name, user_id = v.user_id, team = v.team, round = data.round})
        end
        local ndata = {}
        ndata["round"] = data.round
        ndata["name"] = data.name
        ndata['users'] = {}
        for k, v in next, data.users do
            local nsource = vRP.getUserSource({tonumber(v.user_id)})
            table.insert(ndata['users'], {source = nsource, name = GetPlayerName(nsource), user_id = v.user_id, team = v.team})
        end
        TriggerClientEvent("AR_Fight:client:hostedfight", source, ndata)
    end
end)
RegisterNetEvent("AR_Fight:server:increaseRound")
AddEventHandler("AR_Fight:server:increaseRound", function(team, data)
    local source = source
    local host_id = tostring(vRP.getUserId({source}))
    if (fights[host_id] ~= nil) then
        if (team == 1) then
            fights[host_id]["team_a_score"] = tonumber(fights[host_id]["team_a_score"]) + 1
        else
            fights[host_id]["team_b_score"] = tonumber(fights[host_id]["team_b_score"]) + 1
        end
    end
    if (data ~= nil) then
        for k,v in next, data.users do
            local nsource = vRP.getUserSource({tonumber(v.user_id)})
            TriggerClientEvent("AR_Fight:client:increaseRound", nsource, team)
        end
    end
end)
function vRPts.healteleport(user_id, x, y, z)
    Citizen.CreateThread(function()
        local nsource = vRP.getUserSource({tonumber(user_id)})
        vRPclient.varyHealth(nsource, {100})
        vRPclient.teleport(nsource, {x, y, z})
    end)
end
RegisterNetEvent("AR_Fight:server:finishfight")
AddEventHandler("AR_Fight:server:finishfight", function(data, team1, team2)
    -- print("finish fight")
    local source = source
    local host_id = tostring(vRP.getUserId({source}))
    allfights[allfightsindex] = fights[host_id]
    allfightsindex = allfightsindex + 1
    fights[host_id] = nil
    TriggerClientEvent("AR_Fight:client:finishfight", -1, data.name)
    local winner = 0
    if (team1 > team2) then winner = 1 elseif (team1 < team2) then winner = 2 else winner = 0 end
    local users = data.users
    for k,v in next, users do
        if (winner == 1) then
            if (v.team == "1") then TriggerClientEvent("AR_Fight:client:resultWin", vRP.getUserSource({tonumber(v.user_id)}), "team1", data.name, winner, team1, "TEAM A") else TriggerClientEvent("AR_Fight:client:resultLose", vRP.getUserSource({tonumber(v.user_id)}), "team2", data.name, winner, team2, "TEAM B") end
        elseif (winner == 2) then
            if (v.team == "2") then TriggerClientEvent("AR_Fight:client:resultWin", vRP.getUserSource({tonumber(v.user_id)}), "team2", data.name, winner, team2, "TEAM B") else TriggerClientEvent("AR_Fight:client:resultLose", vRP.getUserSource({tonumber(v.user_id)}), "team1", data.name, winner, team1, "TEAM A") end
        end
    end
end)
AddEventHandler("vRP:playerLeave", function(user_id, source)
    local source = source
    local user_id = user_id
    if (fights[user_id] ~= nil) then
        TriggerClientEvent("AR_Fight:client:finishfight", -1, fights[user_id].name)
        for k, v in next, fights[user_id]['users'] do
            local nsource = vRP.getUserSource({tonumber(v.user_id)})
            TriggerClientEvent('LuaNotify:Send', nsource, {
                name = 'addNotification',
                type = 'error',
                message = 'تم إنهاء المباراة لمغادرة المضيف',
                sound = 'https://cdn.discordapp.com/attachments/789848563928268850/883543701903798302/Desktop_2021.09.04_-_05.46.07.14_Trim.mp3',
                img = 'https://cdn.discordapp.com/attachments/727685588974567435/882963697230827571/close_1.svg',
                time = 5000
            })
            TriggerClientEvent("AR_Fight:client:hideFightScene", nsource)
        end
        allfights[allfightsindex] = fights[user_id]
        allfightsindex = allfightsindex + 1
        fights[user_id] = nil
    else
        for k, v in next, fights do
            if (v.isplaying) then
                for kk, vv in next, v.users do
                    if (tostring(vv.user_id) == tostring(user_id)) then
                        print(k)
                        local nsource = vRP.getUserSource({tonumber(k)})
                        print(nsource)
                        TriggerClientEvent("AR_Fight:client:disconnectPlayer", nsource, vv.user_id)
                        break
                    end
                end
            end
        end
    end
end)



  