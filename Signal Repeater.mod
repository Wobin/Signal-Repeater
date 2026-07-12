return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`Signal Repeater` mod must be lower than Darktide Mod Framework in your launcher's load order.")

		new_mod("Signal Repeater", {
			mod_script       = "Signal Repeater/scripts/mods/Signal Repeater/Signal Repeater",
			mod_data         = "Signal Repeater/scripts/mods/Signal Repeater/Signal Repeater_data",
			mod_localization = "Signal Repeater/scripts/mods/Signal Repeater/Signal Repeater_localization",
		})
	end,
	load_after = {
		"SimpleAudio",
	},
	require = {
		"SimpleAudio",
	},
	packages = {},
}
