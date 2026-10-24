local env_vars = {
	HYPRCURSOR_THEME = "McMojave",
	HYPRCURSOR_SIZE = "36",
	QT_QPA_PLATFORMTHEME = "qt6ct",
	QT_QPA_PLATFORM = "wayland;xcb",
	QT_AUTO_SCREEN_SCALE_FACTOR = "1",
	XDG_SESSION_TYPE = "wayland",
	XDG_SESSION_DESKTOP = "Hyprland",
	XDG_CURRENT_DESKTOP = "Hyprland",
	ELECTRON_OZONE_PLATFORM_HINT = "auto",
	NIXOS_OZONE_WL = "1",
	_JAVA_AWT_WM_NONREPARENTING = "1",
	EDITOR = "nvim",
}

for key, value in pairs(env_vars) do
	hl.env(key, value)
end

hl.config({
	xwayland = {
		force_zero_scaling = true,
	},
})
