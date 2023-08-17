----------------------------------------------------------------------------------------------------
-- Variables
----------------------------------------------------------------------------------------------------
QBCore = exports['qb-core']:GetCoreObject()

-- local ESX = nil;
-- local XPlayer = nil;
-- local OwnPlayerData = nil;
-- local DependenciesLoaded = false;

local Impound = Config.Impound
local GuiEnabled = false
local VehicleAndOwner = nil;
local ImpoundedVehicles = nil;

----------------------------------------------------------------------------------------------------
-- Setup & Initialization
----------------------------------------------------------------------------------------------------

function ActivateBlips()
	local blip = AddBlipForCoord(Impound.RetrieveLocation.X, Impound.RetrieveLocation.Y, Impound.RetrieveLocation.Z)
	SetBlipScale(blip, 1.25)
	SetBlipDisplay(blip, 4)
	SetBlipSprite(blip, 430)
	SetBlipColour(blip, 3)
	SetBlipAsShortRange(blip, true)
	BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Police Impound")
    EndTextCommandSetBlipName(blip)
end

ActivateBlips()

----------------------------------------------------------------------------------------------------
-- Helper functions
----------------------------------------------------------------------------------------------------

function ShowHelpNotification(text)
    ClearAllHelpMessages();
    SetTextComponentFormat("STRING");
    AddTextComponentString(text);
    DisplayHelpTextFromStringLabel(0, false, true, 5000);
end

-- RegisterNetEvent('HRP:ESX:SetCharacter')
-- AddEventHandler('HRP:ESX:SetCharacter', function (playerData)
-- 	OwnPlayerData = playerData
-- end)

RegisterNetEvent('HRP:ESX:SetVehicleAndOwner')
AddEventHandler('HRP:ESX:SetVehicleAndOwner', function (vehicleAndOwner)
	VehicleAndOwner = vehicleAndOwner;
end)

RegisterNetEvent('HRP:Impound:SetImpoundedVehicles')
AddEventHandler('HRP:Impound:SetImpoundedVehicles', function (impoundedVehicles)
	ImpoundedVehicles = impoundedVehicles;
end)

RegisterNetEvent('HRP:Impound:VehicleUnimpounded')
AddEventHandler('HRP:Impound:VehicleUnimpounded', function (data, index)
	local spawnLocationIndex = index % 3 + 1
	local localVehicle = json.decode(data.vehicle)
	-- print(localVehicle.health);
	QBCore.Functions.SpawnVehicle(localVehicle.model, Impound.SpawnLocations[spawnLocationIndex],
		Impound.SpawnLocations[spawnLocationIndex].h, function (spawnedVehicle)
		QBCore.Functions.SetVehicleProperties(spawnedVehicle, localVehicle)

		SetVehicleEngineHealth(spawnedVehicle, localVehicle.engineHealth);
		SetVehicleBodyHealth(spawnedVehicle, localVehicle.bodyHealth);
		SetVehicleFuelLevel(spawnedVehicle, localVehicle.fuelLevel);
		SetVehiclePetrolTankHealth(spawnedVehicle, localVehicle.petrolTankHealth);
		SetVehicleOilLevel(spawnedVehicle, localVehicle.oilLevel);
		SetVehicleDirtLevel(spawnedVehicle, localVehicle.dirtLevel);

		for windowIndex = 1, 13, 1 do
			Citizen.Trace("Smashing window! ")
			if(localVehicle.windows[windowIndex] == false) then
				SmashVehicleWindow(spawnedVehicle, windowIndex);
			end
		end

		for tyreIndex = 1, 7, 1 do
			Citizen.Trace("Pooppiiiin! ")
			if(localVehicle.tyresburst[tyreIndex] ~= false) then
				SetVehicleTyreBurst(spawnedVehicle, tyreIndex, true, 1000);
			end
		end

	end)
	QBCore.Functions.Notify("Your vehicle with the plate: " .. data.plate .. " has been unimpounded!")
	SetNewWaypoint(Impound.SpawnLocations[spawnLocationIndex].x, Impound.SpawnLocations[spawnLocationIndex].y)
end)

RegisterNetEvent('HRP:Impound:CannotUnimpound')
AddEventHandler('HRP:Impound:CannotUnimpound', function ()
	QBCore.Functions.Notify("Your vehicle cannot be unimpounded at this moment, do you have enough cash?");
end)

----------------------------------------------------------------------------------------------------
-- NUI bs
----------------------------------------------------------------------------------------------------

function ShowImpoundMenu(action)

	local pos = GetEntityCoords(GetPlayerPed(PlayerId()))
	local vehicle = GetClosestVehicle(pos.x, pos.y, pos.z, 5.0, 0, 71)

	if (IsPedInAnyVehicle(GetPlayerPed(PlayerId()))) then
		QBCore.Functions.Notify("Leave the vehicle first")
		return
	end


	if (vehicle ~= nil) then
		local v = QBCore.Functions.GetVehicleProperties(vehicle)
		local data = {}

		TriggerServerEvent('HRP:ESX:GetVehicleAndOwner', v.plate)
		Wait(500);

		if(Config.NoPlateColumn == true) then
			Wait(Config.WaitTime);
		end

		if(VehicleAndOwner == nil) then
			QBCore.Functions.Notify('Unknown vehicle owner, cannot impound');
			return
		end

		data.action = "open"
		data.form 	= "impound"
		data.rules  = Config.Rules
		data.vehicle = {
			plate = VehicleAndOwner.plate,
			owner = VehicleAndOwner.firstname .. ' ' .. VehicleAndOwner.lastname
			}

		if (QBCore.Functions.GetPlayerData().job.name == 'police') then
			local PlayerData = QBCore.Functions.GetPlayerData()
			data.officer = PlayerData.charinfo.firstname .. ' ' .. PlayerData.charinfo.lastname;
			GuiEnabled = true
			SetNuiFocus(true, true)
			SendNuiMessage(json.encode(data))
		end

		if (QBCore.Functions.GetPlayerData().job.name == 'mechanic') then
			local PlayerData = QBCore.Functions.GetPlayerData()
			data.mechanic = PlayerData.charinfo.firstname .. ' ' .. PlayerData.charinfo.lastname;
			GuiEnabled = true
			SetNuiFocus(true, true)
			SendNuiMessage(json.encode(data))
		end
	else
		QBCore.Functions.Notify('No vehicle nearby');
	end
end

function ShowAdminTerminal ()
	local xPlayer = QBCore.Functions.GetPlayerData()
	GuiEnabled = true

	TriggerServerEvent('HRP:Impound:GetVehicles')
	Wait(500)

	SetNuiFocus(true, true)
	local data = {
		action = "open",
		form = "admin",
		user = xPlayer,
		job = xPlayer.job,
		vehicles = ImpoundedVehicles
	}

	SendNuiMessage(json.encode(data))
end

function DisableImpoundMenu ()
	local xPlayer = QBCore.Functions.GetPlayerData()
	GuiEnabled = false
	SetNuiFocus(false)
	SendNuiMessage("{\"action\": \"close\", \"form\": \"none\"}")
	xPlayer = nil;
	VehicleAndOwner = nil;
	ImpoundedVehicles = nil;
end

function ShowRetrievalMenu ()
	local xPlayer = QBCore.Functions.GetPlayerData()

	TriggerServerEvent('HRP:Impound:GetImpoundedVehicles', xPlayer.identifier)
	Wait(500)

	GuiEnabled = true
	SetNuiFocus(true, true)
	local data = {
		action = "open",
		form = "retrieve",
		user = xPlayer,
		job = xPlayer.job,
		vehicles = ImpoundedVehicles
	}

	SendNuiMessage(json.encode(data))
end

RegisterNUICallback('escape', function(data, cb)
	DisableImpoundMenu()

    -- cb('ok')
end)

RegisterNUICallback('impound', function(data, cb)
	local v = QBCore.Functions.GetClosestVehicle();
	local veh = QBCore.Functions.GetVehicleProperties(v);

	veh.engineHealth = GetVehicleEngineHealth(v);
	veh.bodyHealth = GetVehicleBodyHealth(v);
	veh.fuelLevel = GetVehicleFuelLevel(v);
	veh.oilLevel = GetVehicleOilLevel(v);
	veh.petrolTankHealth = GetVehiclePetrolTankHealth(v);
	veh.tyresburst = {};
	for i = 1, 7 do
		res = IsVehicleTyreBurst(v, i, false);
		if res ~= nil then
			veh.tyresburst[#veh.tyresburst+1] = res;
			if res == false then
				res = IsVehicleTyreBurst(v, i, true);
				veh.tyresburst[#veh.tyresburst] = res;
			end
		else
			veh.tyresburst[#veh.tyresburst+1] = false;
		end
	end

	veh.windows = {};
	for i = 1, 13 do
		res = IsVehicleWindowIntact(v, i);
		if res ~= nil then
			veh.windows[#veh.windows+1] = res;
		else
			veh.windows[#veh.windows+1] = true;
		end
	end

	if (veh.plate:gsub("%s+", "") ~= data.plate:gsub("%s+", "")) then
		QBCore.Functions.Notify("The processed vehicle, and nearest vehicle do not match");
		return
	end

	data.vehicle = json.encode(veh);
	data.identifier = VehicleAndOwner.identifier;

	TriggerServerEvent('HRP:Impound:ImpoundVehicle', data)

	QBCore.Functions.DeleteVehicle(QBCore.Functions.GetClosestVehicle());

	DisableImpoundMenu()
    -- cb('ok')
end)

RegisterNUICallback('unimpound', function(plate, cb)
	Citizen.Trace("Unimpounding:" .. plate)
	TriggerServerEvent('HRP:Impound:UnimpoundVehicle', plate);
	DisableImpoundMenu();
	-- cb('ok');
end)

RegisterNUICallback('unlock', function(plate, cb)
	TriggerServerEvent('HRP:Impound:UnlockVehicle', plate)
end)
----------------------------------------------------------------------------------------------------
-- Background tasks
----------------------------------------------------------------------------------------------------

-- Decide what the player is currently doing and showing a help notification.
CreateThread(function ()
	while true do
		inZone = false;
		Wait(500)
			local PlayerPed = GetPlayerPed(PlayerId())
			local PlayerPedCoords = GetEntityCoords(PlayerPed)

			if (GetDistanceBetweenCoords(Impound.RetrieveLocation.X, Impound.RetrieveLocation.Y, Impound.RetrieveLocation.Z,
				PlayerPedCoords.x, PlayerPedCoords.y, PlayerPedCoords.z, false) < 3) then

				inZone = true;

				if (CurrentAction ~= "retrieve") then

					CurrentAction = "retrieve"
					QBCore:Notify("Press ~INPUT_CONTEXT~ To unimpound a vehicle");

				end

			elseif (GetDistanceBetweenCoords(Impound.StoreLocation.X, Impound.StoreLocation.Y, Impound.StoreLocation.Z,
				PlayerPedCoords.x, PlayerPedCoords.y, PlayerPedCoords.z, false) < 3) then

				inZone = true;

				if (CurrentAction ~= "store" and (QBCore.Functions.GetPlayerData().job.name == 'police' or QBCore.Functions.GetPlayerData().job.name == 'mechanic')) then

					CurrentAction = "store"
					QBCore:Notify("Press ~INPUT_CONTEXT~ To impound this vehicle");

				end

			else
				for i, location in ipairs(Impound.AdminTerminalLocations) do
					if (GetDistanceBetweenCoords(location.x, location.y, location.z,
					PlayerPedCoords.x, PlayerPedCoords.y, PlayerPedCoords.z, false) < 3) then

						inZone = true;

						if (CurrentAction ~= "admin" and (QBCore.Functions.GetPlayerData().job.name == 'police' or QBCore.Functions.GetPlayerData().job.name == 'mechanic')) then

							CurrentAction = "admin"
							QBCore:Notify("Press ~INPUT_CONTEXT~ To open the admin terminal");
						end

						break;
					end
				end
			end

		if not inZone then
			CurrentAction = nil;
		end
	end
end)

CreateThread(function ()

	while true do
		Wait(0)
		if (IsControlJustReleased(0, 38)) then
			if (CurrentAction == "retrieve") then
				ShowRetrievalMenu()
			elseif (CurrentAction == "store") then
				ShowImpoundMenu("store")
			elseif (CurrentAction == "admin") then
				ShowAdminTerminal("admin")
			end
		end
	end
end)

-- Disable background actions if the player is currently in a menu
CreateThread(function()
  while true do
    if GuiEnabled then
      local ply = GetPlayerPed(-1)
      local active = true
      DisableControlAction(0, 1, active) -- LookLeftRight
      DisableControlAction(0, 2, active) -- LookUpDown
      DisableControlAction(0, 24, active) -- Attack
      DisablePlayerFiring(ply, true) -- Disable weapon firing
      DisableControlAction(0, 142, active) -- MeleeAttackAlternate
      DisableControlAction(0, 106, active) -- VehicleMouseControlOverride
      if IsDisabledControlJustReleased(0, 24) or IsDisabledControlJustReleased(0, 142) then -- MeleeAttackAlternate
        SendNUIMessage({type = "click"})
      end
    end
    Wait(0)
  end
end)

function dump(o)
	if type(o) == 'table' then
	   local s = '{ '
	   for k,v in pairs(o) do
		  if type(k) ~= 'number' then k = '"'..k..'"' end
		  s = s .. '['..k..'] = ' .. dump(v) .. ','
	   end
	   return s .. '} '
	else
	   return tostring(o)
	end
 end
