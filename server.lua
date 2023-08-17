local QBCore = exports['qb-core']:GetCoreObject()

-- Allowed to reset during server restart
-- You can use this number to calculate a vehicle spawn location index if you have multiple
-- eg: 3 spawnlocations = index % 3 + 1
local UnimpoundedVehicleCount = 1;

RegisterServerEvent('HRP:Impound:ImpoundVehicle')
RegisterServerEvent('HRP:Impound:GetImpoundedVehicles')
RegisterServerEvent('HRP:Impound:GetVehicles')
RegisterServerEvent('HRP:Impound:UnimpoundVehicle')
RegisterServerEvent('HRP:Impound:UnlockVehicle')

AddEventHandler('HRP:Impound:ImpoundVehicle', function (form)
	Citizen.Trace("HRP: Impounding vehicle: " .. form.plate);
	local source = source
	MySQL.Async.execute('INSERT INTO `h_impounded_vehicles` VALUES (@plate, @officer, @mechanic, @releasedate, @fee, @reason, @notes, CONCAT(@vehicle), @identifier, @hold_o, @hold_m)',
		{
			['@plate'] 			= form.plate,
			['@officer']     	= form.officer,
			['@mechanic']       = form.mechanic,
			['@releasedate']	= form.releasedate,
			['@fee']			= form.fee,
			['@reason']			= form.reason,
			['@notes']			= form.notes,
			['@vehicle']		= form.vehicle,
			['@identifier']		= form.identifier,
			['@hold_o']			= form.hold_o,
			['@hold_m']			= form.hold_m
		}, function(rowsChanged)
			if (rowsChanged == 0) then
				TriggerClientEvent('QBCore:Notify', source, 'Could not impound')
			else
				TriggerClientEvent('QBCore:Notify', source, 'Vehicle Impounded')
			end
	end)
end)

AddEventHandler('HRP:Impound:GetImpoundedVehicles', function (identifier)
	local source = source
	MySQL.Async.fetchAll('SELECT * FROM `h_impounded_vehicles` WHERE `identifier` = @identifier ORDER BY `releasedate`',
		{
			['@identifier'] = identifier,
		}, function (impoundedVehicles)
			TriggerClientEvent('HRP:Impound:SetImpoundedVehicles', source, impoundedVehicles)
	end)
end)

AddEventHandler('HRP:Impound:UnimpoundVehicle', function (plate)
	local source = source
	local xPlayer = QBCore.Functions.GetPlayer(source)

	UnimpoundedVehicleCount = UnimpoundedVehicleCount + 1;

	Citizen.Trace('HRP: Unimpounding Vehicle with plate: ' .. plate);

	local veh = MySQL.Sync.fetchAll('SELECT * FROM `h_impounded_vehicles` WHERE `plate` = @plate',
	{
		['@plate'] = plate,
	})

	if(veh == nil) then
		TriggerClientEvent("HRP:Impound:CannotUnimpound")
		return
	end

	if (xPlayer.PlayerData.money["cash"] < veh[1].fee) then
		TriggerClientEvent("HRP:Impound:CannotUnimpound")
	else

		xPlayer.Functions.RemoveMoney("cash", round(veh[1].fee), "Impound Fee")

		MySQL.Async.execute('DELETE FROM `h_impounded_vehicles` WHERE `plate` = @plate',
		{
			['@plate'] = plate,
		}, function (rows)
			TriggerClientEvent('HRP:Impound:VehicleUnimpounded', source, veh[1], UnimpoundedVehicleCount)
		end)
	end
end)

AddEventHandler('HRP:Impound:GetVehicles', function ()
	local source = source

	local vehicles = MySQL.Async.fetchAll('SELECT * FROM `h_impounded_vehicles`', nil, function (vehicles)
		TriggerClientEvent('HRP:Impound:SetImpoundedVehicles', source, vehicles);
	end);
end)

AddEventHandler('HRP:Impound:UnlockVehicle', function (plate)
	MySQL.Async.execute('UPDATE `h_impounded_vehicles` SET `hold_m` = false, `hold_o` = false WHERE `plate` = @plate', {
		['@plate'] = plate
	}, function (bs)
		-- Something
	end)
end)

-------------------------------------------------------------------------------------------------------------------------------
-- Stupid extra shit because fuck all of this
-------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent('HRP:ESX:GetCharacter')
AddEventHandler('HRP:ESX:GetCharacter', function (source)
    local player = QBCore.Functions.GetPlayer(source)
    MySQL.Async.fetchAll('SELECT * FROM `players` WHERE `citizenid` = @citizenid',
        {
            ['@citizenid']         =      player.PlayerData.citizenid,
        }, function(users)
        TriggerClientEvent('HRP:ESX:SetCharacter', source, users[1]);
    end)
end)

RegisterServerEvent('HRP:ESX:GetVehicleAndOwner')
AddEventHandler('HRP:ESX:GetVehicleAndOwner', function (plate)
	local source = source
	if (Config.NoPlateColumn == false) then
		MySQL.Async.fetchAll('select * from `player_vehicles` LEFT JOIN `users` ON users.identifier = player_vehicles.owner WHERE `plate` = rtrim(@plate)',
			{
				['@plate'] 		= plate,
			}, function(vehicleAndOwner)
			TriggerClientEvent('HRP:ESX:SetVehicleAndOwner', source, vehicleAndOwner[1]);
		end)
	else
		MySQL.Async.fetchAll('SELECT * FROM `player_vehicles` LEFT JOIN `users` ON users.identifier = player_vehicles.owner', {}, function (result)
			for i=1, #result, 1 do
				local vehicleProps = json.decode(result[i].vehicle)

				if vehicleProps.plate:gsub("%s+", "") == plate:gsub("%s+", "") then
					vehicleAndOwner = result[i];
					vehicleAndOwner.plate = vehicleProps.plate;
					TriggerClientEvent('HRP:ESX:SetVehicleAndOwner', source, vehicleAndOwner);
					break;
				end
			end
		end)
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

function round(x)
	return x>=0 and math.floor(x+0.5) or math.ceil(x-0.5)
end
