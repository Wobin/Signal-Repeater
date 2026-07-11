-- standalone luajit test: catalog integrity. Catches the class of bug that is INVISIBLE at
-- runtime -- a cue that silently never fires, or plays nothing -- without needing the game.
local fake_mod = { localize = function(_, k) return k end }
_G.get_mod = function() return fake_mod end

local ROOT = "mods/Signal Repeater/scripts/mods/Signal Repeater/"
local Catalog = dofile(ROOT .. "cues/CueCatalog.lua")
local Data = dofile(ROOT .. "Signal Repeater_data.lua")
local Loc = dofile(ROOT .. "Signal Repeater_localization.lua")

local KINDS = {
	effect_template = true, sound_event = true, inventory = true, breed_spawn = true,
}

local function exists(path)
	local f = io.open(path, "rb")
	if f then f:close() return true end
	return false
end

-- Glob the folder of a "mods/..." pattern by listing the directory (cmd.exe, so `dir /b`).
local function glob_count(pattern)
	local dir = pattern:match("^(.*)/[^/]*$"):gsub("/", "\\")
	local n = 0
	local p = io.popen('dir /b "' .. dir .. '" 2>nul')
	if not p then return 0 end
	for line in p:lines() do
		if line:match("%.ogg$") then n = n + 1 end
	end
	p:close()
	return n
end

assert(#Catalog == 8, "expected 8 cues, got " .. #Catalog)

local seen_keys = {}
for _, cue in ipairs(Catalog) do
	local key = cue.key
	assert(key and key ~= "", "cue missing key")
	assert(not seen_keys[key], "duplicate cue key: " .. key)
	seen_keys[key] = true

	assert(cue.setting_id, key .. ": missing setting_id")
	assert(KINDS[cue.hook.kind], key .. ": unknown hook kind " .. tostring(cue.hook.kind))

	-- Every Wwise event string must be a FULL resource path. The trapper cue silently never
	-- fired for hours because it was keyed on the bare event name.
	local function check_event(ev, what)
		assert(ev:match("^%^?wwise/events/"), key .. ": " .. what .. " is not a full wwise path: " .. ev)
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

	-- Every cue needs its options widgets and their labels, or it is unreachable in the UI.
	for _, suffix in ipairs({ "_group", "_enabled", "_suppress" }) do
		assert(Loc[cue.setting_id .. suffix], key .. ": missing localization for " .. cue.setting_id .. suffix)
	end

	-- A ramped cue needs a curve; a non-ramped one must not carry ramp settings by accident.
	if cue.mode == "ramped_tick" then
		assert(cue.ramp and cue.ramp.curve, key .. ": ramped_tick without a curve")
	else
		assert(cue.ramp == nil, key .. ": non-ramped cue carries a ramp table")
	end
end

-- Every breed group in the options must correspond to a real cue, and vice versa.
local grouped = {}
for _, w in ipairs(Data.options.widgets) do
	if w.type == "group" then
		grouped[w.setting_id:gsub("_group$", "")] = true
	end
end
for _, cue in ipairs(Catalog) do
	assert(grouped[cue.setting_id], cue.key .. ": no options group for " .. cue.setting_id)
end
local n_groups = 0
for _ in pairs(grouped) do n_groups = n_groups + 1 end
assert(n_groups == #Catalog, "options groups (" .. n_groups .. ") do not match cue count (" .. #Catalog .. ")")

print("test_catalog OK (" .. #Catalog .. " cues, audio present, events well-formed, UI wired)")
