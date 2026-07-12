local mod = get_mod("Signal Repeater")

local Unit = Unit
local Managers = Managers
local Vector3 = Vector3
local math_cos = math.cos
local math_sin = math.sin
local math_pi = math.pi
local math_random = math.random
local pcall = pcall

local SoundTest = {}

local ORBIT_RADIUS = 6
local ORBIT_PERIOD = 8
local ORBIT_HEIGHT = 1.2    -- roughly ear height above the player's feet
local MOVE_THROTTLE = 0.05

local TEST_PATTERN = "mods/Signal Repeater/audio/cues/hound_approach/*.ogg"
local TEST_MAX_DISTANCE = 35

local active = false
local play_id = nil
local angle = 0
local throttle = 0

local function listener_unit()
	local pm = Managers.player
	if not pm then return nil end
	local player = pm:local_player_safe(1)
	if not player then return nil end
	local unit = player.player_unit
	if unit and Unit.alive(unit) then return unit end
	return nil
end

local function orbit_position(unit)
	local base = Unit.world_position(unit, 1)
	return base + Vector3(math_cos(angle) * ORBIT_RADIUS, math_sin(angle) * ORBIT_RADIUS, ORBIT_HEIGHT)
end

local function stop_playback()
	if play_id then
		mod.simple_audio.stop_file(play_id)
		play_id = nil
	end
end

local function start_playback()
	stop_playback()

	local unit = listener_unit()
	if not unit then return end

	local ok, glob = pcall(mod.simple_audio.glob, TEST_PATTERN)
	if not ok or not glob then return end
	local list = glob:list()
	if #list == 0 then return end
	local path = list[math_random(#list)]

	play_id = mod.simple_audio.play_file(
		path,
		{ audio_type = mod.settings.audio_type(), volume = mod.settings.volume(), loop = true },
		orbit_position(unit), mod.cue_player.DECAY, mod.cue_player.MIN_DISTANCE, TEST_MAX_DISTANCE
	)
	if not play_id then return end
end

function SoundTest.start()
	active = true
	angle = 0
	throttle = 0
	start_playback()
	mod:echo("[SR] sound test ON: hound bark orbiting you. Adjust volume, then turn it off.")
end

function SoundTest.stop()
	active = false
	stop_playback()
	mod:echo("[SR] sound test OFF.")
end

function SoundTest.is_active()
	return active
end

function SoundTest.apply()
	local want = mod.settings.sound_test()
	if want and not active then
		SoundTest.start()
	elseif not want and active then
		SoundTest.stop()
	elseif want and active then
		start_playback()
	end
end

function SoundTest.update(dt)
	if not active then return end

	local unit = listener_unit()
	if not unit then
		stop_playback()
		return
	end

	if not play_id or not mod.simple_audio.is_file_playing(play_id) then
		start_playback()
		if not play_id then return end
	end

	angle = angle + dt * (2 * math_pi / ORBIT_PERIOD)

	throttle = throttle + dt
	if throttle >= MOVE_THROTTLE then
		throttle = 0
		mod.simple_audio.set_position(play_id, orbit_position(unit), mod.cue_player.DECAY, mod.cue_player.MIN_DISTANCE, TEST_MAX_DISTANCE)
	end
end

return SoundTest
