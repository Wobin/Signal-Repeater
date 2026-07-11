--[[
	Name: Signal Repeater
	Author: Wobin
	Date: 11/07/2026
	Version: 1.0.0
	Repository: https://github.com/Wobin/Signal-Repeater
]]--

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

local function cue_volume(cue)
	return mod.settings.volume() * (cue.gain or 1)
end

local function cue_max_distance(cue)
	return cue.max_distance or mod.settings.max_distance()
end

local function cue_min_distance(cue)
	return cue.min_distance or MIN_DISTANCE
end

local function unit_alive(unit)
	if not unit or not Unit.alive(unit) then
		return false
	end

	local ok, health_extension = pcall(ScriptUnit.has_extension, unit, "health_system")
	if ok and health_extension and health_extension.is_alive and not health_extension:is_alive() then
		return false
	end

	return true
end

local function resolve_audio(cue, audio_override, cache_key)
	local audio = audio_override or cue.audio
	if audio.kind == "file" then
		return audio.path
	end

	local key = cache_key or cue.key
	local list = glob_cache[key]
	if not list then
		local ok, result = pcall(mod.simple_audio.glob, audio.pattern)
		if ok and result then
			list = result:list()
		else
			list = {}
		end
		glob_cache[key] = list
	end

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

local function resolve_layered(cue, listener_distance)
	local blend = cue.layer_blend
	if not blend or not cue.far_audio or not listener_distance then
		return resolve_audio(cue)
	end

	local t = Curves.blend_weight(blend, listener_distance)

	if math_random() < t then
		return resolve_audio(cue, cue.far_audio, cue.key .. "|far")
	end
	return resolve_audio(cue)
end

local function pitch_filter(cue, distance)
	if not cue.pitch_cents or not distance then
		return cue.filters
	end

	local cents = Curves.piecewise(cue.pitch_cents, distance)
	return Curves.pitch_filter_string(Curves.pitch_rate(cents))
end

local function stop_constant(ramp)
	if ramp.constant_id then
		mod.simple_audio.stop_file(ramp.constant_id)
		ramp.constant_id = nil
	end
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
	mod.simple_audio.set_position(entry.play_id, entry.unit, DECAY, cue_min_distance(entry.cue), cue_max_distance(entry.cue))
end

local overlap_seq = 0

function CuePlayer.play(cue, unit)
	if not unit_alive(unit) then return end

	local key
	if cue.overlap then
		overlap_seq = overlap_seq + 1
		key = cue.key .. "|" .. tostring(unit) .. "|" .. overlap_seq
	else
		key = cue.key .. "|" .. tostring(unit)
		if active[key] then return end
	end

	local path = resolve_audio(cue)
	if not path then return end

	local settings = {
		audio_type = "sfx",
		volume = cue_volume(cue),
		loop = cue.mode == "loop" or nil,
		filters = cue.filters,
	}

	local entry = { unit = unit, cue = cue, elapsed = 0, throttle = 0 }

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

	local play_id = mod.simple_audio.play_file(
		path, settings, unit, DECAY, cue_min_distance(cue), cue_max_distance(cue)
	)
	if not play_id then return end

	entry.play_id = play_id
	active[key] = entry
	apply_position(entry)

	if mod.settings.debug() then
		local player_pos = local_player_position()
		Debug.played(cue, path, player_pos and Vector3.distance(unit_position(unit), player_pos) or nil)
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
	}
	Debug.ramp(cue, "started")
end

function CuePlayer.stop_unit(cue, unit)
	if not unit then return end
	local key = cue.key .. "|" .. tostring(unit)

	if cue.overlap then
		for k, entry in pairs(active) do
			if entry.cue == cue and entry.unit == unit then
				mod.simple_audio.stop_file(entry.play_id)
				active[k] = nil
				Debug.stopped(cue, "stop event")
			end
		end
	else
		local entry = active[key]
		if entry then
			mod.simple_audio.stop_file(entry.play_id)
			active[key] = nil
			Debug.stopped(cue, "stop event")
		end
	end

	local ramp = ramps[key]
	if ramp then
		stop_constant(ramp)
		ramps[key] = nil
		Debug.ramp(cue, "ended")
	end
end

function CuePlayer.stop_cue(cue_key)
	for key, entry in pairs(active) do
		if entry.cue.key == cue_key then
			mod.simple_audio.stop_file(entry.play_id)
			active[key] = nil
		end
	end
	for key, ramp in pairs(ramps) do
		if ramp.cue.key == cue_key then
			stop_constant(ramp)
			ramps[key] = nil
		end
	end
end

function CuePlayer.update(dt)
	local enabled = mod.settings.enabled()

	for key, entry in pairs(active) do
		entry.elapsed = entry.elapsed + dt
		local cue = entry.cue
		local expired = cue.max_duration and entry.elapsed >= cue.max_duration
		local turned_off = not enabled or not mod.settings.cue_enabled(cue.setting_id)
		if (not unit_alive(entry.unit)) or expired or turned_off then
			mod.simple_audio.stop_file(entry.play_id)
			active[key] = nil
			Debug.stopped(cue, expired and "max_duration" or (turned_off and "disabled" or "unit dead"))
		end
	end

	local player_pos, player_pos_done = nil, false
	for key, ramp in pairs(ramps) do
		local unit = ramp.unit
		local cue = ramp.cue

		if not unit_alive(unit) then
			stop_constant(ramp)
			ramps[key] = nil
			Debug.ramp(cue, "ended")
		elseif not enabled or not mod.settings.cue_enabled(cue.setting_id) then
			stop_constant(ramp)
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
								audio_type = "sfx",
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
						local path = resolve_layered(cue, listener_distance)
						if path then
							mod.simple_audio.play_file(
								path,
								{
									audio_type = "sfx",
									volume = cue_volume(cue),
									filters = pitch_filter(cue, listener_distance),
								},
								unit, DECAY, cue_min_distance(cue), cue_max_distance(cue)
							)
						end
					end
				end
			end
		end
	end
end

return CuePlayer
