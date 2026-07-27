local mod = get_mod("Signal Repeater")
local CuePlayer = mod.cue_player
local CueCatalog = mod.catalog
local Debug = mod.cue_debug
local SourceRegistry = mod.source_registry
local HookRegistry = mod.hook_registry
local Units = mod.units
local Settings = mod.settings

local Unit = Unit
local ipairs = ipairs
local pcall = pcall

local CueHooks = {}

local template_cues = {}
local inventory_cues = {}
local spawn_cues = {}
local rpc_wwise_cues = {}

local function index_catalog()
	for _, cue in ipairs(CueCatalog) do
		local hook = cue.hook
		if hook.kind == "rpc_wwise" then
			HookRegistry.claim(rpc_wwise_cues, hook.event, cue, "rpc_wwise event")
		elseif hook.kind == "breed_spawn" then
			HookRegistry.claim(spawn_cues, hook.breed, cue, "breed_spawn breed")
		elseif hook.kind == "inventory" then
			for _, ev in ipairs(hook.events) do
				HookRegistry.claim(inventory_cues, ev, cue, "inventory event")
			end
		elseif hook.kind == "effect_template" then
			if hook.template then
				HookRegistry.claim(template_cues, hook.template, cue, "effect template")
			end
			if hook.templates then
				for _, name in ipairs(hook.templates) do
					HookRegistry.claim(template_cues, name, cue, "effect template")
				end
			end
		end
	end
end

local suppressed_starts = {}

local function unit_from(source)
	local ok, alive = pcall(Unit.alive, source)
	if ok and alive then
		return source
	end
	return SourceRegistry.get(source)
end

local function fire(cue, unit)
	if not Settings.active() then return end
	if not Settings.cue_enabled(cue.setting_id) then return end
	if not Units.breed_matches(cue.hook.breeds, unit) then return end
	CuePlayer.play(cue, unit)
end

local rpc_event_ids
local function rpc_id_map()
	if rpc_event_ids then return rpc_event_ids end
	local lookup = rawget(_G, "NetworkLookup")
	if not lookup or not lookup.sound_events then return nil end
	local map = {}
	for event_name, cue in pairs(rpc_wwise_cues) do
		local id = lookup.sound_events[event_name]
		if id then map[id] = cue end
	end
	rpc_event_ids = map
	return map
end

local function on_rpc_wwise(cue, position)
	if not Settings.active() then return false end
	if not Settings.cue_enabled(cue.setting_id) then return false end
	local played = CuePlayer.play_at(cue, position)
	return played and Settings.suppress(cue.setting_id)
end

local function sound_event_patterns(hook)
	local patterns = {}
	if hook.pattern then
		patterns[#patterns + 1] = hook.pattern
	end
	if hook.event then
		patterns[#patterns + 1] = "^" .. hook.event .. "$"
	end
	for _, ev in ipairs(hook.events or {}) do
		patterns[#patterns + 1] = "^" .. ev .. "$"
	end
	return patterns
end

local function install_utility_hooks()
	local by_path = {}

	for _, cue in ipairs(CueCatalog) do
		if cue.hook.kind == "utility" then
			local path = cue.hook.path
			by_path[path] = by_path[path] or {}
			for _, which in ipairs({ "start", "stop" }) do
				local spec = cue.hook[which]
				if spec then
					local slot = by_path[path][spec.func]
					if not slot then
						slot = { unit_arg = spec.unit_arg, starts = {}, stops = {} }
						by_path[path][spec.func] = slot
					end
					local list = which == "start" and slot.starts or slot.stops
					list[#list + 1] = cue
				end
			end
		end
	end

	for path, funcs in pairs(by_path) do
		mod:hook_require(path, function(module)
			for func, slot in pairs(funcs) do
				if not slot.installed and module[func] then
					slot.installed = true
					mod:hook_safe(module, func, function(...)
						local unit = select(slot.unit_arg, ...)
						if not unit then return end

						for _, cue in ipairs(slot.starts) do
							if Units.breed_matches(cue.hook.breeds, unit) then
								fire(cue, unit)
							end
						end
						for _, cue in ipairs(slot.stops) do
							if Units.breed_matches(cue.hook.breeds, unit) then
								CuePlayer.stop_unit(cue, unit)
							end
						end
					end)
				end
			end
		end)
	end
end

function CueHooks.install()
	index_catalog()
	install_utility_hooks()

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

	mod:hook_require("scripts/extension_systems/fx/fx_system", function(fx_system_class)
		mod:hook(fx_system_class, "rpc_trigger_wwise_event", function(func, self, channel_id, event_id, optional_position, ...)
			local ids = rpc_id_map()
			local cue = ids and ids[event_id]
			if cue and optional_position then
				local ok, suppress = pcall(on_rpc_wwise, cue, optional_position)
				if ok and suppress then
					return
				end
			end
			return func(self, channel_id, event_id, optional_position, ...)
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
			CuePlayer.start_ramp(cue, unit)
		end)
	end)

	for _, cue in ipairs(CueCatalog) do
		if cue.hook.kind == "sound_event" then
			for _, pattern in ipairs(sound_event_patterns(cue.hook)) do
				HookRegistry.add(pattern, function(event_name, source)
					if not Settings.active() then return end
					if not Settings.cue_enabled(cue.setting_id) then return end

					local unit = unit_from(source)
					if not unit then return end
					if not Units.breed_matches(cue.hook.breeds, unit) then return end

					local played = CuePlayer.play(cue, unit)

					if played and Settings.suppress(cue.setting_id) then
						if cue.hook.stop_event then
							suppressed_starts[cue.key .. "|" .. tostring(unit)] = true
						end
						Debug.suppressed(cue, event_name)
						return true
					end
				end)
			end

			if cue.hook.stop_event then
				HookRegistry.add("^" .. cue.hook.stop_event .. "$", function(event_name, source)
					local unit = unit_from(source)
					if not unit then return end
					if not Units.breed_matches(cue.hook.breeds, unit) then return end

					CuePlayer.stop_unit(cue, unit)

					local start_key = cue.key .. "|" .. tostring(unit)
					local suppressed_start = suppressed_starts[start_key]
					suppressed_starts[start_key] = nil
					if suppressed_start then
						return true
					end
				end)
			end
		end
	end
end

CueHooks.unit_from = unit_from

return CueHooks
