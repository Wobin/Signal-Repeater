--[[
	Name: Signal Repeater
	Author: Wobin
	Date: 12/07/2026
	Version: 1.0.0
	Repository: https://github.com/Wobin/Signal-Repeater
]]--

local mod = get_mod("Signal Repeater")
local CuePlayer = mod.cue_player
local CueCatalog = mod.catalog
local Debug = mod.cue_debug

local Managers = Managers
local ipairs = ipairs
local pcall = pcall

local VoCues = {}

local vo_cues = {}

local function match_cue(sound_event)
	for _, cue in ipairs(vo_cues) do
		if sound_event:find(cue.hook.loc_prefix, 1, true) == 1 then
			return cue
		end
	end
end

function VoCues.install()
	for _, cue in ipairs(CueCatalog) do
		if cue.hook.kind == "vo_event" then
			vo_cues[#vo_cues + 1] = cue
		end
	end

	if #vo_cues == 0 then return end

	mod:hook_safe("DialogueSystem", "_play_dialogue_event_implementation", function(self, go_id, is_level_unit, level_name_hash, dialogue_id, dialogue_index)
		if not mod.settings.active() then return end

		pcall(function()
			local unit = Managers.state.unit_spawner:unit(go_id, is_level_unit, level_name_hash)
			local extension = self._unit_to_extension_map[unit]
			if not extension or extension:is_a_player() then return end

			local dialogue_name = NetworkLookup.dialogue_names[dialogue_id]
			local sound_event = extension:get_dialogue_event(dialogue_name, dialogue_index)
			if not sound_event then return end

			local cue = match_cue(sound_event)
			Debug.bark(sound_event, cue)

			if not cue then return end
			if not mod.settings.cue_enabled(cue.setting_id) then return end

			CuePlayer.play(cue, unit, cue.audio.dir .. "/" .. sound_event .. ".ogg")
		end)
	end)

	for _, cue in ipairs(vo_cues) do
		mod.hook_registry.add("^" .. cue.hook.loc_prefix, function()
			if not mod.settings.active() then return end
			if not mod.settings.cue_enabled(cue.setting_id) then return end
			if mod.settings.suppress(cue.setting_id) then
				return true
			end
		end)
	end
end

return VoCues
