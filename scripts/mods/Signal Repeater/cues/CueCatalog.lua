--[[
	Name: Signal Repeater
	Author: Wobin
	Date: 11/07/2026
	Version: 1.0.0
	Repository: https://github.com/Wobin/Signal-Repeater
]]--

return {
	{
		key = "sniper_aim", setting_id = "sniper_aim",
		hook = { kind = "effect_template", template = "renegade_sniper_laser" },
		audio = { kind = "file", path = "mods/Signal Repeater/audio/cues/sniper_aim.ogg" },
		mode = "loop",
		max_duration = 6,
		suppress_events = { "wwise/events/weapon/play_combat_weapon_las_sniper_target_beam" },
	},
	{
		key = "plasma_charge", setting_id = "plasma_charge",
		hook = { kind = "effect_template", template = "renegade_plasma_gunner_charge_up" },
		audio = { kind = "glob", pattern = "mods/Signal Repeater/audio/cues/plasma_charge/*.ogg" },
		mode = "loop",
		max_duration = 5,
		suppress_events = { "wwise/events/weapon/play_minion_plasmapistol_charge_02" },
	},
	{
		key = "mutant_charge", setting_id = "mutant_charge",
		hook = {
			kind = "sound_event",
			event = "wwise/events/minions/play_enemy_mutant_charger_charge_growl",
			stop_event = "wwise/events/minions/stop_enemy_mutant_charger_charge_growl",
		},
		audio = { kind = "glob", pattern = "mods/Signal Repeater/audio/cues/mutant_charge/*.ogg" },
		mode = "loop",
		max_distance = 30,
		max_duration = 5,
		suppress_events = { "wwise/events/minions/play_enemy_mutant_charger_charge_growl" },
	},
	{
		key = "hound_approach", setting_id = "hound_approach",
		hook = { kind = "sound_event", event = "wwise/events/minions/play_enemy_chaos_hound_vce_bark" },
		audio = { kind = "glob", pattern = "mods/Signal Repeater/audio/cues/hound_approach/*.ogg" },
		mode = "play_once",
		overlap = true,
		max_distance = 35,
		max_duration = 4,
		suppress_events = { "wwise/events/minions/play_enemy_chaos_hound_vce_bark" },
	},
	{
		key = "flamer_ignite", setting_id = "flamer_ignite",
		hook = { kind = "sound_event", event = "wwise/events/minions/play_cultist_flamer_proximity_warning" },
		audio = { kind = "glob", pattern = "mods/Signal Repeater/audio/cues/flamer_ignite/*.ogg" },
		mode = "play_once",
		overlap = true,
		max_distance = 35,
		max_duration = 3.5,
		suppress_events = { "wwise/events/minions/play_cultist_flamer_proximity_warning" },
	},
	{
		key = "trapper_windup", setting_id = "trapper_windup",
		hook = { kind = "inventory", events = { "wwise/events/minions/play_weapon_netgunner_wind_up" } },
		audio = { kind = "file", path = "mods/Signal Repeater/audio/cues/trapper_windup.ogg" },
		mode = "play_once",
		max_duration = 4,
		suppress_events = { "wwise/events/minions/play_weapon_netgunner_wind_up" },
	},
	{
		key = "poxburster_beep", setting_id = "poxburster_beep",
		hook = {
			kind = "breed_spawn",
			breed = "chaos_poxwalker_bomber",
			stops = {
				{ path = "scripts/extension_systems/behavior/nodes/actions/bt_poxwalker_bomber_approach_action", func = "_start_lunge" },
				{ path = "scripts/extension_systems/behavior/nodes/actions/bt_chaos_poxwalker_explode_action", func = "enter" },
			},
		},
		audio = { kind = "glob", pattern = "mods/Signal Repeater/audio/cues/poxburster_beep/*.ogg" },
		far_audio = { kind = "glob", pattern = "mods/Signal Repeater/audio/cues/poxburster_far/*.ogg" },
		layer_blend = { near_end = 9.88, far_start = 35.12 },
		mode = "ramped_tick",
		gain = 2.0,
		suppress_events = { "wwise/events/minions/play_enemy_combat_poxwalker_bomber_beep_loop" },
		ramp = {
			curve = {
				points = { { 0, 0.03 }, { 50, 1.5 } },
				min_interval = 0.12,
			},
			pitch_cents = { { 0, 400 }, { 8, 115 }, { 50, -200 } },
			constant = { distance = 3.0, path = "mods/Signal Repeater/audio/cues/poxburster_constant.ogg" },
		},
	},
	{
		key = "daemonhost_aggro", setting_id = "daemonhost_aggro",
		hook = {
			kind = "sound_event",
			pattern = "^wwise/events/minions/play_enemy_daemonhost_alert_scream",
		},
		audio = { kind = "glob", pattern = "mods/Signal Repeater/audio/cues/daemonhost_aggro/*.ogg" },
		mode = "play_once",
		overlap = true,
		min_distance = 60,
		gain = 1.5,
		max_duration = 6,
		suppress_events = { "wwise/events/minions/play_enemy_daemonhost_alert_scream" },
	},
}
