--[[
	Name: Signal Repeater
	Author: Wobin
	Date: 12/07/2026
	Version: 1.0.0
	Repository: https://github.com/Wobin/Signal-Repeater
]]--

local mod = get_mod("Signal Repeater")

local ipairs = ipairs

local HookRegistry = {}

local handlers = {}

function HookRegistry.add(pattern, handler)
	local list = handlers[pattern]

	if not list then
		list = {}
		handlers[pattern] = list

		mod.simple_audio.hook_sound(pattern, function(sound_type, event_name, delta, source)
			local suppress = false
			for _, fn in ipairs(list) do
				if fn(event_name, source) then
					suppress = true
				end
			end
			if suppress then
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
