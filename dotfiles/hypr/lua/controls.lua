hl.config({
	cursor = {
		no_hardware_cursors = true,
	},
	input = {
		kb_layout = "us,ru",
		kb_options = "grp:alt_shift_toggle",
		follow_mouse = 1,
		touchpad = {
			natural_scroll = true,
			clickfinger_behavior = true,
		},
	},
})

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 3, direction = "vertical", action = "workspace" })
