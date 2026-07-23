--[[
	Name: Signal Repeater
	Author: Wobin
	Date: 23/07/2026
	Version: 2.4.1
	Repository: https://github.com/Wobin/Signal-Repeater
]]--

local mod = get_mod("Signal Repeater")
mod.version = "2.4.1"

local ROOT = "Signal Repeater/scripts/mods/Signal Repeater/"

mod.settings = mod:io_dofile(ROOT .. "core/Settings")
mod.cue_debug = mod:io_dofile(ROOT .. "core/Debug")
mod.curves = mod:io_dofile(ROOT .. "core/Curves")
mod.units = mod:io_dofile(ROOT .. "core/Units")
mod.occlusion = mod:io_dofile(ROOT .. "core/Occlusion")
mod.footstep_surfaces = mod:io_dofile(ROOT .. "cues/FootstepSurfaces")
mod.catalog = mod:io_dofile(ROOT .. "cues/CueCatalog")
mod.cue_player = mod:io_dofile(ROOT .. "playback/CuePlayer")
mod.sound_test = mod:io_dofile(ROOT .. "playback/SoundTest")
mod.source_registry = mod:io_dofile(ROOT .. "playback/SourceRegistry")

local was_active = false

local function stop_cues()
	mod.cue_player.stop_all()
end

local function teardown()
	stop_cues()
	if mod.sound_test.is_active() then
		mod.sound_test.stop()
	end
end

mod.update = function(dt)
	local active = mod.settings.active()

	if not active then
		if was_active then
			was_active = false
			stop_cues()
		end
		if mod.settings.mod_on() then
			mod.sound_test.update(dt)
		end
		return
	end

	was_active = true

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

	mod.hook_registry = mod:io_dofile(ROOT .. "cues/HookRegistry")

	mod.source_registry.install()

	mod.cue_hooks = mod:io_dofile(ROOT .. "cues/CueHooks")
	mod.cue_hooks.install()

	mod.suppression = mod:io_dofile(ROOT .. "cues/Suppression")
	mod.suppression.install()

	mod.vo_cues = mod:io_dofile(ROOT .. "cues/VoCues")
	mod.vo_cues.install()

	mod:set("sound_test", false)
	mod.settings.refresh()

	mod:command("sr_test", mod:localize("sr_test"), function()
		mod:set("sound_test", not mod.sound_test.is_active(), true)
	end)
end

mod.on_disabled = function()
	teardown()
end

mod.on_unload = function()
	teardown()
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
