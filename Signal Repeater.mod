return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`Signal Repeater` mod must be lower than Darktide Mod Framework in your launcher's load order.")

		new_mod("Signal Repeater", {
			mod_script       = "Signal Repeater/scripts/mods/Signal Repeater/Signal Repeater",
			mod_data         = "Signal Repeater/scripts/mods/Signal Repeater/data",
			mod_localization = "Signal Repeater/localization/Signal Repeater",
		})
	end,
	packages = {},
}
