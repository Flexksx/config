local expressive = {
	fast_spatial = { name = "expressive_fast_spatial", duration = 3.5, points = { { 0.42, 1.67 }, { 0.21, 0.90 } } },
	default_spatial = { name = "expressive_default_spatial", duration = 5, points = { { 0.38, 1.21 }, { 0.22, 1.00 } } },
	slow_spatial = { name = "expressive_slow_spatial", duration = 6.5, points = { { 0.39, 1.29 }, { 0.35, 0.98 } } },
	fast_effects = { name = "expressive_fast_effects", duration = 1.5, points = { { 0.31, 0.94 }, { 0.34, 1.00 } } },
	default_effects = { name = "expressive_default_effects", duration = 2, points = { { 0.34, 0.80 }, { 0.34, 1.00 } } },
	slow_effects = { name = "expressive_slow_effects", duration = 3, points = { { 0.34, 0.88 }, { 0.34, 1.00 } } },
}

local standard = {
	fast_spatial = { name = "standard_fast_spatial", duration = 3.5, points = { { 0.27, 1.06 }, { 0.18, 1.00 } } },
	default_spatial = { name = "standard_default_spatial", duration = 5, points = { { 0.27, 1.06 }, { 0.18, 1.00 } } },
	slow_spatial = { name = "standard_slow_spatial", duration = 7.5, points = { { 0.27, 1.06 }, { 0.18, 1.00 } } },
	fast_effects = { name = "standard_fast_effects", duration = 1.5, points = { { 0.31, 0.94 }, { 0.34, 1.00 } } },
	default_effects = { name = "standard_default_effects", duration = 2, points = { { 0.34, 0.80 }, { 0.34, 1.00 } } },
	slow_effects = { name = "standard_slow_effects", duration = 3, points = { { 0.34, 0.88 }, { 0.34, 1.00 } } },
}

local function register_bezier_family(family)
	for _, curve in pairs(family) do
		hl.curve(curve.name, { type = "bezier", points = curve.points })
	end
end

register_bezier_family(expressive)
register_bezier_family(standard)

hl.config({ animations = { enabled = true } })

hl.animation({
	leaf = "windows",
	enabled = true,
	speed = expressive.default_effects.duration,
	bezier = expressive.default_effects.name,
	style = "popin 60%",
})

hl.animation({
	leaf = "border",
	enabled = true,
	speed = expressive.slow_effects.duration,
	bezier = expressive.slow_effects.name,
})

hl.animation({
	leaf = "fade",
	enabled = true,
	speed = expressive.fast_effects.duration,
	bezier = expressive.fast_effects.name,
})

hl.animation({
	leaf = "layers",
	enabled = true,
	speed = expressive.default_effects.duration,
	bezier = expressive.default_effects.name,
	style = "popin 40%",
})

local workspace_animation_style = nil

local function apply_workspace_slide_axis(monitor)
	monitor = monitor or hl.get_active_monitor()
	if not monitor then
		return
	end

	local rotated = monitor.transform % 2 == 1
	local portrait = (monitor.height > monitor.width) ~= rotated
	local style = portrait and "slide" or "slidevert"
	if style == workspace_animation_style then
		return
	end

	workspace_animation_style = style
	hl.animation({
		leaf = "workspaces",
		enabled = true,
		speed = expressive.default_effects.duration,
		bezier = expressive.default_effects.name,
		style = style,
	})
end

apply_workspace_slide_axis()

hl.on("hyprland.start", apply_workspace_slide_axis)
hl.on("monitor.focused", apply_workspace_slide_axis)
hl.on("monitor.layout_changed", apply_workspace_slide_axis)
