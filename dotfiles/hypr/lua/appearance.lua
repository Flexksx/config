local home = os.getenv("HOME")
local colors = dofile(home .. "/config/dotfiles/matugen/out/hyprland_colors.lua")

if hl.plugin.hymission then
	hl.config({
		plugin = {
			hymission = {
				workspace_strip_anchor = "top",
				backdrop_color = "rgba(00000040)",
				show_focus_indicator = true,
				focus_hover_color = colors.col_active_border,
				focus_selected_color = colors.tertiary,
				focus_title_color = colors.on_surface,
				selected_expand_scale = 1.1,
				hover_relayout_duration = 200,
			},
		},
	})
end

hl.config({
	general = {
		gaps_in = 6,
		gaps_out = 12,
		border_size = 0,
		col = {
			active_border = colors.col_active_border,
			inactive_border = colors.col_inactive_border,
		},
		resize_on_border = true,
		hover_icon_on_border = true,
		allow_tearing = false,
	},
	decoration = {
		rounding = 8,
		shadow = {
			enabled = true,
			range = 30,
			render_power = 4,
			color = colors.shadow_color,
		},
		blur = {
			enabled = true,
			new_optimizations = true,
			passes = 4,
			size = 8,
			noise = 0.02,
			contrast = 1.0,
			brightness = 0.8,
			vibrancy = 0.1696,
			vibrancy_darkness = 0.0,
		},
		motion_blur = {
			enabled = false,
		},
	},
	misc = {
		font_family = "Inter",
	},
})
