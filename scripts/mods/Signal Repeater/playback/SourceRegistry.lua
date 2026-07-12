local mod = get_mod("Signal Repeater")

local Unit = Unit
local WwiseWorld = WwiseWorld
local pairs = pairs

local SourceRegistry = {}

local manual_map = {}
local auto_map = {}

local ring = {}
local ring_pos = 1
local RING_CAP = 512

local installed = false

local function put_auto(source_id, unit)
	if auto_map[source_id] == nil then
		local evicted = ring[ring_pos]
		if evicted ~= nil then
			auto_map[evicted] = nil
		end
		ring[ring_pos] = source_id
		ring_pos = ring_pos + 1
		if ring_pos > RING_CAP then
			ring_pos = 1
		end
	end
	auto_map[source_id] = unit
end

function SourceRegistry.get(source_id)
	local unit = manual_map[source_id]
	if unit ~= nil then
		if Unit.alive(unit) then
			return unit
		end
		manual_map[source_id] = nil
	end

	unit = auto_map[source_id]
	if unit ~= nil then
		if Unit.alive(unit) then
			return unit
		end
		auto_map[source_id] = nil
	end

	return nil
end

local sweep_timer = 0
local SWEEP_INTERVAL = 5

function SourceRegistry.update(dt)
	sweep_timer = sweep_timer + dt
	if sweep_timer < SWEEP_INTERVAL then return end
	sweep_timer = 0

	for source_id, unit in pairs(manual_map) do
		if not Unit.alive(unit) then
			manual_map[source_id] = nil
		end
	end
end

function SourceRegistry.install()
	if installed then return end
	installed = true

	mod:hook(WwiseWorld, "make_auto_source", function(func, wwise_world, unit_or_position, ...)
		local source_id = func(wwise_world, unit_or_position, ...)
		if source_id and unit_or_position and Unit.alive(unit_or_position) then
			put_auto(source_id, unit_or_position)
		end
		return source_id
	end)

	mod:hook(WwiseWorld, "make_manual_source", function(func, wwise_world, unit_or_position, ...)
		local source_id = func(wwise_world, unit_or_position, ...)
		if source_id and unit_or_position and Unit.alive(unit_or_position) then
			manual_map[source_id] = unit_or_position
		end
		return source_id
	end)

	mod:hook_safe(WwiseWorld, "destroy_manual_source", function(wwise_world, source_id)
		manual_map[source_id] = nil
	end)
end

return SourceRegistry
