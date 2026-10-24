hl.config({
	general = {
		layout = "scrolling",
	},
	scrolling = {
		column_width = 0.667,
		follow_focus = true,
		direction = "right",
		focus_fit_method = 1,
		follow_min_visible = 0.5,
	},
})

hl.workspace_rule({ workspace = "m[HDMI-A-1]", layout_opts = { direction = "down" } })
