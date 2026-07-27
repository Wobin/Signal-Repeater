local Managers = Managers
local Unit = Unit
local World = World
local PhysicsWorld = PhysicsWorld
local Vector3 = Vector3
local pcall = pcall
local ipairs = ipairs

local Occlusion = {}

local LOS_FILTER = "filter_minion_line_of_sight_check"

local EAR_HEIGHT = 1.6
local EMITTER_HEIGHT = 1.0
local FAN_RADIUS = 0.6
local NEAR_CLIP = 2.0

local offsets = { { 0, 0 }, { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }
local RAY_COUNT = #offsets

local function get_physics_world()
	local world_manager = Managers.world
	if not world_manager then
		return nil
	end

	local ok, pw = pcall(function()
		local world = world_manager:world("level_world")
		return world and World.get_data(world, "physics_world")
	end)

	if not ok then
		return nil
	end
	return pw
end

local function in_gameplay()
	local state = Managers.state
	return state ~= nil and state.game_mode ~= nil
end

local function listener_position()
	local pm = Managers.player
	if not pm then return nil end
	local player = pm:local_player_safe(1)
	if not player then return nil end
	local unit = player.player_unit
	if not unit or not Unit.alive(unit) then return nil end
	return Unit.world_position(unit, 1) + Vector3(0, 0, EAR_HEIGHT)
end

local function fraction_to(to)
	if not in_gameplay() then
		return 0
	end

	local pw = get_physics_world()
	if not pw then
		return 0
	end

	local from = listener_position()
	if not from then
		return 0
	end

	local ray = to - from
	local distance = Vector3.length(ray)

	if distance <= NEAR_CLIP then
		return 0
	end

	local forward = ray / distance
	local right = Vector3.cross(forward, Vector3(0, 0, 1))
	if Vector3.length(right) < 0.001 then
		return 0
	end
	right = Vector3.normalize(right)
	local up = Vector3.normalize(Vector3.cross(right, forward))

	local blocked = 0

	for _, offset in ipairs(offsets) do
		local target = to + right * (offset[1] * FAN_RADIUS) + up * (offset[2] * FAN_RADIUS)
		local direction = target - from
		local length = Vector3.length(direction)

		if length > 0.01 then
			local ok, hit = pcall(PhysicsWorld.raycast, pw, from, direction / length, length,
				"closest", "collision_filter", LOS_FILTER)
			if ok and hit then
				blocked = blocked + 1
			end
		end
	end

	return blocked / RAY_COUNT
end

function Occlusion.fraction(unit)
	if not unit or not Unit.alive(unit) then
		return 0
	end
	return fraction_to(Unit.world_position(unit, 1) + Vector3(0, 0, EMITTER_HEIGHT))
end

function Occlusion.fraction_at(position)
	if not position then
		return 0
	end
	return fraction_to(position)
end

return Occlusion
