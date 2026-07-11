--[[
	Name: Signal Repeater
	Author: Wobin
	Date: 11/07/2026
	Version: 1.0.0
	Repository: https://github.com/Wobin/Signal-Repeater
]]--

local mod = get_mod("Signal Repeater")

local function cue_group(id)
	return {
		setting_id = id .. "_group",
		type = "group",
		sub_widgets = {
			{ setting_id = id .. "_enabled", type = "checkbox", default_value = true },
			{ setting_id = id .. "_suppress", type = "checkbox", default_value = false },
		},
	}
end

return {
	name = mod:localize("mod_name"),
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = {
			{ setting_id = "enabled", type = "checkbox", default_value = true },
			{ setting_id = "repeat_all", type = "checkbox", default_value = true },
			{ setting_id = "mute_all", type = "checkbox", default_value = false },
			{ setting_id = "volume", type = "numeric", default_value = 100, range = { 0, 200 } },
			{ setting_id = "audible_range", type = "numeric", default_value = 150, range = { 20, 200 } },
			{ setting_id = "sound_test", type = "checkbox", default_value = false },
			{ setting_id = "debug", type = "checkbox", default_value = false },

			cue_group("sniper_aim"),
			cue_group("plasma_charge"),
			cue_group("mutant_charge"),
			cue_group("hound_approach"),
			cue_group("flamer_ignite"),
			cue_group("trapper_windup"),
			cue_group("poxburster_beep"),
			cue_group("daemonhost_aggro"),
		},
	},
}
