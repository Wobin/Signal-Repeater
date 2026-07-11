--[[
	Name: Signal Repeater
	Author: Wobin
	Date: 10/07/2026
	Version: 1.0.0
	Repository: https://github.com/Wobin/Signal-Repeater
]]--

local mod = get_mod("Signal Repeater")
mod.version = "1.0.0"

mod.settings = mod:io_dofile("Signal Repeater/scripts/mods/Signal Repeater/core/Settings")
mod.cue_debug = mod:io_dofile("Signal Repeater/scripts/mods/Signal Repeater/core/Debug")
mod.curves = mod:io_dofile("Signal Repeater/scripts/mods/Signal Repeater/core/Curves")
mod.catalog = mod:io_dofile("Signal Repeater/scripts/mods/Signal Repeater/cues/CueCatalog")
mod.cue_player = mod:io_dofile("Signal Repeater/scripts/mods/Signal Repeater/playback/CuePlayer")
mod.sound_test = mod:io_dofile("Signal Repeater/scripts/mods/Signal Repeater/playback/SoundTest")
mod.source_registry = mod:io_dofile("Signal Repeater/scripts/mods/Signal Repeater/playback/SourceRegistry")

mod.update = function(dt)
	mod.cue_player.update(dt)
	mod.sound_test.update(dt)
	mod.source_registry.update(dt)
end

mod.on_all_mods_loaded = function()
	mod.simple_audio = get_mod("SimpleAudio")
	if not mod.simple_audio then
		mod:error("SimpleAudio is required but was not found. Signal Repeater will not run.")
		return
	end
	mod:info(mod.version)
	mod.settings.refresh()

	mod.source_registry.install()

	mod.cue_hooks = mod:io_dofile("Signal Repeater/scripts/mods/Signal Repeater/cues/CueHooks")
	mod.cue_hooks.install()

	mod.suppression = mod:io_dofile("Signal Repeater/scripts/mods/Signal Repeater/cues/Suppression")
	mod.suppression.install()

	mod:set("sound_test", false)
	mod.settings.refresh()

	mod:command("sr_test", mod:localize("sr_test"), function()
		mod:set("sound_test", not mod.sound_test.is_active(), true)
	end)

end

local function set_every_cue(suffix, value)
	for _, cue in ipairs(mod.catalog) do
		mod:set(cue.setting_id .. suffix, value)
	end
end

mod.on_setting_changed = function(setting_id)
	if setting_id == "repeat_all" then
		set_every_cue("_enabled", mod:get("repeat_all"))
	elseif setting_id == "mute_all" then
		set_every_cue("_suppress", mod:get("mute_all"))
	end

	mod.settings.refresh()
	mod.sound_test.apply()
end
