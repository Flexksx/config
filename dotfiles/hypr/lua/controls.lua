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
			scroll_factor = 0.35,
		},
	},
})

local strip_swipe_scale = 0.5
local gesture_portrait = nil

local function apply_gesture_axes(monitor)
	monitor = monitor or hl.get_active_monitor()
	if not monitor then
		return
	end

	local rotated = monitor.transform % 2 == 1
	local portrait = (monitor.height > monitor.width) ~= rotated
	if portrait == gesture_portrait then
		return
	end

	local strip_direction = portrait and "vertical" or "horizontal"
	local workspace_direction = portrait and "horizontal" or "vertical"
	if gesture_portrait ~= nil then
		hl.gesture({ fingers = 3, direction = workspace_direction, scale = strip_swipe_scale, action = "unset" })
		hl.gesture({ fingers = 3, direction = strip_direction, action = "unset" })
	end

	gesture_portrait = portrait
	hl.gesture({ fingers = 3, direction = strip_direction, scale = strip_swipe_scale, action = "scroll_move" })
	hl.gesture({ fingers = 3, direction = workspace_direction, action = "workspace" })
end

apply_gesture_axes()
hl.on("hyprland.start", apply_gesture_axes)
hl.on("monitor.focused", apply_gesture_axes)
hl.on("monitor.layout_changed", apply_gesture_axes)
