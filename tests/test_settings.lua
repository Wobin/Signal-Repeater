-- standalone luajit test: fake the DMF mod object, load Settings, assert caching.
local fake_values = {}
local fake_mod = {
	get = function(_, id) return fake_values[id] end,
	localize = function(_, k) return k end,
}
_G.get_mod = function() return fake_mod end

local Settings = dofile("mods/Signal Repeater/scripts/mods/Signal Repeater/core/Settings.lua")

fake_values["enabled"] = true
fake_values["volume"] = 150
fake_values["audible_range"] = 40
fake_values["poxburster_beep_enabled"] = true
fake_values["poxburster_beep_suppress"] = true
Settings.refresh()

assert(Settings.enabled() == true, "master enabled")
assert(Settings.volume() == 150, "volume cached")
assert(Settings.max_distance() == 40, "max distance cached")
assert(Settings.cue_enabled("poxburster_beep") == true, "cue enabled")
assert(Settings.suppress("poxburster_beep") == true, "cue suppress")

-- default fallbacks when unset
fake_values = {}
Settings.refresh()
assert(Settings.enabled() == true, "master defaults on")
assert(Settings.volume() == 100, "volume default 100")
assert(Settings.max_distance() == 150, "audible range default 150")
assert(Settings.suppress("poxburster_beep") == false, "suppress defaults off (supplement)")
print("test_settings OK")
