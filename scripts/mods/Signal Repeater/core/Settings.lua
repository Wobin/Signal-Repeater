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
	cache.range_scale  = get_number("audible_range", 100) / 100
	cache.debug        = get_bool("debug", false)
	cache.sound_test   = get_bool("sound_test", false)
	cache.isolate      = get_bool("isolate_cues", false)
	cache.per_cue      = {}
	cache.group_volume = {}
	cache.group_teammate = {}
	cache.group_pack = {}
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
function Settings.range_scale()   return cache.range_scale end
function Settings.debug()         return cache.debug end
function Settings.sound_test()    return cache.sound_test end
function Settings.isolate()      return cache.isolate end

function Settings.group_volume(cue_setting_id)
	local group = mod.cue_group and mod.cue_group[cue_setting_id]
	if not group then return 1 end
	local key = group .. "_volume"
	local v = cache.group_volume[key]
	if v == nil then
		v = get_number(key, 100) / 100
		cache.group_volume[key] = v
	end
	return v
end

function Settings.pack_limit(cue_setting_id)
	local group = mod.cue_group and mod.cue_group[cue_setting_id]
	if not group then return nil end
	if not (mod.group_pack and mod.group_pack[group]) then return nil end
	local key = group .. "_pack_limit"
	local v = cache.group_pack[key]
	if v == nil then
		v = get_number(key, 4)
		cache.group_pack[key] = v
	end
	return v
end

function Settings.teammate_skip(cue_setting_id)
	local group = mod.cue_group and mod.cue_group[cue_setting_id]
	if not group then return false end
	local key = group .. "_teammate_skip"
	local v = cache.group_teammate[key]
	if v == nil then
		local default = mod.group_teammate_default and mod.group_teammate_default[group]
		v = get_bool(key, default ~= false)
		cache.group_teammate[key] = v
	end
	return v
end

function Settings.audio_type()
	if cache.isolate then return nil end
	return "sfx"
end
function Settings.cue_enabled(id) return per_cue(id).enabled end
function Settings.suppress(id)    return per_cue(id).suppress end

Settings.refresh()

return Settings
