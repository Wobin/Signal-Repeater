--[[
	Name: Signal Repeater
	Author: Wobin
	Date: 10/07/2026
	Version: 1.0.0
	Repository: https://github.com/Wobin/Signal-Repeater
]]--

local mod = get_mod("Signal Repeater")

return {
	name = mod:localize("mod_name"),
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = {
			{ setting_id = "enabled", type = "checkbox", default_value = true },
			{ setting_id = "volume", type = "numeric", default_value = 100, range = { 0, 200 } },
			{ setting_id = "max_distance", type = "numeric", default_value = 35, range = { 5, 80 } },
		},
	},
}
