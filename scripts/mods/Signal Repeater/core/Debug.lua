--[[
	Name: Signal Repeater
	Author: Wobin
	Date: 11/07/2026
	Version: 1.0.0
	Repository: https://github.com/Wobin/Signal-Repeater
]]--

local mod = get_mod("Signal Repeater")

local string_format = string.format

local Debug = {}

local function basename(path)
	if not path then return "?" end
	return path:match("([^/\\]+)$") or path
end

function Debug.played(cue, path, distance)
	if not mod.settings.debug() then return end
	local mode = mod.settings.suppress(cue.setting_id) and "replace" or "supplement"
	if distance then
		mod:echo(string_format("[SR] %s -> %s (%s, %.0fm)", cue.key, basename(path), mode, distance))
	else
		mod:echo(string_format("[SR] %s -> %s (%s)", cue.key, basename(path), mode))
	end
end

function Debug.stopped(cue, reason)
	if not mod.settings.debug() then return end
	mod:echo(string_format("[SR] %s stopped (%s)", cue.key, reason))
end

function Debug.suppressed(cue, event_name)
	if not mod.settings.debug() then return end
	mod:echo(string_format("[SR] muted original %s (%s)", event_name, cue.key))
end

function Debug.ramp(cue, state)
	if not mod.settings.debug() then return end
	mod:echo(string_format("[SR] %s ramp %s", cue.key, state))
end

return Debug
