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
