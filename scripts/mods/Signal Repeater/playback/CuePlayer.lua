local mod = get_mod("Signal Repeater")
local Debug = mod.cue_debug
local Curves = mod.curves

local MinionPerception = require("scripts/utilities/minion_perception")

local Unit = Unit
local ScriptUnit = ScriptUnit
local Managers = Managers
local Vector3 = Vector3
local math_random = math.random
local math_huge = math.huge
local pairs = pairs
local table_remove = table.remove
local pcall = pcall
local tostring = tostring

local CuePlayer = {}

local active = {}

local ramps = {}

local glob_cache = {}

local FOLLOW_THROTTLE = 0.1
local TARGET_REFRESH = 0.5

local MIN_DISTANCE = 5

local DECAY = 0

CuePlayer.MIN_DISTANCE = MIN_DISTANCE
CuePlayer.DECAY = DECAY

local function cue_volume(cue)
	return mod.settings.volume() * (cue.gain or 1)
end

local function cue_max_distance(cue)
	return cue.max_distance or mod.settings.max_distance()
end

local function cue_min_distance(cue)
	return cue.min_distance or MIN_DISTANCE
end

local unit_alive = mod.units.alive

local function glob_list(pattern, key)
	local list = glob_cache[key]
	if not list then
		local ok, result = pcall(mod.simple_audio.glob, pattern)
		if ok and result then
			list = result:list()
		else
			list = {}
		end
		glob_cache[key] = list
	end
	return list
end

local function minion_speed(unit)
	local ok, locomotion = pcall(ScriptUnit.has_extension, unit, "locomotion_system")
	if not ok or not locomotion then
		return 0
	end
	local got, velocity = pcall(function() return locomotion:current_velocity() end)
	if not got or not velocity then
		return 0
	end
	return Vector3.length(velocity)
end

local function minion_gait(unit, gaits)
	local speed = minion_speed(unit)
	for i = 1, #gaits do
		if speed >= gaits[i][2] then
			return gaits[i][1]
		end
	end
	return gaits[#gaits][1]
end

local function resolve_surface(cue, audio, unit)
	local surfaces = mod.footstep_surfaces[audio.surfaces]
	if not surfaces then
		return nil
	end

	local ok, material = pcall(Unit.get_data, unit, "cache_material")
	if not ok then
		material = nil
	end

	if material and surfaces.silent[material] then
		return nil
	end

	local gait = minion_gait(unit, audio.gaits)
	local for_gait = surfaces[gait]
	local set = for_gait[material or "concrete"] or for_gait.concrete
	if not set then
		return nil
	end

	local key = cue.key .. "|" .. gait .. "|" .. set
	local list = glob_list(audio.base .. "/" .. gait .. "/" .. set .. "/*.ogg", key)
	local n = #list
	if n == 0 then
		return nil
	end
	return list[math_random(n)]
end

local function resolve_audio(cue, audio_override, cache_key, unit)
	local audio = audio_override or cue.audio
	if audio.kind == "file" then
		return audio.path
	end

	if audio.kind == "surface" then
		return resolve_surface(cue, audio, unit)
	end

	local list = glob_list(audio.pattern, cache_key or cue.key)
	local n = #list
	if n == 0 then
		return nil
	end
	return list[math_random(n)]
end

local function unit_position(unit)
	return Unit.world_position(unit, 1)
end

local function ramp_interval(params, distance)
	return Curves.interval_at(params.curve, distance)
end

local function pitch_filter(cue, distance)
	local points = cue.ramp and cue.ramp.pitch_cents
	if not points or not distance then
		return cue.filters
	end

	local cents = Curves.piecewise(points, distance)
	return Curves.pitch_filter_string(Curves.pitch_rate(cents))
end

local function stop_constant(ramp)
	if ramp.constant_id then
		mod.simple_audio.stop_file(ramp.constant_id)
		ramp.constant_id = nil
	end
end

local TICK_HISTORY = 8

local function remember_tick(ramp, play_id)
	local ids = ramp.tick_ids
	ids[#ids + 1] = play_id
	if #ids > TICK_HISTORY then
		table_remove(ids, 1)
	end
end

local function stop_ramp_sounds(ramp)
	stop_constant(ramp)

	local ids = ramp.tick_ids
	for i = 1, #ids do
		mod.simple_audio.stop_file(ids[i])
	end
	ramp.tick_ids = {}
end

local function target_unit_of(unit)
	local session_manager = Managers.state.game_session
	local unit_spawner = Managers.state.unit_spawner
	if not session_manager or not unit_spawner then return nil end

	local game_object_id = unit_spawner:game_object_id(unit)
	if not game_object_id then return nil end

	local ok, target = pcall(MinionPerception.target_unit, session_manager:game_session(), game_object_id)
	if ok and unit_alive(target) then
		return target
	end
	return nil
end

local function local_player_position()
	local pm = Managers.player
	if not pm then return nil end
	local player = pm:local_player_safe(1)
	if not player then return nil end
	local player_unit = player.player_unit
	if not unit_alive(player_unit) then return nil end
	return unit_position(player_unit)
end

local function apply_position(entry)
	if not unit_alive(entry.unit) then return end
	local min_d, max_d = cue_min_distance(entry.cue), cue_max_distance(entry.cue)
	for i = 1, #entry.play_ids do
		mod.simple_audio.set_position(entry.play_ids[i], entry.unit, DECAY, min_d, max_d)
	end
end

local function stop_entry(entry)
	for i = 1, #entry.play_ids do
		mod.simple_audio.stop_file(entry.play_ids[i])
	end
end

local overlap_seq = 0
local clock = 0
local prune_clock = 0
local last_played = {}

local PRUNE_INTERVAL = 10
local PRUNE_AGE = 30

function CuePlayer.play(cue, unit, explicit_path)
	if not unit_alive(unit) then return end

	if cue.min_interval then
		local rate_key = cue.key .. "|" .. tostring(unit)
		local last = last_played[rate_key]
		if last and clock - last < cue.min_interval then return end
		last_played[rate_key] = clock
	end

	local key
	if cue.overlap then
		overlap_seq = overlap_seq + 1
		key = cue.key .. "|" .. tostring(unit) .. "|" .. overlap_seq
	else
		key = cue.key .. "|" .. tostring(unit)
		if active[key] then return end
	end

	local layers = explicit_path and { false } or (cue.layers or { cue.audio })
	local entry = { unit = unit, cue = cue, elapsed = 0, throttle = 0, play_ids = {} }
	local first_path

	for i = 1, #layers do
		local path = explicit_path or resolve_audio(cue, layers[i], cue.key .. "|L" .. i, unit)
		if path then
			first_path = first_path or path

			local settings = {
				audio_type = mod.settings.audio_type(),
				volume = cue_volume(cue),
				loop = cue.mode == "loop" or nil,
				filters = cue.filters,
			}

			if i == 1 then
				settings.on_update = function(play_id, dt)
					entry.throttle = entry.throttle + dt
					if entry.throttle >= FOLLOW_THROTTLE then
						entry.throttle = 0
						apply_position(entry)
					end
				end
				settings.on_finished = function()
					active[key] = nil
				end
			end

			local id = mod.simple_audio.play_file(
				path, settings, unit, DECAY, cue_min_distance(cue), cue_max_distance(cue)
			)
			if id then
				entry.play_ids[#entry.play_ids + 1] = id
			end
		end
	end

	if not entry.play_ids[1] then return end

	active[key] = entry
	apply_position(entry)

	if mod.settings.debug() then
		local player_pos = local_player_position()
		Debug.played(cue, first_path, player_pos and Vector3.distance(unit_position(unit), player_pos) or nil)
	end
end

function CuePlayer.start_ramp(cue, unit)
	if not unit_alive(unit) then return end
	local key = cue.key .. "|" .. tostring(unit)
	if ramps[key] then return end
	ramps[key] = {
		cue = cue,
		unit = unit,
		timer = math_huge,
		target_timer = math_huge,
		follow_timer = 0,
		tick_ids = {},
	}
	Debug.ramp(cue, "started")
end

function CuePlayer.stop_unit(cue, unit)
	if not unit then return end
	local key = cue.key .. "|" .. tostring(unit)

	if cue.overlap then
		for k, entry in pairs(active) do
			if entry.cue == cue and entry.unit == unit then
				stop_entry(entry)
				active[k] = nil
				Debug.stopped(cue, "stop event")
			end
		end
	else
		local entry = active[key]
		if entry then
			stop_entry(entry)
			active[key] = nil
			Debug.stopped(cue, "stop event")
		end
	end

	local ramp = ramps[key]
	if ramp then
		stop_ramp_sounds(ramp)
		ramps[key] = nil
		Debug.ramp(cue, "ended")
	end
end

function CuePlayer.stop_all()
	for key, entry in pairs(active) do
		stop_entry(entry)
		active[key] = nil
	end
	for key, ramp in pairs(ramps) do
		stop_ramp_sounds(ramp)
		ramps[key] = nil
	end
end

function CuePlayer.update(dt)
	local enabled = mod.settings.active()

	clock = clock + dt
	if clock - prune_clock >= PRUNE_INTERVAL then
		prune_clock = clock
		for rate_key, when in pairs(last_played) do
			if clock - when > PRUNE_AGE then
				last_played[rate_key] = nil
			end
		end
	end

	for key, entry in pairs(active) do
		entry.elapsed = entry.elapsed + dt
		local cue = entry.cue
		local expired = cue.max_duration and entry.elapsed >= cue.max_duration
		local turned_off = not enabled or not mod.settings.cue_enabled(cue.setting_id)
		if (not unit_alive(entry.unit)) or expired or turned_off then
			stop_entry(entry)
			active[key] = nil
			Debug.stopped(cue, expired and "max_duration" or (turned_off and "disabled" or "unit dead"))
		end
	end

	local player_pos, player_pos_done = nil, false
	for key, ramp in pairs(ramps) do
		local unit = ramp.unit
		local cue = ramp.cue

		if not unit_alive(unit) then
			stop_ramp_sounds(ramp)
			ramps[key] = nil
			Debug.ramp(cue, "ended")
		elseif not enabled or not mod.settings.cue_enabled(cue.setting_id) then
			stop_ramp_sounds(ramp)
		else
			if not player_pos_done then
				player_pos = local_player_position()
				player_pos_done = true
			end

			ramp.target_timer = ramp.target_timer + dt
			if ramp.target_timer >= TARGET_REFRESH then
				ramp.target_timer = 0
				ramp.target = target_unit_of(unit)
			end
			if ramp.target and not unit_alive(ramp.target) then
				ramp.target = nil
			end

			local emitter_pos = unit_position(unit)
			local reference_pos = ramp.target and unit_position(ramp.target) or player_pos

			if reference_pos then
				local params = cue.ramp
				local d = Vector3.distance(emitter_pos, reference_pos)
				local listener_distance = player_pos and Vector3.distance(emitter_pos, player_pos) or nil
				local constant = params.constant

				if constant and d <= constant.distance then
					if not ramp.constant_id then
						ramp.constant_id = mod.simple_audio.play_file(
							constant.path,
							{
								audio_type = mod.settings.audio_type(),
								volume = cue_volume(cue),
								loop = true,
								filters = pitch_filter(cue, listener_distance),
							},
							unit, DECAY, cue_min_distance(cue), cue_max_distance(cue)
						)
						ramp.follow_timer = 0
					elseif ramp.constant_id then
						ramp.follow_timer = ramp.follow_timer + dt
						if ramp.follow_timer >= FOLLOW_THROTTLE then
							ramp.follow_timer = 0
							mod.simple_audio.set_position(ramp.constant_id, unit, DECAY, cue_min_distance(cue), cue_max_distance(cue))
						end
					end
				else
					stop_constant(ramp)

					ramp.timer = ramp.timer + dt
					if ramp.timer >= ramp_interval(params, d) then
						ramp.timer = 0
						local path = resolve_audio(cue)
						if path then
							local tick_id = mod.simple_audio.play_file(
								path,
								{
									audio_type = mod.settings.audio_type(),
									volume = cue_volume(cue),
									filters = pitch_filter(cue, listener_distance),
								},
								unit, DECAY, cue_min_distance(cue), cue_max_distance(cue)
							)
							if tick_id then
								remember_tick(ramp, tick_id)
							end
						end
					end
				end
			end
		end
	end
end

return CuePlayer
