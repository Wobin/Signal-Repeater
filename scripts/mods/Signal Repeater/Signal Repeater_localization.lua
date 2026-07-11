return {
	mod_name = {
		en = "Signal Repeater",
	},
	mod_description = {
		en = "Re-plays important special and elite enemy cues through SimpleAudio so they are always audible.",
	},

	enabled = { en = "Enabled" },

	repeat_all = { en = "Repeat every cue below (ticks/unticks all)" },
	mute_all = { en = "Silence the game's own cue for all of them (ticks/unticks all)" },

	volume = { en = "Volume of our cues (100 = as loud as the game's)" },
	audible_range = { en = "How far away our cues can still be heard (m)" },
	sound_test = { en = "Sound test: loop a hound bark circling you, to set volume" },
	debug = { en = "Debug: print each cue to chat as it fires" },
	sr_test = { en = "Toggle the Signal Repeater sound test" },

	sniper_aim_group = { en = "Sniper" },
	sniper_aim_enabled = { en = "Repeat aim beam" },
	sniper_aim_suppress = { en = "Silence the game's own cue (ours replaces it)" },

	plasma_charge_group = { en = "Plasma Gunner" },
	plasma_charge_enabled = { en = "Repeat charge-up" },
	plasma_charge_suppress = { en = "Silence the game's own cue (ours replaces it)" },

	mutant_charge_group = { en = "Mutant" },
	mutant_charge_enabled = { en = "Repeat charge growl" },
	mutant_charge_suppress = { en = "Silence the game's own cue (ours replaces it)" },

	hound_approach_group = { en = "Chaos Hound" },
	hound_approach_enabled = { en = "Repeat approach bark" },
	hound_approach_suppress = { en = "Silence the game's own cue (ours replaces it)" },

	flamer_ignite_group = { en = "Flamer" },
	flamer_ignite_enabled = { en = "Repeat proximity warning" },
	flamer_ignite_suppress = { en = "Silence the game's own cue (ours replaces it)" },

	trapper_windup_group = { en = "Trapper" },
	trapper_windup_enabled = { en = "Repeat net-gun wind-up" },
	trapper_windup_suppress = { en = "Silence the game's own cue (ours replaces it)" },

	poxburster_beep_group = { en = "Poxburster" },
	poxburster_beep_enabled = { en = "Repeat ticking" },
	poxburster_beep_suppress = { en = "Silence the game's own cue (ours replaces it)" },

	daemonhost_aggro_group = { en = "Daemonhost" },
	daemonhost_aggro_enabled = { en = "Repeat alert scream" },
	daemonhost_aggro_suppress = { en = "Silence the game's own cue (ours replaces it)" },
}
