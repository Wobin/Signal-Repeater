--[[
	Name: Signal Repeater
	Author: Wobin
	Date: 10/07/2026
	Version: 1.0.0
	Repository: https://github.com/Wobin/Signal-Repeater
]]--

local mod = get_mod("Signal Repeater")

local Unit = Unit

local CuePlayer = {}

-- active[key] = { play_id, unit, cue, elapsed }
local active = {}

local FOLLOW_THROTTLE = 0.1

local function unit_alive(unit)
	return unit and Unit.alive(unit)
end

-- Re-point the active playback at the (moving) emitting unit. Standard SimpleAudio
-- spatialization: pass the unit and let SimpleAudio derive distance falloff and pan.
local function apply_position(entry)
	if not unit_alive(entry.unit) then return end
	mod.simple_audio.set_position(entry.play_id, entry.unit, nil, nil, mod.settings.max_distance())
end

function CuePlayer.play(cue, unit)
	if not unit_alive(unit) then return end
	local key = cue.key .. "|" .. tostring(unit)
	if active[key] then return end -- dedup

	local settings = {
		audio_type = "sfx",
		volume = mod.settings.volume(),
		loop = cue.loop or nil,
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
		cue.file, settings, unit, nil, nil, mod.settings.max_distance()
	)
	if not play_id then return end

	entry.play_id = play_id
	active[key] = entry
	apply_position(entry)
end

function CuePlayer.stop_cue(cue_key)
	for key, entry in pairs(active) do
		if entry.cue.key == cue_key then
			mod.simple_audio.stop_file(entry.play_id)
			active[key] = nil
		end
	end
end

function CuePlayer.update(dt)
	for key, entry in pairs(active) do
		entry.elapsed = entry.elapsed + dt
		local expired = entry.cue.max_duration and entry.elapsed >= entry.cue.max_duration
		if (not unit_alive(entry.unit)) or expired then
			mod.simple_audio.stop_file(entry.play_id)
			active[key] = nil
		end
	end
end

return CuePlayer
