--[[
	Name: Signal Repeater
	Author: Wobin
	Date: 10/07/2026
	Version: 1.0.0
	Repository: https://github.com/Wobin/Signal-Repeater
]]--

local mod = get_mod("Signal Repeater")

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
	cache.max_distance = get_number("max_distance", 35)
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
function Settings.volume()        return cache.volume end
function Settings.max_distance()  return cache.max_distance end
function Settings.cue_enabled(id) return per_cue(id).enabled end
function Settings.suppress(id)    return per_cue(id).suppress end

Settings.refresh()

return Settings
