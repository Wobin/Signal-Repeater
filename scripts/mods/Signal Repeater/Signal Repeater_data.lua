--[[
	Name: Signal Repeater
	Author: Wobin
	Date: 13/07/2026
	Version: 2.0.0
	Repository: https://github.com/Wobin/Signal-Repeater
]]--

local mod = get_mod("Signal Repeater")

local function breed_group(id, cues)
	local sub_widgets = {}
	for _, cue in ipairs(cues) do
		sub_widgets[#sub_widgets + 1] = { setting_id = cue .. "_enabled", type = "checkbox", default_value = true }
		sub_widgets[#sub_widgets + 1] = { setting_id = cue .. "_suppress", type = "checkbox", default_value = false }
	end
	return { setting_id = id, type = "group", sub_widgets = sub_widgets }
end

return {
	name = mod:localize("mod_name"),
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = {
			{
				setting_id = "grp_options",
				type = "group",
				sub_widgets = {
					{ setting_id = "enabled", type = "checkbox", default_value = true },
					{ setting_id = "volume", type = "numeric", default_value = 100, range = { 0, 200 } },
					{ setting_id = "audible_range", type = "numeric", default_value = 150, range = { 20, 200 } },
					{ setting_id = "repeat_all", type = "checkbox", default_value = true },
					{ setting_id = "mute_all", type = "checkbox", default_value = false },
					{ setting_id = "sound_test", type = "checkbox", default_value = false },
					{ setting_id = "isolate_cues", type = "checkbox", default_value = false },
					{ setting_id = "debug", type = "checkbox", default_value = false },
				},
			},

			breed_group("grp_trapper", { "trapper_windup", "trapper_interrupted", "trapper_reload", "trapper_proximity", "trapper_footsteps", "trapper_laugh" }),
			breed_group("grp_hound", { "hound_leap", "hound_approach", "hound_growl", "hound_footsteps" }),
			breed_group("grp_mutant", { "mutant_charge", "mutant_breath", "mutant_rattle", "mutant_footsteps" }),
			breed_group("grp_poxburster", { "poxburster_beep", "poxburster_footsteps" }),
			breed_group("grp_flamer", { "flamer_tank", "flamer_aim", "flamer_ignite", "flamer_flame_dreg", "flamer_flame_scab", "dreg_flamer_footsteps", "scab_flamer_footsteps" }),
			breed_group("grp_bomber", { "bomber_footsteps" }),
			breed_group("grp_sniper", { "sniper_aim", "sniper_footsteps" }),
			breed_group("grp_plasma", { "plasma_charge" }),
			breed_group("grp_daemonhost", { "daemonhost_aggro" }),
			breed_group("grp_reaper", { "reaper_vo_alerted", "reaper_vo_shooting", "reaper_ready", "reaper_fire", "reaper_melee", "reaper_footsteps" }),
			breed_group("grp_crusher", { "crusher_vo_alerted", "crusher_vo_assault", "crusher_special", "crusher_melee", "crusher_swing", "crusher_footsteps" }),
			breed_group("grp_bulwark", { "bulwark_ready", "bulwark_special", "bulwark_swing", "bulwark_melee", "bulwark_footsteps" }),
			breed_group("grp_mauler", { "mauler_special", "mauler_swing", "mauler_melee", "mauler_footsteps" }),
		},
	},
}
