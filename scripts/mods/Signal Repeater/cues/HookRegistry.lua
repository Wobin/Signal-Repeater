local mod = get_mod("Signal Repeater")

local xpcall = xpcall

local HookRegistry = {}

local handlers = {}

local reported = false
local function on_error(err)
	if not reported then
		reported = true
		mod:error("cue hook failed (further occurrences suppressed): %s", tostring(err))
	end
	return err
end

local function dispatch(list, event_name, source)
	local suppress = false
	for i = 1, #list do
		if list[i](event_name, source) then
			suppress = true
		end
	end
	return suppress
end

function HookRegistry.add(pattern, handler)
	local list = handlers[pattern]

	if not list then
		list = {}
		handlers[pattern] = list

		mod.simple_audio.hook_sound(pattern, function(sound_type, event_name, delta, source)
			local ok, suppress = xpcall(dispatch, on_error, list, event_name, source)
			if ok and suppress then
				return false
			end
		end)
	end

	list[#list + 1] = handler
end

function HookRegistry.claim(map, key, cue, what)
	if map[key] then
		mod:error(
			"two cues claim the same %s '%s': '%s' and '%s'. The second would be silently ignored.",
			what, tostring(key), map[key].key, cue.key
		)
		return
	end
	map[key] = cue
end

return HookRegistry
