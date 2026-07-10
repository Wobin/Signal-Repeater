--[[
	Name: Signal Repeater
	Author: Wobin
	Date: 10/07/2026
	Version: 1.0.0
	Repository: https://github.com/Wobin/Signal-Repeater
]]--

local mod = get_mod("Signal Repeater")
mod.version = "1.0.0"

mod.settings = mod:io_dofile("Signal Repeater/scripts/mods/Signal Repeater/Settings")

mod.cue_player = mod:io_dofile("Signal Repeater/scripts/mods/Signal Repeater/CuePlayer")

mod.update = function(dt)
	mod.cue_player.update(dt)
end

mod.on_all_mods_loaded = function()
	mod.simple_audio = get_mod("SimpleAudio")
	if not mod.simple_audio then
		mod:error("SimpleAudio is required but was not found. Signal Repeater will not run.")
		return
	end
	mod:info(mod.version)
	mod.settings.refresh()
end

mod.on_setting_changed = function()
	mod.settings.refresh()
end
