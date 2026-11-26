hl.plugin.load(os.getenv("HYMISSION_PLUGIN"))

local dynamicCursors = os.getenv("HYPR_DYNAMIC_CURSORS_PLUGIN")
if dynamicCursors then
	hl.plugin.load(dynamicCursors)
end

local hyprbars = os.getenv("HYPRBARS_PLUGIN")
if hyprbars then
	hl.plugin.load(hyprbars)
end

hl.on("hyprland.start", function()
	hl.exec_cmd(
		"dbus-update-activation-environment --systemd DISPLAY HYPRLAND_INSTANCE_SIGNATURE WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE"
	)
	hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP PATH XDG_DATA_DIRS")
	hl.exec_cmd("/run/current-system/sw/libexec/polkit-gnome-authentication-agent-1")
end)

hl.config({
	cursor = { no_hardware_cursors = true },
})

dofile(os.getenv("HOME") .. "/config/dotfiles/hypr/lua/index.lua")
