local home = os.getenv("HOME")
local colors = dofile(home .. "/config/dotfiles/matugen/out/hyprland_colors.lua")

if hl.plugin.hyprbars then
	hl.config({
		plugin = {
			hyprbars = {
				bar_height = 24,
				bar_color = colors.surface_container,
				col = { text = colors.on_surface },
				bar_text_font = "Inter",
				bar_buttons_alignment = "left",
				icon_on_hover = true,
			},
		},
	})
	hl.plugin.hyprbars.add_button({
		bg_color = "rgb(ff5f57)",
		fg_color = "rgb(4d0000)",
		size = 12,
		icon = "×",
		action = "hyprctl dispatch 'hl.dsp.window.close()'",
	})
	hl.plugin.hyprbars.add_button({
		bg_color = "rgb(febc2e)",
		fg_color = "rgb(664000)",
		size = 12,
		icon = "−",
		action = [[hyprctl dispatch 'hl.dsp.window.move({ workspace = "special:minimized", follow = false })']],
	})
	hl.plugin.hyprbars.add_button({
		bg_color = "rgb(28c840)",
		fg_color = "rgb(004d00)",
		size = 12,
		icon = "+",
		action = [[hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })']],
	})
	hl.window_rule({ match = { float = false }, ["hyprbars:no_bar"] = true })
end

if hl.plugin.dynamic_cursors then
	hl.config({ plugin = { dynamic_cursors = { mode = "none", shake = { enabled = true } } } })
end

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
