local mod = get_mod("Signal Repeater")

local pcall = pcall

local Settings = {}

local cache = {}

local function get_bool(id, default)
	local v = mod:get(id)
	if v == nil then return default end
	return v and true or false
end

local function get_number(id, default)
	local v = mod:get(id)
	if type(v) ~= "number" then return default end
	return v
end

function Settings.refresh()
	cache.enabled      = get_bool("enabled", true)
	cache.volume       = get_number("volume", 100)
	cache.max_distance = get_number("audible_range", 150)
	cache.debug        = get_bool("debug", false)
	cache.sound_test   = get_bool("sound_test", false)
	cache.isolate      = get_bool("isolate_cues", false)
	cache.per_cue      = {}
end

local function per_cue(setting_id)
	local c = cache.per_cue[setting_id]
	if not c then
		c = {
			enabled  = get_bool(setting_id .. "_enabled", true),
			suppress = get_bool(setting_id .. "_suppress", false),
		}
		cache.per_cue[setting_id] = c
	end
	return c
end

function Settings.enabled()       return cache.enabled end

function Settings.active()
	if not cache.enabled then return false end
	local ok, on = pcall(function() return mod:is_enabled() end)
	if ok and on == false then return false end
	return true
end

function Settings.volume()        return cache.volume end
function Settings.max_distance()  return cache.max_distance end
function Settings.debug()         return cache.debug end
function Settings.sound_test()    return cache.sound_test end
function Settings.isolate()      return cache.isolate end

function Settings.audio_type()
	if cache.isolate then return nil end
	return "sfx"
end
function Settings.cue_enabled(id) return per_cue(id).enabled end
function Settings.suppress(id)    return per_cue(id).suppress end

Settings.refresh()

return Settings
