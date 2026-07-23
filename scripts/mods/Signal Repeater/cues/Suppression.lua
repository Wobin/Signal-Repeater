local mod = get_mod("Signal Repeater")
local CueCatalog = mod.catalog
local Debug = mod.cue_debug
local HookRegistry = mod.hook_registry
local Settings = mod.settings

local ipairs = ipairs

local Suppression = {}

local OWNED_ELSEWHERE = {
	sound_event = true,
	vo_event = true,
}

function Suppression.install()
	for _, cue in ipairs(CueCatalog) do
		if cue.suppress_events and not OWNED_ELSEWHERE[cue.hook.kind] then
			for _, ev in ipairs(cue.suppress_events) do
				HookRegistry.add("^" .. ev .. "$", function(event_name, source)
					if not Settings.active() then return end
					if not Settings.cue_enabled(cue.setting_id) then return end

					local unit = mod.cue_hooks.unit_from(source)
					if unit and mod.cue_player.silenced_by_targeting(cue, unit) then return end

					if Settings.suppress(cue.setting_id) then
						Debug.suppressed(cue, event_name)
						return true
					end
				end)
			end
		end
	end
end

return Suppression
