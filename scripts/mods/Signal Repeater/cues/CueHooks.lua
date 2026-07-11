--[[
	Name: Signal Repeater
	Author: Wobin
	Date: 11/07/2026
	Version: 1.0.0
	Repository: https://github.com/Wobin/Signal-Repeater
]]--

local mod = get_mod("Signal Repeater")
local CuePlayer = mod.cue_player
local CueCatalog = mod.catalog
local Debug = mod.cue_debug
local SourceRegistry = mod.source_registry

local ipairs = ipairs

local CueHooks = {}

local template_cues = {}
local inventory_cues = {}
local spawn_cues = {}

local function index_catalog()
	for _, cue in ipairs(CueCatalog) do
		local hook = cue.hook
		if hook.kind == "breed_spawn" then
			spawn_cues[hook.breed] = cue
		elseif hook.kind == "inventory" then
			for _, ev in ipairs(hook.events) do
				inventory_cues[ev] = cue
			end
		elseif hook.kind == "effect_template" then
			if hook.template then
				template_cues[hook.template] = cue
			end
			if hook.templates then
				for _, name in ipairs(hook.templates) do
					template_cues[name] = cue
				end
			end
		end
	end
end

local function fire(cue, unit)
	if not mod.settings.enabled() then return end
	if not mod.settings.cue_enabled(cue.setting_id) then return end
	CuePlayer.play(cue, unit)
end

function CueHooks.install()
	index_catalog()

	mod:hook_require("scripts/extension_systems/fx/utilities/effect_templates_handler", function(handler_class)
		mod:hook_safe(handler_class, "start_template_effect", function(self, unit_to_particle_group_lookup, template_context, template_effect, template, optional_unit, ...)
			if not template or not optional_unit then return end
			local cue = template_cues[template.name]
			if not cue then return end
			fire(cue, optional_unit)
		end)

		mod:hook(handler_class, "stop_template_effect", function(func, self, template_context, template_effect, template)
			if template and template_effect then
				local cue = template_cues[template.name]
				if cue then
					CuePlayer.stop_unit(cue, template_effect.optional_unit)
				end
			end
			return func(self, template_context, template_effect, template)
		end)
	end)

	mod:hook_require("scripts/extension_systems/fx/minion_fx_extension", function(fx_class)
		mod:hook_safe(fx_class, "_trigger_inventory_wwise_event", function(self, event_name, ...)
			local cue = inventory_cues[event_name]
			if cue then
				fire(cue, self._unit)
			end
		end)

		mod:hook_safe(fx_class, "init", function(self, extension_init_context, unit, extension_init_data)
			local breed = extension_init_data and extension_init_data.breed
			local cue = breed and breed.name and spawn_cues[breed.name]
			if not cue then return end
			if not mod.settings.enabled() then return end
			if not mod.settings.cue_enabled(cue.setting_id) then return end
			CuePlayer.start_ramp(cue, unit)
		end)
	end)

	for _, cue in ipairs(CueCatalog) do
		if cue.hook.kind == "breed_spawn" and cue.hook.stops then
			for _, stop in ipairs(cue.hook.stops) do
				mod:hook_require(stop.path, function(action_class)
					mod:hook_safe(action_class, stop.func, function(self, unit)
						CuePlayer.stop_unit(cue, unit)
					end)
				end)
			end
		end
	end

	for _, cue in ipairs(CueCatalog) do
		if cue.hook.kind == "sound_event" then
			local pattern = cue.hook.pattern or ("^" .. cue.hook.event .. "$")
			mod.simple_audio.hook_sound(pattern, function(sound_type, event_name, delta, source)
				if not mod.settings.enabled() then return end
				if not mod.settings.cue_enabled(cue.setting_id) then return end

				local unit = SourceRegistry.get(source)
				if unit then
					CuePlayer.play(cue, unit)
				end

				if mod.settings.suppress(cue.setting_id) then
					Debug.suppressed(cue, event_name)
					return false
				end
			end)

			if cue.hook.stop_event then
				mod.simple_audio.hook_sound("^" .. cue.hook.stop_event .. "$", function(sound_type, event_name, delta, source)
					local unit = SourceRegistry.get(source)
					if unit then
						CuePlayer.stop_unit(cue, unit)
					end
					if mod.settings.enabled() and mod.settings.cue_enabled(cue.setting_id) and mod.settings.suppress(cue.setting_id) then
						return false
					end
				end)
			end
		end
	end

end

return CueHooks
