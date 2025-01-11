vRPts = {}
Tunnel.bindInterface("AR_Fight", vRPts)
TSserver = Tunnel.getInterface("AR_Fight", "AR_Fight")
tvRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP", "AR_Fight")

RegisterFontFile('sharlock')

local function drawNativeNotification(text)
    SetTextComponentFormat("STRING")
    AddTextComponentString(text)
    DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end

local function GetClosestPlayer(radius)
    local players = GetActivePlayers()
    local closestDistance = -1
    local closestPlayer = -1
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    for _,playerId in ipairs(players) do
        local targetPed = GetPlayerPed(playerId)
        if targetPed ~= playerPed then
            local targetCoords = GetEntityCoords(targetPed)
            local distance = #(targetCoords-playerCoords)
            if closestDistance == -1 or closestDistance > distance then
                closestPlayer = playerId
                closestDistance = distance
            end
        end
    end
	if closestDistance ~= -1 and closestDistance <= radius then
		return closestPlayer
	else
		return nil
	end
end

local function ensureAnimDict(animDict)
    if not HasAnimDictLoaded(animDict) then
        RequestAnimDict(animDict)
        while not HasAnimDictLoaded(animDict) do
            Wait(0)
        end        
    end
    return animDict
end

local sending = false
local fontId = RegisterFontId('A9eelsh')
function Draw3DText(content, x, y, z)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z + 0.5)
    if onScreen then
        SetTextScale(0.3, 0.3)
        SetTextFont(fontId)
        SetTextProportional(true)
        SetTextColour(0, 0, 0, 255)
        SetTextEntry("STRING")
        SetTextCentre(true)
        AddTextComponentString(content)
        DrawText(_x,_y)
    end
end

local showHeartbeat = false
Citizen.CreateThread(function()
    local lx, ly, lz = nil
    local rotation = 0.0
    Citizen.CreateThread(function()
        while true do
            if (rotation >= 360.0) then rotation = 0.0 end
            rotation = rotation + 0.1
            Citizen.Wait(1)
        end
    end)
    while true do
        if (IsControlJustPressed(0, 344)) then
            TriggerServerEvent("AR_Fight:server:showallfighs")
        end
        local ped = GetPlayerPed(-1)
        local x, y, z = table.unpack(GetEntityCoords(ped))
        for k,v in next, config.playerVplayer do
            lx, ly, lz = table.unpack(v.location)
            if (not v.busy) then
                if (GetDistanceBetweenCoords(x, y, z, lx, ly, lz, true) <= 10.0) then
                    Draw3DText(config.fight_title, lx, ly, lz+0.3)
                    DrawMarker(42, lx, ly, lz, 0.0, 0.0, 0.0, 0.0, 0.0, rotation, 1.0, 1.0, 1.0, 255, 0, 0, 100)
                    if (IsControlJustPressed(0, 38)) then
                        SetNuiFocus(true, true)
                        TriggerServerEvent("AR_Fight:server:setFightStatus", k, true)
                        SendNUIMessage({showPlayerFight = true, name = k})
                    end
                end
            end
        end
        Citizen.Wait(0)
    end
end)
RegisterNetEvent("AR_Fight:client:showallfighs")
AddEventHandler("AR_Fight:client:showallfighs", function(data, allfights)
    SetNuiFocus(true, true)
    SendNUIMessage({showAllFights = true, data = data, allfights = allfights})
end)
RegisterNUICallback('close', function(data, cb)
    SetNuiFocus(false, false)
    TriggerServerEvent("AR_Fight:server:setFightStatus", data.name, false)
end)
RegisterNUICallback('closefightbox', function(data, cb)
    SetNuiFocus(false, false)
end)
RegisterNetEvent("AR_Fight:client:setFightStatus")
AddEventHandler("AR_Fight:client:setFightStatus", function(fightname, status)
    config.playerVplayer[fightname].busy = status
end)
RegisterNUICallback("startFight", function(data, cb)
    SetNuiFocus(false, false)
    local start = 0
    for k, v in next, data.users do
        if (v.team == "1") then
            for kk, vv in next, data.users do
                if (vv.team == "2") then if (v.user_id == vv.user_id) then start = 1 end end
            end
        end
    end
    local foundX = false
    local foundY = false
    for k, v in next, data.users do
        if (v.team == "1") then foundX = true end
        if (v.team == "2") then foundY = true end
    end
    if (not foundX or not foundY) then start = 2 end
    if (start == 0) then
        TriggerServerEvent("AR_Fight:server:setFightStart", data)
    else
        TriggerServerEvent("AR_Fight:server:setFightStatus", data.name, false)
        if (start == 1) then
            TriggerEvent('LuaNotify:Send', {
                name = 'addNotification',
                type = 'error',
                message = 'لا يمكن تواجد اللاعب في الفريقين',
                sound = 'https://cdn.discordapp.com/attachments/789848563928268850/883543701903798302/Desktop_2021.09.04_-_05.46.07.14_Trim.mp3',
                img = 'https://cdn.discordapp.com/attachments/727685588974567435/882963697230827571/close_1.svg',
                time = 5000
            })
        elseif (start == 2) then
            TriggerEvent('LuaNotify:Send', {
                name = 'addNotification',
                type = 'error',
                message = 'لا يمكن للفرق ان تكون فارغة',
                sound = 'https://cdn.discordapp.com/attachments/789848563928268850/883543701903798302/Desktop_2021.09.04_-_05.46.07.14_Trim.mp3',
                img = 'https://cdn.discordapp.com/attachments/727685588974567435/882963697230827571/close_1.svg',
                time = 5000
            })
        end
    end
end)
function freezeTimer()
    Citizen.CreateThread(function()
        Citizen.Wait(1000)
        FreezeEntityPosition(GetPlayerPed(-1), true)
        SendNUIMessage({freezeTime = true})
        Citizen.Wait(6000)
        FreezeEntityPosition(GetPlayerPed(-1), false)
    end)
end
local playerinfight = false
RegisterNetEvent("AR_Fight:client:startFightForAll")
AddEventHandler("AR_Fight:client:startFightForAll", function(data)
	local x1, y1, z1 = table.unpack(config.playerVplayer[data.name].team1_location)
	local x2, y2, z2 = table.unpack(config.playerVplayer[data.name].team2_location)
    local ped = GetPlayerPed(-1)
    playerinfight = true
    Citizen.CreateThread(function()
        while playerinfight do
            DisableControlAction(0, 344, true)
            Citizen.Wait(0)
        end
    end)
    SetEntityHealth(ped, 200)
    SetPedArmour(ped, 0)
    if (tonumber(data.team) == 1) then
        NetworkResurrectLocalPlayer(x1, y1, z1, true, true, false)
        freezeTimer()
    else
        NetworkResurrectLocalPlayer(x2, y2, z2, true, true, false)
        freezeTimer()
    end
    SendNUIMessage({showmainFight = true, round = data.round})
end)
local hosted = false
local team1 = {}
local team2 = {}
RegisterNetEvent("AR_Fight:client:hostedfight")
AddEventHandler("AR_Fight:client:hostedfight", function(data)
    hosted = true
    local totalRound = tonumber(data.round)
    local realRound = 1
    local users = data.users
    local team1Score = 0
    local team2Score = 0
    team1 = {}
    team2 = {}
    local t1x, t1y, t1z = table.unpack(config.playerVplayer[data.name].team1_location)
    local t2x, t2y, t2z = table.unpack(config.playerVplayer[data.name].team2_location)
    for k, v in next, users do
        if (tonumber(v.team) == 1) then
            team1[tostring(v.user_id)] = {ped = GetPlayerPed(GetPlayerFromServerId(v.source)), source = v.source, user_id = v.user_id}
        else
            team2[tostring(v.user_id)] = {ped = GetPlayerPed(GetPlayerFromServerId(v.source)), source = v.source, user_id = v.user_id}
        end
    end
    while hosted do
        local team1Dead = 0
        local team1Count = 0
        local team2Count = 0
        for k, v in next, team1 do
            if (GetEntityHealth(GetPlayerPed(GetPlayerFromServerId(v.source))) <= 120) then team1Dead = team1Dead + 1 end
            team1Count = team1Count + 1
        end
        if (team1Dead == team1Count) then
            team2Score = team2Score + 1
            for k, v in next, users do if (tonumber(v.team) == 2) then TSserver.healteleport({v.user_id, t2x, t2y, t2z}, function() end) else TSserver.healteleport({v.user_id, t1x, t1y, t1z}, function() end) end end
            if (team2Score < totalRound) then
                TriggerServerEvent("AR_Fight:server:increaseRound", 2, data)
                Citizen.Wait(5000)
            else
                TriggerServerEvent("AR_Fight:server:increaseRound", 2, nil)
                TriggerServerEvent("AR_Fight:server:finishfight", data, team1Score, team2Score)
                hosted = false
            end
        end
        local team2Dead = 0
        for k, v in next, team2 do
            if (GetEntityHealth(GetPlayerPed(GetPlayerFromServerId(v.source))) <= 120) then team2Dead = team2Dead + 1 end
            team2Count = team2Count + 1
        end
        if (team2Dead == team2Count) then
            team1Score = team1Score + 1
            for k, v in next, users do if (tonumber(v.team) == 2) then TSserver.healteleport({v.user_id, t2x, t2y, t2z}, function() end) else TSserver.healteleport({v.user_id, t1x, t1y, t1z}, function() end) end end
            if (team1Score < totalRound) then
                TriggerServerEvent("AR_Fight:server:increaseRound", 1, data)
                Citizen.Wait(5000)
            else
                TriggerServerEvent("AR_Fight:server:increaseRound", 1, nil)
                TriggerServerEvent("AR_Fight:server:finishfight", data, team1Score, team2Score)
                hosted = false
            end
        end
        Citizen.Wait(0)
    end
end)
RegisterNetEvent("AR_Fight:client:increaseRound")
AddEventHandler("AR_Fight:client:increaseRound", function(team)
    SendNUIMessage({increaseround = true, team = team})
    freezeTimer()
end)
RegisterNetEvent("AR_Fight:client:resultWin")
AddEventHandler("AR_Fight:client:resultWin", function(teamname, fightname, winner, score, teamtitle)
    Citizen.Wait(1000)
    local x, y, z = table.unpack(config.playerVplayer[fightname].location)
    print("win")
    playerinfight = false
    DisableControlAction(0, 344, false)
    SetEntityCoords(GetPlayerPed(-1), x, y, z)
    SetEntityHealth(GetPlayerPed(-1), 200)
    SetPedArmour(GetPlayerPed(-1), 0)
    SendNUIMessage({endmatch = true, teamwinner = true, teamname = teamname, score = score, title = "WINNER", teamtitle = teamtitle})
end)
RegisterNetEvent("AR_Fight:client:resultLose")
AddEventHandler("AR_Fight:client:resultLose", function(teamname, fightname, winner, score, teamtitle)
    Citizen.Wait(1000)
    local x, y, z = table.unpack(config.playerVplayer[fightname].location)
    print("lose")
    playerinfight = false
    DisableControlAction(0, 344, false)
    SetEntityCoords(GetPlayerPed(-1), x, y, z)
    SetEntityHealth(GetPlayerPed(-1), 200)
    SetPedArmour(GetPlayerPed(-1), 0)
    SendNUIMessage({endmatch = true, teamwinner = true, teamname = teamname, score = score, title = "LOSER", teamtitle = teamtitle})
end)
RegisterNetEvent("AR_Fight:client:hideFightScene")
AddEventHandler("AR_Fight:client:hideFightScene", function()
    print("hide")
    playerinfight = false
    DisableControlAction(0, 344, false)
    SendNUIMessage({endmatch = true})
end)
local lastspecid = nil
local lastspecname = nil
RegisterNUICallback("spectate", function(data, cb)
    if (lastspecid ~= data.userid) then
        lastspecid = data.userid
        lastspecname = data.name
        TriggerServerEvent("AR_Fight:server:setSpectate", lastspecid, lastspecname)
    else
        lastspecid = nil
        NetworkSetInSpectatorMode(false, GetPlayerPed(-1))
    end
end)
RegisterNetEvent("AR_Fight:client:setSpectate")
AddEventHandler("AR_Fight:client:setSpectate", function(source)
    NetworkSetInSpectatorMode(true, GetPlayerPed(GetPlayerFromServerId(source)))
end)
RegisterNetEvent("AR_Fight:client:finishfight")
AddEventHandler("AR_Fight:client:finishfight", function(fightname)
    config.playerVplayer[fightname].busy = false
    playerinfight = false
    DisableControlAction(0, 344, false)
    if (fightname == lastspecname) then
		NetworkSetInSpectatorMode(false, GetPlayerPed(-1))
		lastspecname = nil
	end
end)
RegisterNetEvent("AR_Fight:client:disconnectPlayer")
AddEventHandler("AR_Fight:client:disconnectPlayer", function(user_id)
    print(user_id)
    if (team1[tostring(user_id)] ~= nil) then
        print("remove from team1")
        team1[tostring(user_id)] = nil
    elseif (team2[tostring(user_id)] ~= nil) then
        print("remove from team2")
        team2[tostring(user_id)] = nil
    end
end)