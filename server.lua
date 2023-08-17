local _UnimpoundedVehicleCount = 1;

RegisterServerEvent('HRP:Impound:ImpoundVehicle')
RegisterServerEvent('HRP:Impound:GetImpoundedVehicles')
RegisterServerEvent('HRP:Impound:GetVehicles')
RegisterServerEvent('HRP:Impound:UnimpoundVehicle')
RegisterServerEvent('HRP:Impound:UnlockVehicle')

AddEventHandler('HRP:Impound:ImpoundVehicle', function (form)
	_source = source;
    Bridge.ImpoundVehicle(form)
end)

AddEventHandler('HRP:Impound:GetImpoundedVehicles', function (identifier)
	_source = source;
    Bridge.GetImpoundedVehicles(identifier)
end)

AddEventHandler('HRP:Impound:UnimpoundVehicle', function (plate)
	_source = source;
     Bridge.UnImpoundVeh(_source, plate)
end)

AddEventHandler('HRP:Impound:GetVehicles', function ()
	_source = source; 
	Bridge.GetVehs()
end)

AddEventHandler('HRP:Impound:UnlockVehicle', function (plate)
      Bridge.UnlockVeh()
end)

-------------------------------------------------------------------------------------------------------------------------------
-- Stupid extra shit because fuck all of this
-------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent('HRP:ESX:GetCharacter')
AddEventHandler('HRP:ESX:GetCharacter', function (identifier)
	local _source = source
    Bridge.GetCharacter(identifier)
end)

RegisterServerEvent('HRP:ESX:GetVehicleAndOwner')
AddEventHandler('HRP:ESX:GetVehicleAndOwner', function (plate)
	local _source = source
    Bridge.GetVehnOwner(plate)
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