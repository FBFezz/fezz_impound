if not Config.Framework == 'esx' then return end  
ESX = exports["es_extended"]:getSharedObject()
Bridge = {}
Bridge.playerLoaded = false
Bridge.PlayerData = {}
local isDead 

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded',function(xPlayer, isNew, skin)
   Bridge.PlayerData = xPlayer
   Bridge.playerLoaded = true
end)

AddEventHandler('esx:onPlayerSpawn', function(spawn)
	isDead = false
end)

AddEventHandler('esx:onPlayerDeath', function(data)
	isDead = true
end)

RegisterNetEvent('esx:onPlayerLogout', function()
    TriggerEvent('Bridge-lib:onPlayerLogout')
    table.wipe(Bridge.PlayerData)
    Bridge.PlayerData = false
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	Bridge.PlayerData.job = job
end)


AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName or not ESX.PlayerLoaded then return end
    Bridge.PlayerData= ESX.GetPlayerData()
    Bridge.playerLoaded = true
end)

  
 Bridge.TriggerServerCallback = function(name, cb, ...)
    return ESX.TriggerServerCallback(name, cb, ...)
 end
  
 Bridge.IsSpawnPointClear = function(coords)
     return ESX.Game.IsSpawnPointClear(coords)
 end
 
 Bridge.ClientSpawnVehicle = function(model, coords, heading, cb)
     return ESX.Game.SpawnVehicle(model, coords, heading, cb)
 end
 
 Bridge.GetPlayerData = function()
   return Bridge.PlayerData
 end

 Bridge.Notify = function(msg, type)
  return ESX.ShowNotification(msg, type)
 end

 Bridge.ClientSpawnVehicle = function(model, coords, heading, cb)
    return ESX.Game.SpawnVehicle(model, coords, heading, cb)
end

Bridge.SetVehicleProperties = function(veh, props)
  return ESX.Game.SetVehicleProperties(veh, props)
end

Bridge.GetVehicleProperties = function(veh)
  return ESX.Game.GetVehicleProperties(veh)
end

Bridge.GetClosestVeh = function(coords, filter)
  return ESX.Game.GetClosestVehicle(coords, filter)
end

Bridge.ClientDeleteVeh = function(veh)
   return ESX.Game.DeleteVehicle(veh)
end

Bridge.TextUI = function(msg)
  return ESX.TextUI(msg)
end

Bridge.HideUI = function()
  return ESX.HideUI()
end

 AddEventHandler('fezz_impound:notify', Bridge.Notify)