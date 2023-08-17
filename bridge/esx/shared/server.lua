Bridge.GetVehs = function()
	local vehicles = MySQL.Async.fetchAll('SELECT * FROM `h_impounded_vehicles`', nil, function (vehicles)
		TriggerClientEvent('HRP:Impound:SetImpoundedVehicles', _source, vehicles);
	end);
end

Bridge.UnlockVeh = function(plate)
	MySQL.Async.execute('UPDATE `h_impounded_vehicles` SET `hold_m` = false, `hold_o` = false WHERE `plate` = @plate', {
		['@plate'] = plate
	}, function (bs)
        if Config.Debug then
            Citizen.Trace('[ESX BRIDGE] HRP: Unlocking Veh ' ..plate .. ' info ' ..bs);
        end
	end)
end

Bridge.GetImpoundedVehicles = function(identifier)
	MySQL.Async.fetchAll('SELECT * FROM `h_impounded_vehicles` WHERE `identifier` = @identifier ORDER BY `releasedate`',
		{
			['@identifier'] = identifier,
		}, function (impoundedVehicles)
			TriggerClientEvent('HRP:Impound:SetImpoundedVehicles', _source, impoundedVehicles)
            if Config.Debug then
                Citizen.Trace('[ESX BRIDGE] HRP: Getting Impounded Vehicles for: ' ..identifier .. ' Found: '..impoundedVehicles);
            end
	end)
end

Bridge.ImpoundVehicle = function(form)
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
            if Config.Debug then
                Citizen.Trace('[ESX BRIDGE] HRP: Impounding vehicle with plate: ' .. form.plate .. ' Owner: ' .. form.identifier);
            end
			if (rowsChanged == 0) then
				TriggerClientEvent('esx:showNotification', _source, 'Could not impound')
			else
				TriggerClientEvent('esx:showNotification', _source, 'Vehicle Impounded')
			end
	end)
end
