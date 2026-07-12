-- standalone luajit test: catalog integrity. Catches the class of bug that is INVISIBLE at
-- runtime -- a cue that silently never fires, or plays nothing -- without needing the game.
local fake_mod = { localize = function(_, k) return k end }
_G.get_mod = function() return fake_mod end

local ROOT = "mods/Signal Repeater/scripts/mods/Signal Repeater/"
local Catalog = dofile(ROOT .. "cues/CueCatalog.lua")
local Surfaces = dofile(ROOT .. "cues/FootstepSurfaces.lua")
local Data = dofile(ROOT .. "Signal Repeater_data.lua")
local Loc = dofile(ROOT .. "Signal Repeater_localization.lua")

local KINDS = {
	effect_template = true, sound_event = true, inventory = true, breed_spawn = true,
	vo_event = true, utility = true,
}

local function exists(path)
	local f = io.open(path, "rb")
	if f then f:close() return true end
	return false
end

-- List the .ogg files in the folder of a "mods/..." pattern (cmd.exe, so `dir /b`).
local function glob_names(dir)
	local win = dir:gsub("/", "\\")
	local names = {}
	local p = io.popen('dir /b "' .. win .. '" 2>nul')
	if not p then return names end
	for line in p:lines() do
		if line:match("%.ogg$") then names[#names + 1] = line end
	end
	p:close()
	return names
end

local function glob_count(pattern)
	return #glob_names(pattern:match("^(.*)/[^/]*$"))
end

assert(#Catalog == 49, "expected 49 cues, got " .. #Catalog)

local seen_keys = {}
for _, cue in ipairs(Catalog) do
	local key = cue.key
	assert(key and key ~= "", "cue missing key")
	assert(not seen_keys[key], "duplicate cue key: " .. key)
	seen_keys[key] = true

	assert(cue.setting_id, key .. ": missing setting_id")
	assert(KINDS[cue.hook.kind], key .. ": unknown hook kind " .. tostring(cue.hook.kind))

	-- Every Wwise event string must be a FULL resource path. The trapper cue silently never
	-- fired for hours because it was keyed on the bare event name. VO cues are the exception:
	-- they key on a dialogue `loc_` line prefix, not a wwise event path.
	local is_vo = cue.hook.kind == "vo_event"
	local function check_event(ev, what)
		if is_vo then
			assert(ev:match("^loc_"), key .. ": " .. what .. " is not a loc_ key: " .. ev)
		else
			assert(ev:match("^%^?wwise/events/"), key .. ": " .. what .. " is not a full wwise path: " .. ev)
		end
	end
	if is_vo then
		assert(cue.hook.loc_prefix, key .. ": vo_event without a loc_prefix")
		check_event(cue.hook.loc_prefix, "hook.loc_prefix")
	end
	if cue.hook.event then check_event(cue.hook.event, "hook.event") end
	if cue.hook.stop_event then check_event(cue.hook.stop_event, "hook.stop_event") end
	if cue.hook.pattern then check_event(cue.hook.pattern, "hook.pattern") end
	if cue.hook.events then
		for _, ev in ipairs(cue.hook.events) do check_event(ev, "hook.events entry") end
	end
	for _, ev in ipairs(cue.suppress_events or {}) do check_event(ev, "suppress_events entry") end

	-- Audio must actually exist on disk, or the cue is a silent no-op.
	local function check_audio(audio, what)
		if audio.kind == "file" then
			assert(exists(audio.path), key .. ": " .. what .. " file missing: " .. audio.path)
		elseif audio.kind == "vo" then
			-- A VO cue plays the EXACT line the game chose, by filename. So the directory must
			-- hold files named for the loc keys, and every one must belong to this cue's prefix.
			local n = glob_count(audio.dir .. "/x")
			assert(n > 0, key .. ": vo dir holds no lines: " .. audio.dir)
			for _, name in ipairs(glob_names(audio.dir)) do
				assert(name:find(cue.hook.loc_prefix, 1, true) == 1,
					key .. ": vo dir holds a line from another cue: " .. name)
			end
		elseif audio.kind == "surface" then
			-- The game picks footstep audio through a Wwise switch on `surface_material`, per gait.
			-- We mirror that switch, so every material the bank gives audio for must resolve to a
			-- populated folder, or the enemy goes silent on that floor.
			local surfaces = Surfaces[audio.surfaces]
			assert(surfaces, key .. ": no surface table named " .. tostring(audio.surfaces))

			-- Every gait the cue can infer must be one the bank actually shipped audio for, and the
			-- thresholds must descend -- the resolver takes the first match, so an out-of-order
			-- entry would shadow every gait below it.
			local previous
			for _, entry in ipairs(audio.gaits) do
				local gait, min_speed = entry[1], entry[2]
				assert(surfaces[gait], key .. ": gait '" .. gait .. "' has no table in " .. audio.surfaces)
				assert(previous == nil or min_speed < previous,
					key .. ": gait thresholds are not in descending order at '" .. gait .. "'")
				previous = min_speed
			end
			assert(previous == 0, key .. ": slowest gait must have a threshold of 0, got " .. tostring(previous))
			for gait in pairs(surfaces) do
				if gait ~= "silent" then
					local reachable = false
					for _, entry in ipairs(audio.gaits) do
						if entry[1] == gait then reachable = true end
					end
					assert(reachable, key .. ": bank has gait '" .. gait .. "' the cue can never select")
				end
			end

			for gait, for_gait in pairs(surfaces) do
				if gait ~= "silent" then
					for material, set in pairs(for_gait) do
						assert(not surfaces.silent[material],
							key .. ": " .. material .. " is both mapped and silent")
						local dir = audio.base .. "/" .. gait .. "/" .. set
						assert(glob_count(dir .. "/x") > 0,
							key .. ": no audio for " .. gait .. "/" .. material .. " -> " .. dir)
					end
				end
			end
		else
			assert(glob_count(audio.pattern) > 0, key .. ": " .. what .. " glob matches nothing: " .. audio.pattern)
		end
	end
	-- A cue has either a single audio source, or `layers` played simultaneously (the plasma
	-- event fires two actions at once: a charge tone plus an overlay).
	assert(cue.audio or cue.layers, key .. ": has neither audio nor layers")
	assert(not (cue.audio and cue.layers), key .. ": has both audio and layers")
	if cue.audio then
		check_audio(cue.audio, "audio")
	else
		assert(#cue.layers >= 2, key .. ": layers needs at least 2 entries")
		for i, layer in ipairs(cue.layers) do
			check_audio(layer, "layer " .. i)
		end
	end
	if cue.ramp and cue.ramp.constant then
		assert(exists(cue.ramp.constant.path), key .. ": constant loop missing: " .. cue.ramp.constant.path)
	end

	-- Every cue needs its options labels, or it is unreachable in the UI.
	for _, suffix in ipairs({ "_enabled", "_suppress" }) do
		assert(Loc[cue.setting_id .. suffix], key .. ": missing localization for " .. cue.setting_id .. suffix)
	end

	-- Every cue's range is the attenuation radius extracted from the game's own soundbank, so a cue
	-- carries exactly as far as the game carries it. The audible_range setting scales all of them.
	-- A missing range would silently fall back to a default and misrepresent that enemy's reach.
	assert(type(cue.range) == "number" and cue.range > 0,
		key .. ": missing range (must be the game's attenuation radius, in metres)")
	assert(cue.max_distance == nil,
		key .. ": max_distance is obsolete, use range (the game's own radius)")
	if cue.min_distance then
		assert(cue.min_distance < cue.range,
			key .. ": min_distance (" .. cue.min_distance .. ") is not inside range (" .. cue.range .. ")")
	end

	-- A ramped cue needs a curve; a non-ramped one must not carry ramp settings by accident.
	if cue.mode == "ramped_tick" then
		assert(cue.ramp and cue.ramp.curve, key .. ": ramped_tick without a curve")
	else
		assert(cue.ramp == nil, key .. ": non-ramped cue carries a ramp table")
	end
end

-- CueHooks dispatches effect_template / inventory / breed_spawn cues through single-slot lookup
-- tables, so two cues claiming the same key means the second silently REPLACES the first. Shared
-- wwise EVENTS are fine (HookRegistry fans one hook_sound out over a list of cues), which is why
-- only these three kinds are checked. Without this, four footstep cues were silently dead.
local claimed = {}
local function claim(what, key, cue_key)
	local slot = what .. "|" .. tostring(key)
	assert(not claimed[slot], "two cues claim the same " .. what .. " '" .. tostring(key) .. "': "
		.. tostring(claimed[slot]) .. " and " .. cue_key)
	claimed[slot] = cue_key
end
for _, cue in ipairs(Catalog) do
	local hook = cue.hook
	if hook.kind == "breed_spawn" then
		claim("breed_spawn breed", hook.breed, cue.key)
	elseif hook.kind == "inventory" then
		for _, ev in ipairs(hook.events) do claim("inventory event", ev, cue.key) end
	elseif hook.kind == "effect_template" then
		if hook.template then claim("effect template", hook.template, cue.key) end
		for _, name in ipairs(hook.templates or {}) do claim("effect template", name, cue.key) end
	end
end

-- suppress_events is only consumed by Suppression.lua, which skips sound_event and vo_event cues
-- (they derive their mute list from the hook itself). Declaring it on those kinds is dead data that
-- reads as authoritative and does nothing.
for _, cue in ipairs(Catalog) do
	if cue.hook.kind == "sound_event" or cue.hook.kind == "vo_event" then
		assert(cue.suppress_events == nil, cue.key .. ": " .. cue.hook.kind ..
			" cues must not declare suppress_events (never read; suppression comes from the hook)")
	end
end

-- The options are grouped BY ENEMY (DMF groups cannot nest, so each enemy is one group holding its
-- cues' checkboxes directly). Every cue must appear in exactly one group, every group must be
-- localized, and no group may list a cue that does not exist -- otherwise a cue is unreachable in
-- the UI, or a dead checkbox sits there doing nothing.
local real_cue = {}
for _, cue in ipairs(Catalog) do real_cue[cue.setting_id] = true end

-- The mod-wide settings, which live in their own "Options" group. Every one is read somewhere in
-- core/Settings.lua; a widget here that nothing reads, or a setting read that has no widget, is a
-- dead control.
local GLOBALS = {
	enabled = true, volume = true, audible_range = true, repeat_all = true,
	mute_all = true, sound_test = true, isolate_cues = true, debug = true,
}

local seen_widget, seen_global, n_groups = {}, {}, 0
for _, w in ipairs(Data.options.widgets) do
	assert(w.type == "group", "top-level widget outside a group: " .. tostring(w.setting_id))
	n_groups = n_groups + 1
	assert(Loc[w.setting_id], "missing localization for options group " .. w.setting_id)
	assert(w.sub_widgets and #w.sub_widgets > 0, w.setting_id .. ": empty options group")

	for _, sw in ipairs(w.sub_widgets) do
		local id = sw.setting_id
		assert(not seen_widget[id] and not seen_global[id], "duplicate widget: " .. id)
		assert(Loc[id], "missing localization for widget " .. id)

		if GLOBALS[id] then
			seen_global[id] = true
		else
			local cue_id = id:gsub("_enabled$", ""):gsub("_suppress$", "")
			assert(real_cue[cue_id], w.setting_id .. ": widget for a cue that does not exist: " .. id)
			seen_widget[id] = true
		end
	end
end

for id in pairs(GLOBALS) do
	assert(seen_global[id], "mod-wide setting '" .. id .. "' has no widget (unreachable in the UI)")
end

for _, cue in ipairs(Catalog) do
	for _, suffix in ipairs({ "_enabled", "_suppress" }) do
		assert(seen_widget[cue.setting_id .. suffix],
			cue.key .. ": no options widget for " .. cue.setting_id .. suffix .. " (unreachable in the UI)")
	end
end

print("test_catalog OK (" .. #Catalog .. " cues in " .. (n_groups - 1) ..
	" enemy groups + Options, audio present, events well-formed, UI wired)")
