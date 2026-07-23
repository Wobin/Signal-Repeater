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
fake_values["audible_range"] = 50   -- 50% of each cue's game range
fake_values["poxburster_beep_enabled"] = true
fake_values["poxburster_beep_suppress"] = true
Settings.refresh()

assert(Settings.enabled() == true, "master enabled")
assert(Settings.volume() == 150, "volume cached")
assert(Settings.range_scale() == 0.5, "range scale cached (50% -> 0.5x)")
assert(Settings.cue_enabled("poxburster_beep") == true, "cue enabled")
assert(Settings.suppress("poxburster_beep") == true, "cue suppress")

-- default fallbacks when unset
fake_values = {}
Settings.refresh()
assert(Settings.enabled() == true, "master defaults on")
assert(Settings.volume() == 100, "volume default 100")
assert(Settings.range_scale() == 1, "range scale defaults to 1x (the game's own range)")
assert(Settings.suppress("poxburster_beep") == false, "suppress defaults off (supplement)")

-- The Psykhanium gate defaults ON, so the mod stays silent in the training modes. It is keyed on the
-- game mode name, and must never fire in a real mission.
fake_mod.is_enabled = function() return true end
_G.Managers = { state = {} }
Settings.refresh()
assert(Settings.active() == true, "no game mode yet -> active")

local function set_mode(name)
	_G.Managers.state.game_mode = { game_mode_name = function() return name end }
end

set_mode("coop_complete_objective")
assert(Settings.active() == true, "a real mission must stay active")
set_mode("shooting_range")
assert(Settings.active() == false, "Psykhanium (shooting_range) is gated off by default")
set_mode("training_grounds")
assert(Settings.active() == false, "training grounds is gated off by default")

fake_values["disable_in_psykhanium"] = false
Settings.refresh()
set_mode("shooting_range")
assert(Settings.active() == true, "gate off -> the mod runs in the Psykhanium")

-- The Psykhanium gate silences CUES only. The sound test is a deliberate calibration tool and the
-- Psykhanium is where you would use it, so mod_on() must stay true there for it to keep orbiting.
fake_values["disable_in_psykhanium"] = true
Settings.refresh()
set_mode("shooting_range")
assert(Settings.active() == false, "cues are gated in the Psykhanium")
assert(Settings.mod_on() == true, "the mod itself is still on, so the sound test keeps running")
fake_values["enabled"] = false
Settings.refresh()
assert(Settings.mod_on() == false, "master off -> nothing runs, sound test included")
fake_values["enabled"] = nil

_G.Managers = nil
print("test_settings OK")
