local Unit = Unit
local ScriptUnit = ScriptUnit
local pcall = pcall

local Units = {}

function Units.alive(unit)
	if not unit or not Unit.alive(unit) then
		return false
	end

	local ok, health_extension = pcall(ScriptUnit.has_extension, unit, "health_system")
	if ok and health_extension and health_extension.is_alive and not health_extension:is_alive() then
		return false
	end

	return true
end

function Units.breed_name(unit)
	local ok, extension = pcall(ScriptUnit.has_extension, unit, "unit_data_system")
	if not ok or not extension then return nil end

	local got, breed = pcall(function() return extension:breed() end)
	if not got or not breed then return nil end

	return breed.name
end

function Units.breed_matches(breeds, unit)
	if not breeds then return true end

	local name = Units.breed_name(unit)
	if not name then return false end

	for i = 1, #breeds do
		if name == breeds[i] then return true end
	end
	return false
end

return Units
