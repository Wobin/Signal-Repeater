--[[
	Name: Signal Repeater
	Author: Wobin
	Date: 11/07/2026
	Version: 1.0.0
	Repository: https://github.com/Wobin/Signal-Repeater
]]--

local mod = get_mod("Signal Repeater")
local CueCatalog = mod.catalog
local Debug = mod.cue_debug

local ipairs = ipairs
local pairs = pairs

local Suppression = {}

local suppress_cue = {}

function Suppression.install()
	for _, cue in ipairs(CueCatalog) do
		if cue.suppress_events and cue.hook.kind ~= "sound_event" then
			for _, ev in ipairs(cue.suppress_events) do
				suppress_cue[ev] = cue
			end
		end
	end

	for ev, cue in pairs(suppress_cue) do
		mod.simple_audio.hook_sound("^" .. ev .. "$", function()
			if not mod.settings.enabled() then return end
			if not mod.settings.cue_enabled(cue.setting_id) then return end
			if mod.settings.suppress(cue.setting_id) then
				Debug.suppressed(cue, ev)
				return false
			end
		end)
	end
end

return Suppression
