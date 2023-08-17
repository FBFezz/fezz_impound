if not Config.Framework == 'esx' then return end  
ESX = exports["es_extended"]:getSharedObject()
Bridge = {}


Bridge.GetPlayer = function(target)
    local player = ESX.GetPlayerFromId(target)
    if not player then return end
    return player
 end
 

Bridge.RegisterServerCallback = function(name, cb)
    return ESX.RegisterServerCallback(name, cb)
  end

Bridge.GetMoney = function(target, type)
    local Player = Bridge.GetPlayer(target)
    return Player.getAccount(type)
end

Bridge.RemoveMoney = function(target, type, amount)
   local Player = Bridge.GetPlayer(target)
   return Player.removeAccountMoney(type, amount)
end

Bridge.UnImpoundVeh = function(target, plate)
	 local Player = Bridge.GetPlayer(target)

	_UnimpoundedVehicleCount = _UnimpoundedVehicleCount + 1;
    
    if Config.Debug then
	Citizen.Trace('[ESX BRIDGE] HRP: Unimpounding Vehicle with plate: ' .. plate);
    end

	local veh = MySQL.Sync.fetchAll('SELECT * FROM `h_impounded_vehicles` WHERE `plate` = @plate',
	{
		['@plate'] = plate,
	})

	if(veh == nil) then
		TriggerClientEvent("HRP:Impound:CannotUnimpound")
		return
	end

	if (Bridge.GetMoney(Player.source, 'cash') < veh[1].fee) then
		TriggerClientEvent("HRP:Impound:CannotUnimpound")
	else

		Bridge.RemoveMoney('money', round(veh[1].fee));

		MySQL.Async.execute('DELETE FROM `h_impounded_vehicles` WHERE `plate` = @plate',
		{
			['@plate'] = plate,
		}, function (rows)
			TriggerClientEvent('HRP:Impound:VehicleUnimpounded', _source, veh[1], _UnimpoundedVehicleCount)
		end)
	end
end

Bridge.GetCharacter = function(identifier)
	MySQL.Async.fetchAll('SELECT * FROM `users` WHERE `identifier` = @identifier',
		{
			['@identifier'] 		= identifier,
		}, function(users)
		TriggerClientEvent('HRP:ESX:SetCharacter', _source, users[1]);
	end)
end

Bridge.GetVehnOwner = function(plate)
	if (Config.NoPlateColumn == false) then
		MySQL.Async.fetchAll('select * from `owned_vehicles` LEFT JOIN `users` ON users.identifier = owned_vehicles.owner WHERE `plate` = rtrim(@plate)',
			{
				['@plate'] 		= plate,
			}, function(vehicleAndOwner)
			TriggerClientEvent('HRP:ESX:SetVehicleAndOwner', _source, vehicleAndOwner[1]);
		end)
	else
		MySQL.Async.fetchAll('SELECT * FROM `owned_vehicles` LEFT JOIN `users` ON users.identifier = owned_vehicles.owner', {}, function (result)
			for i=1, #result, 1 do
				local vehicleProps = json.decode(result[i].vehicle)

				if vehicleProps.plate:gsub("%s+", "") == plate:gsub("%s+", "") then
					vehicleAndOwner = result[i];
					vehicleAndOwner.plate = vehicleProps.plate;
					TriggerClientEvent('HRP:ESX:SetVehicleAndOwner', _source, vehicleAndOwner);
					break;
				end
			end
		end)
	end
end